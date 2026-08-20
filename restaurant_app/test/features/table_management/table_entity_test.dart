import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';

void main() {
  group('RestaurantTable Entity Unit Tests', () {
    test('serialization round-trip preserves all fields', () {
      final now = DateTime(2026, 8, 19, 20, 0);
      final table = RestaurantTable(
        id: 'tbl-1',
        tableNumber: 1,
        capacity: 6,
        location: 'تراس النيل',
        status: TableStatus.occupied,
        currentOrderId: 'ORD-505',
        assignedWaiterId: 'waiter-1',
        lastUpdated: now,
      );

      final json = table.toJson();
      expect(json['id'], 'tbl-1');
      expect(json['tableNumber'], 1);
      expect(json['capacity'], 6);
      expect(json['location'], 'تراس النيل');
      expect(json['status'], 'occupied');
      expect(json['currentOrderId'], 'ORD-505');

      final reconstructed = RestaurantTable.fromJson(json);
      expect(reconstructed, equals(table));
    });

    test('default capacity and location are applied when omitted', () {
      const table = RestaurantTable(
        id: 'tbl-2',
        tableNumber: 2,
        status: TableStatus.available,
      );

      expect(table.capacity, 4);
      expect(table.location, 'صالة');
      expect(table.currentOrderId, isNull);
    });

    test('copyWith properly updates fields', () {
      const table = RestaurantTable(
        id: 'tbl-3',
        tableNumber: 3,
        status: TableStatus.available,
      );

      final occupied = table.copyWith(
        status: TableStatus.occupied,
        currentOrderId: 'ORD-999',
      );

      expect(occupied.status, TableStatus.occupied);
      expect(occupied.currentOrderId, 'ORD-999');
      expect(occupied.tableNumber, 3);
    });
  });
}
