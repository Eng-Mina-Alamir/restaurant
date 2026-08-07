import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/shared/widgets/empty_state.dart';

void main() {
  testWidgets('shows message and optional action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            message: 'لا يوجد شيء',
            icon: Icons.inbox_outlined,
            actionLabel: 'إعادة المحاولة',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('لا يوجد شيء'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    expect(tapped, isTrue);
  });

  testWidgets('renders without action button when omitted', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EmptyState(message: 'فارغ')),
      ),
    );
    expect(find.text('فارغ'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
