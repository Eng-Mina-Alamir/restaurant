// `JsonKey` / `JsonSerializable` are applied inside the freezed constructor;
// the analyzer warnings are a false positive for this well-known freezed pattern.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_item.freezed.dart';
part 'menu_item.g.dart';

@freezed
abstract class MenuModifierOption with _$MenuModifierOption {
  const factory MenuModifierOption({
    required String id,
    required String name,
    @Default(0) double extraPrice,
    @Default(true) bool isAvailable,
  }) = _MenuModifierOption;

  factory MenuModifierOption.fromJson(Map<String, dynamic> json) =>
      _$MenuModifierOptionFromJson(json);
}

@freezed
abstract class MenuModifierGroup with _$MenuModifierGroup {
  @JsonSerializable(explicitToJson: true)
  const factory MenuModifierGroup({
    required String id,
    required String title,
    String? description,
    @Default(false) bool isRequired,
    @Default(1) int maxSelection,
    @Default(<MenuModifierOption>[]) List<MenuModifierOption> options,
  }) = _MenuModifierGroup;

  factory MenuModifierGroup.fromJson(Map<String, dynamic> json) =>
      _$MenuModifierGroupFromJson(json);
}

@freezed
abstract class MenuItem with _$MenuItem {
  @JsonSerializable(explicitToJson: true)
  const factory MenuItem({
    required String id,
    required String categoryId,
    required String name,
    required String description,
    required double price,
    String? imageUrl,
    @Default(true) bool isAvailable,
    @Default(false) bool isVegetarian,
    @Default(false) bool isSpicy,
    double? preparationTime,
    @Default(<MenuModifierGroup>[]) List<MenuModifierGroup> modifierGroups,
    double? rating,
    int? orderCount,
  }) = _MenuItem;

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
      _$MenuItemFromJson(json);
}
