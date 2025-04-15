import '../../../data/repositories/trigger_repository.dart';

/// Use case for deleting a trigger
class DeleteTriggerUseCase {
  final TriggerRepository _repository;

  /// Constructor
  DeleteTriggerUseCase(this._repository);

  /// Delete a trigger by ID
  ///
  /// Returns true if deletion was successful, false if the trigger wasn't found,
  /// or throws an exception if there was an error
  Future<bool> execute(int triggerId) async {
    try {
      return await _repository.deleteTrigger(triggerId);
    } catch (e) {
      throw Exception('Failed to delete trigger: $e');
    }
  }

  /// Delete multiple triggers by ID
  ///
  /// Returns the number of successfully deleted triggers
  Future<int> deleteMultipleTriggers(List<int> triggerIds) async {
    int deleteCount = 0;

    for (final id in triggerIds) {
      try {
        final success = await _repository.deleteTrigger(id);
        if (success) {
          deleteCount++;
        }
      } catch (e) {
        // Continue with other deletions even if one fails
        continue;
      }
    }

    return deleteCount;
  }
}
