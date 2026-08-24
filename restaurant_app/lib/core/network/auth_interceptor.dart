import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';

/// Injects the stored JWT on every outgoing request and transparently handles
/// token expiry.
///
/// On a 401 response the interceptor attempts to refresh the access token
/// using the stored refresh token. If the refresh succeeds the failed request
/// is retried once; otherwise the original error is forwarded unchanged.
///
/// Guards are in place against concurrent refreshes (`_refreshCompleter`) and
/// against retrying requests that already carry a fresh Authorization header,
/// which prevents infinite loops.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorageService storage,
    Dio? dio,
    this.baseUrl,
    this.onSessionExpired,
  }) : _storage = storage,
       _dio = dio;

  final SecureStorageService _storage;
  final Dio? _dio;

  /// Base URL used by fallback clients created when no [dio] is injected.
  /// Without it, retries/refreshes would hit `localhost` (Dio's default).
  final String? baseUrl;

  /// Invoked once when a refresh attempt fails so the host app can force a
  /// clean logout instead of leaving a half-dead session behind.
  final void Function()? onSessionExpired;

  /// Holds the in-flight refresh task to allow concurrent 401 requests to wait and retry.
  Completer<bool>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only intercept authentication failures.
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Never retry a request that was already retried after a successful refresh.
    if (_wasRefreshed(err)) {
      handler.next(err);
      return;
    }

    bool refreshed;
    if (_refreshCompleter != null) {
      // A token refresh is already in progress. Wait for it to complete.
      refreshed = await _refreshCompleter!.future;
    } else {
      final completer = Completer<bool>();
      _refreshCompleter = completer;
      refreshed = await _refreshAccessToken();
      completer.complete(refreshed);
      _refreshCompleter = null;
    }

    if (!refreshed) {
      // The session is unrecoverable: wipe the dead credentials so no further
      // request goes out authenticated, and notify the host to log the user
      // out of app state.
      await _storage.deleteToken();
      await _storage.deleteRefreshToken();
      onSessionExpired?.call();
      handler.next(err);
      return;
    }

    // Retry the original request once with the fresh token.
    try {
      final response = await _retryRequest(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  /// Whether this error's request was already stamped as retried.
  bool _wasRefreshed(DioException err) =>
      err.requestOptions.extra['auth_retried'] == true;

  /// Attempts to exchange the stored refresh token for a new access token.
  ///
  /// On success both tokens are persisted back to secure storage.
  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _postRefresh(refreshToken);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return false;
      }
      final newToken = data['token'] as String?;
      if (newToken == null || newToken.isEmpty) {
        return false;
      }
      await _storage.writeToken(newToken);
      final newRefreshToken = data['refreshToken'] as String?;
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.writeRefreshToken(newRefreshToken);
      }
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Performs the refresh POST against the refresh endpoint.
  Future<Response<dynamic>> _postRefresh(String refreshToken) async {
    if (_dio != null) {
      return _dio.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: <String, dynamic>{'refreshToken': refreshToken},
        options: Options(headers: <String, dynamic>{'Authorization': ''}),
      );
    }
    // Fallback client: MUST carry the API base URL, otherwise the refresh
    // would silently target localhost and always fail.
    final dio = Dio(BaseOptions(baseUrl: baseUrl ?? ''));
    return dio.post<dynamic>(
      ApiEndpoints.refreshToken,
      data: <String, dynamic>{'refreshToken': refreshToken},
      options: Options(headers: <String, dynamic>{'Authorization': ''}),
    );
  }

  /// Replays [options] once with the newly refreshed access token.
  ///
  /// A plain Dio (without the auth interceptor) is used so a failed retry
  /// cannot recurse back into this interceptor.
  Future<Response<dynamic>> _retryRequest(RequestOptions options) async {
    final token = await _storage.readToken();
    final headers = Map<String, dynamic>.from(options.headers);
    headers['Authorization'] = token == null || token.isEmpty
        ? headers['Authorization']
        : 'Bearer $token';
    options.extra['auth_retried'] = true;

    final retryDio = Dio(BaseOptions(baseUrl: baseUrl ?? ''));
    return retryDio.request<dynamic>(
      _resolveUrl(options.path),
      data: options.data,
      queryParameters: options.queryParameters,
      cancelToken: options.cancelToken,
      options: Options(
        method: options.method,
        headers: headers,
        responseType: options.responseType,
        contentType: options.contentType,
        sendTimeout: options.sendTimeout,
        receiveTimeout: options.receiveTimeout,
        extra: options.extra,
        followRedirects: options.followRedirects,
        maxRedirects: options.maxRedirects,
      ),
    );
  }

  /// Resolves a possibly-relative request path against the configured base URL.
  String _resolveUrl(String path) {
    final base = baseUrl;
    if (base == null || base.isEmpty || path.startsWith('http')) {
      return path;
    }
    final trimmedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final trimmedPath = path.startsWith('/') ? path : '/$path';
    return '$trimmedBase$trimmedPath';
  }
}
