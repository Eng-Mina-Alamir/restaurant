import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'local_cache_service.dart';

/// Name of the single Hive box used for JSON-string collections.
const String appCacheBoxName = 'app_cache';

/// Holds the [LocalCacheService] once initialized, or null before/if startup
/// initialization failed (e.g. tests without a Hive path).
final localCacheServiceProvider = Provider<LocalCacheService?>((ref) => null);

/// Initializes Hive and the shared [LocalCacheService].
///
/// Safe to call once at app startup. Returns null on platforms where Hive
/// cannot open a box so callers can fall back to in-memory storage.
Future<LocalCacheService?> initAppCache() async {
  try {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(appCacheBoxName);
    return LocalCacheService(box);
  } catch (_) {
    return null;
  }
}
