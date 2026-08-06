import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/menu.dart';
import '../../domain/entities/menu_item.dart';

/// Sentinel category id meaning "show all items".
const String kAllCategoriesFilter = 'all';

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

/// Derives the visible [MenuItem]s for [menu] under [selectedCategory],
/// further narrowed by [query] (matched against name/description).
List<MenuItem> filterMenu(
  Menu? menu,
  String selectedCategory, [
  String query = '',
]) {
  final visible = menu == null || selectedCategory == kAllCategoriesFilter
      ? menu?.items ?? const <MenuItem>[]
      : menu.itemsIn(selectedCategory);

  final q = query.trim().toLowerCase();
  if (q.isEmpty) return visible;
  return visible
      .where(
        (i) =>
            i.name.toLowerCase().contains(q) ||
            i.description.toLowerCase().contains(q),
      )
      .toList();
}
