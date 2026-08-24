import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/loyalty/domain/entities/loyalty_entity.dart';
import 'package:restaurant_app/features/loyalty/presentation/controllers/loyalty_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../helpers/test_container.dart';

void main() {
  const meal = MenuItem(
    id: 'm-loyalty',
    categoryId: 'combo',
    name: 'وجبة التوفير العائلية',
    description: 'وجبة مميزة',
    price: 100.0,
  );

  test('Order & Loyalty Earn-Redeem Integration Flow', () async {
    final container = createTestContainer(
      seedCheckoutFixtures: true,
      extraCheckoutItems: [meal],
    );
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    final cart = container.read(cartControllerProvider.notifier);
    final ordersController = container.read(ordersControllerProvider.notifier);
    final loyaltyController = container.read(
      loyaltyControllerProvider.notifier,
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));

    final initialPoints = container
        .read(loyaltyControllerProvider)
        .value!
        .currentPoints;

    // Step 1: Customer adds items to cart & places order
    cart.addItem(
      const CartItem(menuItem: meal, quantity: 2),
    ); // 200 + 30 tax = 230
    final order = await ordersController.placeOrder(
      paymentMethod: PaymentMethod.card,
    );
    expect(order, isNotNull);
    expect(cart.state, isEmpty);

    // Step 2: Points earned from the placed order
    await loyaltyController.earnPoints(
      orderTotal: order!.totalAmount,
      orderId: order.id,
    );

    final updatedPoints = container
        .read(loyaltyControllerProvider)
        .value!
        .currentPoints;
    expect(updatedPoints, greaterThan(initialPoints));

    // Step 3: Redeem loyalty reward
    final rewards = await container.read(availableRewardsProvider.future);
    expect(rewards.isNotEmpty, isTrue);
    final affordableReward = rewards.firstWhere(
      (r) => r.pointsCost <= updatedPoints,
      orElse: () => const LoyaltyReward(
        id: 'r-auto',
        title: 'خصم خاص',
        description: 'وصف',
        pointsCost: 10,
        discountAmount: 5.0,
      ),
    );

    final redeemed = await loyaltyController.redeemReward(affordableReward);
    expect(redeemed, isTrue);

    final finalPoints = container
        .read(loyaltyControllerProvider)
        .value!
        .currentPoints;
    expect(finalPoints, updatedPoints - affordableReward.pointsCost);
  });
}
