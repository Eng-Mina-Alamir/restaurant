import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
class SecureStorageService implements SecureStorage {
  const SecureStorageService();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final Map<String, String> _fallback = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _fallback[key] = value;
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value ?? _fallback[key];
    } catch (_) {
      return _fallback[key];
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      _fallback.remove(key);
    } catch (_) {
      _fallback.remove(key);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      _fallback.clear();
    } catch (_) {
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
