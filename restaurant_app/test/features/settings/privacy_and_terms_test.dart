import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:restaurant_app/features/settings/presentation/pages/terms_page.dart';

void main() {
  group('Privacy Policy and Terms Pages', () {
    testWidgets('PrivacyPolicyPage renders security and data usage sections', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));
      await tester.pumpAndSettle();

      expect(find.text('سياسة الخصوصية'), findsOneWidget);
      expect(find.text('1. البيانات التي نجمعها'), findsOneWidget);
      expect(find.text('2. أمان المدفوعات والمعاملات'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('4. حقوق المستخدم'), 200);
      expect(find.text('4. حقوق المستخدم'), findsOneWidget);
    });

    testWidgets(
      'TermsPage renders cancellation, pricing, and delivery conditions',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: TermsPage()));
        await tester.pumpAndSettle();

        expect(find.text('الشروط والأحكام'), findsOneWidget);
        expect(find.text('1. قبول الطلبات'), findsOneWidget);
        expect(find.text('2. سياسة الإلغاء والاسترجاع'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('4. التوصيل والمسؤولية'),
          200,
        );
        expect(find.text('4. التوصيل والمسؤولية'), findsOneWidget);
      },
    );
  });
}
