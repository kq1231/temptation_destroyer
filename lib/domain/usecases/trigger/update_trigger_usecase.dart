import '../../../data/models/trigger_model.dart';
import '../../../data/repositories/trigger_repository.dart';

/// Use case for updating an existing trigger
class UpdateTriggerUseCase {
  final TriggerRepository _repository;

  /// Constructor
  UpdateTriggerUseCase(this._repository);

  /// Update an existing trigger
  ///
  /// Returns true if update was successful, or throws an exception if failed
  Future<bool> execute(Trigger trigger) async {
    try {
      return await _repository.updateTrigger(trigger);
    } catch (e) {
      throw Exception('Failed to update trigger: $e');
    }
  }

  /// Update trigger properties
  ///
  /// Updates only the specified properties of the trigger
  Future<bool> updateTriggerProperties({
    required int triggerId,
    String? description,
    String? triggerType,
    int? intensity,
    String? notes,
    List<String>? activeTimes,
    List<int>? activeDays,
  }) async {
    try {
      // Get the existing trigger
      final existingTrigger = await _repository.getTrigger(triggerId);

      if (existingTrigger == null) {
        throw Exception('Trigger not found with ID $triggerId');
      }

      // Update only the specified properties
      if (description != null) {
        existingTrigger.description = description;
      }

      if (triggerType != null) {
        existingTrigger.triggerType = triggerType;
      }

      if (intensity != null) {
        existingTrigger.intensity = intensity;
      }

      if (notes != null) {
        existingTrigger.notes = notes;
      }

      if (activeTimes != null) {
        existingTrigger.activeTimesList = activeTimes;
      }

      if (activeDays != null) {
        existingTrigger.activeDaysList = activeDays;
      }

      // Save the updated trigger
      return await _repository.updateTrigger(existingTrigger);
    } catch (e) {
      throw Exception('Failed to update trigger properties: $e');
    }
  }
}
