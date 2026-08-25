import 'package:flutter/material.dart';

import '../../features/inventory/domain/entities/inventory_item_entity.dart';
import '../domain/enums.dart';
import 'color_schemes.dart';

/// Generic semantic tone used when no dedicated domain enum exists yet.
///
/// Feature code can map its own states onto these tones instead of hard
/// coding raw colors, keeping every status hue inside the audited palette.
enum SemanticTone {
  success,
  warning,
  danger,
  info,
  neutral;
}

/// Single brightness-aware source of truth for ALL status colors.
///
/// Contrast rules follow the MASTER.md audit method: every value must hold
/// >= 4.5:1 against its background — `#FFF8F3` in light mode, `#151312` in
/// dark mode. No new hues are introduced: light/dark variants are derived
/// from the already-approved [AppColors] / [KdsColors] palette steps.
///
/// Order statuses remain owned by [KdsColors.statusColor]; this registry
/// delegates to it so there is exactly one definition per order status.
abstract final class StatusColors {
  StatusColors._();

  // ── Shared semantic tone steps (audited) ───────────────────────────────────
  // Success: green (reuses KdsColors.ready*).
  static const Color _successLight = Color(0xFF047857); // ~5.6:1 on FFF8F3
  static const Color _successDark = Color(0xFF4ADE80); // ~10.2:1 on 151312

  // Warning: deep orange (reuses KdsColors.pending*).
  static const Color _warningLight = Color(0xFFC2410C); // ~5.2:1 on FFF8F3
  static const Color _warningDark = Color(0xFFFDBA74); // ~10.8:1 on 151312

  // Danger: red (reuses KdsColors.alert*).
  static const Color _dangerLight = Color(0xFFB91C1C); // ~6.2:1 on FFF8F3
  static const Color _dangerDark = Color(0xFFF87171); // ~7.4:1 on 151312

  // Info: sky blue (reuses KdsColors.preparing*).
  static const Color _infoLight = Color(0xFF0369A1); // ~5.5:1 on FFF8F3
  static const Color _infoDark = Color(0xFF38BDF8); // ~8.5:1 on 151312

  // Neutral: slate (matches the KDS served/completed pair).
  static const Color _neutralLight = Color(0xFF475569); // ~7.2:1 on FFF8F3
  static const Color _neutralDark = Color(0xFF94A3B8); // ~7.2:1 on 151312

  // Teal secondary (reuses AppColors.teal / dark-scheme secondary).
  static const Color _tealLight = Color(0xFF006A6B); // ~6.1:1 on FFF8F3
  static const Color _tealDark = Color(0xFF4DD8DA); // ~10.7:1 on 151312

  // ── Order statuses ─────────────────────────────────────────────────────────

  /// Delegates to [KdsColors.statusColor], keeping it the single source for
  /// order statuses. Do NOT duplicate those values here.
  static Color order(OrderStatus status, Brightness brightness) =>
      KdsColors.statusColor(status, brightness);

  // ── Table statuses ─────────────────────────────────────────────────────────

  /// Light values come from the MASTER.md audit (available green, occupied
  /// red, reserved amber, needsCleaning blue-grey). `reserved` was darkened
  /// one amber step (#D97706 -> #B45309) because #D97706 measures ~3.0:1 on
  /// `#FFF8F3` and fails the 4.5:1 bar. Dark variants reuse the matching
  /// audited [KdsColors] dark steps.
  static Color table(TableStatus status, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (status) {
      TableStatus.available =>
        isDark ? _successDark : const Color(0xFF15803D), // ~4.8:1
      TableStatus.occupied => isDark ? _dangerDark : const Color(0xFFDC2626),
      // ~4.6:1
      TableStatus.reserved =>
        isDark ? _warningDark : const Color(0xFFB45309), // ~4.8:1
      TableStatus.needsCleaning =>
        isDark ? _neutralDark : const Color(0xFF475569), // ~7.2:1
    };
  }

  // ── Delivery statuses ──────────────────────────────────────────────────────

  /// Maps each delivery stage onto the audited tone steps above.
  static Color delivery(DeliveryStatus status, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (status) {
      DeliveryStatus.pending => isDark ? _warningDark : _warningLight,
      DeliveryStatus.accepted => isDark ? _infoDark : _infoLight,
      DeliveryStatus.pickedUp => isDark ? _tealDark : _tealLight,
      DeliveryStatus.inTransit => isDark ? _infoDark : _infoLight,
      DeliveryStatus.delivered => isDark ? _successDark : _successLight,
      DeliveryStatus.failed => isDark ? _dangerDark : _dangerLight,
    };
  }

  // ── Inventory levels ───────────────────────────────────────────────────────

  /// Maps [StockStatus] from the inventory feature onto audited tones.
  static Color stock(StockStatus status, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (status) {
      StockStatus.sufficient => isDark ? _successDark : _successLight,
      StockStatus.low => isDark ? _warningDark : _warningLight,
      StockStatus.outOfStock => isDark ? _dangerDark : _dangerLight,
    };
  }

  // ── Generic tones ──────────────────────────────────────────────────────────

  /// Escape hatch for future domains without a dedicated enum: resolve a
  /// [SemanticTone] against the current [brightness].
  static Color tone(SemanticTone tone, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (tone) {
      SemanticTone.success => isDark ? _successDark : _successLight,
      SemanticTone.warning => isDark ? _warningDark : _warningLight,
      SemanticTone.danger => isDark ? _dangerDark : _dangerLight,
      SemanticTone.info => isDark ? _infoDark : _infoLight,
      SemanticTone.neutral => isDark ? _neutralDark : _neutralLight,
    };
  }

  // ── Rating stars ───────────────────────────────────────────────────────────

  /// Canonical accent for star-rating icons across customer surfaces (order
  /// tracking, order history, item detail sheet).
  ///
  /// Stars deliberately reuse [SemanticTone.warning]'s audited amber /
  /// deep-orange steps so the rating hue stays consistent app-wide and keeps
  /// its >= 4.5:1 contrast bar in both brightness modes.
  static Color starRating(Brightness brightness) =>
      tone(SemanticTone.warning, brightness);
}
