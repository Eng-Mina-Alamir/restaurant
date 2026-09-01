import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/kds/presentation/widgets/kds_driver_assignment_sheet.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../../helpers/test_container.dart';

void main() {
  group('KdsDriverAssignmentSheet Widget Tests', () {
    testWidgets('renders available drivers and allows assignment', (tester) async {
      const item = MenuItem(
        id: 'b1',
        categoryId: 'cat-burger',
        name: 'برجر لحم بلدي',
        description: 'لحم مشوي طازج',
        price: 85.0,
      );

      final order = OrderEntity(
        id: 'ORD-7001',
        restaurantId: 'rest-1',
        orderType: OrderType.delivery,
        status: OrderStatus.preparing,
        deliveryAddress: 'المعادي - شارع 9',
        items: [
          OrderItem(
            menuItem: item,
            quantity: 2,
            selectedModifiers: const [],
            addedAt: DateTime.now(),
          ),
        ],
        subtotal: 170.0,
        taxAmount: 25.5,
        totalAmount: 195.5,
        createdAt: DateTime.now(),
      );

      final orderRepo = InMemoryOrderRepository();
      await orderRepo.createOrder(order);
      final deliveryRepo = InMemoryDeliveryRepository();

      final container = createTestContainer(
        additionalOverrides: [
          orderRepositoryProvider.overrideWithValue(orderRepo),
          deliveryRepositoryProvider.overrideWithValue(deliveryRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: KdsDriverAssignmentSheet(order: order),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & order details
      expect(find.text('اختيار مندوب التوصيل'), findsOneWidget);
      expect(find.textContaining('7001'), findsOneWidget);
      expect(find.text('المعادي - شارع 9'), findsOneWidget);

      // Verify Smart auto-assign card
      expect(find.text('⚡ تعيين تلقائي ذكي'), findsOneWidget);

      // Verify seeded drivers rendered
      expect(find.text('driver-demo'), findsOneWidget);

      // Tap on driver card
      await tester.tap(find.text('driver-demo'));
      await tester.pump();
    });
  });
}
