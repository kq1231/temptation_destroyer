import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ai_models.dart';
import '../../data/models/chat_session_model.dart';
import 'chat_state.dart';

class ChatAsyncNotifier extends AsyncNotifier<ChatState> {
  @override
  Future<ChatState> build() async {
    return const ChatState();
  }

  Future<void> initialize() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Load initial messages and session from repository
      final initialState = ChatState(
        messages: [],
        isInitialized: true,
      );
      state = AsyncValue.data(initialState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMoreMessages() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoading) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      // TODO: Load messages from repository with pagination
      final nextPage = currentState.currentPage + 1;
      // final startIndex = (nextPage - 1) * ChatState.messagesPerPage;

      // TODO: Replace with actual repository call
      final newMessages = <ChatMessageModel>[];

      final hasMore = newMessages.length >= ChatState.messagesPerPage;

      state = AsyncValue.data(currentState.copyWith(
        messages: [...currentState.messages, ...newMessages],
        currentPage: nextPage,
        hasMore: hasMore,
        isLoading: false,
      ));
    } catch (error, _) {
      state = AsyncValue.data(currentState.copyWith(
        errorMessage: error.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> sendMessage(String content) async {
    final currentState = state.value;
    if (currentState == null) return;

    final newMessage = ChatMessageModel(
      content: content,
      isUserMessage: true,
    );

    // Optimistically add the message
    state = AsyncValue.data(currentState.copyWith(
      messages: [newMessage, ...currentState.messages],
    ));

    try {
      // TODO: Send message through repository
      // TODO: Get AI response
      // TODO: Add AI response to messages
    } catch (error, _) {
      state = AsyncValue.data(currentState.copyWith(
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> clearChatHistory() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Clear chat history in repository
      state = const AsyncValue.data(ChatState());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> rateResponse(String messageId, bool wasHelpful) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // TODO: Update message rating in repository
      final updatedMessages = currentState.messages.map((message) {
        if (message.uid == messageId) {
          // TODO: Update the message with rating
          return message;
        }
        return message;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
      ));
    } catch (error, _) {
      state = AsyncValue.data(currentState.copyWith(
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> createNewSession({
    required String title,
    ChatSessionType sessionType = ChatSessionType.normal,
    AIServiceType serviceType = AIServiceType.offline,
  }) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final newSession = ChatSession(
        title: title,
        sessionType: sessionType,
        serviceType: serviceType,
      );

      // TODO: Save session in repository

      state = AsyncValue.data(currentState.copyWith(
        currentSession: newSession,
        messages: [],
        currentPage: 1,
        hasMore: false,
      ));
    } catch (error, _) {
      state = AsyncValue.data(currentState.copyWith(
        errorMessage: error.toString(),
      ));
    }
  }
}
