import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/emergency_session_model.dart';
import '../../data/repositories/emergency_repository.dart';
import '../../domain/usecases/emergency/start_emergency_session_usecase.dart';
import '../../domain/usecases/emergency/end_emergency_session_usecase.dart';
import '../../domain/usecases/emergency/get_active_session_usecase.dart';
import '../../domain/usecases/emergency/get_emergency_sessions_usecase.dart';

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

/// Notifier for emergency session state management
class EmergencySessionNotifier extends StateNotifier<EmergencySessionState> {
  final StartEmergencySessionUseCase _startUseCase;
  final EndEmergencySessionUseCase _endUseCase;
  final GetActiveSessionUseCase _getActiveUseCase;
  final GetEmergencySessionsUseCase _getSessionsUseCase;
  final EmergencyRepository _repository;

  EmergencySessionNotifier({
    required StartEmergencySessionUseCase startUseCase,
    required EndEmergencySessionUseCase endUseCase,
    required GetActiveSessionUseCase getActiveUseCase,
    required GetEmergencySessionsUseCase getSessionsUseCase,
    required EmergencyRepository repository,
  })  : _startUseCase = startUseCase,
        _endUseCase = endUseCase,
        _getActiveUseCase = getActiveUseCase,
        _getSessionsUseCase = getSessionsUseCase,
        _repository = repository,
        super(EmergencySessionState());

  /// Initialize the state by loading active session and recent sessions
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final activeSession = await _getActiveUseCase.execute();
      final recentSessions =
          await _getSessionsUseCase.getSessionsForCurrentWeek();

      state = state.copyWith(
        activeSession: activeSession,
        recentSessions: recentSessions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
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
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final session = await _startUseCase.execute(
        triggerId: triggerId,
        intensity: intensity,
      );

      // Refresh recent sessions
      final recentSessions =
          await _getSessionsUseCase.getSessionsForCurrentWeek();

      state = state.copyWith(
        activeSession: session,
        recentSessions: recentSessions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to start emergency session: $e',
      );
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
    if (state.activeSession == null) {
      state = state.copyWith(
        errorMessage: 'No active session to end',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final success = await _endUseCase.execute(
        sessionId: state.activeSession!.id,
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
        final recentSessions =
            await _getSessionsUseCase.getSessionsForCurrentWeek();

        state = state.copyWith(
          activeSession: activeSession,
          recentSessions: recentSessions,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to end emergency session',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error ending emergency session: $e',
      );
    }
  }

  /// Add a trigger to the active session
  Future<void> addTriggerToSession(String triggerId) async {
    if (state.activeSession == null) {
      // If no active session, start a new one with this trigger
      await startEmergencySession(triggerId: triggerId);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final success = await _repository.addTriggerToSession(
        state.activeSession!.id,
        triggerId,
      );

      if (success) {
        // Refresh active session
        final activeSession = await _getActiveUseCase.execute();

        state = state.copyWith(
          activeSession: activeSession,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to add trigger to session',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error adding trigger to session: $e',
      );
    }
  }

  /// Get the duration of the active session
  Future<Duration?> getActiveDuration() async {
    return await _getActiveUseCase.getActiveDuration();
  }
}

/// Provider for the emergency session state
final emergencySessionProvider =
    StateNotifierProvider<EmergencySessionNotifier, EmergencySessionState>(
        (ref) {
  return EmergencySessionNotifier(
    startUseCase: ref.watch(startEmergencySessionUseCaseProvider),
    endUseCase: ref.watch(endEmergencySessionUseCaseProvider),
    getActiveUseCase: ref.watch(getActiveSessionUseCaseProvider),
    getSessionsUseCase: ref.watch(getEmergencySessionsUseCaseProvider),
    repository: ref.watch(emergencyRepositoryProvider),
  );
});
