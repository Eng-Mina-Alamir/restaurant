import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contract for persisting sensitive authentication values.
abstract class SecureStorage {
  Future<void> write({required String key, required String value});
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Wrapper around [FlutterSecureStorage] for storing sensitive authentication
/// data (tokens) on the platform's secure keystore/keychain.
class SecureStorageService implements SecureStorage {
  const SecureStorageService();

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

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
