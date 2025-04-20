import 'dart:math';
import 'package:tiktoken/tiktoken.dart';
import '../../data/models/ai_models.dart';

/// Manages the context window for AI chat interactions, including:
/// - Token counting and estimation
/// - Context selection and pruning
/// - Relevance scoring
/// - Emergency context detection
class ContextManager {
  // Default token limits for different models/services
  static final Map<AIServiceType, int> _defaultTokenLimits = {
    AIServiceType.offline: 2048, // Conservative default
    AIServiceType.openAI: 8192, // Updated GPT-3.5-Turbo default
    AIServiceType.anthropic: 200000, // Updated Claude default
    AIServiceType.openRouter: 8192, // Varies by model
  };

  // Model-specific token limits
  static const Map<String, int> _modelTokenLimits = {
    // OpenAI models
    'gpt-3.5-turbo': 8192, // Updated from 4096
    'gpt-4': 128000, // Updated from 8192
    'gpt-4-turbo': 128000,
    'gpt-4o': 128000, // Added
    'gpt-4o-mini': 128000, // Added
    'gpt-3': 4096, // Added
    'gpt-3-mini': 4096, // Added

    // Anthropic models
    'claude-instant-1': 100000,
    'claude-2': 100000,
    'claude-3-opus': 200000,
    'claude-3-sonnet': 200000,
    'claude-3-haiku': 200000,

    // Meta models
    'llama-2-70b': 4096,
    'llama-3-70b': 8192,
    'meta/llama3-70b-instruct': 128000, // Added for OpenRouter
    'meta/llama3-8b-instruct': 8192, // Added for OpenRouter

    // Mistral models
    'mistral-medium': 32768,
    'mistral-small': 32768,
    'mistralai/mistral-7b-instruct': 8192, // Added for OpenRouter

    // Google models
    'google/gemini-pro': 32000, // Added for OpenRouter
    'google/gemma-7b-it': 8192, // Added for OpenRouter

    // Others from OpenRouter
    'anthropic/claude-3-opus': 200000, // Added for OpenRouter
    'anthropic/claude-3-sonnet': 200000, // Added for OpenRouter
    'anthropic/claude-3-haiku': 200000, // Added for OpenRouter
    'openai/gpt-4': 128000, // Added for OpenRouter
    'openai/gpt-4-turbo': 128000, // Added for OpenRouter
    'openai/gpt-3.5-turbo': 8192, // Added for OpenRouter
    'cohere/command-r': 128000, // Added for OpenRouter
  };

  // Mapping of model types to tiktoken encodings
  final Map<String, Tiktoken?> _encodingCache = {};

  // Token overhead for system messages
  static const int _systemPromptOverhead = 200;

  // Maximum percentage of context to use for history (rest reserved for response)
  static const double _maxContextPercentage = 0.8;

  /// Gets the appropriate encoding for a model
  Tiktoken? _getEncodingForModel(String? modelId, AIServiceType serviceType) {
    // Return from cache if already loaded
    if (modelId != null && _encodingCache.containsKey(modelId)) {
      return _encodingCache[modelId];
    }

    try {
      // Get the appropriate encoding based on model or service type
      Tiktoken? encoding;

      if (modelId != null) {
        // Try to get encoding for the specific model
        try {
          encoding = encodingForModel(modelId);
          _encodingCache[modelId] = encoding;
          return encoding;
        } catch (e) {
          // Model not supported, will fall back to service type
        }
      }

      // Fall back to service type based encoding
      switch (serviceType) {
        case AIServiceType.openAI:
          encoding = getEncoding("cl100k_base"); // For newer GPT models
          break;
        case AIServiceType.anthropic:
          encoding =
              getEncoding("cl100k_base"); // Claude uses similar tokenization
          break;
        case AIServiceType.openRouter:
          encoding = getEncoding("cl100k_base"); // Most models use this
          break;
        case AIServiceType.offline:
          encoding = getEncoding("r50k_base"); // Fallback option
          break;
      }

      if (modelId != null) {
        _encodingCache[modelId] = encoding;
      }

      return encoding;
    } catch (e) {
      // If any error occurs, return null and we'll use fallback estimation
      return null;
    }
  }

  /// Counts tokens accurately using tiktoken
  /// Falls back to estimation if tiktoken fails
  int estimateTokenCount(String text,
      {String? modelId, AIServiceType? serviceType}) {
    if (text.isEmpty) return 0;

    // Try to use tiktoken for accurate counting
    if (modelId != null || serviceType != null) {
      final encoding =
          _getEncodingForModel(modelId, serviceType ?? AIServiceType.openAI);

      if (encoding != null) {
        try {
          final tokens = encoding.encode(text);
          return tokens.length;
        } catch (e) {
          // Fall back to estimation if tiktoken fails
        }
      }
    }

    // Fallback: estimate based on character count and language
    // Check if text contains significant Arabic content
    final arabicPattern = RegExp(r'[\u0600-\u06FF]');
    final arabicMatchCount = arabicPattern.allMatches(text).length;
    final arabicRatio = arabicMatchCount / text.length;

    // Use appropriate tokens-per-char ratio based on language composition
    final tokensPerChar = arabicRatio > 0.5 ? 0.2 : 0.25;

    // Add a small constant for token counting overhead
    return max(1, (text.length * tokensPerChar).ceil());
  }

  /// Gets the token limit for a specific service and model
  int getTokenLimit(AIServiceType serviceType, String? modelId) {
    // If model ID is provided and exists in our map, use that limit
    if (modelId != null && _modelTokenLimits.containsKey(modelId)) {
      return _modelTokenLimits[modelId]!;
    }

    // Otherwise fallback to service default
    return _defaultTokenLimits[serviceType] ??
        _defaultTokenLimits[AIServiceType.offline]!;
  }

  /// Calculates available context window size for new messages
  /// Takes into account the system prompt and reserves space for the response
  int getAvailableContextSize(
      AIServiceType serviceType, String? modelId, int systemPromptLength) {
    final totalTokenLimit = getTokenLimit(serviceType, modelId);

    // Use tiktoken for more accurate system prompt token count if possible
    final systemOverhead = max(
        _systemPromptOverhead,
        estimateTokenCount(systemPromptLength.toString(),
            modelId: modelId, serviceType: serviceType));

    // Reserve space for the response (20% by default)
    final availableForHistory =
        ((totalTokenLimit - systemOverhead) * _maxContextPercentage).floor();

    return max(0, availableForHistory);
  }

  /// Selects the most relevant messages to fit within the available context window
  /// Uses a combination of recency and relevance scoring
  List<ChatMessageModel> selectContext(
      List<ChatMessageModel> messages, int availableTokens,
      {String? currentQuery, String? modelId, AIServiceType? serviceType}) {
    if (messages.isEmpty) return [];

    // First, estimate token count for each message
    final messagesWithTokens = messages.map((message) {
      return MapEntry(
          message,
          estimateTokenCount(message.content,
              modelId: modelId, serviceType: serviceType));
    }).toList();

    // Always include the most recent messages
    final selectedMessages = <ChatMessageModel>[];
    int usedTokens = 0;

    // Process messages in reverse order (newest first)
    for (final entry in messagesWithTokens.reversed) {
      final message = entry.key;
      final tokenCount = entry.value;

      // Check if adding this message would exceed our token budget
      if (usedTokens + tokenCount <= availableTokens) {
        selectedMessages.insert(
            0, message); // Insert at beginning to maintain order
        usedTokens += tokenCount;
      } else {
        // If it's a very important message (like emergency related), try to include it
        if (_isHighPriorityMessage(message, currentQuery)) {
          // If it would fit on its own, add it
          if (tokenCount <= availableTokens) {
            selectedMessages.insert(0, message);
            usedTokens += tokenCount;
          }
        }
      }
    }

    return selectedMessages;
  }

  /// Determines if a message is high priority and should be included in context
  /// even if it means potentially excluding other messages
  bool _isHighPriorityMessage(ChatMessageModel message, String? currentQuery) {
    // Emergency-related keywords
    const emergencyKeywords = [
      'emergency',
      'urgent',
      'help',
      'crisis',
      'suicidal',
      'harm',
      'danger'
    ];

    // Check if message contains emergency keywords
    final lowerContent = message.content.toLowerCase();
    for (final keyword in emergencyKeywords) {
      if (lowerContent.contains(keyword)) {
        return true;
      }
    }

    // If we have a current query, check for similarity with this message
    if (currentQuery != null && currentQuery.isNotEmpty) {
      // Simple keyword matching (in a real app, use semantic similarity)
      final queryWords = currentQuery
          .toLowerCase()
          .split(' ')
          .where((word) => word.length > 3) // Only consider significant words
          .toSet();

      int matchCount = 0;
      for (final word in queryWords) {
        if (lowerContent.contains(word)) {
          matchCount++;
        }
      }

      // If more than 30% of significant query words match, consider it high priority
      if (queryWords.isNotEmpty && matchCount / queryWords.length > 0.3) {
        return true;
      }
    }

    return false;
  }

  /// Detects if the message content suggests an emergency situation
  bool isEmergencyContext(String content) {
    final lowerContent = content.toLowerCase();

    // Emergency phrases and keywords
    const emergencyPhrases = [
      'want to harm myself',
      'thinking of suicide',
      'want to die',
      'kill myself',
      'end my life',
      'harming myself',
      'in danger',
      'emergency',
      'urgent help',
      'crisis',
    ];

    // Check for emergency phrases
    for (final phrase in emergencyPhrases) {
      if (lowerContent.contains(phrase)) {
        return true;
      }
    }

    // Check for distress indicators
    final distressIndicators = [
      'overwhelmed',
      'anxious',
      'depressed',
      'hopeless',
      'stressed',
      'scared',
      'alone',
    ];

    for (final indicator in distressIndicators) {
      if (lowerContent.contains(indicator)) {
        return true;
      }
    }

    return false;
  }

  /// Generates a system prompt for emergency situations
  String getEmergencySystemPrompt() {
    return '''
You are a compassionate Islamic guidance assistant. The user appears to be in distress or a potential emergency situation.

IMPORTANT: You are not a licensed mental health professional or medical doctor. You should:
1. Respond with empathy and concern
2. Encourage the user to seek professional help immediately
3. Provide emergency contact information
4. Share relevant Islamic guidance on hope and patience
5. Avoid making specific medical or psychological diagnoses
6. Keep responses concise and focused on immediate support

Suggest the following resources:
- Emergency services: 911 (US), 999 (UK), or local equivalent
- Crisis helpline: 1-800-273-8255 (US National Suicide Prevention Lifeline)
- Text "HOME" to 741741 (Crisis Text Line)
- Suggest speaking to a trusted family member, friend, imam, or counselor

Your primary goal is to provide immediate support and guide them to professional help.
''';
  }

  /// Compresses chat history to fit within token limits while preserving key information
  String getCompressedHistory(List<ChatMessageModel> messages, int maxTokens) {
    if (messages.isEmpty) return '';

    // If we have just a few messages, format them normally
    if (messages.length <= 3) {
      return _formatMessagesForContext(messages);
    }

    // For longer histories, we'll summarize the older messages
    final recentMessages =
        messages.length > 3 ? messages.sublist(messages.length - 3) : messages;
    final olderMessages =
        messages.length > 3 ? messages.sublist(0, messages.length - 3) : [];

    final StringBuilder summaryBuilder = StringBuilder();

    // Add a summary of older messages
    if (olderMessages.isNotEmpty) {
      summaryBuilder.writeLine('Earlier conversation summary:');

      // Count user and assistant messages
      int userMessageCount = 0;
      int assistantMessageCount = 0;

      for (final message in olderMessages) {
        if (message.isUserMessage) {
          userMessageCount++;
        } else {
          assistantMessageCount++;
        }
      }

      summaryBuilder
          .writeLine('- $userMessageCount messages from the user, discussing:');

      // Extract key topics (just a sample - ideally use NLP)
      final userTopics = _extractKeyTopics(olderMessages
          .where((m) => m.isUserMessage)
          .toList()
          .cast<ChatMessageModel>());
      for (final topic in userTopics) {
        summaryBuilder.writeLine('  - $topic');
      }

      summaryBuilder.writeLine(
          '- $assistantMessageCount responses from the assistant, providing:');

      // Extract key advice points
      final assistantTopics = _extractKeyTopics(olderMessages
          .where((m) => !m.isUserMessage)
          .toList()
          .cast<ChatMessageModel>());
      for (final topic in assistantTopics) {
        summaryBuilder.writeLine('  - $topic');
      }

      summaryBuilder.writeLine('');
    }

    // Add the most recent messages verbatim
    summaryBuilder.writeLine('Most recent messages:');
    summaryBuilder.write(_formatMessagesForContext(recentMessages));

    final result = summaryBuilder.toString();

    // If still too long, truncate with a note
    if (estimateTokenCount(result) > maxTokens) {
      return 'Note: The conversation history is extensive. Here are just the most recent messages:\n\n${_formatMessagesForContext(recentMessages)}';
    }

    return result;
  }

  /// Formats messages for inclusion in context
  String _formatMessagesForContext(List<ChatMessageModel> messages) {
    final StringBuilder sb = StringBuilder();

    for (final message in messages) {
      final role = message.isUserMessage ? 'User' : 'Assistant';
      sb.writeLine('$role: ${message.content}');
      sb.writeLine('');
    }

    return sb.toString();
  }

  /// Extracts key topics from a list of messages
  /// This is a simplified version - in a real app, use NLP techniques
  List<String> _extractKeyTopics(List<ChatMessageModel> messages) {
    if (messages.isEmpty) return [];

    // Simple keyword extraction
    final allContent = messages.map((m) => m.content.toLowerCase()).join(' ');

    // Islamic and personal development related topics
    const potentialTopics = [
      'prayer',
      'salah',
      'fasting',
      'sawm',
      'zakat',
      'charity',
      'hajj',
      'quran',
      'hadith',
      'sunnah',
      'iman',
      'faith',
      'taqwa',
      'piety',
      'sabr',
      'patience',
      'addiction',
      'temptation',
      'struggle',
      'jihad',
      'nafs',
      'soul',
      'heart',
      'family',
      'marriage',
      'children',
      'parents',
      'work',
      'halal',
      'haram',
      'purification',
      'tazkiyah',
      'dhikr',
      'remembrance',
      'dua',
      'supplication',
      'forgiveness',
      'repentance',
      'tawbah',
      'stress',
      'anxiety',
      'depression',
      'health',
      'community',
      'ummah',
      'friends',
    ];

    final foundTopics = <String>[];
    for (final topic in potentialTopics) {
      if (allContent.contains(topic)) {
        // Capitalize first letter for presentation
        foundTopics.add(topic[0].toUpperCase() + topic.substring(1));

        // Limit to 5 topics
        if (foundTopics.length >= 5) break;
      }
    }

    // If we couldn't identify specific topics, provide a generic summary
    if (foundTopics.isEmpty) {
      final messageCount = messages.length;
      if (messageCount == 1) {
        return ['One brief message'];
      } else {
        return ['$messageCount messages on general topics'];
      }
    }

    return foundTopics;
  }

  /// Calculates a relevance score for a message in relation to a query
  /// Returns a score between 0 and 1
  double calculateRelevanceScore(String message, String query) {
    if (message.isEmpty || query.isEmpty) return 0.0;

    final messageWords = message.toLowerCase().split(' ').toSet();
    final queryWords = query.toLowerCase().split(' ').toSet();

    // Calculate word overlap
    final commonWords = messageWords.intersection(queryWords);
    final overlapScore = commonWords.length / queryWords.length;

    // Consider message length (prefer shorter, more focused messages)
    final lengthPenalty = message.length > 500 ? 0.2 : 0.0;

    // Consider recency (if timestamp is available)
    // This would be implemented based on your message model

    return (overlapScore - lengthPenalty).clamp(0.0, 1.0);
  }

  /// Compresses the context by summarizing or removing less relevant messages
  List<ChatMessageModel> compressContext(
      List<ChatMessageModel> messages, int targetTokenCount,
      {String? modelId, AIServiceType? serviceType}) {
    if (messages.isEmpty) return [];

    // First, calculate token count for each message
    final messagesWithTokens = messages.map((message) {
      return MapEntry(
          message,
          estimateTokenCount(message.content,
              modelId: modelId, serviceType: serviceType));
    }).toList();

    int totalTokens =
        messagesWithTokens.fold(0, (sum, entry) => sum + entry.value);

    // If we're already under target, return original messages
    if (totalTokens <= targetTokenCount) return messages;

    // Strategy 1: Remove alternate messages (keeping conversation flow)
    if (totalTokens > targetTokenCount * 2) {
      return messages
          .asMap()
          .entries
          .where((entry) => entry.key % 2 == 0)
          .map((entry) => entry.value)
          .toList();
    }

    // Strategy 2: Keep important messages
    final importantMessages = messages.where((message) {
      // Keep messages with emergency context
      if (_isHighPriorityMessage(message, null)) return true;

      // Keep messages with decisions or actions
      final lowerContent = message.content.toLowerCase();
      final actionKeywords = [
        'decided',
        'agreed',
        'will do',
        'plan',
        'next steps'
      ];
      return actionKeywords.any((keyword) => lowerContent.contains(keyword));
    }).toList();

    // Strategy 3: If still too large, keep most recent messages
    if (importantMessages.length > messages.length / 2) {
      final keepCount = (messages.length * 0.6).floor(); // Keep 60% of messages
      return messages.sublist(messages.length - keepCount);
    }

    return importantMessages;
  }

  /// Generates a summary of removed context
  String generateContextSummary(List<ChatMessageModel> removedMessages) {
    if (removedMessages.isEmpty) return '';

    final summary = StringBuffer();
    summary.writeln('Previous context summary:');

    // Group messages by role
    final userMessages = removedMessages
        .where((m) => m.role == 'user')
        .map((m) => m.content)
        .toList();
    final assistantMessages = removedMessages
        .where((m) => m.role == 'assistant')
        .map((m) => m.content)
        .toList();

    if (userMessages.isNotEmpty) {
      summary.writeln('User discussed: ${userMessages.join(', ')}');
    }

    if (assistantMessages.isNotEmpty) {
      summary.writeln(
          'Assistant provided guidance on: ${assistantMessages.join(', ')}');
    }

    return summary.toString();
  }

  /// Manages the context window for a conversation
  /// Returns a tuple of (selected messages, context summary)
  (List<ChatMessageModel>, String) manageContextWindow(
    List<ChatMessageModel> messages,
    AIServiceType serviceType,
    String? modelId,
    String? currentQuery,
    int systemPromptLength,
  ) {
    // Calculate available context size
    final availableTokens =
        getAvailableContextSize(serviceType, modelId, systemPromptLength);

    // Select initial context
    var selectedMessages = selectContext(messages, availableTokens,
        currentQuery: currentQuery, modelId: modelId, serviceType: serviceType);

    // If we need to compress, do so and generate summary
    final selectedTokenCount = selectedMessages.fold(
        0,
        (sum, message) =>
            sum +
            estimateTokenCount(message.content,
                modelId: modelId, serviceType: serviceType));

    if (selectedTokenCount > availableTokens) {
      final removedMessages =
          messages.where((m) => !selectedMessages.contains(m)).toList();
      selectedMessages = compressContext(selectedMessages, availableTokens,
          modelId: modelId, serviceType: serviceType);
      final summary = generateContextSummary(removedMessages);
      return (selectedMessages, summary);
    }

    return (selectedMessages, '');
  }
}

/// Simple string builder to efficiently build multi-line strings
class StringBuilder {
  final StringBuffer _buffer = StringBuffer();

  void write(String text) {
    _buffer.write(text);
  }

  void writeLine(String line) {
    _buffer.writeln(line);
  }

  @override
  String toString() {
    return _buffer.toString();
  }
}
