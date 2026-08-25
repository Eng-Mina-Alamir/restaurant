import 'package:flutter/material.dart';

import '../domain/enums.dart';

/// Raw brand colors for the restaurant (warm accent + teal secondary).
abstract final class AppColors {
  AppColors._();

  /// Warm deep-orange brand accent (light theme).
  static const Color brand = Color(0xFFB4550A);

  /// Light orange brand accent (dark theme).
  static const Color brandDark = Color(0xFFFFB77C);

  /// Teal secondary accent used for success/positive affordances.
  static const Color teal = Color(0xFF006A6B);

  /// Preferred background tint for the light theme.
  static const Color background = Color(0xFFFFF8F3);

  /// Base surface for the dark theme.
  static const Color surfaceDark = Color(0xFF151312);
}

/// Semantic colors for Kitchen Display System (KDS) with verified contrast >= 4.5:1.
abstract final class KdsColors {
  KdsColors._();

  // Light Mode Colors (on background #FFF8F3 >= 4.5:1)
  static const Color pendingLight = Color(0xFFC2410C); // ~5.2:1
  static const Color preparingLight = Color(0xFF0369A1); // ~5.5:1
  static const Color readyLight = Color(0xFF047857); // ~5.6:1
  static const Color alertLight = Color(0xFFB91C1C); // ~6.2:1

  // Dark Mode Colors (on surface #151312 >= 4.5:1)
  static const Color pendingDark = Color(0xFFFDBA74); // ~10.8:1
  static const Color preparingDark = Color(0xFF38BDF8); // ~8.5:1
  static const Color readyDark = Color(0xFF4ADE80); // ~10.2:1
  static const Color alertDark = Color(0xFFF87171); // ~7.4:1

  /// Returns the high-contrast color for [status] based on [brightness].
  static Color statusColor(OrderStatus status, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (status) {
      OrderStatus.pending => isDark ? pendingDark : pendingLight,
      OrderStatus.preparing => isDark ? preparingDark : preparingLight,
      OrderStatus.ready => isDark ? readyDark : readyLight,
      OrderStatus.served || OrderStatus.completed =>
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      OrderStatus.cancelled => isDark ? alertDark : alertLight,
      OrderStatus.confirmed => isDark ? preparingDark : preparingLight,
    };
  }
}

/// Material 3 [ColorScheme]s derived from the restaurant brand seeds.
abstract final class AppColorSchemes {
  AppColorSchemes._();

  // Seed colors drive the generated tonal palettes.
  static const Color _lightSeed = AppColors.brand;
  static const Color _darkSeed = AppColors.brandDark;

  static final ColorScheme light = ColorScheme.fromSeed(
    seedColor: _lightSeed,
    primary: AppColors.brand,
    secondary: AppColors.teal,
    surface: AppColors.background,
  );

  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: _darkSeed,
    brightness: Brightness.dark,
    primary: AppColors.brandDark,
    secondary: const Color(0xFF4DD8DA),
    surface: AppColors.surfaceDark,
  );
}
