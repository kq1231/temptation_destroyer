import '../../../data/repositories/aspiration_repository.dart';

/// Use case for deleting an aspiration
class DeleteAspirationUseCase {
  final AspirationRepository _repository;

  /// Constructor
  DeleteAspirationUseCase(this._repository);

  /// Delete an aspiration by ID
  ///
  /// Returns true if the deletion was successful, or false if it failed
  Future<bool> execute(int aspirationId) async {
    try {
      return await _repository.deleteAspiration(aspirationId);
    } catch (e) {
      throw Exception('Failed to delete aspiration: $e');
    }
  }
}
