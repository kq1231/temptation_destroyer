import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';
import 'ai_models.dart';

/// Enum for chat session types
enum ChatSessionType {
  normal, // Regular chat session
  emergency, // Emergency support session
  guided, // Guided Islamic advice session
}

/// Model for managing chat sessions with metadata and encryption support
@Entity()
class ChatSession {
  @Id()
  int id = 0;

  /// Unique identifier for the session
  @Unique()
  final String uid;

  /// Title of the chat session
  String title;

  /// When the session was created
  @Property(type: PropertyType.date)
  DateTime createdAt;

  /// When the session was last modified
  @Property(type: PropertyType.date)
  DateTime lastModified;

  /// The type of chat session
  @Transient()
  ChatSessionType? _sessionType;

  /// The session type stored as an integer in the database
  int? get dbSessionType {
    _ensureStableEnumValues();
    return _sessionType?.index;
  }

  set dbSessionType(int? value) {
    _ensureStableEnumValues();
    if (value == null) {
      _sessionType = null;
    } else {
      if (value >= 0 && value < ChatSessionType.values.length) {
        _sessionType = ChatSessionType.values[value];
      } else {
        _sessionType = ChatSessionType.normal;
      }
    }
  }

  /// Topic or category of the session
  String? topic;

  /// Number of messages in the session
  int messageCount;

  /// Whether the session content is encrypted
  bool isEncrypted;

  /// Encryption key for the session (if encrypted)
  String? encryptionKey;

  /// Tags for categorizing and searching
  List<String> tags;

  /// The AI service type used for this session
  @Transient()
  AIServiceType? _serviceType;

  /// The service type stored as an integer in the database
  int? get dbServiceType {
    _ensureStableEnumValues();
    return _serviceType?.index;
  }

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

  /// Selected AI model for this session
  String? selectedModel;

  /// Whether the session is archived
  bool isArchived;

  /// Whether the session is marked as favorite
  bool isFavorite;

  /// Custom metadata as JSON string
  String? metadata;

  /// Preferred AI model for this session
  String? preferredModel;

  /// Whether data training is allowed for this session
  bool allowDataTraining;

  /// Temperature setting for the AI (controls randomness)
  double temperature;

  /// Maximum tokens for AI response
  int maxTokens;

  ChatSession({
    this.id = 0,
    String? uid,
    required this.title,
    DateTime? createdAt,
    DateTime? lastModified,
    ChatSessionType sessionType = ChatSessionType.normal,
    this.topic,
    this.messageCount = 0,
    this.isEncrypted = false,
    this.encryptionKey,
    List<String>? tags,
    AIServiceType serviceType = AIServiceType.offline,
    this.selectedModel,
    this.isArchived = false,
    this.isFavorite = false,
    this.metadata,
    this.preferredModel,
    this.allowDataTraining = false,
    this.temperature = 0.7,
    this.maxTokens = 1000,
  })  : uid = uid ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now(),
        tags = tags ?? [] {
    _sessionType = sessionType;
    _serviceType = serviceType;
  }

  /// Get the session type as enum
  ChatSessionType get sessionType => _sessionType ?? ChatSessionType.normal;

  /// Set the session type from enum
  set sessionType(ChatSessionType value) {
    _ensureStableEnumValues();
    _sessionType = value;
  }

  /// Get the service type as enum
  AIServiceType get serviceType => _serviceType ?? AIServiceType.offline;

  /// Set the service type from enum
  set serviceType(AIServiceType value) {
    _ensureStableEnumValues();
    _serviceType = value;
  }

  /// Create a copy with updated values
  ChatSession copyWith({
    int? id,
    String? uid,
    String? title,
    DateTime? createdAt,
    DateTime? lastModified,
    ChatSessionType? sessionType,
    String? topic,
    int? messageCount,
    bool? isEncrypted,
    String? encryptionKey,
    List<String>? tags,
    AIServiceType? serviceType,
    String? selectedModel,
    bool? isArchived,
    bool? isFavorite,
    String? metadata,
    String? preferredModel,
    bool? allowDataTraining,
    double? temperature,
    int? maxTokens,
  }) {
    return ChatSession(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      sessionType: sessionType ?? this.sessionType,
      topic: topic ?? this.topic,
      messageCount: messageCount ?? this.messageCount,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      tags: tags ?? List.from(this.tags),
      serviceType: serviceType ?? this.serviceType,
      selectedModel: selectedModel ?? this.selectedModel,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      metadata: metadata ?? this.metadata,
      preferredModel: preferredModel ?? this.preferredModel,
      allowDataTraining: allowDataTraining ?? this.allowDataTraining,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }

  /// Update the last modified timestamp
  void touch() {
    lastModified = DateTime.now();
  }

  /// Add a tag to the session
  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
      touch();
    }
  }

  /// Remove a tag from the session
  void removeTag(String tag) {
    if (tags.remove(tag)) {
      touch();
    }
  }

  /// Ensure enum values have stable indices
  void _ensureStableEnumValues() {
    assert(ChatSessionType.normal.index == 0);
    assert(ChatSessionType.emergency.index == 1);
    assert(ChatSessionType.guided.index == 2);

    assert(AIServiceType.offline.index == 0);
    assert(AIServiceType.openAI.index == 1);
    assert(AIServiceType.anthropic.index == 2);
    assert(AIServiceType.openRouter.index == 3);
  }
}
