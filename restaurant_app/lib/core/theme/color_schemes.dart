import 'package:flutter/material.dart';

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
