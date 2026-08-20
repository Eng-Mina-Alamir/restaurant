/// Global application configuration constants that are locale/region specific
/// and used across the whole app.
///
/// This class is intentionally pure Dart so it can be used from any layer
/// (including test-only setup) without ties to the Flutter framework.
abstract final class AppConfig {
  /// Human readable Arabic app name shown in the UI and app bar.
  static const String appName = 'مطعم ليالي المحروسة';

  /// Short tagline used on splash/login screens.
  static const String appTagline = 'أشهى المأكولات والمشويات المصرية الأصيلة';

  /// Current build version, matches the version in `pubspec.yaml`.
  static const String version = '1.0.0';

  /// Default currency in which prices are displayed (Egyptian Pound).
  static const String defaultCurrency = 'ج.م';

  /// Primary locale of the app.
  static const String locale = 'ar';

  /// Fallback locale used when the primary is unavailable.
  static const String fallbackLocale = 'en';

  /// All locales supported by the app.
  static const List<String> supportedLocales = <String>[locale, fallbackLocale];

  /// When true, allows instant demo logins for testing and role walkthroughs;
  /// In production, set to false to enforce live Supabase Auth email/password verification.
  static const bool useDemoAuth = false;

  /// Whether to use live Supabase backend for database, realtime, and storage.
  static const bool useSupabase = true;
}
