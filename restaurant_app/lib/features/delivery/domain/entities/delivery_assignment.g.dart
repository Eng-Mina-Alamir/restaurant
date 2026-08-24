// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeliveryAssignment _$DeliveryAssignmentFromJson(Map<String, dynamic> json) =>
    _DeliveryAssignment(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      driverId: json['driverId'] as String,
      pickupTime: dateTimeFromJson(json['pickupTime']),
      deliveredTime: nullableDateTimeFromJson(json['deliveredTime']),
      deliveryLocation: json['deliveryLocation'] as String,
      customerPhone: json['customerPhone'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      deliveryStatus: _deliveryStatusFromJson(
        json['deliveryStatus'] as String?,
      ),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
      routeOptimized: json['routeOptimized'] as String?,
      routeDistanceMeters: (json['routeDistanceMeters'] as num?)?.toDouble(),
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      driverRating: (json['driverRating'] as num?)?.toDouble(),
      vehicleInfo: json['vehicleInfo'] as String?,
      assignmentMethod: json['assignmentMethod'] as String? ?? 'auto',
      assignedAt: nullableDateTimeFromJson(json['assignedAt']),
    );

Map<String, dynamic> _$DeliveryAssignmentToJson(_DeliveryAssignment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'driverId': instance.driverId,
      'pickupTime': dateTimeToJson(instance.pickupTime),
      'deliveredTime': nullableDateTimeToJson(instance.deliveredTime),
      'deliveryLocation': instance.deliveryLocation,
      'customerPhone': instance.customerPhone,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'deliveryStatus': _deliveryStatusToString(instance.deliveryStatus),
      'deliveryFee': instance.deliveryFee,
      'routeOptimized': instance.routeOptimized,
      'routeDistanceMeters': instance.routeDistanceMeters,
      'driverName': instance.driverName,
      'driverPhone': instance.driverPhone,
      'driverRating': instance.driverRating,
      'vehicleInfo': instance.vehicleInfo,
      'assignmentMethod': instance.assignmentMethod,
      'assignedAt': nullableDateTimeToJson(instance.assignedAt),
    };
