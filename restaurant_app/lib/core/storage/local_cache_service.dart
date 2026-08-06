import 'package:hive_flutter/hive_flutter.dart';

/// Lightweight wrapper around Hive for durable, offline-friendly local
/// caching of non-secret application data.
///
/// Sensitive data (tokens) must be stored via [SecureStorageService] instead.
/// Note: Hive requires platform plugin initialization at runtime (e.g.
/// `Hive.initFlutter`) before a box can actually be opened; this class stays
/// compile-safe so it can be wired up later.
class LocalCacheService {
  const LocalCacheService();

  /// Opens (or reuses an already-open) Hive [Box] with the given [name].
  ///
  /// Boxes are boxed to `dynamic` so callers may store any serializable value.
  Future<Box<dynamic>> openBox(String name) => Hive.openBox<dynamic>(name);

  /// Stores a list of items in [box] under [key].
  Future<void> writeList(String box, String key, List<dynamic> items) async {
    final open = await openBox(box);
    await open.put(key, items);
  }

  /// Reads a list previously stored under [key] in [box], or an empty list.
  Future<List<dynamic>> readList(String box, String key) async {
    final open = await openBox(box);
    final value = open.get(key);
    if (value is List) {
      return List<dynamic>.of(value);
    }
    return <dynamic>[];
  }

  /// Removes all data in [box].
  Future<void> clearBox(String box) async {
    final open = await openBox(box);
    await open.clear();
  }
}
