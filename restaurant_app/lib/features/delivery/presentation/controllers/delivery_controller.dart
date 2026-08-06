import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../data/repositories/in_memory_delivery_repository.dart';

/// Shared [DeliveryRepository].
final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return InMemoryDeliveryRepository();
});

/// Manages the current driver's delivery assignments and their status
/// (pending → accepted → in transit → delivered / failed).
class DeliveryController extends StateNotifier<List<DeliveryAssignment>> {
  DeliveryController(this._repository, this._driverId) : super(const []) {
    _load();
  }

  final DeliveryRepository _repository;
  final String _driverId;

  Future<void> _load() async {
    final result = await _repository.getAssignments(_driverId);
    state = result.when(onLeft: (_) => const [], onRight: (list) => list);
  }

  Future<void> _apply(
    String id,
    DeliveryAssignment Function(DeliveryAssignment) transform,
  ) async {
    final index = state.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = transform(state[index]);
    state = [...state]..[index] = updated;
    await _repository.updateAssignment(updated);
  }

  /// Accepts a pending assignment.
  Future<void> accept(String id) =>
      _apply(id, (a) => a.copyWith(deliveryStatus: DeliveryStatus.accepted));

  /// Marks an accepted assignment as picked up / in transit.
  Future<void> start(String id) =>
      _apply(id, (a) => a.copyWith(deliveryStatus: DeliveryStatus.inTransit));

  /// Completes the delivery, stamping the delivered time.
  Future<void> complete(String id) => _apply(
    id,
    (a) => a.copyWith(
      deliveryStatus: DeliveryStatus.delivered,
      deliveredTime: DateTime.now(),
    ),
  );

  /// Marks a delivery as failed.
  Future<void> fail(String id) =>
      _apply(id, (a) => a.copyWith(deliveryStatus: DeliveryStatus.failed));
}

/// Provider for [DeliveryController] scoped to the demo driver.
final deliveryControllerProvider =
    StateNotifierProvider<DeliveryController, List<DeliveryAssignment>>(
      (ref) => DeliveryController(
        ref.watch(deliveryRepositoryProvider),
        'driver-demo',
      ),
    );
