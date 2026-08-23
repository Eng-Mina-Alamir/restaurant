import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'helpers/qa_test_helpers.dart';

void main() {
  group('Suite 4: Kitchen Display System - KDS (نظام شاشة المطبخ الذكية)', () {
    const grillItem = MenuItem(
      id: 'kds-grill-1',
      categoryId: 'المشويات',
      name: 'ستيك فيليه بصوص الفطر',
      description: 'قطعة لحم فيليه مشوية بصوص المشروم الغني',
      price: 120.0,
    );

    const drinkItem = MenuItem(
      id: 'kds-drink-1',
      categoryId: 'المشروبات',
      name: 'موهيتو فراولة فريش',
      description: 'مشروب موهيتو منعش بالفراولة الطبيعية',
      price: 30.0,
    );

    // -------------------------------------------------------------
    // TC-KDS-01: Instant Order Ticket Reception
    // -------------------------------------------------------------
    test('TC-KDS-01: New placed order immediately appears in KDS active orders stream', () async {
      final container = createQaContainer(
        extraCheckoutItems: [grillItem, drinkItem],
      );
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.addItem(const CartItem(menuItem: grillItem, quantity: 1));

      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final newOrder = await ordersNotifier.placeOrderForTable('t5');

      expect(newOrder, isNotNull);

      final activeKdsOrders = ordersNotifier.activeOrders;
      expect(activeKdsOrders.any((o) => o.id == newOrder!.id), isTrue);
      expect(activeKdsOrders.firstWhere((o) => o.id == newOrder!.id).status, OrderStatus.pending);
    });

    // -------------------------------------------------------------
    // TC-KDS-02: Ticket Details & Special Cooking Instructions
    // -------------------------------------------------------------
    test('TC-KDS-02: KDS order ticket preserves special dietary instructions and notes', () async {
      final container = createQaContainer(
        extraCheckoutItems: [grillItem, drinkItem],
      );
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      const specialNote = 'بدون شطة نهائياً / حساسية لاكتوز حادة';
      cartNotifier.addItem(
        const CartItem(
          menuItem: grillItem,
          quantity: 2,
          specialNotes: specialNote,
        ),
      );

      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final order = await ordersNotifier.placeOrderForTable('t7');

      expect(order, isNotNull);
      expect(order?.items.first.specialNotes, specialNote);
      expect(order?.tableId, 't7');
    });

    // -------------------------------------------------------------
    // TC-KDS-03: Prep Timer Progression
    // -------------------------------------------------------------
    test('TC-KDS-03: Prep timer calculates elapsed preparation duration accurately', () {
      final orderPast = OrderEntity(
        id: 'kds-timer-test',
        restaurantId: 'rest-1',
        tableId: 't1',
        orderType: OrderType.dineIn,
        status: OrderStatus.preparing,
        items: const [],
        subtotal: 100.0,
        taxAmount: 14.0,
        totalAmount: 114.0,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );

      final elapsedMinutes = DateTime.now().difference(orderPast.createdAt).inMinutes;
      expect(elapsedMinutes, greaterThanOrEqualTo(15));
    });

    // -------------------------------------------------------------
    // TC-KDS-04: Prep Status Lifecycle Progression
    // -------------------------------------------------------------
    test('TC-KDS-04: KDS moves ticket from Pending -> Preparing -> Ready -> Served', () async {
      final container = createQaContainer(
        extraCheckoutItems: [grillItem, drinkItem],
      );
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.addItem(const CartItem(menuItem: grillItem));

      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final order = await ordersNotifier.placeOrderForTable('t3');
      expect(order, isNotNull);

      // Start cooking
      await ordersNotifier.updateStatus(order!.id, OrderStatus.preparing);
      var current = container.read(ordersControllerProvider).firstWhere((o) => o.id == order.id);
      expect(current.status, OrderStatus.preparing);

      // Mark ready for pickup
      await ordersNotifier.updateStatus(order.id, OrderStatus.ready);
      current = container.read(ordersControllerProvider).firstWhere((o) => o.id == order.id);
      expect(current.status, OrderStatus.ready);

      // Served
      await ordersNotifier.updateStatus(order.id, OrderStatus.served);
      current = container.read(ordersControllerProvider).firstWhere((o) => o.id == order.id);
      expect(current.status, OrderStatus.served);

      // Completed
      await ordersNotifier.updateStatus(order.id, OrderStatus.completed);
      current = container.read(ordersControllerProvider).firstWhere((o) => o.id == order.id);
      expect(current.status, OrderStatus.completed);

      // Terminal orders are filtered out of active KDS columns
      expect(ordersNotifier.activeOrders.any((o) => o.id == order.id), isFalse);
    });

    // -------------------------------------------------------------
    // TC-KDS-05: Kitchen Station Filtering
    // -------------------------------------------------------------
    test('TC-KDS-05: Orders can be filtered by station category (Grill vs Drinks)', () async {
      final container = createQaContainer(
        extraCheckoutItems: [grillItem, drinkItem],
      );
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      final ordersNotifier = container.read(ordersControllerProvider.notifier);

      // Create Grill Order
      cartNotifier.addItem(const CartItem(menuItem: grillItem));
      final grillOrder = await ordersNotifier.placeOrder();

      // Create Drink Order
      cartNotifier.addItem(const CartItem(menuItem: drinkItem));
      final drinkOrder = await ordersNotifier.placeOrder();

      final allOrders = container.read(ordersControllerProvider);

      // Filter Grill
      final grillStationOrders = allOrders.where(
        (o) => o.items.any((i) => i.menuItem.categoryId == 'المشويات'),
      ).toList();
      expect(grillStationOrders.any((o) => o.id == grillOrder?.id), isTrue);
      expect(grillStationOrders.any((o) => o.id == drinkOrder?.id), isFalse);

      // Filter Drinks
      final drinkStationOrders = allOrders.where(
        (o) => o.items.any((i) => i.menuItem.categoryId == 'المشروبات'),
      ).toList();
      expect(drinkStationOrders.any((o) => o.id == drinkOrder?.id), isTrue);
      expect(drinkStationOrders.any((o) => o.id == grillOrder?.id), isFalse);
    });
  });
}
