import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/kds/presentation/widgets/ticket_print_dialog.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  group('TicketPrintDialog Widget Tests', () {
    testWidgets('renders thermal preview and dialog elements', (tester) async {
      const item = MenuItem(
        id: 'm1',
        categoryId: 'cat-shawarma',
        name: 'شاورما لحم عربي',
        description: 'شاورما طازجة مع الصصوص',
        price: 65.0,
      );

      final order = OrderEntity(
        id: 'ORD-999',
        restaurantId: 'rest-1',
        tableId: 'TBL-12',
        customerId: 'CUST-3',
        orderType: OrderType.dineIn,
        status: OrderStatus.preparing,
        items: [
          OrderItem(
            menuItem: item,
            quantity: 1,
            selectedModifiers: const [],
            addedAt: DateTime.now(),
          ),
        ],
        subtotal: 65.0,
        taxAmount: 9.75,
        totalAmount: 74.75,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TicketPrintDialog(
                order: order,
                tableDisplay: '12',
              ),
            ),
          ),
        ),
      );

      expect(find.text('معاينة تذكرة الطباعة الحرارية'), findsOneWidget);
      expect(find.textContaining('شاورما لحم عربي'), findsOneWidget);
      expect(find.text('إغلاق'), findsOneWidget);
      expect(find.text('طباعة التذكرة الآن'), findsOneWidget);
    });
  });
}
