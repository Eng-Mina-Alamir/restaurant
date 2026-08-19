import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/menu.dart';
import '../../domain/entities/menu_item.dart';

/// Sentinel category id meaning "show all items".
const String kAllCategoriesFilter = 'all';

/// Dietary filter: no restriction, vegetarian only, or spicy only.
enum MenuDietFilter {
  none,
  vegetarian,
  spicy;

  bool matches(MenuItem item) => switch (this) {
    MenuDietFilter.none => true,
    MenuDietFilter.vegetarian => item.isVegetarian,
    MenuDietFilter.spicy => item.isSpicy,
  };
}

/// Loads and holds the restaurant [Menu].
///
/// Uses an [AsyncNotifier] so the UI can react to loading/error/data states.
class MenuController extends AsyncNotifier<Menu> {
  @override
  Future<Menu> build() async {
    final result = await ref.watch(menuRepositoryProvider).getMenu();
    return result.when(
      onLeft: (failure) =>
          throw AsyncError(failure.message, StackTrace.current),
      onRight: (menu) => menu,
    );
  }

  /// Adds a new menu item and refreshes state.
  Future<void> addItem(MenuItem item) async {
    final repo = ref.read(menuRepositoryProvider);
    final result = await repo.addMenuItem(item);
    result.when(
      onLeft: (_) => null,
      onRight: (_) => ref.invalidateSelf(),
    );
  }

  /// Updates an existing menu item and refreshes state.
  Future<void> updateItem(MenuItem item) async {
    final repo = ref.read(menuRepositoryProvider);
    final result = await repo.updateMenuItem(item);
    result.when(
      onLeft: (_) => null,
      onRight: (_) => ref.invalidateSelf(),
    );
  }

  /// Deletes a menu item by [itemId].
  Future<void> deleteItem(String itemId) async {
    final repo = ref.read(menuRepositoryProvider);
    final result = await repo.deleteMenuItem(itemId);
    result.when(
      onLeft: (_) => null,
      onRight: (_) => ref.invalidateSelf(),
    );
  }

  /// Toggles availability of [itemId].
  Future<void> toggleAvailability(String itemId, bool isAvailable) async {
    final repo = ref.read(menuRepositoryProvider);
    final result = await repo.toggleAvailability(itemId, isAvailable);
    result.when(
      onLeft: (_) => null,
      onRight: (_) => ref.invalidateSelf(),
    );
  }

  /// Adds a new category.
  Future<void> addCategory(String categoryName) async {
    final repo = ref.read(menuRepositoryProvider);
    final result = await repo.addCategory(categoryName);
    result.when(
      onLeft: (_) => null,
      onRight: (_) => ref.invalidateSelf(),
    );
  }

  /// Deletes a category by [categoryName].
  Future<void> deleteCategory(String categoryName) async {
    final repo = ref.read(menuRepositoryProvider);
    final result = await repo.deleteCategory(categoryName);
    result.when(
      onLeft: (_) => null,
      onRight: (_) => ref.invalidateSelf(),
    );
  }
}


final menuControllerProvider = AsyncNotifierProvider<MenuController, Menu>(
  MenuController.new,
);

/// The currently selected category filter (`kAllCategoriesFilter` = all).
final selectedCategoryProvider = StateProvider<String>(
  (ref) => kAllCategoriesFilter,
);

/// The active free-text search query (empty = no filtering).
final menuSearchQueryProvider = StateProvider<String>((ref) => '');

/// The active dietary filter (defaults to no restriction).
final menuDietFilterProvider = StateProvider<MenuDietFilter>(
  (ref) => MenuDietFilter.none,
);

/// Derives the visible [MenuItem]s for [menu] under [selectedCategory],
/// further narrowed by [query] (matched against name/description) and by
/// [diet] (vegetarian/spicy restrictions).
List<MenuItem> filterMenu(
  Menu? menu,
  String selectedCategory, [
  String query = '',
  MenuDietFilter diet = MenuDietFilter.none,
]) {
  final visible = menu == null || selectedCategory == kAllCategoriesFilter
      ? menu?.items ?? const <MenuItem>[]
      : menu.itemsIn(selectedCategory);

  final q = query.trim().toLowerCase();
  return visible.where((item) {
    final matchesQuery =
        q.isEmpty ||
        item.name.toLowerCase().contains(q) ||
        item.description.toLowerCase().contains(q);
    return matchesQuery && diet.matches(item);
  }).toList();
}
