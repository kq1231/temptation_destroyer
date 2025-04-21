import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_session_model.dart';
import '../../data/repositories/ai_repository.dart';

final chatSessionsProvider =
    AutoDisposeAsyncNotifierProvider<ChatSessionNotifier, List<ChatSession>>(
        ChatSessionNotifier.new);

class ChatSessionNotifier extends AutoDisposeAsyncNotifier<List<ChatSession>> {
  late final AIRepository _repository;

  @override
  Future<List<ChatSession>> build() async {
    _repository = AIRepository(ref);
    return await _loadSessions();
  }

  Future<List<ChatSession>> _loadSessions() async {
    try {
      final sessions = await _repository.getChatSessions(includeArchived: true);
      return sessions;
    } catch (e) {
      return [];
    }
  }

  Future<void> createSession({
    required String title,
    ChatSessionType sessionType = ChatSessionType.normal,
    String? topic,
    List<String>? tags,
  }) async {
    state = const AsyncValue.loading();
    try {
      final newSession = await _repository.createChatSession(
        title: title,
        sessionType: sessionType,
        topic: topic,
      );

      if (tags != null && tags.isNotEmpty) {
        for (final tag in tags) {
          newSession.addTag(tag);
        }
        await _repository.updateChatSession(newSession);
      }

      state = AsyncValue.data(await _loadSessions());
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateSession(ChatSession session) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateChatSession(session);
      state = AsyncValue.data(await _loadSessions());
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteSession(ChatSession session) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteChatSession(session.id);
      state = AsyncValue.data(await _loadSessions());
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> favoriteSession(ChatSession session, bool isFavorite) async {
    try {
      final updatedSession = session.copyWith(isFavorite: isFavorite);
      await _repository.updateChatSession(updatedSession);
      state = AsyncValue.data(await _loadSessions());
    } catch (e) {
      // Restore original state on error
      state = AsyncValue.data(state.value ?? []);
    }
  }

  Future<void> archiveSession(ChatSession session, bool isArchived) async {
    try {
      final updatedSession = session.copyWith(isArchived: isArchived);
      await _repository.updateChatSession(updatedSession);
      state = AsyncValue.data(await _loadSessions());
    } catch (e) {
      // Restore original state on error
      state = AsyncValue.data(state.value ?? []);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _loadSessions());
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
