import '../../../data/models/emergency_session_model.dart';
import '../../../data/repositories/emergency_repository.dart';

/// Use case for starting a new emergency session
class StartEmergencySessionUseCase {
  final EmergencyRepository _repository;

  /// Constructor for dependency injection
  StartEmergencySessionUseCase(this._repository);

  /// Execute the use case to start a new emergency session
  ///
  /// [triggerId] - Optional initial trigger ID to associate with this session
  /// [intensity] - Optional initial intensity level (1-10)
  /// [notes] - Optional notes about the session
  /// Returns the newly created emergency session
  Future<EmergencySession> execute({
    String? triggerId,
    int? intensity,
    String? notes,
  }) async {
    // Check if there's already an active session
    final activeSession = await _repository.getActiveSession();

    // If there's already an active session, return it
    if (activeSession != null) {
      // If a trigger ID was provided, add it to the session
      if (triggerId != null) {
        await _repository.addTriggerToSession(activeSession.id, triggerId);

        // Get the updated session
        final updatedSession = await _repository.getActiveSession();
        return updatedSession!;
      }

      return activeSession;
    }

    // Create a new emergency session
    final newSession = EmergencySession(
      startTime: DateTime.now(),
      endTime: null,
      activeTriggerIds: triggerId ?? '',
      intensity: intensity ?? 5, // Default to medium intensity if not specified
      notes: notes ?? '',
      wasSuccessful: null,
      helpfulStrategies: '',
    );

    // Save and return the new session
    return await _repository.saveSession(newSession);
  }
}
