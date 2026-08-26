import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/animated_press_card.dart';

void main() {
  group('AnimatedPressCard Tests', () {
    testWidgets('Triggers onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedPressCard(
              onTap: () => tapped = true,
              child: const Text('Pressable Card'),
            ),
          ),
        ),
      );

      expect(find.text('Pressable Card'), findsOneWidget);
      await tester.tap(find.text('Pressable Card'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('Triggers onLongPress callback when long pressed', (
      tester,
    ) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedPressCard(
              onLongPress: () => longPressed = true,
              child: const Text('Long Press Card'),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Long Press Card'));
      await tester.pumpAndSettle();

      expect(longPressed, isTrue);
    });

    testWidgets('Animates scale down on tap down and restores on cancel', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedPressCard(
              onTap: () {},
              child: const Text('Scale Card'),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Scale Card')),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(find.text('Scale Card'), findsOneWidget);
    });

    testWidgets('Renders properly with disableAnimations: true', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AnimatedPressCard(
                onTap: () => tapped = true,
                child: const Text('Accessible Card'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Accessible Card'), findsOneWidget);
      await tester.tap(find.text('Accessible Card'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('AnimatedPressCard button semantics', () {
    // The button flags live on the card's own Semantics node; child content
    // (labels, nested controls) stays independently reachable beneath it.
    Finder cardNodeOf(String label) => find.ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedPressCard),
        );

    testWidgets('announces button role when onTap is provided', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedPressCard(
              onTap: () {},
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      final node = tester.getSemantics(cardNodeOf('Tappable Card'));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);

      semantics.dispose();
    });

    testWidgets('is not flagged as a button without callbacks', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedPressCard(child: Text('Static Card')),
          ),
        ),
      );

      final node = tester.getSemantics(cardNodeOf('Static Card'));
      expect(node.flagsCollection.isButton, isFalse);

      semantics.dispose();
    });

    testWidgets('reports disabled when only onLongPress is provided', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedPressCard(
              onLongPress: () {},
              child: const Text('Long Press Only Card'),
            ),
          ),
        ),
      );

      // Still interactive (wrapped), but with no tap action the button
      // announces itself as disabled.
      final node = tester.getSemantics(cardNodeOf('Long Press Only Card'));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);

      semantics.dispose();
    });
  });
}
