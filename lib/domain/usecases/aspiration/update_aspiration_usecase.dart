import '../../../data/models/aspiration_model.dart';
import '../../../data/repositories/aspiration_repository.dart';

/// Use case for updating an existing aspiration
class UpdateAspirationUseCase {
  final AspirationRepository _repository;

  /// Constructor
  UpdateAspirationUseCase(this._repository);

  /// Update an existing aspiration
  ///
  /// Returns true if the update was successful, or false if it failed
  Future<bool> execute(AspirationModel aspiration) async {
    try {
      return await _repository.updateAspiration(aspiration);
    } catch (e) {
      throw Exception('Failed to update aspiration: $e');
    }
  }

  /// Update an aspiration with details
  ///
  /// Convenience method that updates an aspiration with the given details
  Future<bool> updateAspiration({
    required int id,
    String? dua,
    String? category,
    bool? isAchieved,
    DateTime? targetDate,
    String? note,
    DateTime? achievedDate,
  }) async {
    try {
      // Get the existing aspiration
      final existingAspiration = await _repository.getAspiration(id);
      if (existingAspiration == null) {
        throw Exception('Aspiration not found');
      }

      // Update the aspiration with new values
      final updatedAspiration = existingAspiration.copyWith(
        dua: dua,
        category: category,
        isAchieved: isAchieved,
        targetDate: targetDate,
        note: note,
        achievedDate: achievedDate,
      );

      return await execute(updatedAspiration);
    } catch (e) {
      throw Exception('Failed to update aspiration: $e');
    }
  }

  /// Mark an aspiration as achieved or not achieved
  ///
  /// Returns true if the update was successful, or false if it failed
  Future<bool> updateAchievementStatus(
      int aspirationId, bool isAchieved) async {
    try {
      return await _repository.updateAchievementStatus(
          aspirationId, isAchieved);
    } catch (e) {
      throw Exception('Failed to update aspiration status: $e');
    }
  }
}
