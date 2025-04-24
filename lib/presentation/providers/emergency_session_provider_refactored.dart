import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/emergency_session_model.dart';
import '../../data/repositories/emergency_repository.dart';
import '../../domain/usecases/emergency/start_emergency_session_usecase.dart';
import '../../domain/usecases/emergency/end_emergency_session_usecase.dart';
import '../../domain/usecases/emergency/get_active_session_usecase.dart';
import '../../domain/usecases/emergency/get_emergency_sessions_usecase.dart';

part 'emergency_session_provider_refactored.g.dart';

/// Provider for the emergency repository
final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository();
});

/// Provider for the start emergency session use case
final startEmergencySessionUseCaseProvider =
    Provider<StartEmergencySessionUseCase>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return StartEmergencySessionUseCase(repository);
});

/// Provider for the end emergency session use case
final endEmergencySessionUseCaseProvider =
    Provider<EndEmergencySessionUseCase>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return EndEmergencySessionUseCase(repository);
});

/// Provider for the get active session use case
final getActiveSessionUseCaseProvider =
    Provider<GetActiveSessionUseCase>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return GetActiveSessionUseCase(repository);
});

/// Provider for the get emergency sessions use case
final getEmergencySessionsUseCaseProvider =
    Provider<GetEmergencySessionsUseCase>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return GetEmergencySessionsUseCase(repository);
});

/// State for the emergency session notifier
class EmergencySessionState {
  final EmergencySession? activeSession;
  final List<EmergencySession> recentSessions;
  final bool isLoading;
  final String? errorMessage;

  EmergencySessionState({
    this.activeSession,
    this.recentSessions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Create a copy of the state with updated values
  EmergencySessionState copyWith({
    EmergencySession? activeSession,
    List<EmergencySession>? recentSessions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EmergencySessionState(
      activeSession: activeSession ?? this.activeSession,
      recentSessions: recentSessions ?? this.recentSessions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for emergency session state management using AsyncNotifier
@riverpod
class EmergencySessionNotifier extends _$EmergencySessionNotifier {
  late final StartEmergencySessionUseCase _startUseCase;
  late final EndEmergencySessionUseCase _endUseCase;
  late final GetActiveSessionUseCase _getActiveUseCase;
  late final GetEmergencySessionsUseCase _getSessionsUseCase;
  late final EmergencyRepository _repository;

  @override
  Future<EmergencySessionState> build() async {
    // Initialize use cases
    _startUseCase = ref.watch(startEmergencySessionUseCaseProvider);
    _endUseCase = ref.watch(endEmergencySessionUseCaseProvider);
    _getActiveUseCase = ref.watch(getActiveSessionUseCaseProvider);
    _getSessionsUseCase = ref.watch(getEmergencySessionsUseCaseProvider);
    _repository = ref.watch(emergencyRepositoryProvider);

    try {
      final activeSession = await _getActiveUseCase.execute();
      final recentSessions = await _getSessionsUseCase.getSessionsForCurrentWeek();

      return EmergencySessionState(
        activeSession: activeSession,
        recentSessions: recentSessions,
        isLoading: false,
      );
    } catch (e) {
      return EmergencySessionState(
        isLoading: false,
        errorMessage: 'Failed to load session data: $e',
      );
    }
  }

  /// Start a new emergency session
  Future<void> startEmergencySession({
    String? triggerId,
    int? intensity,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      final session = await _startUseCase.execute(
        triggerId: triggerId,
        intensity: intensity,
      );

      // Refresh recent sessions
      final recentSessions = await _getSessionsUseCase.getSessionsForCurrentWeek();

      state = AsyncValue.data(state.value!.copyWith(
        activeSession: session,
        recentSessions: recentSessions,
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Failed to start emergency session: $e',
      ));
    }
  }

  /// End the active emergency session
  Future<void> endEmergencySession({
    DateTime? customEndTime,
    bool? wasSuccessful,
    String? notes,
    String? helpfulStrategies,
    int? intensity,
  }) async {
    if (state.value?.activeSession == null) {
      state = AsyncValue.data(state.value!.copyWith(
        errorMessage: 'No active session to end',
      ));
      return;
    }

    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      final success = await _endUseCase.execute(
        sessionId: state.value!.activeSession!.id,
        customEndTime: customEndTime,
        wasSuccessful: wasSuccessful,
        notes: notes,
        helpfulStrategies: helpfulStrategies,
        intensity: intensity,
      );

      if (success) {
        // Refresh active session (should be null now)
        final activeSession = await _getActiveUseCase.execute();

        // Refresh recent sessions
        final recentSessions = await _getSessionsUseCase.getSessionsForCurrentWeek();

        state = AsyncValue.data(state.value!.copyWith(
          activeSession: activeSession,
          recentSessions: recentSessions,
          isLoading: false,
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          errorMessage: 'Failed to end emergency session',
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Error ending emergency session: $e',
      ));
    }
  }

  /// Add a trigger to the active session
  Future<void> addTriggerToSession(String triggerId) async {
    if (state.value?.activeSession == null) {
      // If no active session, start a new one with this trigger
      await startEmergencySession(triggerId: triggerId);
      return;
    }

    state = AsyncValue.data(state.value!.copyWith(isLoading: true, errorMessage: null));

    try {
      final success = await _repository.addTriggerToSession(
        state.value!.activeSession!.id,
        triggerId,
      );

      if (success) {
        // Refresh active session
        final activeSession = await _getActiveUseCase.execute();

        state = AsyncValue.data(state.value!.copyWith(
          activeSession: activeSession,
          isLoading: false,
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          errorMessage: 'Failed to add trigger to session',
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        errorMessage: 'Error adding trigger to session: $e',
      ));
    }
  }

  /// Get the duration of the active session
  Future<Duration?> getActiveDuration() async {
    return await _getActiveUseCase.getActiveDuration();
  }
}
