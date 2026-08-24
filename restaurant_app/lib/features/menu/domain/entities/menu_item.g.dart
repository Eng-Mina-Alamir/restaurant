// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MenuModifierOption _$MenuModifierOptionFromJson(Map<String, dynamic> json) =>
    _MenuModifierOption(
      id: json['id'] as String,
      name: json['name'] as String,
      extraPrice: (json['extraPrice'] as num?)?.toDouble() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );

Map<String, dynamic> _$MenuModifierOptionToJson(_MenuModifierOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'extraPrice': instance.extraPrice,
      'isAvailable': instance.isAvailable,
    };

_MenuModifierGroup _$MenuModifierGroupFromJson(Map<String, dynamic> json) =>
    _MenuModifierGroup(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isRequired: json['isRequired'] as bool? ?? false,
      maxSelection: (json['maxSelection'] as num?)?.toInt() ?? 1,
      options:
          (json['options'] as List<dynamic>?)
              ?.map(
                (e) => MenuModifierOption.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <MenuModifierOption>[],
    );

Map<String, dynamic> _$MenuModifierGroupToJson(_MenuModifierGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'isRequired': instance.isRequired,
      'maxSelection': instance.maxSelection,
      'options': instance.options.map((e) => e.toJson()).toList(),
    };

_MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => _MenuItem(
  id: json['id'] as String,
  categoryId: json['categoryId'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  imageUrl: json['imageUrl'] as String?,
  isAvailable: json['isAvailable'] as bool? ?? true,
  isVegetarian: json['isVegetarian'] as bool? ?? false,
  isSpicy: json['isSpicy'] as bool? ?? false,
  preparationTime: (json['preparationTime'] as num?)?.toDouble(),
  modifierGroups:
      (json['modifierGroups'] as List<dynamic>?)
          ?.map((e) => MenuModifierGroup.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MenuModifierGroup>[],
  rating: (json['rating'] as num?)?.toDouble(),
  orderCount: (json['orderCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$MenuItemToJson(_MenuItem instance) => <String, dynamic>{
  'id': instance.id,
  'categoryId': instance.categoryId,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'imageUrl': instance.imageUrl,
  'isAvailable': instance.isAvailable,
  'isVegetarian': instance.isVegetarian,
  'isSpicy': instance.isSpicy,
  'preparationTime': instance.preparationTime,
  'modifierGroups': instance.modifierGroups.map((e) => e.toJson()).toList(),
  'rating': instance.rating,
  'orderCount': instance.orderCount,
};
