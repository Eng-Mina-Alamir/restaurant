import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/payment/payment_service.dart';
import 'package:restaurant_app/core/printing/ticket_printer_service.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';
import 'package:restaurant_app/features/loyalty/presentation/controllers/loyalty_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/data/services/report_export_service.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/ratings/domain/entities/rating_entity.dart';
import 'package:restaurant_app/features/ratings/presentation/controllers/rating_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import '../helpers/test_container.dart';

void main() {
  group('Timeline 8: Grand Symphony Multi-Role Synchronized Journey Test', () {
    const lambChops = MenuItem(
      id: 'item-sym-1',
      categoryId: 'cat-grill',
      name: 'ريش لحم ضأن مشوية فاخرة',
      description: 'متبلة بالأعشاب والبهارات الشرقية',
      price: 95.0,
      isAvailable: true,
    );

    const saffronRice = MenuItem(
      id: 'item-sym-2',
      categoryId: 'cat-sides',
      name: 'أرز بالزعفران والمكسرات',
      description: 'أرز بسمتي فاخر',
      price: 25.0,
      isAvailable: true,
    );

    const symphonyCoupon = CouponEntity(
      id: 'cpn-sym-1',
      code: 'SYMPHONY15',
      title: 'خصم الملحمة 15%',
      discountType: CouponDiscountType.percentage,
      discountValue: 15.0,
      minOrderAmount: 100.0,
    );

    test('Grand Symphony: Manager opens floor -> Customer scans & orders -> Kitchen prepares & prints -> Waiter serves -> Customer pays & rates -> Manager gets real-time analytics', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      final tableNotifier = container.read(tableControllerProvider.notifier);
      await tableNotifier.addTable(tableNumber: 1, capacity: 4);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final initialTables = container.read(tableControllerProvider);
      expect(initialTables, isNotEmpty);

      // ── Phase 1: Floor & Table Ready ──────────────────────────────────────
      final targetTable = initialTables.firstWhere((t) => t.tableNumber == 1);
      expect(targetTable.status, equals(TableStatus.available));

      // ── Phase 2: Customer arrives, scans QR, adds items & coupon ──────────
      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.setTableId(targetTable.id);

      cartNotifier.addItem(const CartItem(menuItem: lambChops, quantity: 2)); // 95 * 2 = 190.0
      cartNotifier.addItem(const CartItem(menuItem: saffronRice, quantity: 2)); // 25 * 2 = 50.0

      // Subtotal = 240.0 SAR
      expect(cartNotifier.totals.subtotal, equals(240.0));

      final discount = symphonyCoupon.calculateDiscount(cartNotifier.totals.subtotal);
      expect(discount, closeTo(240.0 * 0.15, 0.01)); // 36.0 SAR

      // Customer places the order
      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final order = await ordersNotifier.placeOrderForTable(targetTable.id);

      expect(order, isNotNull);
      expect(order!.tableId, equals(targetTable.id));
      expect(order.status, equals(OrderStatus.pending));

      // Waiter links active table to occupied
      await tableNotifier.occupy(targetTable.id, orderId: order.id);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      var currentTable = container.read(tableControllerProvider).firstWhere((t) => t.id == targetTable.id);
      expect(currentTable.status, equals(TableStatus.occupied));

      // ── Phase 3: Kitchen KDS receives order, starts cooking & prints ticket
      await ordersNotifier.updateStatus(order.id, OrderStatus.preparing);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      var currentOrder = container.read(ordersControllerProvider).firstWhere((o) => o.id == order.id);
      expect(currentOrder.status, equals(OrderStatus.preparing));

      final printer = TicketPrinterService();
      final ticketText = printer.generateTicketText(currentOrder, tableDisplay: 'طاولة ${targetTable.tableNumber}');
      expect(ticketText, contains('ريش لحم ضأن مشوية فاخرة'));

      // Kitchen finishes and marks READY
      await ordersNotifier.updateStatus(order.id, OrderStatus.ready);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      currentOrder = container.read(ordersControllerProvider).firstWhere((o) => o.id == order.id);
      expect(currentOrder.status, equals(OrderStatus.ready));

      // ── Phase 4: Waiter serves Table ──────────────────────────────────────
      await ordersNotifier.updateStatus(order.id, OrderStatus.served);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      currentOrder = container.read(ordersControllerProvider).firstWhere((o) => o.id == order.id);
      expect(currentOrder.status, equals(OrderStatus.served));

      // ── Phase 5: Payment, Rating & Loyalty points ─────────────────────────
      final paymentService = PaymentService();
      final payment = await paymentService.payForOrder(
        orderId: order.id,
        amount: currentOrder.totalAmount,
        method: PaymentMethod.card,
      );
      expect(payment.isSuccess, isTrue);

      await ordersNotifier.updateStatus(order.id, OrderStatus.completed);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      currentOrder = container.read(ordersControllerProvider).firstWhere((o) => o.id == order.id);
      expect(currentOrder.status, equals(OrderStatus.completed));

      // Customer earns loyalty points
      final loyaltyNotifier = container.read(loyaltyControllerProvider.notifier);
      await loyaltyNotifier.earnPoints(
        orderTotal: currentOrder.totalAmount,
        orderId: currentOrder.id,
      );
      expect(container.read(loyaltyControllerProvider).value?.currentPoints, isNotNull);

      // Customer submits 5-star review
      final ratingRepo = container.read(ratingRepositoryProvider);
      await ratingRepo.submitRating(
        RatingEntity(
          id: 'rate-sym-01',
          targetId: lambChops.id,
          targetType: RatingTargetType.menuItem,
          userId: 'CUST-VIP-77',
          userName: 'سلطان القحطاني',
          score: 5.0,
          comment: 'تجربة ملكية من الدرجة الأولى وطعم لا يقاوم!',
          createdAt: DateTime.now(),
        ),
      );
      final avgResult = await ratingRepo.getAverageScore(lambChops.id);
      expect(avgResult.when(onLeft: (_) => 0.0, onRight: (s) => s), equals(5.0));

      // ── Phase 6: Waiter releases table for cleaning then marks available ───
      await tableNotifier.release(targetTable.id, needsCleaning: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      currentTable = container.read(tableControllerProvider).firstWhere((t) => t.id == targetTable.id);
      expect(currentTable.status, equals(TableStatus.needsCleaning));

      await tableNotifier.release(targetTable.id, needsCleaning: false);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      currentTable = container.read(tableControllerProvider).firstWhere((t) => t.id == targetTable.id);
      expect(currentTable.status, equals(TableStatus.available));

      // ── Phase 7: Manager exports daily sales and sees the completed order ──
      const exportService = ReportExportService();
      final allCompleted = container.read(ordersControllerProvider).where((o) => o.status == OrderStatus.completed).toList();
      final csvReport = exportService.generateInvoicesCsv(allCompleted);
      expect(csvReport, contains(order.id));
      expect(csvReport, contains('مكتمل'));
    });
  });
}
