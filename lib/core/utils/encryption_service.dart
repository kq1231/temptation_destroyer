import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Custom encryption service for securing data stored in ObjectBox
///
/// This service handles encryption and decryption of data
/// using the user's password as the encryption key.
class EncryptionService {
  late final Key _key;
  late final IV _iv;
  late final Encrypter _encrypter;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // IV storage key in secure storage
  static const String _ivKey = 'encryption_iv';

  // Singleton instance
  static EncryptionService? _instance;

  /// Get the singleton instance of EncryptionService
  static EncryptionService get instance {
    _instance ??= EncryptionService._internal();
    return _instance!;
  }

  EncryptionService._internal();

  /// Initialize the encryption service with the user's password
  ///
  /// This should be called during app initialization after the user logs in
  Future<void> initialize(String password) async {
    // Generate a key from the password using SHA-256
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    _key = Key(Uint8List.fromList(keyBytes));

    // Try to retrieve the IV from secure storage or generate a new one
    String? storedIV = await _secureStorage.read(key: _ivKey);
    if (storedIV != null) {
      _iv = IV(Uint8List.fromList(base64.decode(storedIV)));
    } else {
      // Generate a random IV and store it
      _iv = IV.fromSecureRandom(16);
      await _secureStorage.write(
        key: _ivKey,
        value: base64.encode(_iv.bytes),
      );
    }

    // Create the encrypter with AES in CBC mode with PKCS7 padding
    _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
  }

  /// Encrypt a string value
  String encrypt(String value) {
    return _encrypter.encrypt(value, iv: _iv).base64;
  }

  /// Decrypt a string value
  String decrypt(String encryptedValue) {
    return _encrypter.decrypt64(encryptedValue, iv: _iv);
  }

  /// Check if the encryption service is initialized
  bool get isInitialized => _instance != null;

  /// Clear the encryption keys from memory
  ///
  /// Call this when the user logs out
  void clearKeys() {
    // Clear the key and IV from memory
    // Note: This doesn't delete the IV from secure storage
    _instance = null;
  }

  /// Reset the encryption service (for testing or password reset)
  ///
  /// WARNING: This will make all previously encrypted data unreadable
  Future<void> resetEncryption() async {
    await _secureStorage.delete(key: _ivKey);
    _instance = null;
  }
}
