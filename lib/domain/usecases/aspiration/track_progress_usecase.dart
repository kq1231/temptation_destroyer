import '../../../data/models/aspiration_model.dart';
import '../../../data/repositories/aspiration_repository.dart';

/// Use case for tracking progress of aspirations
class TrackProgressUseCase {
  final AspirationRepository _repository;

  /// Constructor
  TrackProgressUseCase(this._repository);

  /// Mark an aspiration as achieved
  ///
  /// Returns true if the update was successful, or false if it failed
  Future<bool> markAsAchieved(int aspirationId) async {
    try {
      return await _repository.updateAchievementStatus(aspirationId, true);
    } catch (e) {
      throw Exception('Failed to mark aspiration as achieved: $e');
    }
  }

  /// Mark an aspiration as not achieved
  ///
  /// Returns true if the update was successful, or false if it failed
  Future<bool> markAsNotAchieved(int aspirationId) async {
    try {
      return await _repository.updateAchievementStatus(aspirationId, false);
    } catch (e) {
      throw Exception('Failed to mark aspiration as not achieved: $e');
    }
  }

  /// Toggle the achievement status of an aspiration
  ///
  /// Returns true if the update was successful, or false if it failed
  Future<bool> toggleAchievementStatus(int aspirationId) async {
    try {
      // Get the current status
      final aspiration = await _repository.getAspiration(aspirationId);

      if (aspiration == null) {
        throw Exception('Aspiration not found');
      }

      // Toggle the status
      return await _repository.updateAchievementStatus(
          aspirationId, !aspiration.isAchieved);
    } catch (e) {
      throw Exception('Failed to toggle aspiration status: $e');
    }
  }

  /// Get achievement statistics
  ///
  /// Returns a map with stats about aspirations achievement
  Future<Map<String, dynamic>> getAchievementStats() async {
    try {
      final achievedAspirations =
          await _repository.getAspirationsByStatus(true);
      final unachievedAspirations =
          await _repository.getAspirationsByStatus(false);

      // Calculate stats
      final totalCount =
          achievedAspirations.length + unachievedAspirations.length;
      final achievedCount = achievedAspirations.length;
      final achievementRate =
          totalCount > 0 ? (achievedCount / totalCount) * 100 : 0.0;

      // Group achieved aspirations by category
      final achievedByCategory = <String, int>{};
      for (final category in AspirationCategory.values) {
        final count = achievedAspirations
            .where((aspiration) => aspiration.category == category)
            .length;

        if (count > 0) {
          achievedByCategory[category] = count;
        }
      }

      return {
        'totalCount': totalCount,
        'achievedCount': achievedCount,
        'unachievedCount': unachievedAspirations.length,
        'achievementRate': achievementRate,
        'achievedByCategory': achievedByCategory,
      };
    } catch (e) {
      throw Exception('Failed to get achievement stats: $e');
    }
  }
}
