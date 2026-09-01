import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/menu_engineering_item.dart';

void main() {
  group('Menu Engineering (F&B Matrix) Tests', () {
    test('Correctly computes menu engineering metrics and classifications', () {
      const starItem = MenuEngineeringItem(
        menuItemId: 'item-star',
        name: 'طاجن كوارع باللحم',
        category: 'main',
        sellingPrice: 200.0,
        foodCost: 60.0,
        salesCount: 80,
        grossMargin: 140.0,
        foodCostPercentage: 30.0,
        classification: MenuEngineeringCategory.star,
      );

      const dogItem = MenuEngineeringItem(
        menuItemId: 'item-dog',
        name: 'سلطة خضراء عادية',
        category: 'salads',
        sellingPrice: 30.0,
        foodCost: 20.0,
        salesCount: 5,
        grossMargin: 10.0,
        foodCostPercentage: 66.6,
        classification: MenuEngineeringCategory.dog,
      );

      expect(starItem.totalRevenue, equals(200.0 * 80));
      expect(starItem.totalProfit, equals(140.0 * 80));
      expect(starItem.classification, equals(MenuEngineeringCategory.star));
      expect(starItem.classification.titleAr, contains('Star'));

      expect(dogItem.totalRevenue, equals(150.0));
      expect(dogItem.totalProfit, equals(50.0));
      expect(dogItem.classification, equals(MenuEngineeringCategory.dog));
      expect(dogItem.classification.strategyAr, contains('استبدله'));
    });
  });
}
