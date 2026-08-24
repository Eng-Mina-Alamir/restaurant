// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restaurant_table.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RestaurantTable {

 String get id; int get tableNumber; int get capacity;/// Physical zone/location of the table (e.g. "صالة", "حديقة", "تراس").
 String get location;@JsonKey(fromJson: _tableStatusFromJson, toJson: _tableStatusToString, includeIfNull: false) TableStatus get status; String? get currentOrderId; String? get assignedWaiterId;@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get lastUpdated;
/// Create a copy of RestaurantTable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantTableCopyWith<RestaurantTable> get copyWith => _$RestaurantTableCopyWithImpl<RestaurantTable>(this as RestaurantTable, _$identity);

  /// Serializes this RestaurantTable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantTable&&(identical(other.id, id) || other.id == id)&&(identical(other.tableNumber, tableNumber) || other.tableNumber == tableNumber)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.location, location) || other.location == location)&&(identical(other.status, status) || other.status == status)&&(identical(other.currentOrderId, currentOrderId) || other.currentOrderId == currentOrderId)&&(identical(other.assignedWaiterId, assignedWaiterId) || other.assignedWaiterId == assignedWaiterId)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tableNumber,capacity,location,status,currentOrderId,assignedWaiterId,lastUpdated);

@override
String toString() {
  return 'RestaurantTable(id: $id, tableNumber: $tableNumber, capacity: $capacity, location: $location, status: $status, currentOrderId: $currentOrderId, assignedWaiterId: $assignedWaiterId, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class $RestaurantTableCopyWith<$Res>  {
  factory $RestaurantTableCopyWith(RestaurantTable value, $Res Function(RestaurantTable) _then) = _$RestaurantTableCopyWithImpl;
@useResult
$Res call({
 String id, int tableNumber, int capacity, String location,@JsonKey(fromJson: _tableStatusFromJson, toJson: _tableStatusToString, includeIfNull: false) TableStatus status, String? currentOrderId, String? assignedWaiterId,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? lastUpdated
});




}
/// @nodoc
class _$RestaurantTableCopyWithImpl<$Res>
    implements $RestaurantTableCopyWith<$Res> {
  _$RestaurantTableCopyWithImpl(this._self, this._then);

  final RestaurantTable _self;
  final $Res Function(RestaurantTable) _then;

/// Create a copy of RestaurantTable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tableNumber = null,Object? capacity = null,Object? location = null,Object? status = null,Object? currentOrderId = freezed,Object? assignedWaiterId = freezed,Object? lastUpdated = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tableNumber: null == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TableStatus,currentOrderId: freezed == currentOrderId ? _self.currentOrderId : currentOrderId // ignore: cast_nullable_to_non_nullable
as String?,assignedWaiterId: freezed == assignedWaiterId ? _self.assignedWaiterId : assignedWaiterId // ignore: cast_nullable_to_non_nullable
as String?,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RestaurantTable].
extension RestaurantTablePatterns on RestaurantTable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantTable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantTable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantTable value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantTable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantTable value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantTable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int tableNumber,  int capacity,  String location, @JsonKey(fromJson: _tableStatusFromJson, toJson: _tableStatusToString, includeIfNull: false)  TableStatus status,  String? currentOrderId,  String? assignedWaiterId, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? lastUpdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantTable() when $default != null:
return $default(_that.id,_that.tableNumber,_that.capacity,_that.location,_that.status,_that.currentOrderId,_that.assignedWaiterId,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int tableNumber,  int capacity,  String location, @JsonKey(fromJson: _tableStatusFromJson, toJson: _tableStatusToString, includeIfNull: false)  TableStatus status,  String? currentOrderId,  String? assignedWaiterId, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? lastUpdated)  $default,) {final _that = this;
switch (_that) {
case _RestaurantTable():
return $default(_that.id,_that.tableNumber,_that.capacity,_that.location,_that.status,_that.currentOrderId,_that.assignedWaiterId,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int tableNumber,  int capacity,  String location, @JsonKey(fromJson: _tableStatusFromJson, toJson: _tableStatusToString, includeIfNull: false)  TableStatus status,  String? currentOrderId,  String? assignedWaiterId, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? lastUpdated)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantTable() when $default != null:
return $default(_that.id,_that.tableNumber,_that.capacity,_that.location,_that.status,_that.currentOrderId,_that.assignedWaiterId,_that.lastUpdated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RestaurantTable implements RestaurantTable {
  const _RestaurantTable({required this.id, required this.tableNumber, this.capacity = 4, this.location = 'صالة', @JsonKey(fromJson: _tableStatusFromJson, toJson: _tableStatusToString, includeIfNull: false) required this.status, this.currentOrderId, this.assignedWaiterId, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) this.lastUpdated});
  factory _RestaurantTable.fromJson(Map<String, dynamic> json) => _$RestaurantTableFromJson(json);

@override final  String id;
@override final  int tableNumber;
@override@JsonKey() final  int capacity;
/// Physical zone/location of the table (e.g. "صالة", "حديقة", "تراس").
@override@JsonKey() final  String location;
@override@JsonKey(fromJson: _tableStatusFromJson, toJson: _tableStatusToString, includeIfNull: false) final  TableStatus status;
@override final  String? currentOrderId;
@override final  String? assignedWaiterId;
@override@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? lastUpdated;

/// Create a copy of RestaurantTable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantTableCopyWith<_RestaurantTable> get copyWith => __$RestaurantTableCopyWithImpl<_RestaurantTable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantTableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantTable&&(identical(other.id, id) || other.id == id)&&(identical(other.tableNumber, tableNumber) || other.tableNumber == tableNumber)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.location, location) || other.location == location)&&(identical(other.status, status) || other.status == status)&&(identical(other.currentOrderId, currentOrderId) || other.currentOrderId == currentOrderId)&&(identical(other.assignedWaiterId, assignedWaiterId) || other.assignedWaiterId == assignedWaiterId)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tableNumber,capacity,location,status,currentOrderId,assignedWaiterId,lastUpdated);

@override
String toString() {
  return 'RestaurantTable(id: $id, tableNumber: $tableNumber, capacity: $capacity, location: $location, status: $status, currentOrderId: $currentOrderId, assignedWaiterId: $assignedWaiterId, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class _$RestaurantTableCopyWith<$Res> implements $RestaurantTableCopyWith<$Res> {
  factory _$RestaurantTableCopyWith(_RestaurantTable value, $Res Function(_RestaurantTable) _then) = __$RestaurantTableCopyWithImpl;
@override @useResult
$Res call({
 String id, int tableNumber, int capacity, String location,@JsonKey(fromJson: _tableStatusFromJson, toJson: _tableStatusToString, includeIfNull: false) TableStatus status, String? currentOrderId, String? assignedWaiterId,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? lastUpdated
});




}
/// @nodoc
class __$RestaurantTableCopyWithImpl<$Res>
    implements _$RestaurantTableCopyWith<$Res> {
  __$RestaurantTableCopyWithImpl(this._self, this._then);

  final _RestaurantTable _self;
  final $Res Function(_RestaurantTable) _then;

/// Create a copy of RestaurantTable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tableNumber = null,Object? capacity = null,Object? location = null,Object? status = null,Object? currentOrderId = freezed,Object? assignedWaiterId = freezed,Object? lastUpdated = freezed,}) {
  return _then(_RestaurantTable(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tableNumber: null == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TableStatus,currentOrderId: freezed == currentOrderId ? _self.currentOrderId : currentOrderId // ignore: cast_nullable_to_non_nullable
as String?,assignedWaiterId: freezed == assignedWaiterId ? _self.assignedWaiterId : assignedWaiterId // ignore: cast_nullable_to_non_nullable
as String?,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
