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

  /// Get a fallback response for offline mode or errors
  AIResponseModel _getFallbackResponse(String userInput, String context) {
    // Get the most appropriate fallback response based on keywords
    final response = _selectFallbackResponse(userInput);

    return AIResponseModel(
      context: context,
      response: response,
      wasHelpful: false,
    );
  }

  /// Select a fallback response based on the user input
  String _selectFallbackResponse(String userInput) {
    final input = userInput.toLowerCase();

    // Check for keywords to provide more relevant offline responses
    if (input.contains('urge') ||
        input.contains('tempt') ||
        input.contains('relapse')) {
      return "When facing strong urges, remember Allah's words in Surah Yusuf: 'And I do not acquit myself. Indeed, the soul is a persistent enjoiner of evil, except those upon which my Lord has mercy.' Try to immediately change your environment, make wudu, and perform salah. Physical activity like push-ups can also help redirect energy. Remember, this moment will pass, and your future self will thank you for resisting.";
    } else if (input.contains('sad') ||
        input.contains('depress') ||
        input.contains('down')) {
      return "During times of sadness, recall the Prophet Muhammad's ﷺ teaching: 'No fatigue, nor disease, nor anxiety, nor sadness, nor hurt, nor distress befalls a Muslim, even if it were the prick he receives from a thorn, but that Allah expiates some of his sins for that.' Your feelings are valid, but they are temporary. Try to pray two rakats, make dua, and if possible, talk to a trusted friend or family member.";
    } else if (input.contains('lonely') || input.contains('alone')) {
      return "Loneliness can be difficult, but remember that Allah is always with you. The Prophet ﷺ said, 'Allah is with those whose hearts are broken.' Try to reach out to family or friends, attend the mosque if possible, or join Islamic community activities. Filling your time with beneficial activities like learning, exercise, or helping others can also reduce feelings of loneliness.";
    } else if (input.contains('guilt') || input.contains('shame')) {
      return "Feeling guilt after sin is a sign of faith. The Prophet ﷺ said: 'Remorse is repentance.' Allah loves those who turn back to Him in sincere repentance. Make istighfar (seeking forgiveness), perform wudu, pray two rakats of repentance, and resolve to do better. Remember that Allah's mercy encompasses all things.";
    } else if (input.contains('bored') || input.contains('boredom')) {
      return "Boredom can often lead to temptation. Consider engaging in beneficial activities like reading Quran, learning a new skill, physical exercise, or helping others. The Prophet ﷺ said: 'Take advantage of five before five: your youth before your old age, your health before your sickness, your wealth before your poverty, your free time before you are preoccupied, and your life before your death.'";
    } else if (input.contains('prayer') ||
        input.contains('salah') ||
        input.contains('worship')) {
      return "Prayer is a shield against temptation. The Quran states: 'Indeed, prayer prohibits immorality and wrongdoing' (29:45). If you're struggling with prayer, start with what you can manage consistently, even if it's just one prayer a day. Quality is more important than quantity. Remember to focus on your connection with Allah during prayer, rather than just going through the motions.";
    }

    // Default fallback response
    return "Remember that seeking help is a sign of strength, not weakness. The Prophet Muhammad ﷺ said: 'The strong person is not the one who overcomes people, but the one who overcomes their nafs (self).' Take a deep breath, make wudu, and try to change your environment. If possible, reach out to a trusted friend or family member for support. Allah does not burden a soul beyond what it can bear, and with every hardship comes ease.";
  }

  /// Store a chat message
  Future<int> storeChatMessage(ChatMessageModel message) async {
    // Check if chat storage is enabled
    final settings = getChatSettings();
    if (!settings.storeChatHistory) {
      return 0; // Don't store if disabled
    }

    // Encrypt if needed
    if (ObjectBoxManager.instance.isEncrypted && !message.isEncrypted) {
      message.content = ObjectBoxManager.encryptString(message.content);
      message.isEncrypted = true;
    }

    return _chatBox.put(message);
  }

  /// Get chat history
  List<ChatMessageModel> getChatHistory({
    int limit = 50,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Create query builder
    QueryBuilder<ChatMessageModel> qBuilder = _chatBox.query();

    if (startDate != null && endDate != null) {
      qBuilder = _chatBox.query(ChatMessageModel_.timestamp.between(
          startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch));
    } else if (startDate != null) {
      qBuilder = _chatBox.query(ChatMessageModel_.timestamp
          .greaterThan(startDate.millisecondsSinceEpoch));
    } else if (endDate != null) {
      qBuilder = _chatBox.query(
          ChatMessageModel_.timestamp.lessThan(endDate.millisecondsSinceEpoch));
    }

    // Add order by timestamp (descending)
    qBuilder.order(ChatMessageModel_.timestamp, flags: Order.descending);

    // Execute query with pagination
    final query = qBuilder.build()
      ..offset = offset
      ..limit = limit;

    final messages = query.find();
    query.close();

    // Decrypt if needed
    if (ObjectBoxManager.instance.isEncrypted) {
      for (final message in messages) {
        if (message.isEncrypted) {
          message.content = ObjectBoxManager.decryptString(message.content);
          message.isEncrypted = false; // Mark as decrypted in memory
        }
      }
    }

    return messages;
  }

  /// Clear chat history
  Future<void> clearChatHistory() async {
    _chatBox.removeAll();

    // Update last cleared timestamp
    final settings = getChatSettings();
    settings.lastCleared = DateTime.now();
    _settingsBox.put(settings);
  }

  /// Get chat settings, creating default if needed
  ChatHistorySettings getChatSettings() {
    // Try to get existing settings
    final List<ChatHistorySettings> settings = _settingsBox.getAll();
    if (settings.isNotEmpty) {
      return settings.first;
    }

    // Create default settings if none exist
    final defaultSettings = ChatHistorySettings();
    _settingsBox.put(defaultSettings);
    return defaultSettings;
  }

  /// Update chat settings
  Future<void> updateChatSettings(ChatHistorySettings settings) async {
    _settingsBox.put(settings);
  }

  /// Auto-delete chat messages older than the retention period
  Future<void> cleanupOldChatMessages() async {
    final settings = getChatSettings();
    if (!settings.storeChatHistory || settings.autoDeleteAfterDays <= 0) {
      return;
    }

    final cutoffDate = DateTime.now().subtract(
      Duration(days: settings.autoDeleteAfterDays),
    );

    final query = _chatBox
        .query(ChatMessageModel_.timestamp
            .lessThan(cutoffDate.millisecondsSinceEpoch))
        .build();

    final oldMessages = query.find();
    _chatBox.removeMany(oldMessages.map((m) => m.id).toList());
    query.close();
  }

  /// Get the current AI service configuration
  AIServiceConfig getServiceConfig() {
    final List<AIServiceConfig> configs = _configBox.getAll();
    if (configs.isNotEmpty) {
      final config = configs.first;

      // Decrypt API key if it's encrypted
      if (config.isEncrypted && config.apiKey != null) {
        config.apiKey = ObjectBoxManager.decryptString(config.apiKey!);
        config.isEncrypted = false; // Mark as decrypted in memory
      }

      return config;
    }

    // Create default config if none exists
    final defaultConfig = AIServiceConfig(
      serviceType: AIServiceType.offline,
    );
    _configBox.put(defaultConfig);
    return defaultConfig;
  }

  /// Save API service configuration
  Future<void> saveServiceConfig(AIServiceConfig config) async {
    // Encrypt API key if needed
    if (ObjectBoxManager.instance.isEncrypted &&
        !config.isEncrypted &&
        config.apiKey != null &&
        config.apiKey!.isNotEmpty) {
      config.apiKey = ObjectBoxManager.encryptString(config.apiKey!);
      config.isEncrypted = true;
    }

    _configBox.put(config);
  }

  /// Get available models for a service type
  List<String> getAvailableModels(AIServiceType serviceType) {
    switch (serviceType) {
      case AIServiceType.openAI:
        return [
          'gpt-3.5-turbo',
          'gpt-4',
          'gpt-4-turbo',
          'gpt-4o',
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
          'gpt-4-turbo',
          'gpt-4o',
          'claude-3-haiku-20240307',
          'claude-3-sonnet-20240229',
          'claude-3-opus-20240229',
          'mistral-7b-instruct',
          'llama-3-8b-instruct',
          'llama-3-70b-instruct',
        ];
      case AIServiceType.offline:
        return ['offline'];
    }
  }
}
