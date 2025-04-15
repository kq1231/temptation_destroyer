import '../../../data/models/trigger_model.dart';
import '../../../data/repositories/trigger_repository.dart';

/// Use case for adding a new trigger
class AddTriggerUseCase {
  final TriggerRepository _repository;

  /// Constructor
  AddTriggerUseCase(this._repository);

  /// Add a new trigger
  ///
  /// Returns the ID of the newly added trigger, or throws an exception if failed
  Future<int> execute(Trigger trigger) async {
    try {
      return await _repository.addTrigger(trigger);
    } catch (e) {
      throw Exception('Failed to add trigger: $e');
    }
  }

  /// Add a new trigger with details
  ///
  /// Convenience method that creates a Trigger object from parameters
  Future<int> addTrigger({
    required String description,
    required TriggerType triggerType,
    int intensity = 5,
    String? notes,
    List<String>? activeTimes,
    List<int>? activeDays,
  }) async {
    final trigger = Trigger.withEnum(
      description: description,
      triggerType: triggerType,
      intensity: intensity,
      notes: notes,
      activeTimes: activeTimes?.join(','),
      activeDays: activeDays?.join(','),
    );

    return execute(trigger);
  }
}
