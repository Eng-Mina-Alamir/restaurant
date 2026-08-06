// `JsonKey` is applied inside the freezed constructor; the analyzer warning is
// a false positive for this well-known freezed pattern.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/date_converters.dart';
import '../../../../core/domain/enums.dart';
import 'order_item.dart';

part 'order_entity.freezed.dart';
part 'order_entity.g.dart';

@freezed
abstract class OrderEntity with _$OrderEntity {
  @JsonSerializable(explicitToJson: true)
  const factory OrderEntity({
    required String id,
    required String restaurantId,
    String? customerId,
    String? tableId,
    String? waiterId,
    @JsonKey(
      fromJson: OrderType.fromName,
      toJson: _orderTypeToString,
      includeIfNull: false,
    )
    required OrderType orderType,
    @Default(<OrderItem>[]) List<OrderItem> items,
    @JsonKey(
      fromJson: _statusFromJson,
      toJson: _statusToString,
      includeIfNull: false,
    )
    required OrderStatus status,
    @Default(0) double subtotal,
    @Default(0) double taxAmount,
    @Default(0) double discountAmount,
    @Default(0) double totalAmount,
    @JsonKey(fromJson: _paymentFromJson, toJson: _paymentToString)
    PaymentMethod? paymentMethod,
    String? deliveryAddress,
    String? deliveryNotes,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime createdAt,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? completedAt,
    int? estimatedMinutes,
  }) = _OrderEntity;

  factory OrderEntity.fromJson(Map<String, dynamic> json) =>
      _$OrderEntityFromJson(json);
}

String _orderTypeToString(OrderType value) => value.name;
OrderStatus _statusFromJson(String? name) => OrderStatus.fromName(name);
String _statusToString(OrderStatus value) => value.name;
PaymentMethod? _paymentFromJson(String? name) =>
    name == null ? null : PaymentMethod.fromName(name);
String? _paymentToString(PaymentMethod? value) => value?.name;
