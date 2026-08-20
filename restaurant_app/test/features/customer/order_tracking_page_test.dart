import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/customer/presentation/pages/order_tracking_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../../helpers/test_http_overrides.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('OrderTrackingPage Widget Tests', () {
    testWidgets('renders order details, status stepper and driver info', (tester) async {
      const burger = MenuItem(
        id: 'item-1',
        categoryId: 'cat-grill',
        name: 'كباب مشوي عالفحم',
        description: 'طازج ولذيذ',
        price: 95.0,
      );

      final order = OrderEntity(
        id: 'ORD-TRK-1',
        restaurantId: 'rest-1',
        tableId: null,
        customerId: 'CUST-1',
        orderType: OrderType.delivery,
        status: OrderStatus.preparing,
        items: [
          OrderItem(
            menuItem: burger,
            quantity: 2,
            selectedModifiers: const [],
            addedAt: DateTime.now(),
          ),
        ],
        subtotal: 190.0,
        taxAmount: 28.5,
        totalAmount: 218.5,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersControllerProvider.overrideWith(
              (ref) => OrdersControllerMock([order]),
            ),
          ],
          child: const MaterialApp(
            home: OrderTrackingPage(orderId: 'ORD-TRK-1'),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('تتبع الطلب'), findsOneWidget);
      expect(find.textContaining('حالة الطلب:'), findsOneWidget);
      expect(find.text('الكابتن طارق الدسوقي (طيار المحروسة)'), findsOneWidget);
      expect(find.text('2 أصناف'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);

      // Tap phone button and verify SnackBar
      await tester.tap(find.byIcon(Icons.phone));
      await tester.pump();
      expect(find.textContaining('جارٍ الاتصال بالكابتن طارق'), findsOneWidget);
    });
  });
}

class OrdersControllerMock extends StateNotifier<List<OrderEntity>>
    implements OrdersController {
  OrdersControllerMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
