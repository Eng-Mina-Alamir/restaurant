import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/app_cache.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/notifications/new_order_notifier.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../menu/data/menu_seed_data.dart';
import '../../data/repositories/hive_order_repository.dart';
import '../../data/repositories/in_memory_order_repository.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/order_mapper.dart';
import '../../domain/repositories/order_repository.dart';

/// Provides the shared [OrderRepository].
///
/// Uses the Hive-persisted implementation when the local cache is available,
/// falling back to the in-memory repository (tests / unsupported platforms).
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final cache = ref.watch(localCacheServiceProvider);
  if (cache != null) return HiveOrderRepository(cache);
  return InMemoryOrderRepository();
});

/// Manages session orders for the customer's order flow.
///
/// Reads the current cart (via [CartController]) and produces an
/// [OrderEntity] through [OrderMapper], then clears the cart so the user can
/// start a fresh order.
class OrdersController extends StateNotifier<List<OrderEntity>> {
  OrdersController(this._repository, this._cart, this._newOrderNotifier)
    : super(const []);

  final OrderRepository _repository;
  final CartController _cart;
  final NewOrderNotifier _newOrderNotifier;

  /// True once an order is being created, preventing double-taps.
  bool _placing = false;

  int get _nextNumber {
    final maxNumber = state.fold<int>(0, (max, order) {
      final n = int.tryParse(
        order.id.replaceFirst('ORD-', '').replaceAll(RegExp(r'[^0-9]'), ''),
      );
      return (n ?? 0) > max ? (n ?? 0) : max;
    });
    return maxNumber + 1;
  }

  /// Places an order with the next cart contents.
  ///
  /// Appends the created [OrderEntity] to [state] and clears the cart on
  /// success.
  Future<OrderEntity?> placeOrder({PaymentMethod? paymentMethod}) async {
    if (_placing) return null;
    final cartItems = List<CartItem>.of(_cart.state);
    if (cartItems.isEmpty) return null;

    _placing = true;
    try {
      final createdAt = DateTime.now();
      final order = OrderMapper.buildForCustomer(
        orderId: 'ORD-${_nextNumber.toString().padLeft(4, '0')}',
        restaurantId: MenuSeedData.restaurantId,
        cartItems: cartItems,
        createdAt: createdAt,
        paymentMethod: paymentMethod,
      );

      final result = await _repository.createOrder(order);
      final created = result.when(onLeft: (_) => null, onRight: (o) => o);
      if (created != null) {
        state = [...state, created];
        _cart.clear();
        _newOrderNotifier.notifyNewOrder();
      }
      return created;
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

    _placing = true;
    try {
      final createdAt = DateTime.now();
      final order = OrderMapper.buildForTable(
        orderId: 'ORD-${_nextNumber.toString().padLeft(4, '0')}',
        restaurantId: MenuSeedData.restaurantId,
        tableId: tableId,
        cartItems: cartItems,
        createdAt: createdAt,
        paymentMethod: paymentMethod,
      );

      final result = await _repository.createOrder(order);
      final created = result.when(onLeft: (_) => null, onRight: (o) => o);
      if (created != null) {
        state = [...state, created];
        _cart.clear();
        _newOrderNotifier.notifyNewOrder();
      }
      return created;
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

    // Persist the updated order through the repository.
    final result = await _repository.createOrder(updated);
    return result.when(onLeft: (_) => null, onRight: (o) => o);
  }

  /// Orders that are still active for kitchen display (not terminal).
  List<OrderEntity> get activeOrders => state
      .where(
        (o) =>
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled,
      )
      .toList();
}

/// Single shared new-order notifier for badge/sound alerts.
final newOrderNotifierProvider = Provider<NewOrderNotifier>((ref) {
  final notifier = NewOrderNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

final ordersControllerProvider =
    StateNotifierProvider<OrdersController, List<OrderEntity>>((ref) {
      return OrdersController(
        ref.watch(orderRepositoryProvider),
        ref.watch(cartControllerProvider.notifier),
        ref.watch(newOrderNotifierProvider),
      );
    });
