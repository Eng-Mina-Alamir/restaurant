import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/menu.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';

/// Supabase-backed [MenuRepository] with Hive cache-aside persistence.
///
/// Uses PostgREST embedded selects to fetch menu items with their modifier
/// groups and options in a single request, writes to Hive cache on success,
/// and reads from Hive cache when network is offline.
class SupabaseMenuRepositoryImpl implements MenuRepository {
  SupabaseMenuRepositoryImpl(this._supabase, [this._cache]);

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;
  Menu? _cachedMenu;

  static const String _categoriesCacheKey = 'menu_categories_v1';
  static const String _itemsCacheKey = 'menu_items_v1';

  /// PostgREST embedded select: fetches items with nested groups and options.
  static const String _menuItemsWithModifiers =
      '*, menu_modifier_groups(*, menu_modifier_options(*))';

  @override
  Future<Either<Failure, Menu>> getMenu() async {
    try {
      // Query 1: Fetch categories
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

      // Query 2: Fetch menu items WITH embedded modifier groups & options
      final itemResponse = await _supabase
          .from(SupabaseConfig.menuItemsTable)
          .select(_menuItemsWithModifiers);

      final List<MenuItem> items = [];
      for (final raw in (itemResponse as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final itemId = map['id']?.toString() ?? '';

        // Parse embedded modifier groups
        final List<MenuModifierGroup> modifierGroups = [];
        final groupsRaw = map['menu_modifier_groups'] as List? ?? const [];
        for (final groupRaw in groupsRaw) {
          final groupMap = Map<String, dynamic>.from(groupRaw as Map);

          // Parse embedded modifier options within each group
          final List<MenuModifierOption> options = [];
          final optionsRaw =
              groupMap['menu_modifier_options'] as List? ?? const [];
          for (final optRaw in optionsRaw) {
            final optMap = Map<String, dynamic>.from(optRaw as Map);
            options.add(MenuModifierOption(
              id: optMap['id']?.toString() ?? '',
              name: optMap['name'] as String? ?? '',
              extraPrice: (optMap['extra_price'] as num?)?.toDouble() ?? 0.0,
              isAvailable: optMap['is_available'] as bool? ?? true,
            ));
          }

          modifierGroups.add(MenuModifierGroup(
            id: groupMap['id']?.toString() ?? '',
            title: groupMap['title'] as String? ?? '',
            description: groupMap['description'] as String?,
            isRequired: groupMap['is_required'] as bool? ?? false,
            maxSelection: (groupMap['max_selection'] as num?)?.toInt() ?? 1,
            options: options,
          ));
        }

        items.add(
          MenuItem(
            id: itemId,
            categoryId: map['category_id']?.toString() ?? 'عام',
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
            modifierGroups: modifierGroups,
          ),
        );
      }

      final resolvedCategories = categories.isNotEmpty
          ? categories
          : items.map((e) => e.categoryId).toSet().toList();

      final menu = Menu(
        restaurantId: SupabaseConfig.defaultRestaurantId,
        categories: resolvedCategories,
        items: items,
      );
      _cachedMenu = menu;

      // Write-through cache to Hive
      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _categoriesCacheKey,
          resolvedCategories.map((c) => {'name': c}).toList(),
        );
        await cache.writeList(
          _itemsCacheKey,
          items.map((i) => i.toJson()).toList(),
        );
      }

      return Right<Failure, Menu>(menu);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase getMenu failed: $e, reading from local cache',
        error: e,
        stackTrace: st,
      );

      final cache = _cache;
      if (cache != null) {
        final cachedCats = cache.readList(_categoriesCacheKey);
        final cachedItems = cache.readList(_itemsCacheKey);

        if (cachedItems.isNotEmpty || cachedCats.isNotEmpty) {
          final items = cachedItems
              .map((map) => MenuItem.fromJson(map))
              .toList();
          final categories = cachedCats
              .map((map) => map['name'] as String? ?? '')
              .where((c) => c.isNotEmpty)
              .toList();

          final fallback = Menu(
            restaurantId: SupabaseConfig.defaultRestaurantId,
            categories: categories.isNotEmpty
                ? categories
                : items.map((e) => e.categoryId).toSet().toList(),
            items: items,
          );
          _cachedMenu = fallback;
          return Right<Failure, Menu>(fallback);
        }
      }

      final emptyMenu = _cachedMenu ??
          const Menu(
            restaurantId: SupabaseConfig.defaultRestaurantId,
            categories: [],
            items: [],
          );
      return Right<Failure, Menu>(emptyMenu);
    }
  }

  void _ensureCache() {
    _cachedMenu ??= const Menu(
      restaurantId: SupabaseConfig.defaultRestaurantId,
      categories: [],
      items: [],
    );
  }

  @override
  Future<Either<Failure, MenuItem>> addMenuItem(MenuItem item) async {
    _ensureCache();
    try {
      final response = await _supabase.from(SupabaseConfig.menuItemsTable).insert({
        'category_id': item.categoryId,
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'image_url': item.imageUrl,
        'is_available': item.isAvailable,
        'is_vegetarian': item.isVegetarian,
        'is_spicy': item.isSpicy,
        'preparation_time': item.preparationTime,
      }).select().single();

      final created = item.copyWith(
        id: response['id']?.toString() ?? item.id,
      );

      _cachedMenu = _cachedMenu!.copyWith(
        items: [..._cachedMenu!.items.where((i) => i.id != created.id), created],
      );
      return Right<Failure, MenuItem>(created);
    } catch (e) {
      AppLogger.error('Supabase addMenuItem error: $e');
      return Left<Failure, MenuItem>(
        ServerFailure('فشل إضافة الصنف: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MenuItem>> updateMenuItem(MenuItem item) async {
    _ensureCache();
    try {
      await _supabase
          .from(SupabaseConfig.menuItemsTable)
          .update({
            'category_id': item.categoryId,
            'name': item.name,
            'description': item.description,
            'price': item.price,
            'image_url': item.imageUrl,
            'is_available': item.isAvailable,
            'is_vegetarian': item.isVegetarian,
            'is_spicy': item.isSpicy,
            'preparation_time': item.preparationTime,
          })
          .eq('id', item.id);
      _cachedMenu = _cachedMenu!.copyWith(
        items: _cachedMenu!.items
            .map((i) => i.id == item.id ? item : i)
            .toList(),
      );
      return Right<Failure, MenuItem>(item);
    } catch (e) {
      AppLogger.error('Supabase updateMenuItem error: $e');
      return Left<Failure, MenuItem>(
        ServerFailure('فشل تحديث الصنف: $e'),
      );
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
      AppLogger.error('Supabase deleteMenuItem error: $e');
      return Left<Failure, void>(
        ServerFailure('فشل حذف الصنف: $e'),
      );
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
      AppLogger.error('Supabase addCategory error: $e');
      return Left<Failure, void>(
        ServerFailure('فشل إضافة الفئة: $e'),
      );
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
        categories: _cachedMenu!.categories
            .where((c) => c != categoryName)
            .toList(),
      );
      return const Right<Failure, void>(null);
    } catch (e) {
      AppLogger.error('Supabase deleteCategory error: $e');
      return Left<Failure, void>(
        ServerFailure('فشل حذف الفئة: $e'),
      );
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
        final updated = _cachedMenu!.items[index].copyWith(
          isAvailable: isAvailable,
        );
        _cachedMenu = _cachedMenu!.copyWith(
          items: _cachedMenu!.items
              .map((i) => i.id == itemId ? updated : i)
              .toList(),
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
        final updated = _cachedMenu!.items[index].copyWith(
          isAvailable: isAvailable,
        );
        _cachedMenu = _cachedMenu!.copyWith(
          items: _cachedMenu!.items
              .map((i) => i.id == itemId ? updated : i)
              .toList(),
        );
        return Right<Failure, MenuItem>(updated);
      }
      return Left<Failure, MenuItem>(
        ServerFailure('فشل تغيير حالة التوفر: $e'),
      );
    }
  }
}
