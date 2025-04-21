import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';
import 'chat_session_model.dart';

/// AI Service Type Enum
enum AIServiceType {
  offline, // Default, must be first (index 0)
  openAI,
  anthropic,
  openRouter,
}

/// Chat Message Model that represents a single message in a conversation
@Entity()
class ChatMessageModel {
  @Id()
  int id = 0;

  /// Unique identifier for the message
  @Unique()
  final String uid;

  /// The content of the message
  String content;

  /// Whether the message is from the user or AI
  bool isUserMessage;

  /// The role of the message sender (user, assistant, system)
  String role;

  /// When the message was sent
  @Property(type: PropertyType.date)
  DateTime timestamp;

  /// For encrypted storage
  bool isEncrypted = false;

  /// Whether the user marked this message as helpful
  bool? wasHelpful;

  /// Whether this message is an error message
  bool isError;

  /// The session this message belongs to
  final ToOne<ChatSession> session = ToOne<ChatSession>();

  ChatMessageModel({
    this.id = 0,
    String? uid,
    required this.content,
    required this.isUserMessage,
    String? role,
    DateTime? timestamp,
    this.wasHelpful,
    this.isError = false,
    ChatSession? session,
  })  : uid = uid ?? const Uuid().v4(),
        role = role ?? (isUserMessage ? 'user' : 'assistant'),
        timestamp = timestamp ?? DateTime.now() {
    if (session != null) {
      this.session.target = session;
    }
  }

  /// Create a copy with updated values
  ChatMessageModel copyWith({
    int? id,
    String? uid,
    String? content,
    bool? isUserMessage,
    String? role,
    DateTime? timestamp,
    bool? isEncrypted,
    bool? wasHelpful,
    bool? isError,
    ChatSession? session,
  }) {
    final copy = ChatMessageModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      content: content ?? this.content,
      isUserMessage: isUserMessage ?? this.isUserMessage,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      wasHelpful: wasHelpful ?? this.wasHelpful,
      isError: isError ?? this.isError,
      session: session ?? this.session.target,
    );
    copy.isEncrypted = isEncrypted ?? this.isEncrypted;
    return copy;
  }
}

/// Settings for Chat History
@Entity()
class ChatHistorySettings {
  @Id()
  int id = 0;

  /// Whether to store chat history
  bool storeChatHistory;

  /// Number of days after which to auto-delete chat history
  int autoDeleteAfterDays;

  /// When the chat history was last cleared
  @Property(type: PropertyType.date)
  DateTime lastCleared;

  ChatHistorySettings({
    this.id = 0,
    this.storeChatHistory = false,
    this.autoDeleteAfterDays = 30,
    DateTime? lastCleared,
  }) : lastCleared = lastCleared ?? DateTime.now();

  /// Create a copy with updated values
  ChatHistorySettings copyWith({
    int? id,
    bool? storeChatHistory,
    int? autoDeleteAfterDays,
    DateTime? lastCleared,
  }) {
    return ChatHistorySettings(
      id: id ?? this.id,
      storeChatHistory: storeChatHistory ?? this.storeChatHistory,
      autoDeleteAfterDays: autoDeleteAfterDays ?? this.autoDeleteAfterDays,
      lastCleared: lastCleared ?? this.lastCleared,
    );
  }
}

class AIServiceException implements Exception {
  final String message;

  AIServiceException(this.message);

  @override
  String toString() => message;
}

/// Model pricing information
class ModelPricing {
  final double promptPricePerToken; // Price per 1K prompt tokens in USD
  final double completionPricePerToken; // Price per 1K completion tokens in USD
  final int? contextWindow; // Maximum context window size
  final String? notes; // Additional pricing notes

  const ModelPricing({
    required this.promptPricePerToken,
    required this.completionPricePerToken,
    this.contextWindow,
    this.notes,
  });

  /// Calculate estimated cost for a given number of tokens
  double estimateCost({
    required int promptTokens,
    required int completionTokens,
  }) {
    return (promptTokens * promptPricePerToken +
            completionTokens * completionPricePerToken) /
        1000;
  }
}

/// Model performance metrics
class ModelPerformance {
  final double averageResponseTime; // Average response time in seconds
  final double tokenEfficiency; // Tokens per second processing rate
  final double qualityRating; // Quality rating out of 5
  final String strengths; // Model's strong points
  final String limitations; // Model's limitations

  const ModelPerformance({
    required this.averageResponseTime,
    required this.tokenEfficiency,
    required this.qualityRating,
    required this.strengths,
    required this.limitations,
  });
}

/// Extended model information
class ModelInfo {
  final String id;
  final String name;
  final String description;
  final ModelPricing pricing;
  final ModelPerformance performance;
  final String usageRecommendation;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.pricing,
    required this.performance,
    required this.usageRecommendation,
  });
}

/// Map of model information
const Map<String, ModelInfo> modelInfoMap = {
  'meta/llama3-70b-instruct': ModelInfo(
    id: 'meta/llama3-70b-instruct',
    name: 'Meta Llama 3 70B',
    description:
        'Latest Llama model with strong performance and good price/performance ratio',
    pricing: ModelPricing(
      promptPricePerToken: 0.0007,
      completionPricePerToken: 0.0007,
      contextWindow: 4096,
      notes: 'Good balance of cost and performance',
    ),
    performance: ModelPerformance(
      averageResponseTime: 2.5,
      tokenEfficiency: 15.0,
      qualityRating: 4.5,
      strengths: 'Fast responses, good reasoning, cost-effective',
      limitations: 'May occasionally hallucinate on complex topics',
    ),
    usageRecommendation:
        'Best for general guidance and medium-complexity tasks',
  ),
  'anthropic/claude-3-opus': ModelInfo(
    id: 'anthropic/claude-3-opus',
    name: 'Claude 3 Opus',
    description: 'Most capable Claude model with exceptional understanding',
    pricing: ModelPricing(
      promptPricePerToken: 0.015,
      completionPricePerToken: 0.075,
      contextWindow: 8192,
      notes: 'Premium pricing for highest quality responses',
    ),
    performance: ModelPerformance(
      averageResponseTime: 3.0,
      tokenEfficiency: 20.0,
      qualityRating: 5.0,
      strengths: 'Deep understanding, nuanced responses, excellent reasoning',
      limitations: 'Higher cost, slightly slower response time',
    ),
    usageRecommendation:
        'Ideal for complex spiritual guidance and deep theological discussions',
  ),
  'anthropic/claude-3-sonnet': ModelInfo(
    id: 'anthropic/claude-3-sonnet',
    name: 'Claude 3 Sonnet',
    description: 'Balanced Claude model with great capabilities',
    pricing: ModelPricing(
      promptPricePerToken: 0.003,
      completionPricePerToken: 0.015,
      contextWindow: 8192,
      notes: 'Good balance of cost and quality',
    ),
    performance: ModelPerformance(
      averageResponseTime: 2.0,
      tokenEfficiency: 18.0,
      qualityRating: 4.8,
      strengths: 'Fast, reliable, good understanding',
      limitations: 'Slightly less capable than Opus',
    ),
    usageRecommendation:
        'Great for most guidance needs and regular conversations',
  ),
};
