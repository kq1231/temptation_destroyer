import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'encryption_service.dart';

// Import the generated objectbox code
import '../../objectbox.g.dart';

/// ObjectBoxManager handles the initialization and access to ObjectBox store
/// with support for custom encryption.
///
/// This class is responsible for setting up the ObjectBox database and
/// providing access to the Store instance which is needed for database operations.
class ObjectBoxManager {
  /// Singleton instance
  static ObjectBoxManager? _instance;

  /// The ObjectBox Store instance
  late final Store _store;

  /// Flag to indicate if the database is encrypted
  bool _isEncrypted = false;

  /// Private constructor for singleton pattern
  ObjectBoxManager._();

  /// Returns the ObjectBox store for database operations
  Store get store => _store;

  /// Returns whether the database is currently encrypted
  bool get isEncrypted => _isEncrypted;

  /// Get the singleton instance of ObjectBoxManager
  static ObjectBoxManager get instance {
    if (_instance == null) {
      throw StateError('ObjectBoxManager must be initialized before accessing');
    }
    return _instance!;
  }

  /// Initialize the ObjectBox database
  ///
  /// If [password] is provided, data will be encrypted/decrypted using this password
  /// via our custom encryption service.
  static Future<ObjectBoxManager> initialize({String? password}) async {
    if (_instance != null) {
      return _instance!;
    }

    final instance = ObjectBoxManager._();

    // Get the application documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final databaseDir = p.join(appDir.path, 'objectbox_db');

    // Ensure the directory exists
    final dir = Directory(databaseDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // If the password is provided, initialize the encryption service
    if (password != null && password.isNotEmpty) {
      await EncryptionService.instance.initialize(password);
      instance._isEncrypted = true;
    }

    try {
      // Use the generated openStore function
      instance._store = await openStore(directory: databaseDir);
      debugPrint('ObjectBox store initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ObjectBox: $e');
      rethrow;
    }

    _instance = instance;
    return _instance!;
  }

  /// Close the ObjectBox store
  void close() {
    _store.close();
    if (_isEncrypted) {
      EncryptionService.instance.clearKeys();
    }
    _instance = null;
  }

  /// Get a Box for the specified entity type
  Box<T> box<T>() {
    return _store.box<T>();
  }

  /// Encrypts a string value if encryption is enabled
  static String encryptString(String value) {
    if (!EncryptionService.instance.isInitialized) return value;
    try {
      return EncryptionService.instance.encrypt(value);
    } catch (e) {
      debugPrint('Error encrypting value: $e');
      return value; // Return raw value if encryption fails
    }
  }

  /// Decrypts a string value if encryption is enabled
  static String decryptString(String value) {
    if (!EncryptionService.instance.isInitialized) return value;
    try {
      return EncryptionService.instance.decrypt(value);
    } catch (e) {
      debugPrint('Error decrypting value: $e');
      return value; // Return raw value if decryption fails
    }
  }
}
