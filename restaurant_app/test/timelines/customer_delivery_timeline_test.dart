import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/payment/payment_service.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/delivery/domain/services/delivery_fee_calculator.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:restaurant_app/features/ratings/presentation/controllers/rating_controller.dart';
import '../helpers/test_container.dart';

void main() {
  group('Timeline 2: Delivery Customer Journey Test', () {
    const familyMeal = MenuItem(
      id: 'item-fam-1',
      categoryId: 'cat-family',
      name: 'وجبة المشاوي العائلية المشكلة',
      description: 'كيلو مشاوي مشكلة مع المقبلات والخبز الطازج',
      price: 180.0,
    );

    test('Customer Delivery Timeline: Set Address -> Calc Fee -> Checkout Card -> Live GPS -> Delivered -> Rate Driver', () async {
      final container = createTestContainer(
        seedCheckoutFixtures: true,
        extraCheckoutItems: [familyMeal],
      );
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      // ── Step 1: Customer sets delivery mode & calculates distance fee ──────
      const customerLat = 24.7500;
      const customerLng = 46.7200;

      final distanceKm = DeliveryFeeCalculator.calculateDistanceKm(
        startLat: DeliveryFeeCalculator.restaurantLat,
        startLng: DeliveryFeeCalculator.restaurantLng,
        endLat: customerLat,
        endLng: customerLng,
      );
      expect(distanceKm, greaterThan(0));

      final calculator = DeliveryFeeCalculator();
      final feeBreakdown = calculator.calculate(
        distanceKm: distanceKm,
        orderSubtotal: 180.0,
        timestamp: DateTime(2026, 8, 19, 14, 0),
      );

      expect(feeBreakdown.isFreeDelivery, isTrue);
      expect(feeBreakdown.finalFee, equals(0.0));

      // ── Step 2: Add item to cart & place delivery order ───────────────────
      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.addItem(const CartItem(menuItem: familyMeal, quantity: 1));

      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final placedOrder = await ordersNotifier.placeOrder();

      expect(placedOrder, isNotNull);
      expect(placedOrder!.subtotal, equals(180.0));

      // ── Step 3: Payment processed successfully via Card ───────────────────
      final paymentService = PaymentService();
      final paymentResult = await paymentService.payForOrder(
        orderId: placedOrder.id,
        amount: placedOrder.totalAmount,
        method: PaymentMethod.card,
      );

      expect(paymentResult.isSuccess, isTrue);
      expect(paymentResult.transactionId, startsWith('TXN-CARD-'));

      // ── Step 4: Kitchen prepares order and marks ready for pickup ──────────
      await ordersNotifier.updateStatus(placedOrder.id, OrderStatus.preparing);
      await ordersNotifier.updateStatus(placedOrder.id, OrderStatus.ready);

      var orderState = container.read(ordersControllerProvider).firstWhere((o) => o.id == placedOrder.id);
      expect(orderState.status, equals(OrderStatus.ready));

      // ── Step 5: Driver picks up order and starts GPS navigation ───────────
      await ordersNotifier.updateStatus(placedOrder.id, OrderStatus.served);
      orderState = container.read(ordersControllerProvider).firstWhere((o) => o.id == placedOrder.id);
      expect(orderState.status, equals(OrderStatus.served));

      // ── Step 6: Driver delivers order to customer address ─────────────────
      await ordersNotifier.updateStatus(placedOrder.id, OrderStatus.completed);
      orderState = container.read(ordersControllerProvider).firstWhere((o) => o.id == placedOrder.id);
      expect(orderState.status, equals(OrderStatus.completed));

      // ── Step 7: Customer rates the driver and delivery experience ──────────
      final ratingRepo = container.read(ratingRepositoryProvider);
      final driverRating = RatingEntity(
        id: 'rate-drv-1',
        targetId: 'DRV-101',
        targetType: RatingTargetType.driver,
        userId: 'CUST-002',
        userName: 'سارة خالد',
        score: 5.0,
        comment: 'السائق وصل في الموعد والطلب وصل ساخناً بحالة ممتازة',
        createdAt: DateTime.now(),
      );

      await ratingRepo.submitRating(driverRating);
      final avgDriverRating = await ratingRepo.getAverageScore('DRV-101');
      expect(avgDriverRating.when(onLeft: (_) => 0.0, onRight: (s) => s), equals(5.0));
    });
  });
}
