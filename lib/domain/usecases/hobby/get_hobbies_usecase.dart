import '../../../data/models/hobby_model.dart';
import '../../../data/repositories/hobby_repository.dart';

/// Use case for getting hobbies
class GetHobbiesUseCase {
  final HobbyRepository _repository;

  /// Constructor
  GetHobbiesUseCase(this._repository);

  /// Get all hobbies
  ///
  /// Returns a list of all hobbies
  Future<List<HobbyModel>> getAllHobbies() async {
    try {
      return await _repository.getAllHobbies();
    } catch (e) {
      throw Exception('Failed to get hobbies: $e');
    }
  }

  /// Get a hobby by ID
  ///
  /// Returns a single hobby or null if not found
  Future<HobbyModel?> getHobbyById(int id) async {
    try {
      return await _repository.getHobby(id);
    } catch (e) {
      throw Exception('Failed to get hobby: $e');
    }
  }

  /// Get hobbies by category
  ///
  /// Returns hobbies filtered by category
  Future<List<HobbyModel>> getHobbiesByCategory(HobbyCategory category) async {
    try {
      return await _repository.getHobbiesByCategory(category);
    } catch (e) {
      throw Exception('Failed to get hobbies by category: $e');
    }
  }

  /// Get suggested hobbies based on available time
  ///
  /// Returns hobbies that can be completed within the available minutes
  Future<List<HobbyModel>> getSuggestedHobbies(int availableMinutes) async {
    try {
      return await _repository.getSuggestedHobbies(availableMinutes);
    } catch (e) {
      throw Exception('Failed to get suggested hobbies: $e');
    }
  }

  /// Get hobbies grouped by category
  ///
  /// Returns a map of categories to list of hobbies
  Future<Map<HobbyCategory, List<HobbyModel>>>
      getHobbiesGroupedByCategory() async {
    try {
      final allHobbies = await _repository.getAllHobbies();

      // Group hobbies by category
      final Map<HobbyCategory, List<HobbyModel>> groupedHobbies = {};

      for (final hobby in allHobbies) {
        if (hobby.category != null) {
          if (!groupedHobbies.containsKey(hobby.category)) {
            groupedHobbies[hobby.category!] = [];
          }
          groupedHobbies[hobby.category!]!.add(hobby);
        }
      }

      return groupedHobbies;
    } catch (e) {
      throw Exception('Failed to get hobbies grouped by category: $e');
    }
  }

  /// Get recently practiced hobbies
  ///
  /// Returns a list of hobbies sorted by most recently practiced
  Future<List<HobbyModel>> getRecentlyPracticedHobbies({int limit = 5}) async {
    try {
      final allHobbies = await _repository.getAllHobbies();

      // Filter out hobbies that haven't been practiced
      final practicedHobbies =
          allHobbies.where((hobby) => hobby.lastPracticedAt != null).toList();

      // Sort by last practiced date (most recent first)
      practicedHobbies
          .sort((a, b) => b.lastPracticedAt!.compareTo(a.lastPracticedAt!));

      // Limit the number of results
      if (practicedHobbies.length > limit) {
        return practicedHobbies.sublist(0, limit);
      }

      return practicedHobbies;
    } catch (e) {
      throw Exception('Failed to get recently practiced hobbies: $e');
    }
  }
}
