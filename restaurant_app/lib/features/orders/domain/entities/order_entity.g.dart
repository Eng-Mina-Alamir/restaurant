// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderEntity _$OrderEntityFromJson(Map<String, dynamic> json) => _OrderEntity(
  id: json['id'] as String,
  restaurantId: json['restaurantId'] as String,
  customerId: json['customerId'] as String?,
  tableId: json['tableId'] as String?,
  waiterId: json['waiterId'] as String?,
  assignedKitchenId: json['assignedKitchenId'] as String?,
  driverId: json['driverId'] as String?,
  orderType: OrderType.fromName(json['orderType'] as String?),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OrderItem>[],
  status: _statusFromJson(json['status'] as String?),
  subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
  taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
  discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
  totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
  paymentMethod: _paymentFromJson(json['paymentMethod'] as String?),
  deliveryAddress: json['deliveryAddress'] as String?,
  deliveryNotes: json['deliveryNotes'] as String?,
  createdAt: dateTimeFromJson(json['createdAt']),
  completedAt: nullableDateTimeFromJson(json['completedAt']),
  estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
);

Map<String, dynamic> _$OrderEntityToJson(_OrderEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'restaurantId': instance.restaurantId,
      'customerId': instance.customerId,
      'tableId': instance.tableId,
      'waiterId': instance.waiterId,
      'assignedKitchenId': instance.assignedKitchenId,
      'driverId': instance.driverId,
      'orderType': _orderTypeToString(instance.orderType),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'status': _statusToString(instance.status),
      'subtotal': instance.subtotal,
      'taxAmount': instance.taxAmount,
      'discountAmount': instance.discountAmount,
      'totalAmount': instance.totalAmount,
      'paymentMethod': _paymentToString(instance.paymentMethod),
      'deliveryAddress': instance.deliveryAddress,
      'deliveryNotes': instance.deliveryNotes,
      'createdAt': dateTimeToJson(instance.createdAt),
      'completedAt': nullableDateTimeToJson(instance.completedAt),
      'estimatedMinutes': instance.estimatedMinutes,
    };
