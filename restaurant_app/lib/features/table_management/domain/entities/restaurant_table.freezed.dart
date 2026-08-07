// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restaurant_table.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RestaurantTable _$RestaurantTableFromJson(Map<String, dynamic> json) {
  return _RestaurantTable.fromJson(json);
}

/// @nodoc
mixin _$RestaurantTable {
  String get id => throw _privateConstructorUsedError;
  int get tableNumber => throw _privateConstructorUsedError;
  int get capacity => throw _privateConstructorUsedError;

  /// Physical zone/location of the table (e.g. "صالة", "حديقة", "تراس").
  String get location => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: _tableStatusFromJson,
    toJson: _tableStatusToString,
    includeIfNull: false,
  )
  TableStatus get status => throw _privateConstructorUsedError;
  String? get currentOrderId => throw _privateConstructorUsedError;
  String? get assignedWaiterId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  /// Serializes this RestaurantTable to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RestaurantTable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RestaurantTableCopyWith<RestaurantTable> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RestaurantTableCopyWith<$Res> {
  factory $RestaurantTableCopyWith(
    RestaurantTable value,
    $Res Function(RestaurantTable) then,
  ) = _$RestaurantTableCopyWithImpl<$Res, RestaurantTable>;
  @useResult
  $Res call({
    String id,
    int tableNumber,
    int capacity,
    String location,
    @JsonKey(
      fromJson: _tableStatusFromJson,
      toJson: _tableStatusToString,
      includeIfNull: false,
    )
    TableStatus status,
    String? currentOrderId,
    String? assignedWaiterId,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? lastUpdated,
  });
}

/// @nodoc
class _$RestaurantTableCopyWithImpl<$Res, $Val extends RestaurantTable>
    implements $RestaurantTableCopyWith<$Res> {
  _$RestaurantTableCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RestaurantTable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tableNumber = null,
    Object? capacity = null,
    Object? location = null,
    Object? status = null,
    Object? currentOrderId = freezed,
    Object? assignedWaiterId = freezed,
    Object? lastUpdated = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            tableNumber: null == tableNumber
                ? _value.tableNumber
                : tableNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            capacity: null == capacity
                ? _value.capacity
                : capacity // ignore: cast_nullable_to_non_nullable
                      as int,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TableStatus,
            currentOrderId: freezed == currentOrderId
                ? _value.currentOrderId
                : currentOrderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignedWaiterId: freezed == assignedWaiterId
                ? _value.assignedWaiterId
                : assignedWaiterId // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastUpdated: freezed == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RestaurantTableImplCopyWith<$Res>
    implements $RestaurantTableCopyWith<$Res> {
  factory _$$RestaurantTableImplCopyWith(
    _$RestaurantTableImpl value,
    $Res Function(_$RestaurantTableImpl) then,
  ) = __$$RestaurantTableImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    int tableNumber,
    int capacity,
    String location,
    @JsonKey(
      fromJson: _tableStatusFromJson,
      toJson: _tableStatusToString,
      includeIfNull: false,
    )
    TableStatus status,
    String? currentOrderId,
    String? assignedWaiterId,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? lastUpdated,
  });
}

/// @nodoc
class __$$RestaurantTableImplCopyWithImpl<$Res>
    extends _$RestaurantTableCopyWithImpl<$Res, _$RestaurantTableImpl>
    implements _$$RestaurantTableImplCopyWith<$Res> {
  __$$RestaurantTableImplCopyWithImpl(
    _$RestaurantTableImpl _value,
    $Res Function(_$RestaurantTableImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RestaurantTable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tableNumber = null,
    Object? capacity = null,
    Object? location = null,
    Object? status = null,
    Object? currentOrderId = freezed,
    Object? assignedWaiterId = freezed,
    Object? lastUpdated = freezed,
  }) {
    return _then(
      _$RestaurantTableImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        tableNumber: null == tableNumber
            ? _value.tableNumber
            : tableNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        capacity: null == capacity
            ? _value.capacity
            : capacity // ignore: cast_nullable_to_non_nullable
                  as int,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TableStatus,
        currentOrderId: freezed == currentOrderId
            ? _value.currentOrderId
            : currentOrderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignedWaiterId: freezed == assignedWaiterId
            ? _value.assignedWaiterId
            : assignedWaiterId // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastUpdated: freezed == lastUpdated
            ? _value.lastUpdated
            : lastUpdated // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RestaurantTableImpl implements _RestaurantTable {
  const _$RestaurantTableImpl({
    required this.id,
    required this.tableNumber,
    this.capacity = 4,
    this.location = 'صالة',
    @JsonKey(
      fromJson: _tableStatusFromJson,
      toJson: _tableStatusToString,
      includeIfNull: false,
    )
    required this.status,
    this.currentOrderId,
    this.assignedWaiterId,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    this.lastUpdated,
  });

  factory _$RestaurantTableImpl.fromJson(Map<String, dynamic> json) =>
      _$$RestaurantTableImplFromJson(json);

  @override
  final String id;
  @override
  final int tableNumber;
  @override
  @JsonKey()
  final int capacity;

  /// Physical zone/location of the table (e.g. "صالة", "حديقة", "تراس").
  @override
  @JsonKey()
  final String location;
  @override
  @JsonKey(
    fromJson: _tableStatusFromJson,
    toJson: _tableStatusToString,
    includeIfNull: false,
  )
  final TableStatus status;
  @override
  final String? currentOrderId;
  @override
  final String? assignedWaiterId;
  @override
  @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
  final DateTime? lastUpdated;

  @override
  String toString() {
    return 'RestaurantTable(id: $id, tableNumber: $tableNumber, capacity: $capacity, location: $location, status: $status, currentOrderId: $currentOrderId, assignedWaiterId: $assignedWaiterId, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestaurantTableImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tableNumber, tableNumber) ||
                other.tableNumber == tableNumber) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentOrderId, currentOrderId) ||
                other.currentOrderId == currentOrderId) &&
            (identical(other.assignedWaiterId, assignedWaiterId) ||
                other.assignedWaiterId == assignedWaiterId) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tableNumber,
    capacity,
    location,
    status,
    currentOrderId,
    assignedWaiterId,
    lastUpdated,
  );

  /// Create a copy of RestaurantTable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RestaurantTableImplCopyWith<_$RestaurantTableImpl> get copyWith =>
      __$$RestaurantTableImplCopyWithImpl<_$RestaurantTableImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RestaurantTableImplToJson(this);
  }
}

abstract class _RestaurantTable implements RestaurantTable {
  const factory _RestaurantTable({
    required final String id,
    required final int tableNumber,
    final int capacity,
    final String location,
    @JsonKey(
      fromJson: _tableStatusFromJson,
      toJson: _tableStatusToString,
      includeIfNull: false,
    )
    required final TableStatus status,
    final String? currentOrderId,
    final String? assignedWaiterId,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    final DateTime? lastUpdated,
  }) = _$RestaurantTableImpl;

  factory _RestaurantTable.fromJson(Map<String, dynamic> json) =
      _$RestaurantTableImpl.fromJson;

  @override
  String get id;
  @override
  int get tableNumber;
  @override
  int get capacity;

  /// Physical zone/location of the table (e.g. "صالة", "حديقة", "تراس").
  @override
  String get location;
  @override
  @JsonKey(
    fromJson: _tableStatusFromJson,
    toJson: _tableStatusToString,
    includeIfNull: false,
  )
  TableStatus get status;
  @override
  String? get currentOrderId;
  @override
  String? get assignedWaiterId;
  @override
  @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
  DateTime? get lastUpdated;

  /// Create a copy of RestaurantTable
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RestaurantTableImplCopyWith<_$RestaurantTableImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
