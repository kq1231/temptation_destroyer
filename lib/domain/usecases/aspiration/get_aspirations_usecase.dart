import '../../../data/models/aspiration_model.dart';
import '../../../data/repositories/aspiration_repository.dart';

/// Use case for getting aspirations
class GetAspirationsUseCase {
  final AspirationRepository _repository;

  /// Constructor
  GetAspirationsUseCase(this._repository);

  /// Get all aspirations
  ///
  /// Returns a list of all aspirations
  Future<List<AspirationModel>> getAllAspirations() async {
    try {
      return await _repository.getAllAspirations();
    } catch (e) {
      throw Exception('Failed to get aspirations: $e');
    }
  }

  /// Get an aspiration by ID
  ///
  /// Returns the aspiration with the given ID, or null if not found
  Future<AspirationModel?> getAspiration(int aspirationId) async {
    try {
      return await _repository.getAspiration(aspirationId);
    } catch (e) {
      throw Exception('Failed to get aspiration: $e');
    }
  }

  /// Get aspirations by category
  ///
  /// Returns a list of aspirations in the given category
  Future<List<AspirationModel>> getAspirationsByCategory(
      String category) async {
    try {
      return await _repository.getAspirationsByCategory(category);
    } catch (e) {
      throw Exception('Failed to get aspirations by category: $e');
    }
  }

  /// Get aspirations by achievement status
  ///
  /// Returns a list of aspirations based on whether they are achieved or not
  Future<List<AspirationModel>> getAspirationsByStatus(bool isAchieved) async {
    try {
      return await _repository.getAspirationsByStatus(isAchieved);
    } catch (e) {
      throw Exception('Failed to get aspirations by status: $e');
    }
  }

  /// Get aspirations grouped by category
  ///
  /// Returns a map of categories to lists of aspirations
  Future<Map<String, List<AspirationModel>>>
      getAspirationsGroupedByCategory() async {
    try {
      final allAspirations = await _repository.getAllAspirations();
      final result = <String, List<AspirationModel>>{};

      // Organize aspirations by category
      for (final category in AspirationCategory.values) {
        final aspirationsInCategory = allAspirations
            .where((aspiration) => aspiration.category == category)
            .toList();

        if (aspirationsInCategory.isNotEmpty) {
          result[category] = aspirationsInCategory;
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to get aspirations grouped by category: $e');
    }
  }

  /// Get recently added aspirations
  ///
  /// Returns a list of the most recently added aspirations
  Future<List<AspirationModel>> getRecentlyAddedAspirations(
      {int limit = 5}) async {
    try {
      final allAspirations = await _repository.getAllAspirations();

      // Sort by creation date (most recent first)
      allAspirations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Return up to the specified limit
      return allAspirations.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get recently added aspirations: $e');
    }
  }
}
