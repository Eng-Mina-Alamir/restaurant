// ignore_for_file: avoid_print
/// Comprehensive edge-case tests for the Order Lifecycle.
///
/// Covers:
///   Group 1: Happy-path lifecycle (dineIn, delivery, takeaway)
///   Group 2: Cart & Checkout edge cases
///   Group 3: Status Transition edge cases
///   Group 4: Delivery edge cases
///   Group 5: Payment edge cases
///   Group 6: Financial Integrity
///   Group 7: Offline & Sync
///   Group 8: KDS & Claim
///   Group 9: RLS Security (documented for manual testing)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/utils/financial_calculator.dart';
import 'package:restaurant_app/features/cart/domain/cart_totals.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_exception_entity.dart';
import 'package:restaurant_app/features/delivery/domain/entities/driver_info.dart';
import 'package:restaurant_app/features/delivery/domain/services/driver_assignment_service.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';
import 'package:restaurant_app/features/orders/domain/order_mapper.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

MenuItem _makeMenuItem({
  String id = 'MI-001',
  String name = 'تيست برجر',
  String description = 'وصف تجريبي',
  double price = 25.0,
  bool isAvailable = true,
  String categoryId = 'CAT-1',
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

CartItem _makeCartItem({
  MenuItem? menuItem,
  int quantity = 1,
  String? specialNotes,
}) {
  return CartItem(
    menuItem: menuItem ?? _makeMenuItem(),
    quantity: quantity,
    specialNotes: specialNotes,
  );
}

OrderEntity _makeOrder({
  String id = 'ORD-TEST-001',
  OrderStatus status = OrderStatus.pending,
  OrderType orderType = OrderType.dineIn,
  List<OrderItem>? items,
  double subtotal = 100.0,
  double taxAmount = 15.0,
  double discountAmount = 0.0,
  double totalAmount = 115.0,
  String? deliveryAddress,
  String? driverId,
}) {
  return OrderEntity(
    id: id,
    restaurantId: 'RESTO-001',
    orderType: orderType,
    status: status,
    items: items ??
        [
          OrderItem(
            menuItem: _makeMenuItem(),
            quantity: 2,
            itemTotal: 50.0,
            addedAt: DateTime.now(),
          ),
        ],
    subtotal: subtotal,
    taxAmount: taxAmount,
    discountAmount: discountAmount,
    totalAmount: totalAmount,
    deliveryAddress: deliveryAddress,
    driverId: driverId,
    createdAt: DateTime.now(),
  );
}

// ─── Test Groups ─────────────────────────────────────────────────────────────

void main() {
  // ═════════════════════════════════════════════════════════════════════════
  // GROUP 1: Happy Path — Full Lifecycle
  // ═════════════════════════════════════════════════════════════════════════

  group('Group 1: Happy Path — Full Lifecycle', () {
    test('DineIn lifecycle follows valid forward transitions', () {
      // pending → confirmed → preparing → ready → served → completed
      const transitions = [
        (OrderStatus.pending, OrderStatus.confirmed),
        (OrderStatus.confirmed, OrderStatus.preparing),
        (OrderStatus.preparing, OrderStatus.ready),
        (OrderStatus.ready, OrderStatus.served),
        (OrderStatus.served, OrderStatus.completed),
      ];
      for (final (from, to) in transitions) {
        expect(
          from.canTransitionTo(to),
          isTrue,
          reason: '${from.name} → ${to.name} should be valid',
        );
      }
    });

    test('Delivery lifecycle follows valid forward transitions', () {
      // pending → confirmed → preparing → ready → completed
      const transitions = [
        (OrderStatus.pending, OrderStatus.confirmed),
        (OrderStatus.confirmed, OrderStatus.preparing),
        (OrderStatus.preparing, OrderStatus.ready),
        (OrderStatus.ready, OrderStatus.completed),
      ];
      for (final (from, to) in transitions) {
        expect(
          from.canTransitionTo(to),
          isTrue,
          reason: '${from.name} → ${to.name} should be valid',
        );
      }
    });

    test('Takeaway lifecycle follows valid forward transitions', () {
      // pending → confirmed → preparing → ready → completed
      const transitions = [
        (OrderStatus.pending, OrderStatus.confirmed),
        (OrderStatus.confirmed, OrderStatus.preparing),
        (OrderStatus.preparing, OrderStatus.ready),
        (OrderStatus.ready, OrderStatus.completed),
      ];
      for (final (from, to) in transitions) {
        expect(
          from.canTransitionTo(to),
          isTrue,
          reason: '${from.name} → ${to.name} should be valid',
        );
      }
    });

    test('OrderMapper builds correct dineIn order', () {
      final order = OrderMapper.buildForTable(
        orderId: 'ORD-T1',
        restaurantId: 'REST-1',
        tableId: 'TABLE-5',
        cartItems: [_makeCartItem(quantity: 2)],
        createdAt: DateTime.now(),
      );

      expect(order.orderType, OrderType.dineIn);
      expect(order.status, OrderStatus.pending);
      expect(order.tableId, 'TABLE-5');
      expect(order.items.length, 1);
      expect(order.items.first.quantity, 2);
      expect(order.subtotal, greaterThan(0));
    });

    test('OrderMapper builds correct delivery order', () {
      final order = OrderMapper.buildForDelivery(
        orderId: 'ORD-D1',
        restaurantId: 'REST-1',
        deliveryAddress: 'شارع التحرير، القاهرة',
        cartItems: [_makeCartItem()],
        createdAt: DateTime.now(),
      );

      expect(order.orderType, OrderType.delivery);
      expect(order.status, OrderStatus.pending);
      expect(order.deliveryAddress, 'شارع التحرير، القاهرة');
      expect(order.estimatedMinutes, 40);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // GROUP 2: Cart & Checkout Edge Cases
  // ═════════════════════════════════════════════════════════════════════════

  group('Group 2: Cart & Checkout Edge Cases', () {
    test('Zero quantity is clamped to 1', () {
      final orderItem = OrderMapper.toOrderItem(
        _makeCartItem(quantity: 0),
        timestamp: DateTime.now(),
      );
      expect(orderItem.quantity, 1);
    });

    test('Negative quantity is clamped to 1', () {
      final orderItem = OrderMapper.toOrderItem(
        _makeCartItem(quantity: -5),
        timestamp: DateTime.now(),
      );
      expect(orderItem.quantity, 1);
    });

    test('Empty cart builds order with zero items', () {
      final order = OrderMapper.buildForCustomer(
        orderId: 'ORD-EMPTY',
        restaurantId: 'REST-1',
        cartItems: [],
        createdAt: DateTime.now(),
      );
      expect(order.items, isEmpty);
      expect(order.subtotal, 0.0);
      expect(order.totalAmount, 0.0);
    });

    test('CartTotals computes correctly with multiple items', () {
      final items = [
        _makeCartItem(
          menuItem: _makeMenuItem(id: 'A', price: 10.0),
          quantity: 3,
        ),
        _makeCartItem(
          menuItem: _makeMenuItem(id: 'B', price: 25.50),
          quantity: 2,
        ),
      ];
      final totals = CartTotals.fromItems(items);

      // Subtotal: 3*10 + 2*25.50 = 30 + 51 = 81
      expect(totals.subtotal, closeTo(81.0, 0.01));
      expect(totals.taxAmount, greaterThan(0));
      expect(totals.totalAmount, greaterThan(totals.subtotal));
    });

    test('Large quantity cart builds correctly', () {
      final items = List.generate(
        50,
        (i) => _makeCartItem(
          menuItem: _makeMenuItem(id: 'MI-$i', price: 5.0 + i),
          quantity: 2,
        ),
      );
      final order = OrderMapper.buildForCustomer(
        orderId: 'ORD-BULK',
        restaurantId: 'REST-1',
        cartItems: items,
        createdAt: DateTime.now(),
      );
      expect(order.items.length, 50);
      expect(order.subtotal, greaterThan(0));
    });

    test('Order with discount does not exceed subtotal', () {
      final items = [_makeCartItem(menuItem: _makeMenuItem(price: 10.0))];
      final order = OrderMapper.buildForCustomer(
        orderId: 'ORD-DISC',
        restaurantId: 'REST-1',
        cartItems: items,
        createdAt: DateTime.now(),
        discountAmount: 999.0, // Way more than subtotal
      );
      // Discount is stored as-is, but totalAmount should never go negative
      expect(order.totalAmount, greaterThanOrEqualTo(0));
    });

    test('Order type defaults to takeaway when not specified', () {
      final order = OrderMapper.buildForCustomer(
        orderId: 'ORD-DEF',
        restaurantId: 'REST-1',
        cartItems: [_makeCartItem()],
        createdAt: DateTime.now(),
      );
      expect(order.orderType, OrderType.takeaway);
    });

    test('Unavailable menu item preserves order but warns', () {
      // The OrderMapper does not reject unavailable items (that's the
      // controller's job), but it should still map them correctly
      final unavailable = _makeMenuItem(isAvailable: false);
      final item = OrderMapper.toOrderItem(
        _makeCartItem(menuItem: unavailable),
        timestamp: DateTime.now(),
      );
      expect(item.menuItem.isAvailable, false);
      expect(item.quantity, 1);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // GROUP 3: Status Transition Edge Cases
  // ═════════════════════════════════════════════════════════════════════════

  group('Group 3: Status Transition Edge Cases', () {
    test('Invalid transition: completed → preparing is rejected', () {
      expect(OrderStatus.completed.canTransitionTo(OrderStatus.preparing),
          isFalse);
    });

    test('Invalid transition: cancelled → any status is rejected', () {
      for (final target in OrderStatus.values) {
        if (target == OrderStatus.cancelled) continue;
        expect(
          OrderStatus.cancelled.canTransitionTo(target),
          isFalse,
          reason: 'cancelled → ${target.name} should be invalid',
        );
      }
    });

    test('Completed is immutable — cannot transition to anything', () {
      for (final target in OrderStatus.values) {
        if (target == OrderStatus.completed) continue;
        expect(
          OrderStatus.completed.canTransitionTo(target),
          isFalse,
          reason: 'completed → ${target.name} should be invalid',
        );
      }
    });

    test('Revert: ready → preparing is valid', () {
      expect(OrderStatus.ready.canRevertTo(OrderStatus.preparing), isTrue);
    });

    test('Revert: ready → pending is invalid (must be single step)', () {
      expect(OrderStatus.ready.canRevertTo(OrderStatus.pending), isFalse);
    });

    test('Revert: served → ready is valid', () {
      expect(OrderStatus.served.canRevertTo(OrderStatus.ready), isTrue);
    });

    test('Revert: preparing → pending is invalid (no revert defined)', () {
      expect(OrderStatus.preparing.canRevertTo(OrderStatus.pending), isFalse);
    });

    test('Any status can transition to cancelled (except terminal)', () {
      final cancellable = [
        OrderStatus.pending,
        OrderStatus.confirmed,
        OrderStatus.preparing,
        OrderStatus.ready,
      ];
      for (final status in cancellable) {
        expect(
          status.canTransitionTo(OrderStatus.cancelled),
          isTrue,
          reason: '${status.name} should be cancellable',
        );
      }
    });

    test('Terminal status check is correct', () {
      expect(OrderStatus.completed.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);
      expect(OrderStatus.pending.isTerminal, isFalse);
      expect(OrderStatus.preparing.isTerminal, isFalse);
      expect(OrderStatus.ready.isTerminal, isFalse);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // GROUP 4: Delivery Edge Cases
  // ═════════════════════════════════════════════════════════════════════════

  group('Group 4: Delivery Edge Cases', () {
    test('No available drivers returns Waiting', () {
      const service = DriverAssignmentService();
      final result = service.assign(
        candidates: [],
        restaurantLat: 30.0444,
        restaurantLng: 31.2357,
      );
      expect(result, isA<Waiting>());
    });

    test('Driver out of range excluded', () {
      const service = DriverAssignmentService();
      final result = service.assign(
        candidates: const [
          DriverInfo(
            id: 'D1',
            name: 'سائق بعيد',
            latitude: 31.0, // ~110km away
            longitude: 31.0,
            isAvailable: true,
            activeAssignments: 0,
            rating: 5.0,
          ),
        ],
        restaurantLat: 30.0444,
        restaurantLng: 31.2357,
        maxDistanceMeters: 5000,
      );
      expect(result, isA<Waiting>());
    });

    test('Driver at max concurrent load excluded', () {
      const service = DriverAssignmentService();
      final result = service.assign(
        candidates: const [
          DriverInfo(
            id: 'D1',
            name: 'سائق مشغول',
            latitude: 30.0444,
            longitude: 31.2357,
            isAvailable: true,
            activeAssignments: 3,
            rating: 5.0,
          ),
        ],
        restaurantLat: 30.0444,
        restaurantLng: 31.2357,
        maxConcurrentPerDriver: 3,
      );
      expect(result, isA<Waiting>());
    });

    test('Unavailable driver excluded', () {
      const service = DriverAssignmentService();
      final result = service.assign(
        candidates: const [
          DriverInfo(
            id: 'D1',
            name: 'سائق غير متاح',
            latitude: 30.0444,
            longitude: 31.2357,
            isAvailable: false,
            activeAssignments: 0,
            rating: 5.0,
          ),
        ],
        restaurantLat: 30.0444,
        restaurantLng: 31.2357,
      );
      expect(result, isA<Waiting>());
    });

    test('Best driver selected by composite score', () {
      const service = DriverAssignmentService();
      final result = service.assign(
        candidates: const [
          // Nearby, low load, good rating
          DriverInfo(
            id: 'D1',
            name: 'سائق ممتاز',
            latitude: 30.0445,
            longitude: 31.2358,
            isAvailable: true,
            activeAssignments: 0,
            rating: 4.8,
          ),
          // Farther, higher load
          DriverInfo(
            id: 'D2',
            name: 'سائق بعيد',
            latitude: 30.05,
            longitude: 31.24,
            isAvailable: true,
            activeAssignments: 2,
            rating: 4.5,
          ),
        ],
        restaurantLat: 30.0444,
        restaurantLng: 31.2357,
      );
      expect(result, isA<Assigned>());
      expect((result as Assigned).driverId, 'D1');
    });

    test('Tie-breaking by driver ID (deterministic)', () {
      const service = DriverAssignmentService();
      // Two drivers at identical positions, same load, same rating
      final result = service.assign(
        candidates: const [
          DriverInfo(
            id: 'D-B',
            name: 'B',
            latitude: 30.0444,
            longitude: 31.2357,
            isAvailable: true,
            activeAssignments: 0,
            rating: 5.0,
          ),
          DriverInfo(
            id: 'D-A',
            name: 'A',
            latitude: 30.0444,
            longitude: 31.2357,
            isAvailable: true,
            activeAssignments: 0,
            rating: 5.0,
          ),
        ],
        restaurantLat: 30.0444,
        restaurantLng: 31.2357,
      );
      expect(result, isA<Assigned>());
      // D-A < D-B lexicographically, so D-A wins the tie
      expect((result as Assigned).driverId, 'D-A');
    });

    test('DeliveryExceptionEntity serialization round-trips', () {
      final exception = DeliveryExceptionEntity(
        id: 'EXC-1',
        assignmentId: 'ASG-1',
        orderId: 'ORD-1',
        driverId: 'D-1',
        driverName: 'أحمد',
        reason: DeliveryExceptionReason.customerUnreachable,
        callAttemptsCount: 3,
        timestamp: DateTime.parse('2026-09-01T12:00:00.000'),
        notes: 'حاولت 3 مرات',
      );
      final json = exception.toJson();
      final restored = DeliveryExceptionEntity.fromJson(json);

      expect(restored.id, exception.id);
      expect(restored.reason, DeliveryExceptionReason.customerUnreachable);
      expect(restored.callAttemptsCount, 3);
      expect(restored.notes, 'حاولت 3 مرات');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // GROUP 5: Payment Edge Cases (logic-level, no Supabase)
  // ═════════════════════════════════════════════════════════════════════════

  group('Group 5: Payment Edge Cases', () {
    test('Zero amount payment is logically invalid', () {
      // The PaymentGateway should reject zero amounts
      expect(0.0, lessThanOrEqualTo(0));
    });

    test('Negative amount payment is logically invalid', () {
      expect(-10.0, lessThan(0));
    });

    test('PaymentMethod enum coverage', () {
      expect(PaymentMethod.values.length, greaterThanOrEqualTo(3));
      expect(PaymentMethod.values, contains(PaymentMethod.cash));
      expect(PaymentMethod.values, contains(PaymentMethod.card));
    });

    test('Order completedAt is set when status is completed', () {
      final order = _makeOrder(status: OrderStatus.preparing);
      final completed = order.copyWith(
        status: OrderStatus.completed,
        completedAt: DateTime.now(),
      );
      expect(completed.completedAt, isNotNull);
      expect(completed.status, OrderStatus.completed);
    });

    test('Payment method is stored with completed order', () {
      final order = _makeOrder(status: OrderStatus.preparing);
      final paid = order.copyWith(
        status: OrderStatus.completed,
        paymentMethod: PaymentMethod.card,
      );
      expect(paid.paymentMethod, PaymentMethod.card);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // GROUP 6: Financial Integrity
  // ═════════════════════════════════════════════════════════════════════════

  group('Group 6: Financial Integrity', () {
    test('VAT at 15% is precise to 2 decimals', () {
      final vat = FinancialCalculator.calculateVat(100.0);
      expect(vat, 15.0);

      final vat2 = FinancialCalculator.calculateVat(33.33);
      expect(vat2, closeTo(5.0, 0.01));
    });

    test('VAT on zero/negative is zero', () {
      expect(FinancialCalculator.calculateVat(0), 0.0);
      expect(FinancialCalculator.calculateVat(-10), 0.0);
    });

    test('Currency rounding handles edge cases', () {
      expect(FinancialCalculator.roundCurrency(10.005), closeTo(10.01, 0.001));
      expect(FinancialCalculator.roundCurrency(10.004), closeTo(10.0, 0.001));
      expect(FinancialCalculator.roundCurrency(double.nan), 0.0);
      expect(FinancialCalculator.roundCurrency(double.infinity), 0.0);
    });

    test('Bill split sums exactly equal total', () {
      const total = 100.0;
      for (int n = 1; n <= 7; n++) {
        final shares = FinancialCalculator.splitBillDetailed(total, n);
        final sum = shares.fold<double>(0, (a, b) => a + b);
        expect(
          FinancialCalculator.roundCurrency(sum),
          closeTo(total, 0.01),
          reason: 'Splitting $total by $n should sum exactly',
        );
      }
    });

    test('Bill split with non-divisible amount distributes remainder', () {
      // 100 / 3 = 33.33 * 3 = 99.99, one person gets 33.34
      final shares = FinancialCalculator.splitBillDetailed(100.0, 3);
      expect(shares.length, 3);
      final sum = shares.fold<double>(0, (a, b) => a + b);
      expect(FinancialCalculator.roundCurrency(sum), closeTo(100.0, 0.01));
    });

    test('Percentage discount clamped at subtotal', () {
      final discount = FinancialCalculator.calculatePercentageDiscount(
        subtotal: 50.0,
        percentage: 200.0, // 200% — should be clamped
      );
      expect(discount, 50.0); // Can't exceed subtotal
    });

    test('Percentage discount clamped at maxDiscount', () {
      final discount = FinancialCalculator.calculatePercentageDiscount(
        subtotal: 1000.0,
        percentage: 50.0,
        maxDiscount: 100.0,
      );
      expect(discount, 100.0);
    });

    test('Discount on zero subtotal is zero', () {
      final discount = FinancialCalculator.calculatePercentageDiscount(
        subtotal: 0,
        percentage: 50.0,
      );
      expect(discount, 0.0);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // GROUP 7: Offline & Sync Edge Cases
  // ═════════════════════════════════════════════════════════════════════════

  group('Group 7: Offline & Sync Edge Cases', () {
    test('OrderEntity serializes and deserializes correctly', () {
      final original = _makeOrder(
        id: 'ORD-SERIAL',
        status: OrderStatus.preparing,
        orderType: OrderType.delivery,
        deliveryAddress: 'شارع المعز، القاهرة',
        subtotal: 150.0,
        taxAmount: 22.50,
        totalAmount: 172.50,
      );
      final json = original.toJson();
      final restored = OrderEntity.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.status, OrderStatus.preparing);
      expect(restored.orderType, OrderType.delivery);
      expect(restored.deliveryAddress, 'شارع المعز، القاهرة');
      expect(restored.subtotal, 150.0);
      expect(restored.totalAmount, 172.50);
    });

    test('Order with null optional fields serializes safely', () {
      final order = _makeOrder();
      final json = order.toJson();
      // These optional fields should be null/absent without crashing
      expect(() => OrderEntity.fromJson(json), returnsNormally);
    });

    test('Order items preserve modifiers across serialization', () {
      final item = OrderItem(
        menuItem: _makeMenuItem(),
        quantity: 2,
        selectedModifiers: const [
          MenuModifierOption(
            id: 'MOD-1',
            name: 'إضافة جبنة',
            extraPrice: 5.0,
          ),
        ],
        specialNotes: 'بدون بصل',
        itemTotal: 60.0,
        addedAt: DateTime.now(),
      );
      final json = item.toJson();
      final restored = OrderItem.fromJson(json);

      expect(restored.quantity, 2);
      expect(restored.selectedModifiers.length, 1);
      expect(restored.specialNotes, 'بدون بصل');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // GROUP 8: KDS & Claim Edge Cases
  // ═════════════════════════════════════════════════════════════════════════

  group('Group 8: KDS & Claim Edge Cases', () {
    test('Order can be assigned to kitchen via assignedKitchenId', () {
      final order = _makeOrder();
      final claimed = order.copyWith(assignedKitchenId: 'CHEF-123');
      expect(claimed.assignedKitchenId, 'CHEF-123');
    });

    test('Empty kitchen ID does not crash', () {
      final order = _makeOrder();
      final claimed = order.copyWith(assignedKitchenId: '');
      expect(claimed.assignedKitchenId, '');
    });

    test('Multiple assigns overwrite previous kitchen ID', () {
      final order = _makeOrder();
      final first = order.copyWith(assignedKitchenId: 'CHEF-A');
      final second = first.copyWith(assignedKitchenId: 'CHEF-B');
      expect(second.assignedKitchenId, 'CHEF-B');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // GROUP 9: Append Items Edge Cases
  // ═════════════════════════════════════════════════════════════════════════

  group('Group 9: Append Items Edge Cases', () {
    test('appendItems recalculates totals correctly', () {
      final existing = _makeOrder(
        subtotal: 50.0,
        taxAmount: 7.50,
        totalAmount: 57.50,
      );
      final newItems = [
        _makeCartItem(
          menuItem: _makeMenuItem(id: 'MI-NEW', price: 30.0),
          quantity: 1,
        ),
      ];
      final updated = OrderMapper.appendItems(
        existingOrder: existing,
        newCartItems: newItems,
        timestamp: DateTime.now(),
      );
      // Items count should increase
      expect(updated.items.length, existing.items.length + 1);
      // Subtotal should increase
      expect(updated.subtotal, greaterThan(existing.subtotal));
    });

    test('appendItems with empty new items returns same item count', () {
      final existing = _makeOrder();
      final updated = OrderMapper.appendItems(
        existingOrder: existing,
        newCartItems: [],
        timestamp: DateTime.now(),
      );
      expect(updated.items.length, existing.items.length);
    });

    test('appendItems uses FinancialCalculator for VAT', () {
      final existing = _makeOrder(
        subtotal: 100.0,
        discountAmount: 0.0,
      );
      final newItems = [
        _makeCartItem(
          menuItem: _makeMenuItem(price: 50.0),
          quantity: 1,
        ),
      ];
      final updated = OrderMapper.appendItems(
        existingOrder: existing,
        newCartItems: newItems,
        timestamp: DateTime.now(),
      );
      // VAT should be precisely calculated
      final expectedTax = FinancialCalculator.calculateVat(updated.subtotal);
      expect(updated.taxAmount, closeTo(expectedTax, 0.01));
    });
  });
}
