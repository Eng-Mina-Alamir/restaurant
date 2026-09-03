import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/recipe_item_entity.dart';
import '../../domain/entities/waste_log_entity.dart';
import '../../domain/repositories/inventory_repository.dart';

class SupabaseInventoryRepository implements InventoryRepository {
  SupabaseInventoryRepository({
    required SupabaseClient supabase,
    LocalCacheService? cache,
  })  : _supabase = supabase,
        _cache = cache;

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;

  static const String _cacheKey = 'cached_inventory';

  /// In-memory mirror of Supabase-loaded inventory for this session only.
  /// Never seeded: empty Supabase table => empty list (truthful).

  List<InventoryItemEntity>? _cachedItems;
  final List<MenuItemRecipeEntity> _cachedRecipes = [];
  final List<WasteLogEntity> _cachedWasteLogs = [];

  @override
  Future<Either<Failure, List<InventoryItemEntity>>> getInventoryItems() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.inventoryTable)
          .select()
          .order('name');

      final List<InventoryItemEntity> items = [];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        items.add(_mapToInventoryItemEntity(map));
      }
      if (items.isEmpty) {
        _cachedItems = items;
        return Right(items);
      }
      _cachedItems = items;
      final cache = _cache;
      if (cache != null) {
        try {
          await cache.writeList(_cacheKey, items.map((i) => i.toJson()).toList());
        } catch (e) {
          AppLogger.warning('Failed to persist inventory to local cache: $e');
        }
      }
      return Right(items);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase getInventoryItems error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل تحميل المخزون من Supabase: $e'));
    }
  }

  @override
  Future<Either<Failure, InventoryItemEntity>> addItem(
    InventoryItemEntity item,
  ) async {
    try {
      final payload = {
        'id': item.id,
        'name': item.name,
        'category': item.category,
        'quantity': item.currentStock,
        'unit': item.unit,
        'min_threshold': item.minThreshold,
        'cost_per_unit': item.costPerUnit,
        'last_updated': DateTime.now().toIso8601String(),
      };
      await _supabase.from(SupabaseConfig.inventoryTable).insert(payload);
      if (_cachedItems != null) {
        _cachedItems!.add(item);
      }
      return Right(item);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase addItem error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل إضافة الصنف للمخزون: $e'));
    }
  }

  @override
  Future<Either<Failure, InventoryItemEntity>> updateItem(
    InventoryItemEntity item,
  ) async {
    try {
      final payload = {
        'name': item.name,
        'category': item.category,
        'quantity': item.currentStock,
        'unit': item.unit,
        'min_threshold': item.minThreshold,
        'cost_per_unit': item.costPerUnit,
        'last_updated': DateTime.now().toIso8601String(),
      };
      await _supabase
          .from(SupabaseConfig.inventoryTable)
          .update(payload)
          .eq('id', item.id);
      if (_cachedItems != null) {
        final idx = _cachedItems!.indexWhere((i) => i.id == item.id);
        if (idx != -1) _cachedItems![idx] = item;
      }
      return Right(item);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase updateItem error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل تحديث صنف المخزون: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteItem(String id) async {
    try {
      await _supabase
          .from(SupabaseConfig.inventoryTable)
          .delete()
          .eq('id', id);
      if (_cachedItems != null) {
        _cachedItems!.removeWhere((i) => i.id == id);
      }
      return const Right(null);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase deleteItem error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل حذف صنف المخزون: $e'));
    }
  }

  @override
  Future<Either<Failure, InventoryItemEntity>> restock(
    String id,
    double amount,
  ) async {
    try {
      final existingRaw = await _supabase
          .from(SupabaseConfig.inventoryTable)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (existingRaw == null) {
        return const Left(NotFoundFailure('الصنف غير موجود في المخزون'));
      }

      final existing = _mapToInventoryItemEntity(
        Map<String, dynamic>.from(existingRaw),
      );
      final newQuantity = (existing.currentStock + amount).clamp(0.0, 999999.0);

      await _supabase
          .from(SupabaseConfig.inventoryTable)
          .update({
            'quantity': newQuantity,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      final updated = existing.copyWith(currentStock: newQuantity);
      if (_cachedItems != null) {
        final idx = _cachedItems!.indexWhere((i) => i.id == id);
        if (idx != -1) _cachedItems![idx] = updated;
      }
      return Right(updated);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase restock error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل إعادة تزويد المخزون: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deductStockForOrder(OrderEntity order) async {
    final itemsResult = await getInventoryItems();
    final items = itemsResult.when(
      onLeft: (_) => const <InventoryItemEntity>[],
      onRight: (list) => list,
    );

    for (final orderItem in order.items) {
      final name = orderItem.menuItem.name.toLowerCase();
      final qty = orderItem.quantity.toDouble();

      for (var i = 0; i < items.length; i++) {
        final inv = items[i];
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
        } else if (invName.contains('زيت') &&
            (name.contains('مقلي') ||
                name.contains('بطاطس') ||
                name.contains('فراخ') ||
                name.contains('برجر'))) {
          deduction = 0.05 * qty;
        } else if (invName.contains('جبن') &&
            (name.contains('جبن') ||
                name.contains('برجر') ||
                name.contains('بيتزا'))) {
          deduction = 0.05 * qty;
        }

        if (deduction > 0) {
          final newStock = (inv.currentStock - deduction).clamp(0.0, 999999.0);
          final updated = inv.copyWith(currentStock: newStock);
          try {
            await updateItem(updated);
          } catch (_) {}
        }
      }
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<MenuItemRecipeEntity>>> getRecipes() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.recipesTable)
          .select()
          .order('menu_item_name');

      final List<MenuItemRecipeEntity> recipes = [];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        recipes.add(_mapToRecipeEntity(map));
      }
      if (recipes.isNotEmpty) {
        _cachedRecipes
          ..clear()
          ..addAll(recipes);
        return Right(recipes);
      }
      return Right(List.unmodifiable(_cachedRecipes));
    } catch (e, st) {
      AppLogger.warning(
        'Supabase getRecipes fallback: $e',
        error: e,
        stackTrace: st,
      );
      return Right(List.unmodifiable(_cachedRecipes));
    }
  }

  @override
  Future<Either<Failure, MenuItemRecipeEntity?>> getRecipeForMenuItem(
    String menuItemId,
  ) async {
    try {
      final raw = await _supabase
          .from(SupabaseConfig.recipesTable)
          .select()
          .eq('menu_item_id', menuItemId)
          .maybeSingle();

      if (raw != null) {
        final recipe = _mapToRecipeEntity(Map<String, dynamic>.from(raw));
        final idx = _cachedRecipes.indexWhere((r) => r.menuItemId == menuItemId);
        if (idx == -1) {
          _cachedRecipes.add(recipe);
        } else {
          _cachedRecipes[idx] = recipe;
        }
        return Right(recipe);
      }
    } catch (e, st) {
      AppLogger.warning(
        'Supabase getRecipeForMenuItem fallback: $e',
        error: e,
        stackTrace: st,
      );
    }

    final match = _cachedRecipes.where((r) => r.menuItemId == menuItemId);
    if (match.isEmpty) return const Right(null);
    return Right(match.first);
  }

  @override
  Future<Either<Failure, MenuItemRecipeEntity>> saveRecipe(
    MenuItemRecipeEntity recipe,
  ) async {
    final updated = recipe.copyWith(lastUpdated: DateTime.now());
    final idx = _cachedRecipes.indexWhere((r) => r.menuItemId == recipe.menuItemId);
    if (idx == -1) {
      _cachedRecipes.add(updated);
    } else {
      _cachedRecipes[idx] = updated;
    }

    try {
      final payload = {
        'id': 'rec_${recipe.menuItemId}',
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
        'menu_item_id': recipe.menuItemId,
        'menu_item_name': recipe.menuItemName,
        'menu_item_price': recipe.menuItemPrice,
        'ingredients_json': recipe.ingredients.map((i) => i.toJson()).toList(),
        'last_updated': updated.lastUpdated?.toIso8601String(),
      };
      await _supabase.from(SupabaseConfig.recipesTable).upsert(payload);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase saveRecipe fallback: $e',
        error: e,
        stackTrace: st,
      );
    }

    return Right(updated);
  }

  MenuItemRecipeEntity _mapToRecipeEntity(Map<String, dynamic> map) {
    final List<RecipeIngredientEntity> ingredients = [];
    final rawIngredients = map['ingredients_json'];
    if (rawIngredients is List) {
      for (final ing in rawIngredients) {
        if (ing is Map) {
          ingredients.add(
            RecipeIngredientEntity.fromJson(Map<String, dynamic>.from(ing)),
          );
        }
      }
    }
    return MenuItemRecipeEntity(
      menuItemId: map['menu_item_id']?.toString() ?? '',
      menuItemName: map['menu_item_name'] as String? ?? '',
      menuItemPrice: (map['menu_item_price'] as num?)?.toDouble() ?? 0.0,
      ingredients: ingredients,
      lastUpdated: map['last_updated'] != null
          ? DateTime.tryParse(map['last_updated'].toString())
          : null,
    );
  }

  @override
  Future<Either<Failure, List<WasteLogEntity>>> getWasteLogs() async {
    return Right(List.unmodifiable(_cachedWasteLogs));
  }

  @override
  Future<Either<Failure, WasteLogEntity>> logWaste(
    WasteLogEntity wasteLog,
  ) async {
    _cachedWasteLogs.insert(0, wasteLog);
    return Right(wasteLog);
  }

  InventoryItemEntity _mapToInventoryItemEntity(Map<String, dynamic> map) {
    return InventoryItemEntity(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      currentStock: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'كجم',
      minThreshold: (map['min_threshold'] as num?)?.toDouble() ?? 5.0,
      costPerUnit: (map['cost_per_unit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
