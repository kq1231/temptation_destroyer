import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'emergency_session_provider_refactored.dart';
import 'emergency_timer_provider.dart';

/// Provider for app initialization
final appStartProvider = FutureProvider<void>((ref) async {
  // Initialize all required services
  await _initializeServices(ref);

  // Check for active emergency sessions
  await _checkForActiveEmergencySessions(ref);
});

/// Initialize all required services
Future<void> _initializeServices(Ref ref) async {
  // Add any other service initializations here if needed
  // This is where we would initialize other services like authentication, etc.
}

/// Check for active emergency sessions
Future<void> _checkForActiveEmergencySessions(Ref ref) async {
  // Get the active session use case
  final getActiveUseCase = ref.read(getActiveSessionUseCaseProvider);

  // Check if there's an active session
  final hasActiveSession = await getActiveUseCase.hasActiveSession();

  if (hasActiveSession) {
    // Initialize the emergency timer
    final timerNotifier = ref.read(emergencyTimerProvider.notifier);
    await timerNotifier.initialize();

    // Make sure the emergency session provider is initialized
    // This will ensure the active session is loaded when the app starts
    await ref.read(emergencySessionNotifierProvider.future);

    // Set a flag to show a notification after app initialization
    ref.read(shouldShowActiveSessionNotificationProvider.notifier).state = true;
  }
}

/// Provider to indicate if we should show the active session notification
final shouldShowActiveSessionNotificationProvider =
    StateProvider<bool>((ref) => false);

/// Provider to check if there's an active emergency session
final hasActiveEmergencySessionProvider = FutureProvider<bool>((ref) async {
  // Wait for app initialization to complete
  await ref.watch(appStartProvider.future);

  // Get the active session use case
  final getActiveUseCase = ref.read(getActiveSessionUseCaseProvider);

  // Check if there's an active session
  return await getActiveUseCase.hasActiveSession();
});
