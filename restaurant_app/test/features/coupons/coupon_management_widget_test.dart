import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/coupons/presentation/pages/coupon_management_page.dart';

void main() {
  group('CouponManagementPage Widget Tests', () {
    testWidgets('renders coupon list and action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: CouponManagementPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('إدارة الكوبونات وأكواد الخصم'), findsOneWidget);
      expect(find.text('إنشاء كوبون'), findsOneWidget);
    });

    testWidgets('tapping create coupon button opens creation modal', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: CouponManagementPage())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('إنشاء كود خصم جديد'), findsOneWidget);
      expect(find.text('كود الخصم (مثال: SAVE20) *'), findsOneWidget);
      expect(find.text('إنشاء الكود'), findsOneWidget);
    });
  });
}
