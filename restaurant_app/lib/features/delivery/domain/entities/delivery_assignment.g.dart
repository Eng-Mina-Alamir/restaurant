// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeliveryAssignmentImpl _$$DeliveryAssignmentImplFromJson(
  Map<String, dynamic> json,
) => _$DeliveryAssignmentImpl(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  driverId: json['driverId'] as String,
  pickupTime: dateTimeFromJson(json['pickupTime']),
  deliveredTime: nullableDateTimeFromJson(json['deliveredTime']),
  deliveryLocation: json['deliveryLocation'] as String,
  latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
  longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
  deliveryStatus: _deliveryStatusFromJson(json['deliveryStatus'] as String?),
  deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
  routeOptimized: json['routeOptimized'] as String?,
  routeDistanceMeters: (json['routeDistanceMeters'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$DeliveryAssignmentImplToJson(
  _$DeliveryAssignmentImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'driverId': instance.driverId,
  'pickupTime': dateTimeToJson(instance.pickupTime),
  'deliveredTime': nullableDateTimeToJson(instance.deliveredTime),
  'deliveryLocation': instance.deliveryLocation,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'deliveryStatus': _deliveryStatusToString(instance.deliveryStatus),
  'deliveryFee': instance.deliveryFee,
  'routeOptimized': instance.routeOptimized,
  'routeDistanceMeters': instance.routeDistanceMeters,
};
