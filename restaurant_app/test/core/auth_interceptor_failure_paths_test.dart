import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/auth_interceptor.dart';
import 'package:restaurant_app/core/storage/in_memory_secure_storage_service.dart';

/// Adapter that refuses every outgoing request with a [DioException].
///
/// Keeps the refresh path fully offline and deterministic: no socket is ever
/// opened, the failure is instantaneous and reproducible on any machine.
class _RefusingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: 'offline-test: every request is refused',
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter that records every request and answers via a scripted callback.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._answer);

  final ResponseBody Function(RequestOptions options) _answer;

  final List<RequestOptions> seenRequests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seenRequests.add(options);
    return _answer(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Records which terminal branch the interceptor took.
class _RecordingErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  bool resolved = false;
  DioException? lastError;

  @override
  void next(DioException err) {
    nextCalled = true;
    lastError = err;
  }

  @override
  void resolve(Response<dynamic> response) => resolved = true;
}

/// Builds a synthetic 401 [DioException] like a real backend rejection.
DioException _unauthorized(String path) {
  final requestOptions = RequestOptions(path: path);
  return DioException(
    requestOptions: requestOptions,
    response: Response(requestOptions: requestOptions, statusCode: 401),
  );
}

void main() {
  // The retry target is unreachable loopback; allow headroom for slow
  // host-firewall refusals even though failures are usually instantaneous.
  const testTimeout = Timeout.factor(6);

  group('AuthInterceptor failure & recovery paths', () {
    late InMemorySecureStorageService storage;

    setUp(() {
      storage = InMemorySecureStorageService();
    });

    test(
      'refresh failing WITH a refresh token present wipes tokens and fires onSessionExpired exactly once',
      timeout: testTimeout,
      () async {
        await storage.writeToken('stale-access-token');
        await storage.writeRefreshToken('stale-refresh-token');

        var sessionExpiredCount = 0;
        // The refresh POST goes through this injected dio whose adapter
        // always throws — deterministic offline failure.
        //
        // The interceptor is deliberately NOT attached to this dio's
        // interceptor list: it only needs it as its refresh transport.
        final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
          ..httpClientAdapter = _RefusingAdapter();

        final interceptor = AuthInterceptor(
          storage: storage,
          dio: refreshDio,
          onSessionExpired: () => sessionExpiredCount++,
        );

        final error = _unauthorized('/api/v1/orders');
        final handler = _RecordingErrorHandler();

        await interceptor.onError(error, handler);

        // Session teardown happened…
        expect(await storage.readToken(), isNull);
        expect(await storage.readRefreshToken(), isNull);

        // …the host was notified exactly once…
        expect(sessionExpiredCount, 1);

        // …and the original error was still forwarded (no retry attempted).
        expect(handler.nextCalled, isTrue);
        expect(handler.resolved, isFalse);
        expect(handler.lastError, same(error));
      },
    );

    test(
      'successful refresh retries once with auth_retried stamped and fresh bearer token',
      timeout: testTimeout,
      () async {
        await storage.writeToken('old-access-token');
        await storage.writeRefreshToken('valid-refresh-token');

        // Refresh endpoint answers with a brand-new token pair; anything else
        // is unexpected in this scenario and fails loudly.
        final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
          ..httpClientAdapter = _ScriptedAdapter((options) {
            if (options.path.endsWith('/auth/refresh')) {
              return ResponseBody.fromString(
                jsonEncode(<String, dynamic>{
                  'token': 'brand-new-access-token',
                  'refreshToken': 'brand-new-refresh-token',
                }),
                200,
                headers: <String, List<String>>{
                  Headers.contentTypeHeader: <String>[Headers.jsonContentType],
                },
              );
            }
            fail('Unexpected request from interceptor: ${options.uri}');
          });

        // The retry is replayed through a plain Dio built with the
        // interceptor's baseUrl. Pointing it at unreachable loopback keeps
        // the retry fully offline while still surfacing the retried request
        // object (with its stamp) through the error handler.
        final interceptor = AuthInterceptor(
          storage: storage,
          dio: refreshDio,
          baseUrl: 'http://127.0.0.1:9',
        );

        final error = _unauthorized('/api/v1/orders');
        final handler = _RecordingErrorHandler();

        await interceptor.onError(error, handler);

        // Refresh succeeded: both tokens were rotated in storage.
        expect(await storage.readToken(), 'brand-new-access-token');
        expect(await storage.readRefreshToken(), 'brand-new-refresh-token');

        // A single retry was attempted (refused by the dead loopback).
        expect(handler.nextCalled, isTrue);
        expect(handler.resolved, isFalse);

        // The captured retried request carries the one-shot retry stamp…
        final retriedRequest = handler.lastError?.requestOptions;
        expect(retriedRequest, isNotNull);
        expect(retriedRequest!.extra['auth_retried'], isTrue);

        // …the original request options are stamped too, so even a cloned
        // replay can never re-enter the refresh flow.
        expect(error.requestOptions.extra['auth_retried'], isTrue);

        // …targets the same endpoint…
        expect(retriedRequest.path, contains('/api/v1/orders'));

        // …and presents the freshly rotated bearer token, not the stale one.
        expect(
          retriedRequest.headers['Authorization'],
          'Bearer brand-new-access-token',
        );
      },
    );
  });
}
