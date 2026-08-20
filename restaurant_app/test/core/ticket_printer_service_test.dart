import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/printing/ticket_printer_service.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  group('TicketPrinterService Unit Tests', () {
    late TicketPrinterService printerService;
    late OrderEntity dummyOrder;

    setUp(() {
      printerService = TicketPrinterService();

      const burger = MenuItem(
        id: 'item-1',
        categoryId: 'cat-burgers',
        name: 'Classic Cheeseburger',
        description: 'Juicy beef patty',
        price: 45.0,
      );

      dummyOrder = OrderEntity(
        id: 'ORD-1001',
        restaurantId: 'rest-1',
        tableId: 'TBL-5',
        customerId: 'CUST-88',
        orderType: OrderType.dineIn,
        status: OrderStatus.preparing,
        items: [
          OrderItem(
            menuItem: burger,
            quantity: 2,
            selectedModifiers: const [
              MenuModifierOption(id: 'mod-1', name: 'Extra Cheese', extraPrice: 5.0),
            ],
            specialNotes: 'No onions please',
            addedAt: DateTime(2026, 8, 19, 14, 30),
          ),
        ],
        subtotal: 100.0,
        taxAmount: 15.0,
        totalAmount: 115.0,
        createdAt: DateTime(2026, 8, 19, 14, 30),
      );
    });

    test('generateTicketText formats order details, modifiers, and notes', () {
      final text = printerService.generateTicketText(dummyOrder, tableDisplay: '5');

      expect(text, contains('مطعم الأصالة والنكهة'));
      expect(text, contains('Kitchen Ticket'));
      expect(text, contains('#1001'));
      expect(text, contains('طاولة 5'));
      expect(text, contains('CUST-88'));
      expect(text, contains('Classic Cheeseburger'));
      expect(text, contains('Extra Cheese'));
      expect(text, contains('No onions please'));
      expect(text, contains('115.00'));
    });

    test('generateTicketText formats takeaway order without table', () {
      final takeawayOrder = dummyOrder.copyWith(
        orderType: OrderType.takeaway,
        tableId: null,
      );

      final text = printerService.generateTicketText(takeawayOrder);
      expect(text, contains('نوع الطلب: takeaway'));
    });

    test('generateEscPosBytes creates valid ESC/POS byte sequence', () {
      final bytes = printerService.generateEscPosBytes(dummyOrder, tableDisplay: '5');

      expect(bytes, isNotEmpty);
      expect(bytes[0], 0x1B);
      expect(bytes[1], 0x40);
      expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x42, 0x00]);
    });

    test('printKitchenTicket completes simulated hardware handshake', () async {
      final result = await printerService.printKitchenTicket(dummyOrder, tableDisplay: '5');
      expect(result, isTrue);
    });
  });
}
