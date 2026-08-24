import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/auth_interceptor.dart';
import 'package:restaurant_app/core/storage/in_memory_secure_storage_service.dart';

void main() {
  group('AuthInterceptor Unit Tests', () {
    late InMemorySecureStorageService storage;
    late Dio dio;
    late AuthInterceptor interceptor;

    setUp(() {
      storage = InMemorySecureStorageService();
      dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      interceptor = AuthInterceptor(storage: storage, dio: dio);
      dio.interceptors.add(interceptor);
    });

    test('onRequest adds Authorization header when token is stored', () async {
      await storage.writeToken('test-access-token');

      final options = RequestOptions(path: '/api/v1/menu');
      final handler = _FakeRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer test-access-token');
      expect(handler.nextCalled, isTrue);
    });

    test(
      'onRequest leaves Authorization empty when no token is stored',
      () async {
        final options = RequestOptions(path: '/api/v1/menu');
        final handler = _FakeRequestHandler();

        await interceptor.onRequest(options, handler);

        expect(options.headers.containsKey('Authorization'), isFalse);
        expect(handler.nextCalled, isTrue);
      },
    );

    test('onError passes through non-401 errors without refresh', () async {
      final requestOptions = RequestOptions(path: '/api/v1/orders');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 500),
      );

      final handler = _FakeErrorHandler();
      await interceptor.onError(dioException, handler);

      expect(handler.nextCalled, isTrue);
      expect(handler.lastError?.response?.statusCode, 500);
    });

    test(
      'onError does not retry if request is already stamped with auth_retried',
      () async {
        await storage.writeRefreshToken('test-refresh-token');
        final requestOptions = RequestOptions(
          path: '/api/v1/orders',
          extra: {'auth_retried': true},
        );
        final dioException = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        );

        final handler = _FakeErrorHandler();
        await interceptor.onError(dioException, handler);

        expect(handler.nextCalled, isTrue);
      },
    );

    test('onError fails gracefully if no refreshToken is available', () async {
      final requestOptions = RequestOptions(path: '/api/v1/orders');
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      );

      final handler = _FakeErrorHandler();
      await interceptor.onError(dioException, handler);

      expect(handler.nextCalled, isTrue);
      final token = await storage.readToken();
      expect(token, isNull);
    });
  });
}

class _FakeRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(RequestOptions requestOptions) {
    nextCalled = true;
  }
}

class _FakeErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  DioException? lastError;

  @override
  void next(DioException err) {
    nextCalled = true;
    lastError = err;
  }

  @override
  void resolve(Response<dynamic> response) {}
}
