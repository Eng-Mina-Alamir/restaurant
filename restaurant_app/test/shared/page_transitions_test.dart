import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

  group('AppPageTransitions Reduced-Motion Tests', () {
    const transitionUnderTestKey = ValueKey('transition-under-test');
    const anim = AlwaysStoppedAnimation<double>(0.25);
    const secAnim = AlwaysStoppedAnimation<double>(0.0);

    /// Pumps [page]'s transitionsBuilder inside a MediaQuery override that
    /// disables animations, wrapping the result in a keyed subtree so type
    /// finders can be scoped away from MaterialApp's own route transitions.
    Future<void> pumpReducedMotion(
      WidgetTester tester,
      CustomTransitionPage<dynamic> page,
    ) {
      return tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) => KeyedSubtree(
                key: transitionUnderTestKey,
                child: page.transitionsBuilder(
                  context,
                  anim,
                  secAnim,
                  page.child,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Finder withinTransition(Finder matching) => find.descendant(
          of: find.byKey(transitionUnderTestKey),
          matching: matching,
        );

    testWidgets(
      'fadeSlide applies no slide offset and final opacity when animations '
      'are disabled',
      (tester) async {
        final page = AppPageTransitions.fadeSlide(
          key: const ValueKey('fadeSlideReducedMotionKey'),
          child: const Text('FadeSlide Reduced Motion Content'),
        );

        await pumpReducedMotion(tester, page);

        // Page content still renders.
        expect(find.text('FadeSlide Reduced Motion Content'), findsOneWidget);

        // Fade-only at final opacity 1.0.
        expect(withinTransition(find.byType(FadeTransition)), findsOneWidget);
        final fade = tester.widget<FadeTransition>(
          withinTransition(find.byType(FadeTransition)),
        );
        expect(fade.opacity.value, moreOrLessEquals(1.0));

        // No offsetting SlideTransition anywhere in the transition subtree.
        expect(withinTransition(find.byType(SlideTransition)), findsNothing);
      },
    );

    testWidgets(
      'scaleFade applies no scale transform and final opacity when animations '
      'are disabled',
      (tester) async {
        final page = AppPageTransitions.scaleFade(
          key: const ValueKey('scaleFadeReducedMotionKey'),
          child: const Text('ScaleFade Reduced Motion Content'),
        );

        await pumpReducedMotion(tester, page);

        // Page content still renders.
        expect(find.text('ScaleFade Reduced Motion Content'), findsOneWidget);

        // Fade-only at final opacity 1.0.
        expect(withinTransition(find.byType(FadeTransition)), findsOneWidget);
        final fade = tester.widget<FadeTransition>(
          withinTransition(find.byType(FadeTransition)),
        );
        expect(fade.opacity.value, moreOrLessEquals(1.0));

        // No scaling ScaleTransition anywhere in the transition subtree.
        expect(withinTransition(find.byType(ScaleTransition)), findsNothing);
      },
    );

    testWidgets(
      'slide and scale offsets are still applied when animations are enabled',
      (tester) async {
        final fadeSlidePage = AppPageTransitions.fadeSlide(
          key: const ValueKey('fadeSlideEnabledKey'),
          child: const Text('FadeSlide Enabled Content'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => KeyedSubtree(
                  key: transitionUnderTestKey,
                  child: fadeSlidePage.transitionsBuilder(
                    context,
                    anim,
                    secAnim,
                    fadeSlidePage.child,
                  ),
                ),
              ),
            ),
          ),
        );

        final slide = tester.widget<SlideTransition>(
          withinTransition(find.byType(SlideTransition)),
        );
        expect(slide.position.value, isNot(Offset.zero));

        final scaleFadePage = AppPageTransitions.scaleFade(
          key: const ValueKey('scaleFadeEnabledKey'),
          child: const Text('ScaleFade Enabled Content'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => KeyedSubtree(
                  key: transitionUnderTestKey,
                  child: scaleFadePage.transitionsBuilder(
                    context,
                    anim,
                    secAnim,
                    scaleFadePage.child,
                  ),
                ),
              ),
            ),
          ),
        );

        final scale = tester.widget<ScaleTransition>(
          withinTransition(find.byType(ScaleTransition)),
        );
        expect(scale.scale.value, lessThan(1.0));
      },
    );
  });
}
