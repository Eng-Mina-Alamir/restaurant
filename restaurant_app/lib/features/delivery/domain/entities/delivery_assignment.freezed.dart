// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_assignment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DeliveryAssignment _$DeliveryAssignmentFromJson(Map<String, dynamic> json) {
  return _DeliveryAssignment.fromJson(json);
}

/// @nodoc
mixin _$DeliveryAssignment {
  String get id => throw _privateConstructorUsedError;
  String get orderId => throw _privateConstructorUsedError;
  String get driverId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  DateTime get pickupTime => throw _privateConstructorUsedError;
  @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
  DateTime? get deliveredTime => throw _privateConstructorUsedError;
  String get deliveryLocation => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: _deliveryStatusFromJson,
    toJson: _deliveryStatusToString,
    includeIfNull: false,
  )
  DeliveryStatus get deliveryStatus => throw _privateConstructorUsedError;
  double? get deliveryFee => throw _privateConstructorUsedError;
  String? get routeOptimized => throw _privateConstructorUsedError;
  double? get routeDistanceMeters => throw _privateConstructorUsedError;

  /// Serializes this DeliveryAssignment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeliveryAssignment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeliveryAssignmentCopyWith<DeliveryAssignment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeliveryAssignmentCopyWith<$Res> {
  factory $DeliveryAssignmentCopyWith(
    DeliveryAssignment value,
    $Res Function(DeliveryAssignment) then,
  ) = _$DeliveryAssignmentCopyWithImpl<$Res, DeliveryAssignment>;
  @useResult
  $Res call({
    String id,
    String orderId,
    String driverId,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    DateTime pickupTime,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? deliveredTime,
    String deliveryLocation,
    double latitude,
    double longitude,
    @JsonKey(
      fromJson: _deliveryStatusFromJson,
      toJson: _deliveryStatusToString,
      includeIfNull: false,
    )
    DeliveryStatus deliveryStatus,
    double? deliveryFee,
    String? routeOptimized,
    double? routeDistanceMeters,
  });
}

/// @nodoc
class _$DeliveryAssignmentCopyWithImpl<$Res, $Val extends DeliveryAssignment>
    implements $DeliveryAssignmentCopyWith<$Res> {
  _$DeliveryAssignmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeliveryAssignment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? driverId = null,
    Object? pickupTime = null,
    Object? deliveredTime = freezed,
    Object? deliveryLocation = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? deliveryStatus = null,
    Object? deliveryFee = freezed,
    Object? routeOptimized = freezed,
    Object? routeDistanceMeters = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            orderId: null == orderId
                ? _value.orderId
                : orderId // ignore: cast_nullable_to_non_nullable
                      as String,
            driverId: null == driverId
                ? _value.driverId
                : driverId // ignore: cast_nullable_to_non_nullable
                      as String,
            pickupTime: null == pickupTime
                ? _value.pickupTime
                : pickupTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            deliveredTime: freezed == deliveredTime
                ? _value.deliveredTime
                : deliveredTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            deliveryLocation: null == deliveryLocation
                ? _value.deliveryLocation
                : deliveryLocation // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            deliveryStatus: null == deliveryStatus
                ? _value.deliveryStatus
                : deliveryStatus // ignore: cast_nullable_to_non_nullable
                      as DeliveryStatus,
            deliveryFee: freezed == deliveryFee
                ? _value.deliveryFee
                : deliveryFee // ignore: cast_nullable_to_non_nullable
                      as double?,
            routeOptimized: freezed == routeOptimized
                ? _value.routeOptimized
                : routeOptimized // ignore: cast_nullable_to_non_nullable
                      as String?,
            routeDistanceMeters: freezed == routeDistanceMeters
                ? _value.routeDistanceMeters
                : routeDistanceMeters // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeliveryAssignmentImplCopyWith<$Res>
    implements $DeliveryAssignmentCopyWith<$Res> {
  factory _$$DeliveryAssignmentImplCopyWith(
    _$DeliveryAssignmentImpl value,
    $Res Function(_$DeliveryAssignmentImpl) then,
  ) = __$$DeliveryAssignmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String orderId,
    String driverId,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    DateTime pickupTime,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? deliveredTime,
    String deliveryLocation,
    double latitude,
    double longitude,
    @JsonKey(
      fromJson: _deliveryStatusFromJson,
      toJson: _deliveryStatusToString,
      includeIfNull: false,
    )
    DeliveryStatus deliveryStatus,
    double? deliveryFee,
    String? routeOptimized,
    double? routeDistanceMeters,
  });
}

/// @nodoc
class __$$DeliveryAssignmentImplCopyWithImpl<$Res>
    extends _$DeliveryAssignmentCopyWithImpl<$Res, _$DeliveryAssignmentImpl>
    implements _$$DeliveryAssignmentImplCopyWith<$Res> {
  __$$DeliveryAssignmentImplCopyWithImpl(
    _$DeliveryAssignmentImpl _value,
    $Res Function(_$DeliveryAssignmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeliveryAssignment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = null,
    Object? driverId = null,
    Object? pickupTime = null,
    Object? deliveredTime = freezed,
    Object? deliveryLocation = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? deliveryStatus = null,
    Object? deliveryFee = freezed,
    Object? routeOptimized = freezed,
    Object? routeDistanceMeters = freezed,
  }) {
    return _then(
      _$DeliveryAssignmentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as String,
        driverId: null == driverId
            ? _value.driverId
            : driverId // ignore: cast_nullable_to_non_nullable
                  as String,
        pickupTime: null == pickupTime
            ? _value.pickupTime
            : pickupTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        deliveredTime: freezed == deliveredTime
            ? _value.deliveredTime
            : deliveredTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        deliveryLocation: null == deliveryLocation
            ? _value.deliveryLocation
            : deliveryLocation // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        deliveryStatus: null == deliveryStatus
            ? _value.deliveryStatus
            : deliveryStatus // ignore: cast_nullable_to_non_nullable
                  as DeliveryStatus,
        deliveryFee: freezed == deliveryFee
            ? _value.deliveryFee
            : deliveryFee // ignore: cast_nullable_to_non_nullable
                  as double?,
        routeOptimized: freezed == routeOptimized
            ? _value.routeOptimized
            : routeOptimized // ignore: cast_nullable_to_non_nullable
                  as String?,
        routeDistanceMeters: freezed == routeDistanceMeters
            ? _value.routeDistanceMeters
            : routeDistanceMeters // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeliveryAssignmentImpl implements _DeliveryAssignment {
  const _$DeliveryAssignmentImpl({
    required this.id,
    required this.orderId,
    required this.driverId,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required this.pickupTime,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    this.deliveredTime,
    required this.deliveryLocation,
    this.latitude = 0,
    this.longitude = 0,
    @JsonKey(
      fromJson: _deliveryStatusFromJson,
      toJson: _deliveryStatusToString,
      includeIfNull: false,
    )
    required this.deliveryStatus,
    this.deliveryFee,
    this.routeOptimized,
    this.routeDistanceMeters,
  });

  factory _$DeliveryAssignmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeliveryAssignmentImplFromJson(json);

  @override
  final String id;
  @override
  final String orderId;
  @override
  final String driverId;
  @override
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  final DateTime pickupTime;
  @override
  @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
  final DateTime? deliveredTime;
  @override
  final String deliveryLocation;
  @override
  @JsonKey()
  final double latitude;
  @override
  @JsonKey()
  final double longitude;
  @override
  @JsonKey(
    fromJson: _deliveryStatusFromJson,
    toJson: _deliveryStatusToString,
    includeIfNull: false,
  )
  final DeliveryStatus deliveryStatus;
  @override
  final double? deliveryFee;
  @override
  final String? routeOptimized;
  @override
  final double? routeDistanceMeters;

  @override
  String toString() {
    return 'DeliveryAssignment(id: $id, orderId: $orderId, driverId: $driverId, pickupTime: $pickupTime, deliveredTime: $deliveredTime, deliveryLocation: $deliveryLocation, latitude: $latitude, longitude: $longitude, deliveryStatus: $deliveryStatus, deliveryFee: $deliveryFee, routeOptimized: $routeOptimized, routeDistanceMeters: $routeDistanceMeters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryAssignmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.pickupTime, pickupTime) ||
                other.pickupTime == pickupTime) &&
            (identical(other.deliveredTime, deliveredTime) ||
                other.deliveredTime == deliveredTime) &&
            (identical(other.deliveryLocation, deliveryLocation) ||
                other.deliveryLocation == deliveryLocation) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.deliveryStatus, deliveryStatus) ||
                other.deliveryStatus == deliveryStatus) &&
            (identical(other.deliveryFee, deliveryFee) ||
                other.deliveryFee == deliveryFee) &&
            (identical(other.routeOptimized, routeOptimized) ||
                other.routeOptimized == routeOptimized) &&
            (identical(other.routeDistanceMeters, routeDistanceMeters) ||
                other.routeDistanceMeters == routeDistanceMeters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    orderId,
    driverId,
    pickupTime,
    deliveredTime,
    deliveryLocation,
    latitude,
    longitude,
    deliveryStatus,
    deliveryFee,
    routeOptimized,
    routeDistanceMeters,
  );

  /// Create a copy of DeliveryAssignment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryAssignmentImplCopyWith<_$DeliveryAssignmentImpl> get copyWith =>
      __$$DeliveryAssignmentImplCopyWithImpl<_$DeliveryAssignmentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DeliveryAssignmentImplToJson(this);
  }
}

abstract class _DeliveryAssignment implements DeliveryAssignment {
  const factory _DeliveryAssignment({
    required final String id,
    required final String orderId,
    required final String driverId,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required final DateTime pickupTime,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    final DateTime? deliveredTime,
    required final String deliveryLocation,
    final double latitude,
    final double longitude,
    @JsonKey(
      fromJson: _deliveryStatusFromJson,
      toJson: _deliveryStatusToString,
      includeIfNull: false,
    )
    required final DeliveryStatus deliveryStatus,
    final double? deliveryFee,
    final String? routeOptimized,
    final double? routeDistanceMeters,
  }) = _$DeliveryAssignmentImpl;

  factory _DeliveryAssignment.fromJson(Map<String, dynamic> json) =
      _$DeliveryAssignmentImpl.fromJson;

  @override
  String get id;
  @override
  String get orderId;
  @override
  String get driverId;
  @override
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  DateTime get pickupTime;
  @override
  @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
  DateTime? get deliveredTime;
  @override
  String get deliveryLocation;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  @JsonKey(
    fromJson: _deliveryStatusFromJson,
    toJson: _deliveryStatusToString,
    includeIfNull: false,
  )
  DeliveryStatus get deliveryStatus;
  @override
  double? get deliveryFee;
  @override
  String? get routeOptimized;
  @override
  double? get routeDistanceMeters;

  /// Create a copy of DeliveryAssignment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryAssignmentImplCopyWith<_$DeliveryAssignmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
