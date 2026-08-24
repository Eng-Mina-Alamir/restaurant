import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/fade_slide_transition.dart';
import 'package:restaurant_app/shared/animations/pulse_badge.dart';
import 'package:restaurant_app/shared/animations/scale_button.dart';
import 'package:restaurant_app/shared/animations/shimmer_loading.dart';

void main() {
  group('Enhanced Core Animations Tests', () {
    testWidgets(
      'FadeSlideTransitionWidget calls onComplete callback upon finish',
      (tester) async {
        bool completed = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FadeSlideTransitionWidget(
                duration: const Duration(milliseconds: 200),
                onComplete: () => completed = true,
                child: const Text('Completing Widget'),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(completed, isTrue);
      },
    );

    testWidgets('PulseBadge respects custom maxScale and custom duration', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PulseBadge(
              color: Colors.green,
              size: 20,
              maxScale: 3.0,
              duration: Duration(milliseconds: 800),
              child: Icon(Icons.circle, size: 10),
            ),
          ),
        ),
      );

      expect(find.byType(PulseBadge), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PulseBadge), findsOneWidget);
    });

    testWidgets('ScaleButton supports onLongPress callback', (tester) async {
      bool longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScaleButton(
              onTap: () {},
              onLongPress: () => longPressed = true,
              child: const Text('Long Press Me'),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Long Press Me'));
      await tester.pumpAndSettle();
      expect(longPressed, isTrue);
    });

    testWidgets('SkeletonCircle renders properly with custom size', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonCircle(size: 50))),
      );

      expect(find.byType(SkeletonCircle), findsOneWidget);
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });
  });
}
