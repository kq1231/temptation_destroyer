import '../../../data/repositories/emergency_repository.dart';

/// Use case for ending an active emergency session
class EndEmergencySessionUseCase {
  final EmergencyRepository _repository;

  /// Constructor for dependency injection
  EndEmergencySessionUseCase(this._repository);

  /// Execute the use case to end an active emergency session
  ///
  /// [sessionId] - The ID of the session to end
  /// [customEndTime] - Optional custom end time (if not specified, uses current time)
  /// [wasSuccessful] - Whether the user successfully resisted the temptation
  /// [notes] - Any notes the user wants to add about this session
  /// [helpfulStrategies] - Strategies that helped during this session
  /// [intensity] - The final intensity rating for the session
  /// Returns true if the session was successfully ended
  Future<bool> execute({
    required int sessionId,
    DateTime? customEndTime,
    bool? wasSuccessful,
    String? notes,
    String? helpfulStrategies,
    int? intensity,
  }) async {
    return await _repository.endSession(
      sessionId: sessionId,
      customEndTime: customEndTime,
      wasSuccessful: wasSuccessful,
      notes: notes,
      helpfulStrategies: helpfulStrategies,
      intensity: intensity,
    );
  }
}
