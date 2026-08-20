import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/storage/in_memory_secure_storage_service.dart';

void main() {
  group('SecureStorageService Unit Tests', () {
    late InMemorySecureStorageService storage;

    setUp(() {
      storage = InMemorySecureStorageService();
    });

    test('writes and reads token successfully', () async {
      await storage.writeToken('jwt_access_123');
      final token = await storage.readToken();
      expect(token, 'jwt_access_123');
    });

    test('writes and reads refresh token successfully', () async {
      await storage.writeRefreshToken('jwt_refresh_456');
      final refreshToken = await storage.readRefreshToken();
      expect(refreshToken, 'jwt_refresh_456');
    });

    test('delete and deleteAll clears storage keys', () async {
      await storage.write(key: 'key1', value: 'val1');
      await storage.write(key: 'key2', value: 'val2');

      expect(await storage.read('key1'), 'val1');
      await storage.delete('key1');
      expect(await storage.read('key1'), isNull);
      expect(await storage.read('key2'), 'val2');

      await storage.deleteAll();
      expect(await storage.read('key2'), isNull);
    });
  });
}
