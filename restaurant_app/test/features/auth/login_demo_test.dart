import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/core/di/service_locator.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:restaurant_app/features/auth/data/models/user_model.dart';
import 'package:restaurant_app/features/auth/presentation/pages/login_page.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(String identifier, String password) async {
    return UserModel(
      id: 'test-user',
      name: 'User',
      email: identifier,
      phone: '01012345678',
      role: UserRole.customer,
      token: 'token',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> logout(String? token) async {}

  @override
  Future<String> refreshToken(String refreshToken) async => 'token';

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String restaurantId,
    UserRole role = UserRole.customer,
  }) async {
    return UserModel(
      id: 'test-user',
      name: name,
      email: email,
      phone: phone,
      role: role,
      token: 'token',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel> verifyOtp({
    required String otp,
    required String phone,
  }) async {
    return UserModel(
      id: 'test-user',
      name: 'User',
      email: 'test@example.com',
      phone: phone,
      role: UserRole.customer,
      token: 'token',
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  testWidgets('production login page does not display demo account chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );
    await tester.pump();

    expect(find.text('حسابات تجريبية'), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text(AppConstants.loginButton), findsOneWidget);
  });

  testWidgets('login page form submission triggers auth workflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(
            _FakeAuthRemoteDataSource(),
          ),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pump();

    final emailField = find.widgetWithText(
      TextFormField,
      AppConstants.emailLabel,
    );
    final passwordField = find.widgetWithText(
      TextFormField,
      AppConstants.passwordLabel,
    );

    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordField, 'password123');
    await tester.pump();

    await tester.tap(find.text(AppConstants.loginButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('test@example.com'), findsOneWidget);
  });
}
