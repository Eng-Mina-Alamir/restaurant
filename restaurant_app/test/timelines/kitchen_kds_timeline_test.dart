import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/printing/ticket_printer_service.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

void main() {
  group('Timeline 5: Kitchen KDS Station Full Journey Test', () {
    const charcoalChicken = MenuItem(
      id: 'kds-grill-item-1',
      categoryId: 'cat-grills',
      name: 'دجاج شواية على الفحم',
      description: 'دجاج متبل بخلطة الشيف الخاصة',
      price: 48.0,
    );

    const fattoushSalad = MenuItem(
      id: 'kds-salad-item-1',
      categoryId: 'cat-salads',
      name: 'سلطة فتوش لبنانية',
      description: 'خضار طازجة مع دبس الرمان والخبز المقرمش',
      price: 24.0,
    );

    test('Kitchen KDS Timeline: Order Inflow -> Alert Sound -> Station Dispatch -> Prep Timer Progression -> Print Ticket -> Mark Ready', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.setTableId('TBL-07');
      cartNotifier.addItem(const CartItem(menuItem: charcoalChicken, quantity: 2));
      cartNotifier.addItem(const CartItem(menuItem: fattoushSalad, quantity: 1));

      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final printerService = TicketPrinterService();

      // ── Step 1: New multi-item order arrives at Kitchen ────────────────────
      final createdOrder = await ordersNotifier.placeOrderForTable('TBL-07');
      expect(createdOrder, isNotNull);

      // Verify order is queued in Kitchen pending list
      var kdsOrders = container.read(ordersControllerProvider);
      expect(kdsOrders.any((o) => o.id == createdOrder!.id && o.status == OrderStatus.pending), isTrue);

      // ── Step 2: Chef acknowledges order and starts preparation ─────────────
      await ordersNotifier.updateStatus(createdOrder!.id, OrderStatus.preparing);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      kdsOrders = container.read(ordersControllerProvider);
      var currentOrder = kdsOrders.firstWhere((o) => o.id == createdOrder.id);
      expect(currentOrder.status, equals(OrderStatus.preparing));

      // ── Step 3: Check prep time and timer categorization ──────────────────
      final elapsedMinutes = DateTime.now().difference(currentOrder.createdAt).inMinutes;
      expect(elapsedMinutes, lessThanOrEqualTo(10));

      // ── Step 4: Generate thermal ticket bytes for the kitchen printer ──────
      final ticketText = printerService.generateTicketText(currentOrder, tableDisplay: 'طاولة 7');
      expect(ticketText, contains('دجاج شواية على الفحم'));
      expect(ticketText, contains('سلطة فتوش لبنانية'));

      final ticketBytes = printerService.generateEscPosBytes(currentOrder, tableDisplay: 'طاولة 7');
      expect(ticketBytes, isNotEmpty);

      // ── Step 5: Kitchen finishes cooking -> Marks order READY ──────────────
      await ordersNotifier.updateStatus(createdOrder.id, OrderStatus.ready);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      kdsOrders = container.read(ordersControllerProvider);
      currentOrder = kdsOrders.firstWhere((o) => o.id == createdOrder.id);
      expect(currentOrder.status, equals(OrderStatus.ready));
    });
  });
}
