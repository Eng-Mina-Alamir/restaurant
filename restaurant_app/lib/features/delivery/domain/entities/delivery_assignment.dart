// `JsonKey` is applied inside the freezed constructor; the analyzer warning is
// a false positive for this well-known freezed pattern.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/date_converters.dart';
import '../../../../core/domain/enums.dart';

part 'delivery_assignment.freezed.dart';
part 'delivery_assignment.g.dart';

@freezed
abstract class DeliveryAssignment with _$DeliveryAssignment {
  const factory DeliveryAssignment({
    required String id,
    required String orderId,
    required String driverId,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime pickupTime,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? deliveredTime,
    required String deliveryLocation,

    /// Customer phone number for coordination during the trip.
    String? customerPhone,
    @Default(0) double latitude,
    @Default(0) double longitude,
    @JsonKey(
      fromJson: _deliveryStatusFromJson,
      toJson: _deliveryStatusToString,
      includeIfNull: false,
    )
    required DeliveryStatus deliveryStatus,
    double? deliveryFee,
    String? routeOptimized,
    double? routeDistanceMeters,

    /// Display-only enrichment joined from the driver's profile (nullable
    /// because local/seeded assignments have no profile row to join).
    String? driverName,
    String? driverPhone,
    double? driverRating,
    String? vehicleInfo,

    /// How the assignment was dispatched: 'auto' or 'manual'.
    @Default('auto') String assignmentMethod,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? assignedAt,
  }) = _DeliveryAssignment;

  factory DeliveryAssignment.fromJson(Map<String, dynamic> json) =>
      _$DeliveryAssignmentFromJson(json);
}

DeliveryStatus _deliveryStatusFromJson(String? name) =>
    DeliveryStatus.fromName(name);
String _deliveryStatusToString(DeliveryStatus value) => value.name;
