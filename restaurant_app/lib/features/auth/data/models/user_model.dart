// The `JsonKey` annotation is applied inside the freezed constructor, which
// triggers the `invalid_annotation_target` analyzer warning even though the
// annotation is correctly forwarded to the generated field/getter.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/date_converters.dart';
import '../../../../core/domain/enums.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Data-transfer object representing a user as returned by the auth API.
///
/// Mirrors [UserEntity]'s JSON contract (same fields/serialization) so the
/// entity and DTO can be mapped 1:1 at the repository boundary.
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
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
  }) = _UserModel;

  /// Private constructor that lets the generated class `extend` this abstract
  /// class, so custom methods (e.g. [toEntity]) are inherited by the concrete
  /// implementation. See freezed docs on "adding getters and methods".
  const UserModel._();

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Converts this DTO into the domain [UserEntity].
  UserEntity toEntity() => UserEntity(
    id: id,
    name: name,
    email: email,
    phone: phone,
    role: role,
    restaurantId: restaurantId,
    token: token,
    createdAt: createdAt,
    isActive: isActive,
  );
}

UserRole _roleFromJson(String? name) => UserRole.fromName(name);
String _roleToJson(UserRole role) => role.name;
