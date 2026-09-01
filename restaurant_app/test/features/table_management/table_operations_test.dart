import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/table_management/data/repositories/in_memory_table_repository.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';
import 'package:restaurant_app/features/table_management/domain/services/table_operation_service.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';

void main() {
  group('Table Operations & Validation Tests', () {
    late RestaurantTable occupiedSource;
    late RestaurantTable availableTarget;
    late RestaurantTable dirtyTable;

    setUp(() {
      occupiedSource = RestaurantTable(
        id: 't-1',
        tableNumber: 1,
        capacity: 4,
        status: TableStatus.occupied,
        currentOrderId: 'ORD-555',
        lastUpdated: DateTime.now(),
      );

      availableTarget = RestaurantTable(
        id: 't-2',
        tableNumber: 2,
        capacity: 6,
        status: TableStatus.available,
        lastUpdated: DateTime.now(),
      );

      dirtyTable = RestaurantTable(
        id: 't-3',
        tableNumber: 3,
        capacity: 4,
        status: TableStatus.needsCleaning,
        lastUpdated: DateTime.now(),
      );
    });

    test('validateTransfer approves valid table transfer', () {
      final (isValid, errorReason) = TableOperationService.validateTransfer(
        sourceTable: occupiedSource,
        targetTable: availableTarget,
        currentGuestCount: 3,
      );

      expect(isValid, isTrue);
      expect(errorReason, isNull);
    });

    test('validateTransfer rejects transfer if target table needs cleaning', () {
      final (isValid, errorReason) = TableOperationService.validateTransfer(
        sourceTable: occupiedSource,
        targetTable: dirtyTable,
        currentGuestCount: 3,
      );

      expect(isValid, isFalse);
      expect(errorReason, contains('تنظيف'));
    });

    test('validateTransfer rejects transfer if target table capacity is too small', () {
      final smallTable = RestaurantTable(
        id: 't-4',
        tableNumber: 4,
        capacity: 2,
        status: TableStatus.available,
        lastUpdated: DateTime.now(),
      );

      final (isValid, errorReason) = TableOperationService.validateTransfer(
        sourceTable: occupiedSource,
        targetTable: smallTable,
        currentGuestCount: 4,
      );

      expect(isValid, isFalse);
      expect(errorReason, contains('سعة'));
    });

    test('TableController transferTable moves order and updates table statuses', () async {
      final repo = InMemoryTableRepository(
        seed: [occupiedSource, availableTarget],
      );
      final controller = TableController(repo);
      await Future<void>.delayed(const Duration(milliseconds: 15));

      final success = await controller.transferTable('t-1', 't-2');
      expect(success, isTrue);

      final updatedSource = controller.tableById('t-1')!;
      final updatedTarget = controller.tableById('t-2')!;

      expect(updatedSource.status, TableStatus.needsCleaning);
      expect(updatedSource.currentOrderId, isNull);

      expect(updatedTarget.status, TableStatus.occupied);
      expect(updatedTarget.currentOrderId, 'ORD-555');
    });

    test('TableController mergeTables links secondary tables to primary order', () async {
      final primary = RestaurantTable(
        id: 'tp',
        tableNumber: 10,
        capacity: 4,
        status: TableStatus.available,
        lastUpdated: DateTime.now(),
      );

      final sec1 = RestaurantTable(
        id: 'ts1',
        tableNumber: 11,
        capacity: 4,
        status: TableStatus.available,
        lastUpdated: DateTime.now(),
      );

      final repo = InMemoryTableRepository(seed: [primary, sec1]);
      final controller = TableController(repo);
      await Future<void>.delayed(const Duration(milliseconds: 15));

      final success = await controller.mergeTables('tp', ['ts1']);
      expect(success, isTrue);

      final updatedPrimary = controller.tableById('tp')!;
      final updatedSec1 = controller.tableById('ts1')!;

      expect(updatedPrimary.status, TableStatus.occupied);
      expect(updatedSec1.status, TableStatus.occupied);
      expect(updatedPrimary.currentOrderId, updatedSec1.currentOrderId);
    });

    test('calculateTableUrgency flags service requests as level 2 priority', () {
      final (level, desc) = TableOperationService.calculateTableUrgency(
        table: occupiedSource,
        orderCreatedAt: DateTime.now(),
        hasServiceRequest: true,
        isBillRequested: false,
      );

      expect(level, 2);
      expect(desc, contains('طلب خدمة'));
    });
  });
}
