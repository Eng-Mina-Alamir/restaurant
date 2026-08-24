import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/di/service_locator.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/storage/in_memory_secure_storage_service.dart';
import 'package:restaurant_app/features/auth/data/datasources/demo_auth_datasource.dart';
import 'package:restaurant_app/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  group('DemoAuthDataSource.authenticate', () {
    test('logs in a demo customer with correct credentials', () {
      final user = DemoAuthDataSource.authenticate(
        'customer@demo.com',
        '123456',
      );
      expect(user, isNotNull);
      expect(user!.role, UserRole.customer);
    });

    test('accepts leading/trailing whitespace on the identifier', () {
      final user = DemoAuthDataSource.authenticate(
        '  MANAGER@demo.com  ',
        '123456',
      );
      expect(user, isNotNull);
      expect(user!.role, UserRole.manager);
    });

    test('rejects a wrong password', () {
      expect(
        DemoAuthDataSource.authenticate('waiter@demo.com', 'wrong'),
        isNull,
      );
    });

    test('rejects an unknown identifier', () {
      expect(
        DemoAuthDataSource.authenticate('nobody@demo.com', '123456'),
        isNull,
      );
    });
  });

  group('AuthController via demo datasource', () {
    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(
            DemoAuthRemoteDataSource(),
          ),
          secureStorageServiceProvider.overrideWithValue(
            InMemorySecureStorageService(),
          ),
        ],
      );
    }

    test('login succeeds for a demo driver via provider override', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).bootstrap();
      await container
          .read(authControllerProvider.notifier)
          .login('driver@demo.com', '123456');

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.role, UserRole.driver);
    });

    test('failed login surfaces a failure and stays unauthenticated', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('driver@demo.com', 'nope');

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.authFailure, isNotNull);
    });

    test('bootstrap restores a persisted demo session after login', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('manager@demo.com', '123456');
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);

      // Simulate a fresh app bootstrap; the persisted session should be
      // restored from secure storage.
      await container.read(authControllerProvider.notifier).bootstrap();

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.role, UserRole.manager);
    });

    test(
      'bootstrap stays unauthenticated after logout clears the session',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(authControllerProvider.notifier)
            .login('customer@demo.com', '123456');
        await container.read(authControllerProvider.notifier).logout();

        await container.read(authControllerProvider.notifier).bootstrap();

        final state = container.read(authControllerProvider);
        expect(state.isAuthenticated, isFalse);
      },
    );
  });
}
