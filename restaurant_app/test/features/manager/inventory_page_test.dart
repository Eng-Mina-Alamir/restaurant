import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:restaurant_app/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/inventory_page.dart';

void main() {
  group('InventoryPage and Layer Tests', () {
    testWidgets(
      'renders inventory items, summary chips, and opens add item dialog',
      (tester) async {
        final repository = InMemoryInventoryRepository([
          const InventoryItemEntity(
            id: 'inv-1',
            name: 'لحم بقري مفروم (أنجوس)',
            category: 'لحوم',
            currentStock: 18.5,
            unit: 'كغ',
            minThreshold: 8.0,
            costPerUnit: 55.0,
          ),
        ]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              inventoryRepositoryProvider.overrideWithValue(repository),
            ],
            child: const MaterialApp(home: InventoryPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('إدارة المخزون والتوريد'), findsOneWidget);
        expect(find.textContaining('منتهية'), findsWidgets);
        expect(find.textContaining('منخفضة'), findsWidgets);
        expect(find.text('لحم بقري مفروم (أنجوس)'), findsOneWidget);
        expect(find.text('إضافة صنف جديد'), findsOneWidget);

        // Tap FAB
        await tester.tap(find.text('إضافة صنف جديد'));
        await tester.pumpAndSettle();

        expect(find.text('إضافة صنف مخزون جديد'), findsOneWidget);
        expect(find.text('اسم الصنف *'), findsOneWidget);
      },
    );

    test('InventoryController CRUD operations work correctly', () async {
      final repository = InMemoryInventoryRepository();
      final controller = InventoryController(repository);
      await controller.load();

      final initial = controller.state.value!;
      expect(initial.isNotEmpty, isTrue);

      final added = await controller.addItem(
        name: 'صلصة طماطم إيطالية',
        category: 'صلصات',
        currentStock: 10,
        unit: 'علبة',
        minThreshold: 3,
        costPerUnit: 15,
      );
      expect(added, isTrue);
      expect(
        controller.state.value!.any((i) => i.name == 'صلصة طماطم إيطالية'),
        isTrue,
      );

      final target = controller.state.value!.firstWhere(
        (i) => i.name == 'صلصة طماطم إيطالية',
      );
      final restocked = await controller.restock(target.id, 5);
      expect(restocked, isTrue);
      final updated = controller.state.value!.firstWhere(
        (i) => i.id == target.id,
      );
      expect(updated.currentStock, 15);

      final deleted = await controller.deleteItem(target.id);
      expect(deleted, isTrue);
      expect(controller.state.value!.any((i) => i.id == target.id), isFalse);
    });
  });
}
