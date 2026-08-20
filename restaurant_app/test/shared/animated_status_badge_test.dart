import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/animated_status_badge.dart';

void main() {
  group('AnimatedStatusBadge Tests', () {
    testWidgets('Renders badge with icon and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedStatusBadge(
              label: 'متاح',
              color: Colors.green,
              icon: Icons.check_circle_outline,
            ),
          ),
        ),
      );

      expect(find.text('متاح'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('Triggers bounce animation when label and color update',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedStatusBadge(
              label: 'متاح',
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('متاح'), findsOneWidget);

      // Update state to 'مشغول'
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedStatusBadge(
              label: 'مشغول',
              color: Colors.red,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('مشغول'), findsOneWidget);
    });

    testWidgets('Renders correctly with disableAnimations', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AnimatedStatusBadge(
                label: 'قيد التنظيف',
                color: Colors.orange,
              ),
            ),
          ),
        ),
      );

      expect(find.text('قيد التنظيف'), findsOneWidget);
    });
  });
}
