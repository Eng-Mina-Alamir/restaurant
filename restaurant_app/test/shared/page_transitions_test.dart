import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/page_transitions.dart';

void main() {
  group('AppPageTransitions Tests', () {
    testWidgets(
      'fadeSlide creates CustomTransitionPage and builds transitions',
      (tester) async {
        final page = AppPageTransitions.fadeSlide(
          key: const ValueKey('fadeSlideKey'),
          child: const Text('FadeSlide Page Content'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  const anim = AlwaysStoppedAnimation<double>(0.5);
                  const secAnim = AlwaysStoppedAnimation<double>(0.0);
                  return page.transitionsBuilder(
                    context,
                    anim,
                    secAnim,
                    page.child,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('FadeSlide Page Content'), findsOneWidget);
      },
    );

    testWidgets(
      'scaleFade creates CustomTransitionPage and builds transitions',
      (tester) async {
        final page = AppPageTransitions.scaleFade(
          key: const ValueKey('scaleFadeKey'),
          child: const Text('ScaleFade Page Content'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  const anim = AlwaysStoppedAnimation<double>(0.5);
                  const secAnim = AlwaysStoppedAnimation<double>(0.0);
                  return page.transitionsBuilder(
                    context,
                    anim,
                    secAnim,
                    page.child,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('ScaleFade Page Content'), findsOneWidget);
      },
    );

    testWidgets(
      'sharedAxis creates CustomTransitionPage and builds transitions',
      (tester) async {
        final page = AppPageTransitions.sharedAxis(
          key: const ValueKey('sharedAxisKey'),
          child: const Text('SharedAxis Page Content'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  const anim = AlwaysStoppedAnimation<double>(0.5);
                  const secAnim = AlwaysStoppedAnimation<double>(0.0);
                  return page.transitionsBuilder(
                    context,
                    anim,
                    secAnim,
                    page.child,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('SharedAxis Page Content'), findsOneWidget);
      },
    );
  });
}
