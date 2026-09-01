import 'package:flutter/foundation.dart';

/// Status of curbside vehicle arrival.
enum CurbsideArrivalStatus {
  onTheWay,
  arrivedOutside,
  deliveredToCar;

  String get labelAr {
    switch (this) {
      case CurbsideArrivalStatus.onTheWay:
        return 'في الطريق إلى المطعم';
      case CurbsideArrivalStatus.arrivedOutside:
        return 'وصلت بالخارج أمام المطعم';
      case CurbsideArrivalStatus.deliveredToCar:
        return 'تم استلام الطلب بالسيارة';
    }
  }
}

/// Vehicle information and status for Curbside Car Pickup.
@immutable
class CurbsideVehicleInfo {
  const CurbsideVehicleInfo({
    required this.carModel,
    required this.carColor,
    required this.licensePlate,
    this.parkingSpotNote,
    this.status = CurbsideArrivalStatus.onTheWay,
    this.arrivedAt,
  });

  final String carModel;
  final String carColor;
  final String licensePlate;
  final String? parkingSpotNote;
  final CurbsideArrivalStatus status;
  final DateTime? arrivedAt;

  bool get isArrived => status == CurbsideArrivalStatus.arrivedOutside;

  CurbsideVehicleInfo copyWith({
    String? carModel,
    String? carColor,
    String? licensePlate,
    String? parkingSpotNote,
    CurbsideArrivalStatus? status,
    DateTime? arrivedAt,
  }) {
    return CurbsideVehicleInfo(
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      licensePlate: licensePlate ?? this.licensePlate,
      parkingSpotNote: parkingSpotNote ?? this.parkingSpotNote,
      status: status ?? this.status,
      arrivedAt: arrivedAt ?? this.arrivedAt,
    );
  }
}
