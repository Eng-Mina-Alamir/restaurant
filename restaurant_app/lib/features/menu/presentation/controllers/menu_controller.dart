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
