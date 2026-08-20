import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/table_management/data/repositories/supabase_table_repository.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseTableRepository Unit Tests', () {
    late SupabaseClient client;
    late SupabaseTableRepository repository;

    setUp(() {
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
      repository = SupabaseTableRepository(client);
    });

    test('getTables gracefully falls back to seed table data when remote is offline/empty', () async {
      final result = await repository.getTables();

      expect(result.isRight, isTrue);
      result.when(
        onLeft: (_) => fail('Expected right tables'),
        onRight: (tables) {
          expect(tables, isNotEmpty);
          expect(tables.any((t) => t.tableNumber == 1), isTrue);
        },
      );
    });

    test('updateTable handles table update without crashing', () async {
      // Prime cache
      await repository.getTables();

      final updatedTable = RestaurantTable(
        id: 't1',
        tableNumber: 1,
        capacity: 4,
        status: TableStatus.occupied,
        currentOrderId: 'ORD-999',
        lastUpdated: DateTime.now(),
      );

      final result = await repository.updateTable(updatedTable);
      expect(result, isNotNull);
    });
  });
}
