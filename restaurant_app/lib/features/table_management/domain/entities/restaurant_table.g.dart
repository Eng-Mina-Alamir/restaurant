// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_table.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RestaurantTable _$RestaurantTableFromJson(Map<String, dynamic> json) =>
    _RestaurantTable(
      id: json['id'] as String,
      tableNumber: (json['tableNumber'] as num).toInt(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      location: json['location'] as String? ?? 'صالة',
      status: _tableStatusFromJson(json['status'] as String?),
      currentOrderId: json['currentOrderId'] as String?,
      assignedWaiterId: json['assignedWaiterId'] as String?,
      lastUpdated: nullableDateTimeFromJson(json['lastUpdated']),
    );

Map<String, dynamic> _$RestaurantTableToJson(_RestaurantTable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tableNumber': instance.tableNumber,
      'capacity': instance.capacity,
      'location': instance.location,
      'status': _tableStatusToString(instance.status),
      'currentOrderId': instance.currentOrderId,
      'assignedWaiterId': instance.assignedWaiterId,
      'lastUpdated': nullableDateTimeToJson(instance.lastUpdated),
    };
