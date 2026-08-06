// The `JsonKey` annotation is applied inside the freezed constructor, which
// triggers the `invalid_annotation_target` analyzer warning even though the
// annotation is correctly forwarded to the generated field/getter.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/date_converters.dart';
import '../../../../core/domain/enums.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

// Make UserRole visible to json_serializable via the enum converter below.
@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    required String phone,
    @JsonKey(fromJson: _roleFromJson, toJson: _roleToJson)
    required UserRole role,
    String? restaurantId,
    String? token,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime createdAt,
    @Default(true) bool isActive,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
}

UserRole _roleFromJson(String? name) => UserRole.fromName(name);
String _roleToJson(UserRole role) => role.name;
