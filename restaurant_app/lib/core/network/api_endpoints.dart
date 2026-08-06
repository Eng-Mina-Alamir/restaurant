/// Centralized API endpoint paths for the backend.
///
/// All endpoints resolve against [EnvironmentConfig.baseUrl] at runtime so the
/// active environment (dev/staging/production) is honored automatically. The
/// getters are intentionally runtime (not `const`) because the base URL is
/// computed by [EnvironmentConfig].
library;

import '../../config/environment.dart';

abstract final class ApiEndpoints {
  /// Base URL of the active environment's backend.
  static String get base => EnvironmentConfig.baseUrl;

  // ── Auth ──────────────────────────────────────────────────────────────────
  static String get register => '$base/auth/register';
  static String get login => '$base/auth/login';
  static String get verifyOtp => '$base/auth/verify-otp';
  static String get refreshToken => '$base/auth/refresh';
  static String get me => '$base/auth/me';
  static String get logout => '$base/auth/logout';

  // ── Menu ──────────────────────────────────────────────────────────────────
  static String get menu => '$base/menu';

  // ── Orders ────────────────────────────────────────────────────────────────
  static String get orders => '$base/orders';

  // ── Tables ────────────────────────────────────────────────────────────────
  static String get tables => '$base/tables';
}
