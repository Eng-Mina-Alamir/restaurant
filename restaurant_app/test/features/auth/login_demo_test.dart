import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:restaurant_app/features/auth/presentation/pages/login_page.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders demo account chips in demo mode', (tester) async {
    await pump(tester);
    expect(find.text('حسابات تجريبية'), findsOneWidget);
    expect(find.textContaining('123456'), findsOneWidget);
    expect(find.byType(ActionChip), findsWidgets);
  });

  testWidgets('tapping a demo chip logs in to that role immediately', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'مدير'));
    await tester.pumpAndSettle();

    final auth = container.read(authControllerProvider);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.user?.email, 'manager@demo.com');
  });
}
