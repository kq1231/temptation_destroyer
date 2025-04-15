import '../../../data/repositories/auth_repository.dart';

/// Use case for managing recovery codes
class RecoveryCodesUseCase {
  final AuthRepository _repository;

  /// Constructor
  RecoveryCodesUseCase(this._repository);

  /// Generate new recovery codes for the user
  ///
  /// Returns a list of recovery codes that can be used to reset the password
  Future<List<String>> generateRecoveryCodes({int count = 5}) async {
    return await _repository.generateRecoveryCodes(count);
  }

  /// Verify a recovery code
  ///
  /// Returns information about the verification result including success status,
  /// whether the user is rate limited, and a message explaining the result
  Future<Map<String, dynamic>> verifyRecoveryCode(String code) async {
    return await _repository.verifyRecoveryCode(code);
  }

  /// Reset the password using a recovery code
  ///
  /// Returns a map with result information including:
  /// - success: Whether the operation was successful
  /// - rateLimited: Whether the user is rate limited
  /// - message: A message explaining the result
  /// - remainingAttempts: How many attempts remain (if not successful or rate limited)
  /// - remainingMinutes: Minutes remaining in cooldown period (if rate limited)
  Future<Map<String, dynamic>> resetPasswordWithRecoveryCode(
      String recoveryCode, String newPassword) async {
    try {
      return await _repository.resetPasswordWithRecoveryCode(
          recoveryCode, newPassword);
    } catch (e) {
      return {
        'success': false,
        'rateLimited': false,
        'message': 'Error during password reset: $e'
      };
    }
  }

  /// Check if the user has any recovery codes set up
  Future<bool> hasRecoveryCodes() async {
    try {
      final user = await _repository.getUser();
      return user.recoveryCodes != null && user.recoveryCodes!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
