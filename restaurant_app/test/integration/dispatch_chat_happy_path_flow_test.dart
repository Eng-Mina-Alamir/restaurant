import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/supabase/supabase_realtime_service.dart';
import 'package:restaurant_app/core/utils/logger.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/chat/data/repositories/in_memory_chat_repository.dart';
import 'package:restaurant_app/features/chat/domain/entities/chat_message.dart';
import 'package:restaurant_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/domain/entities/driver_info.dart';
import 'package:restaurant_app/features/delivery/domain/services/delivery_fee_calculator.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/test_container.dart';

/// Customer identity stamped on messages sent from the customer side.
const String _customerId = 'cust-happy-1';

/// Driver parked ≈222 m north of the restaurant — well inside the 5000 m
/// service radius with zero active assignments, so dispatch succeeds on the
/// FIRST attempt and no retry timer ever arms.
DriverInfo _nearbyDriver(String id) => DriverInfo(
  id: id,
  name: id,
  rating: 5.0,
  latitude: DeliveryFeeCalculator.restaurantLat + 0.002,
  longitude: DeliveryFeeCalculator.restaurantLng,
);

class _SeededPoolDeliveryRepository extends InMemoryDeliveryRepository {
  _SeededPoolDeliveryRepository();

  DriverInfo? availableDriver;

  @override
  Future<Either<Failure, List<DriverInfo>>> getAvailableDrivers() async =>
      Right<Failure, List<DriverInfo>>(<DriverInfo>[?availableDriver]);
}

class _SpyRealtimeService extends SupabaseRealtimeService {
  _SpyRealtimeService()
    : super(
        SupabaseClient(
          SupabaseConfig.url,
          SupabaseConfig.anonKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
}

void main() {
  setUp(() {
    AppLogger.enabled = false;
  });

  tearDown(() {
    AppLogger.enabled = true;
  });

  test('delivery order → ready fires auto-dispatch once '
      '(persisted) → order-scoped chat reaches both participants', () async {
    const driverId = 'drv-happy';
    final deliveryRepo = _SeededPoolDeliveryRepository();
    final realtime = _SpyRealtimeService();
    final container = createTestContainer(
      seedCheckoutFixtures: true,
      additionalOverrides: [
        deliveryRepositoryProvider.overrideWithValue(deliveryRepo),
        supabaseRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(realtime.dispose);

    // ── 1) Place a DELIVERY order through the real cart → checkout providers.
    await primeMenuForCheckout(container);
    container
        .read(cartControllerProvider.notifier)
        .addItem(CartItem(menuItem: checkoutFixtureItems.first));

    final orders = container.read(ordersControllerProvider.notifier);
    final order = await orders.placeOrder(
      orderType: OrderType.delivery,
      deliveryAddress: 'حي النرجس، الرياض',
    );
    expect(order, isNotNull);
    expect(order!.orderType, OrderType.delivery);
    expect(order.status, OrderStatus.pending);
    expect(container.read(cartControllerProvider), isEmpty);

    // ── 2) Seed an available driver BEFORE advancing to ready, then walk the
    //       KDS transition path. Dispatch succeeds inside the awaited
    //       updateStatus chain — no retry timer is involved.
    deliveryRepo.availableDriver = _nearbyDriver(driverId);

    final preparing = await orders.updateStatus(
      order.id,
      OrderStatus.preparing,
    );
    expect(preparing?.status, OrderStatus.preparing);

    final ready = await orders.updateStatus(order.id, OrderStatus.ready);
    expect(ready?.status, OrderStatus.ready);

    // ── 3) Exactly ONE assignment was persisted for the order.
    final byOrderId = await deliveryRepo.getAssignmentByOrderId(order.id);
    expect(byOrderId.isRight, isTrue);
    final DeliveryAssignment? stored = byOrderId.when(
      onLeft: (_) => null,
      onRight: (a) => a,
    );
    expect(stored, isNotNull);
    expect(stored!.orderId, order.id);
    expect(stored.driverId, driverId);
    expect(stored.assignmentMethod, 'auto');
    expect(stored.deliveryStatus, DeliveryStatus.pending);

    final driverAssignments = await deliveryRepo.getAssignments(driverId);
    final persistedForDriver = driverAssignments.when(
      onLeft: (_) => <DeliveryAssignment>[],
      onRight: (list) => list,
    );
    expect(persistedForDriver, hasLength(1));
    expect(persistedForDriver.single.id, stored.id);

    // ── 4) Chat: customer sends on the order-scoped thread; BOTH the
    //       customer-side and the assigned-driver-side reads see it.
    final chatRepo = InMemoryChatRepository();

    final customerChat = ChatController(chatRepo);
    addTearDown(customerChat.dispose);
    customerChat.init(order.id, _customerId);

    const body = 'وصلت للمطعم، فين الأوردر؟';
    final rejection = await customerChat.send(body);
    expect(rejection, isNull);

    // Customer read-back: live thread state shows the sent message.
    final customerMessages =
        customerChat.state.valueOrNull ?? const <ChatMessage>[];
    expect(customerMessages, hasLength(1));
    expect(customerMessages.single.senderId, _customerId);
    expect(customerMessages.single.orderId, order.id);
    expect(customerMessages.single.body, body);
    expect(customerMessages.single.id, isNotEmpty);

    // Driver read-back: a fresh controller bound to the SAME order id (as the
    // winning driver) loads the identical history.
    final driverChat = ChatController(chatRepo);
    addTearDown(driverChat.dispose);
    driverChat.init(order.id, driverId);
    await Future<void>.delayed(Duration.zero); // settle history-first snapshot
    final driverMessages =
        driverChat.state.valueOrNull ?? const <ChatMessage>[];
    expect(driverMessages, hasLength(1));
    expect(driverMessages.single.id, customerMessages.single.id);
    expect(driverMessages.single.senderId, _customerId);
    expect(driverMessages.single.body, body);

    // Persisted exactly once under the order id.
    final historyResult = await chatRepo.history(order.id);
    expect(historyResult.isRight, isTrue);
    final history = historyResult.when(
      onLeft: (_) => <ChatMessage>[],
      onRight: (list) => list,
    );
    expect(history, hasLength(1));
    expect(history.single.orderId, order.id);
    expect(history.single.senderId, _customerId);
  });
}
