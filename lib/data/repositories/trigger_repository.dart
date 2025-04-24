import '../models/trigger_model.dart';
import '../../core/utils/object_box_manager.dart';
import '../../objectbox.g.dart'; // Import generated ObjectBox code
import 'dart:developer' as dev;

/// Repository for managing user's triggers
class TriggerRepository {
  /// Add a new trigger
  ///
  /// Returns the ID of the newly added trigger
  Future<int> addTrigger(Trigger trigger) async {
    final box = ObjectBoxManager.instance.box<Trigger>();
    return box.put(trigger);
  }

  /// Update an existing trigger
  ///
  /// Returns true if the update was successful
  Future<bool> updateTrigger(Trigger trigger) async {
    try {
      final box = ObjectBoxManager.instance.box<Trigger>();
      box.put(trigger);
      return true;
    } catch (e) {
      dev.log('Error updating trigger: $e');
      return false;
    }
  }

  /// Delete a trigger by ID
  ///
  /// Returns true if the deletion was successful
  Future<bool> deleteTrigger(int triggerId) async {
    try {
      final box = ObjectBoxManager.instance.box<Trigger>();
      return box.remove(triggerId);
    } catch (e) {
      dev.log('Error deleting trigger: $e');
      return false;
    }
  }

  /// Get a trigger by ID
  ///
  /// Returns null if no trigger with the given ID exists
  Future<Trigger?> getTrigger(int triggerId) async {
    final box = ObjectBoxManager.instance.box<Trigger>();
    return box.get(triggerId);
  }

  /// Get a trigger by its external string ID
  ///
  /// Returns null if no trigger with the given ID exists
  Future<Trigger?> getTriggerByStringId(String triggerId) async {
    final box = ObjectBoxManager.instance.box<Trigger>();

    // Query for the trigger with the matching external ID
    final query = box.query(Trigger_.triggerId.equals(triggerId)).build();
    final results = query.find();
    query.close();

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  /// Get all triggers
  ///
  /// Returns an empty list if no triggers exist
  Future<List<Trigger>> getAllTriggers() async {
    final box = ObjectBoxManager.instance.box<Trigger>();
    return box.getAll();
  }

  /// Get triggers by type
  ///
  /// Returns triggers of the specified type, sorted by intensity (highest first)
  Future<List<Trigger>> getTriggersByType(String type) async {
    final box = ObjectBoxManager.instance.box<Trigger>();

    // Query for triggers of the specified type
    final query = box.query(Trigger_.triggerType.equals(type)).build();
    final results = query.find();
    query.close();

    // Sort by intensity (highest first)
    results.sort((a, b) => b.intensity.compareTo(a.intensity));

    return results;
  }

  /// Get triggers that are active at a specific time
  ///
  /// Returns triggers that are active at the given time, sorted by intensity
  Future<List<Trigger>> getActiveTriggersAt(DateTime time) async {
    final allTriggers = await getAllTriggers();

    // Filter for triggers that are active at the given time
    final activeTriggers =
        allTriggers.where((trigger) => trigger.isActiveAt(time)).toList();

    // Sort by intensity (highest first)
    activeTriggers.sort((a, b) => b.intensity.compareTo(a.intensity));

    return activeTriggers;
  }

  /// Search for triggers by keywords in description or notes
  ///
  /// Returns matching triggers sorted by relevance
  Future<List<Trigger>> searchTriggers(String searchText) async {
    if (searchText.trim().isEmpty) {
      return [];
    }

    final box = ObjectBoxManager.instance.box<Trigger>();
    final searchTerms = searchText.toLowerCase().split(' ');

    // Get all triggers and filter them manually
    final allTriggers = box.getAll();
    final matchingTriggers = allTriggers.where((trigger) {
      final description = trigger.description.toLowerCase();
      final notes = trigger.notes?.toLowerCase() ?? '';

      // Check if any search term is contained in description or notes
      return searchTerms
          .any((term) => description.contains(term) || notes.contains(term));
    }).toList();

    return matchingTriggers;
  }

  /// Count the total number of triggers
  Future<int> countTriggers() async {
    final box = ObjectBoxManager.instance.box<Trigger>();
    return box.count();
  }
}
