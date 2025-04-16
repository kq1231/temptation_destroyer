import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

/// Model representing a chat message
@Entity()
class ChatMessageModel {
  @Id()
  int id = 0;

  /// Unique identifier for the message
  @Unique()
  final String uid;

  /// The content of the message
  String content;

  /// Whether the message is from the user (true) or AI (false)
  bool isUserMessage;

  /// When the message was sent
  @Property(type: PropertyType.date)
  final DateTime timestamp;

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
