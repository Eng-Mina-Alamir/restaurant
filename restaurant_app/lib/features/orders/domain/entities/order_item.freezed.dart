// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderItem {

 MenuItem get menuItem; int get quantity; List<MenuModifierOption> get selectedModifiers; String? get specialNotes; double get itemTotal;@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime get addedAt;
/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderItemCopyWith<OrderItem> get copyWith => _$OrderItemCopyWithImpl<OrderItem>(this as OrderItem, _$identity);

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderItem&&(identical(other.menuItem, menuItem) || other.menuItem == menuItem)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&const DeepCollectionEquality().equals(other.selectedModifiers, selectedModifiers)&&(identical(other.specialNotes, specialNotes) || other.specialNotes == specialNotes)&&(identical(other.itemTotal, itemTotal) || other.itemTotal == itemTotal)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,menuItem,quantity,const DeepCollectionEquality().hash(selectedModifiers),specialNotes,itemTotal,addedAt);

@override
String toString() {
  return 'OrderItem(menuItem: $menuItem, quantity: $quantity, selectedModifiers: $selectedModifiers, specialNotes: $specialNotes, itemTotal: $itemTotal, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class $OrderItemCopyWith<$Res>  {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) _then) = _$OrderItemCopyWithImpl;
@useResult
$Res call({
 MenuItem menuItem, int quantity, List<MenuModifierOption> selectedModifiers, String? specialNotes, double itemTotal,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime addedAt
});


$MenuItemCopyWith<$Res> get menuItem;

}
/// @nodoc
class _$OrderItemCopyWithImpl<$Res>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._self, this._then);

  final OrderItem _self;
  final $Res Function(OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? menuItem = null,Object? quantity = null,Object? selectedModifiers = null,Object? specialNotes = freezed,Object? itemTotal = null,Object? addedAt = null,}) {
  return _then(_self.copyWith(
menuItem: null == menuItem ? _self.menuItem : menuItem // ignore: cast_nullable_to_non_nullable
as MenuItem,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,selectedModifiers: null == selectedModifiers ? _self.selectedModifiers : selectedModifiers // ignore: cast_nullable_to_non_nullable
as List<MenuModifierOption>,specialNotes: freezed == specialNotes ? _self.specialNotes : specialNotes // ignore: cast_nullable_to_non_nullable
as String?,itemTotal: null == itemTotal ? _self.itemTotal : itemTotal // ignore: cast_nullable_to_non_nullable
as double,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MenuItemCopyWith<$Res> get menuItem {
  
  return $MenuItemCopyWith<$Res>(_self.menuItem, (value) {
    return _then(_self.copyWith(menuItem: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderItem].
extension OrderItemPatterns on OrderItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderItem value)  $default,){
final _that = this;
switch (_that) {
case _OrderItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderItem value)?  $default,){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MenuItem menuItem,  int quantity,  List<MenuModifierOption> selectedModifiers,  String? specialNotes,  double itemTotal, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime addedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.menuItem,_that.quantity,_that.selectedModifiers,_that.specialNotes,_that.itemTotal,_that.addedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MenuItem menuItem,  int quantity,  List<MenuModifierOption> selectedModifiers,  String? specialNotes,  double itemTotal, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime addedAt)  $default,) {final _that = this;
switch (_that) {
case _OrderItem():
return $default(_that.menuItem,_that.quantity,_that.selectedModifiers,_that.specialNotes,_that.itemTotal,_that.addedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MenuItem menuItem,  int quantity,  List<MenuModifierOption> selectedModifiers,  String? specialNotes,  double itemTotal, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime addedAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.menuItem,_that.quantity,_that.selectedModifiers,_that.specialNotes,_that.itemTotal,_that.addedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _OrderItem extends OrderItem {
  const _OrderItem({required this.menuItem, required this.quantity, final  List<MenuModifierOption> selectedModifiers = const <MenuModifierOption>[], this.specialNotes, this.itemTotal = 0, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) required this.addedAt}): _selectedModifiers = selectedModifiers,super._();
  factory _OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);

@override final  MenuItem menuItem;
@override final  int quantity;
 final  List<MenuModifierOption> _selectedModifiers;
@override@JsonKey() List<MenuModifierOption> get selectedModifiers {
  if (_selectedModifiers is EqualUnmodifiableListView) return _selectedModifiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedModifiers);
}

@override final  String? specialNotes;
@override@JsonKey() final  double itemTotal;
@override@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) final  DateTime addedAt;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderItemCopyWith<_OrderItem> get copyWith => __$OrderItemCopyWithImpl<_OrderItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderItem&&(identical(other.menuItem, menuItem) || other.menuItem == menuItem)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&const DeepCollectionEquality().equals(other._selectedModifiers, _selectedModifiers)&&(identical(other.specialNotes, specialNotes) || other.specialNotes == specialNotes)&&(identical(other.itemTotal, itemTotal) || other.itemTotal == itemTotal)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,menuItem,quantity,const DeepCollectionEquality().hash(_selectedModifiers),specialNotes,itemTotal,addedAt);

@override
String toString() {
  return 'OrderItem(menuItem: $menuItem, quantity: $quantity, selectedModifiers: $selectedModifiers, specialNotes: $specialNotes, itemTotal: $itemTotal, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class _$OrderItemCopyWith<$Res> implements $OrderItemCopyWith<$Res> {
  factory _$OrderItemCopyWith(_OrderItem value, $Res Function(_OrderItem) _then) = __$OrderItemCopyWithImpl;
@override @useResult
$Res call({
 MenuItem menuItem, int quantity, List<MenuModifierOption> selectedModifiers, String? specialNotes, double itemTotal,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime addedAt
});


@override $MenuItemCopyWith<$Res> get menuItem;

}
/// @nodoc
class __$OrderItemCopyWithImpl<$Res>
    implements _$OrderItemCopyWith<$Res> {
  __$OrderItemCopyWithImpl(this._self, this._then);

  final _OrderItem _self;
  final $Res Function(_OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? menuItem = null,Object? quantity = null,Object? selectedModifiers = null,Object? specialNotes = freezed,Object? itemTotal = null,Object? addedAt = null,}) {
  return _then(_OrderItem(
menuItem: null == menuItem ? _self.menuItem : menuItem // ignore: cast_nullable_to_non_nullable
as MenuItem,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,selectedModifiers: null == selectedModifiers ? _self._selectedModifiers : selectedModifiers // ignore: cast_nullable_to_non_nullable
as List<MenuModifierOption>,specialNotes: freezed == specialNotes ? _self.specialNotes : specialNotes // ignore: cast_nullable_to_non_nullable
as String?,itemTotal: null == itemTotal ? _self.itemTotal : itemTotal // ignore: cast_nullable_to_non_nullable
as double,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MenuItemCopyWith<$Res> get menuItem {
  
  return $MenuItemCopyWith<$Res>(_self.menuItem, (value) {
    return _then(_self.copyWith(menuItem: value));
  });
}
}

// dart format on
