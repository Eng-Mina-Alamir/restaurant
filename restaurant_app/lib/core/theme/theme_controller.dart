import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_cache.dart';
import '../data/local_cache_service.dart';

/// Manages application-wide [ThemeMode] with persistent local storage.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController([LocalCacheService? cache])
    : _cache = cache,
      super(ThemeMode.system) {
    _load();
  }

  final LocalCacheService? _cache;
  static const _cacheKey = 'app_selected_theme_mode';

  void _load() {
    final cached = _cache?.readString(_cacheKey);
    if (cached != null) {
      switch (cached) {
        case 'light':
          state = ThemeMode.light;
          break;
        case 'dark':
          state = ThemeMode.dark;
          break;
        default:
          state = ThemeMode.system;
      }
    }
  }

  /// Sets the active theme mode and persists it.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await _cache?.writeString(_cacheKey, mode.name);
  }

  /// Toggles between light and dark modes.
  Future<void> toggleTheme(Brightness currentBrightness) {
    if (state == ThemeMode.dark ||
        (state == ThemeMode.system && currentBrightness == Brightness.dark)) {
      return setThemeMode(ThemeMode.light);
    } else {
      return setThemeMode(ThemeMode.dark);
    }
  }
}

/// Provider for managing and watching the active [ThemeMode].
final themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
      final cache = ref.watch(localCacheServiceProvider);
      return ThemeModeController(cache);
    });
