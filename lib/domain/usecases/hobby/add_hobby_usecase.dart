import '../../../data/models/hobby_model.dart';
import '../../../data/repositories/hobby_repository.dart';

/// Use case for adding a new hobby
class AddHobbyUseCase {
  final HobbyRepository _repository;

  /// Constructor
  AddHobbyUseCase(this._repository);

  /// Add a new hobby
  ///
  /// Returns the ID of the newly added hobby, or throws an exception if failed
  Future<int> execute(HobbyModel hobby) async {
    try {
      return await _repository.addHobby(hobby);
    } catch (e) {
      throw Exception('Failed to add hobby: $e');
    }
  }

  /// Add a new hobby with details
  ///
  /// Convenience method that creates a HobbyModel object from parameters
  Future<int> addHobby({
    required String name,
    String? description,
    String category = HobbyCategory.physical,
    String? frequencyGoal,
    int? durationGoalMinutes,
    int? satisfactionRating,
  }) async {
    final hobby = HobbyModel(
      name: name,
      description: description,
      categoryParam: category,
      frequencyGoal: frequencyGoal,
      durationGoalMinutes: durationGoalMinutes,
      satisfactionRating: satisfactionRating,
    );

    return execute(hobby);
  }

  /// Import all preset hobbies
  ///
  /// Returns the number of hobbies imported
  Future<int> importPresetHobbies() async {
    try {
      return await _repository.importPresetHobbies();
    } catch (e) {
      throw Exception('Failed to import preset hobbies: $e');
    }
  }
}
