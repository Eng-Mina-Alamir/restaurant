import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/orders/presentation/pages/order_confirmation_page.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  final order = OrderEntity(
    id: 'ORD-0001',
    restaurantId: 'r1',
    orderType: OrderType.delivery,
    status: OrderStatus.confirmed,
    items: [
      OrderItem(
        menuItem: burger,
        quantity: 2,
        itemTotal: 56,
        addedAt: DateTime(2024),
      ),
    ],
    subtotal: 56,
    taxAmount: 8.4,
    totalAmount: 64.4,
    estimatedMinutes: 30,
    createdAt: DateTime(2024),
  );

  testWidgets('shows line items and financial summary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OrderConfirmationPage(order: order)),
    );

    expect(find.text('2 × برجر كلاسيك'), findsOneWidget);
    expect(find.textContaining('56.00'), findsWidgets);
    expect(find.textContaining('تفاصيل الطلب'), findsOneWidget);
    expect(find.textContaining('ملخص الطلب'), findsOneWidget);
    expect(find.textContaining('64.40'), findsOneWidget);
  });

  testWidgets('shows a single-hash friendly order number', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OrderConfirmationPage(order: order)),
    );

    // ORD-0001 → #1 (no double hash).
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('##1'), findsNothing);
  });
}
