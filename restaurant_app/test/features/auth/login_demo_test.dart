import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('tapping a demo chip fills the credentials fields', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(ActionChip, 'مدير'));
    await tester.pumpAndSettle();

    expect(find.text('manager@demo.com'), findsOneWidget);
    expect(find.text('123456'), findsWidgets);
  });
}
