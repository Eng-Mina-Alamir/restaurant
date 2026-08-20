import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/menu.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';
import '../menu_seed_data.dart';

/// Supabase-backed [MenuRepository] with fallback to seed menu data.
class SupabaseMenuRepositoryImpl implements MenuRepository {
  SupabaseMenuRepositoryImpl(this._supabase);

  final SupabaseClient _supabase;
  Menu? _cachedMenu;

  @override
  Future<Either<Failure, Menu>> getMenu() async {
    try {
      // 1. Fetch categories
      final catResponse = await _supabase
          .from(SupabaseConfig.categoriesTable)
          .select()
          .order('sort_order', ascending: true);

      final List<String> categories = [];
      for (final raw in (catResponse as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final catName = (map['name_ar'] ?? map['name'])?.toString();
        if (catName != null && catName.isNotEmpty) {
          categories.add(catName);
        }
      }

      // 2. Fetch modifier options
      final optResponse = await _supabase
          .from(SupabaseConfig.modifierOptionsTable)
          .select();
      final Map<String, List<MenuModifierOption>> groupOptionsMap = {};
      for (final raw in (optResponse as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final groupId = map['modifier_group_id']?.toString() ?? '';
        final opt = MenuModifierOption(
          id: map['id']?.toString() ?? '',
          name: map['name'] as String? ?? '',
          extraPrice: (map['extra_price'] as num?)?.toDouble() ?? 0.0,
          isAvailable: map['is_available'] as bool? ?? true,
        );
        groupOptionsMap.putIfAbsent(groupId, () => []).add(opt);
      }

      // 3. Fetch modifier groups
      final groupResponse = await _supabase
          .from(SupabaseConfig.modifierGroupsTable)
          .select();
      final Map<String, List<MenuModifierGroup>> itemGroupsMap = {};
      for (final raw in (groupResponse as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final itemId = map['menu_item_id']?.toString() ?? '';
        final groupId = map['id']?.toString() ?? '';
        final group = MenuModifierGroup(
          id: groupId,
          title: map['title'] as String? ?? '',
          description: map['description'] as String?,
          isRequired: map['is_required'] as bool? ?? false,
          maxSelection: (map['max_selection'] as num?)?.toInt() ?? 1,
          options: groupOptionsMap[groupId] ?? [],
        );
        itemGroupsMap.putIfAbsent(itemId, () => []).add(group);
      }

      // 4. Fetch menu items
      final itemResponse = await _supabase
          .from(SupabaseConfig.menuItemsTable)
          .select();
      final List<MenuItem> items = [];
      for (final raw in (itemResponse as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final itemId = map['id']?.toString() ?? '';
        items.add(MenuItem(
          id: itemId,
          categoryId: map['category_id'] as String? ?? 'عام',
          name: map['name'] as String? ?? '',
          description: map['description'] as String? ?? '',
          price: (map['price'] as num?)?.toDouble() ?? 0.0,
          imageUrl: map['image_url'] as String?,
          isAvailable: map['is_available'] as bool? ?? true,
          isVegetarian: map['is_vegetarian'] as bool? ?? false,
          isSpicy: map['is_spicy'] as bool? ?? false,
          preparationTime: (map['preparation_time'] as num?)?.toDouble(),
          rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
          orderCount: (map['order_count'] as num?)?.toInt() ?? 0,
          modifierGroups: itemGroupsMap[itemId] ?? [],
        ));
      }

      if (items.isEmpty && categories.isEmpty) {
        final fallback = MenuSeedData.buildMenu();
        _cachedMenu = fallback;
        return Right<Failure, Menu>(fallback);
      }

      final resolvedCategories = categories.isNotEmpty
          ? categories
          : items.map((e) => e.categoryId).toSet().toList();

      final menu = Menu(
        restaurantId: 'restaurant-1',
        categories: resolvedCategories,
        items: items,
      );
      _cachedMenu = menu;
      return Right<Failure, Menu>(menu);
    } catch (e) {
      AppLogger.warning('Supabase getMenu failed: $e, falling back to cache or seed data');
      final fallback = _cachedMenu ?? MenuSeedData.buildMenu();
      _cachedMenu = fallback;
      return Right<Failure, Menu>(fallback);
    }
  }

  void _ensureCache() {
    _cachedMenu ??= MenuSeedData.buildMenu();
  }

  @override
  Future<Either<Failure, MenuItem>> addMenuItem(MenuItem item) async {
    _ensureCache();
    try {
      await _supabase.from(SupabaseConfig.menuItemsTable).insert({
        'id': item.id,
        'category_id': item.categoryId,
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'image_url': item.imageUrl,
        'is_available': item.isAvailable,
        'is_vegetarian': item.isVegetarian,
        'is_spicy': item.isSpicy,
        'preparation_time': item.preparationTime,
      });
      _cachedMenu = _cachedMenu!.copyWith(
        items: [..._cachedMenu!.items.where((i) => i.id != item.id), item],
      );
      return Right<Failure, MenuItem>(item);
    } catch (e) {
      _cachedMenu = _cachedMenu!.copyWith(
        items: [..._cachedMenu!.items.where((i) => i.id != item.id), item],
      );
      return Right<Failure, MenuItem>(item);
    }
  }

  @override
  Future<Either<Failure, MenuItem>> updateMenuItem(MenuItem item) async {
    _ensureCache();
    try {
      await _supabase.from(SupabaseConfig.menuItemsTable).update({
        'category_id': item.categoryId,
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'image_url': item.imageUrl,
        'is_available': item.isAvailable,
        'is_vegetarian': item.isVegetarian,
        'is_spicy': item.isSpicy,
        'preparation_time': item.preparationTime,
      }).eq('id', item.id);
      _cachedMenu = _cachedMenu!.copyWith(
        items: _cachedMenu!.items.map((i) => i.id == item.id ? item : i).toList(),
      );
      return Right<Failure, MenuItem>(item);
    } catch (e) {
      _cachedMenu = _cachedMenu!.copyWith(
        items: _cachedMenu!.items.map((i) => i.id == item.id ? item : i).toList(),
      );
      return Right<Failure, MenuItem>(item);
    }
  }

  @override
  Future<Either<Failure, void>> deleteMenuItem(String itemId) async {
    _ensureCache();
    try {
      await _supabase
          .from(SupabaseConfig.menuItemsTable)
          .delete()
          .eq('id', itemId);
      _cachedMenu = _cachedMenu!.copyWith(
        items: _cachedMenu!.items.where((i) => i.id != itemId).toList(),
      );
      return const Right<Failure, void>(null);
    } catch (e) {
      _cachedMenu = _cachedMenu!.copyWith(
        items: _cachedMenu!.items.where((i) => i.id != itemId).toList(),
      );
      return const Right<Failure, void>(null);
    }
  }

  @override
  Future<Either<Failure, void>> addCategory(String categoryName) async {
    _ensureCache();
    try {
      await _supabase.from(SupabaseConfig.categoriesTable).upsert({
        'name': categoryName.trim(),
      });
      if (!_cachedMenu!.categories.contains(categoryName)) {
        _cachedMenu = _cachedMenu!.copyWith(
          categories: [..._cachedMenu!.categories, categoryName],
        );
      }
      return const Right<Failure, void>(null);
    } catch (e) {
      if (!_cachedMenu!.categories.contains(categoryName)) {
        _cachedMenu = _cachedMenu!.copyWith(
          categories: [..._cachedMenu!.categories, categoryName],
        );
      }
      return const Right<Failure, void>(null);
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String categoryName) async {
    _ensureCache();
    try {
      await _supabase
          .from(SupabaseConfig.categoriesTable)
          .delete()
          .eq('name', categoryName);
      _cachedMenu = _cachedMenu!.copyWith(
        categories: _cachedMenu!.categories.where((c) => c != categoryName).toList(),
      );
      return const Right<Failure, void>(null);
    } catch (e) {
      _cachedMenu = _cachedMenu!.copyWith(
        categories: _cachedMenu!.categories.where((c) => c != categoryName).toList(),
      );
      return const Right<Failure, void>(null);
    }
  }

  @override
  Future<Either<Failure, MenuItem>> toggleAvailability(
    String itemId,
    bool isAvailable,
  ) async {
    _ensureCache();
    try {
      await _supabase
          .from(SupabaseConfig.menuItemsTable)
          .update({'is_available': isAvailable})
          .eq('id', itemId);

      final index = _cachedMenu!.items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final updated = _cachedMenu!.items[index].copyWith(isAvailable: isAvailable);
        _cachedMenu = _cachedMenu!.copyWith(
          items: _cachedMenu!.items.map((i) => i.id == itemId ? updated : i).toList(),
        );
        return Right<Failure, MenuItem>(updated);
      }
      return Right<Failure, MenuItem>(
        MenuItem(
          id: itemId,
          categoryId: '',
          name: '',
          description: '',
          price: 0,
          isAvailable: isAvailable,
        ),
      );
    } catch (e) {
      final index = _cachedMenu!.items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final updated = _cachedMenu!.items[index].copyWith(isAvailable: isAvailable);
        _cachedMenu = _cachedMenu!.copyWith(
          items: _cachedMenu!.items.map((i) => i.id == itemId ? updated : i).toList(),
        );
        return Right<Failure, MenuItem>(updated);
      }
      return Left<Failure, MenuItem>(ServerFailure('فشل تغيير حالة التوفر: $e'));
    }
  }
}
