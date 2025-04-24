import '../models/aspiration_model.dart';
import '../../core/utils/object_box_manager.dart';
import '../../objectbox.g.dart'; // Import generated ObjectBox code
import 'dart:developer' as dev;

/// Repository for managing user's aspirations and goals
class AspirationRepository {
  /// Add a new aspiration
  ///
  /// Returns the ID of the newly added aspiration
  Future<int> addAspiration(AspirationModel aspiration) async {
    try {
      final box = ObjectBoxManager.instance.box<AspirationModel>();

      // Check if an aspiration with the same dua already exists
      final existingAspirations =
          box.query(AspirationModel_.dua.equals(aspiration.dua)).build().find();

      if (existingAspirations.isNotEmpty) {
        throw Exception('An aspiration with this dua already exists');
      }

      return box.put(aspiration);
    } catch (e) {
      dev.log('Error adding aspiration: $e');
      throw Exception('Failed to add aspiration: $e');
    }
  }

  /// Update an existing aspiration
  ///
  /// Returns true if the update was successful
  Future<bool> updateAspiration(AspirationModel aspiration) async {
    try {
      final box = ObjectBoxManager.instance.box<AspirationModel>();

      // Check if the aspiration exists
      final existingAspiration = box.get(aspiration.id);
      if (existingAspiration == null) {
        throw Exception('Aspiration not found');
      }

      box.put(aspiration);
      return true;
    } catch (e) {
      dev.log('Error updating aspiration: $e');
      return false;
    }
  }

  /// Delete an aspiration by ID
  ///
  /// Returns true if the deletion was successful
  Future<bool> deleteAspiration(int aspirationId) async {
    try {
      final box = ObjectBoxManager.instance.box<AspirationModel>();
      return box.remove(aspirationId);
    } catch (e) {
      dev.log('Error deleting aspiration: $e');
      return false;
    }
  }

  /// Get an aspiration by ID
  ///
  /// Returns null if no aspiration with the given ID exists
  Future<AspirationModel?> getAspiration(int aspirationId) async {
    final box = ObjectBoxManager.instance.box<AspirationModel>();
    return box.get(aspirationId);
  }

  /// Get all aspirations
  ///
  /// Returns an empty list if no aspirations exist
  Future<List<AspirationModel>> getAllAspirations() async {
    final box = ObjectBoxManager.instance.box<AspirationModel>();
    return box.getAll();
  }

  /// Get aspirations by category
  ///
  /// Returns aspirations of the specified category
  Future<List<AspirationModel>> getAspirationsByCategory(
      String category) async {
    final box = ObjectBoxManager.instance.box<AspirationModel>();

    // Query for aspirations of the specified category
    final query = box.query(AspirationModel_.category.equals(category)).build();
    final results = query.find();
    query.close();

    return results;
  }

  /// Get aspirations by achievement status
  ///
  /// Returns aspirations based on whether they've been achieved
  Future<List<AspirationModel>> getAspirationsByStatus(bool isAchieved) async {
    final box = ObjectBoxManager.instance.box<AspirationModel>();

    // Query for aspirations with the specified achievement status
    final query =
        box.query(AspirationModel_.isAchieved.equals(isAchieved)).build();
    final results = query.find();
    query.close();

    return results;
  }

  /// Mark an aspiration as achieved or not achieved
  ///
  /// Returns true if the update was successful
  Future<bool> updateAchievementStatus(
      int aspirationId, bool isAchieved) async {
    try {
      final box = ObjectBoxManager.instance.box<AspirationModel>();
      final aspiration = box.get(aspirationId);

      if (aspiration == null) {
        throw Exception('Aspiration not found');
      }

      // Update achievement status and date if achieved
      aspiration.isAchieved = isAchieved;
      aspiration.achievedDate = isAchieved ? DateTime.now() : null;

      // Save the updated aspiration
      box.put(aspiration);

      return true;
    } catch (e) {
      dev.log('Error updating aspiration achievement status: $e');
      return false;
    }
  }

  /// Import preset aspirations
  ///
  /// Returns the number of aspirations imported
  Future<int> importPresetAspirations() async {
    try {
      final presets = AspirationModel.getPresets();
      final box = ObjectBoxManager.instance.box<AspirationModel>();

      // Save all presets
      int importedCount = 0;
      for (final preset in presets) {
        // Check if an aspiration with the same dua already exists
        final existingAspirations =
            box.query(AspirationModel_.dua.equals(preset.dua)).build().find();

        if (existingAspirations.isEmpty) {
          box.put(preset);
          importedCount++;
        }
      }

      return importedCount;
    } catch (e) {
      dev.log('Error importing preset aspirations: $e');
      return 0;
    }
  }
}
