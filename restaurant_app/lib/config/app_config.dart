/// Global application configuration constants that are locale/region specific
/// and used across the whole app.
///
/// This class is intentionally pure Dart so it can be used from any layer
/// (including test-only setup) without ties to the Flutter framework.
abstract final class AppConfig {
  /// Human readable Arabic app name shown in the UI and app bar.
  static const String appName = 'مطعمي';

  /// Short tagline used on splash/login screens.
  static const String appTagline = 'طبخك المفضل في مكان واحد';

  /// Current build version, matches the version in `pubspec.yaml`.
  static const String version = '1.0.0';

  /// Default currency in which prices are displayed (Saudi Riyal).
  static const String defaultCurrency = 'ر.س';

  /// Primary locale of the app.
  static const String locale = 'ar';

  /// Fallback locale used when the primary is unavailable.
  static const String fallbackLocale = 'en';

  /// All locales supported by the app.
  static const List<String> supportedLocales = <String>[locale, fallbackLocale];

  /// When true, auth uses the offline demo data source so every role can be
  /// reviewed without a backend (see demo accounts on the login screen).
  static const bool useDemoAuth = true;
}
