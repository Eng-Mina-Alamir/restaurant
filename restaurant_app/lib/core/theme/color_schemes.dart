import 'package:flutter/material.dart';

import '../domain/enums.dart';

/// Raw brand colors for the restaurant (warm accent + teal secondary).
abstract final class AppColors {
  AppColors._();

  /// Warm deep-orange brand accent (light theme).
  static const Color brand = Color(0xFFC2410C);

  /// Light orange brand accent (dark theme).
  static const Color brandDark = Color(0xFFFF9E58);

  /// Teal secondary accent used for success/positive affordances.
  static const Color teal = Color(0xFF0F766E);

  /// Preferred clean modern warm-tinted background for the light theme.
  static const Color background = Color(0xFFFAFAF9);

  /// Pure crisp card surface in light mode.
  static const Color cardLight = Color(0xFFFFFFFF);

  /// Base surface for the dark theme.
  static const Color surfaceDark = Color(0xFF0F1216);

  /// Crisp card surface in dark mode.
  static const Color cardDark = Color(0xFF181C24);
}

/// Curated gradient palettes for modern glowing cards, badges, and accents.
abstract final class AppGradients {
  AppGradients._();

  /// Warm Brand Gradient (Orange to Coral Red)
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success / Positive Gradient (Emerald to Teal)
  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Info / Orders Gradient (Sky Blue to Royal Blue)
  static const LinearGradient info = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warning / Pending Gradient (Amber to Golden Orange)
  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Purple / Royal Gradient (Violet to Deep Indigo)
  static const LinearGradient purple = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Emerald Green Gradient
  static const LinearGradient emerald = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Modern Glass Surface Light Gradient
  static const LinearGradient glassLight = LinearGradient(
    colors: [Color(0xF5FFFFFF), Color(0xE6F8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Modern Glass Surface Dark Gradient
  static const LinearGradient glassDark = LinearGradient(
    colors: [Color(0xF51E293B), Color(0xE60F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Multi-layer modern shadow tokens for realistic, tactile card elevations.
abstract final class AppShadows {
  AppShadows._();

  /// Very soft ambient shadow for subtle cards
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x03000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Standard card elevation with soft ambient diffusion
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 14,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x04000000),
      blurRadius: 3,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  /// Floating elevated cards, modals, or focused elements
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 20,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 6,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  /// Glowing ambient shadow for accent badges and call-to-actions
  static List<BoxShadow> glow(Color color, {double opacity = 0.25}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 14,
          spreadRadius: -1,
          offset: const Offset(0, 4),
        ),
      ];
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
  ).copyWith(
    surfaceContainerLow: AppColors.cardLight,
    surfaceContainer: const Color(0xFFF5F5F4),
  );

  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: _darkSeed,
    brightness: Brightness.dark,
    primary: AppColors.brandDark,
    secondary: const Color(0xFF4DD8DA),
    surface: AppColors.surfaceDark,
  ).copyWith(
    surfaceContainerLow: AppColors.cardDark,
    surfaceContainer: const Color(0xFF222732),
  );
}
