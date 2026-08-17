import 'dart:convert';

import 'package:hive/hive.dart';

/// Generic JSON-string persistence built on Hive.
///
/// Orders, restaurant tables and delivery assignments are stored as JSON
/// so the domain entities (freezed) can be round-tripped without registering
/// Hive type adapters for every class.
class LocalCacheService {
  LocalCacheService(this._box);

  final Box<String> _box;

  /// Reads and decodes all entries stored under [key] into a JSON list.
  List<Map<String, dynamic>> readList(String key) {
    final raw = _box.get(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on FormatException {
      return const [];
    }
  }

  /// Serializes [items] (their `toJson()` output) to a JSON string under
  /// [key], replacing any previous value.
  Future<void> writeList(String key, List<Map<String, dynamic>> items) async {
    await _box.put(key, jsonEncode(items));
  }

  /// Reads a single raw string value from [key].
  String? readString(String key) => _box.get(key);

  /// Writes a single string value to [key].
  Future<void> writeString(String key, String value) => _box.put(key, value);

  /// Removes a single stored collection.
  Future<void> removeKey(String key) => _box.delete(key);
}
