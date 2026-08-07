import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:restaurant_app/shared/widgets/logout_action_button.dart';

void main() {
  testWidgets('logout action button transitions to unauthenticated', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login('customer@demo.com', '123456');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: LogoutActionButton())),
      ),
    );

    expect(find.byIcon(Icons.logout), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(find.text(AppConstants.logoutMessage), findsOneWidget);
  });
}
