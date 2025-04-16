import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

/// AI Service Type Enum
enum AIServiceType {
  offline, // Default, must be first (index 0)
  openAI,
  anthropic,
  openRouter,
}

/// AI Response Model that stores AI responses with metadata
@Entity()
class AIResponseModel {
  @Id()
  int id = 0;

  /// Unique identifier for the response
  @Unique()
  final String uid;

  /// The context provided to the AI
  String context;

  /// The actual response from AI
  String response;

  /// When the response was generated
  @Property(type: PropertyType.date)
  DateTime timestamp;

  /// Whether the user marked this response as helpful
  bool wasHelpful;

  /// For encrypted storage
  bool isEncrypted = false;

  AIResponseModel({
    this.id = 0,
    String? uid,
    required this.context,
    required this.response,
    DateTime? timestamp,
    this.wasHelpful = false,
  })  : uid = uid ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Create a copy with updated values
  AIResponseModel copyWith({
    int? id,
    String? uid,
    String? context,
    String? response,
    DateTime? timestamp,
    bool? wasHelpful,
    bool? isEncrypted,
  }) {
    return AIResponseModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      context: context ?? this.context,
      response: response ?? this.response,
      timestamp: timestamp ?? this.timestamp,
      wasHelpful: wasHelpful ?? this.wasHelpful,
    )..isEncrypted = isEncrypted ?? this.isEncrypted;
  }
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

  /// When the message was sent
  @Property(type: PropertyType.date)
  DateTime timestamp;

  /// For encrypted storage
  bool isEncrypted = false;

  ChatMessageModel({
    this.id = 0,
    String? uid,
    required this.content,
    required this.isUserMessage,
    DateTime? timestamp,
  })  : uid = uid ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Create a copy with updated values
  ChatMessageModel copyWith({
    int? id,
    String? uid,
    String? content,
    bool? isUserMessage,
    DateTime? timestamp,
    bool? isEncrypted,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      content: content ?? this.content,
      isUserMessage: isUserMessage ?? this.isUserMessage,
      timestamp: timestamp ?? this.timestamp,
    )..isEncrypted = isEncrypted ?? this.isEncrypted;
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

/// AI Service Configuration model
@Entity()
class AIServiceConfig {
  @Id()
  int id = 0;

  @Unique()
  final String uid;

  /// The actual enum type as a transient property
  @Transient()
  AIServiceType? _serviceType;

  /// The service type is stored as an integer in the database
  int? get dbServiceType {
    _ensureStableEnumValues();
    return _serviceType?.index;
  }

  /// Setter for the service type integer
  set dbServiceType(int? value) {
    _ensureStableEnumValues();
    if (value == null) {
      _serviceType = null;
    } else {
      if (value >= 0 && value < AIServiceType.values.length) {
        _serviceType = AIServiceType.values[value];
      } else {
        _serviceType = AIServiceType.offline;
      }
    }
  }

  /// API key for the service
  String? apiKey;

  /// Preferred model for the service (e.g., gpt-4, claude-3, etc.)
  String? preferredModel;

  /// Whether to allow data to be used for training
  bool allowDataTraining;

  /// For encrypted storage
  bool isEncrypted = false;

  AIServiceConfig({
    this.id = 0,
    String? uid,
    AIServiceType serviceType = AIServiceType.offline,
    this.apiKey,
    this.preferredModel,
    this.allowDataTraining = false,
  }) : uid = uid ?? const Uuid().v4() {
    _serviceType = serviceType;
  }

  /// Get the service type as enum
  AIServiceType get serviceType => _serviceType ?? AIServiceType.offline;

  /// Set the service type from enum
  set serviceType(AIServiceType value) {
    _ensureStableEnumValues();
    _serviceType = value;
  }

  /// Create a copy with updated values
  AIServiceConfig copyWith({
    int? id,
    String? uid,
    AIServiceType? serviceType,
    String? apiKey,
    String? preferredModel,
    bool? allowDataTraining,
    bool? isEncrypted,
  }) {
    return AIServiceConfig(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      serviceType: serviceType ?? this.serviceType,
      apiKey: apiKey ?? this.apiKey,
      preferredModel: preferredModel ?? this.preferredModel,
      allowDataTraining: allowDataTraining ?? this.allowDataTraining,
    )..isEncrypted = isEncrypted ?? this.isEncrypted;
  }

  /// Ensure enum values have stable indices
  void _ensureStableEnumValues() {
    assert(AIServiceType.offline.index == 0);
    assert(AIServiceType.openAI.index == 1);
    assert(AIServiceType.anthropic.index == 2);
    assert(AIServiceType.openRouter.index == 3);
  }
}
