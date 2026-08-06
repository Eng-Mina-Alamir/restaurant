import 'secure_storage_service.dart';

/// In-memory [SecureStorage] for demo mode and tests where the platform
/// keystore (flutter_secure_storage) is unavailable.
///
/// Tokens persist for the process lifetime only and are never written to disk.
class InMemorySecureStorageService extends SecureStorageService {
  InMemorySecureStorageService() : _values = <String, String>{};

  final Map<String, String> _values;

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();
}
