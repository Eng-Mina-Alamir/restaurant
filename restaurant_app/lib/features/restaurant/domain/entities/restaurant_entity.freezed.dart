// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restaurant_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BusinessHours {

 String get openTime; String get closeTime;
/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessHoursCopyWith<BusinessHours> get copyWith => _$BusinessHoursCopyWithImpl<BusinessHours>(this as BusinessHours, _$identity);

  /// Serializes this BusinessHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessHours&&(identical(other.openTime, openTime) || other.openTime == openTime)&&(identical(other.closeTime, closeTime) || other.closeTime == closeTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,openTime,closeTime);

@override
String toString() {
  return 'BusinessHours(openTime: $openTime, closeTime: $closeTime)';
}


}

/// @nodoc
abstract mixin class $BusinessHoursCopyWith<$Res>  {
  factory $BusinessHoursCopyWith(BusinessHours value, $Res Function(BusinessHours) _then) = _$BusinessHoursCopyWithImpl;
@useResult
$Res call({
 String openTime, String closeTime
});




}
/// @nodoc
class _$BusinessHoursCopyWithImpl<$Res>
    implements $BusinessHoursCopyWith<$Res> {
  _$BusinessHoursCopyWithImpl(this._self, this._then);

  final BusinessHours _self;
  final $Res Function(BusinessHours) _then;

/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? openTime = null,Object? closeTime = null,}) {
  return _then(_self.copyWith(
openTime: null == openTime ? _self.openTime : openTime // ignore: cast_nullable_to_non_nullable
as String,closeTime: null == closeTime ? _self.closeTime : closeTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BusinessHours].
extension BusinessHoursPatterns on BusinessHours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessHours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessHours value)  $default,){
final _that = this;
switch (_that) {
case _BusinessHours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessHours value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessHours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String openTime,  String closeTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessHours() when $default != null:
return $default(_that.openTime,_that.closeTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String openTime,  String closeTime)  $default,) {final _that = this;
switch (_that) {
case _BusinessHours():
return $default(_that.openTime,_that.closeTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String openTime,  String closeTime)?  $default,) {final _that = this;
switch (_that) {
case _BusinessHours() when $default != null:
return $default(_that.openTime,_that.closeTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BusinessHours implements BusinessHours {
  const _BusinessHours({this.openTime = '10:00', this.closeTime = '23:00'});
  factory _BusinessHours.fromJson(Map<String, dynamic> json) => _$BusinessHoursFromJson(json);

@override@JsonKey() final  String openTime;
@override@JsonKey() final  String closeTime;

/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessHoursCopyWith<_BusinessHours> get copyWith => __$BusinessHoursCopyWithImpl<_BusinessHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessHoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessHours&&(identical(other.openTime, openTime) || other.openTime == openTime)&&(identical(other.closeTime, closeTime) || other.closeTime == closeTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,openTime,closeTime);

@override
String toString() {
  return 'BusinessHours(openTime: $openTime, closeTime: $closeTime)';
}


}

/// @nodoc
abstract mixin class _$BusinessHoursCopyWith<$Res> implements $BusinessHoursCopyWith<$Res> {
  factory _$BusinessHoursCopyWith(_BusinessHours value, $Res Function(_BusinessHours) _then) = __$BusinessHoursCopyWithImpl;
@override @useResult
$Res call({
 String openTime, String closeTime
});




}
/// @nodoc
class __$BusinessHoursCopyWithImpl<$Res>
    implements _$BusinessHoursCopyWith<$Res> {
  __$BusinessHoursCopyWithImpl(this._self, this._then);

  final _BusinessHours _self;
  final $Res Function(_BusinessHours) _then;

/// Create a copy of BusinessHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? openTime = null,Object? closeTime = null,}) {
  return _then(_BusinessHours(
openTime: null == openTime ? _self.openTime : openTime // ignore: cast_nullable_to_non_nullable
as String,closeTime: null == closeTime ? _self.closeTime : closeTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RestaurantEntity {

 String get id; String get name; String get address; String get phone; double get latitude; double get longitude; String? get logoUrl; BusinessHours get hours; int get totalTables; List<String> get categories;
/// Create a copy of RestaurantEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantEntityCopyWith<RestaurantEntity> get copyWith => _$RestaurantEntityCopyWithImpl<RestaurantEntity>(this as RestaurantEntity, _$identity);

  /// Serializes this RestaurantEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.totalTables, totalTables) || other.totalTables == totalTables)&&const DeepCollectionEquality().equals(other.categories, categories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,phone,latitude,longitude,logoUrl,hours,totalTables,const DeepCollectionEquality().hash(categories));

@override
String toString() {
  return 'RestaurantEntity(id: $id, name: $name, address: $address, phone: $phone, latitude: $latitude, longitude: $longitude, logoUrl: $logoUrl, hours: $hours, totalTables: $totalTables, categories: $categories)';
}


}

/// @nodoc
abstract mixin class $RestaurantEntityCopyWith<$Res>  {
  factory $RestaurantEntityCopyWith(RestaurantEntity value, $Res Function(RestaurantEntity) _then) = _$RestaurantEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String address, String phone, double latitude, double longitude, String? logoUrl, BusinessHours hours, int totalTables, List<String> categories
});


$BusinessHoursCopyWith<$Res> get hours;

}
/// @nodoc
class _$RestaurantEntityCopyWithImpl<$Res>
    implements $RestaurantEntityCopyWith<$Res> {
  _$RestaurantEntityCopyWithImpl(this._self, this._then);

  final RestaurantEntity _self;
  final $Res Function(RestaurantEntity) _then;

/// Create a copy of RestaurantEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? address = null,Object? phone = null,Object? latitude = null,Object? longitude = null,Object? logoUrl = freezed,Object? hours = null,Object? totalTables = null,Object? categories = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as BusinessHours,totalTables: null == totalTables ? _self.totalTables : totalTables // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of RestaurantEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessHoursCopyWith<$Res> get hours {
  
  return $BusinessHoursCopyWith<$Res>(_self.hours, (value) {
    return _then(_self.copyWith(hours: value));
  });
}
}


/// Adds pattern-matching-related methods to [RestaurantEntity].
extension RestaurantEntityPatterns on RestaurantEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantEntity value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantEntity value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String address,  String phone,  double latitude,  double longitude,  String? logoUrl,  BusinessHours hours,  int totalTables,  List<String> categories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantEntity() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.phone,_that.latitude,_that.longitude,_that.logoUrl,_that.hours,_that.totalTables,_that.categories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String address,  String phone,  double latitude,  double longitude,  String? logoUrl,  BusinessHours hours,  int totalTables,  List<String> categories)  $default,) {final _that = this;
switch (_that) {
case _RestaurantEntity():
return $default(_that.id,_that.name,_that.address,_that.phone,_that.latitude,_that.longitude,_that.logoUrl,_that.hours,_that.totalTables,_that.categories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String address,  String phone,  double latitude,  double longitude,  String? logoUrl,  BusinessHours hours,  int totalTables,  List<String> categories)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantEntity() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.phone,_that.latitude,_that.longitude,_that.logoUrl,_that.hours,_that.totalTables,_that.categories);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _RestaurantEntity implements RestaurantEntity {
  const _RestaurantEntity({required this.id, required this.name, required this.address, required this.phone, this.latitude = 0, this.longitude = 0, this.logoUrl, this.hours = const BusinessHours(), this.totalTables = 0, final  List<String> categories = const <String>[]}): _categories = categories;
  factory _RestaurantEntity.fromJson(Map<String, dynamic> json) => _$RestaurantEntityFromJson(json);

@override final  String id;
@override final  String name;
@override final  String address;
@override final  String phone;
@override@JsonKey() final  double latitude;
@override@JsonKey() final  double longitude;
@override final  String? logoUrl;
@override@JsonKey() final  BusinessHours hours;
@override@JsonKey() final  int totalTables;
 final  List<String> _categories;
@override@JsonKey() List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of RestaurantEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantEntityCopyWith<_RestaurantEntity> get copyWith => __$RestaurantEntityCopyWithImpl<_RestaurantEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.totalTables, totalTables) || other.totalTables == totalTables)&&const DeepCollectionEquality().equals(other._categories, _categories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,phone,latitude,longitude,logoUrl,hours,totalTables,const DeepCollectionEquality().hash(_categories));

@override
String toString() {
  return 'RestaurantEntity(id: $id, name: $name, address: $address, phone: $phone, latitude: $latitude, longitude: $longitude, logoUrl: $logoUrl, hours: $hours, totalTables: $totalTables, categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$RestaurantEntityCopyWith<$Res> implements $RestaurantEntityCopyWith<$Res> {
  factory _$RestaurantEntityCopyWith(_RestaurantEntity value, $Res Function(_RestaurantEntity) _then) = __$RestaurantEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String address, String phone, double latitude, double longitude, String? logoUrl, BusinessHours hours, int totalTables, List<String> categories
});


@override $BusinessHoursCopyWith<$Res> get hours;

}
/// @nodoc
class __$RestaurantEntityCopyWithImpl<$Res>
    implements _$RestaurantEntityCopyWith<$Res> {
  __$RestaurantEntityCopyWithImpl(this._self, this._then);

  final _RestaurantEntity _self;
  final $Res Function(_RestaurantEntity) _then;

/// Create a copy of RestaurantEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? address = null,Object? phone = null,Object? latitude = null,Object? longitude = null,Object? logoUrl = freezed,Object? hours = null,Object? totalTables = null,Object? categories = null,}) {
  return _then(_RestaurantEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as BusinessHours,totalTables: null == totalTables ? _self.totalTables : totalTables // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of RestaurantEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessHoursCopyWith<$Res> get hours {
  
  return $BusinessHoursCopyWith<$Res>(_self.hours, (value) {
    return _then(_self.copyWith(hours: value));
  });
}
}

// dart format on
