import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ai_models.dart' as models;

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
  AIServiceNotifier()
      : super(
          AIServiceState(
            config: const AIServiceConfig(
              serviceType: models.AIServiceType.offline,
            ),
          ),
        );

  /// Set the service type
  void setServiceType(models.AIServiceType type) {
    state = state.copyWith(
      config: state.config.copyWith(
        serviceType: type,
      ),
    );
  }

  /// Alias for setServiceType for the settings screen
  void updateServiceType(models.AIServiceType type) => setServiceType(type);

  /// Set the API key
  void setApiKey(String apiKey) {
    state = state.copyWith(
      config: state.config.copyWith(
        apiKey: apiKey,
      ),
    );
  }

  /// Alias for setApiKey for the settings screen
  void updateApiKey(String apiKey) => setApiKey(apiKey);

  /// Set the preferred model
  void setPreferredModel(String? model) {
    state = state.copyWith(
      config: state.config.copyWith(
        preferredModel: model,
      ),
    );
  }

  /// Alias for setPreferredModel for the settings screen
  void updatePreferredModel(String? model) => setPreferredModel(model);

  /// Toggle data training permission
  void toggleDataTraining() {
    state = state.copyWith(
      config: state.config.copyWith(
        allowDataTraining: !state.config.allowDataTraining,
      ),
    );
  }

  /// Update data training permission
  void updateAllowDataTraining(bool allow) {
    state = state.copyWith(
      config: state.config.copyWith(
        allowDataTraining: allow,
      ),
    );
  }

  /// Update chat history storage setting
  void updateStoreChatHistory(bool store) {
    state = state.copyWith(
      config: state.config.copyWith(
        settings: state.config.settings.copyWith(
          storeChatHistory: store,
        ),
      ),
    );
  }

  /// Update auto-delete days
  void updateAutoDeleteDays(int days) {
    state = state.copyWith(
      config: state.config.copyWith(
        settings: state.config.settings.copyWith(
          autoDeleteAfterDays: days,
        ),
      ),
    );
  }

  /// Clear chat history
  void clearChatHistory() {
    state = state.copyWith(
      config: state.config.copyWith(
        settings: state.config.settings.copyWith(
          lastCleared: DateTime.now(),
        ),
      ),
    );
    // In a real implementation, this would also delete the actual chat history
  }
}

/// Provider for AI service
final aiServiceProvider =
    StateNotifierProvider<AIServiceNotifier, AIServiceState>((ref) {
  return AIServiceNotifier();
});
