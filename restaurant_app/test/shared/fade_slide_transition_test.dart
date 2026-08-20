import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/fade_slide_transition.dart';

void main() {
  group('FadeSlideTransitionWidget Tests', () {
    testWidgets('renders child and completes animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeSlideTransitionWidget(
              duration: Duration(milliseconds: 300),
              child: Text('محتوى متحرك'),
            ),
          ),
        ),
      );

      expect(find.text('محتوى متحرك'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('محتوى متحرك'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('محتوى متحرك'), findsOneWidget);
    });
  });
}
