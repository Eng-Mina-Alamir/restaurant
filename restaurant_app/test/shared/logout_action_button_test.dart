import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/core/di/service_locator.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';
import 'package:restaurant_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:restaurant_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:restaurant_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:restaurant_app/shared/widgets/logout_action_button.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, UserEntity>> restoreSession() async =>
      const Left(CacheFailure('No session'));

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);
}

class _FakeLogoutUseCase extends LogoutUseCase {
  _FakeLogoutUseCase() : super(_FakeAuthRepository());

  @override
  Future<Either<Failure, void>> call() async => const Right(null);
}

void main() {
  testWidgets(
    'logout action button transitions to unauthenticated and shows snackbar',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          logoutUseCaseProvider.overrideWithValue(_FakeLogoutUseCase()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: LogoutActionButton())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsOneWidget);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
      expect(find.text(AppConstants.logoutMessage), findsOneWidget);
    },
  );
}
