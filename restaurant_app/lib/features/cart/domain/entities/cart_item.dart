import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../menu/domain/entities/menu_item.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

/// A line item in the customer's cart.
///
/// Distinct from [OrderItem] (which is persisted on an order): a [CartItem] is
/// a mutable work-in-progress entry that the cart state and UI operate on.
@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    required MenuItem menuItem,
    @Default(1) int quantity,
    @Default(<MenuModifierOption>[]) List<MenuModifierOption> selectedModifiers,
    String? specialNotes,
  }) = _CartItem;

  const CartItem._();

  /// Price of one unit including the selected modifier surcharges.
  double get unitPrice =>
      menuItem.price +
      selectedModifiers.fold<double>(0, (sum, m) => sum + m.extraPrice);

  /// Total for the ordered quantity.
  double get linePrice => unitPrice * quantity;

  /// A stable identity based on the item id and the selected modifier ids.
  ///
  /// Used to merge cart entries: two [CartItem]s with the same key represent
  /// the same "product configuration" and can be combined by quantity.
  String get configKey {
    final modifierIds = selectedModifiers.map((m) => m.id).toList()..sort();
    return '${menuItem.id}|${modifierIds.join(',')}';
  }

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}
