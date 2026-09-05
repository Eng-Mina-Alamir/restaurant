import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/network/realtime_event.dart';
import '../../../../core/supabase/supabase_realtime_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../delivery/domain/entities/delivery_assignment.dart';
import '../../../delivery/domain/entities/driver_info.dart';
import '../../../delivery/domain/repositories/delivery_repository.dart';
import '../../../delivery/presentation/controllers/delivery_controller.dart';
import '../../../orders/data/repositories/supabase_order_repository.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';

/// One reassignable row of the dispatch board: a delivery order whose last
/// auto/manual assignment FAILED and is waiting for a new driver.
class FailedAssignmentEntry {
  const FailedAssignmentEntry({required this.order, required this.assignment});

  final OrderEntity order;

  /// The rejected assignment; its `id` is reused when the manager re-dispatches
  /// so [DeliveryRepository.createAssignment] upserts instead of forking rows.
  final DeliveryAssignment assignment;
}

/// Immutable snapshot of the manual dispatch board.
///
/// Plain class (no codegen) following the manager_dashboard state convention
/// ([FinancialReportsState]); wrapped in an `AsyncValue` by the controller so
/// pages can render loading/error shells uniformly.
class DispatchBoardState {
  const DispatchBoardState({
    this.undispatchedOrders = const [],
    this.failedAssignments = const [],
    this.availableDrivers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Ready-or-later delivery orders that have NO assignment at all yet.
  final List<OrderEntity> undispatchedOrders;

  /// Ready-or-later delivery orders whose assignment failed and can be
  /// re-dispatched to another driver.
  final List<FailedAssignmentEntry> failedAssignments;

  /// Drivers currently available for dispatch (with active-run counts).
  final List<DriverInfo> availableDrivers;

  /// True while a [DispatchController.refresh] pass is running.
  final bool isLoading;

  /// Last failure message for display; null when the board is healthy.
  final String? errorMessage;

  DispatchBoardState copyWith({
    List<OrderEntity>? undispatchedOrders,
    List<FailedAssignmentEntry>? failedAssignments,
    List<DriverInfo>? availableDrivers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DispatchBoardState(
      undispatchedOrders: undispatchedOrders ?? this.undispatchedOrders,
      failedAssignments: failedAssignments ?? this.failedAssignments,
      availableDrivers: availableDrivers ?? this.availableDrivers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Manual half of the hybrid auto-assign flow.
///
/// The orders controller auto-dispatches ready delivery orders and leaves them
/// undispatched when no driver is free or the repository rejects the write.
/// This controller powers the manager's fallback board: it classifies those
/// orders (never dispatched vs. failed-and-reassignable) and lets the manager
/// assign/reassign a driver by hand.
class DispatchController extends StateNotifier<AsyncValue<DispatchBoardState>> {
  DispatchController(
    this._repository,
    this._realtimeService, {
    required List<OrderEntity> Function() ordersSource,
    Future<void> Function(String orderId, String driverId)? onDriverAssigned,
  }) : _ordersSource = ordersSource,
       _onDriverAssigned = onDriverAssigned,
       super(const AsyncValue.loading()) {
    // Realtime assignment changes re-classify the board after the debounce window.
    _realtimeSubscription = _realtimeService.events.listen((event) {
      if (event.type == RealtimeEventType.deliveryAssignmentCreated) {
        scheduleRefresh();
      }
    });
    refresh();
  }

  final DeliveryRepository _repository;
  final SupabaseRealtimeService _realtimeService;
  final List<OrderEntity> Function() _ordersSource;

  /// Hook fired after a manual assignment lands so the order row mirrors the
  /// driver (previously only the KDS path persisted `orders.driver_id`,
  /// leaving board-assigned orders driverless everywhere else).
  final Future<void> Function(String orderId, String driverId)?
  _onDriverAssigned;

  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  Timer? _debounceTimer;

  /// Coalesces rapid triggers (multiple orders landing on ready in the same
  /// second, or back-to-back realtime events) into ONE refresh pass.
  static const Duration _debounceWindow = Duration(milliseconds: 300);

  /// Guard tracking an in-flight refresh pass so concurrent callers await the
  /// same pass instead of dropping or clobbering.
  Future<void>? _activeRefresh;

  /// Queues a debounced refresh pass; safe to call rapidly from `ref.listen`
  /// or realtime listeners.
  void scheduleRefresh() {
    if (!mounted) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceWindow, () {
      if (!mounted) return;
      unawaited(refresh());
    });
  }

  /// Pulls the latest drivers and classifies delivery orders against the
  /// repository assignments.
  ///
  /// Safe to call concurrently: concurrent calls join the active in-flight pass.
  Future<void> refresh() {
    if (_activeRefresh != null) return _activeRefresh!;
    final completer = Completer<void>();
    _activeRefresh = completer.future;

    final previous = state.valueOrNull ?? const DispatchBoardState();
    state = AsyncValue.data(previous.copyWith(isLoading: true, errorMessage: null));

    () async {
      try {
        // 1. Fetch available drivers.
        final driversResult = await _repository.getAvailableDrivers();
        final drivers = driversResult.when(
          onLeft: (failure) {
            AppLogger.warning(
              '[Dispatch] Failed to fetch drivers for board: ${failure.message}',
            );
            return <DriverInfo>[];
          },
          onRight: (list) => list,
        );

        // 2. Bulk-fetch all active assignments in ONE query instead of
        // per-order lookups (avoids N+1 DB reads during busy periods).
        final assignmentsResult = await _repository.getActiveAssignments();
        final assignmentsByOrder = <String, DeliveryAssignment>{};
        assignmentsResult.when(
          onLeft: (failure) {
            AppLogger.warning(
              '[Dispatch] Failed to fetch active assignments: ${failure.message}',
            );
          },
          onRight: (list) {
            for (final a in list) {
              assignmentsByOrder.putIfAbsent(a.orderId, () => a);
            }
          },
        );

        // 3. Classify delivery orders that need driver attention.
        final allOrders = _ordersSource();
        final candidates = allOrders.where((o) {
          // In-scope: delivery orders that are ready or later, non-terminal.
          return o.orderType == OrderType.delivery &&
              !o.status.isTerminal &&
              o.status.index >= OrderStatus.ready.index;
        }).toList();

        final undispatched = <OrderEntity>[];
        final failed = <FailedAssignmentEntry>[];

        for (final order in candidates) {
          final assignment = assignmentsByOrder[order.id];
          if (assignment == null) {
            undispatched.add(order);
          } else if (assignment.deliveryStatus == DeliveryStatus.failed) {
            failed.add(FailedAssignmentEntry(order: order, assignment: assignment));
          }
          // active / accepted / delivering assignments are intentionally
          // omitted from the manual board.
        }

        if (!mounted) return;
        state = AsyncValue.data(
          DispatchBoardState(
            undispatchedOrders: undispatched,
            failedAssignments: failed,
            availableDrivers: drivers,
            isLoading: false,
          ),
        );
      } catch (e, st) {
        AppLogger.error('[Dispatch] Board refresh failed', error: e, stackTrace: st);
        if (!mounted) return;
        state = AsyncValue.data(
          previous.copyWith(
            isLoading: false,
            errorMessage: 'تعذر تحديث لوحة التوزيع: $e',
          ),
        );
      } finally {
        _activeRefresh = null;
        completer.complete();
      }
    }();

    return completer.future;
  }

  /// Lock guarding manual assignments so two simultaneous button taps
  /// cannot dispatch the same order twice.
  bool _assignInFlight = false;

  /// Manually assigns [driverId] to [orderId] (first dispatch or re-dispatch
  /// after failure).
  ///
  /// On success the assignment is persisted in the repository; returns true
  /// when the assignment landed, false when rejected.
  Future<bool> assignDriver(
    String orderId,
    String driverId,
  ) async {
    if (_assignInFlight) return false;

    // Fast-path: find the target order from the active snapshot.
    final orders = _ordersSource();
    final order = orders.cast<OrderEntity?>().firstWhere(
      (o) => o?.id == orderId,
      orElse: () => null,
    );
    if (order == null) {
      AppLogger.warning('[Dispatch] Manual assign failed: order $orderId not found');
      return false;
    }

    // Inspect existing assignment (if any) to preserve id on re-dispatch.
    final lookupResult = await _repository.getAssignmentByOrderId(orderId);
    String? lookupError;
    final existing = lookupResult.when(
      onLeft: (failure) {
        lookupError = failure.message;
        return null;
      },
      onRight: (a) => a,
    );
    if (lookupError != null) {
      state = AsyncValue.data(
        (state.valueOrNull ?? const DispatchBoardState()).copyWith(
          errorMessage: lookupError,
        ),
      );
      return false;
    }
    if (existing != null && existing.deliveryStatus != DeliveryStatus.failed) {
      state = AsyncValue.data(
        (state.valueOrNull ?? const DispatchBoardState()).copyWith(
          errorMessage: 'الطلب $orderId مكلف بالفعل بسائق آخر',
        ),
      );
      return false;
    }

    final now = DateTime.now();
    final resolvedCustomerPhone = (order.deliveryNotes != null &&
            RegExp(r'^(01[0-25]\d{8}|\+201[0-25]\d{8})$')
                .hasMatch(order.deliveryNotes!.trim()))
        ? order.deliveryNotes!.trim()
        : null;

    final DeliveryAssignment assignment;
    if (existing == null) {
      assignment = DeliveryAssignment(
        id: 'ASG-$orderId-${now.millisecondsSinceEpoch}',
        orderId: orderId,
        driverId: driverId,
        pickupTime: now,
        deliveryLocation: order.deliveryAddress ?? '',
        customerPhone: resolvedCustomerPhone,
        deliveryStatus: DeliveryStatus.pending,
        assignmentMethod: 'manual',
        assignedAt: now,
      );
    } else {
      // Upsert semantics: keep the SAME id so createAssignment overwrites the
      // failed row instead of forking a second one for the same order.
      assignment = existing.copyWith(
        driverId: driverId,
        customerPhone: resolvedCustomerPhone ?? existing.customerPhone,
        deliveryStatus: DeliveryStatus.pending,
        assignmentMethod: 'manual',
        assignedAt: now,
      );
    }

    String? failureMessage;
    _assignInFlight = true;
    try {
      final result = await _repository.createAssignment(assignment);
      final created = result.when(
        onLeft: (failure) {
          failureMessage = failure.message;
          return null;
        },
        onRight: (a) => a,
      );
      if (created == null) {
        AppLogger.warning(
          '[Dispatch] outcome=create-rejected orderId=$orderId '
          'driverId=$driverId method=manual reason=$failureMessage',
        );
        state = AsyncValue.data(
          (state.valueOrNull ?? const DispatchBoardState()).copyWith(
            errorMessage: failureMessage,
          ),
        );
        return false;
      }

      AppLogger.info(
        '[Dispatch] outcome=assigned orderId=$orderId '
        'driverId=$driverId method=manual',
      );
      // Mirror the driver onto the order row (same as the KDS path) so
      // tracking/KDS/board stay consistent. Best-effort: a hook failure
      // must never unset the already-persisted assignment.
      final hook = _onDriverAssigned;
      if (hook != null) {
        try {
          await hook(orderId, driverId);
        } catch (e, st) {
          AppLogger.warning(
            '[Dispatch] outcome=driver-mirror-failed orderId=$orderId: $e',
            error: e,
            stackTrace: st,
          );
        }
      }
      await refresh();
    } finally {
      _assignInFlight = false;
    }
    return true;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}

final dispatchControllerProvider =
    StateNotifierProvider<DispatchController, AsyncValue<DispatchBoardState>>((
      ref,
    ) {
      final controller = DispatchController(
        ref.watch(deliveryRepositoryProvider),
        ref.watch(supabaseRealtimeServiceProvider),
        ordersSource: () => ref.read(ordersControllerProvider),
        onDriverAssigned: (orderId, driverId) async {
          ref
              .read(ordersControllerProvider.notifier)
              .syncDriverId(orderId, driverId);
          final orderRepo = ref.read(orderRepositoryProvider);
          if (orderRepo is SupabaseOrderRepository) {
            await orderRepo.updateOrderDriverId(orderId, driverId);
          }
        },
      );
      // Orders advancing (e.g. realtime lands an order on "ready") must
      // re-classify the board without waiting for a manual pull-to-refresh.
      ref.listen(
        ordersControllerProvider,
        (_, _) => controller.scheduleRefresh(),
      );
      return controller;
    });
