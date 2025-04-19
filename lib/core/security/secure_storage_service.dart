import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Service for securely storing sensitive data like API keys
/// Uses platform-specific implementations:
/// - Android: EncryptedSharedPreferences
/// - iOS: Keychain
/// - Others: Flutter Secure Storage with additional encryption
class SecureStorageService {
  static const String _keyPrefix = 'ai_key_';
  static const String _encryptionKeyKey = 'encryption_master_key';

  final FlutterSecureStorage _storage;
  late final encrypt.Key _encryptionKey;
  late final encrypt.IV _iv;

  SecureStorageService._() : _storage = const FlutterSecureStorage() {
    _initializeEncryption();
  }

  static final SecureStorageService instance = SecureStorageService._();

  Future<void> _initializeEncryption() async {
    // Get or generate master encryption key
    String? storedKey = await _storage.read(key: _encryptionKeyKey);
    if (storedKey == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      await _storage.write(
        key: _encryptionKeyKey,
        value: base64.encode(key.bytes),
      );
      storedKey = base64.encode(key.bytes);
    }

    _encryptionKey = encrypt.Key.fromBase64(storedKey);
    _iv = encrypt.IV.fromLength(16); // Fixed IV for simplicity
  }

  /// Stores an API key for a specific service
  Future<void> storeKey(String service, String key) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = encrypter.encrypt(key, iv: _iv);

    await _storage.write(
      key: _keyPrefix + service,
      value: encrypted.base64,
    );
  }

  /// Retrieves an API key for a specific service
  Future<String?> getKey(String service) async {
    final encrypted = await _storage.read(key: _keyPrefix + service);
    if (encrypted == null) return null;

    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    try {
      final decrypted = encrypter.decrypt64(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      return null;
    }
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

  /// Rotates the encryption key and re-encrypts all stored keys
  Future<void> rotateEncryptionKey() async {
    // Get all stored keys
    final allKeys = await _storage.readAll();
    final apiKeys =
        allKeys.entries.where((e) => e.key.startsWith(_keyPrefix)).toList();

    // Generate new encryption key
    final newKey = encrypt.Key.fromSecureRandom(32);
    final oldKey = _encryptionKey;

    // Re-encrypt all keys with new encryption key
    final oldEncrypter = encrypt.Encrypter(encrypt.AES(oldKey));
    final newEncrypter = encrypt.Encrypter(encrypt.AES(newKey));

    for (final entry in apiKeys) {
      try {
        final decrypted = oldEncrypter.decrypt64(entry.value, iv: _iv);
        final newEncrypted = newEncrypter.encrypt(decrypted, iv: _iv);
        await _storage.write(
          key: entry.key,
          value: newEncrypted.base64,
        );
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }

    // Store new encryption key
    await _storage.write(
      key: _encryptionKeyKey,
      value: base64.encode(newKey.bytes),
    );
    _encryptionKey = newKey;
  }
}
