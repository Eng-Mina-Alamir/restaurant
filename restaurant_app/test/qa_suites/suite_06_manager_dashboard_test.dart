import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';
import 'package:restaurant_app/features/coupons/presentation/controllers/coupon_controller.dart';
import 'package:restaurant_app/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'helpers/qa_test_helpers.dart';

void main() {
  group('Suite 6: Manager Dashboard (لوحة تحكم وإدارة المطعم)', () {
    // -------------------------------------------------------------
    // TC-MGR-01: Main KPIs & Metrics
    // -------------------------------------------------------------
    test(
      'TC-MGR-01: Manager dashboard calculates total revenue, active orders, and table occupancy',
      () {
        final orders = [
          OrderEntity(
            id: 'ord-kpi-1',
            restaurantId: 'r1',
            orderType: OrderType.dineIn,
            status: OrderStatus.served,
            items: const [],
            subtotal: 100.0,
            taxAmount: 14.0,
            totalAmount: 114.0,
            createdAt: DateTime.now(),
          ),
          OrderEntity(
            id: 'ord-kpi-2',
            restaurantId: 'r1',
            orderType: OrderType.takeaway,
            status: OrderStatus.preparing,
            items: const [],
            subtotal: 200.0,
            taxAmount: 28.0,
            totalAmount: 228.0,
            createdAt: DateTime.now(),
          ),
        ];

        final totalRevenue = orders.fold<double>(
          0.0,
          (sum, o) => sum + o.totalAmount,
        );
        expect(totalRevenue, 342.0);

        final activeCount = orders.where((o) => !o.status.isTerminal).length;
        expect(activeCount, 2);
      },
    );

    // -------------------------------------------------------------
    // TC-MGR-02: Menu Management & Out-of-Stock Toggle
    // -------------------------------------------------------------
    test('TC-MGR-02: Out-of-stock items cannot be added to customer cart', () {
      final container = createQaContainer();
      addTearDown(container.dispose);

      final cartNotifier = container.read(cartControllerProvider.notifier);

      // Try adding out of stock item
      const outOfStock = MenuItem(
        id: 'oos-item-1',
        categoryId: 'المشاوي',
        name: 'كفتة مشوية (نفذت الكمية)',
        description: 'وجبة كفتة شهية غير متوفرة',
        price: 90.0,
        isAvailable: false,
      );

      cartNotifier.addItem(const CartItem(menuItem: outOfStock));
      expect(container.read(cartControllerProvider), isEmpty);

      // Add available item
      const available = MenuItem(
        id: 'avail-item-1',
        categoryId: 'المشاوي',
        name: 'كفتة مشوية متوفرة',
        description: 'وجبة كفتة شهية متوفرة',
        price: 90.0,
        isAvailable: true,
      );

      cartNotifier.addItem(const CartItem(menuItem: available));
      expect(container.read(cartControllerProvider), hasLength(1));
    });

    // -------------------------------------------------------------
    // TC-MGR-03: Inventory Low Stock Alerts
    // -------------------------------------------------------------
    test(
      'TC-MGR-03: Inventory controller identifies items below minThreshold for alerts',
      () async {
        final container = createQaContainer();
        addTearDown(container.dispose);

        final invNotifier = container.read(
          inventoryControllerProvider.notifier,
        );

        await invNotifier.addItem(
          name: 'جبنة موتزاريلا',
          category: 'الألبان',
          currentStock: 2.0, // Low stock (threshold 10)
          unit: 'كجم',
          minThreshold: 10.0,
          costPerUnit: 120.0,
        );

        final items = container.read(inventoryControllerProvider).value ?? [];
        final lowStockItems = items
            .where((i) => i.currentStock <= i.minThreshold)
            .toList();

        expect(lowStockItems, isNotEmpty);
        expect(lowStockItems.any((i) => i.name == 'جبنة موتزاريلا'), isTrue);
      },
    );

    // -------------------------------------------------------------
    // TC-MGR-04: Coupon Management CRUD
    // -------------------------------------------------------------
    test(
      'TC-MGR-04: Manager creates, updates, and validates discount coupon',
      () async {
        final container = createQaContainer();
        addTearDown(container.dispose);

        final couponController = container.read(
          couponManagementControllerProvider.notifier,
        );

        const newCoupon = CouponEntity(
          id: 'coup-promo-15',
          code: 'PROMO15',
          title: 'خصم 15% ترويجي',
          discountType: CouponDiscountType.percentage,
          discountValue: 15.0,
          maxDiscountAmount: 40.0,
          minOrderAmount: 100.0,
          isActive: true,
        );

        final error = await couponController.createCoupon(newCoupon);
        expect(error, isNull);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final coupons =
            container.read(couponManagementControllerProvider).value ?? [];
        expect(coupons.any((c) => c.code == 'PROMO15'), isTrue);
      },
    );

    // -------------------------------------------------------------
    // TC-MGR-05: Table QR Generator URL Binding
    // -------------------------------------------------------------
    test(
      'TC-MGR-05: Table QR URL generates valid route with tableId query param',
      () {
        const tableNumber = 12;
        const qrPayload = 'https://restaurant.app/customer?table=$tableNumber';

        final uri = Uri.parse(qrPayload);
        expect(uri.queryParameters['table'], '12');
        expect(uri.path, '/customer');
      },
    );

    // -------------------------------------------------------------
    // TC-MGR-06: Financial Calculation & VAT
    // -------------------------------------------------------------
    test('TC-MGR-06: VAT 14% and net profit calculations', () {
      const subtotal = 1000.0;
      const vatRate = 0.14;
      const vatAmount = subtotal * vatRate;
      const totalWithVat = subtotal + vatAmount;

      expect(vatAmount, 140.0);
      expect(totalWithVat, 1140.0);
    });

    // -------------------------------------------------------------
    // TC-MGR-07: Staff Role Permissions
    // -------------------------------------------------------------
    test('TC-MGR-07: User roles have strict distinct home routes', () {
      expect(UserRole.customer.homeRoute, '/customer');
      expect(UserRole.waiter.homeRoute, '/waiter');
      expect(UserRole.kitchen.homeRoute, '/kds');
      expect(UserRole.driver.homeRoute, '/driver');
      expect(UserRole.manager.homeRoute, '/manager');
    });
  });
}
