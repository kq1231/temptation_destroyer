import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/emergency_session_provider_refactored.dart';

/// Service for showing in-app notifications
class NotificationService {
  /// Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  /// Factory constructor
  factory NotificationService() => _instance;

  /// Internal constructor
  NotificationService._internal();

  /// Global key for accessing the navigator state
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Show a snackbar notification
  void showSnackBar(String message, {bool isError = false}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show a dialog notification
  Future<void> showDialogNotification({
    required String title,
    required String message,
    required List<Widget> actions,
  }) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: actions,
        ),
      );
    }
  }

  /// Show active emergency session notification
  Future<void> showActiveSessionNotification(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (context) => Consumer(
        builder: (context, ref, _) => AlertDialog(
          title: const Text('Active Emergency Session'),
          content: const Text(
            'You have an active emergency session. Would you like to continue it or end it?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/emergency');
              },
              child: const Text('Continue Session'),
            ),
            TextButton(
              onPressed: () {
                // Get the navigator and scaffold messenger before async operations
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                // End the session
                final notifier =
                    ref.read(emergencySessionNotifierProvider.notifier);

                // Close the dialog first
                navigator.pop();

                // Then perform the async operations
                Future.microtask(() async {
                  await notifier.endEmergencySession(wasSuccessful: true);
                  // Show confirmation
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Emergency session ended successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                });
              },
              child: const Text('End Session'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Provider for the notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
