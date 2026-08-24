// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MenuModifierOption {

 String get id; String get name; double get extraPrice; bool get isAvailable;
/// Create a copy of MenuModifierOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuModifierOptionCopyWith<MenuModifierOption> get copyWith => _$MenuModifierOptionCopyWithImpl<MenuModifierOption>(this as MenuModifierOption, _$identity);

  /// Serializes this MenuModifierOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuModifierOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.extraPrice, extraPrice) || other.extraPrice == extraPrice)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,extraPrice,isAvailable);

@override
String toString() {
  return 'MenuModifierOption(id: $id, name: $name, extraPrice: $extraPrice, isAvailable: $isAvailable)';
}


}

/// @nodoc
abstract mixin class $MenuModifierOptionCopyWith<$Res>  {
  factory $MenuModifierOptionCopyWith(MenuModifierOption value, $Res Function(MenuModifierOption) _then) = _$MenuModifierOptionCopyWithImpl;
@useResult
$Res call({
 String id, String name, double extraPrice, bool isAvailable
});




}
/// @nodoc
class _$MenuModifierOptionCopyWithImpl<$Res>
    implements $MenuModifierOptionCopyWith<$Res> {
  _$MenuModifierOptionCopyWithImpl(this._self, this._then);

  final MenuModifierOption _self;
  final $Res Function(MenuModifierOption) _then;

/// Create a copy of MenuModifierOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? extraPrice = null,Object? isAvailable = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,extraPrice: null == extraPrice ? _self.extraPrice : extraPrice // ignore: cast_nullable_to_non_nullable
as double,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuModifierOption].
extension MenuModifierOptionPatterns on MenuModifierOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuModifierOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuModifierOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuModifierOption value)  $default,){
final _that = this;
switch (_that) {
case _MenuModifierOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuModifierOption value)?  $default,){
final _that = this;
switch (_that) {
case _MenuModifierOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double extraPrice,  bool isAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuModifierOption() when $default != null:
return $default(_that.id,_that.name,_that.extraPrice,_that.isAvailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double extraPrice,  bool isAvailable)  $default,) {final _that = this;
switch (_that) {
case _MenuModifierOption():
return $default(_that.id,_that.name,_that.extraPrice,_that.isAvailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double extraPrice,  bool isAvailable)?  $default,) {final _that = this;
switch (_that) {
case _MenuModifierOption() when $default != null:
return $default(_that.id,_that.name,_that.extraPrice,_that.isAvailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuModifierOption implements MenuModifierOption {
  const _MenuModifierOption({required this.id, required this.name, this.extraPrice = 0, this.isAvailable = true});
  factory _MenuModifierOption.fromJson(Map<String, dynamic> json) => _$MenuModifierOptionFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  double extraPrice;
@override@JsonKey() final  bool isAvailable;

/// Create a copy of MenuModifierOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuModifierOptionCopyWith<_MenuModifierOption> get copyWith => __$MenuModifierOptionCopyWithImpl<_MenuModifierOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuModifierOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuModifierOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.extraPrice, extraPrice) || other.extraPrice == extraPrice)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,extraPrice,isAvailable);

@override
String toString() {
  return 'MenuModifierOption(id: $id, name: $name, extraPrice: $extraPrice, isAvailable: $isAvailable)';
}


}

/// @nodoc
abstract mixin class _$MenuModifierOptionCopyWith<$Res> implements $MenuModifierOptionCopyWith<$Res> {
  factory _$MenuModifierOptionCopyWith(_MenuModifierOption value, $Res Function(_MenuModifierOption) _then) = __$MenuModifierOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double extraPrice, bool isAvailable
});




}
/// @nodoc
class __$MenuModifierOptionCopyWithImpl<$Res>
    implements _$MenuModifierOptionCopyWith<$Res> {
  __$MenuModifierOptionCopyWithImpl(this._self, this._then);

  final _MenuModifierOption _self;
  final $Res Function(_MenuModifierOption) _then;

/// Create a copy of MenuModifierOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? extraPrice = null,Object? isAvailable = null,}) {
  return _then(_MenuModifierOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,extraPrice: null == extraPrice ? _self.extraPrice : extraPrice // ignore: cast_nullable_to_non_nullable
as double,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MenuModifierGroup {

 String get id; String get title; String? get description; bool get isRequired; int get maxSelection; List<MenuModifierOption> get options;
/// Create a copy of MenuModifierGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuModifierGroupCopyWith<MenuModifierGroup> get copyWith => _$MenuModifierGroupCopyWithImpl<MenuModifierGroup>(this as MenuModifierGroup, _$identity);

  /// Serializes this MenuModifierGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuModifierGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&(identical(other.maxSelection, maxSelection) || other.maxSelection == maxSelection)&&const DeepCollectionEquality().equals(other.options, options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,isRequired,maxSelection,const DeepCollectionEquality().hash(options));

@override
String toString() {
  return 'MenuModifierGroup(id: $id, title: $title, description: $description, isRequired: $isRequired, maxSelection: $maxSelection, options: $options)';
}


}

/// @nodoc
abstract mixin class $MenuModifierGroupCopyWith<$Res>  {
  factory $MenuModifierGroupCopyWith(MenuModifierGroup value, $Res Function(MenuModifierGroup) _then) = _$MenuModifierGroupCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, bool isRequired, int maxSelection, List<MenuModifierOption> options
});




}
/// @nodoc
class _$MenuModifierGroupCopyWithImpl<$Res>
    implements $MenuModifierGroupCopyWith<$Res> {
  _$MenuModifierGroupCopyWithImpl(this._self, this._then);

  final MenuModifierGroup _self;
  final $Res Function(MenuModifierGroup) _then;

/// Create a copy of MenuModifierGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? isRequired = null,Object? maxSelection = null,Object? options = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,maxSelection: null == maxSelection ? _self.maxSelection : maxSelection // ignore: cast_nullable_to_non_nullable
as int,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<MenuModifierOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuModifierGroup].
extension MenuModifierGroupPatterns on MenuModifierGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuModifierGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuModifierGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuModifierGroup value)  $default,){
final _that = this;
switch (_that) {
case _MenuModifierGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuModifierGroup value)?  $default,){
final _that = this;
switch (_that) {
case _MenuModifierGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  bool isRequired,  int maxSelection,  List<MenuModifierOption> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuModifierGroup() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.isRequired,_that.maxSelection,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  bool isRequired,  int maxSelection,  List<MenuModifierOption> options)  $default,) {final _that = this;
switch (_that) {
case _MenuModifierGroup():
return $default(_that.id,_that.title,_that.description,_that.isRequired,_that.maxSelection,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  bool isRequired,  int maxSelection,  List<MenuModifierOption> options)?  $default,) {final _that = this;
switch (_that) {
case _MenuModifierGroup() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.isRequired,_that.maxSelection,_that.options);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MenuModifierGroup implements MenuModifierGroup {
  const _MenuModifierGroup({required this.id, required this.title, this.description, this.isRequired = false, this.maxSelection = 1, final  List<MenuModifierOption> options = const <MenuModifierOption>[]}): _options = options;
  factory _MenuModifierGroup.fromJson(Map<String, dynamic> json) => _$MenuModifierGroupFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? description;
@override@JsonKey() final  bool isRequired;
@override@JsonKey() final  int maxSelection;
 final  List<MenuModifierOption> _options;
@override@JsonKey() List<MenuModifierOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of MenuModifierGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuModifierGroupCopyWith<_MenuModifierGroup> get copyWith => __$MenuModifierGroupCopyWithImpl<_MenuModifierGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuModifierGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuModifierGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&(identical(other.maxSelection, maxSelection) || other.maxSelection == maxSelection)&&const DeepCollectionEquality().equals(other._options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,isRequired,maxSelection,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'MenuModifierGroup(id: $id, title: $title, description: $description, isRequired: $isRequired, maxSelection: $maxSelection, options: $options)';
}


}

/// @nodoc
abstract mixin class _$MenuModifierGroupCopyWith<$Res> implements $MenuModifierGroupCopyWith<$Res> {
  factory _$MenuModifierGroupCopyWith(_MenuModifierGroup value, $Res Function(_MenuModifierGroup) _then) = __$MenuModifierGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, bool isRequired, int maxSelection, List<MenuModifierOption> options
});




}
/// @nodoc
class __$MenuModifierGroupCopyWithImpl<$Res>
    implements _$MenuModifierGroupCopyWith<$Res> {
  __$MenuModifierGroupCopyWithImpl(this._self, this._then);

  final _MenuModifierGroup _self;
  final $Res Function(_MenuModifierGroup) _then;

/// Create a copy of MenuModifierGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? isRequired = null,Object? maxSelection = null,Object? options = null,}) {
  return _then(_MenuModifierGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,maxSelection: null == maxSelection ? _self.maxSelection : maxSelection // ignore: cast_nullable_to_non_nullable
as int,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<MenuModifierOption>,
  ));
}


}


/// @nodoc
mixin _$MenuItem {

 String get id; String get categoryId; String get name; String get description; double get price; String? get imageUrl; bool get isAvailable; bool get isVegetarian; bool get isSpicy; double? get preparationTime; List<MenuModifierGroup> get modifierGroups; double? get rating; int? get orderCount;
/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuItemCopyWith<MenuItem> get copyWith => _$MenuItemCopyWithImpl<MenuItem>(this as MenuItem, _$identity);

  /// Serializes this MenuItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuItem&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.isVegetarian, isVegetarian) || other.isVegetarian == isVegetarian)&&(identical(other.isSpicy, isSpicy) || other.isSpicy == isSpicy)&&(identical(other.preparationTime, preparationTime) || other.preparationTime == preparationTime)&&const DeepCollectionEquality().equals(other.modifierGroups, modifierGroups)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.orderCount, orderCount) || other.orderCount == orderCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,categoryId,name,description,price,imageUrl,isAvailable,isVegetarian,isSpicy,preparationTime,const DeepCollectionEquality().hash(modifierGroups),rating,orderCount);

@override
String toString() {
  return 'MenuItem(id: $id, categoryId: $categoryId, name: $name, description: $description, price: $price, imageUrl: $imageUrl, isAvailable: $isAvailable, isVegetarian: $isVegetarian, isSpicy: $isSpicy, preparationTime: $preparationTime, modifierGroups: $modifierGroups, rating: $rating, orderCount: $orderCount)';
}


}

/// @nodoc
abstract mixin class $MenuItemCopyWith<$Res>  {
  factory $MenuItemCopyWith(MenuItem value, $Res Function(MenuItem) _then) = _$MenuItemCopyWithImpl;
@useResult
$Res call({
 String id, String categoryId, String name, String description, double price, String? imageUrl, bool isAvailable, bool isVegetarian, bool isSpicy, double? preparationTime, List<MenuModifierGroup> modifierGroups, double? rating, int? orderCount
});




}
/// @nodoc
class _$MenuItemCopyWithImpl<$Res>
    implements $MenuItemCopyWith<$Res> {
  _$MenuItemCopyWithImpl(this._self, this._then);

  final MenuItem _self;
  final $Res Function(MenuItem) _then;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? categoryId = null,Object? name = null,Object? description = null,Object? price = null,Object? imageUrl = freezed,Object? isAvailable = null,Object? isVegetarian = null,Object? isSpicy = null,Object? preparationTime = freezed,Object? modifierGroups = null,Object? rating = freezed,Object? orderCount = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,isVegetarian: null == isVegetarian ? _self.isVegetarian : isVegetarian // ignore: cast_nullable_to_non_nullable
as bool,isSpicy: null == isSpicy ? _self.isSpicy : isSpicy // ignore: cast_nullable_to_non_nullable
as bool,preparationTime: freezed == preparationTime ? _self.preparationTime : preparationTime // ignore: cast_nullable_to_non_nullable
as double?,modifierGroups: null == modifierGroups ? _self.modifierGroups : modifierGroups // ignore: cast_nullable_to_non_nullable
as List<MenuModifierGroup>,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,orderCount: freezed == orderCount ? _self.orderCount : orderCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuItem].
extension MenuItemPatterns on MenuItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuItem value)  $default,){
final _that = this;
switch (_that) {
case _MenuItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuItem value)?  $default,){
final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String categoryId,  String name,  String description,  double price,  String? imageUrl,  bool isAvailable,  bool isVegetarian,  bool isSpicy,  double? preparationTime,  List<MenuModifierGroup> modifierGroups,  double? rating,  int? orderCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that.id,_that.categoryId,_that.name,_that.description,_that.price,_that.imageUrl,_that.isAvailable,_that.isVegetarian,_that.isSpicy,_that.preparationTime,_that.modifierGroups,_that.rating,_that.orderCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String categoryId,  String name,  String description,  double price,  String? imageUrl,  bool isAvailable,  bool isVegetarian,  bool isSpicy,  double? preparationTime,  List<MenuModifierGroup> modifierGroups,  double? rating,  int? orderCount)  $default,) {final _that = this;
switch (_that) {
case _MenuItem():
return $default(_that.id,_that.categoryId,_that.name,_that.description,_that.price,_that.imageUrl,_that.isAvailable,_that.isVegetarian,_that.isSpicy,_that.preparationTime,_that.modifierGroups,_that.rating,_that.orderCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String categoryId,  String name,  String description,  double price,  String? imageUrl,  bool isAvailable,  bool isVegetarian,  bool isSpicy,  double? preparationTime,  List<MenuModifierGroup> modifierGroups,  double? rating,  int? orderCount)?  $default,) {final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that.id,_that.categoryId,_that.name,_that.description,_that.price,_that.imageUrl,_that.isAvailable,_that.isVegetarian,_that.isSpicy,_that.preparationTime,_that.modifierGroups,_that.rating,_that.orderCount);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MenuItem implements MenuItem {
  const _MenuItem({required this.id, required this.categoryId, required this.name, required this.description, required this.price, this.imageUrl, this.isAvailable = true, this.isVegetarian = false, this.isSpicy = false, this.preparationTime, final  List<MenuModifierGroup> modifierGroups = const <MenuModifierGroup>[], this.rating, this.orderCount}): _modifierGroups = modifierGroups;
  factory _MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);

@override final  String id;
@override final  String categoryId;
@override final  String name;
@override final  String description;
@override final  double price;
@override final  String? imageUrl;
@override@JsonKey() final  bool isAvailable;
@override@JsonKey() final  bool isVegetarian;
@override@JsonKey() final  bool isSpicy;
@override final  double? preparationTime;
 final  List<MenuModifierGroup> _modifierGroups;
@override@JsonKey() List<MenuModifierGroup> get modifierGroups {
  if (_modifierGroups is EqualUnmodifiableListView) return _modifierGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modifierGroups);
}

@override final  double? rating;
@override final  int? orderCount;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuItemCopyWith<_MenuItem> get copyWith => __$MenuItemCopyWithImpl<_MenuItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuItem&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.isVegetarian, isVegetarian) || other.isVegetarian == isVegetarian)&&(identical(other.isSpicy, isSpicy) || other.isSpicy == isSpicy)&&(identical(other.preparationTime, preparationTime) || other.preparationTime == preparationTime)&&const DeepCollectionEquality().equals(other._modifierGroups, _modifierGroups)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.orderCount, orderCount) || other.orderCount == orderCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,categoryId,name,description,price,imageUrl,isAvailable,isVegetarian,isSpicy,preparationTime,const DeepCollectionEquality().hash(_modifierGroups),rating,orderCount);

@override
String toString() {
  return 'MenuItem(id: $id, categoryId: $categoryId, name: $name, description: $description, price: $price, imageUrl: $imageUrl, isAvailable: $isAvailable, isVegetarian: $isVegetarian, isSpicy: $isSpicy, preparationTime: $preparationTime, modifierGroups: $modifierGroups, rating: $rating, orderCount: $orderCount)';
}


}

/// @nodoc
abstract mixin class _$MenuItemCopyWith<$Res> implements $MenuItemCopyWith<$Res> {
  factory _$MenuItemCopyWith(_MenuItem value, $Res Function(_MenuItem) _then) = __$MenuItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String categoryId, String name, String description, double price, String? imageUrl, bool isAvailable, bool isVegetarian, bool isSpicy, double? preparationTime, List<MenuModifierGroup> modifierGroups, double? rating, int? orderCount
});




}
/// @nodoc
class __$MenuItemCopyWithImpl<$Res>
    implements _$MenuItemCopyWith<$Res> {
  __$MenuItemCopyWithImpl(this._self, this._then);

  final _MenuItem _self;
  final $Res Function(_MenuItem) _then;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? categoryId = null,Object? name = null,Object? description = null,Object? price = null,Object? imageUrl = freezed,Object? isAvailable = null,Object? isVegetarian = null,Object? isSpicy = null,Object? preparationTime = freezed,Object? modifierGroups = null,Object? rating = freezed,Object? orderCount = freezed,}) {
  return _then(_MenuItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,isVegetarian: null == isVegetarian ? _self.isVegetarian : isVegetarian // ignore: cast_nullable_to_non_nullable
as bool,isSpicy: null == isSpicy ? _self.isSpicy : isSpicy // ignore: cast_nullable_to_non_nullable
as bool,preparationTime: freezed == preparationTime ? _self.preparationTime : preparationTime // ignore: cast_nullable_to_non_nullable
as double?,modifierGroups: null == modifierGroups ? _self._modifierGroups : modifierGroups // ignore: cast_nullable_to_non_nullable
as List<MenuModifierGroup>,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,orderCount: freezed == orderCount ? _self.orderCount : orderCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
