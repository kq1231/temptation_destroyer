import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';
import 'ai_models.dart';

/// Chat Session Type Constants
class ChatSessionType {
  static const String normal = 'normal'; // Regular chat session
  static const String emergency = 'emergency'; // Emergency support session
  static const String guided = 'guided'; // Guided Islamic advice session

  // List of all available session types
  static const List<String> values = [normal, emergency, guided];
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
  @Property()
  String sessionType = ChatSessionType.normal;

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
  @Property()
  String serviceType = AIServiceType.offline;

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
    this.sessionType = ChatSessionType.normal,
    this.topic,
    this.messageCount = 0,
    this.isEncrypted = false,
    this.encryptionKey,
    List<String>? tags,
    this.serviceType = AIServiceType.offline,
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
        tags = tags ?? [];

  /// Create a copy with updated values
  ChatSession copyWith({
    int? id,
    String? uid,
    String? title,
    DateTime? createdAt,
    DateTime? lastModified,
    String? sessionType,
    String? topic,
    int? messageCount,
    bool? isEncrypted,
    String? encryptionKey,
    List<String>? tags,
    String? serviceType,
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
}
