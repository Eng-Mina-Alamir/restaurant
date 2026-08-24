import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/animated_success_checkmark.dart';

void main() {
  group('AnimatedSuccessCheckmark Tests', () {
    testWidgets(
      'Renders and triggers onComplete callback upon animation finish',
      (tester) async {
        bool completed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedSuccessCheckmark(
                size: 100,
                color: Colors.green,
                duration: const Duration(milliseconds: 400),
                onComplete: () => completed = true,
              ),
            ),
          ),
        );

        expect(find.byType(AnimatedSuccessCheckmark), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();

        expect(completed, isTrue);
      },
    );

    testWidgets('Renders static icon when animations are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AnimatedSuccessCheckmark(size: 80, color: Colors.blue),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
