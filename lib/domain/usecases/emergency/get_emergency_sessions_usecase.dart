import '../../../data/models/emergency_session_model.dart';
import '../../../data/repositories/emergency_repository.dart';

/// Use case for retrieving emergency sessions
class GetEmergencySessionsUseCase {
  final EmergencyRepository _repository;

  /// Constructor for dependency injection
  GetEmergencySessionsUseCase(this._repository);

  /// Get all emergency sessions, sorted by start time
  Future<List<EmergencySession>> getAllSessions() async {
    return await _repository.getAllSessions();
  }

  /// Get sessions within a specific time range
  Future<List<EmergencySession>> getSessionsByTimeRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _repository.getSessionsByTimeRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get sessions for the current day
  Future<List<EmergencySession>> getSessionsForToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await getSessionsByTimeRange(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Get sessions for the current week
  Future<List<EmergencySession>> getSessionsForCurrentWeek() async {
    final now = DateTime.now();
    // Find the start of the week (Sunday)
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final startOfDay =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfDay.add(const Duration(days: 7));

    return await getSessionsByTimeRange(
      startDate: startOfDay,
      endDate: endOfWeek,
    );
  }

  /// Get sessions for the current month
  Future<List<EmergencySession>> getSessionsForCurrentMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);

    return await getSessionsByTimeRange(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }
}
