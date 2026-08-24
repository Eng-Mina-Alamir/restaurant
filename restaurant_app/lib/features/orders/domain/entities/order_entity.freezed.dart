// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderEntity {

 String get id; String get restaurantId; String? get customerId; String? get tableId; String? get waiterId; String? get assignedKitchenId; String? get driverId;@JsonKey(fromJson: OrderType.fromName, toJson: _orderTypeToString, includeIfNull: false) OrderType get orderType; List<OrderItem> get items;@JsonKey(fromJson: _statusFromJson, toJson: _statusToString, includeIfNull: false) OrderStatus get status; double get subtotal; double get taxAmount; double get discountAmount; double get totalAmount;@JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString) PaymentMethod? get paymentMethod; String? get deliveryAddress; String? get deliveryNotes;@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime get createdAt;@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? get completedAt; int? get estimatedMinutes;
/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderEntityCopyWith<OrderEntity> get copyWith => _$OrderEntityCopyWithImpl<OrderEntity>(this as OrderEntity, _$identity);

  /// Serializes this OrderEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.restaurantId, restaurantId) || other.restaurantId == restaurantId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.waiterId, waiterId) || other.waiterId == waiterId)&&(identical(other.assignedKitchenId, assignedKitchenId) || other.assignedKitchenId == assignedKitchenId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.status, status) || other.status == status)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.taxAmount, taxAmount) || other.taxAmount == taxAmount)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.deliveryNotes, deliveryNotes) || other.deliveryNotes == deliveryNotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.estimatedMinutes, estimatedMinutes) || other.estimatedMinutes == estimatedMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,restaurantId,customerId,tableId,waiterId,assignedKitchenId,driverId,orderType,const DeepCollectionEquality().hash(items),status,subtotal,taxAmount,discountAmount,totalAmount,paymentMethod,deliveryAddress,deliveryNotes,createdAt,completedAt,estimatedMinutes]);

@override
String toString() {
  return 'OrderEntity(id: $id, restaurantId: $restaurantId, customerId: $customerId, tableId: $tableId, waiterId: $waiterId, assignedKitchenId: $assignedKitchenId, driverId: $driverId, orderType: $orderType, items: $items, status: $status, subtotal: $subtotal, taxAmount: $taxAmount, discountAmount: $discountAmount, totalAmount: $totalAmount, paymentMethod: $paymentMethod, deliveryAddress: $deliveryAddress, deliveryNotes: $deliveryNotes, createdAt: $createdAt, completedAt: $completedAt, estimatedMinutes: $estimatedMinutes)';
}


}

/// @nodoc
abstract mixin class $OrderEntityCopyWith<$Res>  {
  factory $OrderEntityCopyWith(OrderEntity value, $Res Function(OrderEntity) _then) = _$OrderEntityCopyWithImpl;
@useResult
$Res call({
 String id, String restaurantId, String? customerId, String? tableId, String? waiterId, String? assignedKitchenId, String? driverId,@JsonKey(fromJson: OrderType.fromName, toJson: _orderTypeToString, includeIfNull: false) OrderType orderType, List<OrderItem> items,@JsonKey(fromJson: _statusFromJson, toJson: _statusToString, includeIfNull: false) OrderStatus status, double subtotal, double taxAmount, double discountAmount, double totalAmount,@JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString) PaymentMethod? paymentMethod, String? deliveryAddress, String? deliveryNotes,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime createdAt,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? completedAt, int? estimatedMinutes
});




}
/// @nodoc
class _$OrderEntityCopyWithImpl<$Res>
    implements $OrderEntityCopyWith<$Res> {
  _$OrderEntityCopyWithImpl(this._self, this._then);

  final OrderEntity _self;
  final $Res Function(OrderEntity) _then;

/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? restaurantId = null,Object? customerId = freezed,Object? tableId = freezed,Object? waiterId = freezed,Object? assignedKitchenId = freezed,Object? driverId = freezed,Object? orderType = null,Object? items = null,Object? status = null,Object? subtotal = null,Object? taxAmount = null,Object? discountAmount = null,Object? totalAmount = null,Object? paymentMethod = freezed,Object? deliveryAddress = freezed,Object? deliveryNotes = freezed,Object? createdAt = null,Object? completedAt = freezed,Object? estimatedMinutes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,tableId: freezed == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String?,waiterId: freezed == waiterId ? _self.waiterId : waiterId // ignore: cast_nullable_to_non_nullable
as String?,assignedKitchenId: freezed == assignedKitchenId ? _self.assignedKitchenId : assignedKitchenId // ignore: cast_nullable_to_non_nullable
as String?,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,orderType: null == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as OrderType,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,taxAmount: null == taxAmount ? _self.taxAmount : taxAmount // ignore: cast_nullable_to_non_nullable
as double,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod?,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryNotes: freezed == deliveryNotes ? _self.deliveryNotes : deliveryNotes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,estimatedMinutes: freezed == estimatedMinutes ? _self.estimatedMinutes : estimatedMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderEntity].
extension OrderEntityPatterns on OrderEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderEntity value)  $default,){
final _that = this;
switch (_that) {
case _OrderEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderEntity value)?  $default,){
final _that = this;
switch (_that) {
case _OrderEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String restaurantId,  String? customerId,  String? tableId,  String? waiterId,  String? assignedKitchenId,  String? driverId, @JsonKey(fromJson: OrderType.fromName, toJson: _orderTypeToString, includeIfNull: false)  OrderType orderType,  List<OrderItem> items, @JsonKey(fromJson: _statusFromJson, toJson: _statusToString, includeIfNull: false)  OrderStatus status,  double subtotal,  double taxAmount,  double discountAmount,  double totalAmount, @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString)  PaymentMethod? paymentMethod,  String? deliveryAddress,  String? deliveryNotes, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? completedAt,  int? estimatedMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderEntity() when $default != null:
return $default(_that.id,_that.restaurantId,_that.customerId,_that.tableId,_that.waiterId,_that.assignedKitchenId,_that.driverId,_that.orderType,_that.items,_that.status,_that.subtotal,_that.taxAmount,_that.discountAmount,_that.totalAmount,_that.paymentMethod,_that.deliveryAddress,_that.deliveryNotes,_that.createdAt,_that.completedAt,_that.estimatedMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String restaurantId,  String? customerId,  String? tableId,  String? waiterId,  String? assignedKitchenId,  String? driverId, @JsonKey(fromJson: OrderType.fromName, toJson: _orderTypeToString, includeIfNull: false)  OrderType orderType,  List<OrderItem> items, @JsonKey(fromJson: _statusFromJson, toJson: _statusToString, includeIfNull: false)  OrderStatus status,  double subtotal,  double taxAmount,  double discountAmount,  double totalAmount, @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString)  PaymentMethod? paymentMethod,  String? deliveryAddress,  String? deliveryNotes, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? completedAt,  int? estimatedMinutes)  $default,) {final _that = this;
switch (_that) {
case _OrderEntity():
return $default(_that.id,_that.restaurantId,_that.customerId,_that.tableId,_that.waiterId,_that.assignedKitchenId,_that.driverId,_that.orderType,_that.items,_that.status,_that.subtotal,_that.taxAmount,_that.discountAmount,_that.totalAmount,_that.paymentMethod,_that.deliveryAddress,_that.deliveryNotes,_that.createdAt,_that.completedAt,_that.estimatedMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String restaurantId,  String? customerId,  String? tableId,  String? waiterId,  String? assignedKitchenId,  String? driverId, @JsonKey(fromJson: OrderType.fromName, toJson: _orderTypeToString, includeIfNull: false)  OrderType orderType,  List<OrderItem> items, @JsonKey(fromJson: _statusFromJson, toJson: _statusToString, includeIfNull: false)  OrderStatus status,  double subtotal,  double taxAmount,  double discountAmount,  double totalAmount, @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString)  PaymentMethod? paymentMethod,  String? deliveryAddress,  String? deliveryNotes, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)  DateTime createdAt, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)  DateTime? completedAt,  int? estimatedMinutes)?  $default,) {final _that = this;
switch (_that) {
case _OrderEntity() when $default != null:
return $default(_that.id,_that.restaurantId,_that.customerId,_that.tableId,_that.waiterId,_that.assignedKitchenId,_that.driverId,_that.orderType,_that.items,_that.status,_that.subtotal,_that.taxAmount,_that.discountAmount,_that.totalAmount,_that.paymentMethod,_that.deliveryAddress,_that.deliveryNotes,_that.createdAt,_that.completedAt,_that.estimatedMinutes);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _OrderEntity implements OrderEntity {
  const _OrderEntity({required this.id, required this.restaurantId, this.customerId, this.tableId, this.waiterId, this.assignedKitchenId, this.driverId, @JsonKey(fromJson: OrderType.fromName, toJson: _orderTypeToString, includeIfNull: false) required this.orderType, final  List<OrderItem> items = const <OrderItem>[], @JsonKey(fromJson: _statusFromJson, toJson: _statusToString, includeIfNull: false) required this.status, this.subtotal = 0, this.taxAmount = 0, this.discountAmount = 0, this.totalAmount = 0, @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString) this.paymentMethod, this.deliveryAddress, this.deliveryNotes, @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) required this.createdAt, @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) this.completedAt, this.estimatedMinutes}): _items = items;
  factory _OrderEntity.fromJson(Map<String, dynamic> json) => _$OrderEntityFromJson(json);

@override final  String id;
@override final  String restaurantId;
@override final  String? customerId;
@override final  String? tableId;
@override final  String? waiterId;
@override final  String? assignedKitchenId;
@override final  String? driverId;
@override@JsonKey(fromJson: OrderType.fromName, toJson: _orderTypeToString, includeIfNull: false) final  OrderType orderType;
 final  List<OrderItem> _items;
@override@JsonKey() List<OrderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(fromJson: _statusFromJson, toJson: _statusToString, includeIfNull: false) final  OrderStatus status;
@override@JsonKey() final  double subtotal;
@override@JsonKey() final  double taxAmount;
@override@JsonKey() final  double discountAmount;
@override@JsonKey() final  double totalAmount;
@override@JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString) final  PaymentMethod? paymentMethod;
@override final  String? deliveryAddress;
@override final  String? deliveryNotes;
@override@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) final  DateTime createdAt;
@override@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) final  DateTime? completedAt;
@override final  int? estimatedMinutes;

/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderEntityCopyWith<_OrderEntity> get copyWith => __$OrderEntityCopyWithImpl<_OrderEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.restaurantId, restaurantId) || other.restaurantId == restaurantId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.tableId, tableId) || other.tableId == tableId)&&(identical(other.waiterId, waiterId) || other.waiterId == waiterId)&&(identical(other.assignedKitchenId, assignedKitchenId) || other.assignedKitchenId == assignedKitchenId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.status, status) || other.status == status)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.taxAmount, taxAmount) || other.taxAmount == taxAmount)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.deliveryNotes, deliveryNotes) || other.deliveryNotes == deliveryNotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.estimatedMinutes, estimatedMinutes) || other.estimatedMinutes == estimatedMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,restaurantId,customerId,tableId,waiterId,assignedKitchenId,driverId,orderType,const DeepCollectionEquality().hash(_items),status,subtotal,taxAmount,discountAmount,totalAmount,paymentMethod,deliveryAddress,deliveryNotes,createdAt,completedAt,estimatedMinutes]);

@override
String toString() {
  return 'OrderEntity(id: $id, restaurantId: $restaurantId, customerId: $customerId, tableId: $tableId, waiterId: $waiterId, assignedKitchenId: $assignedKitchenId, driverId: $driverId, orderType: $orderType, items: $items, status: $status, subtotal: $subtotal, taxAmount: $taxAmount, discountAmount: $discountAmount, totalAmount: $totalAmount, paymentMethod: $paymentMethod, deliveryAddress: $deliveryAddress, deliveryNotes: $deliveryNotes, createdAt: $createdAt, completedAt: $completedAt, estimatedMinutes: $estimatedMinutes)';
}


}

/// @nodoc
abstract mixin class _$OrderEntityCopyWith<$Res> implements $OrderEntityCopyWith<$Res> {
  factory _$OrderEntityCopyWith(_OrderEntity value, $Res Function(_OrderEntity) _then) = __$OrderEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String restaurantId, String? customerId, String? tableId, String? waiterId, String? assignedKitchenId, String? driverId,@JsonKey(fromJson: OrderType.fromName, toJson: _orderTypeToString, includeIfNull: false) OrderType orderType, List<OrderItem> items,@JsonKey(fromJson: _statusFromJson, toJson: _statusToString, includeIfNull: false) OrderStatus status, double subtotal, double taxAmount, double discountAmount, double totalAmount,@JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString) PaymentMethod? paymentMethod, String? deliveryAddress, String? deliveryNotes,@JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson) DateTime createdAt,@JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson) DateTime? completedAt, int? estimatedMinutes
});




}
/// @nodoc
class __$OrderEntityCopyWithImpl<$Res>
    implements _$OrderEntityCopyWith<$Res> {
  __$OrderEntityCopyWithImpl(this._self, this._then);

  final _OrderEntity _self;
  final $Res Function(_OrderEntity) _then;

/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? restaurantId = null,Object? customerId = freezed,Object? tableId = freezed,Object? waiterId = freezed,Object? assignedKitchenId = freezed,Object? driverId = freezed,Object? orderType = null,Object? items = null,Object? status = null,Object? subtotal = null,Object? taxAmount = null,Object? discountAmount = null,Object? totalAmount = null,Object? paymentMethod = freezed,Object? deliveryAddress = freezed,Object? deliveryNotes = freezed,Object? createdAt = null,Object? completedAt = freezed,Object? estimatedMinutes = freezed,}) {
  return _then(_OrderEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,tableId: freezed == tableId ? _self.tableId : tableId // ignore: cast_nullable_to_non_nullable
as String?,waiterId: freezed == waiterId ? _self.waiterId : waiterId // ignore: cast_nullable_to_non_nullable
as String?,assignedKitchenId: freezed == assignedKitchenId ? _self.assignedKitchenId : assignedKitchenId // ignore: cast_nullable_to_non_nullable
as String?,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,orderType: null == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as OrderType,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,taxAmount: null == taxAmount ? _self.taxAmount : taxAmount // ignore: cast_nullable_to_non_nullable
as double,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod?,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryNotes: freezed == deliveryNotes ? _self.deliveryNotes : deliveryNotes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,estimatedMinutes: freezed == estimatedMinutes ? _self.estimatedMinutes : estimatedMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
