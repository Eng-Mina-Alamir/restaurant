import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  group('OnboardingPage Tests', () {
    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: OnboardingPage())),
      );
    }

    testWidgets('renders first onboarding slide and advances to next slide', (
      tester,
    ) async {
      await pumpPage(tester);

      // Verify first slide title
      expect(find.text('طلب ذكي ومباشر من طاولتك'), findsOneWidget);
      expect(find.text('تخطي'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);

      // Tap next button
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      // Verify second slide title
      expect(find.text('متابعة حية لحظة بلحظة'), findsOneWidget);

      // Tap next button again
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      // Verify third slide title and start button
      expect(find.text('دفع متعدد ونقاط ولاء ومكافآت'), findsOneWidget);
      expect(find.text('ابدأ الآن'), findsOneWidget);
    });

    test('onboarding page source stays free of emoji codepoints', () {
      final source = File(
        'lib/features/onboarding/presentation/pages/onboarding_page.dart',
      ).readAsStringSync();

      // Covers pictographs (1F000-1FAFF), misc symbols & dingbats
      // (2600-27BF), clock/watch symbols (2300-23FF), misc symbols and
      // arrows (2B00-2BFF) plus the emoji variation selector (FE00-FE0F).
      final emojiPattern = RegExp(
        '[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2300}-\u{23FF}'
        '\u{2B00}-\u{2BFF}\u{FE00}-\u{FE0F}]',
        unicode: true,
      );

      expect(
        emojiPattern.allMatches(source).map((match) => match.group(0)).toList(),
        isEmpty,
        reason: 'Onboarding copy must stay emoji-free; icons carry the visual.',
      );
    });

    testWidgets('page dots live region announces page changes to screen '
        'readers', (tester) async {
      final semantics = tester.ensureSemantics();

      await pumpPage(tester);

      var dotsNode = tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^الصفحة \d من 3$')),
      );
      expect(find.bySemanticsLabel('الصفحة 1 من 3'), findsOneWidget);
      expect(dotsNode.flagsCollection.isLiveRegion, isTrue);

      // Swipe to the second slide; the announced label must follow.
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 10000);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('الصفحة 2 من 3'), findsOneWidget);
      dotsNode = tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^الصفحة \d من 3$')),
      );
      expect(dotsNode.label, 'الصفحة 2 من 3');
      expect(dotsNode.flagsCollection.isLiveRegion, isTrue);

      semantics.dispose();
    });

    testWidgets('cta button semantics reflect the current action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await pumpPage(tester);

      // Early slides announce the advance action.
      final nextNode = tester.getSemantics(find.bySemanticsLabel('التالي'));
      expect(nextNode.flagsCollection.isButton, isTrue);

      // Advance to the final slide.
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      // Last page announces the start action instead.
      final startNode = tester.getSemantics(find.bySemanticsLabel('ابدأ الآن'));
      expect(startNode.flagsCollection.isButton, isTrue);
      expect(startNode.label, 'ابدأ الآن');

      semantics.dispose();
    });
  });
}
