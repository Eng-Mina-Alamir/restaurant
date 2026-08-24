import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/di/service_locator.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:restaurant_app/features/auth/data/models/user_model.dart';
import 'package:restaurant_app/features/auth/presentation/controllers/auth_controller.dart';

class _MockAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(String identifier, String password) async {
    return UserModel(
      id: 'usr-manager-1',
      name: 'كيرلس الأمير',
      email: identifier,
      phone: '01012345678',
      role: UserRole.manager,
      token: 'jwt-token-123',
      createdAt: DateTime(2025),
    );
  }

  @override
  Future<void> logout(String? token) async {}

  @override
  Future<String> refreshToken(String refreshToken) async =>
      'jwt-token-refreshed';

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
      id: 'usr-new-1',
      name: name,
      email: email,
      phone: phone,
      role: role,
      token: 'jwt-token-registered',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel> verifyOtp({
    required String otp,
    required String phone,
  }) async {
    return UserModel(
      id: 'usr-otp-1',
      name: 'مستخدم محقق',
      email: 'otp@example.com',
      phone: phone,
      role: UserRole.customer,
      token: 'jwt-token-otp',
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  group('Auth Flow Integration Test', () {
    test(
      'complete authentication cycle: login -> role check -> logout',
      () async {
        final container = ProviderContainer(
          overrides: [
            authRemoteDataSourceProvider.overrideWithValue(
              _MockAuthRemoteDataSource(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final authNotifier = container.read(authControllerProvider.notifier);

        // Initially unknown / unauthenticated
        expect(container.read(authControllerProvider).isAuthenticated, isFalse);

        // Login as manager
        await authNotifier.login('manager@restaurant.com', 'strongpassword123');

        final authState = container.read(authControllerProvider);
        expect(authState.isAuthenticated, isTrue);
        expect(authState.user?.role, UserRole.manager);
        expect(authState.user?.role.homeRoute, '/manager');

        // Logout
        await authNotifier.logout();

        final loggedOutState = container.read(authControllerProvider);
        expect(loggedOutState.isAuthenticated, isFalse);
        expect(loggedOutState.user, isNull);
      },
    );
  });
}
