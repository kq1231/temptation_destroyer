import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../../core/utils/object_box_manager.dart';
import '../../core/utils/encryption_service.dart';

/// Repository for handling user authentication
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
  /// This hashes the password before storing it
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
      print('Error saving password: $e');
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
      print('Error verifying password: $e');
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
      print('Error updating password: $e');
      return false;
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
      print('Error saving API key: $e');
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
      print('Error getting API key: $e');
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
      print('Error getting API service type: $e');
      return null;
    }
  }

  /// Helper function to hash a password with a salt
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
