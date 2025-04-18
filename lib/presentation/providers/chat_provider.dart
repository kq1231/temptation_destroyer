import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_async_notifier.dart';
import 'chat_state.dart';

final chatProvider = AsyncNotifierProvider<ChatAsyncNotifier, ChatState>(() {
  return ChatAsyncNotifier();
});
