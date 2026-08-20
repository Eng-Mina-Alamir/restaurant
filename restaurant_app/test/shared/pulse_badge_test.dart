import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/pulse_badge.dart';

void main() {
  group('PulseBadge Widget Tests', () {
    testWidgets('renders pulse badge and child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PulseBadge(
                color: Colors.red,
                size: 16.0,
                child: Text('3', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PulseBadge), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(PulseBadge), findsOneWidget);
    });
  });
}
