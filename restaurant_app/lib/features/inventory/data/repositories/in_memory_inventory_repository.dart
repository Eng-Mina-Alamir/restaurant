import '../../../orders/domain/entities/order_entity.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/recipe_item_entity.dart';
import '../../domain/entities/waste_log_entity.dart';
import '../../domain/repositories/inventory_repository.dart';

/// In-memory implementation of [InventoryRepository] with realistic Egyptian restaurant ingredients,
/// comprehensive recipe (BOM) definitions, and waste logs.
class InMemoryInventoryRepository implements InventoryRepository {
  InMemoryInventoryRepository([
    List<InventoryItemEntity>? initialItems,
    List<MenuItemRecipeEntity>? initialRecipes,
    List<WasteLogEntity>? initialWasteLogs,
  ]) {
    _items =
        initialItems ??
        [
          const InventoryItemEntity(
            id: 'inv-1',
            name: 'لحم ضاني وكندوز بلدي طازج',
            category: 'لحوم',
            currentStock: 35.0,
            unit: 'كغ',
            minThreshold: 15.0,
            costPerUnit: 380.0,
          ),
          const InventoryItemEntity(
            id: 'inv-2',
            name: 'عيش بلدي طازج مخبوز بالردة',
            category: 'مخبوزات',
            currentStock: 120.0,
            unit: 'رغيف',
            minThreshold: 50.0,
            costPerUnit: 2.5,
          ),
          const InventoryItemEntity(
            id: 'inv-3',
            name: 'سمن بلدي فلاحي جاموسي نقي',
            category: 'ألبان ودهون',
            currentStock: 14.0,
            unit: 'كغ',
            minThreshold: 8.0,
            costPerUnit: 260.0,
          ),
          const InventoryItemEntity(
            id: 'inv-4',
            name: 'ملوخية خضراء فلاحي طازجة',
            category: 'خضروات',
            currentStock: 25.0,
            unit: 'كغ',
            minThreshold: 10.0,
            costPerUnit: 20.0,
          ),
          const InventoryItemEntity(
            id: 'inv-5',
            name: 'أرز مصري درجة أولى (الحبة الرفيعة)',
            category: 'حبوب',
            currentStock: 80.0,
            unit: 'كغ',
            minThreshold: 30.0,
            costPerUnit: 32.0,
          ),
          const InventoryItemEntity(
            id: 'inv-6',
            name: 'دجاج مزارع بلدي طازج للتحمير',
            category: 'دواجن',
            currentStock: 40.0,
            unit: 'دجاجة',
            minThreshold: 15.0,
            costPerUnit: 125.0,
          ),
          const InventoryItemEntity(
            id: 'inv-7',
            name: 'طحينة سمسم بلدي نقية خام',
            category: 'صلصات',
            currentStock: 18.0,
            unit: 'كغ',
            minThreshold: 10.0,
            costPerUnit: 110.0,
          ),
          const InventoryItemEntity(
            id: 'inv-8',
            name: 'مانجو عويس وسكري فريش للعصير',
            category: 'فواكه',
            currentStock: 3.5,
            unit: 'كغ',
            minThreshold: 5.0,
            costPerUnit: 70.0,
          ),
          const InventoryItemEntity(
            id: 'inv-9',
            name: 'صلصة طماطم بلدي مركزة وثوم',
            category: 'صلصات',
            currentStock: 30.0,
            unit: 'كغ',
            minThreshold: 10.0,
            costPerUnit: 40.0,
          ),
        ];

    _recipes =
        initialRecipes ??
        [
          const MenuItemRecipeEntity(
            menuItemId: 'item-1',
            menuItemName: 'طاجن ملوخية باللحم الضاني والموزة',
            menuItemPrice: 195.0,
            ingredients: [
              RecipeIngredientEntity(
                inventoryItemId: 'inv-4',
                inventoryItemName: 'ملوخية خضراء فلاحي طازجة',
                quantity: 0.35,
                unit: 'كغ',
                costPerUnit: 20.0,
              ),
              RecipeIngredientEntity(
                inventoryItemId: 'inv-1',
                inventoryItemName: 'لحم ضاني وكندوز بلدي طازج',
                quantity: 0.25,
                unit: 'كغ',
                costPerUnit: 380.0,
              ),
              RecipeIngredientEntity(
                inventoryItemId: 'inv-3',
                inventoryItemName: 'سمن بلدي فلاحي جاموسي نقي',
                quantity: 0.03,
                unit: 'كغ',
                costPerUnit: 260.0,
              ),
              RecipeIngredientEntity(
                inventoryItemId: 'inv-2',
                inventoryItemName: 'عيش بلدي طازج مخبوز بالردة',
                quantity: 2.0,
                unit: 'رغيف',
                costPerUnit: 2.5,
              ),
            ],
          ),
          const MenuItemRecipeEntity(
            menuItemId: 'item-2',
            menuItemName: 'فتة كوارع ولحم بالخل والثوم',
            menuItemPrice: 220.0,
            ingredients: [
              RecipeIngredientEntity(
                inventoryItemId: 'inv-5',
                inventoryItemName: 'أرز مصري درجة أولى',
                quantity: 0.25,
                unit: 'كغ',
                costPerUnit: 32.0,
              ),
              RecipeIngredientEntity(
                inventoryItemId: 'inv-1',
                inventoryItemName: 'لحم ضاني وكندوز بلدي طازج',
                quantity: 0.20,
                unit: 'كغ',
                costPerUnit: 380.0,
              ),
              RecipeIngredientEntity(
                inventoryItemId: 'inv-2',
                inventoryItemName: 'عيش بلدي محمص بالسمن',
                quantity: 2.0,
                unit: 'رغيف',
                costPerUnit: 2.5,
              ),
              RecipeIngredientEntity(
                inventoryItemId: 'inv-9',
                inventoryItemName: 'صلصة طماطم بلدي مركزة وثوم',
                quantity: 0.10,
                unit: 'كغ',
                costPerUnit: 40.0,
              ),
            ],
          ),
          const MenuItemRecipeEntity(
            menuItemId: 'item-3',
            menuItemName: 'نصف دجاجة محمرة بلدي بالسمن الفلاحي',
            menuItemPrice: 145.0,
            ingredients: [
              RecipeIngredientEntity(
                inventoryItemId: 'inv-6',
                inventoryItemName: 'دجاج مزارع بلدي طازج',
                quantity: 0.5,
                unit: 'دجاجة',
                costPerUnit: 125.0,
              ),
              RecipeIngredientEntity(
                inventoryItemId: 'inv-3',
                inventoryItemName: 'سمن بلدي فلاحي جاموسي نقي',
                quantity: 0.02,
                unit: 'كغ',
                costPerUnit: 260.0,
              ),
              RecipeIngredientEntity(
                inventoryItemId: 'inv-5',
                inventoryItemName: 'أرز مصري درجة أولى',
                quantity: 0.2,
                unit: 'كغ',
                costPerUnit: 32.0,
              ),
            ],
          ),
          const MenuItemRecipeEntity(
            menuItemId: 'item-4',
            menuItemName: 'عصير مانجو فريش طبيعي مثلج',
            menuItemPrice: 55.0,
            ingredients: [
              RecipeIngredientEntity(
                inventoryItemId: 'inv-8',
                inventoryItemName: 'مانجو عويس وسكري فريش',
                quantity: 0.35,
                unit: 'كغ',
                costPerUnit: 70.0,
              ),
            ],
          ),
        ];

    _wasteLogs =
        initialWasteLogs ??
        [
          WasteLogEntity(
            id: 'waste-1',
            inventoryItemId: 'inv-4',
            inventoryItemName: 'ملوخية خضراء فلاحي طازجة',
            quantity: 2.5,
            unit: 'كغ',
            unitCost: 20.0,
            totalCost: 50.0,
            reason: WasteReason.spoilage,
            loggedByName: 'شيف مصطفى محمود',
            notes: 'تلف بسبب عطل مؤقت في تبريد الثلاجة رقم 2',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          WasteLogEntity(
            id: 'waste-2',
            inventoryItemId: 'inv-2',
            inventoryItemName: 'عيش بلدي طازج مخبوز بالردة',
            quantity: 15.0,
            unit: 'رغيف',
            unitCost: 2.5,
            totalCost: 37.5,
            reason: WasteReason.expired,
            loggedByName: 'كابتن أحمد سامي',
            notes: 'بقايا الخبز الزائد بعد إغلاق وردية الأمس',
            createdAt: DateTime.now().subtract(const Duration(hours: 12)),
          ),
        ];
  }

  late List<InventoryItemEntity> _items;
  late List<MenuItemRecipeEntity> _recipes;
  late List<WasteLogEntity> _wasteLogs;

  @override
  Future<Either<Failure, List<InventoryItemEntity>>> getInventoryItems() async {
    return Right(List.unmodifiable(_items));
  }

  @override
  Future<Either<Failure, InventoryItemEntity>> addItem(
    InventoryItemEntity item,
  ) async {
    _items = [..._items, item];
    return Right(item);
  }

  @override
  Future<Either<Failure, InventoryItemEntity>> updateItem(
    InventoryItemEntity item,
  ) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      return const Left(NotFoundFailure('الصنف غير موجود في المخزون'));
    }
    _items = [..._items]..[index] = item;
    return Right(item);
  }

  @override
  Future<Either<Failure, void>> deleteItem(String id) async {
    _items = _items.where((i) => i.id != id).toList();
    return const Right(null);
  }

  @override
  Future<Either<Failure, InventoryItemEntity>> restock(
    String id,
    double amount,
  ) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      return const Left(NotFoundFailure('الصنف غير موجود في المخزون'));
    }
    final existing = _items[index];
    final updated = existing.copyWith(
      currentStock: (existing.currentStock + amount).clamp(0.0, 999999.0),
    );
    _items = [..._items]..[index] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, void>> deductStockForOrder(OrderEntity order) async {
    for (final orderItem in order.items) {
      final menuItem = orderItem.menuItem;
      final qty = orderItem.quantity.toDouble();

      // Check if this menu item has a defined recipe
      final recipeMatch = _recipes.where(
        (r) =>
            r.menuItemId == menuItem.id ||
            r.menuItemName.trim().toLowerCase() ==
                menuItem.name.trim().toLowerCase(),
      );

      if (recipeMatch.isNotEmpty) {
        final recipe = recipeMatch.first;
        for (final ingredient in recipe.ingredients) {
          final deduction = ingredient.quantity * qty;
          final invIndex = _items.indexWhere(
            (i) => i.id == ingredient.inventoryItemId,
          );
          if (invIndex != -1) {
            final inv = _items[invIndex];
            final newStock = (inv.currentStock - deduction).clamp(
              0.0,
              999999.0,
            );
            _items[invIndex] = inv.copyWith(currentStock: newStock);
          }
        }
      } else {
        // Fallback deduction based on generic keywords
        final name = menuItem.name.toLowerCase();
        for (var i = 0; i < _items.length; i++) {
          final inv = _items[i];
          final invName = inv.name.toLowerCase();
          double deduction = 0.0;
          if (invName.contains('لحم') &&
              (name.contains('لحم') ||
                  name.contains('كباب') ||
                  name.contains('طاجن') ||
                  name.contains('برجر') ||
                  name.contains('كفتة'))) {
            deduction = 0.25 * qty;
          } else if (invName.contains('دجاج') &&
              (name.contains('دجاج') ||
                  name.contains('فراخ') ||
                  name.contains('شاورما') ||
                  name.contains('شيش'))) {
            deduction = 0.3 * qty;
          } else if (invName.contains('أرز') &&
              (name.contains('أرز') ||
                  name.contains('فتة') ||
                  name.contains('وجبة') ||
                  name.contains('برياني'))) {
            deduction = 0.2 * qty;
          } else if (invName.contains('عيش') &&
              (name.contains('ساندوتش') ||
                  name.contains('حواوشي') ||
                  name.contains('شاورما') ||
                  name.contains('وجبة'))) {
            deduction = 1.0 * qty;
          } else if (invName.contains('مانجو') && name.contains('مانجو')) {
            deduction = 0.35 * qty;
          }

          if (deduction > 0) {
            final newStock = (inv.currentStock - deduction).clamp(
              0.0,
              999999.0,
            );
            _items[i] = inv.copyWith(currentStock: newStock);
          }
        }
      }
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<MenuItemRecipeEntity>>> getRecipes() async {
    // Refresh costs from current inventory items
    final refreshed = _recipes.map((recipe) {
      final updatedIngredients = recipe.ingredients.map((ing) {
        final invItem = _items.firstWhere(
          (i) => i.id == ing.inventoryItemId,
          orElse: () => InventoryItemEntity(
            id: ing.inventoryItemId,
            name: ing.inventoryItemName,
            category: 'عام',
            currentStock: 0,
            unit: ing.unit,
            minThreshold: 0,
            costPerUnit: ing.costPerUnit,
          ),
        );
        return ing.copyWith(
          inventoryItemName: invItem.name,
          costPerUnit: invItem.costPerUnit,
        );
      }).toList();

      return recipe.copyWith(ingredients: updatedIngredients);
    }).toList();

    _recipes = refreshed;
    return Right(List.unmodifiable(_recipes));
  }

  @override
  Future<Either<Failure, MenuItemRecipeEntity?>> getRecipeForMenuItem(
    String menuItemId,
  ) async {
    final match = _recipes.where((r) => r.menuItemId == menuItemId);
    if (match.isEmpty) return const Right(null);
    return Right(match.first);
  }

  @override
  Future<Either<Failure, MenuItemRecipeEntity>> saveRecipe(
    MenuItemRecipeEntity recipe,
  ) async {
    final index = _recipes.indexWhere((r) => r.menuItemId == recipe.menuItemId);
    final updated = recipe.copyWith(lastUpdated: DateTime.now());
    if (index == -1) {
      _recipes = [..._recipes, updated];
    } else {
      _recipes = [..._recipes]..[index] = updated;
    }
    return Right(updated);
  }

  @override
  Future<Either<Failure, List<WasteLogEntity>>> getWasteLogs() async {
    final sorted = List<WasteLogEntity>.from(_wasteLogs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Right(List.unmodifiable(sorted));
  }

  @override
  Future<Either<Failure, WasteLogEntity>> logWaste(
    WasteLogEntity wasteLog,
  ) async {
    _wasteLogs = [wasteLog, ..._wasteLogs];

    // Deduct wasted quantity from inventory stock
    final invIndex = _items.indexWhere(
      (i) => i.id == wasteLog.inventoryItemId,
    );
    if (invIndex != -1) {
      final item = _items[invIndex];
      final newStock = (item.currentStock - wasteLog.quantity).clamp(
        0.0,
        999999.0,
      );
      _items[invIndex] = item.copyWith(currentStock: newStock);
    }

    return Right(wasteLog);
  }
}
