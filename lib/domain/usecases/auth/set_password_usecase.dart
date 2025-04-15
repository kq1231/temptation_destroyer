import '../../../data/repositories/auth_repository.dart';
import 'dart:developer' as dev;

/// Use case for setting a user's password (both initial and update)
class SetPasswordUseCase {
  final AuthRepository _repository;

  /// Constructor for dependency injection
  SetPasswordUseCase(this._repository);

  /// Execute the password setting process for a new user
  ///
  /// [password] - The password to set
  /// Returns true if password was successfully set, false otherwise
  Future<bool> execute(String password) async {
    try {
      // Save the password
      return await _repository.savePassword(password);
    } catch (e) {
      // Log the error but don't expose details to caller
      dev.log('Error setting password: $e');
      return false;
    }
  }

  /// Execute the password update process for existing users
  ///
  /// [oldPassword] - The current password
  /// [newPassword] - The new password to set
  /// Returns true if password was successfully updated, false otherwise
  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    try {
      // Update the password
      return await _repository.updatePassword(oldPassword, newPassword);
    } catch (e) {
      // Log the error but don't expose details to caller
      dev.log('Error updating password: $e');
      return false;
    }
  }
}
