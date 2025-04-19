import 'package:flutter/foundation.dart';
import '../../data/models/ai_models.dart';
import '../../data/models/chat_session_model.dart';

@immutable
class ChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;
  final ChatSession? currentSession;
  final bool isInitialized;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 1,
    this.currentSession,
    this.isInitialized = false,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
    ChatSession? currentSession,
    bool? isInitialized,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      currentSession: currentSession ?? this.currentSession,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  static const int messagesPerPage = 20;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatState &&
          runtimeType == other.runtimeType &&
          listEquals(messages, other.messages) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          hasMore == other.hasMore &&
          currentPage == other.currentPage &&
          currentSession == other.currentSession &&
          isInitialized == other.isInitialized;

  @override
  int get hashCode =>
      messages.hashCode ^
      isLoading.hashCode ^
      errorMessage.hashCode ^
      hasMore.hashCode ^
      currentPage.hashCode ^
      currentSession.hashCode ^
      isInitialized.hashCode;
}
