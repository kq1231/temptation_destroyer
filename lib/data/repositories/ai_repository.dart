import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:math';

import '../../core/utils/object_box_manager.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/utils/encryption_service.dart';
import '../models/ai_models.dart';
import '../models/chat_session_model.dart';
import '../models/chat_history_settings_model.dart';
import '../../objectbox.g.dart';
import '../../core/config/ai_service_config.dart' as config;
import '../../presentation/providers/ai_service_provider.dart';

/// Repository for handling AI-related operations
class AIRepository {
  final SecureStorageService _secureStorage;
  final Box<ChatMessageModel> _chatBox;
  final Box<ChatHistorySettingsModel> _settingsBox;
  final Dio _dio;
  final EncryptionService _encryptionService = EncryptionService.instance;
  final dynamic _ref;

  // Rate limiting configuration
  static const _maxRequestsPerMinute = 60;
  final Map<AIServiceType, List<DateTime>> _requestTimestamps = {};

  /// Constructor
  AIRepository(dynamic ref)
      : _secureStorage = SecureStorageService.instance,
        _chatBox = ObjectBoxManager.instance.box<ChatMessageModel>(),
        _settingsBox =
            ObjectBoxManager.instance.box<ChatHistorySettingsModel>(),
        _dio = Dio(),
        _ref = ref {
    _initializeRequestTracking();
  }

  /// Initialize request tracking for rate limiting
  void _initializeRequestTracking() {
    for (final type in AIServiceType.values) {
      _requestTimestamps[type] = [];
    }
  }

  /// Check if we can make a request (rate limiting)
  bool _canMakeRequest(AIServiceType serviceType) {
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
  Future<String?> _getSecureApiKey(AIServiceType type) async {
    try {
      // First check if we have a key in the config
      final config = getServiceConfig();
      if (config.serviceType == type &&
          config.apiKey != null &&
          config.apiKey!.isNotEmpty) {
        return config.apiKey;
      }

      // If no key in config, try secure storage
      final key = await _secureStorage.getKey(type.toString());
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
      debugPrint('Error getting API key: $e');
      return null;
    }
  }

  /// Validate API key for a service
  Future<bool> _validateApiKey(AIServiceType type, String key) async {
    // TODO: Implement key validation logic for each service
    // For now, just check if it's not empty and has a valid format
    if (key.isEmpty) return false;

    switch (type) {
      case AIServiceType.openAI:
        return key.startsWith('sk-') && key.length > 20;
      case AIServiceType.anthropic:
        return key.startsWith('sk-ant-') && key.length > 20;
      case AIServiceType.openRouter:
        return key.length > 20;
      case AIServiceType.offline:
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
    print('\n=== AI Repository: Generating Response ===');
    print('User input length: ${userInput.length}');
    print('Context length: ${context.length}');
    print('User input: $userInput');
    print('Context: $context');

    // Get the current AI service config if not provided
    final serviceConfig = config ?? getServiceConfig();
    print('Service type: ${serviceConfig.serviceType}');
    print('Model: ${serviceConfig.preferredModel ?? "default"}');
    print('Temperature: ${serviceConfig.temperature}');
    print('Max tokens: ${serviceConfig.maxTokens}');

    // Don't check for API key if we're in offline mode
    if (serviceConfig.serviceType == AIServiceType.offline) {
      print('Using offline mode');
      return await _getFallbackResponse(userInput, context, session);
    }

    try {
      // Get API key from secure storage
      final apiKey = await _getSecureApiKey(serviceConfig.serviceType);
      if (apiKey == null || apiKey.isEmpty) {
        print('No API key found, falling back to offline mode');
        return await _getFallbackResponse(userInput, context, session);
      }

      // Validate API key
      final isValid = await _validateApiKey(serviceConfig.serviceType, apiKey);
      if (!isValid) {
        print('Invalid API key, falling back to offline mode');
        return await _getFallbackResponse(userInput, context, session);
      }

      // Check rate limiting
      if (!_canMakeRequest(serviceConfig.serviceType)) {
        print('Rate limit exceeded');
        throw Exception('Rate limit exceeded for ${serviceConfig.serviceType}');
      }

      // Create a config copy with the secure API key
      final secureConfig = serviceConfig.copyWith(apiKey: apiKey);

      print('\nSending request to AI service...');
      // Send the request to the appropriate AI service
      final response = await _sendRequestToAIService(
        userInput: userInput,
        context: context,
        config: secureConfig,
      );
      print('Received response of length: ${response.length}');

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

      print('=== AI Repository: Response Generation Complete ===\n');
      return chatMessage;
    } catch (e) {
      print('Error generating AI response: $e');
      // Return a fallback response on error
      return await _getFallbackResponse(userInput, context, session);
    }
  }

  /// Send a request to the selected AI service with retry logic
  Future<String> _sendRequestToAIService({
    required String userInput,
    required List<ChatMessageModel> context,
    required config.AIServiceConfig config,
  }) async {
    print('\n=== Sending Request to AI Service ===');
    print('Service type: ${config.serviceType}');
    print('Model: ${config.preferredModel ?? "default"}');
    print('Context: $context');

    int retryCount = 0;
    const maxRetries = 3;
    Duration retryDelay = const Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        String response;

        switch (config.serviceType) {
          case AIServiceType.openAI:
            print('Sending request to OpenAI...');
            response = await _sendOpenAIRequest(userInput, context, config);
            break;
          case AIServiceType.anthropic:
            print('Sending request to Anthropic...');
            response = await _sendAnthropicRequest(userInput, context, config);
            break;
          case AIServiceType.openRouter:
            print('Sending request to OpenRouter...');
            response = await _sendOpenRouterRequest(userInput, context, config);
            break;
          case AIServiceType.offline:
            print('Using offline mode');
            return "I'm currently in offline mode. Please switch to an online AI service for more personalized guidance.";
        }
        print('Request successful!');
        return response;
      } catch (e) {
        retryCount++;
        print('Request failed (attempt $retryCount/$maxRetries): $e');
        if (retryCount == maxRetries) {
          // If this was the last retry, rethrow the error
          rethrow;
        }
        // Wait before retrying, with exponential backoff
        print('Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
        retryDelay *= 2;
      }
    }

    throw Exception('Failed after $maxRetries retries');
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

      // Debug print the context being sent
      print('Context being sent to OpenAI:');
      print(context);

      // Add logging for OpenAI request parameters
      print('OpenAI Request Parameters:');
      print('Model: ${config.preferredModel}');
      print('Messages: ${buildContextMessages(context)}');
      print('Temperature: ${config.temperature}');
      print('Max Tokens: ${config.maxTokens}');

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
      // Debug print the parsed messages
      print('Parsed ${messageList.length} context messages:');
      for (var msg in messageList) {
        print(
            '${msg['role']}: ${msg['content']?.substring(0, min(30, msg['content']!.length))}...');
      }
      return messageList;
    } catch (e) {
      print('Error parsing context into messages: $e');
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
      print('Anthropic Request Parameters:');
      print('Model: $selectedModel');
      print('Messages: '
          '[{"role": "user", "content": "$context\n\n$userInput"}]');
      print('Temperature: ${config.temperature}');
      print('Max Tokens: ${config.maxTokens}');

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
      print('OpenRouter Request Parameters:');
      print('Model: $selectedModel');
      print('Messages: '
          '[{"role": "system", "content": "You are a thoughtful, wise, and Islamic guidance assistant helping someone overcome temptations. Provide kind, helpful, encouraging advice based on Islamic principles and psychology. Your advice should be supportive, practical, and grounded in both religious wisdom and evidence-based approaches to behavior change. Use appropriate Quranic verses or hadith where relevant. Speak with compassion and without judgment. Keep responses concise but helpful."}, {"role": "user", "content": "Context about my situation: $context"}, {"role": "user", "content": "$userInput"}]');
      print('Temperature: $temperature');
      print('Max Tokens: $maxTokens');

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
    }
  }

  /// Get a fallback response when AI services are unavailable
  Future<ChatMessageModel> _getFallbackResponse(String userInput,
      List<ChatMessageModel> context, ChatSession? session) async {
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

  /// Get chat history settings
  config.ChatHistorySettings getChatHistorySettings() {
    final allSettings = _settingsBox.getAll();

    if (allSettings.isEmpty) {
      // Create default settings if none exist
      final defaultSettings = ChatHistorySettingsModel();
      _settingsBox.put(defaultSettings);
      return config.ChatHistorySettings(
        storeChatHistory: defaultSettings.storeChatHistory,
        autoDeleteAfterDays: defaultSettings.autoDeleteAfterDays,
        lastCleared: defaultSettings.lastCleared,
      );
    }

    final dbSettings = allSettings.first;
    return config.ChatHistorySettings(
      storeChatHistory: dbSettings.storeChatHistory,
      autoDeleteAfterDays: dbSettings.autoDeleteAfterDays,
      lastCleared: dbSettings.lastCleared,
    );
  }

  /// Update chat history settings
  void updateChatHistorySettings(config.ChatHistorySettings settings) {
    // Get existing settings or create new
    var existingSettings =
        _settingsBox.getAll().firstOrNull ?? ChatHistorySettingsModel();

    // Update settings using copyWith
    existingSettings = existingSettings.copyWith(
      storeChatHistory: settings.storeChatHistory,
      autoDeleteAfterDays: settings.autoDeleteAfterDays,
      lastCleared: settings.lastCleared,
    );
    _settingsBox.put(existingSettings);
  }

  /// Clear chat history and update last cleared timestamp
  Future<void> clearChatHistory() async {
    // Get existing settings or create new
    var dbSettings =
        _settingsBox.getAll().firstOrNull ?? ChatHistorySettingsModel();

    // Update last cleared timestamp
    dbSettings = dbSettings.copyWith(
      lastCleared: DateTime.now(),
    );
    _settingsBox.put(dbSettings);

    // Clear messages
    await _chatBox.removeAllAsync();

    // Also update the current config with new settings
    saveServiceConfig(getServiceConfig().copyWith(
      settings: config.ChatHistorySettings(
        storeChatHistory: dbSettings.storeChatHistory,
        autoDeleteAfterDays: dbSettings.autoDeleteAfterDays,
        lastCleared: dbSettings.lastCleared,
      ),
    ));
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
      debugPrint('Error in saveServiceConfig: $e');
    }
  }

  /// Get available models for the selected service with pricing info
  List<Map<String, dynamic>> getAvailableModelsWithPricing(
      AIServiceType serviceType) {
    switch (serviceType) {
      case AIServiceType.openAI:
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
      case AIServiceType.anthropic:
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
      case AIServiceType.openRouter:
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
      case AIServiceType.offline:
        return [];
    }
  }

  /// Get available models for the selected service (IDs only)
  List<String> getAvailableModels(AIServiceType serviceType) {
    return getAvailableModelsWithPricing(serviceType)
        .map((model) => model['id'] as String)
        .toList();
  }

  /// Delete all AI data (responses and chat history)
  void deleteAllAIData() {
    _chatBox.removeAll();

    // Update lastCleared in settings
    var dbSettings =
        _settingsBox.getAll().firstOrNull ?? ChatHistorySettingsModel();
    dbSettings = dbSettings.copyWith(lastCleared: DateTime.now());
    _settingsBox.put(dbSettings);

    // Update config settings to match
    saveServiceConfig(getServiceConfig().copyWith(
      settings: config.ChatHistorySettings(
        storeChatHistory: dbSettings.storeChatHistory,
        autoDeleteAfterDays: dbSettings.autoDeleteAfterDays,
        lastCleared: dbSettings.lastCleared,
      ),
    ));
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
      debugPrint('Error fetching chat messages: $e');
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
      debugPrint('Error getting chat message count: $e');
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
      debugPrint('Error storing chat message: $e');
      rethrow;
    }
  }

  /// Create a new chat session
  Future<ChatSession> createChatSession({
    required String title,
    ChatSessionType sessionType = ChatSessionType.normal,
    AIServiceType serviceType = AIServiceType.offline,
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
      debugPrint('Error creating chat session: $e');
      rethrow;
    }
  }

  /// Get a chat session by ID
  Future<ChatSession?> getChatSession(int id) async {
    try {
      final box = ObjectBoxManager.instance.box<ChatSession>();
      return box.get(id);
    } catch (e) {
      debugPrint('Error getting chat session: $e');
      return null;
    }
  }

  /// Get all chat sessions with optional filtering
  Future<List<ChatSession>> getChatSessions({
    bool includeArchived = false,
    ChatSessionType? type,
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
        final typeQuery =
            box.query(ChatSession_.dbSessionType.equals(type.index));
        query = typeQuery;
      }

      query.order(ChatSession_.lastModified, flags: Order.descending);

      final builtQuery = query.build();
      final sessions = builtQuery.find();
      builtQuery.close();
      return sessions;
    } catch (e) {
      debugPrint('Error getting chat sessions: $e');
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
      debugPrint('Error updating chat session: $e');
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
      debugPrint('Error deleting chat session: $e');
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
      debugPrint('Error updating message rating: $e');
      rethrow;
    }
  }
}
