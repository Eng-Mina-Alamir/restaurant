import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/data/app_cache.dart';
import '../../../../core/data/offline_queue_service.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/realtime_service.dart';
import '../../../../core/notifications/new_order_notifier.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/logger.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../coupons/presentation/controllers/coupon_controller.dart';
import '../../../delivery/domain/entities/delivery_assignment.dart';
import '../../../delivery/domain/services/delivery_fee_calculator.dart';
import '../../../delivery/domain/services/driver_assignment_service.dart';
import '../../../delivery/presentation/controllers/delivery_controller.dart';
import '../../../menu/data/menu_seed_data.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../../data/repositories/hive_order_repository.dart';
import '../../data/repositories/in_memory_order_repository.dart';
import '../../data/repositories/supabase_order_repository.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/order_mapper.dart';
import '../../domain/repositories/order_repository.dart';

/// Provides the shared [OrderRepository].
///
/// Uses Supabase backend with local caching when enabled, or falls back to Hive/In-memory.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final cache = ref.watch(localCacheServiceProvider);
  if (AppConfig.useSupabase) {
    return SupabaseOrderRepository(
      supabase: ref.watch(supabaseClientProvider),
      cache: cache,
    );
  }
  if (cache != null) return HiveOrderRepository(cache);
  return InMemoryOrderRepository();
});

/// Resolves the discount currently applied to [items] (e.g. from an active
/// coupon), so persisted order totals match what checkout displayed.
typedef CartDiscountResolver = double Function(List<CartItem> items);

/// Manages session orders for the customer's order flow.
///
/// Reads the current cart (via [CartController]) and produces an
/// [OrderEntity] through [OrderMapper], then clears the cart so the user can
/// start a fresh order.
class OrdersController extends StateNotifier<List<OrderEntity>> {
  OrdersController(
    this._repository,
    this._cart,
    this._newOrderNotifier, {
    RealtimeService? realtimeService,
    ConnectivityService? connectivityService,
    OfflineQueueService? offlineQueueService,
    CartDiscountResolver? discountResolver,
    MenuItem? Function(String menuItemId)? menuLookup,
    Future<void> Function(OrderEntity order)? onDeliveryOrderReady,
  })  : _realtimeService = realtimeService,
        _connectivityService = connectivityService,
        _offlineQueueService = offlineQueueService,
        _discountResolver = discountResolver,
        _menuLookup = menuLookup,
        _onDeliveryOrderReady = onDeliveryOrderReady,
        super(const []) {
    _initRealtime();
    _initConnectivity();
  }

  final OrderRepository _repository;
  final CartController _cart;
  final NewOrderNotifier _newOrderNotifier;
  final RealtimeService? _realtimeService;
  final ConnectivityService? _connectivityService;
  final OfflineQueueService? _offlineQueueService;
  final CartDiscountResolver? _discountResolver;

  /// Live menu lookup used at checkout time to revalidate item availability
  /// and price; null disables revalidation (offline/demo mode).
  final MenuItem? Function(String menuItemId)? _menuLookup;

  /// Optional dispatch hook fired when a persisted transition lands a
  /// delivery order on [OrderStatus.ready] (auto-assign wiring lives in
  /// [ordersControllerProvider]). Null disables auto-dispatch.
  final Future<void> Function(OrderEntity order)? _onDeliveryOrderReady;

  /// Human-readable reason the last [placeOrder]/[placeOrderForTable] call
  /// returned null (checkout-time revalidation failure). Null when the last
  /// call succeeded.
  String? get lastPlaceOrderError => _lastPlaceOrderError;
  String? _lastPlaceOrderError;
  StreamSubscription<RealtimeEvent>? _realtimeSub;
  StreamSubscription<ConnectivityStatus>? _connectivitySub;

  /// In-memory mirror of orders awaiting sync. ONLY used for UI state and as
  /// the replay source when no persistent [OfflineQueueService] is injected —
  /// never both, which previously caused every offline order to be submitted
  /// twice per reconnect.
  final List<OrderEntity> _offlineQueue = [];

  /// Guards against concurrent sync runs.
  bool _syncInFlight = false;

  /// Debounce window for reconnect-triggered syncs (flapping networks).
  DateTime? _lastSyncTriggeredAt;

  List<OrderEntity> get offlineQueue => List.unmodifiable(_offlineQueue);
  int get pendingSyncCount => _offlineQueue.length;

  void _initConnectivity() {
    final connectivity = _connectivityService;
    if (connectivity == null) return;
    _connectivitySub = connectivity.onStatusChanged.listen((status) {
      if (status == ConnectivityStatus.online) {
        unawaited(_onReconnect());
      }
    });
  }

  /// Reconnect handler with debounce + reentrancy guard so a flapping
  /// network cannot trigger a retry storm.
  Future<void> _onReconnect() async {
    final now = DateTime.now();
    final last = _lastSyncTriggeredAt;
    if (_syncInFlight ||
        (last != null &&
            now.difference(last) < const Duration(milliseconds: 1500))) {
      return;
    }
    _lastSyncTriggeredAt = now;
    _syncInFlight = true;
    try {
      await syncOfflineOrders();
    } finally {
      _syncInFlight = false;
    }
  }

  /// Synchronizes pending offline orders when connectivity returns.
  ///
  /// The persistent [OfflineQueueService] is the single source of truth when
  /// available; the in-memory list is only a fallback (and a UI mirror that is
  /// pruned as its persistent counterparts succeed).
  Future<void> syncOfflineOrders() async {
    final queueService = _offlineQueueService;

    if (queueService != null) {
      if (!queueService.hasPending) return;
      await queueService.drainWith(
        (type, payload) async {
          if (type == 'createOrder') {
            try {
              final order = OrderEntity.fromJson(payload);
              final result = await _repository.createOrder(order);
              if (result.isRight) {
                _realtimeService?.broadcastOrderCreated(payload);
                // Keep the UI mirror consistent with the persistent queue.
                _offlineQueue.removeWhere((o) => o.id == order.id);
                return true;
              }
              AppLogger.warning(
                'Offline sync: createOrder ${order.id} rejected by repository; '
                'will retry/backoff',
              );
              return false;
            } catch (e, st) {
              AppLogger.error(
                'Offline sync: corrupt queued order dropped',
                error: e,
                stackTrace: st,
              );
              return true; // Poison payload — let the queue dead-letter it.
            }
          }
          return true;
        },
      );
      return;
    }

    // Fallback path when persistence is unavailable (e.g. tests).
    if (_offlineQueue.isNotEmpty) {
      final toSync = List<OrderEntity>.of(_offlineQueue);
      for (final order in toSync) {
        final result = await _repository.createOrder(order);
        if (result.isRight) {
          _realtimeService?.broadcastOrderCreated(order.toJson());
          _offlineQueue.removeWhere((o) => o.id == order.id);
        }
      }
    }
  }

  /// Last applied realtime status-event timestamp per order id, used to drop
  /// stale/out-of-order deliveries instead of regressing order state.
  final Map<String, DateTime> _statusEventAt = {};

  void _initRealtime() {
    final realtime = _realtimeService;
    if (realtime == null) return;
    _realtimeSub = realtime.events.listen((event) {
      if (event.type == RealtimeEventType.orderCreated) {
        try {
          final order = OrderEntity.fromJson(event.payload);
          final exists = state.any((o) => o.id == order.id);
          if (!exists) {
            state = [...state, order];
            _newOrderNotifier.notifyNewOrder();
          }
        } catch (e, st) {
          AppLogger.warning(
            'Realtime: malformed orderCreated payload: $e\n$st',
          );
        }
      } else if (event.type == RealtimeEventType.orderStatusChanged ||
          event.type == RealtimeEventType.orderStatusReverted) {
        try {
          final orderId =
              (event.payload['orderId'] ?? event.payload['id'])?.toString();
          final statusName = event.payload['status']?.toString();
          if (orderId == null || statusName == null) {
            AppLogger.warning(
              'Realtime: malformed ${event.type} payload: ${event.payload}',
            );
            return;
          }

          // Staleness guard: events carry an updatedAt stamp; anything older
          // than the last event we APPLIED for this order is dropped, so a
          // delayed message can never move an order backwards.
          final rawUpdatedAt = event.payload['updatedAt'];
          final eventAt =
              rawUpdatedAt is String ? DateTime.tryParse(rawUpdatedAt) : null;
          final lastApplied = _statusEventAt[orderId];
          if (eventAt != null &&
              lastApplied != null &&
              !eventAt.isAfter(lastApplied)) {
            AppLogger.info(
              'Realtime: dropping stale status event for $orderId '
              '(event ${eventAt.toIso8601String()} <= applied '
              '${lastApplied.toIso8601String()})',
            );
            return;
          }

          final newStatus = OrderStatus.fromName(statusName);
          final index = state.indexWhere((o) => o.id == orderId);
          if (index != -1) {
            final currentStatus = state[index].status;
            // Forward business transitions are always applied; intentional
            // one-step reverts (e.g. ready → preparing) are accepted through
            // the same path, whether they arrive as a plain status change or
            // as a dedicated orderStatusReverted event.
            if (currentStatus != newStatus &&
                (currentStatus.canTransitionTo(newStatus) ||
                    currentStatus.canRevertTo(newStatus))) {
              final updated = state[index].copyWith(status: newStatus);
              state = [...state]..[index] = updated;
              if (eventAt != null &&
                  (lastApplied == null || eventAt.isAfter(lastApplied))) {
                _statusEventAt[orderId] = eventAt;
              }
            }
          }
        } catch (e, st) {
          AppLogger.warning(
            'Realtime: bad status-change payload: $e\n$st',
          );
        }
      }
    });
  }

  /// True once an order is being created, preventing double-taps.
  bool _placing = false;

  /// Persists [order] in the durable offline queue.
  ///
  /// MUST be awaited BEFORE any local state mutation so that an app kill in
  /// the middle of placing an order can never lose an order the user already
  /// saw confirmed. Failures are logged loudly instead of swallowed.
  Future<void> _persistOfflineOrder(OrderEntity order) async {
    final queueService = _offlineQueueService;
    if (queueService == null) return;
    try {
      final ok = await queueService.enqueue(
        operationType: 'createOrder',
        payload: order.toJson(),
        idempotencyKey: order.id,
      );
      if (!ok) {
        AppLogger.warning(
          '_persistOfflineOrder: order ${order.id} was NOT persisted '
          '(duplicate idempotency key or storage failure)',
        );
      }
    } catch (e, st) {
      AppLogger.error(
        '_persistOfflineOrder: persisting ${order.id} failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  int get _nextNumber {
    final maxNumber = state.fold<int>(0, (max, order) {
      final n = Formatters.orderNumberFromId(order.id);
      return (n ?? 0) > max ? (n ?? 0) : max;
    });
    return maxNumber + 1;
  }

  /// Checkout-time revalidation: returns a localized rejection reason when
  /// any cart line is no longer available or its price changed since it was
  /// added, or null when the cart is safe to submit.
  ///
  /// Skipped entirely when no live menu lookup is available (offline/demo).
  String? _checkoutRejection(List<CartItem> cartItems) {
    final lookup = _menuLookup;
    if (lookup == null) return null;
    final problems = <String>[];
    for (final item in cartItems) {
      final fresh = lookup(item.menuItem.id);
      if (fresh == null || !fresh.isAvailable) {
        problems.add(item.menuItem.name);
        continue;
      }
      if ((fresh.price - item.menuItem.price).abs() > 0.001) {
        problems.add(
          '${item.menuItem.name} '
          '(تغير السعر من ${fresh.price.toStringAsFixed(2)} '
          'إلى ${item.menuItem.price.toStringAsFixed(2)})',
        );
      }
    }
    if (problems.isEmpty) return null;
    return 'بعض الأصناف لم تعد متاحة أو تغير سعرها، يرجى تحديث السلة: '
        '${problems.join('، ')}';
  }

  /// Places an order with the next cart contents.
  ///
  /// Appends the created [OrderEntity] to [state] and clears the cart on
  /// success. [orderType] defaults to takeaway when null; [deliveryAddress]
  /// and [deliveryNotes] are persisted for delivery orders.
  Future<OrderEntity?> placeOrder({
    PaymentMethod? paymentMethod,
    OrderType? orderType,
    String? deliveryAddress,
    String? deliveryNotes,
  }) async {
    if (_placing) return null;
    final cartItems = List<CartItem>.of(_cart.state);
    if (cartItems.isEmpty) return null;

    final rejection = _checkoutRejection(cartItems);
    if (rejection != null) {
      AppLogger.warning('placeOrder rejected: $rejection');
      _lastPlaceOrderError = rejection;
      return null;
    }
    _lastPlaceOrderError = null;

    _placing = true;
    try {
      final createdAt = DateTime.now();
      final discountAmount =
          _discountResolver?.call(cartItems) ?? 0.0;
      final order = OrderMapper.buildForCustomer(
        orderId: 'ORD-${_nextNumber.toString().padLeft(4, '0')}',
        restaurantId: MenuSeedData.restaurantId,
        cartItems: cartItems,
        createdAt: createdAt,
        paymentMethod: paymentMethod,
        discountAmount: discountAmount,
        orderType: orderType,
        deliveryAddress: deliveryAddress,
        deliveryNotes: deliveryNotes,
      );

      final isOffline = _connectivityService?.isOnline == false;
      if (isOffline) {
        await _persistOfflineOrder(order);
        state = [...state, order];
        _cart.clear();
        _newOrderNotifier.notifyNewOrder();
        _offlineQueue.add(order);
        return order;
      }

      final result = await _repository.createOrder(order);
      switch (result) {
        case Left(:final value):
          AppLogger.warning('Server order creation returned error: ${value.message}. Storing in offline queue.');
          await _persistOfflineOrder(order);
          state = [...state, order];
          _cart.clear();
          _offlineQueue.add(order);
          _newOrderNotifier.notifyNewOrder();
          _realtimeService?.broadcastOrderCreated(order.toJson());
          return order;
        case Right(:final value):
          state = [...state, value];
          _cart.clear();
          _newOrderNotifier.notifyNewOrder();
          _realtimeService?.broadcastOrderCreated(value.toJson());
          return value;
      }
    } finally {
      _placing = false;
    }
  }

  /// Places an order for a specific [tableId] (dine-in) with the next cart
  /// contents, defaulting the type to [OrderType.dineIn].
  Future<OrderEntity?> placeOrderForTable(
    String tableId, {
    PaymentMethod? paymentMethod,
  }) async {
    if (_placing) return null;
    final cartItems = List<CartItem>.of(_cart.state);
    if (cartItems.isEmpty) return null;

    final rejection = _checkoutRejection(cartItems);
    if (rejection != null) {
      AppLogger.warning('placeOrderForTable rejected: $rejection');
      _lastPlaceOrderError = rejection;
      return null;
    }
    _lastPlaceOrderError = null;

    _placing = true;
    try {
      final createdAt = DateTime.now();
      final discountAmount =
          _discountResolver?.call(cartItems) ?? 0.0;
      final order = OrderMapper.buildForTable(
        orderId: 'ORD-${_nextNumber.toString().padLeft(4, '0')}',
        restaurantId: MenuSeedData.restaurantId,
        tableId: tableId,
        cartItems: cartItems,
        createdAt: createdAt,
        paymentMethod: paymentMethod,
        discountAmount: discountAmount,
      );

      final isOffline = _connectivityService?.isOnline == false;
      if (isOffline) {
        await _persistOfflineOrder(order);
        state = [...state, order];
        _cart.clear();
        _newOrderNotifier.notifyNewOrder();
        _offlineQueue.add(order);
        return order;
      }

      final result = await _repository.createOrder(order);
      switch (result) {
        case Left(:final value):
          AppLogger.warning('Server order creation returned error: ${value.message}. Storing in offline queue.');
          await _persistOfflineOrder(order);
          state = [...state, order];
          _cart.clear();
          _offlineQueue.add(order);
          _newOrderNotifier.notifyNewOrder();
          _realtimeService?.broadcastOrderCreated(order.toJson());
          return order;
        case Right(:final value):
          state = [...state, value];
          _cart.clear();
          _newOrderNotifier.notifyNewOrder();
          _realtimeService?.broadcastOrderCreated(value.toJson());
          return value;
      }
    } finally {
      _placing = false;
    }
  }

  /// Advances the status of the order with [orderId] to [status].
  ///
  /// When the order is completed/cancelled it is kept in state but no longer
  /// counts toward the KDS active columns.
  Future<OrderEntity?> updateStatus(String orderId, OrderStatus status) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index == -1) return null;

    final updated = state[index].copyWith(status: status);
    state = [...state]..[index] = updated;

    // Stamp locally-applied transitions so our own broadcast echo — or any
    // delayed remote event older than this moment — can never regress state.
    final stampedAt = DateTime.now();
    final lastApplied = _statusEventAt[orderId];
    if (lastApplied == null || stampedAt.isAfter(lastApplied)) {
      _statusEventAt[orderId] = stampedAt;
    }

    _realtimeService?.broadcastOrderStatusChanged(
      orderId,
      status.name,
      updatedAt: stampedAt,
    );

    // Persist the updated order status through the repository.
    final result = await _repository.updateOrderStatus(orderId, status);

    // Auto-dispatch: once a delivery order is PERSISTED on "ready", hand it
    // to the dispatch hook. The hook must never break the status-update path
    // — failures are logged and the order simply stays undispatched (manual
    // manager reassign remains possible).
    if (result.isRight &&
        status == OrderStatus.ready &&
        updated.orderType == OrderType.delivery) {
      await _notifyDeliveryOrderReady(updated);
    }

    return result.when(
      onLeft: (_) => null,
      onRight: (_) => updated,
    );
  }

  /// Claims [orderId] for [kitchenUserId] (KDS استلام الطلب).
  ///
  /// Optimistically stamps the local order so the claiming chef keeps seeing
  /// the ticket while other KDS clients filter it out; persists through
  /// [OrderRepository.claimOrder].
  Future<OrderEntity?> claim(
    String orderId, {
    String? kitchenUserId,
  }) async {
    final uid = kitchenUserId;
    if (uid == null || uid.isEmpty) {
      AppLogger.warning('claim($orderId) ignored: no authenticated chef id');
      return null;
    }
    final index = state.indexWhere((o) => o.id == orderId);
    if (index == -1) return null;

    final updated = state[index].copyWith(assignedKitchenId: uid);
    state = [...state]..[index] = updated;

    // Stamp locally-applied transitions so any delayed remote event older
    // than this moment can never clobber the fresh assignment.
    _stampStatusEvent(orderId);

    final result = await _repository.claimOrder(orderId, uid);
    return result.when(
      onLeft: (_) => null,
      onRight: (_) => updated,
    );
  }

  /// Moves [orderId] BACK to [toStatus] (guarded revert, e.g.
  /// ready → preparing) recording an audit entry attributed to [actorId].
  ///
  /// Mirrors [updateStatus]: optimistic state update, `_statusEventAt`
  /// stamping (so our own realtime echo is dropped), broadcast via
  /// [RealtimeService.broadcastOrderStatusReverted], then persistence.
  Future<OrderEntity?> revertStatus(
    String orderId,
    OrderStatus toStatus, {
    required String actorId,
    String? reason,
  }) async {
    final index = state.indexWhere((o) => o.id == orderId);
    if (index == -1) return null;

    final current = state[index];
    // Domain guard: terminal orders are immutable and only single-step
    // backward moves are legal (ready→preparing, served→ready).
    if (!current.status.canRevertTo(toStatus)) {
      AppLogger.warning(
        'revertStatus($orderId, ${toStatus.name}) rejected: illegal revert '
        'from ${current.status.name}',
      );
      return null;
    }

    final updated = current.copyWith(status: toStatus);
    state = [...state]..[index] = updated;

    // Stamp BEFORE broadcasting so our own echo is recognized as stale.
    final stampedAt = _stampStatusEvent(orderId);

    _realtimeService?.broadcastOrderStatusReverted(
      orderId,
      current.status.name,
      toStatus.name,
      updatedAt: stampedAt,
    );

    final result = await _repository.revertStatus(
      orderId,
      toStatus,
      actorId: actorId,
      reason: reason,
    );
    return result.when(
      onLeft: (_) => null,
      onRight: (_) => updated,
    );
  }

  /// Records a locally-applied transition timestamp for [orderId]; returns
  /// the stamp used so broadcasts and guards stay consistent.
  DateTime _stampStatusEvent(String orderId) {
    final stampedAt = DateTime.now();
    final lastApplied = _statusEventAt[orderId];
    if (lastApplied == null || stampedAt.isAfter(lastApplied)) {
      _statusEventAt[orderId] = stampedAt;
    }
    return stampedAt;
  }

  /// Invokes the optional [OrdersController] dispatch hook for a delivery
  /// order that reached [OrderStatus.ready], swallowing any failure.
  Future<void> _notifyDeliveryOrderReady(OrderEntity order) async {
    final hook = _onDeliveryOrderReady;
    if (hook == null) return;
    try {
      await hook(order);
    } catch (e, st) {
      AppLogger.error(
        'onDeliveryOrderReady failed for order ${order.id}; '
        'order left undispatched (manual reassign still possible)',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Orders that are still active for kitchen display (not terminal).
  List<OrderEntity> get activeOrders =>
      state.where((o) => !o.status.isTerminal).toList();

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}

/// Single shared new-order notifier for badge/sound alerts.
final newOrderNotifierProvider = Provider<NewOrderNotifier>((ref) {
  final notifier = NewOrderNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

final ordersControllerProvider =
    StateNotifierProvider<OrdersController, List<OrderEntity>>((ref) {
      // Hybrid auto-dispatch: when a delivery order hits "ready", rank the
      // available drivers and create exactly one assignment for the winner,
      // then broadcast it so driver/dispatch clients stay in sync. A Waiting
      // decision (or any failure) leaves the order undispatched — the manager
      // can still assign manually.
      Future<void> autoDispatchDeliveryOrder(OrderEntity order) async {
        final deliveryRepo = ref.read(deliveryRepositoryProvider);
        final realtime = ref.read(realtimeServiceProvider);

        final driversResult = await deliveryRepo.getAvailableDrivers();
        final drivers = driversResult.when(
          onLeft: (failure) {
            AppLogger.warning(
              'Auto-dispatch: getAvailableDrivers failed (${failure.message}); '
              'order ${order.id} left undispatched',
            );
            return null;
          },
          onRight: (list) => list,
        );
        if (drivers == null) return;

        final decision = const DriverAssignmentService().assign(
          candidates: drivers,
          restaurantLat: DeliveryFeeCalculator.restaurantLat,
          restaurantLng: DeliveryFeeCalculator.restaurantLng,
        );

        switch (decision) {
          case Waiting(:final reason):
            AppLogger.info(
              'Auto-dispatch: order ${order.id} waiting for a driver — $reason',
            );
          case Assigned(:final driverId):
            final now = DateTime.now();
            final assignment = DeliveryAssignment(
              id: 'ASG-${order.id}-${now.millisecondsSinceEpoch}',
              orderId: order.id,
              driverId: driverId,
              pickupTime: now,
              deliveryLocation: order.deliveryAddress ?? '',
              deliveryStatus: DeliveryStatus.pending,
              assignmentMethod: 'auto',
              assignedAt: now,
            );
            final createdResult =
                await deliveryRepo.createAssignment(assignment);
            createdResult.when(
              onLeft: (failure) => AppLogger.warning(
                'Auto-dispatch: createAssignment rejected for order '
                '${order.id} (${failure.message})',
              ),
              onRight: (created) => realtime
                  .broadcastDeliveryAssignmentCreated(created.toJson()),
            );
        }
      }

      return OrdersController(
        ref.watch(orderRepositoryProvider),
        ref.watch(cartControllerProvider.notifier),
        ref.watch(newOrderNotifierProvider),
        realtimeService: ref.watch(realtimeServiceProvider),
        connectivityService: ref.watch(connectivityServiceProvider),
        offlineQueueService: ref.watch(offlineQueueServiceProvider),
        // Checkout integrity: persisted totals include the applied coupon so
        // they match what the cart UI displayed.
        discountResolver: (items) {
          final coupon = ref.read(appliedCouponProvider);
          if (coupon == null) return 0.0;
          final rawSubtotal = items.fold<double>(
            0,
            (sum, item) => sum + item.linePrice,
          );
          return coupon.calculateDiscount(rawSubtotal);
        },
        // Checkout-time revalidation against the live menu snapshot.
        menuLookup: (menuItemId) {
          final menu =
              ref.read(menuControllerProvider).valueOrNull;
          for (final item in menu?.items ?? const <MenuItem>[]) {
            if (item.id == menuItemId) return item;
          }
          return null;
        },
        onDeliveryOrderReady: autoDispatchDeliveryOrder,
      );
    });
