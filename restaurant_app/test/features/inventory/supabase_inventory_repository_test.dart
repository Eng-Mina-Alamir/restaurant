import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/features/inventory/data/repositories/supabase_inventory_repository.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseInventoryRepository Tests', () {
    late SupabaseClient client;
    late SupabaseInventoryRepository repository;

    setUp(() {
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
      repository = SupabaseInventoryRepository(supabase: client);
    });

    const testItem = InventoryItemEntity(
      id: 'inv-test-001',
      name: 'أرز بسمتي فاخر',
      category: 'حبوب ومواد جافة',
      currentStock: 25.0,
      unit: 'كجم',
      minThreshold: 10.0,
      costPerUnit: 45.0,
    );

    test('InventoryItemEntity stock checks', () {
      expect(testItem.status, equals(StockStatus.sufficient));
      final lowStockItem = testItem.copyWith(currentStock: 5.0);
      expect(lowStockItem.status, equals(StockStatus.low));
    });

    test('getInventoryItems returns Either list or failure', () async {
      final result = await repository.getInventoryItems();
      expect(result, isNotNull);
    });
  });
}
