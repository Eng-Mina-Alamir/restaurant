import 'package:flutter/foundation.dart';

/// Common food allergen types recognized in culinary standards.
enum AllergenType {
  peanuts,
  treeNuts,
  dairy,
  gluten,
  seafood,
  eggs,
  sesame,
  soy;

  String get labelAr {
    switch (this) {
      case AllergenType.peanuts:
        return 'فول سوداني';
      case AllergenType.treeNuts:
        return 'مكسرات بندق ولوز';
      case AllergenType.dairy:
        return 'مشتقات حليب ولاكتوز';
      case AllergenType.gluten:
        return 'جلوتين وقمح';
      case AllergenType.seafood:
        return 'مأكولات بحرية وأسماك';
      case AllergenType.eggs:
        return 'بيض';
      case AllergenType.sesame:
        return 'سمسم';
      case AllergenType.soy:
        return 'فول صويا';
    }
  }

  String get iconEmoji {
    switch (this) {
      case AllergenType.peanuts:
        return '🥜';
      case AllergenType.treeNuts:
        return '🌰';
      case AllergenType.dairy:
        return '🥛';
      case AllergenType.gluten:
        return '🌾';
      case AllergenType.seafood:
        return '🦐';
      case AllergenType.eggs:
        return '🥚';
      case AllergenType.sesame:
        return '🌱';
      case AllergenType.soy:
        return '🫘';
    }
  }
}

/// Dietary lifestyles and health goals.
enum DietaryGoal {
  all,
  keto,
  vegan,
  vegetarian,
  lowCarb,
  highProtein,
  halal;

  String get labelAr {
    switch (this) {
      case DietaryGoal.all:
        return 'جميع الوجبات';
      case DietaryGoal.keto:
        return 'كيتو دايت (Keto)';
      case DietaryGoal.vegan:
        return 'نباتي صرف (Vegan)';
      case DietaryGoal.vegetarian:
        return 'نباتي ألبان (Vegetarian)';
      case DietaryGoal.lowCarb:
        return 'قليل الكربوهيدرات (Low-Carb)';
      case DietaryGoal.highProtein:
        return 'عالي البروتين (High-Protein)';
      case DietaryGoal.halal:
        return 'حلال ومذبوح إسلامي (Halal)';
    }
  }
}

/// Nutritional values breakdown for dishes.
@immutable
class NutritionalFacts {
  const NutritionalFacts({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.allergens = const [],
  });

  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final List<AllergenType> allergens;

  NutritionalFacts copyWith({
    int? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    List<AllergenType>? allergens,
  }) {
    return NutritionalFacts(
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      allergens: allergens ?? this.allergens,
    );
  }
}

/// Customer's personal health profile with selected allergens and lifestyle preferences.
@immutable
class CustomerDietaryProfile {
  const CustomerDietaryProfile({
    this.allergens = const [],
    this.dietaryGoal = DietaryGoal.all,
    this.strictAllergenAlerts = true,
  });

  final List<AllergenType> allergens;
  final DietaryGoal dietaryGoal;
  final bool strictAllergenAlerts;

  bool hasAllergyTo(AllergenType type) => allergens.contains(type);

  CustomerDietaryProfile copyWith({
    List<AllergenType>? allergens,
    DietaryGoal? dietaryGoal,
    bool? strictAllergenAlerts,
  }) {
    return CustomerDietaryProfile(
      allergens: allergens ?? this.allergens,
      dietaryGoal: dietaryGoal ?? this.dietaryGoal,
      strictAllergenAlerts: strictAllergenAlerts ?? this.strictAllergenAlerts,
    );
  }
}
