// `JsonKey` is applied inside the freezed constructor; the analyzer warning is
// a false positive for this well-known freezed pattern.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/date_converters.dart';
import '../../../../core/domain/enums.dart';

part 'restaurant_table.freezed.dart';
part 'restaurant_table.g.dart';

@freezed
abstract class RestaurantTable with _$RestaurantTable {
  const factory RestaurantTable({
    required String id,
    required int tableNumber,
    @Default(4) int capacity,

    /// Physical zone/location of the table (e.g. "صالة", "حديقة", "تراس").
    @Default('صالة') String location,
    @JsonKey(
      fromJson: _tableStatusFromJson,
      toJson: _tableStatusToString,
      includeIfNull: false,
    )
    required TableStatus status,
    String? currentOrderId,
    String? assignedWaiterId,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? lastUpdated,
  }) = _RestaurantTable;

  factory RestaurantTable.fromJson(Map<String, dynamic> json) =>
      _$RestaurantTableFromJson(json);
}

TableStatus _tableStatusFromJson(String? name) => TableStatus.fromName(name);
String _tableStatusToString(TableStatus value) => value.name;
