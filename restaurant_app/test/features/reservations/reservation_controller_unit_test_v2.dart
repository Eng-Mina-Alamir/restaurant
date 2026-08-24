import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/reservations/domain/entities/reservation_entity.dart';
import 'package:restaurant_app/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:restaurant_app/features/reservations/presentation/controllers/reservation_controller.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';
import 'package:restaurant_app/features/table_management/domain/repositories/table_repository.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';

class _FakeReservationRepo implements ReservationRepository {
  final List<ReservationEntity> reservations = [];

  @override
  Future<Either<Failure, List<ReservationEntity>>> getReservations() async {
    return Right(List.unmodifiable(reservations));
  }

  @override
  Future<Either<Failure, ReservationEntity>> createReservation(
    ReservationEntity reservation,
  ) async {
    reservations.add(reservation);
    return Right(reservation);
  }

  @override
  Future<Either<Failure, ReservationEntity>> updateStatus(
    String id,
    ReservationStatus status,
  ) async {
    final index = reservations.indexWhere((r) => r.id == id);
    if (index != -1) {
      final updated = reservations[index].copyWith(status: status);
      reservations[index] = updated;
      return Right(updated);
    }
    return const Left(NotFoundFailure());
  }

  @override
  Future<Either<Failure, void>> cancelReservation(String id) async {
    await updateStatus(id, ReservationStatus.cancelled);
    return const Right(null);
  }
}

class _FakeTableRepo implements TableRepository {
  final List<RestaurantTable> tables = [];

  @override
  Future<Either<Failure, List<RestaurantTable>>> getTables() async =>
      Right(List.unmodifiable(tables));

  @override
  Future<Either<Failure, RestaurantTable>> addTable(
    RestaurantTable table,
  ) async {
    tables.add(table);
    return Right(table);
  }

  @override
  Future<Either<Failure, RestaurantTable>> updateTable(
    RestaurantTable table,
  ) async {
    final i = tables.indexWhere((t) => t.id == table.id);
    if (i != -1) tables[i] = table;
    return Right(table);
  }

  @override
  Future<Either<Failure, void>> deleteTable(String tableId) async =>
      const Right(null);
}

void main() {
  group('ReservationController Integration with TableController (v2)', () {
    late _FakeReservationRepo resRepo;
    late _FakeTableRepo tableRepo;
    late ProviderContainer container;

    setUp(() async {
      resRepo = _FakeReservationRepo();
      tableRepo = _FakeTableRepo();
      tableRepo.tables.add(
        RestaurantTable(
          id: 'tbl-3',
          tableNumber: 3,
          capacity: 4,
          status: TableStatus.available,
          lastUpdated: DateTime.now(),
        ),
      );

      container = ProviderContainer(
        overrides: [
          reservationRepositoryProvider.overrideWithValue(resRepo),
          tableRepositoryProvider.overrideWithValue(tableRepo),
        ],
      );

      container.read(tableControllerProvider);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'createReservation saves reservation and updates table to reserved',
      () async {
        final controller = container.read(
          reservationControllerProvider.notifier,
        );

        final success = await controller.createReservation(
          customerName: 'طارق',
          customerPhone: '01122334455',
          tableId: 'tbl-3',
          tableNumber: 3,
          guestCount: 2,
          reservationTime: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(success, isTrue);
        expect(resRepo.reservations, hasLength(1));

        final tables = container.read(tableControllerProvider);
        final table = tables.firstWhere((t) => t.id == 'tbl-3');
        expect(table.status, TableStatus.reserved);
      },
    );

    test(
      'seatCustomer updates reservation to seated and table to occupied',
      () async {
        final controller = container.read(
          reservationControllerProvider.notifier,
        );

        await controller.createReservation(
          customerName: 'طارق',
          customerPhone: '01122334455',
          tableId: 'tbl-3',
          tableNumber: 3,
          guestCount: 2,
          reservationTime: DateTime.now(),
        );

        final reservation = resRepo.reservations.first;
        await controller.seatCustomer(reservation);

        expect(resRepo.reservations.first.status, ReservationStatus.seated);

        final tables = container.read(tableControllerProvider);
        final table = tables.firstWhere((t) => t.id == 'tbl-3');
        expect(table.status, TableStatus.occupied);
        expect(table.currentOrderId, 'RES-SEATED');
      },
    );

    test(
      'cancelReservation sets status cancelled and releases table reservation',
      () async {
        final controller = container.read(
          reservationControllerProvider.notifier,
        );

        await controller.createReservation(
          customerName: 'طارق',
          customerPhone: '01122334455',
          tableId: 'tbl-3',
          tableNumber: 3,
          guestCount: 2,
          reservationTime: DateTime.now(),
        );

        final reservation = resRepo.reservations.first;
        await controller.cancelReservation(reservation);

        expect(resRepo.reservations.first.status, ReservationStatus.cancelled);

        final tables = container.read(tableControllerProvider);
        final table = tables.firstWhere((t) => t.id == 'tbl-3');
        expect(table.status, TableStatus.available);
      },
    );
  });
}
