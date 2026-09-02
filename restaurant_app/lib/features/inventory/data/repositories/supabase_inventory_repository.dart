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

  static const String _inventoryCacheKey = 'inventory_v1';
  static const String _recipesCacheKey = 'recipes_v1';
  static const String _wasteCacheKey = 'waste_logs_v1';

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

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _inventoryCacheKey,
          items.map((i) => {
            'id': i.id,
            'name': i.name,
            'category': i.category,
            'currentStock': i.currentStock,
            'unit': i.unit,
            'minThreshold': i.minThreshold,
            'costPerUnit': i.costPerUnit,
          }).toList(),
        );
      }

      return Right(items);
    } catch (e, st) {
      AppLogger.warning('Supabase getInventoryItems fallback: $e', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readList(_inventoryCacheKey);
        if (cached.isNotEmpty) {
          final list = cached.map((map) => InventoryItemEntity(
            id: map['id']?.toString() ?? '',
            name: map['name'] as String? ?? '',
            category: map['category'] as String? ?? '',
            currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
            unit: map['unit'] as String? ?? 'كجم',
            minThreshold: (map['minThreshold'] as num?)?.toDouble() ?? 5.0,
            costPerUnit: (map['costPerUnit'] as num?)?.toDouble() ?? 0.0,
          )).toList();
          return Right(list);
        }
      }
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, InventoryItemEntity>> addItem(
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
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
      };

      final response = await _supabase
          .from(SupabaseConfig.inventoryTable)
          .insert(payload)
          .select()
          .single();

      final created = _mapToInventoryItemEntity(
        Map<String, dynamic>.from(response as Map),
      );
      return Right(created);
    } catch (e, st) {
      AppLogger.error('Supabase addItem failed: $e', error: e, stackTrace: st);
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
      };

      final parsedId = int.tryParse(item.id);
      final query = _supabase.from(SupabaseConfig.inventoryTable).update(payload);
      if (parsedId != null) {
        await query.eq('id', parsedId);
      } else {
        await query.eq('name', item.name);
      }

      return Right(item);
    } catch (e, st) {
      AppLogger.error('Supabase updateItem failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل تحديث المخزون: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteItem(String itemId) async {
    try {
      final parsedId = int.tryParse(itemId);
      final query = _supabase.from(SupabaseConfig.inventoryTable).delete();
      if (parsedId != null) {
        await query.eq('id', parsedId);
      } else {
        await query.eq('id', itemId);
      }
      return const Right(null);
    } catch (e, st) {
      AppLogger.error('Supabase deleteItem failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل حذف الصنف: $e'));
    }
  }

  @override
  Future<Either<Failure, InventoryItemEntity>> restock(
    String id,
    double amount,
  ) async {
    try {
      final itemsResult = await getInventoryItems();
      final items = itemsResult.getOrElse((_) => []);
      final match = items.where((i) => i.id == id);
      if (match.isEmpty) {
        return const Left(NotFoundFailure('الصنف غير موجود بالمخزون'));
      }
      final current = match.first;
      final updated = current.copyWith(
        currentStock: current.currentStock + amount,
      );
      return await updateItem(updated);
    } catch (e, st) {
      AppLogger.error('Supabase restock failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل إعادة تزويد المخزون: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deductStockForOrder(OrderEntity order) async {
    final itemsResult = await getInventoryItems();
    final inventoryList = itemsResult.getOrElse((_) => []);

    for (final orderItem in order.items) {
      final name = orderItem.menuItem.name.trim();
      final qty = orderItem.quantity.toDouble();

      for (final inv in inventoryList) {
        final invName = inv.name.trim();
        double deduction = 0.0;

        if (invName.contains('لحم') &&
            (name.contains('برجر') ||
                name.contains('لحم') ||
                name.contains('كفتة') ||
                name.contains('ستيك'))) {
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
          .select();

      final list = (response as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final ingredientsRaw = map['ingredients_json'] as List? ?? [];
        final ingredients = ingredientsRaw.whereType<Map>().map((i) {
          return RecipeIngredientEntity.fromJson(Map<String, dynamic>.from(i));
        }).toList();

        return MenuItemRecipeEntity(
          menuItemId: map['menu_item_id'] as String? ?? '',
          menuItemName: map['menu_item_name'] as String? ?? '',
          menuItemPrice: (map['menu_item_price'] as num?)?.toDouble() ?? 0.0,
          ingredients: ingredients,
          lastUpdated: map['last_updated'] != null
              ? DateTime.parse(map['last_updated'] as String)
              : DateTime.now(),
        );
      }).toList();

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _recipesCacheKey,
          list.map((r) => {
            'menuItemId': r.menuItemId,
            'menuItemName': r.menuItemName,
            'menuItemPrice': r.menuItemPrice,
            'ingredients': r.ingredients.map((i) => i.toJson()).toList(),
            'lastUpdated': r.lastUpdated?.toIso8601String(),
          }).toList(),
        );
      }

      return Right(list);
    } catch (e, st) {
      AppLogger.warning('Supabase getRecipes fallback: $e', error: e, stackTrace: st);
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, MenuItemRecipeEntity?>> getRecipeForMenuItem(
    String menuItemId,
  ) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.recipesTable)
          .select()
          .eq('menu_item_id', menuItemId)
          .maybeSingle();

      if (response == null) return const Right(null);

      final map = Map<String, dynamic>.from(response);
      final ingredientsRaw = map['ingredients_json'] as List? ?? [];
      final ingredients = ingredientsRaw.whereType<Map>().map((i) {
        return RecipeIngredientEntity.fromJson(Map<String, dynamic>.from(i));
      }).toList();

      return Right(
        MenuItemRecipeEntity(
          menuItemId: map['menu_item_id'] as String? ?? '',
          menuItemName: map['menu_item_name'] as String? ?? '',
          menuItemPrice: (map['menu_item_price'] as num?)?.toDouble() ?? 0.0,
          ingredients: ingredients,
          lastUpdated: map['last_updated'] != null
              ? DateTime.parse(map['last_updated'] as String)
              : DateTime.now(),
        ),
      );
    } catch (e, st) {
      AppLogger.error('Supabase getRecipeForMenuItem failed: $e', error: e, stackTrace: st);
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, MenuItemRecipeEntity>> saveRecipe(
    MenuItemRecipeEntity recipe,
  ) async {
    try {
      final payload = {
        'id': 'REC-${recipe.menuItemId}',
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
        'menu_item_id': recipe.menuItemId,
        'menu_item_name': recipe.menuItemName,
        'menu_item_price': recipe.menuItemPrice,
        'ingredients_json': recipe.ingredients.map((i) => i.toJson()).toList(),
        'last_updated': DateTime.now().toIso8601String(),
      };

      await _supabase.from(SupabaseConfig.recipesTable).upsert(payload, onConflict: 'menu_item_id');
      return Right(recipe.copyWith(lastUpdated: DateTime.now()));
    } catch (e, st) {
      AppLogger.error('Supabase saveRecipe failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل حفظ الوصفة: $e'));
    }
  }

  @override
  Future<Either<Failure, List<WasteLogEntity>>> getWasteLogs() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.wasteLogsTable)
          .select()
          .order('logged_at', ascending: false);

      final list = (response as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final reasonStr = map['reason'] as String? ?? 'other';
        final reason = WasteReason.values.firstWhere(
          (r) => r.name == reasonStr,
          orElse: () => WasteReason.other,
        );

        final qty = (map['quantity'] as num?)?.toDouble() ?? 0.0;
        final unitCost = (map['cost_per_unit'] as num?)?.toDouble() ?? 0.0;

        return WasteLogEntity(
          id: map['id']?.toString() ?? '',
          inventoryItemId: map['ingredient_id'] as String? ?? '',
          inventoryItemName: map['ingredient_name'] as String? ?? '',
          quantity: qty,
          unit: map['unit'] as String? ?? 'كجم',
          unitCost: unitCost,
          totalCost: qty * unitCost,
          reason: reason,
          loggedByName: map['logged_by'] as String? ?? 'مدير الفرع',
          notes: map['custom_notes'] as String?,
          createdAt: map['logged_at'] != null
              ? DateTime.parse(map['logged_at'] as String)
              : DateTime.now(),
        );
      }).toList();

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _wasteCacheKey,
          list.map((w) => w.toJson()).toList(),
        );
      }

      return Right(list);
    } catch (e, st) {
      AppLogger.warning('Supabase getWasteLogs fallback: $e', error: e, stackTrace: st);
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, WasteLogEntity>> logWaste(
    WasteLogEntity wasteLog,
  ) async {
    try {
      final payload = {
        'id': wasteLog.id,
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
        'ingredient_id': wasteLog.inventoryItemId,
        'ingredient_name': wasteLog.inventoryItemName,
        'quantity': wasteLog.quantity,
        'unit': wasteLog.unit,
        'cost_per_unit': wasteLog.unitCost,
        'reason': wasteLog.reason.name,
        'custom_notes': wasteLog.notes,
        'logged_by': wasteLog.loggedByName,
        'logged_at': wasteLog.createdAt.toIso8601String(),
      };

      await _supabase.from(SupabaseConfig.wasteLogsTable).upsert(payload);
      return Right(wasteLog);
    } catch (e, st) {
      AppLogger.error('Supabase logWaste failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل تسجيل الهدر: $e'));
    }
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
