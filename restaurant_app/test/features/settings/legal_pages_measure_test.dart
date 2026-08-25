import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:restaurant_app/features/settings/presentation/pages/terms_page.dart';

/// Simulated tablet/desktop viewport width where the readable-measure
/// constraint must kick in.
const double _testWidth = 1200;

/// Matches the content-width cap applied inside both legal pages.
const double _expectedMaxWidth = 720;

void main() {
  Finder constrainedContent() => find.byWidgetPredicate(
    (widget) =>
        widget is ConstrainedBox &&
        widget.constraints.maxWidth == _expectedMaxWidth,
  );

  /// Pumps [page] at a 1200px-wide viewport in [brightness] and returns the
  /// render box of the width-constrained content.
  Future<RenderBox> pumpLegalPage(
    WidgetTester tester,
    Widget page,
    Brightness brightness,
  ) async {
    tester.view.physicalSize = const Size(_testWidth, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: page,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    return tester.element(constrainedContent()).renderObject! as RenderBox;
  }

  /// Asserts the box sits centered horizontally within the viewport.
  void expectCenteredHorizontally(RenderBox box) {
    final left = box.localToGlobal(Offset.zero).dx;
    final rightMargin = _testWidth - left - box.size.width;
    expect(left, greaterThan(0), reason: 'content must not stretch full-width');
    expect(
      left,
      closeTo(rightMargin, 0.5),
      reason: 'content must be horizontally centered',
    );
  }

  group('legal pages readable measure', () {
    for (final brightness in Brightness.values) {
      testWidgets(
        'TermsPage constrains content to ${_expectedMaxWidth}px and centers '
        'it at 1200px width in $brightness',
        (tester) async {
          final box = await pumpLegalPage(
            tester,
            const TermsPage(),
            brightness,
          );

          expect(constrainedContent(), findsOneWidget);
          expect(box.size.width, lessThanOrEqualTo(_expectedMaxWidth));
          expectCenteredHorizontally(box);
        },
      );

      testWidgets(
        'PrivacyPolicyPage constrains content to ${_expectedMaxWidth}px and '
        'centers it at 1200px width in $brightness',
        (tester) async {
          final box = await pumpLegalPage(
            tester,
            const PrivacyPolicyPage(),
            brightness,
          );

          expect(constrainedContent(), findsOneWidget);
          expect(box.size.width, lessThanOrEqualTo(_expectedMaxWidth));
          expectCenteredHorizontally(box);
        },
      );
    }
  });
}
