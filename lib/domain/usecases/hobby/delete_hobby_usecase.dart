import '../../../data/repositories/hobby_repository.dart';

/// Use case for deleting a hobby
class DeleteHobbyUseCase {
  final HobbyRepository _repository;

  /// Constructor
  DeleteHobbyUseCase(this._repository);

  /// Delete a hobby by ID
  ///
  /// Returns true if the deletion was successful, false otherwise
  Future<bool> execute(int hobbyId) async {
    try {
      return await _repository.deleteHobby(hobbyId);
    } catch (e) {
      throw Exception('Failed to delete hobby: $e');
    }
  }
}
