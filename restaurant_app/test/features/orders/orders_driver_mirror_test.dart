import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/network/connectivity_service.dart';
import 'package:restaurant_app/core/network/realtime_event.dart';
import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/core/supabase/supabase_realtime_service.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_status_log_entry.dart';
import 'package:restaurant_app/features/orders/domain/repositories/order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeOrderRepository implements OrderRepository {
  final List<OrderEntity> orders = [];

  @override
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order) async {
    orders.add(order);
    return Right(order);
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async =>
      Right(List.unmodifiable(orders));

  @override
  Future<Either<Failure, OrderEntity?>> getOrderById(String orderId) async {
    for (final o in orders) {
      if (o.id == orderId) return Right(o);
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async => const Right(null);

  @override
  Future<Either<Failure, OrderEntity>> claimOrder(
    String orderId,
    String kitchenUserId,
  ) async => const Left(NotFoundFailure('x'));

  @override
  Future<Either<Failure, OrderEntity>> revertStatus(
    String orderId,
    OrderStatus toStatus, {
    required String actorId,
    String? reason,
  }  ) async => const Left(NotFoundFailure('x'));

  @override
  Future<Either<Failure, List<OrderStatusLogEntry>>> getAuditTrail(
    String orderId,
  ) async => const Right(<OrderStatusLogEntry>[]);
}

void main() {
  group('OrdersController driver mirror (customer tracking)', () {
    late _FakeOrderRepository repo;
    late CartController cart;
    late NewOrderNotifier notifier;
    late SupabaseRealtimeService realtime;
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
      final client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.anonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      realtime = SupabaseRealtimeService(client);
      controller = OrdersController(
        repo,
        cart,
        notifier,
        realtimeService: realtime,
        connectivityService: ConnectivityService(ConnectivityStatus.online),
      );
    });

    tearDown(() {
      controller.dispose();
      notifier.dispose();
      realtime.dispose();
    });

    test('syncDriverId mirrors dispatch onto local order state', () async {
      cart.addItem(const CartItem(menuItem: testItem, quantity: 1));
      final order = await controller.placeOrder(
        orderType: OrderType.delivery,
        deliveryAddress: 'المعادي',
      );
      expect(order, isNotNull);
      expect(order!.driverId, isNull);

      controller.syncDriverId(order.id, 'driver-9');
      expect(controller.orderById(order.id)?.driverId, 'driver-9');

      // Idempotent: second call with same driver is a no-op (no crash).
      controller.syncDriverId(order.id, 'driver-9');
      expect(controller.orderById(order.id)?.driverId, 'driver-9');

      // Unknown order id is ignored.
      controller.syncDriverId('no-such-order', 'driver-9');
    });

    test(
      'orderStatusChanged event carrying driver_id mirrors it even when '
      'status is unchanged (kitchen dispatch without status transition)',
      () async {
        cart.addItem(const CartItem(menuItem: testItem, quantity: 1));
        final order = await controller.placeOrder(
          orderType: OrderType.delivery,
          deliveryAddress: 'المعادي',
        );
        expect(order, isNotNull);

        realtime.emit(
          RealtimeEvent(
            type: RealtimeEventType.orderStatusChanged,
            payload: {
              'order_id': order!.id,
              'status': order.status.name,
              'driver_id': 'driver-live-1',
              'updatedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          controller.orderById(order.id)?.driverId,
          'driver-live-1',
        );
      },
    );
  });
}
