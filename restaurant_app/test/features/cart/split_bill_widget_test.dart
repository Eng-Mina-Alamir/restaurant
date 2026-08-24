import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/cart/presentation/widgets/split_bill_sheet.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'c1',
    name: 'برجر',
    description: 'وصف',
    price: 50.0,
  );

  group('SplitBillSheet Widget Tests', () {
    testWidgets(
      'renders split bill sheet with person counter and calculated per-person amount',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final cartController = container.read(cartControllerProvider.notifier);
        cartController.addItem(const CartItem(menuItem: burger, quantity: 2));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: Scaffold(body: SplitBillSheet())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('تقسيم الفاتورة'), findsOneWidget);
        expect(find.text('عدد الأشخاص'), findsOneWidget);
        expect(find.text('المجموع الكلي'), findsOneWidget);
        expect(find.byKey(const ValueKey(2)), findsOneWidget); // Counter at 2
        expect(find.text('شخص 1'), findsOneWidget);
        expect(find.text('شخص 2'), findsOneWidget);

        // Increment persons
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey(3)), findsOneWidget); // Counter at 3
        expect(find.text('شخص 3'), findsOneWidget);
      },
    );
  });
}
