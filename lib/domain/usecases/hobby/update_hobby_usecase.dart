import '../../../data/models/hobby_model.dart';
import '../../../data/repositories/hobby_repository.dart';

/// Use case for updating an existing hobby
class UpdateHobbyUseCase {
  final HobbyRepository _repository;

  /// Constructor
  UpdateHobbyUseCase(this._repository);

  /// Update an existing hobby
  ///
  /// Returns true if the update was successful, or throws an exception if failed
  Future<bool> execute(HobbyModel hobby) async {
    try {
      return await _repository.updateHobby(hobby);
    } catch (e) {
      throw Exception('Failed to update hobby: $e');
    }
  }

  /// Track engagement with a hobby
  ///
  /// Updates the last practiced date for a hobby
  /// Returns true if the update was successful
  Future<bool> trackEngagement(int hobbyId, {DateTime? engagementTime}) async {
    try {
      return await _repository.trackEngagement(hobbyId,
          engagementTime: engagementTime);
    } catch (e) {
      throw Exception('Failed to track hobby engagement: $e');
    }
  }

  /// Update an existing hobby with new values
  ///
  /// Convenience method that accepts individual parameters to update a hobby
  Future<bool> updateHobby({
    required int id,
    String? name,
    String? description,
    HobbyCategory? category,
    String? frequencyGoal,
    int? durationGoalMinutes,
    int? satisfactionRating,
    DateTime? lastPracticedAt,
  }) async {
    // First get the existing hobby
    final existingHobby = await _repository.getHobby(id);
    if (existingHobby == null) {
      throw Exception('Hobby not found with id: $id');
    }

    // Update with new values
    final updatedHobby = existingHobby.copyWith(
      name: name,
      description: description,
      category: category,
      frequencyGoal: frequencyGoal,
      durationGoalMinutes: durationGoalMinutes,
      satisfactionRating: satisfactionRating,
      lastPracticedAt: lastPracticedAt,
    );

    return execute(updatedHobby);
  }
}
