import '../../data/models/ai_models.dart';
import '../../data/models/chat_session_model.dart';

/// Configuration class for AI services
class AIServiceConfig {
  /// The type of AI service to use
  final AIServiceType serviceType;

  /// The API key for the service (optional)
  final String? apiKey;

  /// Preferred model for the service (optional)
  final String? preferredModel;

  /// Whether to allow data training
  final bool allowDataTraining;

  /// Temperature for response generation (0.0 to 1.0)
  final double temperature;

  /// Maximum tokens for response generation
  final int maxTokens;

  /// Constructor
  const AIServiceConfig({
    this.serviceType = AIServiceType.offline,
    this.apiKey,
    this.preferredModel,
    this.allowDataTraining = false,
    this.temperature = 1.0,
    this.maxTokens = 2048,
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
  }) {
    return AIServiceConfig(
      serviceType: serviceType ?? this.serviceType,
      apiKey: apiKey ?? this.apiKey,
      preferredModel: preferredModel ?? this.preferredModel,
      allowDataTraining: allowDataTraining ?? this.allowDataTraining,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }

  /// Create a config from a chat session
  factory AIServiceConfig.fromChatSession(ChatSession session) {
    return AIServiceConfig(
      serviceType: session.serviceType,
      preferredModel: session.preferredModel,
      allowDataTraining: session.allowDataTraining,
      temperature: session.temperature,
      maxTokens: session.maxTokens,
    );
  }

  /// Apply this config to a chat session
  ChatSession applyToSession(ChatSession session) {
    return session.copyWith(
      serviceType: serviceType,
      preferredModel: preferredModel,
      allowDataTraining: allowDataTraining,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }
}
