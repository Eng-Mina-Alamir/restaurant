import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/network/connectivity_service.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/repositories/order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

class _FakeOrderRepository implements OrderRepository {
  final List<OrderEntity> orders = [];

  @override
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order) async {
    final index = orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      orders[index] = order;
    } else {
      orders.add(order);
    }
    return Right(order);
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    return Right(List.unmodifiable(orders));
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      orders[index] = orders[index].copyWith(status: status);
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, OrderEntity>> claimOrder(
    String orderId,
    String kitchenUserId,
  ) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      return const Left(NotFoundFailure('الطلب غير موجود'));
    }
    orders[index] = orders[index].copyWith(assignedKitchenId: kitchenUserId);
    return Right(orders[index]);
  }

  @override
  Future<Either<Failure, OrderEntity>> revertStatus(
    String orderId,
    OrderStatus toStatus, {
    required String actorId,
    String? reason,
  }) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      return const Left(NotFoundFailure('الطلب غير موجود'));
    }
    if (!orders[index].status.canRevertTo(toStatus)) {
      return Left(
        ValidationFailure('لا يمكن التراجع من ${orders[index].status.labelAr}'),
      );
    }
    orders[index] = orders[index].copyWith(status: toStatus);
    return Right(orders[index]);
  }
}

void main() {
  group('OrdersController Unit Tests (v2)', () {
    late _FakeOrderRepository repo;
    late CartController cart;
    late NewOrderNotifier notifier;
    late RealtimeService realtime;
    late ConnectivityService connectivity;
    late OrdersController controller;

    const testItem = MenuItem(
      id: 'i-test',
      categoryId: 'cat-1',
      name: 'طبق تجريبي',
      description: 'وصف',
      price: 50.0,
    );

    setUp(() {
      repo = _FakeOrderRepository();
      cart = CartController();
      notifier = NewOrderNotifier();
      realtime = RealtimeService();
      connectivity = ConnectivityService(ConnectivityStatus.online);

      controller = OrdersController(
        repo,
        cart,
        notifier,
        realtimeService: realtime,
        connectivityService: connectivity,
      );
    });

    tearDown(() {
      controller.dispose();
      notifier.dispose();
      realtime.disconnect();
    });

    test('placeOrder with empty cart returns null', () async {
      final order = await controller.placeOrder();
      expect(order, isNull);
      expect(controller.state, isEmpty);
    });

    test('placeOrder adds order to state, persists, and clears cart', () async {
      cart.addItem(const CartItem(menuItem: testItem, quantity: 2));
      expect(cart.itemCount, 1);

      final order = await controller.placeOrder(paymentMethod: PaymentMethod.card);

      expect(order, isNotNull);
      expect(order?.items.first.menuItem.id, 'i-test');
      expect(controller.state, hasLength(1));
      expect(cart.state, isEmpty); // Cart cleared
      expect(repo.orders, hasLength(1));
    });

    test('placeOrderForTable sets dineIn order type and tableId', () async {
      cart.addItem(const CartItem(menuItem: testItem, quantity: 1));

      final order = await controller.placeOrderForTable(
        'tbl-5',
        paymentMethod: PaymentMethod.cash,
      );

      expect(order, isNotNull);
      expect(order?.orderType, OrderType.dineIn);
      expect(order?.tableId, 'tbl-5');
      expect(controller.state.first.tableId, 'tbl-5');
    });

    test('updateStatus modifies order and persists update', () async {
      cart.addItem(const CartItem(menuItem: testItem, quantity: 1));
      final order = await controller.placeOrder();
      expect(order, isNotNull);

      final updated = await controller.updateStatus(order!.id, OrderStatus.preparing);
      expect(updated?.status, OrderStatus.preparing);
      expect(controller.state.first.status, OrderStatus.preparing);
    });

    test('updateStatus on non-existent order returns null', () async {
      final updated = await controller.updateStatus('NON-EXISTENT', OrderStatus.ready);
      expect(updated, isNull);
    });

    test('activeOrders excludes completed and cancelled orders', () async {
      cart.addItem(const CartItem(menuItem: testItem, quantity: 1));
      final order1 = await controller.placeOrder();

      cart.addItem(const CartItem(menuItem: testItem, quantity: 1));
      final order2 = await controller.placeOrder();

      expect(controller.activeOrders, hasLength(2));

      await controller.updateStatus(order1!.id, OrderStatus.completed);
      expect(controller.activeOrders, hasLength(1));
      expect(controller.activeOrders.first.id, order2!.id);

      await controller.updateStatus(order2.id, OrderStatus.cancelled);
      expect(controller.activeOrders, isEmpty);
    });

    test('offline queuing when connectivity is offline', () async {
      connectivity.goOffline();

      cart.addItem(const CartItem(menuItem: testItem, quantity: 1));
      final order = await controller.placeOrder();

      expect(order, isNotNull);
      expect(controller.pendingSyncCount, 1);
      expect(controller.offlineQueue.first.id, order!.id);

      // Go online triggers sync
      connectivity.goOnline();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.pendingSyncCount, 0);
    });
  });
}
