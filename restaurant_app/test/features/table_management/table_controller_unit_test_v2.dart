import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';
import 'package:restaurant_app/features/table_management/domain/repositories/table_repository.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';

class _FakeTableRepository implements TableRepository {
  final List<RestaurantTable> tables = [];

  @override
  Future<Either<Failure, List<RestaurantTable>>> getTables() async {
    return Right(List.unmodifiable(tables));
  }

  @override
  Future<Either<Failure, RestaurantTable>> addTable(RestaurantTable table) async {
    tables.add(table);
    return Right(table);
  }

  @override
  Future<Either<Failure, RestaurantTable>> updateTable(RestaurantTable table) async {
    final index = tables.indexWhere((t) => t.id == table.id);
    if (index != -1) {
      tables[index] = table;
    } else {
      tables.add(table);
    }
    return Right(table);
  }

  @override
  Future<Either<Failure, void>> deleteTable(String tableId) async {
    tables.removeWhere((t) => t.id == tableId);
    return const Right(null);
  }
}

void main() {
  group('TableController Unit Tests (v2)', () {
    late _FakeTableRepository repo;
    late RealtimeService realtime;
    late TableController controller;

    setUp(() async {
      repo = _FakeTableRepository();
      repo.tables.addAll([
        RestaurantTable(
          id: 'tbl-1',
          tableNumber: 1,
          capacity: 4,
          status: TableStatus.available,
          lastUpdated: DateTime.now(),
        ),
        RestaurantTable(
          id: 'tbl-2',
          tableNumber: 2,
          capacity: 6,
          status: TableStatus.available,
          lastUpdated: DateTime.now(),
        ),
      ]);

      realtime = RealtimeService();
      controller = TableController(repo, realtimeService: realtime);
      // Wait for initial load
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      controller.dispose();
      realtime.disconnect();
    });

    test('tableById finds table by id or returns null', () {
      expect(controller.tableById('tbl-1')?.tableNumber, 1);
      expect(controller.tableById('tbl-unknown'), isNull);
    });

    test('occupy links active order and sets status to occupied', () async {
      await controller.occupy('tbl-1', orderId: 'ORD-99');

      final table = controller.tableById('tbl-1');
      expect(table?.status, TableStatus.occupied);
      expect(table?.currentOrderId, 'ORD-99');
    });

    test('release clears order and marks available or needsCleaning', () async {
      await controller.occupy('tbl-1', orderId: 'ORD-99');

      await controller.release('tbl-1', needsCleaning: true);
      expect(controller.tableById('tbl-1')?.status, TableStatus.needsCleaning);
      expect(controller.tableById('tbl-1')?.currentOrderId, isNull);

      await controller.release('tbl-1', needsCleaning: false);
      expect(controller.tableById('tbl-1')?.status, TableStatus.available);
    });

    test('setReserved marks table reserved or available', () async {
      await controller.setReserved('tbl-2', reserved: true);
      expect(controller.tableById('tbl-2')?.status, TableStatus.reserved);

      await controller.setReserved('tbl-2', reserved: false);
      expect(controller.tableById('tbl-2')?.status, TableStatus.available);
    });

    test('addTable adds table and maintains sorted order by tableNumber', () async {
      await controller.addTable(tableNumber: 5, capacity: 8);

      expect(controller.state, hasLength(3));
      expect(controller.state.last.tableNumber, 5);
      expect(controller.state.last.capacity, 8);
    });

    test('editTable modifies properties', () async {
      await controller.editTable(
        'tbl-1',
        capacity: 10,
        assignedWaiterId: 'waiter-1',
      );

      final table = controller.tableById('tbl-1');
      expect(table?.capacity, 10);
      expect(table?.assignedWaiterId, 'waiter-1');
    });

    test('deleteTable removes table from state and repo', () async {
      await controller.deleteTable('tbl-1');

      expect(controller.tableById('tbl-1'), isNull);
      expect(controller.state, hasLength(1));
    });
  });
}
