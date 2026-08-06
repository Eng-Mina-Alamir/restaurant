import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'spacing.dart';
import 'text_styles.dart';

/// Builds the app-wide Material 3 [ThemeData].
///
/// Arabic-RTL *directionality* is intentionally deferred to the app root:
/// [MaterialApp] + a `Directionality` widget apply the language/text direction
/// from the active locale. Keeping this theme pure lets it drive both `ar`
/// (RTL) and any fallback locale with the same set of tokens.
abstract final class AppTheme {
  AppTheme._();

  /// Constructs a [ThemeData] for a light or dark [brightness].
  ///
  /// Composes the restaurant [AppColorSchemes] with the Arabic-tuned
  /// [AppTextStyles.build] text theme and shared component themes.
  static ThemeData build(Brightness brightness) {
    final colorScheme = brightness == Brightness.dark
        ? AppColorSchemes.dark
        : AppColorSchemes.light;
    final textTheme = AppTextStyles.build(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.none,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: AppElevation.none,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: AppSpacing.sm,
      ),

      // ── Form inputs ──────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
      ),

      // ── Buttons ──────────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  /// Light theme shorthand.
  static ThemeData get light => build(Brightness.light);

  /// Dark theme shorthand.
  static ThemeData get dark => build(Brightness.dark);
}
