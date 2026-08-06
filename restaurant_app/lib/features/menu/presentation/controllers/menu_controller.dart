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

/// Derives the visible [MenuItem]s for [menu] under [selectedCategory].
List<MenuItem> filterMenu(Menu? menu, String selectedCategory) {
  if (menu == null || selectedCategory == kAllCategoriesFilter) {
    return menu?.items ?? const <MenuItem>[];
  }
  return menu.itemsIn(selectedCategory);
}
