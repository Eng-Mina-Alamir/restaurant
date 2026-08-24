// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => _OrderItem(
  menuItem: MenuItem.fromJson(json['menuItem'] as Map<String, dynamic>),
  quantity: (json['quantity'] as num).toInt(),
  selectedModifiers:
      (json['selectedModifiers'] as List<dynamic>?)
          ?.map((e) => MenuModifierOption.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MenuModifierOption>[],
  specialNotes: json['specialNotes'] as String?,
  itemTotal: (json['itemTotal'] as num?)?.toDouble() ?? 0,
  addedAt: dateTimeFromJson(json['addedAt']),
);

Map<String, dynamic> _$OrderItemToJson(_OrderItem instance) =>
    <String, dynamic>{
      'menuItem': instance.menuItem.toJson(),
      'quantity': instance.quantity,
      'selectedModifiers': instance.selectedModifiers
          .map((e) => e.toJson())
          .toList(),
      'specialNotes': instance.specialNotes,
      'itemTotal': instance.itemTotal,
      'addedAt': dateTimeToJson(instance.addedAt),
    };
