import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/table_management/data/repositories/in_memory_table_repository.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';

void main() {
  late InMemoryTableRepository repo;
  late TableController controller;

  setUp(() {
    repo = InMemoryTableRepository();
    controller = TableController(repo);
  });

  tearDown(() {
    controller.dispose();
  });

  group('TableController Unit Tests', () {
    test('initializes and loads tables from seed repository', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state.isNotEmpty, isTrue);
    });

    test('tableById returns table or null if not found', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final firstTable = controller.state.first;
      expect(controller.tableById(firstTable.id), isNotNull);
      expect(controller.tableById('non_existent_id'), isNull);
    });

    test('occupy updates status to occupied and sets orderId', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final first = controller.state.first;

      await controller.occupy(first.id, orderId: 'ORD-999');
      final updated = controller.tableById(first.id);

      expect(updated?.status, TableStatus.occupied);
      expect(updated?.currentOrderId, 'ORD-999');
    });

    test('release marks table available or needsCleaning', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final first = controller.state.first;

      await controller.occupy(first.id, orderId: 'ORD-999');
      await controller.release(first.id, needsCleaning: true);
      expect(controller.tableById(first.id)?.status, TableStatus.needsCleaning);
      expect(controller.tableById(first.id)?.currentOrderId, isNull);

      await controller.release(first.id, needsCleaning: false);
      expect(controller.tableById(first.id)?.status, TableStatus.available);
    });

    test('setReserved toggles reserved status', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final first = controller.state.first;

      await controller.setReserved(first.id, reserved: true);
      expect(controller.tableById(first.id)?.status, TableStatus.reserved);

      await controller.setReserved(first.id, reserved: false);
      expect(controller.tableById(first.id)?.status, TableStatus.available);
    });

    test('addTable, editTable and deleteTable CRUD actions', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final initialCount = controller.state.length;

      await controller.addTable(
        tableNumber: 99,
        capacity: 6,
        assignedWaiterId: 'waiter-1',
      );
      expect(controller.state.length, initialCount + 1);

      final added = controller.state.firstWhere((t) => t.tableNumber == 99);
      expect(added.capacity, 6);

      await controller.editTable(
        added.id,
        capacity: 8,
        assignedWaiterId: 'waiter-2',
      );
      final edited = controller.tableById(added.id);
      expect(edited?.capacity, 8);
      expect(edited?.assignedWaiterId, 'waiter-2');

      await controller.deleteTable(added.id);
      expect(controller.tableById(added.id), isNull);
      expect(controller.state.length, initialCount);
    });
  });
}
