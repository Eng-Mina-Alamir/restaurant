import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 [TextTheme] tuned for Arabic and English typography using Cairo typeface.
abstract final class AppTextStyles {
  AppTextStyles._();

  /// Builds a [TextTheme] suitable for [brightness], utilizing the Google Fonts
  /// Cairo typeface tailored for premium Arabic and multilingual rendering.
  static TextTheme build(Brightness brightness) {
    final source = Typography.material2021(platform: TargetPlatform.android);
    final base = brightness == Brightness.dark ? source.white : source.black;

    final cairoTheme = GoogleFonts.cairoTextTheme(base);

    return cairoTheme.copyWith(
      displaySmall: cairoTheme.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      headlineMedium: cairoTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      headlineSmall: cairoTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleLarge: cairoTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      titleMedium: cairoTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleSmall: cairoTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      bodyLarge: cairoTheme.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: cairoTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: cairoTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: cairoTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      labelMedium: cairoTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      labelSmall: cairoTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }
}
