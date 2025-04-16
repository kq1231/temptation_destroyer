import '../../../data/models/aspiration_model.dart';
import '../../../data/repositories/aspiration_repository.dart';

/// Use case for adding a new aspiration
class AddAspirationUseCase {
  final AspirationRepository _repository;

  /// Constructor
  AddAspirationUseCase(this._repository);

  /// Add a new aspiration
  ///
  /// Returns the ID of the newly added aspiration, or throws an exception if failed
  Future<int> execute(AspirationModel aspiration) async {
    try {
      return await _repository.addAspiration(aspiration);
    } catch (e) {
      throw Exception('Failed to add aspiration: $e');
    }
  }

  /// Add a new aspiration with details
  ///
  /// Convenience method that creates an AspirationModel object from parameters
  Future<int> addAspiration({
    required String dua,
    AspirationCategory category = AspirationCategory.personal,
    bool isAchieved = false,
    DateTime? targetDate,
    String? note,
  }) async {
    final aspiration = AspirationModel(
      dua: dua,
      category: category,
      isAchieved: isAchieved,
      targetDate: targetDate,
      note: note,
    );

    return execute(aspiration);
  }

  /// Import all preset aspirations
  ///
  /// Returns the number of aspirations imported
  Future<int> importPresetAspirations() async {
    try {
      return await _repository.importPresetAspirations();
    } catch (e) {
      throw Exception('Failed to import preset aspirations: $e');
    }
  }
}
