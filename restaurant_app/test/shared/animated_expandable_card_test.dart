import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/animated_expandable_card.dart';

void main() {
  group('AnimatedExpandableCard Tests', () {
    testWidgets('Toggles expansion and executes onExpansionChanged callback', (
      tester,
    ) async {
      bool? expandedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedExpandableCard(
              header: const Text('Card Header'),
              expandedContent: const Text('Hidden Details'),
              onExpansionChanged: (state) => expandedState = state,
            ),
          ),
        ),
      );

      expect(find.text('Card Header'), findsOneWidget);
      expect(find.text('Hidden Details'), findsOneWidget);

      // Tap header to expand
      await tester.tap(find.text('Card Header'));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(expandedState, isTrue);

      // Tap header to collapse
      await tester.tap(find.text('Card Header'));
      await tester.pumpAndSettle();

      expect(expandedState, isFalse);
    });

    testWidgets('Starts expanded when initiallyExpanded is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedExpandableCard(
              initiallyExpanded: true,
              header: Text('Expanded Header'),
              expandedContent: Text('Visible Details'),
            ),
          ),
        ),
      );

      expect(find.text('Expanded Header'), findsOneWidget);
      expect(find.text('Visible Details'), findsOneWidget);
    });
  });
}
