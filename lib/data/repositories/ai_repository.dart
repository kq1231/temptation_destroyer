import 'package:dio/dio.dart';
import 'package:temptation_destroyer/core/utils/logger.dart';
import 'dart:math';
import 'dart:convert';

import '../../core/utils/object_box_manager.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/utils/encryption_service.dart';
import '../models/ai_models.dart';
import '../models/chat_session_model.dart';
import '../../objectbox.g.dart';
import '../../core/config/ai_service_config.dart' as config;
import '../../presentation/providers/ai_service_provider.dart';

/// Repository for handling AI-related operations
class AIRepository {
  final SecureStorageService _secureStorage;
  final Box<ChatMessageModel> _chatBox;
  final Dio _dio;
  final EncryptionService _encryptionService = EncryptionService.instance;
  final dynamic _ref;

  // Rate limiting configuration
  static const _maxRequestsPerMinute = 60;
  final Map<String, List<DateTime>> _requestTimestamps = {};

  /// Constructor
  AIRepository(dynamic ref)
      : _secureStorage = SecureStorageService.instance,
        _chatBox = ObjectBoxManager.instance.box<ChatMessageModel>(),
        _dio = Dio(),
        _ref = ref {
    _initializeRequestTracking();
  }

  /// Initialize request tracking for rate limiting
  void _initializeRequestTracking() {
    // Initialize request tracking for all service types
    _requestTimestamps[AIServiceType.openAI] = [];
    _requestTimestamps[AIServiceType.anthropic] = [];
    _requestTimestamps[AIServiceType.openRouter] = [];
    _requestTimestamps[AIServiceType.offline] = [];
  }

  /// Check if we can make a request (rate limiting)
  bool _canMakeRequest(String serviceType) {
    final timestamps = _requestTimestamps[serviceType]!;
    final now = DateTime.now();

    // Remove timestamps older than 1 minute
    timestamps.removeWhere(
        (timestamp) => now.difference(timestamp) > const Duration(minutes: 1));

    // Check if we're under the limit
    if (timestamps.length < _maxRequestsPerMinute) {
      timestamps.add(now);
      return true;
    }

    return false;
  }

  /// Get API key for a service type from secure storage
  Future<String?> _getSecureApiKey(String type) async {
    try {
      // First check if we have a key in the config
      final config = getServiceConfig();
      if (config.serviceType == type &&
          config.apiKey != null &&
          config.apiKey!.isNotEmpty) {
        return config.apiKey;
      }

      // If no key in config, try secure storage
      final key = await _secureStorage.getKey(type);
      if (key != null && key.isNotEmpty) {
        // Save the key to config for future use
        final updatedConfig = config.copyWith(
          apiKey: ObjectBoxManager.encryptString(key),
          isEncrypted: true,
        );
        saveServiceConfig(updatedConfig);
        return key;
      }
      return null;
    } catch (e) {
      AppLogger.debug('Error getting API key: $e');
      return null;
    }
  }

  /// Validate API key for a service
  Future<bool> _validateApiKey(String type, String key) async {
    // TODO: Implement key validation logic for each service
    // For now, just check if it's not empty and has a valid format
    if (key.isEmpty) return false;

    if (type == AIServiceType.openAI) {
      return key.startsWith('sk-') && key.length > 20;
    } else if (type == AIServiceType.anthropic) {
      return key.startsWith('sk-ant-') && key.length > 20;
    } else if (type == AIServiceType.openRouter) {
      return key.length > 20;
    } else if (type == AIServiceType.offline) {
      return true;
    } else {
      return true;
    }
  }

  /// Generate a response from the AI
  Future<ChatMessageModel> generateResponse({
    required String userInput,
    required List<ChatMessageModel> context,
    config.AIServiceConfig? config,
    ChatSession? session,
  }) async {
    AppLogger.debug('\n=== AI Repository: Generating Response ===');
    AppLogger.debug('User input length: ${userInput.length}');
    AppLogger.debug('Context length: ${context.length}');
    AppLogger.debug('User input: $userInput');
    AppLogger.debug('Context: $context');

    // Get the current AI service config if not provided
    final serviceConfig = config ?? getServiceConfig();
    AppLogger.debug('Service type: ${serviceConfig.serviceType}');
    AppLogger.debug('Model: ${serviceConfig.preferredModel ?? "default"}');
    AppLogger.debug('Temperature: ${serviceConfig.temperature}');
    AppLogger.debug('Max tokens: ${serviceConfig.maxTokens}');

    // Don't check for API key if we're in offline mode
    if (serviceConfig.serviceType == AIServiceType.offline) {
      AppLogger.debug('Using offline mode');
      return await _getFallbackResponse(userInput, context, session);
    }

    try {
      // Get API key from secure storage
      final apiKey = await _getSecureApiKey(serviceConfig.serviceType);
      if (apiKey == null || apiKey.isEmpty) {
        AppLogger.debug('No API key found, returning error message');
        return await _getFallbackResponse(userInput, context, session,
            errorMessage:
                "No API key found for ${serviceConfig.serviceType}. Please add your API key in the settings.");
      }

      // Validate API key
      final isValid = await _validateApiKey(serviceConfig.serviceType, apiKey);
      if (!isValid) {
        AppLogger.debug('Invalid API key, returning error message');
        return await _getFallbackResponse(userInput, context, session,
            errorMessage:
                "Invalid API key format for ${serviceConfig.serviceType}. Please check your API key in the settings.");
      }

      // Check rate limiting
      if (!_canMakeRequest(serviceConfig.serviceType)) {
        AppLogger.debug('Rate limit exceeded');
        return await _getFallbackResponse(userInput, context, session,
            errorMessage:
                "Rate limit exceeded for ${serviceConfig.serviceType}. Please try again in a minute.");
      }

      // Create a config copy with the secure API key
      final secureConfig = serviceConfig.copyWith(apiKey: apiKey);

      AppLogger.debug('\nSending request to AI service...');
      // Send the request to the appropriate AI service
      final response = await _sendRequestToAIService(
        userInput: userInput,
        context: context,
        config: secureConfig,
      );
      AppLogger.debug('Received response of length: ${response.length}');

      // Create the AI response
      final chatMessage = ChatMessageModel(
        content: response,
        isUserMessage: false,
        role: 'assistant',
        wasHelpful: null,
        session: session,
      );

      // Save the message using storeMessageAsync to ensure encryption
      await storeMessageAsync(chatMessage);

      AppLogger.debug('=== AI Repository: Response Generation Complete ===\n');
      return chatMessage;
    } catch (e) {
      AppLogger.debug('Error generating AI response: $e');
      // Return an error message instead of a fallback response
      return await _getFallbackResponse(userInput, context, session,
          errorMessage: e.toString());
    }
  }

  /// Send a request to the selected AI service with retry logic
  Future<String> _sendRequestToAIService({
    required String userInput,
    required List<ChatMessageModel> context,
    required config.AIServiceConfig config,
  }) async {
    AppLogger.debug('\n=== Sending Request to AI Service ===');
    AppLogger.debug('Service type: ${config.serviceType}');
    AppLogger.debug('Model: ${config.preferredModel ?? "default"}');
    AppLogger.debug('Context: $context');

    int retryCount = 0;
    const maxRetries = 3;
    Duration retryDelay = const Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        String response;

        if (config.serviceType == AIServiceType.openAI) {
          AppLogger.debug('Sending request to OpenAI...');
          response = await _sendOpenAIRequest(userInput, context, config);
        } else if (config.serviceType == AIServiceType.anthropic) {
          AppLogger.debug('Sending request to Anthropic...');
          response = await _sendAnthropicRequest(userInput, context, config);
        } else if (config.serviceType == AIServiceType.openRouter) {
          AppLogger.debug('Sending request to OpenRouter...');
          response = await _sendOpenRouterRequest(userInput, context, config);
        } else if (config.serviceType == AIServiceType.offline) {
          AppLogger.debug('Using offline mode');
          throw AIServiceException(
              "Currently in offline mode. Please select an online AI service in settings.");
        } else {
          throw AIServiceException(
              "Invalid AI service type. Please select a valid AI service in settings.");
        }
        AppLogger.debug('Request successful!');
        return response;
      } on DioException catch (e) {
        retryCount++;
        AppLogger.debug('Request failed (attempt $retryCount/$maxRetries): $e');

        // Parse the error response to get a more specific error message
        String errorMessage = "Network error occurred";

        if (e.response != null && e.response?.data != null) {
          try {
            final responseData = e.response?.data;
            if (responseData is Map<String, dynamic>) {
              if (responseData.containsKey('error')) {
                final error = responseData['error'];
                if (error is Map<String, dynamic> &&
                    error.containsKey('message')) {
                  errorMessage = error['message'];
                } else if (error is String) {
                  errorMessage = error;
                }
              } else if (responseData.containsKey('message')) {
                errorMessage = responseData['message'];
              }
            } else if (responseData is String) {
              errorMessage = responseData;
            }
          } catch (_) {
            // If we can't parse the error, use a default message with the status code
            errorMessage = "Error ${e.response?.statusCode}: ${e.message}";
          }
        }

        // Specific error handling based on status code
        if (e.response?.statusCode == 401) {
          throw AIServiceException(
              "Authentication failed: Invalid API key or unauthorized access.");
        } else if (e.response?.statusCode == 403) {
          throw AIServiceException(
              "Access forbidden: Your API key may not have permission to use this model.");
        } else if (e.response?.statusCode == 429) {
          if (retryCount == maxRetries) {
            throw AIServiceException(
                "Rate limit exceeded: The service is currently overloaded. Please try again later.");
          }
          // We'll retry for 429 errors
        } else if (e.response?.statusCode == 500 ||
            e.response?.statusCode == 502 ||
            e.response?.statusCode == 503) {
          if (retryCount == maxRetries) {
            throw AIServiceException(
                "Server error (${e.response?.statusCode}): The AI service is currently experiencing issues. Please try again later.");
          }
          // We'll retry for server errors
        } else {
          // For other errors, provide the specific error message
          throw AIServiceException("API error: $errorMessage");
        }

        // Wait before retrying, with exponential backoff
        if (retryCount < maxRetries) {
          AppLogger.debug('Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
          retryDelay *= 2;
        }
      } catch (e) {
        retryCount++;
        AppLogger.debug('Request failed (attempt $retryCount/$maxRetries): $e');

        // If it's already an AIServiceException, just rethrow it
        if (e is AIServiceException) {
          if (retryCount == maxRetries) rethrow;
        } else {
          // For other exceptions, create a more specific error
          if (retryCount == maxRetries) {
            throw AIServiceException(
                "Error connecting to AI service: ${e.toString()}");
          }
        }

        // Wait before retrying, with exponential backoff
        if (retryCount < maxRetries) {
          AppLogger.debug('Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
          retryDelay *= 2;
        }
      }
    }

    throw AIServiceException('Failed after $maxRetries retries');
  }

  /// Send a request to OpenAI
  Future<String> _sendOpenAIRequest(String userInput,
      List<ChatMessageModel> context, config.AIServiceConfig config) async {
    try {
      final apiKey = await _getSecureApiKey(AIServiceType.openAI);
      if (apiKey == null) {
        throw AIServiceException('OpenAI API key not found');
      }

      if (!_canMakeRequest(AIServiceType.openAI)) {
        throw AIServiceException('Rate limit exceeded for OpenAI');
      }

      const maxRetries = 3;
      var retryCount = 0;
      var backoffDelay = const Duration(seconds: 1);

      // Debug AppLogger.debug the context being sent
      AppLogger.debug('Context being sent to OpenAI:');
      AppLogger.debug(context.toString());

      // Add logging for OpenAI request parameters
      AppLogger.debug('OpenAI Request Parameters:');
      AppLogger.debug('Model: ${config.preferredModel}');
      AppLogger.debug('Messages: ${buildContextMessages(context)}');
      AppLogger.debug('Temperature: ${config.temperature}');
      AppLogger.debug('Max Tokens: ${config.maxTokens}');

      while (retryCount <= maxRetries) {
        try {
          final response = await _dio.post(
            'https://api.openai.com/v1/chat/completions',
            data: {
              'model': config.preferredModel,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a thoughtful, wise, and Islamic guidance assistant helping someone overcome temptations. Provide kind, helpful, encouraging advice based on Islamic principles and psychology. Your advice should be supportive, practical, and grounded in both religious wisdom and evidence-based approaches to behavior change. Use appropriate Quranic verses or hadith where relevant. Speak with compassion and without judgment.'
                },
                ...buildContextMessages(context),
                {'role': 'user', 'content': userInput}
              ],
              'temperature': config.temperature,
              'max_tokens': config.maxTokens,
            },
            options: Options(
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              sendTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

          final responseData = response.data;
          return responseData['choices'][0]['message']['content'] as String;
        } on DioException catch (e) {
          if (e.response?.statusCode == 429 || e.response?.statusCode == 500) {
            if (retryCount == maxRetries) rethrow;
            await Future.delayed(backoffDelay);
            backoffDelay *= 2;
            retryCount++;
            continue;
          }
          rethrow;
        }
      }

      throw AIServiceException('Max retries exceeded for OpenAI request');
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException(
          'Failed to generate OpenAI response: ${e.toString()}');
    }
  }

  /// Build context messages from a list of ChatMessageModel
  List<Map<String, String>> buildContextMessages(
      List<ChatMessageModel> context) {
    if (context.isEmpty) {
      return [];
    }
    try {
      final messageList = <Map<String, String>>[];
      for (final message in context) {
        String role = 'user';
        if (message.isUserMessage == false) {
          role = 'assistant';
        }
        messageList.add({
          'role': role,
          'content': message.content.trim(),
        });
      }
      // Debug AppLogger.debug the parsed messages
      AppLogger.debug('Parsed ${messageList.length} context messages:');
      for (var msg in messageList) {
        AppLogger.debug(
            '${msg['role']}: ${msg['content']?.substring(0, min(30, msg['content']!.length))}...');
      }
      return messageList;
    } catch (e) {
      AppLogger.debug('Error parsing context into messages: $e');
      return [];
    }
  }

  /// Send a request to Anthropic
  Future<String> _sendAnthropicRequest(String userInput,
      List<ChatMessageModel> context, config.AIServiceConfig config) async {
    try {
      final apiKey = await _getSecureApiKey(AIServiceType.anthropic);
      if (apiKey == null) {
        throw AIServiceException('Anthropic API key not found');
      }

      if (!_canMakeRequest(AIServiceType.anthropic)) {
        throw AIServiceException('Rate limit exceeded for Anthropic');
      }

      final selectedModel =
          await _selectOptimalModel(userInput, context, config);
      const maxRetries = 3;
      var retryCount = 0;
      var backoffDelay = const Duration(seconds: 1);

      // Add logging for Anthropic request parameters
      AppLogger.debug('Anthropic Request Parameters:');
      AppLogger.debug('Model: $selectedModel');
      AppLogger.debug('Messages: '
          '[{"role": "user", "content": "$context\n\n$userInput"}]');
      AppLogger.debug('Temperature: ${config.temperature}');
      AppLogger.debug('Max Tokens: ${config.maxTokens}');

      while (retryCount <= maxRetries) {
        try {
          final response = await _dio.post(
            'https://api.anthropic.com/v1/messages',
            data: {
              'model': selectedModel,
              'messages': [
                {'role': 'user', 'content': '$context\n\n$userInput'}
              ],
              'max_tokens': config.maxTokens,
              'temperature': config.temperature,
            },
            options: Options(
              headers: {
                'x-api-key': apiKey,
                'anthropic-version': '2024-01-01',
                'Content-Type': 'application/json',
              },
              sendTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

          final responseData = response.data;
          return responseData['content'][0]['text'] as String;
        } on DioException catch (e) {
          if (e.response?.statusCode == 429 || e.response?.statusCode == 500) {
            if (retryCount == maxRetries) rethrow;
            await Future.delayed(backoffDelay);
            backoffDelay *= 2;
            retryCount++;
            continue;
          }
          rethrow;
        }
      }

      throw AIServiceException('Max retries exceeded for Anthropic request');
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException(
          'Failed to generate Anthropic response: ${e.toString()}');
    }
  }

  /// Send a request to OpenRouter with enhanced error handling and model selection
  Future<String> _sendOpenRouterRequest(String userInput,
      List<ChatMessageModel> context, config.AIServiceConfig config) async {
    try {
      final apiKey = await _getSecureApiKey(AIServiceType.openRouter);
      if (apiKey == null) {
        throw AIServiceException('OpenRouter API key not found');
      }

      if (!_canMakeRequest(AIServiceType.openRouter)) {
        throw AIServiceException('Rate limit exceeded for OpenRouter');
      }

      final selectedModel =
          await _selectOptimalModel(userInput, context, config);
      const maxRetries = 3;
      var retryCount = 0;
      var backoffDelay = const Duration(seconds: 1);

      // Adjust parameters based on the model
      int maxTokens = config.maxTokens;
      double temperature = config.temperature;

      // Model-specific adjustments
      if (selectedModel.contains('claude-3')) {
        maxTokens = 1000; // Claude models can handle longer responses
      } else if (selectedModel.contains('gpt-4')) {
        maxTokens = 800; // GPT-4 models get slightly more tokens
      } else if (selectedModel.contains('llama3-70b')) {
        maxTokens = 600; // Llama models get moderate tokens
      }

      // Add logging for OpenRouter request parameters
      AppLogger.debug('OpenRouter Request Parameters:');
      AppLogger.debug('Model: $selectedModel');
      AppLogger.debug('Messages: '
          '[{"role": "system", "content": "You are a thoughtful, wise, and Islamic guidance assistant helping someone overcome temptations. Provide kind, helpful, encouraging advice based on Islamic principles and psychology. Your advice should be supportive, practical, and grounded in both religious wisdom and evidence-based approaches to behavior change. Use appropriate Quranic verses or hadith where relevant. Speak with compassion and without judgment. Keep responses concise but helpful."}, {"role": "user", "content": "Context about my situation: $context"}, {"role": "user", "content": "$userInput"}]');
      AppLogger.debug('Temperature: $temperature');
      AppLogger.debug('Max Tokens: $maxTokens');

      while (retryCount <= maxRetries) {
        try {
          final response = await _dio.post(
            'https://openrouter.ai/api/v1/chat/completions',
            data: {
              'model': selectedModel,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a thoughtful, wise, and Islamic guidance assistant helping someone overcome temptations. Provide kind, helpful, encouraging advice based on Islamic principles and psychology. Your advice should be supportive, practical, and grounded in both religious wisdom and evidence-based approaches to behavior change. Use appropriate Quranic verses or hadith where relevant. Speak with compassion and without judgment. Keep responses concise but helpful.'
                },
                {
                  'role': 'user',
                  'content': 'Context about my situation: $context'
                },
                {'role': 'user', 'content': userInput}
              ],
              'temperature': temperature,
              'max_tokens': maxTokens,
              'request_timeout': 60, // Timeout in seconds
            },
            options: Options(
              headers: {
                'Authorization': 'Bearer $apiKey',
                'HTTP-Referer': 'https://temptation-destroyer.app',
                'X-Title': 'Temptation Destroyer',
                'Content-Type': 'application/json',
              },
              sendTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 60),
            ),
          );

          final responseData = response.data;
          return responseData['choices'][0]['message']['content'] as String;
        } on DioException catch (e) {
          if (e.response?.statusCode == 429 || e.response?.statusCode == 500) {
            if (retryCount == maxRetries) rethrow;
            await Future.delayed(backoffDelay);
            backoffDelay *= 2;
            retryCount++;
            continue;
          }
          rethrow;
        }
      }

      throw AIServiceException('Max retries exceeded for OpenRouter request');
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException(
          'Failed to generate OpenRouter response: ${e.toString()}');
    }
  }

  /// Select the optimal model based on input complexity and availability
  Future<String> _selectOptimalModel(String userInput,
      List<ChatMessageModel> context, config.AIServiceConfig config) async {
    // If user has specified a model, use it
    if (config.preferredModel != null &&
        getAvailableModels(config.serviceType)
            .contains(config.preferredModel)) {
      return config.preferredModel!;
    }

    // Calculate total input length
    final totalLength = userInput.length + context.length;

    // Select model based on service type and complexity
    switch (config.serviceType) {
      case AIServiceType.openAI:
        if (totalLength > 2000) {
          return 'gpt-4'; // For long/complex inputs
        } else {
          return 'gpt-3.5-turbo'; // For shorter inputs
        }

      case AIServiceType.anthropic:
        if (totalLength > 2000) {
          return 'claude-3-opus';
        } else if (totalLength > 500) {
          return 'claude-3-sonnet';
        } else {
          return 'claude-3-haiku';
        }

      case AIServiceType.openRouter:
        if (totalLength > 2000) {
          return 'claude-3-opus';
        } else if (totalLength > 500) {
          return 'claude-3-sonnet';
        } else {
          return 'claude-3-haiku';
        }

      case AIServiceType.offline:
        return 'offline';

      default:
        return 'Offline';
    }
  }

  /// Get a fallback response when AI services are unavailable or there's an error
  Future<ChatMessageModel> _getFallbackResponse(
      String userInput, List<ChatMessageModel> context, ChatSession? session,
      {String? errorMessage}) async {
    // If we have a specific error message, use it
    if (errorMessage != null) {
      // Format the error message for better readability
      String formattedError = "⚠️ Error: ";

      // Remove "Exception:" prefix if it exists
      if (errorMessage.startsWith("Exception:")) {
        errorMessage = errorMessage.substring(10).trim();
      }

      // Clean up common error messages
      if (errorMessage.contains("AIServiceException")) {
        errorMessage = errorMessage.replaceAll("AIServiceException: ", "");
      }

      // Format the error message
      formattedError += errorMessage;

      // Add helpful advice based on error type
      if (errorMessage.contains("API key")) {
        formattedError += "\n\nPlease go to Settings and check your API key.";
      } else if (errorMessage.contains("rate limit") ||
          errorMessage.contains("429")) {
        formattedError +=
            "\n\nThe AI service is currently overloaded. Please try again in a few minutes.";
      } else if (errorMessage.contains("timeout") ||
          errorMessage.contains("network")) {
        formattedError +=
            "\n\nPlease check your internet connection and try again.";
      } else if (errorMessage.toLowerCase().contains("insufficient credit") ||
          errorMessage.toLowerCase().contains("quota") ||
          errorMessage.toLowerCase().contains("credits")) {
        formattedError +=
            "\n\nYou have insufficient credits on your account. Please check your API service dashboard.";
      }

      final message = ChatMessageModel(
        content: formattedError,
        isUserMessage: false,
        role: 'assistant',
        wasHelpful: null,
        session: session,
        isError: true,
      );

      // Ensure error messages are also encrypted
      await storeMessageAsync(message);

      return message;
    }

    // Default fallback responses if no specific error
    final responses = [
      'I apologize, but I am currently in offline mode. Please try again later when online services are available.',
      'I am currently operating in offline mode. Please check your internet connection and API settings.',
      'Sorry, I cannot provide a detailed response at the moment as I am in offline mode.',
    ];

    final message = ChatMessageModel(
      content: responses[Random().nextInt(responses.length)],
      isUserMessage: false,
      role: 'assistant',
      wasHelpful: null,
      session: session,
    );

    // Ensure fallback responses are also encrypted
    await storeMessageAsync(message);

    return message;
  }

  /// Save a chat message
  int saveChatMessage(ChatMessageModel message) {
    if (_encryptionService.isInitialized) {
      final encryptedContent = _encryptionService.encrypt(message.content);
      message = message.copyWith(
        content: encryptedContent,
        isEncrypted: true,
      );
    }
    return _chatBox.put(message);
  }

  /// Get a chat message by ID
  ChatMessageModel? getChatMessage(int id) {
    final message = _chatBox.get(id);
    if (message != null &&
        message.isEncrypted &&
        _encryptionService.isInitialized) {
      final decryptedContent = _encryptionService.decrypt(message.content);
      return message.copyWith(
        content: decryptedContent,
        isEncrypted: false,
      );
    }
    return message;
  }

  /// Update a chat message
  bool updateChatMessage(ChatMessageModel message) {
    return _chatBox.put(message) > 0;
  }

  /// Get all chat messages
  List<ChatMessageModel> getAllChatMessages() {
    return _chatBox.getAll();
  }

  /// Get chat history
  List<ChatMessageModel> getChatHistory() {
    final messages = _chatBox.getAll();
    return messages.map((message) {
      if (message.isEncrypted && _encryptionService.isInitialized) {
        final decryptedContent = _encryptionService.decrypt(message.content);
        return message.copyWith(
          content: decryptedContent,
          isEncrypted: false,
        );
      }
      return message;
    }).toList();
  }

  /// Get recent chat history limited by count
  List<ChatMessageModel> getRecentChatHistory(int limit) {
    final query = _chatBox
        .query()
        .order(ChatMessageModel_.timestamp, flags: Order.descending)
        .build()
      ..limit = limit;

    final messages = query.find();
    query.close();

    // Sort chronologically (oldest first)
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Decrypt messages if encryption is initialized
    if (_encryptionService.isInitialized) {
      return messages.map((message) {
        if (message.isEncrypted) {
          final decryptedContent = _encryptionService.decrypt(message.content);
          return message.copyWith(
            content: decryptedContent,
            isEncrypted: false,
          );
        }
        return message;
      }).toList();
    }

    return messages;
  }

  /// Delete chat messages older than specified days
  int deleteOldChatMessages(int olderThanDays) {
    final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

    final query = _chatBox
        .query(ChatMessageModel_.timestamp
            .lessThan(cutoffDate.millisecondsSinceEpoch))
        .build();

    final oldMessages = query.find();
    query.close();

    int count = 0;
    for (final message in oldMessages) {
      if (_chatBox.remove(message.id)) {
        count++;
      }
    }

    return count;
  }

  /// Get the AI service configuration
  config.AIServiceConfig getServiceConfig() {
    // First check for active session configuration
    final aiServiceState = _ref.read(aiServiceProvider);
    if (aiServiceState.activeSession != null) {
      // If we have an active session, use its configuration
      return config.AIServiceConfig.fromChatSession(
          aiServiceState.activeSession!);
    }

    // Otherwise use the global configuration
    return _ref.read(aiServiceProvider).config;
  }

  /// Save the AI service configuration
  void saveServiceConfig(config.AIServiceConfig newConfig) {
    // We don't need to update the provider state here anymore
    // This was causing a circular dependency
    // Just update the session if we have an active one
    try {
      final aiServiceState = _ref.read(aiServiceProvider);
      if (aiServiceState.activeSession != null) {
        final session = aiServiceState.activeSession!;
        final updatedSession = session.copyWith(
          serviceType: newConfig.serviceType,
          preferredModel: newConfig.preferredModel,
          allowDataTraining: newConfig.allowDataTraining,
          temperature: newConfig.temperature,
          maxTokens: newConfig.maxTokens,
        );
        updateChatSession(updatedSession);
      }
    } catch (e) {
      AppLogger.debug('Error in saveServiceConfig: $e');
    }
  }

  /// Get available models for the selected service with pricing info
  List<Map<String, dynamic>> getAvailableModelsWithPricing(String serviceType) {
    if (serviceType == AIServiceType.openAI) {
      return [
        {
          'id': 'gpt-3.5-turbo',
          'name': 'GPT-3.5 Turbo',
          'cost_per_1k_tokens': 0.0015,
        },
        {
          'id': 'gpt-4',
          'name': 'GPT-4',
          'cost_per_1k_tokens': 0.03,
        },
        {
          'id': 'gpt-4-turbo',
          'name': 'GPT-4 Turbo',
          'cost_per_1k_tokens': 0.01,
        },
      ];
    } else if (serviceType == AIServiceType.anthropic) {
      return [
        {
          'id': 'claude-3-haiku',
          'name': 'Claude 3 Haiku',
          'cost_per_1k_tokens': 0.0025,
        },
        {
          'id': 'claude-3-sonnet',
          'name': 'Claude 3 Sonnet',
          'cost_per_1k_tokens': 0.008,
        },
        {
          'id': 'claude-3-opus',
          'name': 'Claude 3 Opus',
          'cost_per_1k_tokens': 0.015,
        },
      ];
    } else if (serviceType == AIServiceType.openRouter) {
      return [
        {
          'id': 'gpt-3.5-turbo',
          'name': 'GPT-3.5 Turbo',
          'cost_per_1k_tokens': 0.001,
        },
        {
          'id': 'gpt-4',
          'name': 'GPT-4',
          'cost_per_1k_tokens': 0.025,
        },
        {
          'id': 'claude-3-haiku',
          'name': 'Claude 3 Haiku',
          'cost_per_1k_tokens': 0.002,
        },
        {
          'id': 'claude-3-sonnet',
          'name': 'Claude 3 Sonnet',
          'cost_per_1k_tokens': 0.007,
        },
        {
          'id': 'claude-3-opus',
          'name': 'Claude 3 Opus',
          'cost_per_1k_tokens': 0.013,
        },
        {
          'id': 'mistral-medium',
          'name': 'Mistral Medium',
          'cost_per_1k_tokens': 0.002,
        },
        {
          'id': 'llama3-70b',
          'name': 'Llama 3 70B',
          'cost_per_1k_tokens': 0.0008,
        },
      ];
    } else if (serviceType == AIServiceType.offline) {
      return [];
    } else {
      return [];
    }
  }

  /// Get available models for the selected service (IDs only)
  List<String> getAvailableModels(String serviceType) {
    return getAvailableModelsWithPricing(serviceType)
        .map((model) => model['id'] as String)
        .toList();
  }

  /// Delete all AI data (responses and chat history)
  void deleteAllAIData() {
    _chatBox.removeAll();
  }

  /// Get chat messages with pagination
  Future<List<ChatMessageModel>> getChatMessages({
    ChatSession? session,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final query = _chatBox.query()
        ..order(ChatMessageModel_.timestamp, flags: Order.descending);

      if (session != null) {
        query.link(
          ChatMessageModel_.session,
          ChatSession_.id.equals(session.id),
        );
      }

      final builtQuery = query.build();
      builtQuery.offset = offset;
      builtQuery.limit = limit;
      final messages = builtQuery.find().reversed.toList();
      builtQuery.close();

      // Decrypt messages if encryption is initialized
      if (_encryptionService.isInitialized) {
        return messages.map((message) {
          if (message.isEncrypted) {
            final decryptedContent =
                _encryptionService.decrypt(message.content);
            return message.copyWith(
              content: decryptedContent,
              isEncrypted: false,
            );
          }
          return message;
        }).toList();
      }

      return messages;
    } catch (e) {
      AppLogger.debug('Error fetching chat messages: $e');
      return [];
    }
  }

  /// Get total count of chat messages
  Future<int> getChatMessageCount(ChatSession? session) async {
    try {
      final query = _chatBox.query();
      if (session != null) {
        query.link(
          ChatMessageModel_.session,
          ChatSession_.id.equals(session.id),
        );
      }
      final builtQuery = query.build();
      final count = builtQuery.count();
      builtQuery.close();
      return count;
    } catch (e) {
      AppLogger.debug('Error getting chat message count: $e');
      return 0;
    }
  }

  /// Store a chat message (async version)
  Future<void> storeMessageAsync(ChatMessageModel message) async {
    try {
      if (_encryptionService.isInitialized) {
        // Encrypt the message content
        final encryptedContent = _encryptionService.encrypt(message.content);
        message = message.copyWith(
          content: encryptedContent,
          isEncrypted: true,
        );
      }
      _chatBox.put(message);
    } catch (e) {
      AppLogger.debug('Error storing chat message: $e');
      rethrow;
    }
  }

  /// Create a new chat session
  Future<ChatSession> createChatSession({
    required String title,
    String sessionType = ChatSessionType.normal,
    String serviceType = AIServiceType.offline,
    String? topic,
  }) async {
    try {
      final session = ChatSession(
        title: title,
        sessionType: sessionType,
        serviceType: serviceType,
        topic: topic,
      );

      final box = ObjectBoxManager.instance.box<ChatSession>();
      box.put(session);
      return session;
    } catch (e) {
      AppLogger.debug('Error creating chat session: $e');
      rethrow;
    }
  }

  /// Get a chat session by ID
  Future<ChatSession?> getChatSession(int id) async {
    try {
      final box = ObjectBoxManager.instance.box<ChatSession>();
      return box.get(id);
    } catch (e) {
      AppLogger.debug('Error getting chat session: $e');
      return null;
    }
  }

  /// Get all chat sessions with optional filtering
  Future<List<ChatSession>> getChatSessions({
    bool includeArchived = false,
    String? type,
    bool onlyEmergency = false,
  }) async {
    try {
      final box = ObjectBoxManager.instance.box<ChatSession>();
      QueryBuilder<ChatSession> query;

      if (!includeArchived) {
        query = box.query(ChatSession_.isArchived.equals(false));
      } else {
        query = box.query();
      }

      if (type != null) {
        final typeQuery = box.query(ChatSession_.sessionType.equals(type));
        query = typeQuery;
      }

      query.order(ChatSession_.lastModified, flags: Order.descending);

      final builtQuery = query.build();
      final sessions = builtQuery.find();
      builtQuery.close();
      return sessions;
    } catch (e) {
      AppLogger.debug('Error getting chat sessions: $e');
      return [];
    }
  }

  /// Update a chat session
  Future<void> updateChatSession(ChatSession session) async {
    try {
      final box = ObjectBoxManager.instance.box<ChatSession>();
      session.touch(); // Update lastModified
      box.put(session);
    } catch (e) {
      AppLogger.debug('Error updating chat session: $e');
      rethrow;
    }
  }

  /// Delete a chat session and its messages
  Future<void> deleteChatSession(int sessionId) async {
    try {
      final box = ObjectBoxManager.instance.box<ChatSession>();

      // Delete associated messages first
      final messageQuery = _chatBox.query()
        ..link(
          ChatMessageModel_.session,
          ChatSession_.id.equals(sessionId),
        );
      final messagesToDelete = messageQuery.build().find();

      _chatBox.removeMany(messagesToDelete.map((m) => m.id).toList());

      // Then delete the session
      box.remove(sessionId);
    } catch (e) {
      AppLogger.debug('Error deleting chat session: $e');
      rethrow;
    }
  }

  /// Update message rating
  Future<void> updateMessageRating(String messageId, bool wasHelpful) async {
    try {
      final query =
          _chatBox.query(ChatMessageModel_.uid.equals(messageId)).build();
      final message = query.findFirst();
      query.close();

      if (message != null) {
        // Create updated message with rating
        final updatedMessage = message.copyWith(wasHelpful: wasHelpful);

        // If the message is already encrypted, ensure we maintain encryption
        if (message.isEncrypted && _encryptionService.isInitialized) {
          _chatBox.put(updatedMessage);
        } else {
          // Otherwise use storeMessageAsync to handle encryption
          await storeMessageAsync(updatedMessage);
        }
      }
    } catch (e) {
      AppLogger.debug('Error updating message rating: $e');
      rethrow;
    }
  }

  /// Generate a streaming response from the AI
  Stream<String> generateStreamingResponse({
    required String userInput,
    required List<ChatMessageModel> context,
    config.AIServiceConfig? config,
    ChatSession? session,
  }) async* {
    AppLogger.debug('\n=== AI Repository: Generating Streaming Response ===');
    AppLogger.debug('User input length: ${userInput.length}');
    AppLogger.debug('Context length: ${context.length}');

    // Get the current AI service config if not provided
    final serviceConfig = config ?? getServiceConfig();
    AppLogger.debug('Service type: ${serviceConfig.serviceType}');
    AppLogger.debug('Model: ${serviceConfig.preferredModel ?? "default"}');

    // Don't check for API key if we're in offline mode
    if (serviceConfig.serviceType == AIServiceType.offline) {
      AppLogger.debug('Using offline mode');
      yield 'I am currently in offline mode. Please switch to an online AI service for more personalized guidance.';
      return;
    }

    try {
      // Get API key from secure storage
      final apiKey = await _getSecureApiKey(serviceConfig.serviceType);
      if (apiKey == null || apiKey.isEmpty) {
        AppLogger.debug('No API key found, returning error message');
        yield "⚠️ Error: No API key found for ${serviceConfig.serviceType}. Please add your API key in the settings.";
        return;
      }

      // Validate API key
      final isValid = await _validateApiKey(serviceConfig.serviceType, apiKey);
      if (!isValid) {
        AppLogger.debug('Invalid API key, returning error message');
        yield "⚠️ Error: Invalid API key format for ${serviceConfig.serviceType}. Please check your API key in the settings.";
        return;
      }

      // Check rate limiting
      if (!_canMakeRequest(serviceConfig.serviceType)) {
        AppLogger.debug('Rate limit exceeded');
        yield "⚠️ Error: Rate limit exceeded for ${serviceConfig.serviceType}. Please try again in a minute.";
        return;
      }

      // Create a config copy with the secure API key
      final secureConfig = serviceConfig.copyWith(apiKey: apiKey);

      AppLogger.debug('\nSending streaming request to AI service...');
      // Send the streaming request to the appropriate AI service
      try {
        await for (final chunk in _sendStreamingRequestToAIService(
          userInput: userInput,
          context: context,
          config: secureConfig,
        )) {
          yield chunk;
        }
      } catch (e) {
        // If there's an error during streaming, yield an error message
        yield "⚠️ Error: ${e.toString()}";
      }
    } catch (e) {
      AppLogger.debug('Error generating AI response: $e');
      yield "⚠️ Error: ${e.toString()}";
    }
  }

  /// Send a streaming request to the selected AI service
  Stream<String> _sendStreamingRequestToAIService({
    required String userInput,
    required List<ChatMessageModel> context,
    required config.AIServiceConfig config,
  }) async* {
    AppLogger.debug('\n=== Sending Streaming Request to AI Service ===');
    AppLogger.debug('Service type: ${config.serviceType}');
    AppLogger.debug('Model: ${config.preferredModel ?? "default"}');

    try {
      if (config.serviceType == AIServiceType.openAI) {
        AppLogger.debug('Sending streaming request to OpenAI...');
        await for (final chunk
            in _sendOpenAIStreamingRequest(userInput, context, config)) {
          yield chunk;
        }
      } else if (config.serviceType == AIServiceType.anthropic) {
        AppLogger.debug('Sending streaming request to Anthropic...');
        await for (final chunk
            in _sendAnthropicStreamingRequest(userInput, context, config)) {
          yield chunk;
        }
      } else if (config.serviceType == AIServiceType.openRouter) {
        AppLogger.debug('Sending streaming request to OpenRouter...');
        await for (final chunk
            in _sendOpenRouterStreamingRequest(userInput, context, config)) {
          yield chunk;
        }
      } else if (config.serviceType == AIServiceType.offline) {
        AppLogger.debug('Using offline mode');
        yield "I'm currently in offline mode. Please switch to an online AI service for more personalized guidance.";
      } else {
        AppLogger.debug('Unknown AI service type');
        yield "Unknown AI service type. Please switch to a supported AI service.";
      }
    } catch (e) {
      AppLogger.debug('Error in streaming request: $e');
      if (e is AIServiceException) {
        yield "⚠️ Error: ${e.message}";
      } else {
        yield "⚠️ Error: ${e.toString()}";
      }
    }
  }

  /// Send a streaming request to OpenAI
  Stream<String> _sendOpenAIStreamingRequest(String userInput,
      List<ChatMessageModel> context, config.AIServiceConfig config) async* {
    try {
      final apiKey = await _getSecureApiKey(AIServiceType.openAI);
      if (apiKey == null) {
        throw AIServiceException('OpenAI API key not found');
      }

      // Add logging for OpenAI request parameters
      AppLogger.debug('OpenAI Streaming Request Parameters:');
      AppLogger.debug('Model: ${config.preferredModel}');
      AppLogger.debug('Temperature: ${config.temperature}');
      AppLogger.debug('Max Tokens: ${config.maxTokens}');

      // Send the streaming request using Dio SSE
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        data: {
          'model': config.preferredModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a thoughtful, wise, and Islamic guidance assistant helping someone overcome temptations. Provide kind, helpful, encouraging advice based on Islamic principles and psychology. Your advice should be supportive, practical, and grounded in both religious wisdom and evidence-based approaches to behavior change. Use appropriate Quranic verses or hadith where relevant. Speak with compassion and without judgment.'
            },
            ...buildContextMessages(context),
            {'role': 'user', 'content': userInput}
          ],
          'temperature': config.temperature,
          'max_tokens': config.maxTokens,
          'stream': true, // Enable streaming
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      // Process the stream
      final stream = response.data.stream;
      await for (List<int> chunk in stream) {
        final String decodedChunk = String.fromCharCodes(chunk);

        // Split by newline and process each SSE
        for (String line in decodedChunk.split('\n')) {
          if (line.startsWith('data: ') && line != 'data: [DONE]') {
            // Extract the JSON data
            String jsonData = line.substring(6);
            try {
              Map<String, dynamic> data = jsonDecode(jsonData);
              if (data['choices'] != null &&
                  data['choices'][0]['delta'] != null &&
                  data['choices'][0]['delta']['content'] != null) {
                yield data['choices'][0]['delta']['content'] as String;
              }
            } catch (e) {
              AppLogger.debug('Error parsing SSE chunk: $e');
            }
          }
        }
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 429) {
          throw AIServiceException('Rate limit exceeded for OpenAI');
        } else if (e.response?.statusCode == 401) {
          throw AIServiceException('Invalid API key for OpenAI');
        } else {
          throw AIServiceException('OpenAI error: ${e.message}');
        }
      }
      throw AIServiceException('OpenAI streaming error: ${e.toString()}');
    }
  }

  /// Send a streaming request to Anthropic
  Stream<String> _sendAnthropicStreamingRequest(String userInput,
      List<ChatMessageModel> context, config.AIServiceConfig config) async* {
    try {
      final apiKey = await _getSecureApiKey(AIServiceType.anthropic);
      if (apiKey == null) {
        throw AIServiceException('Anthropic API key not found');
      }

      final selectedModel =
          await _selectOptimalModel(userInput, context, config);

      // Add logging for Anthropic request parameters
      AppLogger.debug('Anthropic Streaming Request Parameters:');
      AppLogger.debug('Model: $selectedModel');
      AppLogger.debug('Temperature: ${config.temperature}');
      AppLogger.debug('Max Tokens: ${config.maxTokens}');

      // Send the streaming request using Dio SSE
      final response = await _dio.post(
        'https://api.anthropic.com/v1/messages',
        data: {
          'model': selectedModel,
          'messages': [
            {'role': 'user', 'content': '$context\n\n$userInput'}
          ],
          'max_tokens': config.maxTokens,
          'temperature': config.temperature,
          'stream': true, // Enable streaming
        },
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2024-01-01',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      // Process the stream
      final stream = response.data.stream;
      await for (List<int> chunk in stream) {
        final String decodedChunk = String.fromCharCodes(chunk);

        // Split by newline and process each SSE
        for (String line in decodedChunk.split('\n')) {
          if (line.startsWith('data: ') && !line.contains('event_type')) {
            // Extract the JSON data
            String jsonData = line.substring(6);
            try {
              Map<String, dynamic> data = jsonDecode(jsonData);
              if (data['type'] == 'content_block_delta' &&
                  data['delta'] != null &&
                  data['delta']['text'] != null) {
                yield data['delta']['text'] as String;
              }
            } catch (e) {
              AppLogger.debug('Error parsing Anthropic SSE chunk: $e');
            }
          }
        }
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 429) {
          throw AIServiceException('Rate limit exceeded for Anthropic');
        } else if (e.response?.statusCode == 401) {
          throw AIServiceException('Invalid API key for Anthropic');
        } else {
          throw AIServiceException('Anthropic error: ${e.message}');
        }
      }
      throw AIServiceException('Anthropic streaming error: ${e.toString()}');
    }
  }

  /// Send a streaming request to OpenRouter
  Stream<String> _sendOpenRouterStreamingRequest(String userInput,
      List<ChatMessageModel> context, config.AIServiceConfig config) async* {
    try {
      final apiKey = await _getSecureApiKey(AIServiceType.openRouter);
      if (apiKey == null) {
        throw AIServiceException('OpenRouter API key not found');
      }

      final selectedModel =
          await _selectOptimalModel(userInput, context, config);

      // Adjust parameters based on the model
      int maxTokens = config.maxTokens;
      double temperature = config.temperature;

      // Model-specific adjustments
      if (selectedModel.contains('claude-3')) {
        maxTokens = 1000; // Claude models can handle longer responses
      } else if (selectedModel.contains('gpt-4')) {
        maxTokens = 800; // GPT-4 models get slightly more tokens
      } else if (selectedModel.contains('llama3-70b')) {
        maxTokens = 600; // Llama models get moderate tokens
      }

      // Add logging for OpenRouter request parameters
      AppLogger.debug('OpenRouter Streaming Request Parameters:');
      AppLogger.debug('Model: $selectedModel');
      AppLogger.debug('Temperature: $temperature');
      AppLogger.debug('Max Tokens: $maxTokens');

      // Send the streaming request using Dio SSE
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        data: {
          'model': selectedModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a thoughtful, wise, and Islamic guidance assistant helping someone overcome temptations. Provide kind, helpful, encouraging advice based on Islamic principles and psychology. Your advice should be supportive, practical, and grounded in both religious wisdom and evidence-based approaches to behavior change. Use appropriate Quranic verses or hadith where relevant. Speak with compassion and without judgment. Keep responses concise but helpful.'
            },
            {'role': 'user', 'content': 'Context about my situation: $context'},
            {'role': 'user', 'content': userInput}
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': true, // Enable streaming
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://temptation-destroyer.app',
            'X-Title': 'Temptation Destroyer',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      // Process the stream
      final stream = response.data.stream;
      await for (List<int> chunk in stream) {
        final String decodedChunk = String.fromCharCodes(chunk);

        // Split by newline and process each SSE
        for (String line in decodedChunk.split('\n')) {
          if (line.startsWith('data: ') && line != 'data: [DONE]') {
            // Extract the JSON data
            String jsonData = line.substring(6);
            try {
              Map<String, dynamic> data = jsonDecode(jsonData);
              if (data['choices'] != null &&
                  data['choices'][0]['delta'] != null &&
                  data['choices'][0]['delta']['content'] != null) {
                yield data['choices'][0]['delta']['content'] as String;
              }
            } catch (e) {
              AppLogger.debug('Error parsing OpenRouter SSE chunk: $e');
            }
          }
        }
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 429) {
          throw AIServiceException('Rate limit exceeded for OpenRouter');
        } else if (e.response?.statusCode == 401) {
          throw AIServiceException('Invalid API key for OpenRouter');
        } else {
          throw AIServiceException('OpenRouter error: ${e.message}');
        }
      }
      throw AIServiceException('OpenRouter streaming error: ${e.toString()}');
    }
  }

  /// Clear chat history
  Future<void> clearChatHistory() async {
    // Clear messages
    await _chatBox.removeAllAsync();
  }
}
