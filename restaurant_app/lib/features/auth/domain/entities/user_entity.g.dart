// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserEntity _$UserEntityFromJson(Map<String, dynamic> json) => _UserEntity(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  role: _roleFromJson(json['role'] as String?),
  restaurantId: json['restaurantId'] as String?,
  token: json['token'] as String?,
  createdAt: dateTimeFromJson(json['createdAt']),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$UserEntityToJson(_UserEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'role': _roleToJson(instance.role),
      'restaurantId': instance.restaurantId,
      'token': instance.token,
      'createdAt': dateTimeToJson(instance.createdAt),
      'isActive': instance.isActive,
    };
