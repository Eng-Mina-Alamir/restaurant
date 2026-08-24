import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/reservations/domain/entities/reservation_entity.dart';
import 'package:restaurant_app/features/reservations/presentation/controllers/reservation_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import '../helpers/test_container.dart';

void main() {
  group('Table and Reservation Combined Flow Integration Test', () {
    test(
      'full flow: reservation -> table reserved -> seat customer -> dine-in order -> release table',
      () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        await primeMenuForCheckout(container);

        final tableController = container.read(
          tableControllerProvider.notifier,
        );
        final reservationController = container.read(
          reservationControllerProvider.notifier,
        );
        final cartController = container.read(cartControllerProvider.notifier);
        final ordersController = container.read(
          ordersControllerProvider.notifier,
        );
        final resRepo = container.read(reservationRepositoryProvider);

        // 1. Add a table
        await tableController.addTable(tableNumber: 10, capacity: 4);
        final tables = container.read(tableControllerProvider);
        final table = tables.firstWhere((t) => t.tableNumber == 10);
        expect(table.status, TableStatus.available);

        // 2. Create reservation for this table
        final reservationCreated = await reservationController
            .createReservation(
              customerName: 'أحمد محمود',
              customerPhone: '0501234567',
              tableId: table.id,
              tableNumber: table.tableNumber,
              guestCount: 3,
              reservationTime: DateTime.now().add(const Duration(hours: 2)),
            );
        expect(reservationCreated, isTrue);

        // Table should now be marked as reserved
        final tablesAfterRes = container.read(tableControllerProvider);
        expect(
          tablesAfterRes.firstWhere((t) => t.id == table.id).status,
          TableStatus.reserved,
        );

        // 3. Customer arrives -> Seat customer
        final allRes = (await resRepo.getReservations()).when(
          onLeft: (_) => <ReservationEntity>[],
          onRight: (list) => list,
        );
        final customerRes = allRes.firstWhere((r) => r.tableId == table.id);
        await reservationController.seatCustomer(customerRes);

        // Table should now be marked as occupied
        final tablesAfterSeat = container.read(tableControllerProvider);
        expect(
          tablesAfterSeat.firstWhere((t) => t.id == table.id).status,
          TableStatus.occupied,
        );

        // 4. Place dine-in order for the table
        final menuItem = MenuSeedData.items.first;
        cartController.addItem(CartItem(menuItem: menuItem, quantity: 2));
        final order = await ordersController.placeOrderForTable(table.id);
        expect(order, isNotNull);
        expect(order!.orderType, OrderType.dineIn);
        expect(order.tableId, table.id);

        // 5. Order is completed & table released
        await ordersController.updateStatus(order.id, OrderStatus.completed);
        await tableController.release(table.id);

        final tablesAfterDone = container.read(tableControllerProvider);
        expect(
          tablesAfterDone.firstWhere((t) => t.id == table.id).status,
          TableStatus.available,
        );
      },
    );
  });
}
