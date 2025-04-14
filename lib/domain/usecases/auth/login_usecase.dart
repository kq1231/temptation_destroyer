import '../../../data/repositories/auth_repository.dart';

/// Use case for user login
class LoginUseCase {
  final AuthRepository _repository;

  /// Constructor for dependency injection
  LoginUseCase(this._repository);

  /// Execute the login process
  ///
  /// [password] - The user's password
  /// Returns true if login was successful, false otherwise
  Future<bool> execute(String password) async {
    try {
      // Verify the password
      final isValid = await _repository.verifyPassword(password);

      return isValid;
    } catch (e) {
      // Log the error but don't expose details to caller
      print('Error during login: $e');
      return false;
    }
  }
}
