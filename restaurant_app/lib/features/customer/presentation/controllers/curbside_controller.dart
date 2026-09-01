import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/curbside_pickup_entity.dart';

/// Controller for managing Curbside Car Pickup vehicle details and live arrival signal.
class CurbsideController extends StateNotifier<CurbsideVehicleInfo?> {
  CurbsideController() : super(null);

  /// Registers car info during checkout.
  void setVehicleInfo({
    required String carModel,
    required String carColor,
    required String licensePlate,
    String? parkingSpotNote,
  }) {
    state = CurbsideVehicleInfo(
      carModel: carModel,
      carColor: carColor,
      licensePlate: licensePlate,
      parkingSpotNote: parkingSpotNote,
      status: CurbsideArrivalStatus.onTheWay,
    );
  }

  /// Sends the "I'm Here - Arrived Outside" signal when the customer parks at the restaurant.
  void signalArrival() {
    if (state == null) return;
    state = state!.copyWith(
      status: CurbsideArrivalStatus.arrivedOutside,
      arrivedAt: DateTime.now(),
    );
  }

  /// Marks car delivery as completed.
  void markDelivered() {
    if (state == null) return;
    state = state!.copyWith(
      status: CurbsideArrivalStatus.deliveredToCar,
    );
  }

  /// Clears vehicle info.
  void clear() {
    state = null;
  }
}

final curbsideControllerProvider =
    StateNotifierProvider<CurbsideController, CurbsideVehicleInfo?>((ref) {
  return CurbsideController();
});
