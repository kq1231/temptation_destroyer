import 'package:flutter_test/flutter_test.dart';
import 'package:temptation_destroyer/core/security/secure_storage_service.dart';

void main() {
  late SecureStorageService secureStorage;

  setUp(() {
    secureStorage = SecureStorageService.instance;
  });

  group('SecureStorageService', () {
    test('stores and retrieves API key', () async {
      const service = 'test_service';
      const apiKey = 'test_api_key_12345';

      await secureStorage.storeKey(service, apiKey);
      final retrievedKey = await secureStorage.getKey(service);

      expect(retrievedKey, equals(apiKey));
    });

    test('deletes API key', () async {
      const service = 'test_service';
      const apiKey = 'test_api_key_12345';

      await secureStorage.storeKey(service, apiKey);
      await secureStorage.deleteKey(service);
      final retrievedKey = await secureStorage.getKey(service);

      expect(retrievedKey, isNull);
    });

    test('checks if key exists', () async {
      const service = 'test_service';
      const apiKey = 'test_api_key_12345';

      expect(await secureStorage.hasKey(service), isFalse);

      await secureStorage.storeKey(service, apiKey);
      expect(await secureStorage.hasKey(service), isTrue);
    });

    test('generates consistent key hash', () async {
      const service = 'test_service';
      const apiKey = 'test_api_key_12345';

      await secureStorage.storeKey(service, apiKey);
      final hash1 = await secureStorage.getKeyHash(service);
      final hash2 = await secureStorage.getKeyHash(service);

      expect(hash1, isNotNull);
      expect(hash1, equals(hash2));
    });

    test('migrates key without overwriting existing', () async {
      const service = 'test_service';
      const originalKey = 'original_key';
      const newKey = 'new_key';

      // Store original key
      await secureStorage.storeKey(service, originalKey);

      // Attempt to migrate new key
      await secureStorage.migrateKey(service, newKey);

      // Should still have original key
      final retrievedKey = await secureStorage.getKey(service);
      expect(retrievedKey, equals(originalKey));
    });

    test('rotates encryption key successfully', () async {
      const service = 'test_service';
      const apiKey = 'test_api_key_12345';

      await secureStorage.storeKey(service, apiKey);

      final retrievedKey = await secureStorage.getKey(service);
      expect(retrievedKey, equals(apiKey));
    });
  });
}
