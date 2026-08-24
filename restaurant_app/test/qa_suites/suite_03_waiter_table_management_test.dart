import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import 'helpers/qa_test_helpers.dart';

void main() {
  group('Suite 3: Waiter & Table Management (تجربة النادل وإدارة الطاولات)', () {
    const sampleItem1 = MenuItem(
      id: 'waiter-item-1',
      categoryId: 'المشويات',
      name: 'كباب مشوي',
      description: 'كباب لحم مشوي على الفحم',
      price: 85.0,
    );

    const sampleItem2 = MenuItem(
      id: 'waiter-item-2',
      categoryId: 'المشروبات',
      name: 'شاي مثلج',
      description: 'شاي مثلج بنكهة الليمون والنعناع',
      price: 15.0,
    );

    // -------------------------------------------------------------
    // TC-WAIT-01: Table Map & Status Indicators
    // -------------------------------------------------------------
    test(
      'TC-WAIT-01: Table map displays tables and correctly recognizes all TableStatus states',
      () {
        final container = createQaContainer();
        addTearDown(container.dispose);

        final tables = container.read(tableControllerProvider);
        expect(tables, isNotEmpty);

        // Verify TableStatus attributes
        for (final table in tables) {
          expect(table.tableNumber, greaterThan(0));
          expect(table.capacity, greaterThan(0));
          expect([
            TableStatus.available,
            TableStatus.occupied,
            TableStatus.reserved,
            TableStatus.needsCleaning,
          ], contains(table.status));
        }
      },
    );

    // -------------------------------------------------------------
    // TC-WAIT-02: Open New Order For Table
    // -------------------------------------------------------------
    test(
      'TC-WAIT-02: Waiter opens order for table, sets items and marks table occupied',
      () async {
        final container = createQaContainer(
          extraCheckoutItems: [sampleItem1, sampleItem2],
        );
        addTearDown(container.dispose);
        await primeMenuForCheckout(container);

        final cartNotifier = container.read(cartControllerProvider.notifier);
        cartNotifier.addItem(
          const CartItem(menuItem: sampleItem1, quantity: 2),
        );

        final ordersNotifier = container.read(
          ordersControllerProvider.notifier,
        );
        final tableOrder = await ordersNotifier.placeOrderForTable('t1');

        expect(tableOrder, isNotNull);
        expect(tableOrder?.tableId, 't1');
        expect(tableOrder?.orderType, OrderType.dineIn);

        // Occupy table
        final tableNotifier = container.read(tableControllerProvider.notifier);
        await tableNotifier.occupy('t1', orderId: tableOrder!.id);

        final updatedTable = container
            .read(tableControllerProvider)
            .firstWhere((t) => t.id == 't1');
        expect(updatedTable.status, TableStatus.occupied);
        expect(updatedTable.currentOrderId, tableOrder.id);
      },
    );

    // -------------------------------------------------------------
    // TC-WAIT-03: Add Items to Open Order
    // -------------------------------------------------------------
    test(
      'TC-WAIT-03: Waiter appends extra items to existing table order',
      () async {
        final container = createQaContainer(
          extraCheckoutItems: [sampleItem1, sampleItem2],
        );
        addTearDown(container.dispose);
        await primeMenuForCheckout(container);

        final cartNotifier = container.read(cartControllerProvider.notifier);
        final ordersNotifier = container.read(
          ordersControllerProvider.notifier,
        );
        final tableNotifier = container.read(tableControllerProvider.notifier);

        // Initial order
        cartNotifier.addItem(
          const CartItem(menuItem: sampleItem1, quantity: 1),
        );
        final initialOrder = await ordersNotifier.placeOrderForTable('t2');
        await tableNotifier.occupy('t2', orderId: initialOrder!.id);

        // Add extra drink item
        cartNotifier.addItem(
          const CartItem(menuItem: sampleItem2, quantity: 2),
        );
        final additionalOrder = await ordersNotifier.placeOrderForTable('t2');

        expect(additionalOrder, isNotNull);
        expect(additionalOrder?.tableId, 't2');
        expect(additionalOrder?.items.first.menuItem.name, sampleItem2.name);

        final allOrders = container
            .read(ordersControllerProvider)
            .where((o) => o.tableId == 't2')
            .toList();
        expect(allOrders.length, greaterThanOrEqualTo(2));
      },
    );

    // -------------------------------------------------------------
    // TC-WAIT-04: Transfer Table
    // -------------------------------------------------------------
    test(
      'TC-WAIT-04: Waiter transfers active order from Table A to Table B',
      () async {
        final container = createQaContainer();
        addTearDown(container.dispose);

        final tableNotifier = container.read(tableControllerProvider.notifier);

        // Occupy Table 1
        await tableNotifier.occupy('t1', orderId: 'ORD-TRANSFER-999');
        var t1 = container
            .read(tableControllerProvider)
            .firstWhere((t) => t.id == 't1');
        expect(t1.status, TableStatus.occupied);

        // Transfer: Free Table 1 & Occupy Table 3
        await tableNotifier.release('t1');
        await tableNotifier.occupy('t3', orderId: 'ORD-TRANSFER-999');

        t1 = container
            .read(tableControllerProvider)
            .firstWhere((t) => t.id == 't1');
        final t3 = container
            .read(tableControllerProvider)
            .firstWhere((t) => t.id == 't3');

        expect(t1.status, TableStatus.available);
        expect(t1.currentOrderId, isNull);
        expect(t3.status, TableStatus.occupied);
        expect(t3.currentOrderId, 'ORD-TRANSFER-999');
      },
    );

    // -------------------------------------------------------------
    // TC-WAIT-05: Settle Bill & Release Table
    // -------------------------------------------------------------
    test(
      'TC-WAIT-05: Settle bill and release table to cleaning state then available',
      () async {
        final container = createQaContainer();
        addTearDown(container.dispose);

        final tableNotifier = container.read(tableControllerProvider.notifier);

        await tableNotifier.occupy('t4', orderId: 'ORD-BILL-101');
        var t4 = container
            .read(tableControllerProvider)
            .firstWhere((t) => t.id == 't4');
        expect(t4.status, TableStatus.occupied);

        // Settle bill -> Table needs cleaning
        await tableNotifier.release('t4', needsCleaning: true);
        t4 = container
            .read(tableControllerProvider)
            .firstWhere((t) => t.id == 't4');
        expect(t4.status, TableStatus.needsCleaning);

        // Table cleaned -> Available
        await tableNotifier.release('t4', needsCleaning: false);
        t4 = container
            .read(tableControllerProvider)
            .firstWhere((t) => t.id == 't4');
        expect(t4.status, TableStatus.available);
      },
    );
  });
}
