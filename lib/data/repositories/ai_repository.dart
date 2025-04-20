import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:math';

import '../../core/utils/object_box_manager.dart';
import '../../core/security/secure_storage_service.dart';
import '../models/ai_models.dart';
import '../models/chat_session_model.dart';
import '../../objectbox.g.dart';

/// Repository for handling AI-related operations
class AIRepository {
  final SecureStorageService _secureStorage;
  final Box<AIResponseModel> _responseBox;
  final Box<ChatMessageModel> _chatBox;
  final Box<ChatHistorySettings> _settingsBox;
  final Box<AIServiceConfig> _configBox;
  final Dio _dio;

  // Rate limiting configuration
  static const _maxRequestsPerMinute = 60;
  final Map<AIServiceType, List<DateTime>> _requestTimestamps = {};

  /// Constructor
  AIRepository()
      : _secureStorage = SecureStorageService.instance,
        _responseBox = ObjectBoxManager.instance.box<AIResponseModel>(),
        _chatBox = ObjectBoxManager.instance.box<ChatMessageModel>(),
        _settingsBox = ObjectBoxManager.instance.box<ChatHistorySettings>(),
        _configBox = ObjectBoxManager.instance.box<AIServiceConfig>(),
        _dio = Dio() {
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
        // If the key is encrypted, decrypt it
        if (config.isEncrypted) {
          return ObjectBoxManager.decryptString(config.apiKey!);
        }
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
  Future<AIResponseModel> generateResponse({
    required String userInput,
    required String context,
    AIServiceConfig? config,
  }) async {
    print('\n=== AI Repository: Generating Response ===');
    print('User input length: ${userInput.length}');
    print('Context length: ${context.length}');

    // Get the current AI service config if not provided
    final serviceConfig = config ?? getServiceConfig();
    print('Service type: ${serviceConfig.serviceType}');
    print('Model: ${serviceConfig.preferredModel ?? "default"}');
    print('Temperature: ${serviceConfig.temperature}');
    print('Max tokens: ${serviceConfig.maxTokens}');

    // Don't check for API key if we're in offline mode
    if (serviceConfig.serviceType == AIServiceType.offline) {
      print('Using offline mode');
      return _getFallbackResponse(userInput, context);
    }

    try {
      // Get API key from secure storage
      final apiKey = await _getSecureApiKey(serviceConfig.serviceType);
      if (apiKey == null || apiKey.isEmpty) {
        print('No API key found, falling back to offline mode');
        return _getFallbackResponse(userInput, context);
      }

      // Validate API key
      final isValid = await _validateApiKey(serviceConfig.serviceType, apiKey);
      if (!isValid) {
        print('Invalid API key, falling back to offline mode');
        return _getFallbackResponse(userInput, context);
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

      // Create and save the AI response
      final aiResponse = AIResponseModel(
        context: context,
        response: response,
        wasHelpful: false, // Will be updated by user feedback
      );

      // Cache the response for offline use if needed
      _cacheResponse(aiResponse);

      print('=== AI Repository: Response Generation Complete ===\n');
      return aiResponse;
    } catch (e) {
      print('Error generating AI response: $e');
      // Return a fallback response on error
      return _getFallbackResponse(userInput, context);
    }
  }

  /// Send a request to the selected AI service with retry logic
  Future<String> _sendRequestToAIService({
    required String userInput,
    required String context,
    required AIServiceConfig config,
  }) async {
    print('\n=== Sending Request to AI Service ===');
    print('Service type: ${config.serviceType}');
    print('Model: ${config.preferredModel ?? "default"}');

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
  Future<String> _sendOpenAIRequest(
      String userInput, String context, AIServiceConfig config) async {
    try {
      final apiKey = await _getSecureApiKey(AIServiceType.openAI);
      if (apiKey == null) {
        throw AIServiceException('OpenAI API key not found');
      }

      if (!_canMakeRequest(AIServiceType.openAI)) {
        throw AIServiceException('Rate limit exceeded for OpenAI');
      }

      final selectedModel =
          await _selectOptimalModel(userInput, context, config);
      final maxRetries = 3;
      var retryCount = 0;
      var backoffDelay = const Duration(seconds: 1);

      // Debug print the context being sent
      print('Context being sent to OpenAI:');
      print(context);

      while (retryCount <= maxRetries) {
        try {
          final response = await _dio.post(
            'https://api.openai.com/v1/chat/completions',
            data: {
              'model': selectedModel,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a thoughtful, wise, and Islamic guidance assistant helping someone overcome temptations. Provide kind, helpful, encouraging advice based on Islamic principles and psychology. Your advice should be supportive, practical, and grounded in both religious wisdom and evidence-based approaches to behavior change. Use appropriate Quranic verses or hadith where relevant. Speak with compassion and without judgment.'
                },
                // Parse the context into previous messages
                ...buildContextMessages(context),
                // Add the current user message
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

  /// Build context messages from a string representation of previous messages
  List<Map<String, String>> buildContextMessages(String context) {
    if (context.isEmpty) {
      return [];
    }

    try {
      // Try to split the context into separate messages based on typical patterns
      final messageList = <Map<String, String>>[];
      final lines = context.split('\n');
      String currentMessage = '';
      String currentRole = 'system';

      for (var line in lines) {
        // Skip empty lines
        if (line.trim().isEmpty) {
          continue;
        }

        // Check for role markers
        if (line.startsWith('User:') || line.contains('User said:')) {
          // If we have a current message, add it before starting a new one
          if (currentMessage.isNotEmpty) {
            messageList
                .add({'role': currentRole, 'content': currentMessage.trim()});
            currentMessage = '';
          }
          currentRole = 'user';
          // Remove the prefix to get just the message content
          currentMessage =
              line.replaceAll(RegExp(r'User:?|User said:?'), '').trim();
        } else if (line.startsWith('Assistant:') ||
            line.contains('Assistant said:')) {
          // If we have a current message, add it before starting a new one
          if (currentMessage.isNotEmpty) {
            messageList
                .add({'role': currentRole, 'content': currentMessage.trim()});
            currentMessage = '';
          }
          currentRole = 'assistant';
          // Remove the prefix to get just the message content
          currentMessage = line
              .replaceAll(RegExp(r'Assistant:?|Assistant said:?'), '')
              .trim();
        } else {
          // Continue the current message
          currentMessage += (currentMessage.isEmpty ? '' : '\n') + line;
        }
      }

      // Add the last message if there is one
      if (currentMessage.isNotEmpty) {
        messageList
            .add({'role': currentRole, 'content': currentMessage.trim()});
      }

      // If we couldn't parse any messages, treat the whole context as a system message
      if (messageList.isEmpty) {
        return [
          {'role': 'system', 'content': context}
        ];
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
      // If there's an error in parsing, treat the whole context as a system message
      return [
        {'role': 'system', 'content': context}
      ];
    }
  }

  /// Send a request to Anthropic
  Future<String> _sendAnthropicRequest(
      String userInput, String context, AIServiceConfig config) async {
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
      final maxRetries = 3;
      var retryCount = 0;
      var backoffDelay = const Duration(seconds: 1);

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
  Future<String> _sendOpenRouterRequest(
      String userInput, String context, AIServiceConfig config) async {
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
      final maxRetries = 3;
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
  Future<String> _selectOptimalModel(
      String userInput, String context, AIServiceConfig config) async {
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

  /// Cache the AI response for offline use
  void _cacheResponse(AIResponseModel response) {
    if (response.isEncrypted) {
      saveAIResponse(response);
    } else {
      // Only encrypt if we're using encryption
      if (ObjectBoxManager.instance.isEncrypted) {
        // Encrypt sensitive fields
        response.context = ObjectBoxManager.encryptString(response.context);
        response.response = ObjectBoxManager.encryptString(response.response);
        response.isEncrypted = true;
      }

      saveAIResponse(response);
    }
  }

  /// Save an AI response to the database
  int saveAIResponse(AIResponseModel response) {
    return _responseBox.put(response);
  }

  /// Get a specific AI response by ID
  AIResponseModel? getAIResponse(int id) {
    final response = _responseBox.get(id);
    return _decryptAIResponseIfNeeded(response);
  }

  /// Update an AI response (e.g., to mark it as helpful)
  bool updateAIResponse(AIResponseModel response) {
    // Encrypt if needed
    if (!response.isEncrypted && ObjectBoxManager.instance.isEncrypted) {
      response.context = ObjectBoxManager.encryptString(response.context);
      response.response = ObjectBoxManager.encryptString(response.response);
      response.isEncrypted = true;
    }

    return _responseBox.put(response) > 0;
  }

  /// Get a fallback response when offline or on error
  AIResponseModel _getFallbackResponse(String userInput, String context) {
    // Create list of fallback responses for different scenarios
    final fallbackResponses = [
      "Remember that Allah is with those who are patient. Whatever challenge you're facing, try to seek refuge in prayer and dhikr. The Prophet Muhammad (peace be upon him) said: 'Whoever Allah wishes good for, He puts them to trial.'",
      "In times of difficulty, try to remember the verse: 'And Allah is with you wherever you are.' (Qur'an 57:4). Perhaps taking a moment for deep breathing, prayer, or reaching out to a trusted friend could help.",
      "The Prophet (peace be upon him) taught us to say 'Astaghfirullah' (I seek forgiveness from Allah) when we're struggling. Combined with practical actions like changing your environment or engaging in a beneficial activity, this can help overcome the current challenge.",
      "Consider taking a few moments to pray two raka'at of voluntary prayer. The Prophet (peace be upon him) would turn to prayer in times of distress. After prayer, try to engage in a hobby or activity that brings you joy and keeps you away from temptation.",
      "When facing a trial, remember the hadith: 'Wonderful is the affair of the believer, for there is good in every affair of his.' Try to identify what this situation is teaching you, and take practical steps to protect yourself.",
    ];

    // Try to match the input with a relevant response
    String fallbackResponse;
    if (userInput.contains('urgent') || context.contains('emergency')) {
      fallbackResponse =
          "During urgent moments of temptation, immediately change your environment. Step outside, call someone trustworthy, or engage in dhikr. Remember that immediate distraction followed by prayer is one of the most effective strategies the Prophet (peace be upon him) taught us for overcoming temptation.";
    } else if (userInput.contains('sad') ||
        userInput.contains('depress') ||
        context.contains('sad') ||
        context.contains('depress')) {
      fallbackResponse =
          "During times of sadness, remember the Prophet's (peace be upon him) dua: 'O Allah, I seek refuge in You from anxiety and grief.' Consider speaking to a trusted friend or counselor about your feelings. Combining spiritual practices with social support and possibly professional help is an approach aligned with Islamic principles of comprehensive wellbeing.";
    } else {
      // Select a random fallback response if no specific match
      fallbackResponse = fallbackResponses[
          DateTime.now().millisecondsSinceEpoch % fallbackResponses.length];
    }

    return AIResponseModel(
      context: context,
      response: fallbackResponse,
      wasHelpful: false,
    );
  }

  /// Decrypt AI response if needed
  AIResponseModel? _decryptAIResponseIfNeeded(AIResponseModel? response) {
    if (response == null) return null;

    if (response.isEncrypted) {
      // Create a decrypted copy
      final decrypted = response.copyWith(
        context: ObjectBoxManager.decryptString(response.context),
        response: ObjectBoxManager.decryptString(response.response),
        isEncrypted: false,
      );
      return decrypted;
    }

    return response;
  }

  /// Get all AI responses
  List<AIResponseModel> getAllAIResponses() {
    final responses = _responseBox.getAll();
    return responses
        .map((response) => _decryptAIResponseIfNeeded(response)!)
        .toList();
  }

  /// Store a chat message
  int storeChatMessage(ChatMessageModel message) {
    if (!message.isEncrypted && ObjectBoxManager.instance.isEncrypted) {
      message.content = ObjectBoxManager.encryptString(message.content);
      message.isEncrypted = true;
    }

    return _chatBox.put(message);
  }

  /// Get chat history
  List<ChatMessageModel> getChatHistory() {
    final messages = _chatBox.getAll();
    return messages
        .map((message) => _decryptChatMessageIfNeeded(message)!)
        .toList();
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

    return messages
        .map((message) => _decryptChatMessageIfNeeded(message)!)
        .toList();
  }

  /// Decrypt chat message if needed
  ChatMessageModel? _decryptChatMessageIfNeeded(ChatMessageModel? message) {
    if (message == null) return null;

    if (message.isEncrypted) {
      // Create a decrypted copy
      final decrypted = message.copyWith(
        content: ObjectBoxManager.decryptString(message.content),
        isEncrypted: false,
      );
      return decrypted;
    }

    return message;
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
  ChatHistorySettings getChatHistorySettings() {
    final allSettings = _settingsBox.getAll();

    if (allSettings.isEmpty) {
      // Create default settings if none exist
      final defaultSettings = ChatHistorySettings();
      _settingsBox.put(defaultSettings);
      return defaultSettings;
    }

    return allSettings.first;
  }

  /// Update chat history settings
  void updateChatHistorySettings(ChatHistorySettings settings) {
    _settingsBox.put(settings);
  }

  /// Get the AI service configuration
  AIServiceConfig getServiceConfig() {
    try {
      final query = _configBox.query();

      final builtQuery = query.build();
      final configs = builtQuery.find();
      builtQuery.close();

      if (configs.isEmpty) {
        // Create default config if none exists
        final defaultConfig = AIServiceConfig();
        _configBox.put(defaultConfig);
        return defaultConfig;
      }

      final config = configs.first;
      if (config.isEncrypted) {
        // Decrypt API key if encrypted
        return config.copyWith(
          apiKey: config.apiKey != null
              ? ObjectBoxManager.decryptString(config.apiKey!)
              : null,
          isEncrypted: false,
        );
      }

      return config;
    } catch (e) {
      debugPrint('Error getting service config: $e');
      return AIServiceConfig(); // Return default offline config
    }
  }

  /// Save the AI service configuration
  void saveServiceConfig(AIServiceConfig config) {
    try {
      // Remove any existing configs first
      final query = _configBox.query();
      final builtQuery = query.build();
      final existingConfigs = builtQuery.find();
      builtQuery.close();

      for (final existing in existingConfigs) {
        _configBox.remove(existing.id);
      }

      // Encrypt API key if needed
      if (!config.isEncrypted &&
          ObjectBoxManager.instance.isEncrypted &&
          config.apiKey != null) {
        config = config.copyWith(
          apiKey: ObjectBoxManager.encryptString(config.apiKey!),
          isEncrypted: true,
        );
      }

      // Save the new config
      _configBox.put(config);
    } catch (e) {
      debugPrint('Error saving service config: $e');
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
    _responseBox.removeAll();
    _chatBox.removeAll();

    // Update lastCleared in settings
    final settings = getChatHistorySettings();
    settings.lastCleared = DateTime.now();
    _settingsBox.put(settings);
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

  /// Clear all chat history
  Future<void> clearChatHistory() async {
    try {
      _chatBox.removeAll();
      final sessionBox = ObjectBoxManager.instance.box<ChatSession>();
      sessionBox.removeAll();
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
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
        message.wasHelpful = wasHelpful;
        _chatBox.put(message);
      }
    } catch (e) {
      debugPrint('Error updating message rating: $e');
      rethrow;
    }
  }
}
