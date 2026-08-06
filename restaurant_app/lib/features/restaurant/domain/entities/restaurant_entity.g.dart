// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BusinessHoursImpl _$$BusinessHoursImplFromJson(Map<String, dynamic> json) =>
    _$BusinessHoursImpl(
      openTime: json['openTime'] as String? ?? '10:00',
      closeTime: json['closeTime'] as String? ?? '23:00',
    );

Map<String, dynamic> _$$BusinessHoursImplToJson(_$BusinessHoursImpl instance) =>
    <String, dynamic>{
      'openTime': instance.openTime,
      'closeTime': instance.closeTime,
    };

_$RestaurantEntityImpl _$$RestaurantEntityImplFromJson(
  Map<String, dynamic> json,
) => _$RestaurantEntityImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  phone: json['phone'] as String,
  latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
  longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
  logoUrl: json['logoUrl'] as String?,
  hours: json['hours'] == null
      ? const BusinessHours()
      : BusinessHours.fromJson(json['hours'] as Map<String, dynamic>),
  totalTables: (json['totalTables'] as num?)?.toInt() ?? 0,
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$$RestaurantEntityImplToJson(
  _$RestaurantEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'phone': instance.phone,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'logoUrl': instance.logoUrl,
  'hours': instance.hours.toJson(),
  'totalTables': instance.totalTables,
  'categories': instance.categories,
};
