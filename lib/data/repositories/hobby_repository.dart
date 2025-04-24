import '../models/hobby_model.dart';
import '../../core/utils/object_box_manager.dart';
import '../../objectbox.g.dart'; // Import generated ObjectBox code
import 'dart:developer' as dev;

/// Repository for managing user's hobbies
class HobbyRepository {
  /// Add a new hobby
  ///
  /// Returns the ID of the newly added hobby
  Future<int> addHobby(HobbyModel hobby) async {
    try {
      final box = ObjectBoxManager.instance.box<HobbyModel>();

      // Check if a hobby with the same name already exists
      final existingHobbies =
          box.query(HobbyModel_.name.equals(hobby.name)).build().find();

      if (existingHobbies.isNotEmpty) {
        throw Exception('A hobby with this name already exists');
      }

      return box.put(hobby);
    } catch (e) {
      dev.log('Error adding hobby: $e');
      throw Exception('Failed to add hobby: $e');
    }
  }

  /// Update an existing hobby
  ///
  /// Returns true if the update was successful
  Future<bool> updateHobby(HobbyModel hobby) async {
    try {
      final box = ObjectBoxManager.instance.box<HobbyModel>();

      // Check if the hobby exists
      final existingHobby = box.get(hobby.id);
      if (existingHobby == null) {
        throw Exception('Hobby not found');
      }

      box.put(hobby);
      return true;
    } catch (e) {
      dev.log('Error updating hobby: $e');
      return false;
    }
  }

  /// Delete a hobby by ID
  ///
  /// Returns true if the deletion was successful
  Future<bool> deleteHobby(int hobbyId) async {
    try {
      final box = ObjectBoxManager.instance.box<HobbyModel>();
      return box.remove(hobbyId);
    } catch (e) {
      dev.log('Error deleting hobby: $e');
      return false;
    }
  }

  /// Get a hobby by ID
  ///
  /// Returns null if no hobby with the given ID exists
  Future<HobbyModel?> getHobby(int hobbyId) async {
    final box = ObjectBoxManager.instance.box<HobbyModel>();
    return box.get(hobbyId);
  }

  /// Get all hobbies
  ///
  /// Returns an empty list if no hobbies exist
  Future<List<HobbyModel>> getAllHobbies() async {
    final box = ObjectBoxManager.instance.box<HobbyModel>();
    return box.getAll();
  }

  /// Get hobbies by category
  ///
  /// Returns hobbies of the specified category
  Future<List<HobbyModel>> getHobbiesByCategory(String category) async {
    final box = ObjectBoxManager.instance.box<HobbyModel>();

    // Query for hobbies of the specified category
    final query = box.query(HobbyModel_.category.equals(category)).build();
    final results = query.find();
    query.close();

    return results;
  }

  /// Track hobby engagement - update the last practiced date
  ///
  /// Returns true if the update was successful
  Future<bool> trackEngagement(int hobbyId, {DateTime? engagementTime}) async {
    try {
      final box = ObjectBoxManager.instance.box<HobbyModel>();
      final hobby = box.get(hobbyId);

      if (hobby == null) {
        throw Exception('Hobby not found');
      }

      // Update last practiced date
      hobby.lastPracticedAt = engagementTime ?? DateTime.now();

      // Save the updated hobby
      box.put(hobby);

      return true;
    } catch (e) {
      dev.log('Error tracking hobby engagement: $e');
      return false;
    }
  }

  /// Get suggested hobbies based on available time
  ///
  /// Returns hobbies that can be completed within the available time
  Future<List<HobbyModel>> getSuggestedHobbies(int availableMinutes) async {
    try {
      final box = ObjectBoxManager.instance.box<HobbyModel>();

      // Query for hobbies that can be completed within the available time
      final query = box
          .query(HobbyModel_.durationGoalMinutes.lessOrEqual(availableMinutes))
          .order(HobbyModel_.lastPracticedAt, flags: Order.descending)
          .build();

      final results = query.find();
      query.close();

      return results;
    } catch (e) {
      dev.log('Error getting suggested hobbies: $e');
      return [];
    }
  }

  /// Import preset hobbies
  ///
  /// Returns the number of hobbies imported
  Future<int> importPresetHobbies() async {
    try {
      final presets = HobbyModel.getPresets();
      final box = ObjectBoxManager.instance.box<HobbyModel>();

      // Save all presets
      int importedCount = 0;
      for (final preset in presets) {
        // Check if a hobby with the same name already exists
        final existingHobbies =
            box.query(HobbyModel_.name.equals(preset.name)).build().find();

        if (existingHobbies.isEmpty) {
          box.put(preset);
          importedCount++;
        }
      }

      return importedCount;
    } catch (e) {
      dev.log('Error importing preset hobbies: $e');
      return 0;
    }
  }
}
