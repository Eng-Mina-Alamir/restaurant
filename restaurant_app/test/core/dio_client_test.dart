import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/auth_interceptor.dart';
import 'package:restaurant_app/core/network/dio_client.dart';
import 'package:restaurant_app/core/storage/in_memory_secure_storage_service.dart';

void main() {
  group('DioClient Unit Tests', () {
    test('initializes with given baseUrl and default timeouts', () {
      final storage = InMemorySecureStorageService();
      final client = DioClient(
        baseUrl: 'https://api.restaurant.example.com',
        storage: storage,
      );

      expect(client.baseUrl, 'https://api.restaurant.example.com');
      expect(client.dio.options.baseUrl, 'https://api.restaurant.example.com');
      expect(client.dio.options.connectTimeout, const Duration(seconds: 30));
      expect(client.dio.options.receiveTimeout, const Duration(seconds: 30));
      expect(client.dio.options.contentType, Headers.jsonContentType);

      final hasAuthInterceptor = client.dio.interceptors.any(
        (i) => i is AuthInterceptor,
      );
      expect(hasAuthInterceptor, isTrue);
    });
  });
}
