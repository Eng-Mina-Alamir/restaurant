import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/features/loyalty/domain/entities/loyalty_entity.dart';
import 'package:restaurant_app/features/loyalty/presentation/controllers/loyalty_controller.dart';
import 'package:restaurant_app/features/loyalty/presentation/pages/loyalty_page.dart';
import 'package:restaurant_app/shared/widgets/error_state.dart';

void main() {
  group('LoyaltyPage Widget Tests', () {
    testWidgets(
      'renders loyalty tier, points, rewards catalog and points history',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: LoyaltyPage())),
        );
        await tester.pumpAndSettle();

        expect(find.text('برنامج الولاء والمكافآت'), findsOneWidget);
        expect(find.text('المكافآت المتاحة للاستبدال'), findsOneWidget);
        expect(find.text('سجل النقاط والمعاملات'), findsOneWidget);
        expect(find.textContaining('نقطة'), findsWidgets);
      },
    );

    testWidgets('tapping redeem opens confirmation dialog', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoyaltyPage())),
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

    testWidgets(
      'rewards failure shows shared ErrorState and retry invalidates rewards provider',
      (tester) async {
        var failRewards = true;
        var rewardsBuilds = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              availableRewardsProvider.overrideWith((ref) async {
                rewardsBuilds++;
                if (failRewards) {
                  throw Exception('تعذر جلب المكافآت من المصدر');
                }
                return const [
                  LoyaltyReward(
                    id: 'reward-1',
                    title: 'قهوة مجانية',
                    description: 'قهوة لاتيه مجانية',
                    pointsCost: 100,
                    discountAmount: 15,
                  ),
                ];
              }),
            ],
            child: const MaterialApp(home: LoyaltyPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Rewards failure surfaces via the shared ErrorState with a retry
        // action (not a bare Text).
        expect(rewardsBuilds, 1);
        expect(find.byType(ErrorState), findsOneWidget);
        expect(find.text(AppConstants.errorLoadingData), findsOneWidget);
        final retryBtn = find.text(AppConstants.orderAuditTrailRetryAction);
        expect(retryBtn, findsOneWidget);

        // Tapping retry invalidates the rewards provider and recovers.
        failRewards = false;
        await tester.ensureVisible(retryBtn);
        await tester.tap(retryBtn);
        await tester.pumpAndSettle();

        expect(rewardsBuilds, 2);
        expect(find.byType(ErrorState), findsNothing);
        expect(find.text('قهوة مجانية'), findsOneWidget);
      },
    );
  });
}
