import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/shared/widgets/constrained_content_view.dart';
import 'package:restaurant_app/shared/widgets/responsive_layout.dart';

void main() {
  const contentKey = Key('constrained_content');

  Future<void> pumpContent(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConstrainedContentView(
            child: ColoredBox(
              key: contentKey,
              color: Colors.blue,
              child: SizedBox(height: 100, width: double.infinity),
            ),
          ),
        ),
      ),
    );
  }

  group('ConstrainedContentView', () {
    testWidgets('centers child and caps width at tabletMax on desktop screens',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpContent(tester);

      final rect = tester.getRect(find.byKey(contentKey));
      expect(rect.width, AppBreakpoints.tabletMax);
      // Horizontally centered within the 1400px surface.
      expect(rect.left, closeTo((1400 - AppBreakpoints.tabletMax) / 2, 0.5));
    });

    testWidgets('passes child through unconstrained at mobile sizes',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpContent(tester);

      final rect = tester.getRect(find.byKey(contentKey));
      expect(rect.width, 400);
      expect(rect.left, 0);
    });

    testWidgets('honors a custom maxWidth', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConstrainedContentView(
              maxWidth: 720,
              child: Container(
                key: contentKey,
                height: 100,
                width: double.infinity,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      final rect = tester.getRect(find.byKey(contentKey));
      expect(rect.width, 720);
      expect(rect.left, closeTo((1400 - 720) / 2, 0.5));
    });
  });
}
