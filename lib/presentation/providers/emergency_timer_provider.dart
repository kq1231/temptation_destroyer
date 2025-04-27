import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'emergency_session_provider_refactored.dart';
import '../../domain/usecases/emergency/get_active_session_usecase.dart';

/// State for the emergency timer
class EmergencyTimerState {
  final Duration elapsed;
  final bool isRunning;

  const EmergencyTimerState({
    this.elapsed = Duration.zero,
    this.isRunning = false,
  });

  /// Create a copy of the state with updated values
  EmergencyTimerState copyWith({
    Duration? elapsed,
    bool? isRunning,
  }) {
    return EmergencyTimerState(
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  /// Format the elapsed time as HH:MM:SS
  String get formattedTime {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format the elapsed time based on how long it's been
  String get humanReadableTime {
    if (elapsed.inSeconds < 60) {
      return '${elapsed.inSeconds} seconds';
    } else if (elapsed.inMinutes < 60) {
      final minutes = elapsed.inMinutes;
      final seconds = elapsed.inSeconds.remainder(60);
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} $seconds ${seconds == 1 ? 'second' : 'seconds'}';
    } else {
      final hours = elapsed.inHours;
      final minutes = elapsed.inMinutes.remainder(60);
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
  }
}

/// Notifier for emergency timer state management
class EmergencyTimerNotifier extends StateNotifier<EmergencyTimerState> {
  final GetActiveSessionUseCase _getActiveUseCase;
  final Ref _ref;
  Timer? _timer;

  EmergencyTimerNotifier({
    required GetActiveSessionUseCase getActiveUseCase,
    required Ref ref,
  })  : _getActiveUseCase = getActiveUseCase,
        _ref = ref,
        super(const EmergencyTimerState()) {
    // Setup listeners for the emergency session
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to changes in the emergency session state
    _ref.listen(emergencySessionNotifierProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        // If we have an active session but the timer isn't running, start it
        if (next.value!.activeSession != null && !state.isRunning) {
          startTimer();
        }

        // If we don't have an active session but the timer is running, stop it
        if (next.value!.activeSession == null && state.isRunning) {
          stopTimer();
          resetTimer();
        }
      }
    });
  }

  /// Initialize the timer by checking for an active session
  Future<void> initialize() async {
    final hasActiveSession = await _getActiveUseCase.hasActiveSession();

    if (hasActiveSession) {
      final activeDuration = await _getActiveUseCase.getActiveDuration();

      if (activeDuration != null) {
        state = state.copyWith(
          elapsed: activeDuration,
          isRunning: true,
        );

        // Start the timer
        _startTimer();
      }
    }
  }

  /// Start the emergency timer
  void startTimer() {
    if (!state.isRunning) {
      state = state.copyWith(isRunning: true);
      _startTimer();
    }
  }

  /// Stop the emergency timer
  void stopTimer() {
    if (state.isRunning) {
      _timer?.cancel();
      state = state.copyWith(isRunning: false);
    }
  }

  /// Reset the emergency timer
  void resetTimer() {
    _timer?.cancel();
    state = const EmergencyTimerState();
  }

  /// Start the internal timer
  void _startTimer() {
    _timer?.cancel();

    // Update the timer every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsed: state.elapsed + const Duration(seconds: 1),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
