import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/menu.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';

/// Supabase-backed [MenuRepository].
///
/// Single source of truth is Supabase. No seed data is ever shown:
/// - empty tables => empty [Menu] (truthful empty, not fake items)
/// - network failure with no prior Supabase-loaded session data =>
///   [Left] so the UI shows an error + retry instead of fake content.
/// Previously persisted Hive mirror (which originated from Supabase) is kept
/// only as a stale fallback for staff continuity and is never mixed with seed.
///
/// Uses PostgREST embedded selects to fetch menu items with their modifier
/// groups and options in a single request (instead of 4 separate queries).
class SupabaseMenuRepositoryImpl implements MenuRepository {
  SupabaseMenuRepositoryImpl(this._supabase, [this._cache]);

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;
  Menu? _cachedMenu;

  final Map<String, String> _categoryIdToName = {};
  final Map<String, int> _categoryNameToId = {};

  static const String _cacheKey = 'cached_menu';

  /// PostgREST embedded select: fetches items with nested groups and options.
  static const String _menuItemsWithModifiers =
      '*, menu_modifier_groups(*, menu_modifier_options(*))';

  @override
  Future<Either<Failure, Menu>> getMenu() async {
    try {
      // Query 1: Fetch categories (small, stable table)
      final catResponse = await _supabase
          .from(SupabaseConfig.categoriesTable)
          .select()
          .order('sort_order', ascending: true);

      final List<String> categories = [];
      _categoryIdToName.clear();
      _categoryNameToId.clear();

      for (final raw in (catResponse as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final catName = (map['name_ar'] ?? map['name'])?.toString();
        final rawId = map['id'];
        if (catName != null && catName.isNotEmpty) {
          categories.add(catName);
          if (rawId != null) {
            _categoryIdToName[rawId.toString()] = catName;
            if (rawId is int) {
              _categoryNameToId[catName] = rawId;
            } else {
              final parsed = int.tryParse(rawId.toString());
              if (parsed != null) _categoryNameToId[catName] = parsed;
            }
          }
        }
      }

      // Query 2: Fetch menu items WITH embedded modifier groups & options
      // This replaces 3 separate queries (items + groups + options) with 1.
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
              name: optMap['name']?.toString() ?? '',
              extraPrice: (optMap['extra_price'] is num)
                  ? (optMap['extra_price'] as num).toDouble()
                  : (double.tryParse(optMap['extra_price']?.toString() ?? '') ??
                      0.0),
              isAvailable: optMap['is_available'] is bool
                  ? (optMap['is_available'] as bool)
                  : (optMap['is_available']?.toString().toLowerCase() !=
                      'false'),
            ));
          }

          modifierGroups.add(MenuModifierGroup(
            id: groupMap['id']?.toString() ?? '',
            title: groupMap['title']?.toString() ?? '',
            description: groupMap['description']?.toString(),
            isRequired: groupMap['is_required'] is bool
                ? (groupMap['is_required'] as bool)
                : false,
            maxSelection: (groupMap['max_selection'] is num)
                ? (groupMap['max_selection'] as num).toInt()
                : (int.tryParse(groupMap['max_selection']?.toString() ?? '') ??
                    1),
            options: options,
          ));
        }

        // Map integer category_id to human-readable category name so that UI
        // filtering by category name (e.g. 'مشويات', 'مقبلات') works seamlessly.
        final rawCat = map['category_id']?.toString();
        final resolvedCategory =
            (rawCat != null && _categoryIdToName.containsKey(rawCat))
                ? _categoryIdToName[rawCat]!
                : (rawCat ?? 'عام');

        items.add(
          MenuItem(
            id: itemId,
            categoryId: resolvedCategory,
            name: map['name']?.toString() ?? '',
            description: map['description']?.toString() ?? '',
            price: (map['price'] is num)
                ? (map['price'] as num).toDouble()
                : (double.tryParse(map['price']?.toString() ?? '') ?? 0.0),
            imageUrl: map['image_url']?.toString(),
            isAvailable: map['is_available'] is bool
                ? (map['is_available'] as bool)
                : (map['is_available']?.toString().toLowerCase() != 'false'),
            isVegetarian: map['is_vegetarian'] is bool
                ? (map['is_vegetarian'] as bool)
                : (map['is_vegetarian']?.toString().toLowerCase() == 'true'),
            isSpicy: map['is_spicy'] is bool
                ? (map['is_spicy'] as bool)
                : (map['is_spicy']?.toString().toLowerCase() == 'true'),
            preparationTime: (map['preparation_time'] is num)
                ? (map['preparation_time'] as num).toDouble()
                : double.tryParse(map['preparation_time']?.toString() ?? ''),
            rating: (map['rating'] is num)
                ? (map['rating'] as num).toDouble()
                : (double.tryParse(map['rating']?.toString() ?? '') ?? 5.0),
            orderCount: (map['order_count'] is num)
                ? (map['order_count'] as num).toInt()
                : (int.tryParse(map['order_count']?.toString() ?? '') ?? 0),
            modifierGroups: modifierGroups,
          ),
        );
      }

      if (items.isEmpty && categories.isEmpty) {
        const empty = Menu(
          restaurantId: SupabaseConfig.defaultRestaurantId,
          categories: [],
          items: [],
        );
        _cachedMenu = empty;
        return const Right<Failure, Menu>(empty);
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
      await _persistCache();
      return Right<Failure, Menu>(menu);
    } catch (e) {
      AppLogger.warning('Supabase getMenu failed: $e');
      final fallback = _loadFromPersistentCache();
      if (fallback != null && fallback.items.isNotEmpty) {
        _cachedMenu = fallback;
        return Right<Failure, Menu>(fallback);
      }
      return Left<Failure, Menu>(
        ServerFailure('فشل تحميل القائمة من Supabase: $e'),
      );
    }
  }

  Menu? _loadFromPersistentCache() {
    final cache = _cache;
    if (cache == null) return null;
    try {
      final raw = cache.readString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Menu.fromJson(json);
    } catch (e) {
      AppLogger.warning('Failed to read menu from local cache: $e');
      return null;
    }
  }

  Future<void> _persistCache() async {
    final cache = _cache;
    final menu = _cachedMenu;
    if (cache != null && menu != null) {
      try {
        await cache.writeString(_cacheKey, jsonEncode(menu.toJson()));
      } catch (_) {}
    }
  }

  void _ensureCache() {
    _cachedMenu ??= _loadFromPersistentCache() ??
        const Menu(
          restaurantId: SupabaseConfig.defaultRestaurantId,
          categories: [],
          items: [],
        );
  }

  @override
  Future<Either<Failure, MenuItem>> addMenuItem(MenuItem item) async {
    _ensureCache();
    try {
      int? catId = _categoryNameToId[item.categoryId] ??
          int.tryParse(item.categoryId);
      if (catId == null && item.categoryId.isNotEmpty) {
        final existingCat = await _supabase
            .from(SupabaseConfig.categoriesTable)
            .select('id')
            .or('name.eq.${item.categoryId},name_ar.eq.${item.categoryId}')
            .maybeSingle();
        if (existingCat != null && existingCat['id'] != null) {
          catId = int.tryParse(existingCat['id'].toString());
        }
      }
      catId ??= 1;

      final insertData = <String, dynamic>{
        'category_id': catId,
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'image_url': item.imageUrl,
        'is_available': item.isAvailable,
        'is_vegetarian': item.isVegetarian,
        'is_spicy': item.isSpicy,
      };
      if (item.preparationTime != null) {
        insertData['preparation_time'] = item.preparationTime;
      }

      final response = await _supabase
          .from(SupabaseConfig.menuItemsTable)
          .insert(insertData)
          .select('id')
          .single();

      final generatedId = response['id']?.toString() ?? item.id;
      final savedItem = item.copyWith(id: generatedId);

      _cachedMenu = _cachedMenu!.copyWith(
        items: [
          ..._cachedMenu!.items.where((i) => i.id != savedItem.id),
          savedItem
        ],
      );
      await _persistCache();
      return Right<Failure, MenuItem>(savedItem);
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
      int? catId = _categoryNameToId[item.categoryId] ??
          int.tryParse(item.categoryId);
      final updateData = <String, dynamic>{
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'image_url': item.imageUrl,
        'is_available': item.isAvailable,
        'is_vegetarian': item.isVegetarian,
        'is_spicy': item.isSpicy,
      };
      if (catId != null) {
        updateData['category_id'] = catId;
      }
      if (item.preparationTime != null) {
        updateData['preparation_time'] = item.preparationTime;
      }

      final parsedId = int.tryParse(item.id);
      if (parsedId != null) {
        await _supabase
            .from(SupabaseConfig.menuItemsTable)
            .update(updateData)
            .eq('id', parsedId);
      } else {
        await _supabase
            .from(SupabaseConfig.menuItemsTable)
            .update(updateData)
            .eq('id', item.id);
      }

      _cachedMenu = _cachedMenu!.copyWith(
        items: _cachedMenu!.items
            .map((i) => i.id == item.id ? item : i)
            .toList(),
      );
      await _persistCache();
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
      final parsedId = int.tryParse(itemId);
      if (parsedId != null) {
        await _supabase
            .from(SupabaseConfig.menuItemsTable)
            .delete()
            .eq('id', parsedId);
      } else {
        await _supabase
            .from(SupabaseConfig.menuItemsTable)
            .delete()
            .eq('id', itemId);
      }
      _cachedMenu = _cachedMenu!.copyWith(
        items: _cachedMenu!.items.where((i) => i.id != itemId).toList(),
      );
      await _persistCache();
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
      final parsedId = int.tryParse(itemId);
      if (parsedId != null) {
        await _supabase
            .from(SupabaseConfig.menuItemsTable)
            .update({'is_available': isAvailable})
            .eq('id', parsedId);
      } else {
        await _supabase
            .from(SupabaseConfig.menuItemsTable)
            .update({'is_available': isAvailable})
            .eq('id', itemId);
      }

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
        await _persistCache();
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
      return Left<Failure, MenuItem>(
        ServerFailure('فشل تغيير حالة التوفر: $e'),
      );
    }
  }
}

