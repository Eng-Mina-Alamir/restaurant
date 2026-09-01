import '../../../menu/domain/entities/menu_item.dart';
import '../entities/customer_dietary_entity.dart';

/// Domain service for calculating food safety, allergen matching, and nutritional facts.
class AllergenSafetyService {
  const AllergenSafetyService();

  /// Infers mock/seed nutritional facts and allergen contents for a menu item.
  NutritionalFacts getNutritionalFactsForItem(String itemId, String itemName) {
    final lower = itemName.toLowerCase();
    final List<AllergenType> allergens = [];

    // Heuristics based on common ingredients
    if (lower.contains('برجر') || lower.contains('burger') || lower.contains('جبن') || lower.contains('cheese') || lower.contains('بيتزا') || lower.contains('pizza')) {
      allergens.add(AllergenType.dairy);
      allergens.add(AllergenType.gluten);
    }
    if (lower.contains('سمك') || lower.contains('جمبري') || lower.contains('seafood') || lower.contains('fish') || lower.contains('shrimp')) {
      allergens.add(AllergenType.seafood);
    }
    if (lower.contains('مكسرات') || lower.contains('نوتيل') || lower.contains('nut') || lower.contains('لوز') || lower.contains('فستق')) {
      allergens.add(AllergenType.treeNuts);
    }
    if (lower.contains('فول سوداني') || lower.contains('peanut') || lower.contains('بينت')) {
      allergens.add(AllergenType.peanuts);
    }
    if (lower.contains('بيض') || lower.contains('كيك') || lower.contains('وافل') || lower.contains('egg')) {
      allergens.add(AllergenType.eggs);
    }
    if (lower.contains('طحينة') || lower.contains('سمسم') || lower.contains('sesame')) {
      allergens.add(AllergenType.sesame);
    }

    // Default calories heuristic
    int baseCalories = 450;
    double protein = 24.0;
    double carbs = 35.0;
    double fats = 18.0;

    if (lower.contains('سلطة') || lower.contains('salad')) {
      baseCalories = 180;
      protein = 8.0;
      carbs = 12.0;
      fats = 6.0;
    } else if (lower.contains('برجر') || lower.contains('ستيك')) {
      baseCalories = 680;
      protein = 38.0;
      carbs = 42.0;
      fats = 28.0;
    } else if (lower.contains('عصير') || lower.contains('مشروب')) {
      baseCalories = 140;
      protein = 1.0;
      carbs = 32.0;
      fats = 0.5;
    }

    return NutritionalFacts(
      calories: baseCalories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fats,
      allergens: allergens,
    );
  }

  /// Detects whether adding/viewing this item conflicts with the user's allergen profile.
  List<AllergenType> detectAllergenConflicts({
    required String itemName,
    required CustomerDietaryProfile profile,
  }) {
    if (profile.allergens.isEmpty) return const [];
    final facts = getNutritionalFactsForItem('item', itemName);
    return facts.allergens.where((a) => profile.allergens.contains(a)).toList();
  }

  /// Filters a menu list based on the chosen dietary goal and allergen exclusions.
  List<MenuItem> filterMenuItems({
    required List<MenuItem> items,
    required DietaryGoal goal,
    required List<AllergenType> excludedAllergens,
  }) {
    return items.where((item) {
      final facts = getNutritionalFactsForItem(item.id, item.name);

      // Check if contains excluded allergens
      final hasConflict = facts.allergens.any((a) => excludedAllergens.contains(a));
      if (hasConflict) return false;

      // Check dietary goal
      switch (goal) {
        case DietaryGoal.all:
          return true;
        case DietaryGoal.vegan:
          return item.isVegetarian && !facts.allergens.contains(AllergenType.dairy) && !facts.allergens.contains(AllergenType.eggs);
        case DietaryGoal.vegetarian:
          return item.isVegetarian;
        case DietaryGoal.keto:
        case DietaryGoal.lowCarb:
          return facts.carbsGrams <= 20.0;
        case DietaryGoal.highProtein:
          return facts.proteinGrams >= 25.0;
        case DietaryGoal.halal:
          return true;
      }
    }).toList();
  }
}
