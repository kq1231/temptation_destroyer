import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ai_models.dart' hide AIServiceType;
import '../../data/repositories/ai_repository.dart';
import '../providers/ai_service_provider.dart';
import '../../domain/usecases/ai/generate_ai_guidance_usecase.dart';

/// Class representing the chat message state
class ChatMessage {
  final String id;
  final String content;
  final bool isUserMessage;
  final DateTime timestamp;
  final bool isPending;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUserMessage,
    DateTime? timestamp,
    this.isPending = false,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to model for storage
  ChatMessageModel toModel() {
    return ChatMessageModel(
      uid: id,
      content: content,
      isUserMessage: isUserMessage,
      timestamp: timestamp,
    );
  }

  /// Create from model
  factory ChatMessage.fromModel(ChatMessageModel model) {
    return ChatMessage(
      id: model.uid,
      content: model.content,
      isUserMessage: model.isUserMessage,
      timestamp: model.timestamp,
    );
  }

  /// Create a copy with updated values
  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUserMessage,
    DateTime? timestamp,
    bool? isPending,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUserMessage: isUserMessage ?? this.isUserMessage,
      timestamp: timestamp ?? this.timestamp,
      isPending: isPending ?? this.isPending,
      isError: isError ?? this.isError,
    );
  }
}

/// State for AI guidance
class AIGuidanceState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isVoiceInputActive;
  final String? errorMessage;
  final bool showOfflineMessage;

  AIGuidanceState({
    this.messages = const [],
    this.isLoading = false,
    this.isVoiceInputActive = false,
    this.errorMessage,
    this.showOfflineMessage = false,
  });

  /// Create a copy with updated values
  AIGuidanceState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isVoiceInputActive,
    String? errorMessage,
    bool? showOfflineMessage,
  }) {
    return AIGuidanceState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isVoiceInputActive: isVoiceInputActive ?? this.isVoiceInputActive,
      errorMessage: errorMessage,
      showOfflineMessage: showOfflineMessage ?? this.showOfflineMessage,
    );
  }
}

/// Provider for AI guidance
class AIGuidanceNotifier extends StateNotifier<AIGuidanceState> {
  final AIRepository _aiRepository;
  final GenerateAIGuidanceUseCase _generateAIGuidanceUseCase;
  final AIServiceState _aiServiceState;

  AIGuidanceNotifier(
    this._aiRepository,
    this._generateAIGuidanceUseCase,
    this._aiServiceState,
  ) : super(AIGuidanceState());

  /// Initialize chat
  Future<void> initialize() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Load chat history if available
      final chatHistory = await _aiRepository.getRecentChatHistory(50);
      final messages =
          chatHistory.map((m) => ChatMessage.fromModel(m)).toList();

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        showOfflineMessage:
            _aiServiceState.config.serviceType == AIServiceType.offline,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load chat history: $e',
      );
    }
  }

  /// Send a message to the AI
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      // Generate a unique ID for this message
      final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();

      // Add user message to state immediately
      final userMessage = ChatMessage(
        id: userMessageId,
        content: message,
        isUserMessage: true,
      );

      state = state.copyWith(
        messages: [...state.messages, userMessage],
        isLoading: true,
        errorMessage: null,
      );

      // Save user message to chat history
      await _aiRepository.storeChatMessage(userMessage.toModel());

      // Generate AI response with pending state
      final pendingAiMessage = ChatMessage(
        id: 'pending-${DateTime.now().millisecondsSinceEpoch}',
        content: '...',
        isUserMessage: false,
        isPending: true,
      );

      state = state.copyWith(
        messages: [...state.messages, pendingAiMessage],
      );

      // Generate actual AI response
      final response = await _generateAIGuidanceUseCase.execute(message);

      // Create final AI message
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUserMessage: false,
      );

      // Update state by replacing the pending message with the actual response
      final updatedMessages = state.messages.where((m) => !m.isPending).toList()
        ..add(aiMessage);

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
      );

      // Save AI message to chat history
      await _aiRepository.storeChatMessage(aiMessage.toModel());
    } catch (e) {
      // Update the pending message to show an error
      final updatedMessages = state.messages.map((m) {
        if (m.isPending) {
          return m.copyWith(
            content: 'Failed to generate response. Please try again.',
            isPending: false,
            isError: true,
          );
        }
        return m;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        errorMessage: 'Failed to generate response: $e',
      );
    }
  }

  /// Toggle voice input
  void toggleVoiceInput() {
    state = state.copyWith(
      isVoiceInputActive: !state.isVoiceInputActive,
    );
  }

  /// Clear chat history
  Future<void> clearChatHistory() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      _aiRepository.clearChatHistory();

      state = state.copyWith(
        messages: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to clear chat history: $e',
      );
    }
  }

  /// Rate AI response
  Future<void> rateResponse(String responseId, bool wasHelpful) async {
    try {
      // Find the corresponding stored AI response
      final aiResponses = await _aiRepository.getAllAIResponses();
      final aiResponse = aiResponses.firstWhere(
        (response) => response.uid == responseId,
        orElse: () => throw Exception('AI response not found'),
      );

      // Update the rating in the database
      aiResponse.wasHelpful = wasHelpful;
      _aiRepository.updateAIResponse(aiResponse);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to rate response: $e',
      );
    }
  }
}

/// Provider for AI guidance
final aiGuidanceProvider =
    StateNotifierProvider<AIGuidanceNotifier, AIGuidanceState>((ref) {
  final aiRepository = ref.watch(aiRepositoryProvider);
  final aiServiceState = ref.watch(aiServiceProvider);
  final generateAIGuidanceUseCase =
      ref.watch(generateAIGuidanceUseCaseProvider);

  return AIGuidanceNotifier(
    aiRepository,
    generateAIGuidanceUseCase,
    aiServiceState,
  );
});

/// Repository provider
final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepository();
});

/// Use case provider
final generateAIGuidanceUseCaseProvider =
    Provider<GenerateAIGuidanceUseCase>((ref) {
  final aiRepository = ref.watch(aiRepositoryProvider);
  return GenerateAIGuidanceUseCase(aiRepository);
});
