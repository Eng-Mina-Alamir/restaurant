import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/data/app_cache.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/network/realtime_service.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../data/repositories/hive_delivery_repository.dart';
import '../../data/repositories/in_memory_delivery_repository.dart';
import '../../data/repositories/supabase_delivery_repository.dart';

/// Shared [DeliveryRepository].
///
/// Uses the live Supabase backend when enabled, otherwise Hive-persisted
/// storage when the local cache is available, or in-memory for tests /
/// unsupported platforms.
final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  final cache = ref.watch(localCacheServiceProvider);
  if (AppConfig.useSupabase) {
    return SupabaseDeliveryRepository(
      supabase: ref.watch(supabaseClientProvider),
    );
  }
  if (cache != null) return HiveDeliveryRepository(cache);
  return InMemoryDeliveryRepository();
});

/// Manages the current driver's delivery assignments and their status
/// (pending → accepted → in transit → delivered / failed).
class DeliveryController extends StateNotifier<List<DeliveryAssignment>> {
  DeliveryController(
    this._repository,
    this._driverId, {
    RealtimeService? realtimeService,
  }) : _realtimeService = realtimeService,
       super(const []) {
    _load();
    _initRealtime();
  }

  final DeliveryRepository _repository;
  final String _driverId;
  final RealtimeService? _realtimeService;
  StreamSubscription<RealtimeEvent>? _realtimeSub;

  void _initRealtime() {
    final service = _realtimeService;
    if (service == null) return;
    _realtimeSub = service.events.listen((event) {
      if (event.type == RealtimeEventType.driverLocationUpdated) {
        try {
          final driverId = event.payload['driverId']?.toString();
          final lat = (event.payload['latitude'] as num?)?.toDouble();
          final lng = (event.payload['longitude'] as num?)?.toDouble();
          if (driverId == _driverId && lat != null && lng != null) {
            // Update active in-transit assignments coordinates
            state = state.map((a) {
              if (a.deliveryStatus == DeliveryStatus.inTransit) {
                return a.copyWith(latitude: lat, longitude: lng);
              }
              return a;
            }).toList();
          }
        } catch (_) {}
      }
    });
  }

  Future<void> _load() async {
    final result = await _repository.getAssignments(_driverId);
    state = result.when(onLeft: (_) => const [], onRight: (list) => list);
  }

  /// Persists a newly dispatched [assignment].
  ///
  /// On success the assignment is appended to state and broadcast over
  /// realtime so other clients (dispatch board, driver apps) stay in sync.
  /// Returns false when the repository rejected it.
  Future<bool> createAssignment(DeliveryAssignment assignment) async {
    final result = await _repository.createAssignment(assignment);
    final created = result.when(onLeft: (_) => null, onRight: (a) => a);
    if (created == null) return false;
    state = [
      ...state.where((a) => a.id != created.id),
      created,
    ];
    _realtimeService?.broadcastDeliveryAssignmentCreated(created.toJson());
    return true;
  }

  Future<void> _apply(
    String id,
    DeliveryAssignment Function(DeliveryAssignment) transform,
  ) async {
    final index = state.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = transform(state[index]);
    state = [...state]..[index] = updated;
    _realtimeService?.sendEvent('deliveryStatusChanged', updated.toJson());
    await _repository.updateAssignment(updated);
  }

  /// Broadcasts live driver GPS location.
  void updateLocation({required double latitude, required double longitude}) {
    _realtimeService?.broadcastDriverLocation(
      driverId: _driverId,
      latitude: latitude,
      longitude: longitude,
    );
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

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}

/// Provider for [DeliveryController] scoped to the demo driver.
final deliveryControllerProvider =
    StateNotifierProvider<DeliveryController, List<DeliveryAssignment>>(
      (ref) => DeliveryController(
        ref.watch(deliveryRepositoryProvider),
        'driver-demo',
        realtimeService: ref.watch(realtimeServiceProvider),
      ),
    );
