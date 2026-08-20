import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/reservations/presentation/controllers/reservation_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';

void main() {
  test('Reservation & Table Lifecycle Integration Flow', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final tableController = container.read(tableControllerProvider.notifier);
    final resController = container.read(reservationControllerProvider.notifier);

    await Future<void>.delayed(const Duration(milliseconds: 20));

    final tables = container.read(tableControllerProvider);
    final targetTable = tables.first;
    expect(targetTable.status, TableStatus.available);

    // Step 1: Customer creates reservation for table
    final created = await resController.createReservation(
      customerName: 'عبدالله السبيعي',
      customerPhone: '0551122334',
      tableId: targetTable.id,
      tableNumber: targetTable.tableNumber,
      guestCount: 2,
      reservationTime: DateTime.now().add(const Duration(hours: 3)),
      notes: 'طاولة بجانب النافذة',
    );
    expect(created, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Table is now reserved
    final reservedTable = container.read(tableControllerProvider).firstWhere((t) => t.id == targetTable.id);
    expect(reservedTable.status, TableStatus.reserved);

    // Step 2: Customer arrives -> Seat customer
    final reservations = container.read(reservationControllerProvider).value!;
    final myRes = reservations.firstWhere((r) => r.customerName == 'عبدالله السبيعي');

    await resController.seatCustomer(myRes);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Table is now occupied
    final occupiedTable = container.read(tableControllerProvider).firstWhere((t) => t.id == targetTable.id);
    expect(occupiedTable.status, TableStatus.occupied);
    expect(occupiedTable.currentOrderId, isNotNull);

    // Step 3: Customer finishes and leaves -> Table is released for cleaning
    await tableController.release(targetTable.id, needsCleaning: true);
    final cleaningTable = container.read(tableControllerProvider).firstWhere((t) => t.id == targetTable.id);
    expect(cleaningTable.status, TableStatus.needsCleaning);

    // Step 4: Table cleaned and marked available
    await tableController.release(targetTable.id, needsCleaning: false);
    final availableTable = container.read(tableControllerProvider).firstWhere((t) => t.id == targetTable.id);
    expect(availableTable.status, TableStatus.available);
  });
}
