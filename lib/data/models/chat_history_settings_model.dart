import 'package:objectbox/objectbox.dart';

/// Settings for Chat History (Database Model)
@Entity()
class ChatHistorySettingsModel {
  @Id()
  int id = 0;

  /// Whether to store chat history
  bool storeChatHistory;

  /// Number of days after which to auto-delete chat history
  int autoDeleteAfterDays;

  /// When the chat history was last cleared
  @Property(type: PropertyType.date)
  DateTime lastCleared;

  ChatHistorySettingsModel({
    this.id = 0,
    this.storeChatHistory = false,
    this.autoDeleteAfterDays = 30,
    DateTime? lastCleared,
  }) : lastCleared = lastCleared ?? DateTime.now();

  /// Create a copy with updated values
  ChatHistorySettingsModel copyWith({
    int? id,
    bool? storeChatHistory,
    int? autoDeleteAfterDays,
    DateTime? lastCleared,
  }) {
    return ChatHistorySettingsModel(
      id: id ?? this.id,
      storeChatHistory: storeChatHistory ?? this.storeChatHistory,
      autoDeleteAfterDays: autoDeleteAfterDays ?? this.autoDeleteAfterDays,
      lastCleared: lastCleared ?? this.lastCleared,
    );
  }
}
