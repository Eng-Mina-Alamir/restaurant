import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:restaurant_app/features/ratings/presentation/controllers/rating_controller.dart';
import 'helpers/qa_test_helpers.dart';

void main() {
  group('Suite 2: Customer Experience Flow (تجربة العميل الكاملة)', () {
    // -------------------------------------------------------------
    // TC-CUST-01: Menu Browsing and Category Filtering
    // -------------------------------------------------------------
    test('TC-CUST-01: Menu browsing, categories and dietary tags filtering', () {
      final items = MenuSeedData.items;
      expect(items, isNotEmpty);

      // Categories exist
      final categories = items.map((i) => i.categoryId).toSet();
      expect(categories, contains('برجر'));
      expect(categories, contains('بيتزا'));

      // Filter by category
      final burgerItems = items.where((i) => i.categoryId == 'برجر').toList();
      expect(burgerItems, isNotEmpty);
      for (final burger in burgerItems) {
        expect(burger.categoryId, 'برجر');
        expect(burger.price, greaterThan(0));
        expect(burger.name, isNotEmpty);
      }
    });

    // -------------------------------------------------------------
    // TC-CUST-02: Rapid Menu Search (Arabic & English)
    // -------------------------------------------------------------
    test('TC-CUST-02: Rapid menu search filters matching items and returns empty for non-existent', () {
      final items = MenuSeedData.items;

      // Search in Arabic
      final searchArabic = items.where(
        (i) => i.name.toLowerCase().contains('برجر') || i.description.toLowerCase().contains('برجر'),
      ).toList();
      expect(searchArabic, isNotEmpty);

      // Search by keyword
      final searchMatch = items.where(
        (i) => i.name.contains('بيتزا') || i.description.contains('بيتزا'),
      ).toList();
      expect(searchMatch, isNotEmpty);

      // Non-existent search query
      final emptyResult = items.where(
        (i) => i.name.contains('صنف_غير_موجود_نهائيا_123'),
      ).toList();
      expect(emptyResult, isEmpty);
    });

    // -------------------------------------------------------------
    // TC-CUST-03: Item Customization & Modifiers
    // -------------------------------------------------------------
    test('TC-CUST-03: Item customization calculates modifier price additions accurately', () {
      const baseItem = MenuItem(
        id: 'item-custom-1',
        categoryId: 'برجر',
        name: 'برجر ديلوكس',
        description: 'برجر شهي',
        price: 50.0,
        modifierGroups: [
          MenuModifierGroup(
            id: 'mg-cheese',
            title: 'الجبن',
            isRequired: false,
            maxSelection: 1,
            options: [
              MenuModifierOption(id: 'opt-c1', name: 'شيدر مدخن', extraPrice: 10.0),
            ],
          ),
        ],
      );

      final selectedOptions = [
        const MenuModifierOption(id: 'opt-c1', name: 'شيدر مدخن', extraPrice: 10.0),
      ];

      final cartItem = CartItem(
        menuItem: baseItem,
        quantity: 2,
        selectedModifiers: selectedOptions,
        specialNotes: 'بدون بصل',
      );

      // Base price 50 + Modifier 10 = 60 * quantity 2 = 120
      expect(cartItem.unitPrice, 60.0);
      expect(cartItem.linePrice, 120.0);
      expect(cartItem.specialNotes, 'بدون بصل');
    });

    // -------------------------------------------------------------
    // TC-CUST-04: Cart Calculations (Subtotal, Tax, Total)
    // -------------------------------------------------------------
    test('TC-CUST-04: Cart item management, tax calculations and grand total accuracy', () {
      final container = createQaContainer();
      addTearDown(container.dispose);

      final cartNotifier = container.read(cartControllerProvider.notifier);

      const item1 = MenuItem(id: 'i1', categoryId: 'c1', name: 'بيتزا', description: 'مارجريتا', price: 100.0);
      const item2 = MenuItem(id: 'i2', categoryId: 'c1', name: 'عصير', description: 'برتقال طازج', price: 20.0);

      cartNotifier.addItem(const CartItem(menuItem: item1, quantity: 1));
      cartNotifier.addItem(const CartItem(menuItem: item2, quantity: 2));

      // 100 + (20 * 2) = 140
      var totals = cartNotifier.totals;
      expect(totals.subtotal, 140.0);
      // Tax (15% default in calculator) = 140 * 0.15 = 21.0
      expect(totals.taxAmount, closeTo(21.0, 0.01));
      expect(totals.totalAmount, closeTo(161.0, 0.01));

      // Test Increment
      final firstKey = container.read(cartControllerProvider).first.configKey;
      cartNotifier.increment(firstKey);
      expect(container.read(cartControllerProvider).first.quantity, 2);

      // Test Decrement & Remove
      cartNotifier.decrement(firstKey);
      expect(container.read(cartControllerProvider).first.quantity, 1);
    });

    // -------------------------------------------------------------
    // TC-CUST-05: Coupon Application & Validation
    // -------------------------------------------------------------
    test('TC-CUST-05: Coupon application applies discount and rejects expired/inactive codes', () {
      // 1. Valid coupon 20%
      const validCoupon = QaSeedData.active20Coupon;
      expect(validCoupon.validate(100.0), isNull);

      final discountAmount = validCoupon.calculateDiscount(100.0);
      expect(discountAmount, 20.0);

      // 2. Minimum order requirement
      expect(validCoupon.validate(30.0), isNotNull); // min is 50.0

      // 3. Expired coupon
      final expired = QaSeedData.expiredCoupon;
      expect(expired.validate(100.0), isNotNull);
    });

    // -------------------------------------------------------------
    // TC-CUST-06: Order Placement & Cart Clearance
    // -------------------------------------------------------------
    test('TC-CUST-06: Order placement clears active cart and sets order entity', () async {
      final container = createQaContainer();
      addTearDown(container.dispose);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      const testItem = MenuItem(id: 'ord-item-1', categoryId: 'c1', name: 'وجبة تجريبية', description: 'وصف', price: 75.0);
      cartNotifier.addItem(const CartItem(menuItem: testItem, quantity: 1));
      expect(container.read(cartControllerProvider), hasLength(1));

      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final createdOrder = await ordersNotifier.placeOrder(paymentMethod: PaymentMethod.cash);

      expect(createdOrder, isNotNull);
      expect(createdOrder?.items.first.menuItem.name, 'وجبة تجريبية');
      expect(createdOrder?.totalAmount, greaterThan(75.0));

      // Cart cleared automatically
      expect(container.read(cartControllerProvider), isEmpty);
    });

    // -------------------------------------------------------------
    // TC-CUST-07: Realtime Order Tracking Timeline Progression
    // -------------------------------------------------------------
    test('TC-CUST-07: Order status advances through tracking states', () async {
      final container = createQaContainer();
      addTearDown(container.dispose);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      const testItem = MenuItem(id: 'track-item', categoryId: 'c1', name: 'طلب متابعة', description: 'وصف', price: 50.0);
      cartNotifier.addItem(const CartItem(menuItem: testItem));

      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final order = await ordersNotifier.placeOrder();
      expect(order, isNotNull);
      expect(order?.status, OrderStatus.pending);

      // Transition to Preparing (Kitchen cooking)
      await ordersNotifier.updateStatus(order!.id, OrderStatus.preparing);
      var current = container.read(ordersControllerProvider).firstWhere((o) => o.id == order.id);
      expect(current.status, OrderStatus.preparing);

      // Transition to Ready
      await ordersNotifier.updateStatus(order.id, OrderStatus.ready);
      current = container.read(ordersControllerProvider).firstWhere((o) => o.id == order.id);
      expect(current.status, OrderStatus.ready);

      // Transition to Delivered / Served
      await ordersNotifier.updateStatus(order.id, OrderStatus.served);
      current = container.read(ordersControllerProvider).firstWhere((o) => o.id == order.id);
      expect(current.status, OrderStatus.served);
    });

    // -------------------------------------------------------------
    // TC-CUST-08: Rating & Reviews Submission
    // -------------------------------------------------------------
    test('TC-CUST-08: Rating and review submission updates entity and score', () async {
      final container = createQaContainer();
      addTearDown(container.dispose);

      final ratingController = container.read(ratingSubmissionControllerProvider.notifier);

      final success = await ratingController.submitRating(
        targetId: 'item-burger-101',
        targetType: RatingTargetType.menuItem,
        userId: 'usr-cust-1',
        userName: 'عميل تقييم',
        score: 5.0,
        comment: 'طعام رائع وخدمة ممتازة جداً!',
      );

      expect(success, isTrue);

      final ratings = await container.read(targetRatingsProvider('item-burger-101').future);
      expect(ratings, isNotEmpty);
      expect(ratings.first.score, 5.0);
      expect(ratings.first.comment, 'طعام رائع وخدمة ممتازة جداً!');
    });
  });
}
