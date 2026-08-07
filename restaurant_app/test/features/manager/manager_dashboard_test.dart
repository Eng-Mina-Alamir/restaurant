import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/metrics_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/manager_dashboard_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  group('computeMetrics', () {
    test('empty orders produce zeroed metrics', () {
      final metrics = computeMetrics(const []);
      expect(metrics.totalSales, 0);
      expect(metrics.totalOrders, 0);
      expect(metrics.itemsSold, isEmpty);
    });

    test('aggregates order totals and item popularity', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cart = container.read(cartControllerProvider.notifier);
      cart.addItem(const CartItem(menuItem: burger, quantity: 2));
      final orders = container.read(ordersControllerProvider.notifier);
      await orders.placeOrder();

      final metrics = computeMetrics(container.read(ordersControllerProvider));
      expect(metrics.totalOrders, 1);
      // Not "completed" so totalSales stays 0.
      expect(metrics.totalSales, 0);
      expect(metrics.itemsSold['برجر كلاسيك'], 2);
      expect(metrics.categoryRevenue['برجر'], 56.0);
    });

    test('category revenue aggregates multiple orders', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cart = container.read(cartControllerProvider.notifier);
      cart.addItem(const CartItem(menuItem: burger, quantity: 1));
      cart.addItem(const CartItem(menuItem: burger, quantity: 1));
      final orders = container.read(ordersControllerProvider.notifier);
      await orders.placeOrder();

      final metrics = computeMetrics(container.read(ordersControllerProvider));
      expect(metrics.categoryRevenue['برجر'], 56.0);
    });

    test('tracks revenue by payment method', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cart = container.read(cartControllerProvider.notifier);
      cart.addItem(const CartItem(menuItem: burger, quantity: 1));
      final orders = container.read(ordersControllerProvider.notifier);
      await orders.placeOrder(paymentMethod: PaymentMethod.card);

      final metrics = computeMetrics(container.read(ordersControllerProvider));
      expect(metrics.paymentMethodRevenue['بطاقة'], 32.2);
    });

    test('counts completed orders in sales, pending ones do not', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cart = container.read(cartControllerProvider.notifier);
      cart.addItem(const CartItem(menuItem: burger, quantity: 1));
      final orders = container.read(ordersControllerProvider.notifier);
      final placed = await orders.placeOrder();
      expect(placed, isNotNull);

      // Pending order is not yet revenue.
      expect(
        computeMetrics(container.read(ordersControllerProvider)).totalSales,
        0,
      );

      // Completing it makes it count toward sales.
      await orders.updateStatus(placed!.id, OrderStatus.completed);
      expect(
        computeMetrics(container.read(ordersControllerProvider)).totalSales,
        32.2,
      );
    });
  });

  testWidgets('manager dashboard renders metric cards', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ManagerDashboardPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('نظرة عامة'), findsOneWidget);
    expect(find.text('إجمالي المبيعات'), findsOneWidget);
    expect(find.text('عدد الطلبات'), findsOneWidget);
  });

  testWidgets('shows an order status breakdown when orders exist', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger, quantity: 1));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ManagerDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    // One pending order in the seeded flow.
    expect(find.text('الطلبات حسب الحالة'), findsOneWidget);
    expect(find.textContaining('قيد الانتظار: 1'), findsOneWidget);
  });

  testWidgets('shows no-data placeholder when there are no orders', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ManagerDashboardPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('الطلبات حسب الحالة'), findsOneWidget);
    expect(find.text('لا توجد بيانات بعد'), findsWidgets);
  });
}
