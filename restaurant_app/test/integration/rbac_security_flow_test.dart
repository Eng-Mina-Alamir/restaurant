import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/auth/data/datasources/demo_auth_datasource.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';

void main() {
  group('RBAC & Role Routing Security Integration Flow', () {
    test('all roles map to their designated isolated home routes', () {
      expect(UserRole.customer.homeRoute, '/customer');
      expect(UserRole.waiter.homeRoute, '/waiter');
      expect(UserRole.kitchen.homeRoute, '/kds');
      expect(UserRole.manager.homeRoute, '/manager');
      expect(UserRole.admin.homeRoute, '/manager');
      expect(UserRole.driver.homeRoute, '/driver');
    });

    test('demo authentication enforces role integrity and email matching', () {
      for (final role in DemoAuthDataSource.supportedRoles) {
        final email = DemoAuthDataSource.accounts[role]!;
        final user = DemoAuthDataSource.authenticate(email, DemoAuthDataSource.password);

        expect(user, isNotNull);
        expect(user!.role, role);
        expect(user.email, email);
        expect(user.isActive, isTrue);
      }
    });

    test('rejection of unauthorized credentials across role accounts', () {
      final invalidUser = DemoAuthDataSource.authenticate(
        'manager@demo.com',
        'wrong-password',
      );
      expect(invalidUser, isNull);
    });

    test('UserEntity immutability and role persistence', () {
      final user = UserEntity(
        id: 'usr-1',
        name: 'Manager',
        email: 'manager@restaurant.com',
        phone: '0500000000',
        role: UserRole.manager,
        createdAt: DateTime(2026, 1, 1),
      );

      final cloned = user.copyWith(name: 'Updated Manager');
      expect(cloned.role, UserRole.manager);
      expect(cloned.name, 'Updated Manager');
      expect(user.name, 'Manager');
    });
  });
}
