import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_cache.dart';
import '../data/local_cache_service.dart';

/// Supported locales in the restaurant application.
enum AppLanguage {
  arabic(Locale('ar'), 'العربية', TextDirection.rtl),
  english(Locale('en'), 'English', TextDirection.ltr);

  const AppLanguage(this.locale, this.displayName, this.direction);

  final Locale locale;
  final String displayName;
  final TextDirection direction;

  static AppLanguage fromLocale(Locale locale) {
    if (locale.languageCode == 'en') return AppLanguage.english;
    return AppLanguage.arabic;
  }
}

/// Manages the application-wide active locale with caching.
class LocaleController extends StateNotifier<Locale> {
  LocaleController([LocalCacheService? cache])
      : _cache = cache,
        super(const Locale('ar')) {
    _load();
  }

  final LocalCacheService? _cache;
  static const _cacheKey = 'app_selected_locale';

  void _load() {
    final cached = _cache?.readString(_cacheKey);
    if (cached != null && (cached == 'ar' || cached == 'en')) {
      state = Locale(cached);
    }
  }

  /// Sets the active locale to [locale] and persists the preference.
  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;
    state = locale;
    await _cache?.writeString(_cacheKey, locale.languageCode);
  }

  /// Sets the active language via [AppLanguage].
  Future<void> setLanguage(AppLanguage language) => setLocale(language.locale);

  /// Toggles between Arabic and English.
  Future<void> toggleLanguage() {
    final next = state.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    return setLocale(next);
  }
}

/// Provider for managing and watching the active [Locale].
final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) {
  final cache = ref.watch(localCacheServiceProvider);
  return LocaleController(cache);
});

/// Convenience provider returning whether current locale is RTL (Arabic).
final isRtlProvider = Provider<bool>((ref) {
  final locale = ref.watch(localeControllerProvider);
  return locale.languageCode == 'ar';
});

/// Convenience provider returning the active [AppLanguage].
final currentLanguageProvider = Provider<AppLanguage>((ref) {
  final locale = ref.watch(localeControllerProvider);
  return AppLanguage.fromLocale(locale);
});
