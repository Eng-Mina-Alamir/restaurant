import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/routing/app_router.dart';
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

    group('deep-link privilege escalation blocked by route guards', () {
      const allRoles = UserRole.values;

      test('customer cannot reach staff-only areas', () {
        const staffAreas = [
          '/manager',
          '/manager/users',
          '/manager/financial-reports',
          '/manager/inventory',
          '/manager/orders',
          '/waiter',
          '/waiter/table/t1',
          '/kds',
          '/driver',
        ];
        for (final area in staffAreas) {
          expect(
            canRoleAccess(UserRole.customer, area),
            isFalse,
            reason: 'Customer must NOT access $area via deep link',
          );
        }
      });

      test('staff roles cannot cross into each other areas', () {
        // Waiter cannot run the kitchen display or drive deliveries.
        expect(canRoleAccess(UserRole.waiter, '/kds'), isFalse);
        expect(canRoleAccess(UserRole.waiter, '/driver'), isFalse);
        // Kitchen cannot manage users or wait tables.
        expect(canRoleAccess(UserRole.kitchen, '/manager/users'), isFalse);
        expect(canRoleAccess(UserRole.kitchen, '/waiter'), isFalse);
        // Driver cannot open POS or dashboard.
        expect(canRoleAccess(UserRole.driver, '/waiter/order/t1'), isFalse);
        expect(canRoleAccess(UserRole.driver, '/manager'), isFalse);
      });

      test('admin and manager can access every staff area', () {
        for (final role in [UserRole.manager, UserRole.admin]) {
          for (final area in ['/manager', '/manager/users', '/waiter', '/kds', '/driver']) {
            expect(
              canRoleAccess(role, area),
              isTrue,
              reason: '$role should access $area',
            );
          }
        }
      });

      test('each role retains access to its own home area', () {
        for (final role in allRoles) {
          expect(
            canRoleAccess(role, role.homeRoute),
            isTrue,
            reason: '${role.name} should access own home ${role.homeRoute}',
          );
        }
      });

      test('shared and unknown routes stay reachable for everyone', () {
        for (final role in allRoles) {
          for (final location in [
            '/notifications',
            '/privacy-policy',
            '/terms',
            '/customer',
            '/customer/cart',
            '/customer/track/ORD-1',
            '/some-unknown-page',
          ]) {
            expect(
              canRoleAccess(role, location),
              isTrue,
              reason: '$role should access shared route $location',
            );
          }
        }
      });
    });
  });
}
