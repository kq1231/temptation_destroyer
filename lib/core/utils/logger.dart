import 'package:flutter/foundation.dart';

/// A utility class for logging messages in the app
class AppLogger {
  /// Log an informational message
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  /// Log an error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('Error details: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Log a debug message
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🔍 DEBUG: $message');
    }
  }
}
