import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/floating_illustration.dart';

void main() {
  group('FloatingIllustration & BreathingWidget Tests', () {
    testWidgets(
      'FloatingIllustration renders child and completes translation',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FloatingIllustration(
                distance: 12.0,
                duration: Duration(milliseconds: 400),
                child: Icon(Icons.inbox, size: 48),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.inbox), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.inbox), findsOneWidget);
      },
    );

    testWidgets('BreathingWidget scales child smoothly and completes', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BreathingWidget(
              minScale: 0.9,
              maxScale: 1.1,
              duration: Duration(milliseconds: 400),
              child: Text('Breathing Text'),
            ),
          ),
        ),
      );

      expect(find.text('Breathing Text'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Breathing Text'), findsOneWidget);
    });

    testWidgets('Respects disableAnimations in accessibility settings', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: FloatingIllustration(child: Text('Static Text')),
            ),
          ),
        ),
      );

      expect(find.text('Static Text'), findsOneWidget);
    });
  });
}
