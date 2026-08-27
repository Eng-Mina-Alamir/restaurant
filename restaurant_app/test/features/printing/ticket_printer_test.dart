import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/printing/ticket_printer_service.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  group('Ticket Printer Service Tests', () {
    late TicketPrinterService printerService;
    late OrderEntity testOrder;

    setUp(() {
      printerService = const TicketPrinterService();
      testOrder = OrderEntity(
        id: 'ord-9988',
        restaurantId: 'rest-1',
        orderType: OrderType.dineIn,
        tableId: 't2',
        customerId: 'cust-123',
        createdAt: DateTime.now(),
        status: OrderStatus.preparing,
        items: [
          OrderItem(
            menuItem: const MenuItem(
              id: 'm1',
              categoryId: 'برجر',
              name: 'برجر لحم فاخر',
              description: 'وصف',
              price: 35.0,
            ),
            quantity: 2,
            specialNotes: 'بدون بصل',
            addedAt: DateTime.now(),
          ),
        ],
        subtotal: 70.0,
        taxAmount: 10.5,
        totalAmount: 80.5,
      );
    });

    test(
      'generates formatted text ticket with order details, items and notes',
      () {
        final ticket = printerService.generateTicketText(
          testOrder,
          tableDisplay: '2',
        );
        expect(ticket.contains('مطعم الأصالة والنكهة'), isTrue);
        expect(ticket.contains('#9988'), isTrue);
        expect(ticket.contains('طاولة 2'), isTrue);
        expect(ticket.contains('برجر لحم فاخر'), isTrue);
        expect(ticket.contains('بدون بصل'), isTrue);
        expect(ticket.contains('80.50'), isTrue);
      },
    );

    test('generates ESC/POS binary byte stream with init and cut commands', () {
      final bytes = printerService.generateEscPosBytes(
        testOrder,
        tableDisplay: '2',
      );
      expect(bytes.isNotEmpty, isTrue);
      // ESC @ init command
      expect(bytes[0], 0x1B);
      expect(bytes[1], 0x40);
      // GS V cut command at end
      expect(bytes[bytes.length - 4], 0x1D);
      expect(bytes[bytes.length - 3], 0x56);
    });

    test('dispatches simulated print job successfully', () async {
      final ok = await printerService.printKitchenTicket(
        testOrder,
        tableDisplay: '2',
      );
      expect(ok, isTrue);
    });
  });
}
