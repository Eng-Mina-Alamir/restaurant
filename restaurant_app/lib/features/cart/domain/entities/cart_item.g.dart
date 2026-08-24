// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CartItem _$CartItemFromJson(Map<String, dynamic> json) => _CartItem(
  menuItem: MenuItem.fromJson(json['menuItem'] as Map<String, dynamic>),
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  selectedModifiers:
      (json['selectedModifiers'] as List<dynamic>?)
          ?.map((e) => MenuModifierOption.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MenuModifierOption>[],
  specialNotes: json['specialNotes'] as String?,
);

Map<String, dynamic> _$CartItemToJson(_CartItem instance) => <String, dynamic>{
  'menuItem': instance.menuItem,
  'quantity': instance.quantity,
  'selectedModifiers': instance.selectedModifiers,
  'specialNotes': instance.specialNotes,
};
