import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ai_models.dart' as models;
import '../../data/models/chat_session_model.dart';
import '../../data/repositories/ai_repository.dart';
import '../../core/config/ai_service_config.dart';
import '../../core/security/secure_storage_service.dart';

/// Provider for the AI repository
final aiRepositoryProvider = Provider((ref) => AIRepository(ref));

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

  AIServiceNotifier(this._repository)
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
      // Default config if no session is provided
      AIServiceConfig config = AIServiceConfig(
        serviceType: models.AIServiceType.openAI,
      );

      // Get API key from secure storage for the default service type
      final apiKey = await _secureStorage.getKey(config.serviceType.toString());

      // Update config with API key
      final updatedConfig = config.copyWith(apiKey: apiKey);

      state = state.copyWith(
        isLoading: false,
        config: updatedConfig,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings: $e',
      );
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

    // Apply the current config to the session
    final updatedSession = state.config.applyToSession(session);

    // Save the updated session
    await _repository.updateChatSession(updatedSession);

    // Update the state with the updated session
    state = state.copyWith(activeSession: updatedSession);
  }

  /// Set the service type
  Future<void> setServiceType(models.AIServiceType type) async {
    try {
      // Create new config with updated service type
      final newConfig = state.config.copyWith(
        serviceType: type,
        apiKey: null, // Clear API key when switching services
      );

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(config: newConfig);

      // If there's an active session, apply the changes to it
      if (state.activeSession != null) {
        await saveConfigToActiveSession();
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save service type: $e',
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

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        isLoading: false,
        config: newConfig,
      );
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

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(config: newConfig);

      // If there's an active session, apply the changes to it
      if (state.activeSession != null) {
        await saveConfigToActiveSession();
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

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        config: newConfig,
      );

      // If there's an active session, apply the changes to it
      if (state.activeSession != null) {
        await saveConfigToActiveSession();
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update data training setting: $e',
      );
    }
  }

  /// Update chat history storage setting
  Future<void> updateStoreChatHistory(bool store) async {
    try {
      final newSettings = state.config.settings.copyWith(
        storeChatHistory: store,
      );

      // Create new config with updated settings
      final newConfig = state.config.copyWith(
        settings: newSettings,
      );

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        config: newConfig,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update chat history setting: $e',
      );
    }
  }

  /// Update auto-delete days
  Future<void> updateAutoDeleteDays(int days) async {
    try {
      final newSettings = state.config.settings.copyWith(
        autoDeleteAfterDays: days,
      );

      // Create new config with updated settings
      final newConfig = state.config.copyWith(
        settings: newSettings,
      );

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        config: newConfig,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update auto-delete days: $e',
      );
    }
  }

  /// Clear chat history
  Future<void> clearChatHistory() async {
    try {
      final newSettings = state.config.settings.copyWith(
        lastCleared: DateTime.now(),
      );

      // Create new config with updated settings
      final newConfig = state.config.copyWith(
        settings: newSettings,
      );

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        config: newConfig,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update last cleared timestamp: $e',
      );
    }
  }

  /// Update temperature setting
  Future<void> setTemperature(double temperature) async {
    try {
      // Create new config with updated temperature
      final newConfig = state.config.copyWith(temperature: temperature);

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(config: newConfig);

      // If there's an active session, apply the changes to it
      if (state.activeSession != null) {
        await saveConfigToActiveSession();
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update temperature: $e',
      );
    }
  }

  /// Update max tokens setting
  Future<void> setMaxTokens(int maxTokens) async {
    try {
      // Create new config with updated max tokens
      final newConfig = state.config.copyWith(maxTokens: maxTokens);

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(config: newConfig);

      // If there's an active session, apply the changes to it
      if (state.activeSession != null) {
        await saveConfigToActiveSession();
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
  return AIServiceNotifier(repository);
});
