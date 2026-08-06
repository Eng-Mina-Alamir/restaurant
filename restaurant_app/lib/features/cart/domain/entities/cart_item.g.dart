// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CartItemImpl _$$CartItemImplFromJson(Map<String, dynamic> json) =>
    _$CartItemImpl(
      menuItem: MenuItem.fromJson(json['menuItem'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      selectedModifiers:
          (json['selectedModifiers'] as List<dynamic>?)
              ?.map(
                (e) => MenuModifierOption.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <MenuModifierOption>[],
      specialNotes: json['specialNotes'] as String?,
    );

Map<String, dynamic> _$$CartItemImplToJson(_$CartItemImpl instance) =>
    <String, dynamic>{
      'menuItem': instance.menuItem,
      'quantity': instance.quantity,
      'selectedModifiers': instance.selectedModifiers,
      'specialNotes': instance.specialNotes,
    };
