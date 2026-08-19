import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/app.dart';
import 'package:restaurant_app/config/app_config.dart';

void main() {
  testWidgets('App renders scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RestaurantApp()));
    await tester.pump();

    // The login page should be shown for an unauthenticated (bootstrapped) user.
    expect(find.text(AppConfig.appName), findsWidgets);
  });
}
