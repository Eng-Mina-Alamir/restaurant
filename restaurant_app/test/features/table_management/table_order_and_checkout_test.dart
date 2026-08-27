import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/core/printing/ticket_printer_service.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/shift_entity.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/data/repositories/in_memory_table_repository.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';

import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';

void main() {
  group('Table Order & Checkout Workflows Test', () {
    late InMemoryOrderRepository orderRepo;
    late InMemoryTableRepository tableRepo;
    late CartController cartController;
    late NewOrderNotifier newOrderNotifier;
    late OrdersController ordersController;
    late TableController tableController;

    const testMenuItem1 = MenuItem(
      id: 'item-1',
      categoryId: 'cat-1',
      name: 'برجر لحم كلاسيك',
      price: 40.0,
      description: 'برجر طازج مع الجبن',
      imageUrl: 'assets/images/burger.png',
    );

    const testMenuItem2 = MenuItem(
      id: 'item-2',
      categoryId: 'cat-2',
      name: 'عصير برتقال طازج',
      price: 15.0,
      description: 'عصير طبيعي',
      imageUrl: 'assets/images/juice.png',
    );

    setUp(() {
      orderRepo = InMemoryOrderRepository();
      tableRepo = InMemoryTableRepository();
      cartController = CartController();
      newOrderNotifier = NewOrderNotifier();
      ordersController = OrdersController(
        orderRepo,
        cartController,
        newOrderNotifier,
      );
      tableController = TableController(tableRepo);
    });

    test('1. Place initial table order and mark table occupied', () async {
      cartController.addItem(const CartItem(menuItem: testMenuItem1, quantity: 2));

      final order = await ordersController.placeOrderForTable(
        't1',
        paymentMethod: PaymentMethod.cash,
      );

      expect(order, isNotNull);
      expect(order!.items.length, 1);
      expect(order.tableId, 't1');
      expect(order.subtotal, 80.0);

      await tableController.occupy('t1', orderId: order.id);
      final table = tableController.tableById('t1');
      expect(table?.status, TableStatus.occupied);
      expect(table?.currentOrderId, order.id);
    });

    test('2. Append additional items to an already occupied table order', () async {
      // First order
      cartController.addItem(const CartItem(menuItem: testMenuItem1, quantity: 1));
      final initialOrder = await ordersController.placeOrderForTable('t1');
      expect(initialOrder, isNotNull);
      expect(initialOrder!.items.length, 1);

      // Append drinks to the open order
      final appendItems = [const CartItem(menuItem: testMenuItem2, quantity: 2)];
      final updatedOrder = await ordersController.addItemsToExistingOrder(
        initialOrder.id,
        appendItems,
      );

      expect(updatedOrder, isNotNull);
      expect(updatedOrder!.items.length, 2);
      expect(updatedOrder.subtotal, 70.0); // 40 + (15 * 2) = 70
      expect(updatedOrder.totalAmount, greaterThan(70.0)); // Includes 15% VAT
    });

    test('3. Complete and pay order, then release table for cleaning', () async {
      cartController.addItem(const CartItem(menuItem: testMenuItem1, quantity: 1));
      final order = await ordersController.placeOrderForTable('t1');
      expect(order, isNotNull);

      await tableController.occupy('t1', orderId: order!.id);

      final completed = await ordersController.completeAndPayOrder(
        order.id,
        paymentMethod: PaymentMethod.card,
        discountAmount: 5.0,
      );

      expect(completed, isNotNull);
      expect(completed!.status, OrderStatus.completed);
      expect(completed.paymentMethod, PaymentMethod.card);
      expect(completed.discountAmount, 5.0);

      // Release table
      await tableController.release('t1', needsCleaning: true);
      final table = tableController.tableById('t1');
      expect(table?.status, TableStatus.needsCleaning);
      expect(table?.currentOrderId, isNull);
    });

    test('4. TicketPrinterService generates customer tax invoice text', () {
      const printer = TicketPrinterService();
      cartController.addItem(const CartItem(menuItem: testMenuItem1, quantity: 2));

      final invoiceText = printer.generateCustomerInvoiceText(
        ordersController.state.isNotEmpty
            ? ordersController.state.first
            : OrderEntity(
                id: 'ORD-0001',
                restaurantId: 'rest-1',
                orderType: OrderType.dineIn,
                status: OrderStatus.completed,
                paymentMethod: PaymentMethod.card,
                createdAt: DateTime.now(),
                subtotal: 80.0,
                taxAmount: 12.0,
                totalAmount: 92.0,
              ),
        tableDisplay: '5',
      );

      expect(invoiceText, contains('فاتورة ضريبية مبسطة'));
      expect(invoiceText, contains('طاولة رقم: 5'));
      expect(invoiceText, contains('الرقم الضريبي'));
    });

    test('5. ShiftEntity calculates cash discrepancy and generates Z-Report', () {
      final shift = ShiftEntity(
        id: 'SHIFT-01',
        cashierId: 'usr-1',
        cashierName: 'أحمد',
        openedAt: DateTime.now().subtract(const Duration(hours: 8)),
        closedAt: DateTime.now(),
        openingCashFloat: 500.0,
        cashSales: 1200.0,
        cardSales: 2500.0,
        actualCashCount: 1700.0, // exactly 500 + 1200
        totalOrdersCount: 25,
      );

      expect(shift.expectedCashInDrawer, 1700.0);
      expect(shift.cashDiscrepancy, 0.0);

      final zReport = shift.generateZReportText();
      expect(zReport, contains('Z-Report'));
      expect(zReport, contains('المبلغ الافتتاحي'));
      expect(zReport, contains('مطابق تماماً'));
    });
  });
}
