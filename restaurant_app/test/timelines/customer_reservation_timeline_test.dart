import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/reservations/presentation/controllers/reservation_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import '../helpers/test_container.dart';

void main() {
  group('Timeline 3: Customer Table Reservation Journey Test', () {
    test('Reservation Timeline: Pick Time & Table -> Confirm Booking -> Table becomes Reserved -> Arrive & Seat -> Release', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      final tableNotifier = container.read(tableControllerProvider.notifier);
      await tableNotifier.addTable(tableNumber: 10, capacity: 4);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final tables = container.read(tableControllerProvider);
      expect(tables, isNotEmpty);
      final targetTable = tables.firstWhere((t) => t.tableNumber == 10);
      expect(targetTable.status, equals(TableStatus.available));

      // ── Step 1 & 2: Customer creates reservation for target table ──────────
      final reservationNotifier = container.read(reservationControllerProvider.notifier);
      final reservationTime = DateTime.now().add(const Duration(hours: 2));

      final success = await reservationNotifier.createReservation(
        customerName: 'فيصل العتيبي',
        customerPhone: '0501234567',
        tableId: targetTable.id,
        tableNumber: targetTable.tableNumber,
        guestCount: 4,
        reservationTime: reservationTime,
        notes: 'طاولة بجانب النافذة مع كرسي أطفال',
      );

      expect(success, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // ── Step 3: Verify table status is now reserved ────────────────────────
      var reservedTable = container.read(tableControllerProvider).firstWhere((t) => t.id == targetTable.id);
      expect(reservedTable.status, equals(TableStatus.reserved));

      // ── Step 4: Customer arrives at the restaurant and is seated ───────────
      await tableNotifier.occupy(targetTable.id, orderId: 'ORD-RES-${targetTable.id}');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      var seatedTable = container.read(tableControllerProvider).firstWhere((t) => t.id == targetTable.id);
      expect(seatedTable.status, equals(TableStatus.occupied));
      expect(seatedTable.currentOrderId, isNotNull);

      // ── Step 5: Meal completed -> Table is marked for cleaning & released ───
      await tableNotifier.release(targetTable.id, needsCleaning: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      var releasedTable = container.read(tableControllerProvider).firstWhere((t) => t.id == targetTable.id);
      expect(releasedTable.status, equals(TableStatus.needsCleaning));

      await tableNotifier.release(targetTable.id, needsCleaning: false);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      releasedTable = container.read(tableControllerProvider).firstWhere((t) => t.id == targetTable.id);
      expect(releasedTable.status, equals(TableStatus.available));
    });
  });
}
