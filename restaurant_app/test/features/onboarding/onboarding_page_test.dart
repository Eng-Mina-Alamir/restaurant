import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  group('OnboardingPage Tests', () {
    testWidgets('renders first onboarding slide and advances to next slide', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: OnboardingPage())),
      );

      // Verify first slide title
      expect(find.text('طلب ذكي ومباشر من طاولتك 🍽️'), findsOneWidget);
      expect(find.text('تخطي'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);

      // Tap next button
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      // Verify second slide title
      expect(find.text('متابعة حية لحظة بلحظة ⏱️'), findsOneWidget);

      // Tap next button again
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      // Verify third slide title and start button
      expect(find.text('دفع متعدد ونقاط ولاء ومكافآت 🎁'), findsOneWidget);
      expect(find.text('ابدأ الآن'), findsOneWidget);
    });
  });
}
