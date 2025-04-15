import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import 'dart:developer' as dev;

/// Authentication status enum
enum AuthStatus {
  /// New user, needs to set up a password
  newUser,

  /// Existing user, needs to login
  existingUser,

  /// User is authenticated
  authenticated,

  /// Error occurred while checking status
  error
}

/// Use case for getting the user's authentication status
class GetUserStatusUseCase {
  final AuthRepository _repository;

  /// Constructor for dependency injection
  GetUserStatusUseCase(this._repository);

  /// Execute the use case to get the user's authentication status
  Future<AuthStatus> execute() async {
    try {
      // Get the user from the repository
      final user = await _repository.getUser();

      // Determine the status based on user properties
      if (user.id == 0 && user.hashedPassword.isEmpty) {
        // New user, no password set yet
        return AuthStatus.newUser;
      } else if (!user.isFirstLogin) {
        // Existing user who has logged in before
        return AuthStatus.existingUser;
      } else {
        // User has just set their password but isn't fully authenticated yet
        return AuthStatus.existingUser;
      }
    } catch (e) {
      dev.log('Error getting user status: $e');
      return AuthStatus.error;
    }
  }

  /// Get the user instance
  Future<User> getUser() async {
    try {
      return await _repository.getUser();
    } catch (e) {
      dev.log('Error getting user: $e');
      // Return a blank user model in case of error
      return User(hashedPassword: '', isFirstLogin: true);
    }
  }
}
