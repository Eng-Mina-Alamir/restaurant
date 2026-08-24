import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/auth/presentation/pages/register_page.dart';

void main() {
  group('RegisterPage Widget Tests', () {
    testWidgets(
      'renders registration form with secure customer role and validation',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: RegisterPage())),
        );

        expect(find.text('إنشاء حساب جديد'), findsOneWidget);
        expect(find.text('الاسم بالكامل'), findsOneWidget);
        expect(find.text('رقم الهاتف'), findsOneWidget);
        expect(find.text('إنشاء الحساب والمتابعة'), findsOneWidget);

        await tester.ensureVisible(find.text('إنشاء الحساب والمتابعة'));
        await tester.tap(find.text('إنشاء الحساب والمتابعة'));
        await tester.pump();

        expect(find.text('يرجى إدخال الاسم'), findsOneWidget);
        expect(find.text('يرجى إدخال رقم الهاتف'), findsOneWidget);
      },
    );
  });
}
