import '../../../data/models/emergency_session_model.dart';
import '../../../data/repositories/emergency_repository.dart';

/// Use case for retrieving the currently active emergency session
class GetActiveSessionUseCase {
  final EmergencyRepository _repository;

  /// Constructor for dependency injection
  GetActiveSessionUseCase(this._repository);

  /// Execute the use case to get the active emergency session
  ///
  /// Returns the active emergency session or null if none exists
  Future<EmergencySession?> execute() async {
    return await _repository.getActiveSession();
  }

  /// Check if there is an active emergency session
  Future<bool> hasActiveSession() async {
    return await _repository.hasActiveSession();
  }

  /// Get the duration of the current active session
  Future<Duration?> getActiveDuration() async {
    final activeSession = await _repository.getActiveSession();
    if (activeSession == null) {
      return null;
    }
    return _repository.getSessionDuration(activeSession);
  }
}
