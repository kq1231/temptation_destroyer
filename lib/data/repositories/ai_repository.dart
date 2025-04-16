import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/object_box_manager.dart';
import '../models/ai_models.dart';
import '../../objectbox.g.dart';

/// Repository for handling AI-related operations
class AIRepository {
  final Box<AIResponseModel> _responseBox;
  final Box<ChatMessageModel> _chatBox;
  final Box<ChatHistorySettings> _settingsBox;
  final Box<AIServiceConfig> _configBox;

  /// Constructor
  AIRepository()
      : _responseBox = ObjectBoxManager.instance.box<AIResponseModel>(),
        _chatBox = ObjectBoxManager.instance.box<ChatMessageModel>(),
        _settingsBox = ObjectBoxManager.instance.box<ChatHistorySettings>(),
        _configBox = ObjectBoxManager.instance.box<AIServiceConfig>();

  /// Generate a response from the AI
  Future<AIResponseModel> generateResponse({
    required String userInput,
    required String context,
    AIServiceConfig? config,
  }) async {
    // Get the current AI service config if not provided
    final serviceConfig = config ?? getServiceConfig();

    if (serviceConfig.serviceType == AIServiceType.offline) {
      // Return a fallback response if using offline mode
      return _getFallbackResponse(userInput, context);
    }

    try {
      // Send the request to the appropriate AI service
      final response = await _sendRequestToAIService(
        userInput: userInput,
        context: context,
        config: serviceConfig,
      );

      // Create and save the AI response
      final aiResponse = AIResponseModel(
        context: context,
        response: response,
        wasHelpful: false, // Will be updated by user feedback
      );

      // Cache the response for offline use if needed
      _cacheResponse(aiResponse);

      return aiResponse;
    } catch (e) {
      debugPrint('Error generating AI response: $e');
      // Return a fallback response on error
      return _getFallbackResponse(userInput, context);
    }
  }

  /// Send a request to the selected AI service
  Future<String> _sendRequestToAIService({
    required String userInput,
    required String context,
    required AIServiceConfig config,
  }) async {
    switch (config.serviceType) {
      case AIServiceType.openAI:
        return _sendOpenAIRequest(userInput, context, config);
      case AIServiceType.anthropic:
        return _sendAnthropicRequest(userInput, context, config);
      case AIServiceType.openRouter:
        return _sendOpenRouterRequest(userInput, context, config);
      case AIServiceType.offline:
        return "I'm currently in offline mode. Please switch to an online AI service for more personalized guidance.";
    }
  }

  /// Send a request to OpenAI
  Future<String> _sendOpenAIRequest(
      String userInput, String context, AIServiceConfig config) async {
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      throw Exception('No API key provided for OpenAI');
    }

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    // Default to gpt-3.5-turbo if no model specified
    final model = config.preferredModel ?? 'gpt-3.5-turbo';

    // Construct the messages with context and user input
    final messages = [
      {
        'role': 'system',
        'content':
            'You are a thoughtful, wise, and Islamic guidance assistant helping someone overcome temptations. Provide kind, helpful, encouraging advice based on Islamic principles and psychology. Your advice should be supportive, practical, and grounded in both religious wisdom and evidence-based approaches to behavior change. Use appropriate Quranic verses or hadith where relevant. Speak with compassion and without judgment. Keep responses concise but helpful.'
      },
      {'role': 'user', 'content': 'Context about my situation: $context'},
      {'role': 'user', 'content': userInput}
    ];

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}'
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        debugPrint('OpenAI error: ${response.body}');
        throw Exception('Error calling OpenAI API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error with OpenAI request: $e');
      rethrow;
    }
  }

  /// Send a request to Anthropic
  Future<String> _sendAnthropicRequest(
      String userInput, String context, AIServiceConfig config) async {
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      throw Exception('No API key provided for Anthropic');
    }

    final uri = Uri.parse('https://api.anthropic.com/v1/messages');

    // Default to claude-3-haiku if no model specified
    final model = config.preferredModel ?? 'claude-3-haiku-20240307';

    // Construct the system prompt with Islamic guidance context
    const systemPrompt =
        'You are a thoughtful, wise, and Islamic guidance assistant helping someone overcome temptations. Provide kind, helpful, encouraging advice based on Islamic principles and psychology. Your advice should be supportive, practical, and grounded in both religious wisdom and evidence-based approaches to behavior change. Use appropriate Quranic verses or hadith where relevant. Speak with compassion and without judgment. Keep responses concise but helpful.';

    // Combine context and user input
    final userMessage = 'Context about my situation: $context\n\n$userInput';

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': config.apiKey!,
          'anthropic-version': '2023-06-01'
        },
        body: jsonEncode({
          'model': model,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage}
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'].trim();
      } else {
        debugPrint('Anthropic error: ${response.body}');
        throw Exception('Error calling Anthropic API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error with Anthropic request: $e');
      rethrow;
    }
  }

  /// Send a request to OpenRouter
  Future<String> _sendOpenRouterRequest(
      String userInput, String context, AIServiceConfig config) async {
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      throw Exception('No API key provided for OpenRouter');
    }

    final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    // Default to gpt-3.5-turbo if no model specified
    final model = config.preferredModel ?? 'gpt-3.5-turbo';

    // Construct the messages with context and user input
    final messages = [
      {
        'role': 'system',
        'content':
            'You are a thoughtful, wise, and Islamic guidance assistant helping someone overcome temptations. Provide kind, helpful, encouraging advice based on Islamic principles and psychology. Your advice should be supportive, practical, and grounded in both religious wisdom and evidence-based approaches to behavior change. Use appropriate Quranic verses or hadith where relevant. Speak with compassion and without judgment. Keep responses concise but helpful.'
      },
      {'role': 'user', 'content': 'Context about my situation: $context'},
      {'role': 'user', 'content': userInput}
    ];

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
          'HTTP-Referer':
              'https://temptation-destroyer.app' // Required by OpenRouter
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        debugPrint('OpenRouter error: ${response.body}');
        throw Exception('Error calling OpenRouter API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error with OpenRouter request: $e');
      rethrow;
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

  /// Clear chat history
  void clearChatHistory() {
    _chatBox.removeAll();

    // Update the last cleared date in settings
    final settings = getChatHistorySettings();
    settings.lastCleared = DateTime.now();
    _settingsBox.put(settings);
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
    final allConfigs = _configBox.getAll();

    if (allConfigs.isEmpty) {
      // Create default config if none exists
      final defaultConfig = AIServiceConfig();
      _configBox.put(defaultConfig);
      return defaultConfig;
    }

    final config = allConfigs.first;

    if (config.isEncrypted) {
      // Decrypt API key if encrypted
      final decrypted = config.copyWith(
        apiKey: config.apiKey != null
            ? ObjectBoxManager.decryptString(config.apiKey!)
            : null,
        isEncrypted: false,
      );
      return decrypted;
    }

    return config;
  }

  /// Save the AI service configuration
  void saveServiceConfig(AIServiceConfig config) {
    // Encrypt API key if needed
    if (!config.isEncrypted &&
        ObjectBoxManager.instance.isEncrypted &&
        config.apiKey != null) {
      config = config.copyWith(
        apiKey: ObjectBoxManager.encryptString(config.apiKey!),
        isEncrypted: true,
      );
    }

    _configBox.put(config);
  }

  /// Get available models for the selected service
  List<String> getAvailableModels(AIServiceType serviceType) {
    switch (serviceType) {
      case AIServiceType.openAI:
        return [
          'gpt-3.5-turbo',
          'gpt-4',
          'gpt-4-turbo',
        ];
      case AIServiceType.anthropic:
        return [
          'claude-3-haiku-20240307',
          'claude-3-sonnet-20240229',
          'claude-3-opus-20240229',
        ];
      case AIServiceType.openRouter:
        return [
          'gpt-3.5-turbo',
          'gpt-4',
          'claude-3-haiku',
          'claude-3-sonnet',
          'claude-3-opus',
          'mistral-medium',
          'llama3-70b',
        ];
      case AIServiceType.offline:
        return [];
    }
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
}
