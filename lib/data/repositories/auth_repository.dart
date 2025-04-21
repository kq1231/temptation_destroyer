import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:developer' as dev;
import '../models/user_model.dart';
import '../../core/utils/object_box_manager.dart';
import '../../core/utils/encryption_service.dart';

/// Repository for handling user authentication and password management.
///
/// IMPORTANT SECURITY DISTINCTION:
/// 1. Password Hashing: Uses salt + password for secure password storage.
///    - Salt is stored in the database (this is safe and standard practice)
///    - Used only for verifying login attempts
///    - Cannot be used to decrypt user data
///
/// 2. Data Encryption: Uses raw password as encryption key
///    - Password is never stored, only used in memory
///    - Required for decrypting user data
///    - Salt is never used for data encryption
///
/// This separation ensures that even if someone accesses the database,
/// they cannot decrypt user data without the actual password.
class AuthRepository {
  /// Get the user instance, creating it if it doesn't exist
  Future<User> getUser() async {
    final userBox = ObjectBoxManager.instance.box<User>();
    final users = userBox.getAll();

    if (users.isEmpty) {
      // No user exists yet, return a blank instance
      return User(
        hashedPassword: '',
        isFirstLogin: true,
      );
    }

    // Return the first user (there should only be one)
    return users.first;
  }

  /// Save a password for the user
  ///
  /// This method handles two separate security mechanisms:
  /// 1. Password Hashing: Creates a salt and hashes password+salt for secure storage
  /// 2. Data Encryption: Uses the raw password (not salt) to initialize encryption
  ///
  /// The salt is only used for password verification and NEVER for data encryption.
  Future<bool> savePassword(String password) async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();

      // Generate a salt for the password
      final salt = base64Encode(List<int>.generate(
          16, (_) => DateTime.now().microsecondsSinceEpoch % 256));

      // Hash the password with the salt
      final hashedPassword = _hashPassword(password, salt);

      // Get existing user or create a new one
      final users = userBox.getAll();
      final user = users.isEmpty
          ? User(
              hashedPassword: hashedPassword,
              passwordSalt: salt,
              lastLoginDate: DateTime.now(),
              isFirstLogin: true,
            )
          : users.first;

      // Update the user's password if it already exists
      if (users.isNotEmpty) {
        user.hashedPassword = hashedPassword;
        user.passwordSalt = salt;
        user.lastLoginDate = DateTime.now();
      }

      // Save the user
      userBox.put(user);

      // Initialize encryption with the password
      await EncryptionService.instance.initialize(password);

      return true;
    } catch (e) {
      dev.log('Error saving password: $e', name: 'AuthRepository');
      return false;
    }
  }

  /// Verify a password against the stored hash
  Future<bool> verifyPassword(String password) async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();
      final users = userBox.getAll();

      if (users.isEmpty) {
        return false; // No user exists
      }

      final user = users.first;
      final salt = user.passwordSalt;

      if (salt == null) {
        return false; // No salt found
      }

      // Hash the input password with the same salt
      final hashedInput = _hashPassword(password, salt);

      // Compare the hashed input with the stored hash
      final isValid = hashedInput == user.hashedPassword;

      if (isValid) {
        // Update last login date
        user.lastLoginDate = DateTime.now();
        userBox.put(user);

        // Initialize encryption with the password
        await EncryptionService.instance.initialize(password);
      }

      return isValid;
    } catch (e) {
      dev.log('Error verifying password: $e', name: 'AuthRepository');
      return false;
    }
  }

  /// Update the user's password
  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    try {
      // First verify the old password
      final isValid = await verifyPassword(oldPassword);

      if (!isValid) {
        return false; // Old password is incorrect
      }

      // Save the new password
      return await savePassword(newPassword);
    } catch (e) {
      dev.log('Error updating password: $e', name: 'AuthRepository');
      return false;
    }
  }

  /// Save security questions and answers for password recovery
  ///
  /// The questions and answers are provided as a list of key-value pairs.
  /// Answers are hashed before storage.
  Future<bool> saveSecurityQuestions(
      List<Map<String, String>> questionsAndAnswers) async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();
      final users = userBox.getAll();

      if (users.isEmpty) {
        return false; // No user exists
      }

      final user = users.first;

      // Hash the answers for security
      final hashedQuestionsAndAnswers = questionsAndAnswers.map((qna) {
        // Generate a salt for each answer
        final salt = base64Encode(List<int>.generate(
            8, (_) => DateTime.now().microsecondsSinceEpoch % 256));

        // Hash the answer with the salt
        final answer = qna['answer'] ?? '';
        final hashedAnswer = _hashString(answer.toLowerCase().trim(), salt);

        return {
          'question': qna['question'],
          'answer_hash': hashedAnswer,
          'salt': salt,
        };
      }).toList();

      // Convert to JSON string
      final jsonString = jsonEncode(hashedQuestionsAndAnswers);

      // Encrypt the JSON string if encryption is enabled
      if (ObjectBoxManager.instance.isEncrypted) {
        user.securityQuestions = ObjectBoxManager.encryptString(jsonString);
      } else {
        user.securityQuestions = jsonString;
      }

      userBox.put(user);
      return true;
    } catch (e) {
      dev.log('Error saving security questions: $e', name: 'AuthRepository');
      return false;
    }
  }

  /// Verify security question answers
  ///
  /// Returns true if the answers are correct for the given questions
  Future<bool> verifySecurityAnswers(
      List<Map<String, String>> providedAnswers) async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();
      final users = userBox.getAll();

      if (users.isEmpty) {
        return false; // No user exists
      }

      final user = users.first;

      if (user.securityQuestions == null) {
        return false; // No security questions are set
      }

      // Decrypt the security questions if encrypted
      String jsonString;
      if (ObjectBoxManager.instance.isEncrypted) {
        jsonString = ObjectBoxManager.decryptString(user.securityQuestions!);
      } else {
        jsonString = user.securityQuestions!;
      }

      // Parse the security questions from JSON
      final List<dynamic> decoded = jsonDecode(jsonString);
      final storedQuestions =
          decoded.map((qna) => qna as Map<String, dynamic>).toList();

      // Check if the provided answers match the stored ones
      int correctAnswers = 0;

      for (final providedQA in providedAnswers) {
        final questionToCheck = providedQA['question'] ?? '';
        final answerToCheck = providedQA['answer']?.toLowerCase().trim() ?? '';

        // Find the matching question in stored questions
        final matchingQuestion = storedQuestions.firstWhere(
          (stored) => stored['question'] == questionToCheck,
          orElse: () => <String, dynamic>{},
        );

        if (matchingQuestion.isNotEmpty) {
          final storedHash = matchingQuestion['answer_hash'];
          final salt = matchingQuestion['salt'];

          // Hash the provided answer with the same salt
          final hashedInput = _hashString(answerToCheck, salt);

          // Compare the hashes
          if (hashedInput == storedHash) {
            correctAnswers++;
          }
        }
      }

      // Determine if enough answers are correct
      // The threshold could be adjustable, but here we require all answers to be correct
      return correctAnswers == providedAnswers.length && correctAnswers > 0;
    } catch (e) {
      dev.log('Error verifying security answers: $e', name: 'AuthRepository');
      return false;
    }
  }

  /// Check if security questions have been set up
  Future<bool> hasSecurityQuestions() async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();
      final users = userBox.getAll();

      if (users.isEmpty) {
        return false; // No user exists
      }

      final user = users.first;
      return user.securityQuestions != null &&
          user.securityQuestions!.isNotEmpty;
    } catch (e) {
      dev.log('Error checking security questions: $e', name: 'AuthRepository');
      return false;
    }
  }

  /// Get the security questions (without answers) for recovery
  Future<List<String>> getSecurityQuestions() async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();
      final users = userBox.getAll();

      if (users.isEmpty || users.first.securityQuestions == null) {
        return []; // No user or no security questions
      }

      final user = users.first;

      // Decrypt the security questions if encrypted
      String jsonString;
      if (ObjectBoxManager.instance.isEncrypted) {
        jsonString = ObjectBoxManager.decryptString(user.securityQuestions!);
      } else {
        jsonString = user.securityQuestions!;
      }

      // Parse the security questions from JSON
      final List<dynamic> decoded = jsonDecode(jsonString);

      // Extract just the questions
      return decoded.map((qna) => qna['question'] as String).toList();
    } catch (e) {
      dev.log('Error getting security questions: $e', name: 'AuthRepository');
      return [];
    }
  }

  /// Generate recovery codes for the user
  ///
  /// Returns a list of recovery codes that can be used to reset the password
  Future<List<String>> generateRecoveryCodes(int count) async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();
      final users = userBox.getAll();

      if (users.isEmpty) {
        return []; // No user exists
      }

      final user = users.first;

      // Generate the specified number of recovery codes
      final codes = List.generate(count, (_) {
        // Generate a random code (16 hexadecimal characters)
        final random = List<int>.generate(
            8, (_) => DateTime.now().microsecondsSinceEpoch % 256);
        return base64Encode(random).substring(0, 16).toUpperCase();
      });

      // Hash the codes before storing them
      final hashedCodes = codes.map((code) {
        final salt = base64Encode(List<int>.generate(
            8, (_) => DateTime.now().microsecondsSinceEpoch % 256));
        return {
          'code_hash': _hashString(code, salt),
          'salt': salt,
        };
      }).toList();

      // Convert to JSON string
      final jsonString = jsonEncode(hashedCodes);

      // Store the hashed codes in the user model
      // In a real implementation, we might want a dedicated field for this
      // Here we're storing it alongside security questions for simplicity
      if (ObjectBoxManager.instance.isEncrypted) {
        user.recoveryCodes = ObjectBoxManager.encryptString(jsonString);
      } else {
        user.recoveryCodes = jsonString;
      }

      userBox.put(user);

      // Return the plain text codes to the user (only shown once)
      return codes;
    } catch (e) {
      dev.log('Error generating recovery codes: $e', name: 'AuthRepository');
      return [];
    }
  }

  /// Verify a recovery code
  ///
  /// Returns true if the code matches one of the stored recovery codes
  /// Will enforce rate limiting if too many failed attempts occur
  Future<Map<String, dynamic>> verifyRecoveryCode(String code) async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();
      final users = userBox.getAll();

      if (users.isEmpty || users.first.recoveryCodes == null) {
        return {
          'success': false,
          'rateLimited': false,
          'message': 'No recovery codes found'
        };
      }

      final user = users.first;

      // Check for rate limiting
      const cooldownMinutes =
          30; // 30 minute cooldown after too many failed attempts
      const maxAttempts = 5; // Maximum of 5 attempts before cooldown

      // If user has exceeded max attempts and is within cooldown period
      if (user.failedRecoveryAttempts >= maxAttempts &&
          user.lastFailedRecoveryAttempt != null) {
        final cooldownEnd = user.lastFailedRecoveryAttempt!
            .add(const Duration(minutes: cooldownMinutes));
        final now = DateTime.now();

        if (now.isBefore(cooldownEnd)) {
          // Still in cooldown period
          final remainingMinutes = cooldownEnd.difference(now).inMinutes + 1;
          return {
            'success': false,
            'rateLimited': true,
            'message':
                'Too many attempts. Please try again in $remainingMinutes minutes.',
            'remainingMinutes': remainingMinutes
          };
        } else {
          // Cooldown period has passed, reset counter
          user.failedRecoveryAttempts = 0;
          userBox.put(user);
        }
      }

      // Decrypt the recovery codes if encrypted
      String jsonString;
      if (ObjectBoxManager.instance.isEncrypted) {
        jsonString = ObjectBoxManager.decryptString(user.recoveryCodes!);
      } else {
        jsonString = user.recoveryCodes!;
      }

      // Parse the recovery codes from JSON
      final List<dynamic> decoded = jsonDecode(jsonString);
      final storedCodes =
          decoded.map((item) => item as Map<String, dynamic>).toList();

      // Check if the provided code matches any stored code
      for (final storedCode in storedCodes) {
        final codeHash = storedCode['code_hash'];
        final salt = storedCode['salt'];

        // Hash the provided code with the same salt
        final hashedInput = _hashString(code, salt);

        // Compare the hashes
        if (hashedInput == codeHash) {
          // Valid code, reset failed attempts
          user.failedRecoveryAttempts = 0;
          userBox.put(user);
          return {
            'success': true,
            'rateLimited': false,
            'message': 'Valid recovery code'
          };
        }
      }

      // Increment failed attempts
      user.failedRecoveryAttempts += 1;
      user.lastFailedRecoveryAttempt = DateTime.now();
      userBox.put(user);

      // Calculate how many attempts remain before lockout
      final remainingAttempts = maxAttempts - user.failedRecoveryAttempts;
      String message = 'Invalid recovery code.';

      if (remainingAttempts > 0) {
        message += ' $remainingAttempts attempts remaining.';
      } else {
        message += ' Account recovery locked for $cooldownMinutes minutes.';
      }

      return {
        'success': false,
        'rateLimited': false,
        'message': message,
        'remainingAttempts': remainingAttempts
      };
    } catch (e) {
      dev.log('Error verifying recovery code: $e', name: 'AuthRepository');
      return {
        'success': false,
        'rateLimited': false,
        'message': 'Error verifying recovery code'
      };
    }
  }

  /// Invalidate a specific recovery code after use
  ///
  /// This prevents the code from being used again
  Future<bool> invalidateRecoveryCode(String code) async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();
      final users = userBox.getAll();

      if (users.isEmpty || users.first.recoveryCodes == null) {
        return false;
      }

      final user = users.first;

      // Decrypt the recovery codes if encrypted
      String jsonString;
      if (ObjectBoxManager.instance.isEncrypted) {
        jsonString = ObjectBoxManager.decryptString(user.recoveryCodes!);
      } else {
        jsonString = user.recoveryCodes!;
      }

      // Parse the recovery codes from JSON
      final List<dynamic> decoded = jsonDecode(jsonString);
      final storedCodes =
          decoded.map((item) => item as Map<String, dynamic>).toList();
      bool codeFound = false;
      int codeIndex = -1;

      // Find the index of the code to remove
      for (int i = 0; i < storedCodes.length; i++) {
        final codeHash = storedCodes[i]['code_hash'];
        final salt = storedCodes[i]['salt'];

        // Hash the provided code with the same salt
        final hashedInput = _hashString(code, salt);

        // Compare the hashes
        if (hashedInput == codeHash) {
          codeFound = true;
          codeIndex = i;
          break;
        }
      }

      if (codeFound && codeIndex >= 0) {
        // Remove the code from the list
        storedCodes.removeAt(codeIndex);

        // Convert back to JSON string
        final updatedJsonString = jsonEncode(storedCodes);

        // Encrypt if needed and save
        if (ObjectBoxManager.instance.isEncrypted) {
          user.recoveryCodes =
              ObjectBoxManager.encryptString(updatedJsonString);
        } else {
          user.recoveryCodes = updatedJsonString;
        }

        userBox.put(user);
        return true;
      }

      return false;
    } catch (e) {
      dev.log('Error invalidating recovery code: $e', name: 'AuthRepository');
      return false;
    }
  }

  /// Reset password using a recovery code
  ///
  /// Verifies the code and sets a new password if valid
  Future<Map<String, dynamic>> resetPasswordWithRecoveryCode(
      String code, String newPassword) async {
    try {
      // First verify the recovery code
      final result = await verifyRecoveryCode(code);

      if (!result['success']) {
        return result; // Return the verification result if it failed
      }

      // If code is valid, set the new password
      final success = await savePassword(newPassword);
      if (success) {
        // Invalidate the used recovery code to prevent reuse
        await invalidateRecoveryCode(code);
        return {
          'success': true,
          'rateLimited': false,
          'message': 'Password reset successful'
        };
      } else {
        return {
          'success': false,
          'rateLimited': false,
          'message': 'Failed to reset password'
        };
      }
    } catch (e) {
      dev.log('Error resetting password: $e', name: 'AuthRepository');
      return {
        'success': false,
        'rateLimited': false,
        'message': 'Error during password reset'
      };
    }
  }

  /// Save an API key for AI services
  Future<bool> saveApiKey(String apiKey, String serviceType) async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();
      final users = userBox.getAll();

      if (users.isEmpty) {
        return false; // No user exists
      }

      final user = users.first;

      // Encrypt the API key if encryption is enabled
      if (ObjectBoxManager.instance.isEncrypted) {
        user.customApiKey = ObjectBoxManager.encryptString(apiKey);
      } else {
        user.customApiKey = apiKey;
      }

      user.apiServiceType = serviceType;
      userBox.put(user);

      return true;
    } catch (e) {
      dev.log('Error saving API key: $e', name: 'AuthRepository');
      return false;
    }
  }

  /// Get the saved API key
  Future<String?> getApiKey() async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();
      final users = userBox.getAll();

      if (users.isEmpty || users.first.customApiKey == null) {
        return null; // No user or API key exists
      }

      final user = users.first;
      final encryptedKey = user.customApiKey;

      if (encryptedKey == null) {
        return null;
      }

      // Decrypt the API key if encryption is enabled
      if (ObjectBoxManager.instance.isEncrypted) {
        return ObjectBoxManager.decryptString(encryptedKey);
      } else {
        return encryptedKey;
      }
    } catch (e) {
      dev.log('Error getting API key: $e', name: 'AuthRepository');
      return null;
    }
  }

  /// Get the API service type
  Future<String?> getApiServiceType() async {
    try {
      final userBox = ObjectBoxManager.instance.box<User>();
      final users = userBox.getAll();

      if (users.isEmpty) {
        return null; // No user exists
      }

      return users.first.apiServiceType;
    } catch (e) {
      dev.log('Error getting API service type: $e', name: 'AuthRepository');
      return null;
    }
  }

  /// Helper function to hash a password with a salt
  ///
  /// This is used ONLY for password verification, not for data encryption.
  /// The salt makes rainbow table attacks ineffective against stored password hashes.
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Helper function to hash any string with a salt
  String _hashString(String input, String salt) {
    final bytes = utf8.encode(input + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
