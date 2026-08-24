import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/reservations/domain/entities/reservation_entity.dart';
import 'package:restaurant_app/features/reservations/presentation/controllers/reservation_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import '../../helpers/test_container.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = createTestContainer();
    // Warm up both controllers
    container.read(tableControllerProvider.notifier);
    container.read(reservationControllerProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() {
    container.dispose();
  });

  group('ReservationController Unit Tests', () {
    test('initializes and loads seeded reservations', () async {
      final state = container.read(reservationControllerProvider);
      expect(state, isA<AsyncData<List<ReservationEntity>>>());
      expect(state.value!.isNotEmpty, isTrue);
    });

    test(
      'createReservation adds reservation and sets table reserved',
      () async {
        final controller = container.read(
          reservationControllerProvider.notifier,
        );
        final tables = container.read(tableControllerProvider);
        final table = tables.first;

        final success = await controller.createReservation(
          customerName: 'سارة',
          customerPhone: '0512345678',
          tableId: table.id,
          tableNumber: table.tableNumber,
          guestCount: 4,
          reservationTime: DateTime.now().add(const Duration(hours: 2)),
        );

        expect(success, isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final updatedTables = container.read(tableControllerProvider);
        expect(
          updatedTables.firstWhere((t) => t.id == table.id).status,
          TableStatus.reserved,
        );
      },
    );

    test('seatCustomer updates status to seated and occupies table', () async {
      final controller = container.read(reservationControllerProvider.notifier);
      final resList = container.read(reservationControllerProvider).value!;
      final res = resList.first;

      await controller.seatCustomer(res);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final updatedTables = container.read(tableControllerProvider);
      final table = updatedTables.firstWhere((t) => t.id == res.tableId);
      expect(table.status, TableStatus.occupied);
    });

    test('cancelReservation cancels reservation and frees table', () async {
      final controller = container.read(reservationControllerProvider.notifier);
      final resList = container.read(reservationControllerProvider).value!;
      final res = resList.first;

      // Reserve it first
      await container
          .read(tableControllerProvider.notifier)
          .setReserved(res.tableId, reserved: true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await controller.cancelReservation(res);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final updatedTables = container.read(tableControllerProvider);
      final table = updatedTables.firstWhere((t) => t.id == res.tableId);
      expect(table.status, TableStatus.available);
    });
  });
}
