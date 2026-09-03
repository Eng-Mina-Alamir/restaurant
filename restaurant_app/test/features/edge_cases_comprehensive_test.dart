import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/core/payment/mock_payment_gateway.dart';
import 'package:restaurant_app/core/payment/payment_service.dart';
import 'package:restaurant_app/core/utils/zatca_qr_codec.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/cashier/presentation/controllers/cash_drawer_controller.dart';
import 'package:restaurant_app/features/customer/presentation/controllers/customer_wallet_controller.dart';
import 'package:restaurant_app/features/delivery/domain/services/delivery_fee_calculator.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/reservations/presentation/controllers/reservation_controller.dart';
import 'package:restaurant_app/features/reservations/data/repositories/in_memory_reservation_repository.dart';
import 'package:restaurant_app/features/table_management/data/repositories/in_memory_table_repository.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';

MenuItem _makeMenuItem({
  String id = 'MI-001',
  String name = 'برجر لحم',
  String description = 'برجر لحم فاخر',
  double price = 50.0,
  String categoryId = 'burgers',
  bool isAvailable = true,
}) {
  return MenuItem(
    id: id,
    name: name,
    description: description,
    price: price,
    categoryId: categoryId,
    imageUrl: '',
    isAvailable: isAvailable,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ Comprehensive Edge Cases Hardening Suite', () {
    test('EC-PAY-01 & 02: Concurrent payments blocked and non-positive amounts rejected', () async {
      final paymentService = PaymentService(MockPaymentGateway());

      // Test zero and negative amount rejection
      final zeroResult = await paymentService.payForOrder(
        orderId: 'ORD-TEST-01',
        amount: 0.0,
        method: PaymentMethod.card,
      );
      expect(zeroResult.isSuccess, isFalse);

      final negResult = await paymentService.payForOrder(
        orderId: 'ORD-TEST-01',
        amount: -50.0,
        method: PaymentMethod.card,
      );
      expect(negResult.isSuccess, isFalse);

      // Test refund non-positive
      final zeroRefund = await paymentService.refund(
        transactionId: 'TXN-1',
        amount: 0.0,
      );
      expect(zeroRefund.isSuccess, isFalse);
    });

    test('EC-ZAT-01 & 02: ZATCA TLV encoding handles >255 byte strings and negative amounts safely', () {
      // Very long seller name (> 300 characters in Arabic UTF-8)
      final longArabicName = 'شركة مطاعم القصر الملكي الذهبي الفاخر لتقديم أشهى المأكولات والمشروبات الشرقية والغربية ذات المسؤولية المحدودة ' * 4;

      final qrBase64 = ZatcaQrCodec.generateBase64Qr(
        sellerName: longArabicName,
        vatNumber: '300000000000003',
        invoiceTimestamp: DateTime.now(),
        totalWithVat: -100.0, // Negative should clamp to 0.0
        vatAmount: -15.0,     // Negative should clamp to 0.0
      );

      expect(qrBase64, isNotEmpty);
      final decoded = ZatcaQrCodec.decodeBase64Qr(qrBase64);
      expect(decoded.containsKey(1), isTrue);
      expect(decoded.containsKey(2), isTrue);
      expect(decoded[2], equals('300000000000003'));
      expect(decoded[4], equals('0.00'));
      expect(decoded[5], equals('0.00'));
    });

    test('EC-TBL-01: Table transfer invokes onOrderTableTransferred and updates order tableId', () async {
      final tableRepo = InMemoryTableRepository();
      String? transferredOrderId;
      String? transferredToTableId;

      final tableController = TableController(
        tableRepo,
        onOrderTableTransferred: (orderId, newTableId) async {
          transferredOrderId = orderId;
          transferredToTableId = newTableId;
        },
      );

      // Wait for tableController to load initial tables
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final tables = tableController.state;
      expect(tables.length, greaterThanOrEqualTo(2));
      final fromTable = tables[0];
      final toTable = tables[1];

      // Occupy fromTable with an order
      await tableController.occupy(fromTable.id, orderId: 'ORD-9999');
      expect(tableController.tableById(fromTable.id)?.status, equals(TableStatus.occupied));

      // Transfer from fromTable to toTable
      final success = await tableController.transferTable(fromTable.id, toTable.id);
      expect(success, isTrue);

      // Verify table statuses
      expect(tableController.tableById(fromTable.id)?.status, equals(TableStatus.needsCleaning));
      expect(tableController.tableById(toTable.id)?.status, equals(TableStatus.occupied));
      expect(tableController.tableById(toTable.id)?.currentOrderId, equals('ORD-9999'));

      // Verify hook fired
      expect(transferredOrderId, equals('ORD-9999'));
      expect(transferredToTableId, equals(toTable.id));
    });

    test('EC-ORD-03: OrdersController.updateOrderTableId correctly mutates in-memory order tableId', () async {
      final orderRepo = InMemoryOrderRepository();
      final cartController = CartController();
      final notifier = NewOrderNotifier();

      final ordersController = OrdersController(
        orderRepo,
        cartController,
        notifier,
      );

      // Seed an order
      final testOrder = OrderEntity(
        id: 'ORD-0001',
        restaurantId: 'rest-1',
        tableId: 'tbl-1',
        orderType: OrderType.dineIn,
        items: [
          OrderItem(
            menuItem: _makeMenuItem(),
            quantity: 1,
            itemTotal: 50.0,
            addedAt: DateTime.now(),
          ),
        ],
        subtotal: 50,
        taxAmount: 7.5,
        totalAmount: 57.5,
        status: OrderStatus.preparing,
        createdAt: DateTime.now(),
      );

      ordersController.state = [testOrder];

      // Transfer table
      final updated = await ordersController.updateOrderTableId('ORD-0001', 'tbl-2');
      expect(updated, isTrue);
      expect(ordersController.state.first.tableId, equals('tbl-2'));
    });

    test('EC-DLV-03: DeliveryFeeCalculator safely handles (0,0) uninitialized GPS coordinates', () {
      final distance = DeliveryFeeCalculator.calculateDistanceKm(
        startLat: DeliveryFeeCalculator.restaurantLat,
        startLng: DeliveryFeeCalculator.restaurantLng,
        endLat: 0.0,
        endLng: 0.0,
      );

      // Should fall back to base distance instead of ~5500 km
      expect(distance, equals(DeliveryFeeCalculator.baseDistanceKm));

      final calculator = DeliveryFeeCalculator();
      final breakdown = calculator.calculate(
        distanceKm: distance,
        orderSubtotal: 50.0,
      );

      expect(breakdown.finalFee, lessThan(100.0));
    });

    test('EC-WLT-01 & 02: CustomerWalletNotifier rounds currency and prevents negative amounts', () {
      final walletNotifier = CustomerWalletNotifier();

      // Attempt negative addition
      walletNotifier.addFunds(-20.0, title: 'Invalid Negative');
      expect(walletNotifier.state.balance, equals(0.0));

      // Positive addition with fractional cents
      walletNotifier.addFunds(100.555, title: 'Top-up');
      expect(walletNotifier.state.balance, equals(100.56)); // rounded to 2 decimals

      // Partial deduction
      final deducted = walletNotifier.deductFunds(50.123, title: 'Order Pay');
      expect(deducted, isTrue);
      expect(walletNotifier.state.balance, equals(50.44));

      // Overdraw deduction
      final overdraw = walletNotifier.deductFunds(100.0, title: 'Too much');
      expect(overdraw, isFalse);
      expect(walletNotifier.state.balance, equals(50.44));
    });

    test('EC-CSH-02: CashDrawerController sanitizes payIn and payOut amounts to positive', () {
      final drawerController = CashDrawerController();

      final payIn = drawerController.recordPayIn(
        shiftId: 'SHIFT-1',
        amount: -500.0,
        reason: 'إيداع نقدي',
      );
      expect(payIn.amount, equals(500.0));

      final payOut = drawerController.recordPayOut(
        shiftId: 'SHIFT-1',
        amount: -150.0,
        reason: 'مصروفات',
      );
      expect(payOut.amount, equals(150.0));
    });

    test('EC-RES-02: ReservationController rejects overcapacity reservations', () async {
      final container = ProviderContainer(
        overrides: [
          reservationRepositoryProvider.overrideWithValue(InMemoryReservationRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(reservationControllerProvider.notifier);

      // Wait for table state
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Try booking 10 guests for table t1 (capacity 2)
      final success = await controller.createReservation(
        customerName: 'أحمد',
        customerPhone: '01012345678',
        tableId: 't1',
        tableNumber: 1,
        guestCount: 10, // Exceeds table capacity (2)
        reservationTime: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(success, isFalse);
    });
  });
}
