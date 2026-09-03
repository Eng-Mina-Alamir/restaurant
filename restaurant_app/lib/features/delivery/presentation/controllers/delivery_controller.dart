import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/data/app_cache.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/network/realtime_event.dart';
import '../../../../core/payment/payment_service.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/supabase/supabase_realtime_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/driver_info.dart';
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

/// List of drivers currently available for delivery dispatch.
final availableDriversProvider =
    FutureProvider.autoDispose<List<DriverInfo>>((ref) async {
  final repo = ref.watch(deliveryRepositoryProvider);
  final result = await repo.getAvailableDrivers();
  return result.when(
    onLeft: (failure) {
      AppLogger.warning('Failed to fetch available drivers: ${failure.message}');
      return const <DriverInfo>[];
    },
    onRight: (drivers) => drivers,
  );
});

/// Manages the current driver's delivery assignments and their status
/// (pending → accepted → in transit → delivered / failed).
class DeliveryController extends StateNotifier<List<DeliveryAssignment>> {
  DeliveryController(
    this._repository,
    this._driverId, {
    SupabaseRealtimeService? realtimeService,
    Future<void> Function(String orderId)? onDelivered,
    Future<void> Function(String orderId)? onDeliveryFailed,
  }) : _realtimeService = realtimeService,
       _onDelivered = onDelivered,
       _onDeliveryFailed = onDeliveryFailed,
       super(const []) {
    _load();
    _initRealtime();
  }

  final DeliveryRepository _repository;
  final String _driverId;
  final SupabaseRealtimeService? _realtimeService;
  StreamSubscription<RealtimeEvent>? _realtimeSub;

  /// Minimum interval between successive driver-location DB writes to avoid
  /// excessive Supabase usage during continuous urban driving.
  static const Duration _locationWriteThrottle = Duration(seconds: 5);
  DateTime? _lastLocationWrite;

  /// Optional hook fired after an assignment lands on
  /// [DeliveryStatus.delivered] so the PARENT order advances too (driver
  /// devices don't load every order, so the provider wiring writes via the
  /// repository directly). Null keeps the assignment-only behaviour.
  final Future<void> Function(String orderId)? _onDelivered;
  final Future<void> Function(String orderId)? _onDeliveryFailed;

  void _initRealtime() {
    final service = _realtimeService;
    if (service == null) return;
    _realtimeSub = service.events.listen((event) {
      if (event.type == RealtimeEventType.driverLocationUpdated) {
        try {
          final driverId = (event.payload['driver_id'] ?? event.payload['driverId'])?.toString();
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
      } else if (event.type == RealtimeEventType.deliveryAssignmentCreated) {
        try {
          // Only accept dispatches addressed to this driver.
          final targetDriverId = (event.payload['driver_id'] ?? event.payload['driverId'])?.toString();
          if (targetDriverId != _driverId) return;
          final assignment = SupabaseDeliveryRepository.fromRow(event.payload);
          if (state.any((a) => a.id == assignment.id)) return;
          // Appending grows the state list — the driver home page watches it
          // to raise the "new assignment" cue.
          state = [...state, assignment];
        } catch (e, st) {
          // Malformed payloads must never take down the dashboard.
          AppLogger.warning(
            'DeliveryController: ignored malformed deliveryAssignmentCreated '
            'event',
            error: e,
            stackTrace: st,
          );
        }
      }
    });
  }

  Future<void> _load() async {
    // No signed-in driver (demo/guest): nothing server-side may be queried
    // under a fake id — the previous 'driver-demo' fallback only produced
    // FK/RLS rejections that died silently in the repository warning logs.
    if (_driverId.isEmpty) {
      state = const [];
      return;
    }
    final result = await _repository.getAssignments(_driverId);
    state = result.when(onLeft: (_) => const [], onRight: (list) => list);
  }

  /// Persists a newly dispatched [assignment].
  ///
  /// On success the assignment is appended to state and Supabase Realtime
  /// delivers the event so other clients (dispatch board, driver apps) stay in sync.
  /// Returns false when the repository rejected it.
  Future<bool> createAssignment(DeliveryAssignment assignment) async {
    final result = await _repository.createAssignment(assignment);
    String? rejectionReason;
    final created = result.when(
      onLeft: (failure) {
        rejectionReason = failure.message;
        return null;
      },
      onRight: (a) => a,
    );
    if (created == null) {
      AppLogger.warning(
        '[Dispatch] outcome=create-rejected orderId=${assignment.orderId} '
        'driverId=${assignment.driverId} reason=$rejectionReason',
      );
      return false;
    }
    state = [...state.where((a) => a.id != created.id), created];
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
    await _repository.updateAssignment(updated);
  }

  /// Updates live driver GPS location.
  ///
  /// Writes are throttled to [_locationWriteThrottle] to avoid excessive
  /// Supabase DB upserts and Realtime broadcasts during continuous driving.
  /// When the driver has an in-transit assignment its orderId is attached to
  /// the payload so customer tracking pages can scope updates per order.
  void updateLocation({required double latitude, required double longitude}) {
    // Guard parity with _load(): never emit beacons for a fake identity.
    if (_driverId.isEmpty) return;
    final now = DateTime.now();
    if (_lastLocationWrite != null &&
        now.difference(_lastLocationWrite!) < _locationWriteThrottle) {
      return; // Throttled — too soon since last write.
    }
    _lastLocationWrite = now;

    String? activeOrderId;
    for (final a in state) {
      if (a.deliveryStatus == DeliveryStatus.inTransit) {
        activeOrderId = a.orderId;
        break;
      }
    }
    _realtimeService?.updateDriverLocation(
      driverId: _driverId,
      latitude: latitude,
      longitude: longitude,
      orderId: activeOrderId,
    );
  }

  /// Accepts a pending assignment.
  Future<void> accept(String id) =>
      _apply(id, (a) => a.copyWith(deliveryStatus: DeliveryStatus.accepted));

  /// Marks an accepted assignment as picked up / in transit.
  Future<void> start(String id) =>
      _apply(id, (a) => a.copyWith(deliveryStatus: DeliveryStatus.inTransit));

  /// Completes the delivery, stamping the delivered time.
  ///
  /// When [_onDelivered] is wired it fires best-effort afterwards so the
  /// parent order advances as well; failures are logged and swallowed.
  Future<void> complete(String id) async {
    await _apply(
      id,
      (a) => a.copyWith(
        deliveryStatus: DeliveryStatus.delivered,
        deliveredTime: DateTime.now(),
      ),
    );
    final index = state.indexWhere((a) => a.id == id);
    // Assignment unknown / unchanged — nothing was delivered, skip the hook.
    if (index == -1) return;
    await _notifyDelivered(state[index].orderId);
  }

  /// Invokes the optional [_onDelivered] hook for an order whose delivery
  /// just completed, swallowing any failure so a broken parent-order write
  /// never breaks the driver flow.
  Future<void> _notifyDelivered(String orderId) async {
    final hook = _onDelivered;
    if (hook == null) return;
    try {
      await hook(orderId);
    } catch (e, st) {
      AppLogger.warning(
        '[Delivery] outcome=on-delivered-hook-failure orderId=$orderId; '
        'assignment stays delivered (order may need manual completion)',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Marks a delivery as failed.
  Future<void> fail(String id) async {
    final index = state.indexWhere((a) => a.id == id);
    final orderId = index != -1 ? state[index].orderId : null;
    await _apply(id, (a) => a.copyWith(deliveryStatus: DeliveryStatus.failed));
    if (orderId != null && _onDeliveryFailed != null) {
      try {
        await _onDeliveryFailed(orderId);
      } catch (e, st) {
        AppLogger.warning(
          '[Delivery] onDeliveryFailed hook error: $e',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}

/// Provider for [DeliveryController] scoped to the demo driver.
///
/// The [DeliveryController] `onDelivered` hook advances the PARENT order to
/// completed once its delivery lands, then broadcasts the new status so
/// customer/waiter clients stay in sync. Driver devices don't hold every
/// order in local state ([OrdersController.updateStatus] would no-op), so
/// the write goes through the repository directly. Best-effort: failures are
/// logged inside [DeliveryController], never surfaced to the driver UI.
final deliveryControllerProvider =
    StateNotifierProvider<DeliveryController, List<DeliveryAssignment>>(
      (ref) {
        final authUser = ref.watch(authControllerProvider).user;
        final supabaseUser = ref.watch(supabaseCurrentUserProvider);
        // Empty (not a fake 'driver-demo' id) when nobody is signed in:
        // the controller then idles instead of writing FK-violating rows.
        final driverId = authUser?.id ?? supabaseUser?.id ?? '';

        return DeliveryController(
          ref.watch(deliveryRepositoryProvider),
          driverId,
          realtimeService: ref.watch(supabaseRealtimeServiceProvider),
          onDelivered: (orderId) => _completeParentOrder(ref, orderId),
          onDeliveryFailed: (orderId) async {
            AppLogger.warning(
              '[Delivery] Delivery marked failed by driver for order: $orderId',
            );
          },
        );
      },
    );

/// Advances [orderId] to [OrderStatus.completed] after a successful delivery
/// (ready → completed is a legal transition). Skips orders that are unknown
/// to this backend or already terminal — re-completing must never regress a
/// cancelled order.
Future<void> _completeParentOrder(Ref ref, String orderId) async {
  final orderRepo = ref.read(orderRepositoryProvider);
  final result = await orderRepo.getOrderById(orderId);
  final order = result.when(
    onLeft: (_) => null,
    onRight: (o) => o,
  );
  if (order == null || order.status.isTerminal) return;
  await orderRepo.updateOrderStatus(
    orderId,
    OrderStatus.completed,
  );

  // If cash on delivery, record payment transaction so driver/cashier remittance is accurate
  if (order.paymentMethod == PaymentMethod.cash) {
    try {
      final paymentService = ref.read(paymentServiceProvider);
      await paymentService.payForOrder(
        orderId: orderId,
        amount: order.totalAmount,
        method: PaymentMethod.cash,
        phone: order.deliveryNotes,
      );
    } catch (e) {
      AppLogger.warning('Failed to record COD payment for order $orderId: $e');
    }
  }
}

/// Fetches the assignment linked to [orderId] for the customer tracking UI.
///
/// Auto-dispose: the query lives only while a tracking page watches it.
/// Returns null when no driver has been assigned yet (order still pending /
/// not dispatched) — callers render a "searching for driver" placeholder.
final deliveryAssignmentForOrderProvider = FutureProvider.autoDispose
    .family<DeliveryAssignment?, String>((ref, orderId) async {
      final result = await ref
          .watch(deliveryRepositoryProvider)
          .getAssignmentByOrderId(orderId);
      return result.when(onLeft: (_) => null, onRight: (a) => a);
    });
