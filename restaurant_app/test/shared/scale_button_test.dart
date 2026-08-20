import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/scale_button.dart';

void main() {
  group('ScaleButton Widget Tests', () {
    testWidgets('triggers onTap callback when pressed', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScaleButton(
                onTap: () => tapped = true,
                child: const Text('اضغط هنا'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('اضغط هنا'), findsOneWidget);

      await tester.tap(find.text('اضغط هنا'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
