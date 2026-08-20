import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/auth_interceptor.dart';
import 'package:restaurant_app/core/storage/in_memory_secure_storage_service.dart';

void main() {
  group('Token Refresh Concurrency & Mutex Tests', () {
    late InMemorySecureStorageService storage;
    late AuthInterceptor interceptor;

    setUp(() {
      storage = InMemorySecureStorageService();
      interceptor = AuthInterceptor(storage: storage);
    });

    test('Parallel 401 errors are synchronized via Completer without crashing', () async {
      await storage.writeRefreshToken('valid-refresh-token');

      final req1 = RequestOptions(path: '/api/v1/orders');
      final err1 = DioException(
        requestOptions: req1,
        response: Response(requestOptions: req1, statusCode: 401),
      );
      final handler1 = _TestErrorHandler();

      final req2 = RequestOptions(path: '/api/v1/menu');
      final err2 = DioException(
        requestOptions: req2,
        response: Response(requestOptions: req2, statusCode: 401),
      );
      final handler2 = _TestErrorHandler();

      final req3 = RequestOptions(path: '/api/v1/tables');
      final err3 = DioException(
        requestOptions: req3,
        response: Response(requestOptions: req3, statusCode: 401),
      );
      final handler3 = _TestErrorHandler();

      // Dispatch 3 parallel 401 errors concurrently
      final futures = [
        interceptor.onError(err1, handler1),
        interceptor.onError(err2, handler2),
        interceptor.onError(err3, handler3),
      ];

      await Future.wait(futures);

      // All handlers should be resolved or completed cleanly
      expect(handler1.called, isTrue);
      expect(handler2.called, isTrue);
      expect(handler3.called, isTrue);
    });
  });
}

class _TestErrorHandler extends ErrorInterceptorHandler {
  bool called = false;

  @override
  void next(DioException err) {
    called = true;
  }

  @override
  void resolve(Response<dynamic> response) {
    called = true;
  }
}
