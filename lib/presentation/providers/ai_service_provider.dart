import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ai_models.dart' as models;
import '../../data/models/chat_session_model.dart';
import '../../data/repositories/ai_repository.dart';
import '../../core/config/ai_service_config.dart';
import '../../core/security/secure_storage_service.dart';
import 'chat_session_provider.dart';

/// Provider for the AI repository
final aiRepositoryProvider = Provider.autoDispose((ref) => AIRepository(ref));

/// AI Service state
class AIServiceState {
  final AIServiceConfig config;
  final bool isLoading;
  final String? errorMessage;
  final ChatSession? activeSession;

  AIServiceState({
    required this.config,
    this.isLoading = false,
    this.errorMessage,
    this.activeSession,
  });

  /// Create a copy with updated values
  AIServiceState copyWith({
    AIServiceConfig? config,
    bool? isLoading,
    String? errorMessage,
    ChatSession? activeSession,
  }) {
    return AIServiceState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeSession: activeSession ?? this.activeSession,
    );
  }
}

/// AI Service notifier
class AIServiceNotifier extends StateNotifier<AIServiceState> {
  final AIRepository _repository;
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  final dynamic _ref;

  AIServiceNotifier(this._repository, this._ref)
      : super(
          AIServiceState(
            config: const AIServiceConfig(
              serviceType: models.AIServiceType.offline,
            ),
          ),
        ) {
    // Initialize the state when created
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      // Try to get the current chat session
      final chatSessions = await _ref.read(chatSessionsProvider.future);
      final currentSession =
          chatSessions.isNotEmpty ? chatSessions.first : null;

      // Initialize config based on session or defaults
      AIServiceConfig config;

      if (currentSession != null) {
        // Create config from session
        config = AIServiceConfig.fromChatSession(currentSession);

        // Get API key for the session's service type
        final apiKey =
            await _secureStorage.getKey(currentSession.serviceType.toString());
        config = config.copyWith(apiKey: apiKey);

        // Set the active session
        state = state.copyWith(
          isLoading: false,
          config: config,
          activeSession: currentSession,
        );
      } else {
        // Use default config
        config = const AIServiceConfig(
          serviceType: models.AIServiceType.offline,
          maxTokens: 512,
        );

        // Get API key for default service
        final apiKey =
            await _secureStorage.getKey(config.serviceType.toString());
        config = config.copyWith(apiKey: apiKey);

        state = state.copyWith(
          isLoading: false,
          config: config,
        );
      }
      // Save the initial config to persist it
      await _directSaveConfig(config);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings: $e',
      );
    }
  }

  /// Directly save the config without updating state or triggering other methods
  /// This avoids the circular dependency problem
  Future<void> _directSaveConfig(AIServiceConfig config) async {
    try {
      if (state.activeSession != null) {
        // Apply config to the active session
        final updatedSession = config.applyToSession(state.activeSession!);

        // Save the updated session to the database
        await _repository.updateChatSession(updatedSession);
      }
    } catch (e) {
      print('Error saving config: $e');
    }
  }

  /// Set the active chat session and load its configuration
  Future<void> setActiveSession(ChatSession? session) async {
    if (session == null) {
      // If no session is provided, use the global configuration
      state = state.copyWith(activeSession: null);
      return;
    }

    try {
      // Create a config from the session
      final sessionConfig = AIServiceConfig.fromChatSession(session);

      // Get the API key for the session's service type
      final apiKey =
          await _secureStorage.getKey(session.serviceType.toString());

      // Update the config with the appropriate API key
      final updatedConfig = sessionConfig.copyWith(apiKey: apiKey);

      // Update the state with the session and its config
      state = state.copyWith(
        activeSession: session,
        config: updatedConfig,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load session settings: $e',
      );
    }
  }

  /// Save the current configuration to the active session
  Future<void> saveConfigToActiveSession() async {
    final session = state.activeSession;
    if (session == null) return;

    try {
      // Apply the current config to the session
      final updatedSession = state.config.applyToSession(session);

      // Save the updated session
      await _repository.updateChatSession(updatedSession);

      // Update the state with the updated session
      state = state.copyWith(
        activeSession: updatedSession,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save session settings: $e',
      );
    }
  }

  /// Set the service type
  Future<void> setServiceType(models.AIServiceType type,
      {String? apiKey}) async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true);

      // Create new config with updated service type
      final newConfig = AIServiceConfig(
        temperature: state.config.temperature,
        maxTokens: state.config.maxTokens,
        preferredModel: state.config.preferredModel,
        allowDataTraining: state.config.allowDataTraining,
        serviceType: type,
        apiKey: apiKey,
      );

      // Update state immediately to reflect the new service type
      state = state.copyWith(
        config: newConfig,
        isLoading: false,
      );

      // If there's an active session, apply the changes to it
      if (state.activeSession != null) {
        await saveConfigToActiveSession();
      } else {
        // Otherwise save it directly
        await _directSaveConfig(newConfig);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save service type: $e',
      );
    }
  }

  /// Update API Key for the current service
  Future<void> updateApiKey(String apiKey) async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true);

      // Store the API key securely
      final secureStorage = SecureStorageService.instance;
      await secureStorage.storeKey(
        state.config.serviceType.toString(),
        apiKey,
      );

      // Create an updated config with the API key
      final updatedConfig = state.config.copyWith(
        apiKey: apiKey,
      );

      state = state.copyWith(
        config: updatedConfig,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update API key: $e',
        isLoading: false,
      );
    }
  }

  /// Clear chat history
  Future<void> clearChatHistory() async {
    try {
      // Clear chat history in repository
      await _repository.clearChatHistory();

      print('Chat history cleared');
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to clear chat history: $e',
      );
    }
  }

  /// Update temperature setting
  Future<void> setTemperature(double temperature) async {
    try {
      // Create new config with updated temperature
      final newConfig = state.config.copyWith(temperature: temperature);

      // Update state immediately
      state = state.copyWith(config: newConfig);

      // If there's an active session, apply the changes to it
      if (state.activeSession != null) {
        await saveConfigToActiveSession();
      } else {
        // Otherwise save it directly
        await _directSaveConfig(newConfig);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update temperature: $e',
      );
    }
  }

  /// Set the API key
  Future<void> setApiKey(String apiKey) async {
    state = state.copyWith(isLoading: true);
    try {
      // Store API key in secure storage
      await _secureStorage.storeKey(
          state.config.serviceType.toString(), apiKey);

      // Create new config with updated API key
      final newConfig = state.config.copyWith(apiKey: apiKey);

      // Update state immediately
      state = state.copyWith(
        isLoading: false,
        config: newConfig,
      );

      // Save the config
      await _directSaveConfig(newConfig);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save API key: $e',
      );
    }
  }

  /// Set the preferred model
  Future<void> setPreferredModel(String? model) async {
    try {
      // Create new config with updated model
      final newConfig = state.config.copyWith(preferredModel: model);

      // Update state immediately
      state = state.copyWith(config: newConfig);

      // If there's an active session, apply the changes to it
      if (state.activeSession != null) {
        await saveConfigToActiveSession();
      } else {
        // Otherwise save it directly
        await _directSaveConfig(newConfig);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save preferred model: $e',
      );
    }
  }

  /// Toggle data training permission
  Future<void> toggleDataTraining() async {
    try {
      final newAllowDataTraining = !state.config.allowDataTraining;

      // Create new config with updated data training setting
      final newConfig = state.config.copyWith(
        allowDataTraining: newAllowDataTraining,
      );

      // Update state immediately
      state = state.copyWith(config: newConfig);

      // If there's an active session, apply the changes to it
      if (state.activeSession != null) {
        await saveConfigToActiveSession();
      } else {
        // Otherwise save it directly
        await _directSaveConfig(newConfig);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update data training setting: $e',
      );
    }
  }

  /// Update max tokens setting
  Future<void> setMaxTokens(int maxTokens) async {
    try {
      // Create new config with updated max tokens
      final newConfig = state.config.copyWith(maxTokens: maxTokens);

      // Update state immediately
      state = state.copyWith(config: newConfig);

      // If there's an active session, apply the changes to it
      if (state.activeSession != null) {
        await saveConfigToActiveSession();
      } else {
        // Otherwise save it directly
        await _directSaveConfig(newConfig);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update max tokens: $e',
      );
    }
  }
}

/// Provider for AI service
final aiServiceProvider =
    StateNotifierProvider<AIServiceNotifier, AIServiceState>((ref) {
  final repository = ref.watch(aiRepositoryProvider);
  return AIServiceNotifier(repository, ref);
});
