import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AIServiceType {
  openAI,
  anthropic,
  openRouter,
  offline,
}

/// Configuration for an AI service
class AIServiceConfig {
  final AIServiceType serviceType;
  final String? apiKey;
  final String? preferredModel;
  final bool allowDataTraining;

  const AIServiceConfig({
    required this.serviceType,
    this.apiKey,
    this.preferredModel,
    this.allowDataTraining = false,
  });

  /// Create a copy with updated values
  AIServiceConfig copyWith({
    AIServiceType? serviceType,
    String? apiKey,
    String? preferredModel,
    bool? allowDataTraining,
  }) {
    return AIServiceConfig(
      serviceType: serviceType ?? this.serviceType,
      apiKey: apiKey ?? this.apiKey,
      preferredModel: preferredModel ?? this.preferredModel,
      allowDataTraining: allowDataTraining ?? this.allowDataTraining,
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
              serviceType: AIServiceType.offline,
            ),
          ),
        );

  /// Set the service type
  void setServiceType(AIServiceType type) {
    state = state.copyWith(
      config: state.config.copyWith(
        serviceType: type,
      ),
    );
  }

  /// Set the API key
  void setApiKey(String apiKey) {
    state = state.copyWith(
      config: state.config.copyWith(
        apiKey: apiKey,
      ),
    );
  }

  /// Set the preferred model
  void setPreferredModel(String model) {
    state = state.copyWith(
      config: state.config.copyWith(
        preferredModel: model,
      ),
    );
  }

  /// Toggle data training permission
  void toggleDataTraining() {
    state = state.copyWith(
      config: state.config.copyWith(
        allowDataTraining: !state.config.allowDataTraining,
      ),
    );
  }
}

/// Provider for AI service
final aiServiceProvider =
    StateNotifierProvider<AIServiceNotifier, AIServiceState>((ref) {
  return AIServiceNotifier();
});
