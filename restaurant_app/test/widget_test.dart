import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/main.dart';

void main() {
  testWidgets('App renders app name placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const RestaurantApp());

    expect(find.text('مطعمي - جاهز للتطوير'), findsOneWidget);
  });
}
