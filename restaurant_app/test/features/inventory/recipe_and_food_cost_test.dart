import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:restaurant_app/features/inventory/domain/entities/recipe_item_entity.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  group('Recipe & Food Cost (BOM) Calculation Tests', () {
    test('Calculates total food cost and margin correctly for a recipe', () {
      const recipe = MenuItemRecipeEntity(
        menuItemId: 'item-burger',
        menuItemName: 'برجر لحم بلدي فاخر',
        menuItemPrice: 150.0,
        ingredients: [
          RecipeIngredientEntity(
            inventoryItemId: 'inv-beef',
            inventoryItemName: 'لحم أنجوس مفروم',
            quantity: 0.2, // 200 grams
            unit: 'كغ',
            costPerUnit: 200.0, // 200 EGP per kg -> 40 EGP
          ),
          RecipeIngredientEntity(
            inventoryItemId: 'inv-bun',
            inventoryItemName: 'خبز بريوش',
            quantity: 1.0,
            unit: 'قطعة',
            costPerUnit: 5.0, // 5 EGP
          ),
          RecipeIngredientEntity(
            inventoryItemId: 'inv-cheese',
            inventoryItemName: 'جبنة شيدر',
            quantity: 0.05,
            unit: 'كغ',
            costPerUnit: 100.0, // 5 EGP
          ),
        ],
      );

      // Total Cost = 40 + 5 + 5 = 50 EGP
      expect(recipe.totalFoodCost, equals(50.0));
      // Gross Margin = 150 - 50 = 100 EGP
      expect(recipe.grossMargin, equals(100.0));
      // Food Cost Percentage = (50 / 150) * 100 = 33.33%
      expect(recipe.foodCostPercentage, closeTo(33.33, 0.01));
      expect(recipe.costHealthLabel, contains('ربحية مقبولة'));
    });

    test('Deducts stock automatically according to defined recipe ingredients', () async {
      final initialInventory = [
        const InventoryItemEntity(
          id: 'inv-beef',
          name: 'لحم أنجوس مفروم',
          category: 'لحوم',
          currentStock: 10.0, // 10 kg
          unit: 'كغ',
          minThreshold: 2.0,
          costPerUnit: 200.0,
        ),
        const InventoryItemEntity(
          id: 'inv-bun',
          name: 'خبز بريوش',
          category: 'مخبوزات',
          currentStock: 50.0, // 50 buns
          unit: 'قطعة',
          minThreshold: 10.0,
          costPerUnit: 5.0,
        ),
      ];

      final recipes = [
        const MenuItemRecipeEntity(
          menuItemId: 'item-burger',
          menuItemName: 'برجر لحم بلدي فاخر',
          menuItemPrice: 150.0,
          ingredients: [
            RecipeIngredientEntity(
              inventoryItemId: 'inv-beef',
              inventoryItemName: 'لحم أنجوس مفروم',
              quantity: 0.25, // 250g
              unit: 'كغ',
              costPerUnit: 200.0,
            ),
            RecipeIngredientEntity(
              inventoryItemId: 'inv-bun',
              inventoryItemName: 'خبز بريوش',
              quantity: 1.0,
              unit: 'قطعة',
              costPerUnit: 5.0,
            ),
          ],
        ),
      ];

      final repo = InMemoryInventoryRepository(initialInventory, recipes, []);

      final testOrder = OrderEntity(
        id: 'order-101',
        restaurantId: '1e08b47c-15be-4604-a913-431af7fbd54f',
        orderType: OrderType.dineIn,
        status: OrderStatus.completed,
        subtotal: 300.0,
        taxAmount: 0.0,
        discountAmount: 0.0,
        totalAmount: 300.0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime.now(),
        items: [
          OrderItem(
            menuItem: const MenuItem(
              id: 'item-burger',
              name: 'برجر لحم بلدي فاخر',
              description: '',
              price: 150.0,
              categoryId: 'burgers',
              isAvailable: true,
            ),
            quantity: 2, // 2 burgers ordered
            itemTotal: 300.0,
            addedAt: DateTime.now(),
          ),
        ],
      );

      // Perform deduction
      final deductResult = await repo.deductStockForOrder(testOrder);
      expect(deductResult.isRight, isTrue);

      // Verify inventory was deducted:
      // Beef: 10.0 - (0.25 * 2) = 9.5 kg
      // Buns: 50.0 - (1.0 * 2) = 48.0 buns
      final itemsResult = await repo.getInventoryItems();
      final updatedItems = itemsResult.when(
        onLeft: (_) => <InventoryItemEntity>[],
        onRight: (v) => v,
      );

      final beef = updatedItems.firstWhere((i) => i.id == 'inv-beef');
      final bun = updatedItems.firstWhere((i) => i.id == 'inv-bun');

      expect(beef.currentStock, closeTo(9.5, 0.001));
      expect(bun.currentStock, closeTo(48.0, 0.001));
    });
  });
}
