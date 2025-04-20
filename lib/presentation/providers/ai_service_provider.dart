import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ai_models.dart' as models;
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

  AIServiceState({
    required this.config,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Create a copy with updated values
  AIServiceState copyWith({
    AIServiceConfig? config,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AIServiceState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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
      final config = AIServiceConfig(
        serviceType: models.AIServiceType.openAI,
        apiKey: await _secureStorage.getKey(
          models.AIServiceType.openAI.toString(),
        ),
      );

      // Get API key from secure storage
      final apiKey = await _secureStorage.getKey(config.serviceType.toString());

      print('API Key: $apiKey');

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

  /// Set the service type
  void setServiceType(models.AIServiceType type) {
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
  void setPreferredModel(String? model) {
    try {
      // Create new config with updated model
      final newConfig = state.config.copyWith(preferredModel: model);

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(config: newConfig);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save preferred model: $e',
      );
    }
  }

  /// Toggle data training permission
  void toggleDataTraining() {
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
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update data training setting: $e',
      );
    }
  }

  /// Update chat history storage setting
  void updateStoreChatHistory(bool store) {
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
  void updateAutoDeleteDays(int days) {
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
  void clearChatHistory() {
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
}

/// Provider for AI service
final aiServiceProvider =
    StateNotifierProvider<AIServiceNotifier, AIServiceState>((ref) {
  final repository = ref.watch(aiRepositoryProvider);
  return AIServiceNotifier(repository);
});
