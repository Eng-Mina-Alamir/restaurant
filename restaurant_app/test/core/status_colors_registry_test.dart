import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/theme/color_schemes.dart';
import 'package:restaurant_app/core/theme/status_colors.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';

/// Regression suite pinning [StatusColors] to its audited, documented values
/// (see lib/core/theme/status_colors.dart and design-system/MASTER.md §6).
///
/// Pure color math only: no widgets, no theme construction, no font fetching.
void main() {
  const surfaceLight = Color(0xFFFFF8F3);
  const surfaceDark = Color(0xFF151312);

  /// WCAG 2.1 relative-luminance contrast ratio between two colors,
  /// mirroring the MASTER.md §6 audit method.
  double contrastRatio(Color foreground, Color background) {
    final lighter =
        foreground.computeLuminance() > background.computeLuminance()
            ? foreground
            : background;
    final darker = lighter == foreground ? background : foreground;
    return (lighter.computeLuminance() + 0.05) /
        (darker.computeLuminance() + 0.05);
  }

  Color surfaceOf(Brightness brightness) =>
      brightness == Brightness.light ? surfaceLight : surfaceDark;

  void expectHoldsAAContrast(Color color, Brightness brightness, String label) {
    final ratio = contrastRatio(color, surfaceOf(brightness));
    expect(
      ratio,
      greaterThanOrEqualTo(4.5),
      reason: '$label must hold >= 4.5:1 on ${surfaceOf(brightness)} '
          '(measured $ratio)',
    );
  }

  group('StatusColors Registry Regression', () {
    test('Order statuses delegate to KdsColors.statusColor (single source)',
        () {
      for (final status in OrderStatus.values) {
        for (final brightness in Brightness.values) {
          expect(
            StatusColors.order(status, brightness),
            KdsColors.statusColor(status, brightness),
            reason: '$status/$brightness must come from KdsColors',
          );
        }
      }
    });

    test('Light and dark never collide across table/delivery/stock/tone', () {
      for (final status in TableStatus.values) {
        expect(
          StatusColors.table(status, Brightness.light),
          isNot(StatusColors.table(status, Brightness.dark)),
          reason: 'table/$status must differ per brightness',
        );
      }
      for (final status in DeliveryStatus.values) {
        expect(
          StatusColors.delivery(status, Brightness.light),
          isNot(StatusColors.delivery(status, Brightness.dark)),
          reason: 'delivery/$status must differ per brightness',
        );
      }
      for (final status in StockStatus.values) {
        expect(
          StatusColors.stock(status, Brightness.light),
          isNot(StatusColors.stock(status, Brightness.dark)),
          reason: 'stock/$status must differ per brightness',
        );
      }
      for (final tone in SemanticTone.values) {
        expect(
          StatusColors.tone(tone, Brightness.light),
          isNot(StatusColors.tone(tone, Brightness.dark)),
          reason: 'tone/$tone must differ per brightness',
        );
      }
    });
  });

  group('Documented audited hex steps', () {
    test('tone() resolves every semantic tone to its documented pair', () {
      const expected = <SemanticTone, (Color, Color)>{
        SemanticTone.success: (Color(0xFF047857), Color(0xFF4ADE80)),
        SemanticTone.warning: (Color(0xFFC2410C), Color(0xFFFDBA74)),
        SemanticTone.danger: (Color(0xFFB91C1C), Color(0xFFF87171)),
        SemanticTone.info: (Color(0xFF0369A1), Color(0xFF38BDF8)),
        SemanticTone.neutral: (Color(0xFF475569), Color(0xFF94A3B8)),
      };
      expected.forEach((tone, pair) {
        final (lightStep, darkStep) = pair;
        expect(
          StatusColors.tone(tone, Brightness.light),
          lightStep,
          reason: 'tone/$tone light drifted from the audited step $lightStep',
        );
        expect(
          StatusColors.tone(tone, Brightness.dark),
          darkStep,
          reason: 'tone/$tone dark drifted from the audited step $darkStep',
        );
      });
    });

    test('table() keeps MASTER.md light steps and reuses audited tone darks',
        () {
      // Light values come straight from the MASTER.md audit; reserved was
      // darkened one amber step (#D97706 -> #B45309) to clear the 4.5:1 bar.
      const expectedLight = <TableStatus, Color>{
        TableStatus.available: Color(0xFF15803D), // ~4.8:1 on FFF8F3
        TableStatus.occupied: Color(0xFFDC2626), // ~4.6:1 on FFF8F3
        TableStatus.reserved: Color(0xFFB45309), // ~4.8:1 on FFF8F3
        TableStatus.needsCleaning: Color(0xFF475569), // ~7.2:1 on FFF8F3
      };
      expectedLight.forEach((status, step) {
        expect(
          StatusColors.table(status, Brightness.light),
          step,
          reason: 'table/$status light drifted from the audited step $step',
        );
      });

      final expectedDark = <TableStatus, SemanticTone>{
        TableStatus.available: SemanticTone.success,
        TableStatus.occupied: SemanticTone.danger,
        TableStatus.reserved: SemanticTone.warning,
        TableStatus.needsCleaning: SemanticTone.neutral,
      };
      expectedDark.forEach((status, tone) {
        expect(
          StatusColors.table(status, Brightness.dark),
          StatusColors.tone(tone, Brightness.dark),
          reason: 'table/$status dark must reuse the audited $tone step',
        );
      });
    });

    test('delivery() tracks tone outputs with the teal pair for pickedUp', () {
      const toneByStatus = <DeliveryStatus, SemanticTone>{
        DeliveryStatus.pending: SemanticTone.warning,
        DeliveryStatus.accepted: SemanticTone.info,
        DeliveryStatus.inTransit: SemanticTone.info,
        DeliveryStatus.delivered: SemanticTone.success,
        DeliveryStatus.failed: SemanticTone.danger,
      };
      toneByStatus.forEach((status, tone) {
        for (final brightness in Brightness.values) {
          expect(
            StatusColors.delivery(status, brightness),
            StatusColors.tone(tone, brightness),
            reason: 'delivery/$status must track tone/$tone in $brightness',
          );
        }
      });

      // pickedUp rides the teal secondary pair instead of a SemanticTone.
      expect(
        StatusColors.delivery(DeliveryStatus.pickedUp, Brightness.light),
        AppColors.teal, // #006A6B
        reason: 'pickedUp light must reuse the teal secondary',
      );
      expect(
        StatusColors.delivery(DeliveryStatus.pickedUp, Brightness.dark),
        const Color(0xFF4DD8DA), // dark-scheme teal secondary
        reason: 'pickedUp dark must reuse the dark teal secondary',
      );
    });
  });

  group('Stock-to-tone alignment', () {
    test('stock levels resolve onto their semantic tones', () {
      const expectedTone = <StockStatus, SemanticTone>{
        StockStatus.sufficient: SemanticTone.success,
        StockStatus.low: SemanticTone.warning,
        StockStatus.outOfStock: SemanticTone.danger,
      };
      expectedTone.forEach((status, tone) {
        for (final brightness in Brightness.values) {
          expect(
            StatusColors.stock(status, brightness),
            StatusColors.tone(tone, brightness),
            reason: 'stock/$status must equal tone/$tone in $brightness',
          );
        }
      });
    });
  });

  group('Star-rating accent', () {
    test('starRating() equals tone(warning) in both brightness modes', () {
      for (final brightness in Brightness.values) {
        expect(
          StatusColors.starRating(brightness),
          StatusColors.tone(SemanticTone.warning, brightness),
          reason: 'stars must reuse the audited warning step in $brightness',
        );
      }
    });
  });

  group('WCAG AA contrast audit', () {
    test('every registered color holds >= 4.5:1 on its theme surface', () {
      for (final brightness in Brightness.values) {
        for (final status in TableStatus.values) {
          expectHoldsAAContrast(
            StatusColors.table(status, brightness),
            brightness,
            'table/$status',
          );
        }
        for (final status in DeliveryStatus.values) {
          expectHoldsAAContrast(
            StatusColors.delivery(status, brightness),
            brightness,
            'delivery/$status',
          );
        }
        for (final status in StockStatus.values) {
          expectHoldsAAContrast(
            StatusColors.stock(status, brightness),
            brightness,
            'stock/$status',
          );
        }
        for (final tone in SemanticTone.values) {
          expectHoldsAAContrast(
            StatusColors.tone(tone, brightness),
            brightness,
            'tone/$tone',
          );
        }
        for (final status in OrderStatus.values) {
          expectHoldsAAContrast(
            StatusColors.order(status, brightness),
            brightness,
            'order/$status',
          );
        }
        expectHoldsAAContrast(
          StatusColors.starRating(brightness),
          brightness,
          'starRating',
        );
      }
    });
  });
}
