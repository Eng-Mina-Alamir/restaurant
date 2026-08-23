import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/network/realtime_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../delivery/domain/entities/delivery_assignment.dart';
import '../../../delivery/domain/entities/driver_info.dart';
import '../../../delivery/domain/repositories/delivery_repository.dart';
import '../../../delivery/presentation/controllers/delivery_controller.dart';
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
/// assign/reassign a driver by hand, broadcasting each created assignment so
/// driver clients stay in sync.
class DispatchController
    extends StateNotifier<AsyncValue<DispatchBoardState>> {
  DispatchController(
    this._repository,
    this._realtimeService, {
    required List<OrderEntity> Function() ordersSource,
  }) : _ordersSource = ordersSource,
       super(const AsyncValue.loading()) {
    refresh();
  }

  final DeliveryRepository _repository;
  final RealtimeService _realtimeService;
  final List<OrderEntity> Function() _ordersSource;

  /// Orders eligible for dispatch right now: delivery-type, non-terminal, and
  /// already prepared (kitchen released them at "ready" or later).
  List<OrderEntity> _dispatchCandidates() {
    final orders = _ordersSource();
    return orders
        .where(
          (o) =>
              o.orderType == OrderType.delivery &&
              !o.status.isTerminal &&
              o.status.index >= OrderStatus.ready.index,
        )
        .toList();
  }

  /// Reclassifies every candidate order against the assignment store and
  /// reloads the available drivers list.
  ///
  /// Never throws: failures are logged and surfaced via
  /// [DispatchBoardState.errorMessage] so the board keeps showing stale data.
  Future<void> refresh() async {
    final previous = state.valueOrNull ?? const DispatchBoardState();
    state = AsyncValue.data(previous.copyWith(isLoading: true));

    final issues = <String>[];
    final undispatched = <OrderEntity>[];
    final failed = <FailedAssignmentEntry>[];

    // ONE bulk read instead of a per-order lookup per candidate (N+1 fix):
    // classification runs locally against an orderId→assignment map.
    final assignmentsResult = await _repository.getActiveAssignments();
    final assignmentByOrderId = <String, DeliveryAssignment>{};
    assignmentsResult.when(
      onLeft: (failure) {
        AppLogger.warning(
          '[Dispatch] outcome=lookup-failed '
          'source=board-refresh reason=${failure.message}; orders skipped',
        );
        if (!issues.contains(failure.message)) issues.add(failure.message);
      },
      onRight: (assignments) {
        for (final assignment in assignments) {
          // First match wins, mirroring per-order lookup semantics.
          assignmentByOrderId.putIfAbsent(assignment.orderId, () => assignment);
        }
      },
    );

    for (final order in _dispatchCandidates()) {
      final assignment = assignmentByOrderId[order.id];
      if (assignment == null) {
        undispatched.add(order);
      } else if (assignment.deliveryStatus == DeliveryStatus.failed) {
        failed.add(
          FailedAssignmentEntry(order: order, assignment: assignment),
        );
      }
      // Any other status means the order is already on the road — skip.
    }

    var drivers = previous.availableDrivers;
    final driversResult = await _repository.getAvailableDrivers();
    driversResult.when(
      onLeft: (failure) {
        AppLogger.warning(
          '[Dispatch] outcome=get-drivers-failed '
          'source=board-refresh reason=${failure.message}',
        );
        if (!issues.contains(failure.message)) issues.add(failure.message);
      },
      onRight: (list) => drivers = list,
    );

    state = AsyncValue.data(
      DispatchBoardState(
        undispatchedOrders: undispatched,
        failedAssignments: failed,
        availableDrivers: drivers,
        errorMessage: issues.isEmpty ? null : issues.join(' | '),
      ),
    );
  }

  /// Manually assigns [driverId] to the order with id [orderId].
  ///
  /// - Undispatched order → a fresh pending assignment is created
  ///   (`ASG-<orderId>-<ms>` ids, matching the auto-dispatch format).
  /// - Failed assignment → the SAME row is upserted with the new driver, reset
  ///   to pending and stamped manual, keeping the original id.
  ///
  /// Returns true on success; on failure the message is surfaced in state
  /// instead of throwing.
  Future<bool> assignDriver(String orderId, String driverId) async {
    OrderEntity? order;
    for (final o in _ordersSource()) {
      if (o.id == orderId) {
        order = o;
        break;
      }
    }
    if (order == null) {
      state = AsyncValue.data(
        (state.valueOrNull ?? const DispatchBoardState()).copyWith(
          errorMessage: 'لم يتم العثور على الطلب $orderId',
        ),
      );
      return false;
    }

    // Classify before building: reuse the existing row only when it FAILED.
    final existingResult = await _repository.getAssignmentByOrderId(orderId);
    DeliveryAssignment? existing;
    String? lookupError;
    existingResult.when(
      onLeft: (failure) => lookupError = failure.message,
      onRight: (assignment) => existing = assignment,
    );
    if (lookupError != null) {
      state = AsyncValue.data(
        (state.valueOrNull ?? const DispatchBoardState()).copyWith(
          errorMessage: lookupError,
        ),
      );
      return false;
    }
    if (existing != null &&
        existing!.deliveryStatus != DeliveryStatus.failed) {
      state = AsyncValue.data(
        (state.valueOrNull ?? const DispatchBoardState()).copyWith(
          errorMessage: 'الطلب $orderId مكلف بالفعل بسائق آخر',
        ),
      );
      return false;
    }

    final now = DateTime.now();
    final DeliveryAssignment assignment;
    if (existing == null) {
      assignment = DeliveryAssignment(
        id: 'ASG-$orderId-${now.millisecondsSinceEpoch}',
        orderId: orderId,
        driverId: driverId,
        pickupTime: now,
        deliveryLocation: order.deliveryAddress ?? '',
        deliveryStatus: DeliveryStatus.pending,
        assignmentMethod: 'manual',
        assignedAt: now,
      );
    } else {
      // Upsert semantics: keep the SAME id so createAssignment overwrites the
      // failed row instead of forking a second one for the same order.
      assignment = existing!.copyWith(
        driverId: driverId,
        deliveryStatus: DeliveryStatus.pending,
        assignmentMethod: 'manual',
        assignedAt: now,
      );
    }

    String? failureMessage;
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

    _realtimeService.broadcastDeliveryAssignmentCreated(created.toJson());
    AppLogger.info(
      '[Dispatch] outcome=assigned orderId=$orderId '
      'driverId=$driverId method=manual',
    );
    await refresh();
    return true;
  }
}

final dispatchControllerProvider =
    StateNotifierProvider<DispatchController, AsyncValue<DispatchBoardState>>(
  (ref) {
    return DispatchController(
      ref.watch(deliveryRepositoryProvider),
      ref.watch(realtimeServiceProvider),
      ordersSource: () => ref.read(ordersControllerProvider),
    );
  },
);
