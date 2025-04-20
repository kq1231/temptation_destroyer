import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Service for securely storing sensitive data like API keys
/// Uses platform-specific implementations:
/// - Android: EncryptedSharedPreferences
/// - iOS: Keychain
/// - Others: Flutter Secure Storage (which provides built-in encryption)
class SecureStorageService {
  static const String _keyPrefix = 'ai_key_';

  final FlutterSecureStorage _storage;

  SecureStorageService._() : _storage = const FlutterSecureStorage();

  static final SecureStorageService instance = SecureStorageService._();

  /// Stores an API key for a specific service
  Future<void> storeKey(String service, String key) async {
    await _storage.write(
      key: _keyPrefix + service,
      value: key,
    );
  }

  /// Retrieves an API key for a specific service
  Future<String?> getKey(String service) async {
    return await _storage.read(key: _keyPrefix + service);
  }

  /// Deletes an API key for a specific service
  Future<void> deleteKey(String service) async {
    await _storage.delete(key: _keyPrefix + service);
  }

  /// Checks if an API key exists for a specific service
  Future<bool> hasKey(String service) async {
    final value = await _storage.read(key: _keyPrefix + service);
    return value != null;
  }

  /// Generates a hash of the stored key for verification
  Future<String?> getKeyHash(String service) async {
    final key = await getKey(service);
    if (key == null) return null;

    final bytes = utf8.encode(key);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Migrates an existing key from old storage to new secure storage
  Future<void> migrateKey(String service, String oldKey) async {
    if (await hasKey(service)) return; // Don't overwrite existing keys
    await storeKey(service, oldKey);
  }
}
