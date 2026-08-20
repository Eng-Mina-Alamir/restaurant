import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/features/customer/presentation/widgets/category_chips.dart';
import 'package:restaurant_app/features/menu/presentation/controllers/menu_controller.dart';

void main() {
  group('CategoryChips Widget Tests', () {
    testWidgets('renders all category chips with initial selected', (tester) async {
      String selectedCat = kAllCategoriesFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChips(
              categories: const ['مشويات', 'مقبلات', 'مشروبات'],
              selected: selectedCat,
              onSelected: (val) {
                selectedCat = val;
              },
            ),
          ),
        ),
      );

      expect(find.text(AppConstants.dietAll), findsOneWidget);
      expect(find.text('مشويات'), findsOneWidget);
      expect(find.text('مقبلات'), findsOneWidget);
      expect(find.text('مشروبات'), findsOneWidget);

      await tester.tap(find.text('مشويات'));
      await tester.pump();

      expect(selectedCat, 'مشويات');
    });
  });
}
