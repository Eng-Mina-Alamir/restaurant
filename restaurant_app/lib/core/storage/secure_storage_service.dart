import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/logger.dart';

/// Contract for persisting sensitive authentication values.
abstract class SecureStorage {
  Future<void> write({required String key, required String value});
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Wrapper around [FlutterSecureStorage] for storing sensitive authentication
/// data (tokens) on the platform's secure keystore/keychain, with safe memory fallback
/// for unit tests and headless environments.
///
/// **Security note:** the [_fallback] map is `static final` so it is shared
/// across all instances. When the platform keystore is unavailable, secrets
/// live in plain RAM — acceptable for tests/CI, but a red flag in production.
/// Every catch block now logs a warning so the issue is visible.
class SecureStorageService implements SecureStorage {
  const SecureStorageService();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final Map<String, String> _fallback = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      AppLogger.warning(
        'SecureStorageService: write($key) fell back to in-memory: $e',
      );
      _fallback[key] = value;
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value ?? _fallback[key];
    } catch (e) {
      AppLogger.warning(
        'SecureStorageService: read($key) fell back to in-memory: $e',
      );
      return _fallback[key];
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      _fallback.remove(key);
    } catch (e) {
      AppLogger.warning(
        'SecureStorageService: delete($key) fell back to in-memory: $e',
      );
      _fallback.remove(key);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      _fallback.clear();
    } catch (e) {
      AppLogger.warning(
        'SecureStorageService: deleteAll() fell back to in-memory: $e',
      );
      _fallback.clear();
    }
  }

  // ── Access token ──────────────────────────────────────────────────────────

  Future<void> writeToken(String token) => write(key: _tokenKey, value: token);

  Future<String?> readToken() => read(_tokenKey);

  Future<void> deleteToken() => delete(_tokenKey);

  // ── Refresh token ─────────────────────────────────────────────────────────

  Future<void> writeRefreshToken(String token) =>
      write(key: _refreshTokenKey, value: token);

  Future<String?> readRefreshToken() => read(_refreshTokenKey);

  Future<void> deleteRefreshToken() => delete(_refreshTokenKey);

  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
}

