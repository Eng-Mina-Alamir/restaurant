import '../../../core/domain/enums.dart';
import '../domain/entities/restaurant_table.dart';

/// Static seed data for restaurant tables used by the offline flow.
abstract final class TableSeedData {
  TableSeedData._();

  static const String restaurantId = 'demo-restaurant-1';

  static const List<RestaurantTable> tables = <RestaurantTable>[
    RestaurantTable(
      id: 't1',
      tableNumber: 1,
      capacity: 2,
      location: 'تراس',
      status: TableStatus.available,
    ),
    RestaurantTable(
      id: 't2',
      tableNumber: 2,
      capacity: 4,
      location: 'صالة',
      status: TableStatus.available,
    ),
    RestaurantTable(
      id: 't3',
      tableNumber: 3,
      capacity: 4,
      location: 'صالة',
      status: TableStatus.occupied,
    ),
    RestaurantTable(
      id: 't4',
      tableNumber: 4,
      capacity: 6,
      location: 'حديقة',
      status: TableStatus.available,
    ),
    RestaurantTable(
      id: 't5',
      tableNumber: 5,
      capacity: 6,
      location: 'حديقة',
      status: TableStatus.reserved,
    ),
    RestaurantTable(
      id: 't6',
      tableNumber: 6,
      capacity: 8,
      location: 'قاعة',
      status: TableStatus.needsCleaning,
    ),
    RestaurantTable(
      id: 't7',
      tableNumber: 7,
      capacity: 2,
      location: 'تراس',
      status: TableStatus.available,
    ),
    RestaurantTable(
      id: 't8',
      tableNumber: 8,
      capacity: 4,
      location: 'صالة',
      status: TableStatus.occupied,
    ),
  ];

  static List<RestaurantTable> buildTables() =>
      List<RestaurantTable>.of(tables);
}
