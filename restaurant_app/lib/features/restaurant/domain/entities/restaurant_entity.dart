// `JsonSerializable` is applied inside the freezed constructor; the analyzer
// warning is a false positive for this well-known freezed pattern.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'restaurant_entity.freezed.dart';
part 'restaurant_entity.g.dart';

@freezed
abstract class BusinessHours with _$BusinessHours {
  const factory BusinessHours({
    @Default('10:00') String openTime,
    @Default('23:00') String closeTime,
  }) = _BusinessHours;

  factory BusinessHours.fromJson(Map<String, dynamic> json) =>
      _$BusinessHoursFromJson(json);
}

@freezed
abstract class RestaurantEntity with _$RestaurantEntity {
  @JsonSerializable(explicitToJson: true)
  const factory RestaurantEntity({
    required String id,
    required String name,
    required String address,
    required String phone,
    @Default(0) double latitude,
    @Default(0) double longitude,
    String? logoUrl,
    @Default(BusinessHours()) BusinessHours hours,
    @Default(0) int totalTables,
    @Default(<String>[]) List<String> categories,
  }) = _RestaurantEntity;

  factory RestaurantEntity.fromJson(Map<String, dynamic> json) =>
      _$RestaurantEntityFromJson(json);
}
