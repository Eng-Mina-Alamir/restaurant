import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/shared/widgets/not_found_page.dart';

void main() {
  testWidgets('renders 404 message and navigates home on action', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/nope',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(path: '/nope', builder: (_, _) => const NotFoundPage()),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // Title shows in both the app bar and the empty-state body.
    expect(find.text(AppConstants.notFoundTitle), findsNWidgets(2));
    expect(find.text(AppConstants.notFoundAction), findsOneWidget);

    await tester.tap(find.text(AppConstants.notFoundAction));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
