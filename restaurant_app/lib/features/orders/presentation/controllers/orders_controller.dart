import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../menu/data/menu_seed_data.dart';
import '../../data/repositories/in_memory_order_repository.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/order_mapper.dart';
import '../../domain/repositories/order_repository.dart';

/// Provides the shared [OrderRepository]. Swap for the Hive/remote-backed
/// implementation here once persistence is introduced.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return InMemoryOrderRepository();
});

/// Manages session orders for the customer's order flow.
///
/// Reads the current cart (via [CartController]) and produces an
/// [OrderEntity] through [OrderMapper], then clears the cart so the user can
/// start a fresh order.
class OrdersController extends StateNotifier<List<OrderEntity>> {
  OrdersController(this._repository, this._cart) : super(const []);

  final OrderRepository _repository;
  final CartController _cart;

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
  Future<OrderEntity?> placeOrder() async {
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
      );

      final result = await _repository.createOrder(order);
      final created = result.when(onLeft: (_) => null, onRight: (o) => o);
      if (created != null) {
        state = [...state, created];
        _cart.clear();
      }
      return created;
    } finally {
      _placing = false;
    }
  }
}

final ordersControllerProvider =
    StateNotifierProvider<OrdersController, List<OrderEntity>>((ref) {
      return OrdersController(
        ref.watch(orderRepositoryProvider),
        ref.watch(cartControllerProvider.notifier),
      );
    });
