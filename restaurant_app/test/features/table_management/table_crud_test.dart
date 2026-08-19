import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/table_management/data/repositories/in_memory_table_repository.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';

void main() {
  group('Table Repository CRUD Tests', () {
    late InMemoryTableRepository repository;

    setUp(() {
      repository = InMemoryTableRepository();
    });

    test('retrieves seeded tables', () async {
      final result = await repository.getTables();
      expect(result.isRight, isTrue);
      final tables = result.when(onLeft: (_) => null, onRight: (t) => t);
      expect(tables!.isNotEmpty, isTrue);
    });

    test('adds new table correctly', () async {
      const newTable = RestaurantTable(
        id: 't-new-10',
        tableNumber: 10,
        capacity: 8,
        status: TableStatus.available,
        assignedWaiterId: 'waiter-1',
      );

      final result = await repository.addTable(newTable);
      expect(result.isRight, isTrue);

      final allRes = await repository.getTables();
      final all = allRes.when(onLeft: (_) => null, onRight: (t) => t);
      expect(all!.any((t) => t.id == 't-new-10'), isTrue);
    });

    test('deletes table', () async {
      final allRes = await repository.getTables();
      final firstTable = allRes.when(onLeft: (_) => null, onRight: (t) => t)!.first;

      await repository.deleteTable(firstTable.id);

      final updatedRes = await repository.getTables();
      final exists = updatedRes.when(onLeft: (_) => null, onRight: (t) => t)!.any((t) => t.id == firstTable.id);
      expect(exists, isFalse);
    });
  });
}
