import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

/// Thin wrapper around the Dio HTTP client.
///
/// Centralizes the [BaseOptions] used by every request and installs the
/// [AuthInterceptor] so that JWTs are injected automatically and 401s are
/// handled via a refresh flow.
class DioClient {
  DioClient({required this.baseUrl, required SecureStorageService storage})
    : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: Headers.jsonContentType,
      ),
    );
    _dio.interceptors.add(AuthInterceptor(storage: _storage, dio: _dio));
  }

  late final Dio _dio;
  final String baseUrl;
  final SecureStorageService _storage;

  /// The configured Dio instance for all outbound HTTP traffic.
  Dio get dio => _dio;
}
