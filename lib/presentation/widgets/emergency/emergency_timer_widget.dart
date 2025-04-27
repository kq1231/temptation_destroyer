import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/emergency_session_provider_refactored.dart';

/// A dedicated widget for displaying the emergency timer
/// This widget uses local state for the timer to ensure it updates properly
class EmergencyTimerWidget extends ConsumerStatefulWidget {
  /// Constructor
  const EmergencyTimerWidget({super.key});

  @override
  ConsumerState<EmergencyTimerWidget> createState() =>
      _EmergencyTimerWidgetState();
}

class _EmergencyTimerWidgetState extends ConsumerState<EmergencyTimerWidget> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _startTime;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Start the timer in initState
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Initialize the timer with the active session start time
      _initializeTimer();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Initialize the timer based on the active session
  Future<void> _initializeTimer() async {
    final emergencyState = ref.read(emergencySessionNotifierProvider);

    if (emergencyState.hasValue &&
        emergencyState.value?.activeSession != null) {
      final activeSession = emergencyState.value!.activeSession!;
      // Get the start time from the active session
      final startTime = activeSession.startTime;

      // Update the state with the start time
      setState(() {
        _startTime = startTime;
        _elapsed = DateTime.now().difference(startTime);
      });
    }
  }

  /// Start the timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

  /// Format the elapsed time as HH:MM:SS
  String get formattedTime {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes.remainder(60);
    final seconds = _elapsed.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format the elapsed time in a human-readable format
  String get humanReadableTime {
    if (_elapsed.inSeconds < 60) {
      return '${_elapsed.inSeconds} seconds';
    } else if (_elapsed.inMinutes < 60) {
      final minutes = _elapsed.inMinutes;
      final seconds = _elapsed.inSeconds.remainder(60);
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} $seconds ${seconds == 1 ? 'second' : 'seconds'}';
    } else {
      final hours = _elapsed.inHours;
      final minutes = _elapsed.inMinutes.remainder(60);
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the emergency session state
    ref.listen(emergencySessionNotifierProvider, (previous, next) {
      if (next.hasValue) {
        if (next.value?.activeSession == null && _timer != null) {
          // If there's no active session, stop the timer
          _timer?.cancel();
          setState(() {
            _elapsed = Duration.zero;
            _startTime = null;
          });
        } else if (next.value?.activeSession != null && _startTime == null) {
          // If there's a new active session, initialize the timer
          _initializeTimer();
          if (_timer == null || !(_timer?.isActive ?? false)) {
            _startTimer();
          }
        }
      }
    });

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              AppStrings.emergencyTimerLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              formattedTime,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.emergencyRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              humanReadableTime,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
