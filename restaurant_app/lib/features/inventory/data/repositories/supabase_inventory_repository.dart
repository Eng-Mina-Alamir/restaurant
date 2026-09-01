import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/recipe_item_entity.dart';
import '../../domain/entities/waste_log_entity.dart';
import '../../domain/repositories/inventory_repository.dart';

class SupabaseInventoryRepository implements InventoryRepository {
  SupabaseInventoryRepository({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  static final List<InventoryItemEntity> _initialSeedItems = [
    const InventoryItemEntity(
      id: 'inv-01',
      name: 'لحم أنجوس مفروم فاخر',
      category: 'لحوم',
      currentStock: 45.0,
      minThreshold: 15.0,
      unit: 'كجم',
      costPerUnit: 120.0,
    ),
    const InventoryItemEntity(
      id: 'inv-02',
      name: 'أرز بسمتي فاخر',
      category: 'حبوب',
      currentStock: 80.0,
      minThreshold: 25.0,
      unit: 'كجم',
      costPerUnit: 35.0,
    ),
    const InventoryItemEntity(
      id: 'inv-03',
      name: 'زيت قلي نباتي نقي',
      category: 'زيوت',
      currentStock: 8.0,
      minThreshold: 12.0,
      unit: 'لتر',
      costPerUnit: 45.0,
    ),
    const InventoryItemEntity(
      id: 'inv-04',
      name: 'أجبان شيدر هولندية',
      category: 'ألبان',
      currentStock: 22.0,
      minThreshold: 10.0,
      unit: 'كجم',
      costPerUnit: 65.0,
    ),
  ];

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
        _cachedItems = List.of(_initialSeedItems);
        return Right(_cachedItems!);
      }
      _cachedItems = items;
      return Right(items);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase getInventoryItems fallback: $e',
        error: e,
        stackTrace: st,
      );
      _cachedItems ??= List.of(_initialSeedItems);
      return Right(List.unmodifiable(_cachedItems!));
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
        'Supabase addItem fallback: $e',
        error: e,
        stackTrace: st,
      );
      _cachedItems ??= List.of(_initialSeedItems);
      _cachedItems!.add(item);
      return Right(item);
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
        'Supabase updateItem fallback: $e',
        error: e,
        stackTrace: st,
      );
      _cachedItems ??= List.of(_initialSeedItems);
      final idx = _cachedItems!.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        _cachedItems![idx] = item;
        return Right(item);
      }
      return const Left(NotFoundFailure('الصنف غير موجود في المخزون'));
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
        'Supabase deleteItem fallback: $e',
        error: e,
        stackTrace: st,
      );
      _cachedItems?.removeWhere((i) => i.id == id);
      return const Right(null);
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
        'Supabase restock fallback: $e',
        error: e,
        stackTrace: st,
      );
      try {
        final local = (_cachedItems ?? _initialSeedItems).firstWhere(
          (i) => i.id == id,
          orElse: () =>
              throw const NotFoundFailure('الصنف غير موجود في المخزون'),
        );
        final newQuantity = (local.currentStock + amount).clamp(0.0, 999999.0);
        final updated = local.copyWith(currentStock: newQuantity);
        if (_cachedItems != null) {
          final idx = _cachedItems!.indexWhere((i) => i.id == id);
          if (idx != -1) _cachedItems![idx] = updated;
        }
        return Right(updated);
      } catch (err) {
        if (err is Failure) return Left(err);
        return Left(ServerFailure('فشل إعادة تزويد المخزون: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> deductStockForOrder(OrderEntity order) async {
    final itemsResult = await getInventoryItems();
    final items = itemsResult.when(
      onLeft: (_) => _cachedItems ?? _initialSeedItems,
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
    return Right(List.unmodifiable(_cachedRecipes));
  }

  @override
  Future<Either<Failure, MenuItemRecipeEntity?>> getRecipeForMenuItem(
    String menuItemId,
  ) async {
    final match = _cachedRecipes.where((r) => r.menuItemId == menuItemId);
    if (match.isEmpty) return const Right(null);
    return Right(match.first);
  }

  @override
  Future<Either<Failure, MenuItemRecipeEntity>> saveRecipe(
    MenuItemRecipeEntity recipe,
  ) async {
    final idx = _cachedRecipes.indexWhere((r) => r.menuItemId == recipe.menuItemId);
    final updated = recipe.copyWith(lastUpdated: DateTime.now());
    if (idx == -1) {
      _cachedRecipes.add(updated);
    } else {
      _cachedRecipes[idx] = updated;
    }
    return Right(updated);
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
