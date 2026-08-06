/// App-wide spacing and radius scale.
///
/// Values are kept as raw doubles (not `EdgeInsets`) so callers can combine
/// them with `EdgeInsets.only/symmetric/all` and rounded corner widgets.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border-radius scale for cards, buttons and inputs.
abstract final class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Fully rounded radius suitable for chips/pills and circular imagery.
  static const double full = 999;
}

/// Elevation scale shared across surface widgets.
abstract final class AppElevation {
  AppElevation._();

  static const double none = 0;
  static const double sm = 1;
  static const double md = 3;
  static const double lg = 6;
}
