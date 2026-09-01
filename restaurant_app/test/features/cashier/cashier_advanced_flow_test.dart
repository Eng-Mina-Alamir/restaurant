import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/cashier/presentation/widgets/cash_drawer_in_out_dialog.dart';
import 'package:restaurant_app/features/cashier/presentation/widgets/cashier_discount_dialog.dart';
import 'package:restaurant_app/features/cashier/presentation/widgets/customer_loyalty_lookup_sheet.dart';
import 'package:restaurant_app/features/cashier/presentation/widgets/held_orders_modal.dart';
import 'package:restaurant_app/features/cashier/presentation/widgets/order_refund_dialog.dart';
import 'package:restaurant_app/features/cashier/presentation/widgets/quick_tender_sheet.dart';
import 'package:restaurant_app/features/cashier/presentation/widgets/split_tender_dialog.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  const dummyItem = MenuItem(
    id: 'item-1',
    name: 'شاورما دجاج سبيشال',
    description: 'شاورما دجاج عربية مع صوص الثومية',
    price: 120.0,
    categoryId: 'shawarma',
  );

  final dummyOrder = OrderEntity(
    id: 'ORD-999',
    restaurantId: 'rest-1',
    orderType: OrderType.takeaway,
    items: [
      OrderItem(
        menuItem: dummyItem,
        quantity: 2,
        addedAt: DateTime.now(),
      ),
    ],
    status: OrderStatus.completed,
    subtotal: 240.0,
    taxAmount: 33.6,
    discountAmount: 0.0,
    totalAmount: 273.6,
    createdAt: DateTime.now(),
    paymentMethod: PaymentMethod.cash,
  );

  Widget createTestWidget(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('Cashier Advanced Flow & UI Widgets Tests', () {
    testWidgets('QuickTenderSheet renders change calculator and handles cash bill selection',
        (tester) async {
      double? receivedTender;

      await tester.pumpWidget(
        createTestWidget(
          QuickTenderSheet(
            totalAmountDue: 350.0,
            onCompletePayment: (val) => receivedTender = val,
          ),
        ),
      );

      expect(find.text('حاسبة النقدية والباقي (Cash Tender)'), findsOneWidget);
      expect(find.textContaining('350'), findsWidgets);

      // Verify preset bill chip selection
      final bill500Finder = find.widgetWithText(ChoiceChip, '500.00 ج.م');
      expect(bill500Finder, findsOneWidget);

      await tester.tap(bill500Finder);
      await tester.pumpAndSettle();

      // Change due for 500 - 350 = 150
      expect(find.textContaining('150'), findsWidgets);

      // Tap confirm button
      final confirmBtn = find.text('تأكيد الدفع وفتح الدرج 💵');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pump();

      expect(receivedTender, equals(500.0));
    });

    testWidgets('HeldOrdersModal parks and displays held orders', (tester) async {
      final container = ProviderContainer();
      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.addItem(const CartItem(menuItem: dummyItem, quantity: 2));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: HeldOrdersModal(),
            ),
          ),
        ),
      );

      expect(find.text('الطلبات المعلقة (Held / Parked Orders)'), findsOneWidget);
      expect(find.text('تعليق السلة الحالية'), findsOneWidget);

      // Tap park active cart
      await tester.tap(find.text('تعليق السلة الحالية'));
      await tester.pumpAndSettle();

      // Active cart should be cleared and held order card shown
      expect(container.read(cartControllerProvider).isEmpty, isTrue);
      expect(find.text('استدعاء للسلة'), findsOneWidget);
    });

    testWidgets('CashDrawerInOutDialog accepts pay-in / pay-out entries', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CashDrawerInOutDialog(shiftId: 'shift-1'),
        ),
      );

      expect(find.text('حركات الدرج والمصروفات النثرية'), findsOneWidget);
      expect(find.text('إيداع نقدية (Pay-In)'), findsOneWidget);
      expect(find.text('سحب مصروفات (Pay-Out)'), findsOneWidget);

      // Switch to Pay-Out tab
      await tester.tap(find.text('سحب مصروفات (Pay-Out)'));
      await tester.pumpAndSettle();

      expect(find.text('مشتريات طارئة للمطبخ / خضار'), findsOneWidget);
    });

    testWidgets('CashierDiscountDialog lists preset discounts with manager PIN indications',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CashierDiscountDialog(orderSubtotal: 500.0),
        ),
      );

      expect(find.text('تطبيق خصم أو ضيافة إدارة'), findsOneWidget);
      expect(find.text('خصم ترويجي 10%'), findsOneWidget);
      expect(find.text('ضيافة إدارة 100% (Complimentary)'), findsOneWidget);
      expect(find.text('PIN المدير'), findsWidgets);
    });

    testWidgets('SplitTenderDialog tracks multi-tender shares correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SplitTenderDialog(
            orderId: 'ORD-101',
            totalAmountDue: 400.0,
          ),
        ),
      );

      expect(find.text('الدفع المجزأ (Split Tender)'), findsOneWidget);
      expect(find.text('المتبقي للتحصيل:'), findsOneWidget);

      // Record first payment share (400 default)
      await tester.tap(find.text('تسجيل الدفعة'));
      await tester.pumpAndSettle();

      expect(find.text('إتمام سداد الفاتورة بنجاح'), findsOneWidget);
    });

    testWidgets('CustomerLoyaltyLookupSheet searches and displays customer profile', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomerLoyaltyLookupSheet(orderTotal: 300.0),
        ),
      );

      expect(find.text('برنامج الولاء ونقاط العملاء (Loyalty POS)'), findsOneWidget);

      // Enter phone number
      await tester.enterText(find.byType(TextField), '01012345678');
      await tester.pumpAndSettle();

      expect(find.text('أحمد محمود العطار'), findsOneWidget);
      expect(find.text('450 نقطة'), findsOneWidget);
    });

    testWidgets('OrderRefundDialog renders refund types and reasons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          OrderRefundDialog(order: dummyOrder),
        ),
      );

      expect(find.textContaining('استرجاع فاتورة'), findsOneWidget);
      expect(find.text('استرجاع كامل الفاتورة'), findsOneWidget);
      expect(find.text('طلب موافقة المدير وتأكيد المرتجع'), findsOneWidget);
    });
  });
}
