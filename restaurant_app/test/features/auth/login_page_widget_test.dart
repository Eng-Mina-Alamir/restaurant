import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/app_config.dart';
import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage Production Widget Tests', () {
    testWidgets('renders login form, input fields, and submit button in production', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      expect(find.text(AppConfig.appName), findsOneWidget);
      expect(find.text(AppConstants.loginSubtitle), findsOneWidget);
      expect(find.text(AppConstants.emailLabel), findsOneWidget);
      expect(find.text(AppConstants.passwordLabel), findsOneWidget);
      expect(find.text(AppConstants.loginButton), findsOneWidget);
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);

      // Validate empty form submission triggers required error
      await tester.tap(find.text(AppConstants.loginButton));
      await tester.pump();

      expect(find.text(AppConstants.requiredField), findsNWidgets(2));
    });

    testWidgets('entering credentials updates text fields and enables submission', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      final emailField = find.widgetWithText(TextFormField, AppConstants.emailLabel);
      final passwordField = find.widgetWithText(TextFormField, AppConstants.passwordLabel);

      await tester.enterText(emailField, 'manager@restaurant.com');
      await tester.enterText(passwordField, 'secret123');
      await tester.pump();

      expect(find.text('manager@restaurant.com'), findsOneWidget);
      expect(find.text('secret123'), findsOneWidget);
    });
  });
}
