import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_session_model.dart';
import 'chat_async_notifier.dart';
import 'chat_state.dart';

// Session parameter for the chat provider
final chatSessionParam = StateProvider<ChatSession?>((ref) => null);

final chatProvider =
    AutoDisposeAsyncNotifierProvider<ChatAsyncNotifier, ChatState>(() {
  return ChatAsyncNotifier();
});
