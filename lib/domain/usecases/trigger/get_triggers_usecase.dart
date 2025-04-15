import '../../../data/models/trigger_model.dart';
import '../../../data/repositories/trigger_repository.dart';

/// Use case for retrieving triggers with various filtering options
class GetTriggersUseCase {
  final TriggerRepository _repository;

  /// Constructor
  GetTriggersUseCase(this._repository);

  /// Get all triggers
  ///
  /// Returns a list of all triggers, or an empty list if none are found
  Future<List<Trigger>> getAllTriggers() async {
    try {
      return await _repository.getAllTriggers();
    } catch (e) {
      throw Exception('Failed to get triggers: $e');
    }
  }

  /// Get a trigger by ID
  ///
  /// Returns the trigger with the specified ID, or null if not found
  Future<Trigger?> getTriggerById(int triggerId) async {
    try {
      return await _repository.getTrigger(triggerId);
    } catch (e) {
      throw Exception('Failed to get trigger by ID: $e');
    }
  }

  /// Get triggers by type
  ///
  /// Returns triggers of the specified type, sorted by intensity
  Future<List<Trigger>> getTriggersByType(TriggerType type) async {
    try {
      return await _repository.getTriggersByType(type);
    } catch (e) {
      throw Exception('Failed to get triggers by type: $e');
    }
  }

  /// Get active triggers at a specific time
  ///
  /// Returns triggers that are active at the specified time
  Future<List<Trigger>> getActiveTriggersAt(DateTime time) async {
    try {
      return await _repository.getActiveTriggersAt(time);
    } catch (e) {
      throw Exception('Failed to get active triggers: $e');
    }
  }

  /// Get active triggers now
  ///
  /// Returns triggers that are active at the current time
  Future<List<Trigger>> getActiveTriggersNow() async {
    try {
      return await _repository.getActiveTriggersAt(DateTime.now());
    } catch (e) {
      throw Exception('Failed to get active triggers now: $e');
    }
  }

  /// Search triggers by keywords
  ///
  /// Returns triggers that match the search text in description or notes
  Future<List<Trigger>> searchTriggers(String searchText) async {
    try {
      return await _repository.searchTriggers(searchText);
    } catch (e) {
      throw Exception('Failed to search triggers: $e');
    }
  }

  /// Get trigger count
  ///
  /// Returns the total number of triggers
  Future<int> getTriggerCount() async {
    try {
      return await _repository.countTriggers();
    } catch (e) {
      throw Exception('Failed to count triggers: $e');
    }
  }
}
