import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/presentation/providers/ai_service_provider.dart';
import '../../data/models/ai_models.dart';
import '../../data/models/chat_session_model.dart';
import '../../core/context/context_manager.dart';
import '../../core/services/sound_service.dart';
import '../../data/repositories/ai_repository.dart';
import 'chat_provider.dart';
import 'chat_state.dart';

class ChatAsyncNotifier extends AutoDisposeAsyncNotifier<ChatState> {
  final ContextManager _contextManager = ContextManager();
  final SoundService _soundService = SoundService();
  late final AIRepository _repository;

  @override
  Future<ChatState> build() async {
    _repository = AIRepository(ref);

    try {
      // Get session from the session parameter provider
      final session = ref.watch(chatSessionParam);

      // Load initial messages from repository
      final messages = await _repository.getChatMessages(
        session: session,
        limit: ChatState.messagesPerPage,
      );

      // Get total message count for pagination
      final totalCount = await _repository.getChatMessageCount(session);
      final hasMore = messages.length < totalCount;

      // Create initial state
      return ChatState(
        messages: messages,
        isInitialized: true,
        isLoading: false,
        currentPage: 1,
        hasMore: hasMore,
        currentSession: session,
      );
    } catch (error) {
      // Return empty state on error, the error will be handled by Riverpod
      return const ChatState();
    }
  }

  // This method is kept for backward compatibility
  // but should be removed once all code is updated
  @Deprecated('Use the build method instead')
  Future<void> initialize({ChatSession? session}) async {
    state = const AsyncValue.loading();
    try {
      // Set the session parameter
      ref.read(chatSessionParam.notifier).state = session;

      // Refresh the state
      ref.invalidateSelf();
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

    try {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

      final nextPage = currentState.currentPage + 1;
      final offset = (nextPage - 1) * ChatState.messagesPerPage;

      final newMessages = await _repository.getChatMessages(
        session: currentState.currentSession,
        limit: ChatState.messagesPerPage,
        offset: offset,
      );

      final totalCount =
          await _repository.getChatMessageCount(currentState.currentSession);
      final hasMore = (offset + newMessages.length) < totalCount;

      state = AsyncValue.data(currentState.copyWith(
        messages: [...newMessages, ...currentState.messages],
        currentPage: nextPage,
        hasMore: hasMore,
        isLoading: false,
      ));
    } catch (error) {
      state = AsyncValue.data(currentState.copyWith(
        errorMessage: error.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> sendMessage(String content) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Get the current config from the service provider
    final config = ref.read(aiServiceProvider).config;

    // Play message sent sound
    _soundService.playSound(SoundEffect.messageSent);

    // Check if this is an emergency message
    final isEmergency = _contextManager.isEmergencyContext(content);

    final newMessage = ChatMessageModel(
      content: content,
      isUserMessage: true,
      session: currentState.currentSession,
    );

    // Create a loading message for the AI response
    final loadingMessage = ChatMessageModel(
      content: '',
      isUserMessage: false,
      session: currentState.currentSession,
    );

    // Create a new list with the user's message at the end
    final updatedMessages = [
      ...currentState.messages,
      newMessage,
      loadingMessage
    ];

    // Update state with user's message and loading state
    state = AsyncValue.data(currentState.copyWith(
      messages: updatedMessages,
    ));

    try {
      // Store the user message (encryption handled in storeMessageAsync)
      await _repository.storeMessageAsync(newMessage);

      // If this is an emergency, use special handling
      if (isEmergency) {
        await _handleEmergencyMessage(content);
        return;
      }

      // Get AI response with context management
      final availableTokens = _contextManager.getAvailableContextSize(
        config.serviceType,
        config.preferredModel,
        500, // System prompt length
      );

      final context = _contextManager.selectContext(
        updatedMessages,
        availableTokens,
        currentQuery: content,
      );

      // Generate AI response
      final aiResponse = await _repository.generateResponse(
        userInput: content,
        context: context,
        config: config,
      );

      // Create AI message
      final aiMessage = ChatMessageModel(
        content: aiResponse.content,
        isUserMessage: false,
        session: currentState.currentSession,
        wasHelpful: null,
      );

      // Store AI message (encryption handled in storeMessageAsync)
      await _repository.storeMessageAsync(aiMessage);

      // Play message received sound
      _soundService.playSound(SoundEffect.messageReceived);

      // Update state with both messages, removing loading message
      final finalMessages = [...currentState.messages, newMessage, aiMessage];
      state = AsyncValue.data(currentState.copyWith(
        messages: finalMessages,
      ));
    } catch (error) {
      // Play error sound
      _soundService.playSound(SoundEffect.error);

      // Create an error message from the AI
      final errorMessage = ChatMessageModel(
        content: "Error: ${error.toString()}",
        isUserMessage: false,
        session: currentState.currentSession,
        wasHelpful: null,
        isError: true,
      );

      // Store the error message
      await _repository.storeMessageAsync(errorMessage);

      // On error, keep the user's message and add the error message
      final messagesWithError = [
        ...currentState.messages,
        newMessage,
        errorMessage
      ];
      state = AsyncValue.data(currentState.copyWith(
        messages: messagesWithError,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> _handleEmergencyMessage(String content) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Get the current config from the service provider
    final config = ref.read(aiServiceProvider).config;

    try {
      // Use emergency system prompt
      final emergencyPrompt = _contextManager.getEmergencySystemPrompt();

      // Generate emergency response
      final aiResponse = await _repository.generateResponse(
        userInput: content,
        context: [
          ChatMessageModel(
            content: emergencyPrompt,
            isUserMessage: false,
            session: currentState.currentSession,
          ),
        ],
        config: config.copyWith(
          temperature: 0.3, // Lower temperature for more focused response
          maxTokens: 300, // Shorter response for immediate help
        ),
      );

      // Create emergency AI message
      final aiMessage = ChatMessageModel(
        content: aiResponse.content,
        isUserMessage: false,
        session: currentState.currentSession,
        wasHelpful: null,
      );

      // Store AI message (encryption handled in storeMessageAsync)
      await _repository.storeMessageAsync(aiMessage);

      // Play emergency sound (notification sound for emergencies)
      _soundService.playSound(SoundEffect.notification);

      // Update state with both messages, removing loading message
      final messagesWithoutLoading = currentState.messages
          .where((m) => !m.isUserMessage || m.content.isNotEmpty)
          .toList();
      state = AsyncValue.data(currentState.copyWith(
        messages: [...messagesWithoutLoading, aiMessage],
      ));
    } catch (error) {
      // Play error sound
      _soundService.playSound(SoundEffect.error);

      // Create an error message from the AI
      final errorMessage = ChatMessageModel(
        content: "Emergency Response Error: ${error.toString()}",
        isUserMessage: false,
        session: currentState.currentSession,
        wasHelpful: null,
        isError: true,
      );

      // Store the error message
      await _repository.storeMessageAsync(errorMessage);

      // On error, remove loading state and add error message
      final messagesWithoutLoading = currentState.messages
          .where((m) => !m.isUserMessage || m.content.isNotEmpty)
          .toList();
      state = AsyncValue.data(currentState.copyWith(
        messages: [...messagesWithoutLoading, errorMessage],
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> clearChatHistory() async {
    state = const AsyncValue.loading();
    try {
      await _repository.clearChatHistory();
      final newState = await build();
      state = AsyncValue.data(newState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> rateResponse(String messageId, bool wasHelpful) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      await _repository.updateMessageRating(messageId, wasHelpful);

      final updatedMessages = currentState.messages.map((message) {
        if (message.uid == messageId) {
          return message.copyWith(wasHelpful: wasHelpful);
        }
        return message;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
      ));
    } catch (error) {
      state = AsyncValue.data(currentState.copyWith(
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> createNewSession({
    required String title,
    String sessionType = ChatSessionType.normal,
    String serviceType = AIServiceType.offline,
    String? topic,
  }) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final newSession = await _repository.createChatSession(
        title: title,
        sessionType: sessionType,
        serviceType: serviceType,
        topic: topic,
      );

      state = AsyncValue.data(currentState.copyWith(
        currentSession: newSession,
        messages: [],
        currentPage: 1,
        hasMore: false,
      ));

      // Set the session parameter and refresh
      ref.read(chatSessionParam.notifier).state = newSession;
      ref.invalidateSelf();
    } catch (error) {
      state = AsyncValue.data(currentState.copyWith(
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> clearError() async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(
      errorMessage: null,
    ));
  }

  /// Send a system message (not from the user)
  Future<void> sendSystemMessage(String content) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Get the current config from the service provider
      final config = ref.read(aiServiceProvider).config;

      // Create a system message
      final systemMessage = ChatMessageModel(
        content: content,
        isUserMessage: false,
        session: currentState.currentSession,
        wasHelpful: null,
      );

      // Store the system message
      await _repository.storeMessageAsync(systemMessage);

      // Generate AI response based on the system message
      final aiResponse = await _repository.generateResponse(
        userInput: "Please provide guidance based on the above context.",
        context: [systemMessage],
        config: config.copyWith(
          temperature: 0.3, // Lower temperature for more focused response
        ),
      );

      // Create AI message
      final aiMessage = ChatMessageModel(
        content: aiResponse.content,
        isUserMessage: false,
        session: currentState.currentSession,
        wasHelpful: null,
      );

      // Store AI message
      await _repository.storeMessageAsync(aiMessage);

      // Play message received sound
      _soundService.playSound(SoundEffect.notification);

      // Update state with the new messages
      state = AsyncValue.data(currentState.copyWith(
        messages: [systemMessage, aiMessage, ...currentState.messages],
      ));
    } catch (error) {
      // Play error sound
      _soundService.playSound(SoundEffect.error);

      // Create an error message
      final errorMessage = ChatMessageModel(
        content: "Error processing system message: ${error.toString()}",
        isUserMessage: false,
        session: currentState.currentSession,
        wasHelpful: null,
        isError: true,
      );

      // Store the error message
      await _repository.storeMessageAsync(errorMessage);

      // Update state with the error message
      state = AsyncValue.data(currentState.copyWith(
        messages: [errorMessage, ...currentState.messages],
        errorMessage: error.toString(),
      ));
    }
  }

  /// Send a message with streaming response
  Future<void> sendStreamingMessage(String content) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Get the current config from the service provider
    final config = ref.read(aiServiceProvider).config;

    // Play message sent sound
    _soundService.playSound(SoundEffect.messageSent);

    // Check if this is an emergency message
    final isEmergency = _contextManager.isEmergencyContext(content);

    final newMessage = ChatMessageModel(
      content: content,
      isUserMessage: true,
      session: currentState.currentSession,
    );

    // Create a typing indicator message for the AI response
    final typingMessage = ChatMessageModel(
      content: '',
      isUserMessage: false,
      session: currentState.currentSession,
    );

    // Create a new list with the user's message and typing indicator
    final updatedMessages = [
      ...currentState.messages,
      newMessage,
      typingMessage
    ];

    // Update state with user's message and typing indicator
    state = AsyncValue.data(currentState.copyWith(
      messages: updatedMessages,
    ));

    try {
      // Store the user message (encryption handled in storeMessageAsync)
      await _repository.storeMessageAsync(newMessage);

      // If this is an emergency, use special handling
      if (isEmergency) {
        await _handleEmergencyMessage(content);
        return;
      }

      // Get AI response with context management
      final availableTokens = _contextManager.getAvailableContextSize(
        config.serviceType,
        config.preferredModel,
        500, // System prompt length
      );

      final context = _contextManager.selectContext(
        updatedMessages,
        availableTokens,
        currentQuery: content,
      );

      // Generate streaming AI response
      String fullResponse = '';
      final streamingMessage = ChatMessageModel(
        content: '',
        isUserMessage: false,
        session: currentState.currentSession,
        wasHelpful: null,
      );

      // Update state to show a streaming message
      final messagesWithoutTyping = currentState.messages
          .where((m) => !m.isUserMessage || m.content.isNotEmpty)
          .toList();

      state = AsyncValue.data(currentState.copyWith(
        messages: [...messagesWithoutTyping, newMessage, streamingMessage],
      ));

      // Listen to the stream of response chunks
      await for (final chunk in _repository.generateStreamingResponse(
        userInput: content,
        context: context,
        config: config,
      )) {
        // Append the new chunk to the full response
        fullResponse += chunk;

        // Update the streaming message with the accumulated text
        final updatedStreamingMessage = streamingMessage.copyWith(
          content: fullResponse,
        );

        // Get current state again in case it changed
        final latestState = state.value;
        if (latestState == null) continue;

        // Find the index of the streaming message
        final msgIndex = latestState.messages
            .indexWhere((m) => m.uid == streamingMessage.uid);

        if (msgIndex != -1) {
          // Create a new list with the updated streaming message
          final updatedMessages = [...latestState.messages];
          updatedMessages[msgIndex] = updatedStreamingMessage;

          // Update state with the new content
          state = AsyncValue.data(latestState.copyWith(
            messages: updatedMessages,
          ));
        }
      }

      // Stream completed, create final AI message
      final finalAiMessage = streamingMessage.copyWith(
        content: fullResponse,
      );

      // Store AI message (encryption handled in storeMessageAsync)
      await _repository.storeMessageAsync(finalAiMessage);

      // Play message received sound
      _soundService.playSound(SoundEffect.messageReceived);

      // Update state with the final message
      final latestState = state.value;
      if (latestState != null) {
        final msgIndex = latestState.messages
            .indexWhere((m) => m.uid == streamingMessage.uid);

        if (msgIndex != -1) {
          // Create a new list with the final message
          final finalMessages = [...latestState.messages];
          finalMessages[msgIndex] = finalAiMessage;

          // Update state with the final message
          state = AsyncValue.data(latestState.copyWith(
            messages: finalMessages,
          ));
        }
      }
    } catch (error) {
      // Play error sound
      _soundService.playSound(SoundEffect.error);

      // Create an error message from the AI
      final errorMessage = ChatMessageModel(
        content: "Error: ${error.toString()}",
        isUserMessage: false,
        session: currentState.currentSession,
        wasHelpful: null,
        isError: true,
      );

      // Store the error message
      await _repository.storeMessageAsync(errorMessage);

      // On error, keep the user's message and add the error message
      final messagesWithoutTyping = currentState.messages
          .where((m) => !m.isUserMessage || m.content.isNotEmpty)
          .toList();

      state = AsyncValue.data(currentState.copyWith(
        messages: [...messagesWithoutTyping, newMessage, errorMessage],
        errorMessage: error.toString(),
      ));
    }
  }
}
