import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for app initialization
final appStartProvider = FutureProvider<void>((ref) async {
  // Initialize all required services
  await _initializeServices(ref);
});

/// Initialize all required services
Future<void> _initializeServices(Ref ref) async {
  // Add any other service initializations here if needed
  // This is where we would initialize other services like authentication, etc.
}
