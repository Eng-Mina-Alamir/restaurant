import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/animations/staggered_fade_slide_list.dart';

void main() {
  group('StaggeredFadeSlideList & AnimatedListItem Tests', () {
    testWidgets('AnimatedListItem renders child and completes transition', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              duration: Duration(milliseconds: 200),
              child: Text('Staggered Item 0'),
            ),
          ),
        ),
      );

      expect(find.text('Staggered Item 0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Staggered Item 0'), findsOneWidget);
    });

    testWidgets('StaggeredFadeSlideList renders multiple items sequentially', (
      tester,
    ) async {
      final items = List.generate(5, (i) => 'Item $i');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredFadeSlideList(
              itemCount: items.length,
              staggerDuration: const Duration(milliseconds: 50),
              animationDuration: const Duration(milliseconds: 200),
              itemBuilder: (context, index) => Text(items[index]),
            ),
          ),
        ),
      );

      for (var i = 0; i < 5; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      for (var i = 0; i < 5; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
    });

    testWidgets('Respects MediaQuery.disableAnimationsOf', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AnimatedListItem(
                index: 1,
                child: Text('Disabled Animation Item'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Disabled Animation Item'), findsOneWidget);
    });
  });
}
