import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ai_models.dart' as models;
import '../../data/repositories/ai_repository.dart';

/// Chat history settings
class ChatHistorySettings {
  final bool storeChatHistory;
  final int autoDeleteAfterDays;
  final DateTime? lastCleared;

  const ChatHistorySettings({
    this.storeChatHistory = false,
    this.autoDeleteAfterDays = 30,
    this.lastCleared,
  });

  /// Create a copy with updated values
  ChatHistorySettings copyWith({
    bool? storeChatHistory,
    int? autoDeleteAfterDays,
    DateTime? lastCleared,
  }) {
    return ChatHistorySettings(
      storeChatHistory: storeChatHistory ?? this.storeChatHistory,
      autoDeleteAfterDays: autoDeleteAfterDays ?? this.autoDeleteAfterDays,
      lastCleared: lastCleared ?? this.lastCleared,
    );
  }
}

/// Configuration for an AI service
class AIServiceConfig {
  final models.AIServiceType serviceType;
  final String? apiKey;
  final String? preferredModel;
  final bool allowDataTraining;
  final ChatHistorySettings settings;

  const AIServiceConfig({
    required this.serviceType,
    this.apiKey,
    this.preferredModel,
    this.allowDataTraining = false,
    this.settings = const ChatHistorySettings(),
  });

  /// Create a copy with updated values
  AIServiceConfig copyWith({
    models.AIServiceType? serviceType,
    String? apiKey,
    String? preferredModel,
    bool? allowDataTraining,
    ChatHistorySettings? settings,
  }) {
    return AIServiceConfig(
      serviceType: serviceType ?? this.serviceType,
      apiKey: apiKey ?? this.apiKey,
      preferredModel: preferredModel ?? this.preferredModel,
      allowDataTraining: allowDataTraining ?? this.allowDataTraining,
      settings: settings ?? this.settings,
    );
  }
}

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
  final AIRepository _repository = AIRepository();

  AIServiceNotifier()
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
      // Load saved settings from repository
      final savedConfig = _repository.getServiceConfig();
      state = state.copyWith(
        isLoading: false,
        config: AIServiceConfig(
          serviceType: savedConfig.serviceType,
          apiKey: savedConfig.apiKey,
          preferredModel: savedConfig.preferredModel,
          allowDataTraining: savedConfig.allowDataTraining,
        ),
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
      final newConfig = models.AIServiceConfig(
        serviceType: type,
        apiKey: state.config.apiKey,
        preferredModel: state.config.preferredModel,
        allowDataTraining: state.config.allowDataTraining,
      );

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        config: state.config.copyWith(
          serviceType: type,
          // Clear API key when switching services
          apiKey: null,
        ),
      );
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
      // Create new config with updated API key
      final newConfig = models.AIServiceConfig(
        serviceType: state.config.serviceType,
        apiKey: apiKey,
        preferredModel: state.config.preferredModel,
        allowDataTraining: state.config.allowDataTraining,
      );

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        isLoading: false,
        config: state.config.copyWith(
          apiKey: apiKey,
        ),
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
      final newConfig = models.AIServiceConfig(
        serviceType: state.config.serviceType,
        apiKey: state.config.apiKey,
        preferredModel: model,
        allowDataTraining: state.config.allowDataTraining,
      );

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        config: state.config.copyWith(
          preferredModel: model,
        ),
      );
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
      final newConfig = models.AIServiceConfig(
        serviceType: state.config.serviceType,
        apiKey: state.config.apiKey,
        preferredModel: state.config.preferredModel,
        allowDataTraining: newAllowDataTraining,
      );

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        config: state.config.copyWith(
          allowDataTraining: newAllowDataTraining,
        ),
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
      final newConfig = models.AIServiceConfig(
        serviceType: state.config.serviceType,
        apiKey: state.config.apiKey,
        preferredModel: state.config.preferredModel,
        allowDataTraining: state.config.allowDataTraining,
      );

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        config: state.config.copyWith(
          settings: newSettings,
        ),
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
      final newConfig = models.AIServiceConfig(
        serviceType: state.config.serviceType,
        apiKey: state.config.apiKey,
        preferredModel: state.config.preferredModel,
        allowDataTraining: state.config.allowDataTraining,
      );

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        config: state.config.copyWith(
          settings: newSettings,
        ),
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
      final newConfig = models.AIServiceConfig(
        serviceType: state.config.serviceType,
        apiKey: state.config.apiKey,
        preferredModel: state.config.preferredModel,
        allowDataTraining: state.config.allowDataTraining,
      );

      // Save to repository
      _repository.saveServiceConfig(newConfig);

      // Update state
      state = state.copyWith(
        config: state.config.copyWith(
          settings: newSettings,
        ),
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
  return AIServiceNotifier();
});
