import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/customer/domain/entities/customer_dietary_entity.dart';
import 'package:restaurant_app/features/customer/domain/services/allergen_safety_service.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  late AllergenSafetyService service;

  setUp(() {
    service = const AllergenSafetyService();
  });

  group('AllergenSafetyService Tests', () {
    test('getNutritionalFactsForItem correctly infers allergens and macros', () {
      final factsBurger = service.getNutritionalFactsForItem('1', 'Double Cheeseburger Pizza');
      expect(factsBurger.allergens.contains(AllergenType.dairy), true);
      expect(factsBurger.allergens.contains(AllergenType.gluten), true);
      expect(factsBurger.calories, greaterThan(300));

      final factsFish = service.getNutritionalFactsForItem('2', 'Fried Seafood Shrimp Platter');
      expect(factsFish.allergens.contains(AllergenType.seafood), true);

      final factsSalad = service.getNutritionalFactsForItem('3', 'Green Garden Salad');
      expect(factsSalad.calories, lessThan(300));
    });

    test('detectAllergenConflicts alerts matching allergens', () {
      const profile = CustomerDietaryProfile(
        allergens: [AllergenType.dairy, AllergenType.peanuts],
      );

      final conflicts = service.detectAllergenConflicts(
        itemName: 'Cheeseburger',
        profile: profile,
      );

      expect(conflicts.contains(AllergenType.dairy), true);
      expect(conflicts.contains(AllergenType.peanuts), false);
    });

    test('filterMenuItems filters out conflicting allergens and matches dietary goal', () {
      const item1 = MenuItem(
        id: '1',
        name: 'Classic Burger with Cheese',
        description: 'Juicy beef patty with cheddar cheese',
        price: 120.0,
        categoryId: 'cat-1',
        imageUrl: '',
        isVegetarian: false,
      );

      const item2 = MenuItem(
        id: '2',
        name: 'Fresh Garden Salad',
        description: 'Crisp greens and vinaigrette',
        price: 50.0,
        categoryId: 'cat-2',
        imageUrl: '',
        isVegetarian: true,
      );

      final items = [item1, item2];

      // Exclude dairy
      final dairyFree = service.filterMenuItems(
        items: items,
        goal: DietaryGoal.all,
        excludedAllergens: [AllergenType.dairy],
      );

      expect(dairyFree.length, 1);
      expect(dairyFree.first.name, 'Fresh Garden Salad');

      // Vegan goal
      final veganList = service.filterMenuItems(
        items: items,
        goal: DietaryGoal.vegan,
        excludedAllergens: [],
      );
      expect(veganList.length, 1);
      expect(veganList.first.name, 'Fresh Garden Salad');
    });
  });
}
