/// Represents a single ingredient component within a recipe (Bill of Materials).
class RecipeIngredientEntity {
  const RecipeIngredientEntity({
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.quantity,
    required this.unit,
    required this.costPerUnit,
    this.notes,
  });

  final String inventoryItemId;
  final String inventoryItemName;
  final double quantity;
  final String unit;
  final double costPerUnit;
  final String? notes;

  /// Line cost = required quantity * cost per unit in inventory
  double get lineCost => quantity * costPerUnit;

  RecipeIngredientEntity copyWith({
    String? inventoryItemId,
    String? inventoryItemName,
    double? quantity,
    String? unit,
    double? costPerUnit,
    String? notes,
  }) {
    return RecipeIngredientEntity(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      inventoryItemName: inventoryItemName ?? this.inventoryItemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'inventoryItemId': inventoryItemId,
    'inventoryItemName': inventoryItemName,
    'quantity': quantity,
    'unit': unit,
    'costPerUnit': costPerUnit,
    'notes': notes,
  };

  factory RecipeIngredientEntity.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientEntity(
      inventoryItemId: json['inventoryItemId'] as String,
      inventoryItemName: json['inventoryItemName'] as String? ?? 'مكون خام',
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'كغ',
      costPerUnit: (json['costPerUnit'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );
  }
}

/// Represents the complete Recipe (BOM) definition for a menu item.
class MenuItemRecipeEntity {
  const MenuItemRecipeEntity({
    required this.menuItemId,
    required this.menuItemName,
    required this.menuItemPrice,
    this.ingredients = const [],
    this.lastUpdated,
  });

  final String menuItemId;
  final String menuItemName;
  final double menuItemPrice;
  final List<RecipeIngredientEntity> ingredients;
  final DateTime? lastUpdated;

  /// Total Food Cost (COGS) to prepare 1 portion of this dish
  double get totalFoodCost =>
      ingredients.fold<double>(0.0, (sum, ing) => sum + ing.lineCost);

  /// Gross Margin per plate = Selling Price - Food Cost
  double get grossMargin => menuItemPrice - totalFoodCost;

  /// Food Cost Percentage = (Total Food Cost / Selling Price) * 100
  /// Healthy restaurant benchmark is typically between 28% and 35%.
  double get foodCostPercentage {
    if (menuItemPrice <= 0) return 0.0;
    return (totalFoodCost / menuItemPrice) * 100.0;
  }

  /// Health status of this recipe's cost margin
  String get costHealthLabel {
    final pct = foodCostPercentage;
    if (pct <= 0) return 'غير محدد';
    if (pct <= 32.0) return 'ممتاز (ربحية عالية)';
    if (pct <= 38.0) return 'متوسط (ربحية مقبولة)';
    return 'مرتفع التكلفة (يحتاج مراجعة)';
  }

  MenuItemRecipeEntity copyWith({
    String? menuItemId,
    String? menuItemName,
    double? menuItemPrice,
    List<RecipeIngredientEntity>? ingredients,
    DateTime? lastUpdated,
  }) {
    return MenuItemRecipeEntity(
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      menuItemPrice: menuItemPrice ?? this.menuItemPrice,
      ingredients: ingredients ?? this.ingredients,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
    'menuItemId': menuItemId,
    'menuItemName': menuItemName,
    'menuItemPrice': menuItemPrice,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'lastUpdated': lastUpdated?.toIso8601String(),
  };

  factory MenuItemRecipeEntity.fromJson(Map<String, dynamic> json) {
    return MenuItemRecipeEntity(
      menuItemId: json['menuItemId'] as String,
      menuItemName: json['menuItemName'] as String? ?? '',
      menuItemPrice: (json['menuItemPrice'] as num?)?.toDouble() ?? 0.0,
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map(
                (i) => RecipeIngredientEntity.fromJson(
                  i as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      lastUpdated:
          json['lastUpdated'] != null
              ? DateTime.tryParse(json['lastUpdated'] as String)
              : null,
    );
  }
}
