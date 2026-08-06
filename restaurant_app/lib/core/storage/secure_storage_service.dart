import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around [FlutterSecureStorage] for storing sensitive authentication
/// data (tokens) on the platform's secure keystore/keychain.
class SecureStorageService {
  const SecureStorageService();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // ── Access token ──────────────────────────────────────────────────────────

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // ── Refresh token ─────────────────────────────────────────────────────────

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> deleteRefreshToken() => _storage.delete(key: _refreshTokenKey);

  // ── Generic / lifecycle ───────────────────────────────────────────────────

  /// Writes an arbitrary string value under [key].
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  /// Reads the string value stored under [key], or `null` if absent.
  Future<String?> read(String key) => _storage.read(key: key);

  /// Removes any value stored under [key].
  Future<void> delete(String key) => _storage.delete(key: key);

  /// Deletes all stored values in one call.
  Future<void> clear() => _storage.deleteAll();

  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
}
