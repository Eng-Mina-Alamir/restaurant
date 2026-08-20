import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';
import 'package:restaurant_app/features/loyalty/presentation/controllers/loyalty_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:restaurant_app/features/ratings/presentation/controllers/rating_controller.dart';

void main() {
  group('Timeline 1: Dine-In Customer Full Journey Test', () {
    const extraCheese = MenuModifierOption(id: 'mod-cheese', name: 'جبنة شيدر إضافية', extraPrice: 5.0);
    const spicySauce = MenuModifierOption(id: 'mod-sauce', name: 'صوص حار مميز', extraPrice: 3.0);

    const gourmetBurger = MenuItem(
      id: 'menu-burger-1',
      categoryId: 'cat-burgers',
      name: 'برجر لحم بلاك أنجوس',
      description: 'لحم أنجوس فاخر مشوي مع الخس والطماطم',
      price: 65.0,
    );

    const icedTea = MenuItem(
      id: 'menu-drink-1',
      categoryId: 'cat-beverages',
      name: 'شاي مثلج بالخوخ',
      description: 'شاي مثلج منعش',
      price: 18.0,
    );

    const couponWelcome = CouponEntity(
      id: 'cpn-01',
      code: 'WELCOME20',
      title: 'خصم ترحيبي 20%',
      discountType: CouponDiscountType.percentage,
      discountValue: 20.0,
      minOrderAmount: 50.0,
    );

    test('Customer Dine-In Timeline: QR Scan -> Browse -> Cart -> Coupon -> Order -> Live Prep -> Serve -> Loyalty & Rating', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // ── Step 1: Customer arrives at table and scans QR code ───────────────
      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.setTableId('TBL-04');
      expect(cartNotifier.activeTableId, equals('TBL-04'));

      // ── Step 2: Customer browses menu, customizes burger, and adds drinks ───
      const burgerItem = CartItem(
        menuItem: gourmetBurger,
        quantity: 2,
        selectedModifiers: [extraCheese, spicySauce],
      ); // (65 + 5 + 3) * 2 = 146.0

      const drinkItem = CartItem(
        menuItem: icedTea,
        quantity: 2,
      ); // 18 * 2 = 36.0

      cartNotifier.addItem(burgerItem);
      cartNotifier.addItem(drinkItem);

      // Initial subtotal check: 146 + 36 = 182.0 SAR
      expect(cartNotifier.itemCount, equals(2));
      expect(cartNotifier.totals.subtotal, equals(182.0));

      // ── Step 3: Customer validates and applies 20% discount coupon ─────────
      final couponError = couponWelcome.validate(cartNotifier.totals.subtotal);
      expect(couponError, isNull);

      final discountAmount = couponWelcome.calculateDiscount(cartNotifier.totals.subtotal);
      expect(discountAmount, closeTo(182.0 * 0.20, 0.01)); // 36.4 SAR

      // ── Step 4: Customer submits order for Table 4 ─────────────────────────
      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final placedOrder = await ordersNotifier.placeOrderForTable('TBL-04');

      expect(placedOrder, isNotNull);
      expect(placedOrder!.tableId, equals('TBL-04'));
      expect(placedOrder.orderType, equals(OrderType.dineIn));
      expect(placedOrder.status, equals(OrderStatus.pending));
      expect(placedOrder.items.length, equals(2));

      // Cart is cleared after successful order placement
      expect(container.read(cartControllerProvider), isEmpty);

      // ── Step 5: Kitchen and Waiter advance order lifecycle ─────────────────
      // 5.1: Kitchen starts preparation
      await ordersNotifier.updateStatus(placedOrder.id, OrderStatus.preparing);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      var currentOrder = container.read(ordersControllerProvider).firstWhere((o) => o.id == placedOrder.id);
      expect(currentOrder.status, equals(OrderStatus.preparing));

      // 5.2: Kitchen marks order ready
      await ordersNotifier.updateStatus(placedOrder.id, OrderStatus.ready);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      currentOrder = container.read(ordersControllerProvider).firstWhere((o) => o.id == placedOrder.id);
      expect(currentOrder.status, equals(OrderStatus.ready));

      // 5.3: Waiter serves the order at Table 4
      await ordersNotifier.updateStatus(placedOrder.id, OrderStatus.served);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      currentOrder = container.read(ordersControllerProvider).firstWhere((o) => o.id == placedOrder.id);
      expect(currentOrder.status, equals(OrderStatus.served));

      // ── Step 6: Customer completes order, rates food, and earns loyalty pts ─
      await ordersNotifier.updateStatus(placedOrder.id, OrderStatus.completed);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      currentOrder = container.read(ordersControllerProvider).firstWhere((o) => o.id == placedOrder.id);
      expect(currentOrder.status, equals(OrderStatus.completed));

      // 6.1: Loyalty points accrual
      final loyaltyNotifier = container.read(loyaltyControllerProvider.notifier);
      await loyaltyNotifier.earnPoints(
        orderTotal: currentOrder.totalAmount,
        orderId: currentOrder.id,
      );
      expect(container.read(loyaltyControllerProvider).value?.currentPoints, isNotNull);

      // 6.2: Customer submits 5-star rating review
      final ratingRepo = container.read(ratingRepositoryProvider);
      final rating = RatingEntity(
        id: 'rate-cust-1',
        targetId: gourmetBurger.id,
        targetType: RatingTargetType.menuItem,
        userId: 'CUST-001',
        userName: 'أحمد محمود',
        score: 5.0,
        comment: 'الأكل ساخن وممتاز جداً والخدمة سريعة!',
        createdAt: DateTime.now(),
      );

      await ratingRepo.submitRating(rating);
      final avgResult = await ratingRepo.getAverageScore(gourmetBurger.id);
      expect(avgResult.when(onLeft: (_) => 0.0, onRight: (s) => s), equals(5.0));
    });
  });
}
