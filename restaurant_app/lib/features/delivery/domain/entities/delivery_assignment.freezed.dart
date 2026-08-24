// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_assignment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeliveryAssignment {

 String get id; String get orderId; String get driverId;@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime get pickupTime;@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get deliveredTime; String get deliveryLocation;/// Customer phone number for coordination during the trip.
 String? get customerPhone; double get latitude; double get longitude;@JsonKey(fromJson: _deliveryStatusFromJson, toJson: _deliveryStatusToString, includeIfNull: false) DeliveryStatus get deliveryStatus; double? get deliveryFee; String? get routeOptimized; double? get routeDistanceMeters;/// Display-only enrichment joined from the driver's profile (nullable
/// because local/seeded assignments have no profile row to join).
 String? get driverName; String? get driverPhone; double? get driverRating; String? get vehicleInfo;/// How the assignment was dispatched: 'auto' or 'manual'.
 String get assignmentMethod;@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get assignedAt;
/// Create a copy of DeliveryAssignment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryAssignmentCopyWith<DeliveryAssignment> get copyWith => _$DeliveryAssignmentCopyWithImpl<DeliveryAssignment>(this as DeliveryAssignment, _$identity);

  /// Serializes this DeliveryAssignment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryAssignment&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.pickupTime, pickupTime) || other.pickupTime == pickupTime)&&(identical(other.deliveredTime, deliveredTime) || other.deliveredTime == deliveredTime)&&(identical(other.deliveryLocation, deliveryLocation) || other.deliveryLocation == deliveryLocation)&&(identical(other.customerPhone, customerPhone) || other.customerPhone == customerPhone)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.deliveryStatus, deliveryStatus) || other.deliveryStatus == deliveryStatus)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.routeOptimized, routeOptimized) || other.routeOptimized == routeOptimized)&&(identical(other.routeDistanceMeters, routeDistanceMeters) || other.routeDistanceMeters == routeDistanceMeters)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.driverPhone, driverPhone) || other.driverPhone == driverPhone)&&(identical(other.driverRating, driverRating) || other.driverRating == driverRating)&&(identical(other.vehicleInfo, vehicleInfo) || other.vehicleInfo == vehicleInfo)&&(identical(other.assignmentMethod, assignmentMethod) || other.assignmentMethod == assignmentMethod)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,orderId,driverId,pickupTime,deliveredTime,deliveryLocation,customerPhone,latitude,longitude,deliveryStatus,deliveryFee,routeOptimized,routeDistanceMeters,driverName,driverPhone,driverRating,vehicleInfo,assignmentMethod,assignedAt]);

@override
String toString() {
  return 'DeliveryAssignment(id: $id, orderId: $orderId, driverId: $driverId, pickupTime: $pickupTime, deliveredTime: $deliveredTime, deliveryLocation: $deliveryLocation, customerPhone: $customerPhone, latitude: $latitude, longitude: $longitude, deliveryStatus: $deliveryStatus, deliveryFee: $deliveryFee, routeOptimized: $routeOptimized, routeDistanceMeters: $routeDistanceMeters, driverName: $driverName, driverPhone: $driverPhone, driverRating: $driverRating, vehicleInfo: $vehicleInfo, assignmentMethod: $assignmentMethod, assignedAt: $assignedAt)';
}


}

/// @nodoc
abstract mixin class $DeliveryAssignmentCopyWith<$Res>  {
  factory $DeliveryAssignmentCopyWith(DeliveryAssignment value, $Res Function(DeliveryAssignment) _then) = _$DeliveryAssignmentCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, String driverId,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime pickupTime,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? deliveredTime, String deliveryLocation, String? customerPhone, double latitude, double longitude,@JsonKey(fromJson: _deliveryStatusFromJson, toJson: _deliveryStatusToString, includeIfNull: false) DeliveryStatus deliveryStatus, double? deliveryFee, String? routeOptimized, double? routeDistanceMeters, String? driverName, String? driverPhone, double? driverRating, String? vehicleInfo, String assignmentMethod,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? assignedAt
});




}
/// @nodoc
class _$DeliveryAssignmentCopyWithImpl<$Res>
    implements $DeliveryAssignmentCopyWith<$Res> {
  _$DeliveryAssignmentCopyWithImpl(this._self, this._then);

  final DeliveryAssignment _self;
  final $Res Function(DeliveryAssignment) _then;

/// Create a copy of DeliveryAssignment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? driverId = null,Object? pickupTime = null,Object? deliveredTime = freezed,Object? deliveryLocation = null,Object? customerPhone = freezed,Object? latitude = null,Object? longitude = null,Object? deliveryStatus = null,Object? deliveryFee = freezed,Object? routeOptimized = freezed,Object? routeDistanceMeters = freezed,Object? driverName = freezed,Object? driverPhone = freezed,Object? driverRating = freezed,Object? vehicleInfo = freezed,Object? assignmentMethod = null,Object? assignedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,pickupTime: null == pickupTime ? _self.pickupTime : pickupTime // ignore: cast_nullable_to_non_nullable
as DateTime,deliveredTime: freezed == deliveredTime ? _self.deliveredTime : deliveredTime // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveryLocation: null == deliveryLocation ? _self.deliveryLocation : deliveryLocation // ignore: cast_nullable_to_non_nullable
as String,customerPhone: freezed == customerPhone ? _self.customerPhone : customerPhone // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,deliveryStatus: null == deliveryStatus ? _self.deliveryStatus : deliveryStatus // ignore: cast_nullable_to_non_nullable
as DeliveryStatus,deliveryFee: freezed == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as double?,routeOptimized: freezed == routeOptimized ? _self.routeOptimized : routeOptimized // ignore: cast_nullable_to_non_nullable
as String?,routeDistanceMeters: freezed == routeDistanceMeters ? _self.routeDistanceMeters : routeDistanceMeters // ignore: cast_nullable_to_non_nullable
as double?,driverName: freezed == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String?,driverPhone: freezed == driverPhone ? _self.driverPhone : driverPhone // ignore: cast_nullable_to_non_nullable
as String?,driverRating: freezed == driverRating ? _self.driverRating : driverRating // ignore: cast_nullable_to_non_nullable
as double?,vehicleInfo: freezed == vehicleInfo ? _self.vehicleInfo : vehicleInfo // ignore: cast_nullable_to_non_nullable
as String?,assignmentMethod: null == assignmentMethod ? _self.assignmentMethod : assignmentMethod // ignore: cast_nullable_to_non_nullable
as String,assignedAt: freezed == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveryAssignment].
extension DeliveryAssignmentPatterns on DeliveryAssignment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryAssignment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryAssignment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryAssignment value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryAssignment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryAssignment value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryAssignment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  String driverId, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime pickupTime, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? deliveredTime,  String deliveryLocation,  String? customerPhone,  double latitude,  double longitude, @JsonKey(fromJson: _deliveryStatusFromJson, toJson: _deliveryStatusToString, includeIfNull: false)  DeliveryStatus deliveryStatus,  double? deliveryFee,  String? routeOptimized,  double? routeDistanceMeters,  String? driverName,  String? driverPhone,  double? driverRating,  String? vehicleInfo,  String assignmentMethod, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? assignedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryAssignment() when $default != null:
return $default(_that.id,_that.orderId,_that.driverId,_that.pickupTime,_that.deliveredTime,_that.deliveryLocation,_that.customerPhone,_that.latitude,_that.longitude,_that.deliveryStatus,_that.deliveryFee,_that.routeOptimized,_that.routeDistanceMeters,_that.driverName,_that.driverPhone,_that.driverRating,_that.vehicleInfo,_that.assignmentMethod,_that.assignedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  String driverId, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime pickupTime, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? deliveredTime,  String deliveryLocation,  String? customerPhone,  double latitude,  double longitude, @JsonKey(fromJson: _deliveryStatusFromJson, toJson: _deliveryStatusToString, includeIfNull: false)  DeliveryStatus deliveryStatus,  double? deliveryFee,  String? routeOptimized,  double? routeDistanceMeters,  String? driverName,  String? driverPhone,  double? driverRating,  String? vehicleInfo,  String assignmentMethod, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? assignedAt)  $default,) {final _that = this;
switch (_that) {
case _DeliveryAssignment():
return $default(_that.id,_that.orderId,_that.driverId,_that.pickupTime,_that.deliveredTime,_that.deliveryLocation,_that.customerPhone,_that.latitude,_that.longitude,_that.deliveryStatus,_that.deliveryFee,_that.routeOptimized,_that.routeDistanceMeters,_that.driverName,_that.driverPhone,_that.driverRating,_that.vehicleInfo,_that.assignmentMethod,_that.assignedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  String driverId, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime pickupTime, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? deliveredTime,  String deliveryLocation,  String? customerPhone,  double latitude,  double longitude, @JsonKey(fromJson: _deliveryStatusFromJson, toJson: _deliveryStatusToString, includeIfNull: false)  DeliveryStatus deliveryStatus,  double? deliveryFee,  String? routeOptimized,  double? routeDistanceMeters,  String? driverName,  String? driverPhone,  double? driverRating,  String? vehicleInfo,  String assignmentMethod, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? assignedAt)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryAssignment() when $default != null:
return $default(_that.id,_that.orderId,_that.driverId,_that.pickupTime,_that.deliveredTime,_that.deliveryLocation,_that.customerPhone,_that.latitude,_that.longitude,_that.deliveryStatus,_that.deliveryFee,_that.routeOptimized,_that.routeDistanceMeters,_that.driverName,_that.driverPhone,_that.driverRating,_that.vehicleInfo,_that.assignmentMethod,_that.assignedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryAssignment implements DeliveryAssignment {
  const _DeliveryAssignment({required this.id, required this.orderId, required this.driverId, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) required this.pickupTime, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) this.deliveredTime, required this.deliveryLocation, this.customerPhone, this.latitude = 0, this.longitude = 0, @JsonKey(fromJson: _deliveryStatusFromJson, toJson: _deliveryStatusToString, includeIfNull: false) required this.deliveryStatus, this.deliveryFee, this.routeOptimized, this.routeDistanceMeters, this.driverName, this.driverPhone, this.driverRating, this.vehicleInfo, this.assignmentMethod = 'auto', @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) this.assignedAt});
  factory _DeliveryAssignment.fromJson(Map<String, dynamic> json) => _$DeliveryAssignmentFromJson(json);

@override final  String id;
@override final  String orderId;
@override final  String driverId;
@override@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) final  DateTime pickupTime;
@override@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? deliveredTime;
@override final  String deliveryLocation;
/// Customer phone number for coordination during the trip.
@override final  String? customerPhone;
@override@JsonKey() final  double latitude;
@override@JsonKey() final  double longitude;
@override@JsonKey(fromJson: _deliveryStatusFromJson, toJson: _deliveryStatusToString, includeIfNull: false) final  DeliveryStatus deliveryStatus;
@override final  double? deliveryFee;
@override final  String? routeOptimized;
@override final  double? routeDistanceMeters;
/// Display-only enrichment joined from the driver's profile (nullable
/// because local/seeded assignments have no profile row to join).
@override final  String? driverName;
@override final  String? driverPhone;
@override final  double? driverRating;
@override final  String? vehicleInfo;
/// How the assignment was dispatched: 'auto' or 'manual'.
@override@JsonKey() final  String assignmentMethod;
@override@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? assignedAt;

/// Create a copy of DeliveryAssignment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryAssignmentCopyWith<_DeliveryAssignment> get copyWith => __$DeliveryAssignmentCopyWithImpl<_DeliveryAssignment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryAssignmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryAssignment&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.pickupTime, pickupTime) || other.pickupTime == pickupTime)&&(identical(other.deliveredTime, deliveredTime) || other.deliveredTime == deliveredTime)&&(identical(other.deliveryLocation, deliveryLocation) || other.deliveryLocation == deliveryLocation)&&(identical(other.customerPhone, customerPhone) || other.customerPhone == customerPhone)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.deliveryStatus, deliveryStatus) || other.deliveryStatus == deliveryStatus)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.routeOptimized, routeOptimized) || other.routeOptimized == routeOptimized)&&(identical(other.routeDistanceMeters, routeDistanceMeters) || other.routeDistanceMeters == routeDistanceMeters)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.driverPhone, driverPhone) || other.driverPhone == driverPhone)&&(identical(other.driverRating, driverRating) || other.driverRating == driverRating)&&(identical(other.vehicleInfo, vehicleInfo) || other.vehicleInfo == vehicleInfo)&&(identical(other.assignmentMethod, assignmentMethod) || other.assignmentMethod == assignmentMethod)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,orderId,driverId,pickupTime,deliveredTime,deliveryLocation,customerPhone,latitude,longitude,deliveryStatus,deliveryFee,routeOptimized,routeDistanceMeters,driverName,driverPhone,driverRating,vehicleInfo,assignmentMethod,assignedAt]);

@override
String toString() {
  return 'DeliveryAssignment(id: $id, orderId: $orderId, driverId: $driverId, pickupTime: $pickupTime, deliveredTime: $deliveredTime, deliveryLocation: $deliveryLocation, customerPhone: $customerPhone, latitude: $latitude, longitude: $longitude, deliveryStatus: $deliveryStatus, deliveryFee: $deliveryFee, routeOptimized: $routeOptimized, routeDistanceMeters: $routeDistanceMeters, driverName: $driverName, driverPhone: $driverPhone, driverRating: $driverRating, vehicleInfo: $vehicleInfo, assignmentMethod: $assignmentMethod, assignedAt: $assignedAt)';
}


}

/// @nodoc
abstract mixin class _$DeliveryAssignmentCopyWith<$Res> implements $DeliveryAssignmentCopyWith<$Res> {
  factory _$DeliveryAssignmentCopyWith(_DeliveryAssignment value, $Res Function(_DeliveryAssignment) _then) = __$DeliveryAssignmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, String driverId,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime pickupTime,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? deliveredTime, String deliveryLocation, String? customerPhone, double latitude, double longitude,@JsonKey(fromJson: _deliveryStatusFromJson, toJson: _deliveryStatusToString, includeIfNull: false) DeliveryStatus deliveryStatus, double? deliveryFee, String? routeOptimized, double? routeDistanceMeters, String? driverName, String? driverPhone, double? driverRating, String? vehicleInfo, String assignmentMethod,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? assignedAt
});




}
/// @nodoc
class __$DeliveryAssignmentCopyWithImpl<$Res>
    implements _$DeliveryAssignmentCopyWith<$Res> {
  __$DeliveryAssignmentCopyWithImpl(this._self, this._then);

  final _DeliveryAssignment _self;
  final $Res Function(_DeliveryAssignment) _then;

/// Create a copy of DeliveryAssignment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? driverId = null,Object? pickupTime = null,Object? deliveredTime = freezed,Object? deliveryLocation = null,Object? customerPhone = freezed,Object? latitude = null,Object? longitude = null,Object? deliveryStatus = null,Object? deliveryFee = freezed,Object? routeOptimized = freezed,Object? routeDistanceMeters = freezed,Object? driverName = freezed,Object? driverPhone = freezed,Object? driverRating = freezed,Object? vehicleInfo = freezed,Object? assignmentMethod = null,Object? assignedAt = freezed,}) {
  return _then(_DeliveryAssignment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,pickupTime: null == pickupTime ? _self.pickupTime : pickupTime // ignore: cast_nullable_to_non_nullable
as DateTime,deliveredTime: freezed == deliveredTime ? _self.deliveredTime : deliveredTime // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveryLocation: null == deliveryLocation ? _self.deliveryLocation : deliveryLocation // ignore: cast_nullable_to_non_nullable
as String,customerPhone: freezed == customerPhone ? _self.customerPhone : customerPhone // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,deliveryStatus: null == deliveryStatus ? _self.deliveryStatus : deliveryStatus // ignore: cast_nullable_to_non_nullable
as DeliveryStatus,deliveryFee: freezed == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as double?,routeOptimized: freezed == routeOptimized ? _self.routeOptimized : routeOptimized // ignore: cast_nullable_to_non_nullable
as String?,routeDistanceMeters: freezed == routeDistanceMeters ? _self.routeDistanceMeters : routeDistanceMeters // ignore: cast_nullable_to_non_nullable
as double?,driverName: freezed == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String?,driverPhone: freezed == driverPhone ? _self.driverPhone : driverPhone // ignore: cast_nullable_to_non_nullable
as String?,driverRating: freezed == driverRating ? _self.driverRating : driverRating // ignore: cast_nullable_to_non_nullable
as double?,vehicleInfo: freezed == vehicleInfo ? _self.vehicleInfo : vehicleInfo // ignore: cast_nullable_to_non_nullable
as String?,assignmentMethod: null == assignmentMethod ? _self.assignmentMethod : assignmentMethod // ignore: cast_nullable_to_non_nullable
as String,assignedAt: freezed == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
