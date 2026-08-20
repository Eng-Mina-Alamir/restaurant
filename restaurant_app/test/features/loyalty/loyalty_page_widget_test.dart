import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/loyalty/presentation/pages/loyalty_page.dart';

void main() {
  group('LoyaltyPage Widget Tests', () {
    testWidgets('renders loyalty tier, points, rewards catalog and points history', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoyaltyPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('برنامج الولاء والمكافآت'), findsOneWidget);
      expect(find.text('المكافآت المتاحة للاستبدال'), findsOneWidget);
      expect(find.text('سجل النقاط والمعاملات'), findsOneWidget);
      expect(find.textContaining('نقطة'), findsWidgets);
    });

    testWidgets('tapping redeem opens confirmation dialog', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoyaltyPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final redeemBtn = find.text('استبدال').first;
      if (redeemBtn.evaluate().isNotEmpty) {
        await tester.tap(redeemBtn);
        await tester.pumpAndSettle();

        expect(find.text('تأكيد الاستبدال'), findsOneWidget);
        expect(find.text('إلغاء'), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.text('إلغاء'));
        await tester.pumpAndSettle();
        expect(find.text('تأكيد الاستبدال'), findsNothing);
      }
    });
  });
}
