import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/fade_slide_transition.dart';
import 'package:restaurant_app/shared/animations/pulse_badge.dart';
import 'package:restaurant_app/shared/animations/scale_button.dart';
import 'package:restaurant_app/shared/animations/shimmer_loading.dart';

void main() {
  group('Shared Animations & Micro-interactions', () {
    testWidgets('FadeSlideTransitionWidget renders and animates child', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeSlideTransitionWidget(child: Text('Animated Text')),
          ),
        ),
      );

      expect(find.text('Animated Text'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Animated Text'), findsOneWidget);
    });

    testWidgets('ShimmerLoading and SkeletonBox render properly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonBox(width: 100, height: 20)),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(SkeletonBox), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('PulseBadge renders with animated pulse effect', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PulseBadge(color: Colors.red, size: 14)),
        ),
      );

      expect(find.byType(PulseBadge), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('ScaleButton reacts to press and triggers onTap', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScaleButton(
              onTap: () => tapped = true,
              child: const Text('Press Me'),
            ),
          ),
        ),
      );

      expect(find.text('Press Me'), findsOneWidget);
      await tester.tap(find.text('Press Me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
