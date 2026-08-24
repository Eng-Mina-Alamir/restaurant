import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/payment/payment_service.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../helpers/test_container.dart';

void main() {
  group('Payment Checkout Flow Integration Test', () {
    test(
      'add items to cart, process payment through PaymentService, and place order',
      () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        await primeMenuForCheckout(container);

        final cartController = container.read(cartControllerProvider.notifier);
        final ordersController = container.read(
          ordersControllerProvider.notifier,
        );
        final paymentService = container.read(paymentServiceProvider);

        final item = MenuSeedData.items.first;
        cartController.addItem(CartItem(menuItem: item, quantity: 2));

        final cartTotals = cartController.totals;
        expect(cartTotals.totalAmount, greaterThan(0));

        // 1. Process payment
        final paymentResult = await paymentService.payForOrder(
          orderId: 'ORD-TEMP-1',
          amount: cartTotals.totalAmount,
          method: PaymentMethod.card,
          phone: '0501234567',
        );
        expect(paymentResult.isSuccess, isTrue);
        expect(paymentService.transactions, hasLength(1));

        // 2. Place order
        final order = await ordersController.placeOrder(
          paymentMethod: PaymentMethod.card,
        );
        expect(order, isNotNull);
        expect(order?.paymentMethod, PaymentMethod.card);
        expect(cartController.state, isEmpty);
      },
    );
  });
}
