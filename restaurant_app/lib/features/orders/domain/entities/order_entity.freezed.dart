// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OrderEntity _$OrderEntityFromJson(Map<String, dynamic> json) {
  return _OrderEntity.fromJson(json);
}

/// @nodoc
mixin _$OrderEntity {
  String get id => throw _privateConstructorUsedError;
  String get restaurantId => throw _privateConstructorUsedError;
  String? get customerId => throw _privateConstructorUsedError;
  String? get tableId => throw _privateConstructorUsedError;
  String? get waiterId => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: OrderType.fromName,
    toJson: _orderTypeToString,
    includeIfNull: false,
  )
  OrderType get orderType => throw _privateConstructorUsedError;
  List<OrderItem> get items => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: _statusFromJson,
    toJson: _statusToString,
    includeIfNull: false,
  )
  OrderStatus get status => throw _privateConstructorUsedError;
  double get subtotal => throw _privateConstructorUsedError;
  double get taxAmount => throw _privateConstructorUsedError;
  double get discountAmount => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString)
  PaymentMethod? get paymentMethod => throw _privateConstructorUsedError;
  String? get deliveryAddress => throw _privateConstructorUsedError;
  String? get deliveryNotes => throw _privateConstructorUsedError;
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
  DateTime? get completedAt => throw _privateConstructorUsedError;
  int? get estimatedMinutes => throw _privateConstructorUsedError;

  /// Serializes this OrderEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderEntityCopyWith<OrderEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderEntityCopyWith<$Res> {
  factory $OrderEntityCopyWith(
    OrderEntity value,
    $Res Function(OrderEntity) then,
  ) = _$OrderEntityCopyWithImpl<$Res, OrderEntity>;
  @useResult
  $Res call({
    String id,
    String restaurantId,
    String? customerId,
    String? tableId,
    String? waiterId,
    @JsonKey(
      fromJson: OrderType.fromName,
      toJson: _orderTypeToString,
      includeIfNull: false,
    )
    OrderType orderType,
    List<OrderItem> items,
    @JsonKey(
      fromJson: _statusFromJson,
      toJson: _statusToString,
      includeIfNull: false,
    )
    OrderStatus status,
    double subtotal,
    double taxAmount,
    double discountAmount,
    double totalAmount,
    @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString)
    PaymentMethod? paymentMethod,
    String? deliveryAddress,
    String? deliveryNotes,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    DateTime createdAt,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? completedAt,
    int? estimatedMinutes,
  });
}

/// @nodoc
class _$OrderEntityCopyWithImpl<$Res, $Val extends OrderEntity>
    implements $OrderEntityCopyWith<$Res> {
  _$OrderEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? restaurantId = null,
    Object? customerId = freezed,
    Object? tableId = freezed,
    Object? waiterId = freezed,
    Object? orderType = null,
    Object? items = null,
    Object? status = null,
    Object? subtotal = null,
    Object? taxAmount = null,
    Object? discountAmount = null,
    Object? totalAmount = null,
    Object? paymentMethod = freezed,
    Object? deliveryAddress = freezed,
    Object? deliveryNotes = freezed,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? estimatedMinutes = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            restaurantId: null == restaurantId
                ? _value.restaurantId
                : restaurantId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerId: freezed == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            tableId: freezed == tableId
                ? _value.tableId
                : tableId // ignore: cast_nullable_to_non_nullable
                      as String?,
            waiterId: freezed == waiterId
                ? _value.waiterId
                : waiterId // ignore: cast_nullable_to_non_nullable
                      as String?,
            orderType: null == orderType
                ? _value.orderType
                : orderType // ignore: cast_nullable_to_non_nullable
                      as OrderType,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<OrderItem>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as OrderStatus,
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as double,
            taxAmount: null == taxAmount
                ? _value.taxAmount
                : taxAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            discountAmount: null == discountAmount
                ? _value.discountAmount
                : discountAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            totalAmount: null == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            paymentMethod: freezed == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as PaymentMethod?,
            deliveryAddress: freezed == deliveryAddress
                ? _value.deliveryAddress
                : deliveryAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            deliveryNotes: freezed == deliveryNotes
                ? _value.deliveryNotes
                : deliveryNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            estimatedMinutes: freezed == estimatedMinutes
                ? _value.estimatedMinutes
                : estimatedMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrderEntityImplCopyWith<$Res>
    implements $OrderEntityCopyWith<$Res> {
  factory _$$OrderEntityImplCopyWith(
    _$OrderEntityImpl value,
    $Res Function(_$OrderEntityImpl) then,
  ) = __$$OrderEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String restaurantId,
    String? customerId,
    String? tableId,
    String? waiterId,
    @JsonKey(
      fromJson: OrderType.fromName,
      toJson: _orderTypeToString,
      includeIfNull: false,
    )
    OrderType orderType,
    List<OrderItem> items,
    @JsonKey(
      fromJson: _statusFromJson,
      toJson: _statusToString,
      includeIfNull: false,
    )
    OrderStatus status,
    double subtotal,
    double taxAmount,
    double discountAmount,
    double totalAmount,
    @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString)
    PaymentMethod? paymentMethod,
    String? deliveryAddress,
    String? deliveryNotes,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    DateTime createdAt,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? completedAt,
    int? estimatedMinutes,
  });
}

/// @nodoc
class __$$OrderEntityImplCopyWithImpl<$Res>
    extends _$OrderEntityCopyWithImpl<$Res, _$OrderEntityImpl>
    implements _$$OrderEntityImplCopyWith<$Res> {
  __$$OrderEntityImplCopyWithImpl(
    _$OrderEntityImpl _value,
    $Res Function(_$OrderEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? restaurantId = null,
    Object? customerId = freezed,
    Object? tableId = freezed,
    Object? waiterId = freezed,
    Object? orderType = null,
    Object? items = null,
    Object? status = null,
    Object? subtotal = null,
    Object? taxAmount = null,
    Object? discountAmount = null,
    Object? totalAmount = null,
    Object? paymentMethod = freezed,
    Object? deliveryAddress = freezed,
    Object? deliveryNotes = freezed,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? estimatedMinutes = freezed,
  }) {
    return _then(
      _$OrderEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        restaurantId: null == restaurantId
            ? _value.restaurantId
            : restaurantId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerId: freezed == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        tableId: freezed == tableId
            ? _value.tableId
            : tableId // ignore: cast_nullable_to_non_nullable
                  as String?,
        waiterId: freezed == waiterId
            ? _value.waiterId
            : waiterId // ignore: cast_nullable_to_non_nullable
                  as String?,
        orderType: null == orderType
            ? _value.orderType
            : orderType // ignore: cast_nullable_to_non_nullable
                  as OrderType,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<OrderItem>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as OrderStatus,
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as double,
        taxAmount: null == taxAmount
            ? _value.taxAmount
            : taxAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        discountAmount: null == discountAmount
            ? _value.discountAmount
            : discountAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        totalAmount: null == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        paymentMethod: freezed == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as PaymentMethod?,
        deliveryAddress: freezed == deliveryAddress
            ? _value.deliveryAddress
            : deliveryAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        deliveryNotes: freezed == deliveryNotes
            ? _value.deliveryNotes
            : deliveryNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        estimatedMinutes: freezed == estimatedMinutes
            ? _value.estimatedMinutes
            : estimatedMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$OrderEntityImpl implements _OrderEntity {
  const _$OrderEntityImpl({
    required this.id,
    required this.restaurantId,
    this.customerId,
    this.tableId,
    this.waiterId,
    @JsonKey(
      fromJson: OrderType.fromName,
      toJson: _orderTypeToString,
      includeIfNull: false,
    )
    required this.orderType,
    final List<OrderItem> items = const <OrderItem>[],
    @JsonKey(
      fromJson: _statusFromJson,
      toJson: _statusToString,
      includeIfNull: false,
    )
    required this.status,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString)
    this.paymentMethod,
    this.deliveryAddress,
    this.deliveryNotes,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required this.createdAt,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    this.completedAt,
    this.estimatedMinutes,
  }) : _items = items;

  factory _$OrderEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String restaurantId;
  @override
  final String? customerId;
  @override
  final String? tableId;
  @override
  final String? waiterId;
  @override
  @JsonKey(
    fromJson: OrderType.fromName,
    toJson: _orderTypeToString,
    includeIfNull: false,
  )
  final OrderType orderType;
  final List<OrderItem> _items;
  @override
  @JsonKey()
  List<OrderItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey(
    fromJson: _statusFromJson,
    toJson: _statusToString,
    includeIfNull: false,
  )
  final OrderStatus status;
  @override
  @JsonKey()
  final double subtotal;
  @override
  @JsonKey()
  final double taxAmount;
  @override
  @JsonKey()
  final double discountAmount;
  @override
  @JsonKey()
  final double totalAmount;
  @override
  @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString)
  final PaymentMethod? paymentMethod;
  @override
  final String? deliveryAddress;
  @override
  final String? deliveryNotes;
  @override
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  final DateTime createdAt;
  @override
  @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
  final DateTime? completedAt;
  @override
  final int? estimatedMinutes;

  @override
  String toString() {
    return 'OrderEntity(id: $id, restaurantId: $restaurantId, customerId: $customerId, tableId: $tableId, waiterId: $waiterId, orderType: $orderType, items: $items, status: $status, subtotal: $subtotal, taxAmount: $taxAmount, discountAmount: $discountAmount, totalAmount: $totalAmount, paymentMethod: $paymentMethod, deliveryAddress: $deliveryAddress, deliveryNotes: $deliveryNotes, createdAt: $createdAt, completedAt: $completedAt, estimatedMinutes: $estimatedMinutes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.restaurantId, restaurantId) ||
                other.restaurantId == restaurantId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.tableId, tableId) || other.tableId == tableId) &&
            (identical(other.waiterId, waiterId) ||
                other.waiterId == waiterId) &&
            (identical(other.orderType, orderType) ||
                other.orderType == orderType) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.taxAmount, taxAmount) ||
                other.taxAmount == taxAmount) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.deliveryAddress, deliveryAddress) ||
                other.deliveryAddress == deliveryAddress) &&
            (identical(other.deliveryNotes, deliveryNotes) ||
                other.deliveryNotes == deliveryNotes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.estimatedMinutes, estimatedMinutes) ||
                other.estimatedMinutes == estimatedMinutes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    restaurantId,
    customerId,
    tableId,
    waiterId,
    orderType,
    const DeepCollectionEquality().hash(_items),
    status,
    subtotal,
    taxAmount,
    discountAmount,
    totalAmount,
    paymentMethod,
    deliveryAddress,
    deliveryNotes,
    createdAt,
    completedAt,
    estimatedMinutes,
  );

  /// Create a copy of OrderEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderEntityImplCopyWith<_$OrderEntityImpl> get copyWith =>
      __$$OrderEntityImplCopyWithImpl<_$OrderEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderEntityImplToJson(this);
  }
}

abstract class _OrderEntity implements OrderEntity {
  const factory _OrderEntity({
    required final String id,
    required final String restaurantId,
    final String? customerId,
    final String? tableId,
    final String? waiterId,
    @JsonKey(
      fromJson: OrderType.fromName,
      toJson: _orderTypeToString,
      includeIfNull: false,
    )
    required final OrderType orderType,
    final List<OrderItem> items,
    @JsonKey(
      fromJson: _statusFromJson,
      toJson: _statusToString,
      includeIfNull: false,
    )
    required final OrderStatus status,
    final double subtotal,
    final double taxAmount,
    final double discountAmount,
    final double totalAmount,
    @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString)
    final PaymentMethod? paymentMethod,
    final String? deliveryAddress,
    final String? deliveryNotes,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required final DateTime createdAt,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    final DateTime? completedAt,
    final int? estimatedMinutes,
  }) = _$OrderEntityImpl;

  factory _OrderEntity.fromJson(Map<String, dynamic> json) =
      _$OrderEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get restaurantId;
  @override
  String? get customerId;
  @override
  String? get tableId;
  @override
  String? get waiterId;
  @override
  @JsonKey(
    fromJson: OrderType.fromName,
    toJson: _orderTypeToString,
    includeIfNull: false,
  )
  OrderType get orderType;
  @override
  List<OrderItem> get items;
  @override
  @JsonKey(
    fromJson: _statusFromJson,
    toJson: _statusToString,
    includeIfNull: false,
  )
  OrderStatus get status;
  @override
  double get subtotal;
  @override
  double get taxAmount;
  @override
  double get discountAmount;
  @override
  double get totalAmount;
  @override
  @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString)
  PaymentMethod? get paymentMethod;
  @override
  String? get deliveryAddress;
  @override
  String? get deliveryNotes;
  @override
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  DateTime get createdAt;
  @override
  @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
  DateTime? get completedAt;
  @override
  int? get estimatedMinutes;

  /// Create a copy of OrderEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderEntityImplCopyWith<_$OrderEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
