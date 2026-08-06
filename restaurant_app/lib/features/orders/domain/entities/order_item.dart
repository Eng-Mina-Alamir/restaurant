// `JsonKey` is applied inside the freezed constructor; the analyzer warning is
// a false positive for this well-known freezed pattern.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/date_converters.dart';
import '../../../menu/domain/entities/menu_item.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

/// A single line-item inside an order (equivalent to the spec `CartItem`).
@freezed
abstract class OrderItem with _$OrderItem {
  @JsonSerializable(explicitToJson: true)
  const factory OrderItem({
    required MenuItem menuItem,
    required int quantity,
    @Default(<MenuModifierOption>[]) List<MenuModifierOption> selectedModifiers,
    String? specialNotes,
    @Default(0) double itemTotal,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime addedAt,
  }) = _OrderItem;

  const OrderItem._();

  /// Computed unit total including selected modifier surcharges.
  double get unitTotal =>
      menuItem.price +
      selectedModifiers.fold<double>(0, (sum, m) => sum + m.extraPrice);

  /// Computed line total for the ordered quantity.
  double get lineTotal => (itemTotal == 0 ? unitTotal * quantity : itemTotal);

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}
