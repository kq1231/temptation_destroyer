import '../../data/models/ai_models.dart';

/// Chat history settings
class ChatHistorySettings {
  final bool storeChatHistory;
  final int autoDeleteAfterDays;
  final DateTime? lastCleared;

  const ChatHistorySettings({
    this.storeChatHistory = false,
    this.autoDeleteAfterDays = 30,
    this.lastCleared,
  });

  /// Create a copy with updated values
  ChatHistorySettings copyWith({
    bool? storeChatHistory,
    int? autoDeleteAfterDays,
    DateTime? lastCleared,
  }) {
    return ChatHistorySettings(
      storeChatHistory: storeChatHistory ?? this.storeChatHistory,
      autoDeleteAfterDays: autoDeleteAfterDays ?? this.autoDeleteAfterDays,
      lastCleared: lastCleared ?? this.lastCleared,
    );
  }
}

/// Configuration class for AI services
class AIServiceConfig {
  /// The type of AI service to use
  final AIServiceType serviceType;

  /// The API key for the service (optional)
  final String? apiKey;

  /// Whether the API key is encrypted
  final bool isEncrypted;

  /// Preferred model for the service (optional)
  final String? preferredModel;

  /// Whether to allow data training
  final bool allowDataTraining;

  /// Temperature for response generation (0.0 to 1.0)
  final double temperature;

  /// Maximum tokens for response generation
  final int maxTokens;

  /// Chat history settings
  final ChatHistorySettings settings;

  /// Constructor
  const AIServiceConfig({
    this.serviceType = AIServiceType.offline,
    this.apiKey,
    this.isEncrypted = false,
    this.preferredModel,
    this.allowDataTraining = false,
    this.temperature = 1.0,
    this.maxTokens = 2048,
    this.settings = const ChatHistorySettings(),
  });

  /// Create a copy with updated values
  AIServiceConfig copyWith({
    AIServiceType? serviceType,
    String? apiKey,
    bool? isEncrypted,
    String? preferredModel,
    bool? allowDataTraining,
    double? temperature,
    int? maxTokens,
    ChatHistorySettings? settings,
  }) {
    return AIServiceConfig(
      serviceType: serviceType ?? this.serviceType,
      apiKey: apiKey ?? this.apiKey,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      preferredModel: preferredModel ?? this.preferredModel,
      allowDataTraining: allowDataTraining ?? this.allowDataTraining,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      settings: settings ?? this.settings,
    );
  }
}
