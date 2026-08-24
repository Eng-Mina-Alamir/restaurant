import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/animated_counter.dart';

void main() {
  group('AnimatedCounter & AnimatedPriceTicker Tests', () {
    testWidgets('AnimatedCounter animates integer value from start to finish', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 100,
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);

      // Rebuild with new target value
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 200,
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));
      // Midpoint evaluation
      await tester.pumpAndSettle();
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets(
      'AnimatedCounter formats with prefix, suffix and decimalPlaces',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AnimatedCounter(
                value: 45.5,
                prefix: 'Total: ',
                suffix: ' SAR',
                decimalPlaces: 2,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Total: 45.50 SAR'), findsOneWidget);
      },
    );

    testWidgets('AnimatedPriceTicker renders formatted currency correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedPriceTicker(amount: 129.99, currency: 'ر.س'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('129.99 ر.س'), findsOneWidget);
    });
  });
}
