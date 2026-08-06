import 'package:freezed_annotation/freezed_annotation.dart';

import 'menu_item.dart';

part 'menu.freezed.dart';
part 'menu.g.dart';

/// Aggregate view of a restaurant's menu: the ordered categories and the items
/// belonging to each.
@freezed
abstract class Menu with _$Menu {
  const factory Menu({
    required String restaurantId,
    @Default(<String>[]) List<String> categories,
    @Default(<MenuItem>[]) List<MenuItem> items,
  }) = _Menu;

  const Menu._();

  /// Returns items whose [MenuItem.categoryId] matches [categoryId].
  List<MenuItem> itemsIn(String categoryId) =>
      items.where((item) => item.categoryId == categoryId).toList();

  factory Menu.fromJson(Map<String, dynamic> json) => _$MenuFromJson(json);
}
