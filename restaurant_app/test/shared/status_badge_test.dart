import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/theme/color_schemes.dart';
import 'package:restaurant_app/core/theme/status_colors.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:restaurant_app/shared/animations/animated_status_badge.dart';
import 'package:restaurant_app/shared/widgets/status_badge.dart';

void main() {
  group('StatusColors Registry', () {
    test('Delegates order statuses to KdsColors.statusColor (no duplication)',
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

    test('Resolves different colors for light vs dark across all domains', () {
      final statuses = <Object>[
        ...TableStatus.values,
        ...DeliveryStatus.values,
        ...StockStatus.values,
        ...SemanticTone.values,
      ];

      for (final status in statuses) {
        Color light;
        Color dark;
        if (status is TableStatus) {
          light = StatusColors.table(status, Brightness.light);
          dark = StatusColors.table(status, Brightness.dark);
        } else if (status is DeliveryStatus) {
          light = StatusColors.delivery(status, Brightness.light);
          dark = StatusColors.delivery(status, Brightness.dark);
        } else if (status is StockStatus) {
          light = StatusColors.stock(status, Brightness.light);
          dark = StatusColors.stock(status, Brightness.dark);
        } else if (status is SemanticTone) {
          light = StatusColors.tone(status, Brightness.light);
          dark = StatusColors.tone(status, Brightness.dark);
        } else {
          throw StateError('Unhandled status type: ${status.runtimeType}');
        }

        expect(light, isNot(dark), reason: '$status must differ per brightness');
      }
    });

    test('Every registered color holds WCAG AA contrast on its background', () {
      const backgroundLight = Color(0xFFFFF8F3);
      const backgroundDark = Color(0xFF151312);

      void expectContrast(Color color, Color background, String reason) {
        final lighter =
            color.computeLuminance() > background.computeLuminance()
                ? color
                : background;
        final darker = lighter == color ? background : color;
        final ratio = (lighter.computeLuminance() + 0.05) /
            (darker.computeLuminance() + 0.05);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: '$reason ($ratio)');
      }

      for (final status in TableStatus.values) {
        expectContrast(StatusColors.table(status, Brightness.light),
            backgroundLight, 'table/$status light');
        expectContrast(StatusColors.table(status, Brightness.dark),
            backgroundDark, 'table/$status dark');
      }

      for (final status in DeliveryStatus.values) {
        expectContrast(StatusColors.delivery(status, Brightness.light),
            backgroundLight, 'delivery/$status light');
        expectContrast(StatusColors.delivery(status, Brightness.dark),
            backgroundDark, 'delivery/$status dark');
      }

      for (final status in StockStatus.values) {
        expectContrast(StatusColors.stock(status, Brightness.light),
            backgroundLight, 'stock/$status light');
        expectContrast(StatusColors.stock(status, Brightness.dark),
            backgroundDark, 'stock/$status dark');
      }

      for (final tone in SemanticTone.values) {
        expectContrast(StatusColors.tone(tone, Brightness.light),
            backgroundLight, 'tone/$tone light');
        expectContrast(StatusColors.tone(tone, Brightness.dark),
            backgroundDark, 'tone/$tone dark');
      }
    });
  });

  group('StatusBadge Widget Tests', () {
    Widget host(Widget child, {Brightness brightness = Brightness.light}) {
      return MaterialApp(
        theme: brightness == Brightness.light
            ? ThemeData.light(useMaterial3: true)
            : ThemeData.dark(useMaterial3: true),
        home: Scaffold(body: Center(child: child)),
      );
    }

    AnimatedStatusBadge badgeOf(WidgetTester tester) =>
        tester.widget<AnimatedStatusBadge>(find.byType(AnimatedStatusBadge));

    testWidgets('Renders icon and label for an order status', (tester) async {
      await tester.pumpWidget(host(StatusBadge.order(OrderStatus.ready)));
      await tester.pumpAndSettle();

      expect(find.text(OrderStatus.ready.labelAr), findsOneWidget);
      // Default icon for ready status.
      expect(badgeOf(tester).icon, Icons.takeout_dining_outlined);
      expect(badgeOf(tester).label, OrderStatus.ready.labelAr);
    });

    testWidgets('Renders every domain factory without errors', (tester) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              StatusBadge.table(TableStatus.available),
              StatusBadge.delivery(DeliveryStatus.inTransit),
              StatusBadge.stock(StockStatus.low),
              StatusBadge.order(
                OrderStatus.pending,
                icon: Icons.hourglass_top,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedStatusBadge), findsNWidgets(4));
      expect(find.text(TableStatus.available.labelAr), findsOneWidget);
      expect(find.text(DeliveryStatus.inTransit.labelAr), findsOneWidget);
      expect(find.text('منخفض'), findsOneWidget); // StockStatus.low label
      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    });

    testWidgets('Exposes a live-region Semantics node with the status label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(StatusBadge.table(TableStatus.reserved)));
      await tester.pumpAndSettle();

      final node = tester.getSemantics(
        find.bySemanticsLabel(TableStatus.reserved.labelAr),
      );
      expect(node.flagsCollection.isLiveRegion, isTrue);

      handle.dispose();
    });

    testWidgets('Resolves different badge colors in light vs dark themes',
        (tester) async {
      await tester.pumpWidget(host(StatusBadge.order(OrderStatus.pending)));
      await tester.pumpAndSettle();
      final lightColor = badgeOf(tester).color;

      await tester.pumpWidget(
        host(
          StatusBadge.order(OrderStatus.pending),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      final darkColor = badgeOf(tester).color;

      expect(
        lightColor,
        KdsColors.statusColor(OrderStatus.pending, Brightness.light),
      );
      expect(
        darkColor,
        KdsColors.statusColor(OrderStatus.pending, Brightness.dark),
      );
      expect(darkColor, isNot(lightColor));
    });
  });
}

