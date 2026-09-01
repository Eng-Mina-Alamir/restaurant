import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/printing/ticket_printer_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../cart/domain/cart_totals.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../customer/presentation/pages/menu_item_detail_sheet.dart';
import '../../../customer/presentation/widgets/menu_item_tile.dart';
import '../../../manager_dashboard/presentation/controllers/shift_controller.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../controllers/cashier_pos_controller.dart';
import '../controllers/held_orders_controller.dart';
import '../widgets/cashier_discount_dialog.dart';
import '../widgets/customer_loyalty_lookup_sheet.dart';
import '../widgets/held_orders_modal.dart';
import '../widgets/quick_tender_sheet.dart';
import '../widgets/split_tender_dialog.dart';

/// Ultra-Fast Counter & Takeaway POS Page designed specifically for frontline Cashiers.
class FastPOSCheckoutPage extends ConsumerStatefulWidget {
  const FastPOSCheckoutPage({super.key});

  @override
  ConsumerState<FastPOSCheckoutPage> createState() => _FastPOSCheckoutPageState();
}

class _FastPOSCheckoutPageState extends ConsumerState<FastPOSCheckoutPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _processingPayment = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addItem(MenuItem item) {
    AppHaptics.selectionTap();
    if (item.modifierGroups.isEmpty) {
      ref
          .read(cartControllerProvider.notifier)
          .addItem(CartItem(menuItem: item, quantity: 1));
      return;
    }
    MenuItemDetailSheet.show(context, item);
  }

  Future<void> _processCheckout({
    PaymentMethod paymentMethod = PaymentMethod.cash,
    double? tenderedCash,
  }) async {
    if (_processingPayment) return;
    final cart = ref.read(cartControllerProvider);
    if (cart.isEmpty) return;

    setState(() => _processingPayment = true);

    try {
      final posState = ref.read(cashierPOSControllerProvider);
      final rawTotals = CartTotals.fromItems(cart);
      final discountAmount = posState.calculateTotalDiscount(rawTotals.subtotal);
      final finalTotal = (rawTotals.totalAmount - discountAmount).clamp(0.0, rawTotals.totalAmount);

      final orderNotifier = ref.read(ordersControllerProvider.notifier);
      final order = await orderNotifier.placeOrder(
        orderType: OrderType.takeaway,
        paymentMethod: paymentMethod,
      );

      if (order != null) {
        // Complete the order immediately since cashier collected payment
        await orderNotifier.updateStatus(order.id, OrderStatus.completed);

        // Auto print invoice ticket
        final printer = ref.read(ticketPrinterServiceProvider);
        unawaited(printer.printCustomerInvoice(order));

        // Clear cart and POS state
        ref.read(cartControllerProvider.notifier).clear();
        ref.read(cashierPOSControllerProvider.notifier).reset();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم تحصيل طلب #${Formatters.formatOrderId(order.id)} بقيمة ${Formatters.formatCurrency(finalTotal)} بنجاح ✅',
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _processingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final menu = ref.watch(menuControllerProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final cart = ref.watch(cartControllerProvider);
    final posState = ref.watch(cashierPOSControllerProvider);
    final heldOrdersCount = ref.watch(heldOrdersControllerProvider).length;
    final shiftState = ref.watch(shiftControllerProvider);

    final rawTotals = CartTotals.fromItems(cart);
    final discountAmount = posState.calculateTotalDiscount(rawTotals.subtotal);
    final finalTotalAmount =
        (rawTotals.totalAmount - discountAmount).clamp(0.0, rawTotals.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.point_of_sale_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            const Text('نقطة البيع السريعة (Fast POS Counter)'),
            const SizedBox(width: 8),
            if (shiftState.activeShift != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'وردية #${shiftState.activeShift!.id}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          // Held orders button with badge
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                tooltip: 'الطلبات المعلقة',
                icon: const Icon(Icons.pause_circle_filled_rounded, color: Color(0xFFF59E0B)),
                onPressed: () => HeldOrdersModal.show(context),
              ),
              if (heldOrdersCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$heldOrdersCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          return Row(
            children: [
              // Left / Main Area: Menu catalog with fast filter
              Expanded(
                flex: isWide ? 6 : 5,
                child: Column(
                  children: [
                    // Search & Category Bar
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _query = v.trim()),
                              decoration: InputDecoration(
                                hintText: 'بحث سريع بالاسم أو الكود...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Menu Grid
                    Expanded(
                      child: menu.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => ErrorState(
                          message: 'خطأ في تحميل المنيو',
                          errorDetail: e,
                          onRetry: () => ref.refresh(menuControllerProvider),
                        ),
                        data: (itemsData) {
                          final items = filterMenu(itemsData, selectedCategory, _query);
                          if (items.isEmpty) {
                            return const EmptyState(
                              message: 'لا توجد أصناف مطابقة • جرّب البحث باسم آخر',
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide ? 4 : 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: isWide ? 1.25 : 1.1,
                            ),
                            itemCount: items.length,
                            itemBuilder: (ctx, index) {
                              final item = items[index];
                              return MenuItemTile(
                                item: item,
                                onTap: () => _addItem(item),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical separator
              VerticalDivider(
                width: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),

              // Right Area: Active POS Cart & Tender Station
              Expanded(
                flex: isWide ? 4 : 5,
                child: Container(
                  color: isDark
                      ? colorScheme.surfaceContainerLow
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  child: Column(
                    children: [
                      // Cart Header & Park Action
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'السلة الحالية (${cart.length} أصناف)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: cart.isNotEmpty
                                      ? () {
                                          final held = ref
                                              .read(heldOrdersControllerProvider.notifier)
                                              .holdOrder(cartItems: List<CartItem>.from(cart));
                                          if (held != null) {
                                            ref.read(cartControllerProvider.notifier).clear();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('تم تعليق الطلب (${held.label}) ✅'),
                                                backgroundColor: const Color(0xFFF59E0B),
                                              ),
                                            );
                                          }
                                        }
                                      : null,
                                  icon: const Icon(Icons.pause_circle_outline, size: 16),
                                  label: const Text('تعليق الطلب'),
                                ),
                                IconButton(
                                  tooltip: 'تفريغ السلة',
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: cart.isNotEmpty
                                      ? () {
                                          ref.read(cartControllerProvider.notifier).clear();
                                          ref.read(cashierPOSControllerProvider.notifier).reset();
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Cart Items List
                      Expanded(
                        child: cart.isEmpty
                            ? const Center(
                                child: Text(
                                  'السلة فارغة • اضغط على الأصناف لإضافتها',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                itemCount: cart.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 6),
                                itemBuilder: (ctx, index) {
                                  final item = cart[index];
                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      border: Border.all(
                                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.menuItem.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                '${Formatters.formatCurrency(item.unitPrice)} × ${item.quantity}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          Formatters.formatCurrency(item.linePrice),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                                          onPressed: () => ref
                                              .read(cartControllerProvider.notifier)
                                              .decrement(item.configKey),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 18),
                                          onPressed: () => ref
                                              .read(cartControllerProvider.notifier)
                                              .increment(item.configKey),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Fast Tool Actions Bar: (Discount, Loyalty, Split)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.percent, size: 14, color: Color(0xFF8B5CF6)),
                              label: Text(
                                posState.selectedDiscount != null
                                    ? posState.selectedDiscount!.nameAr
                                    : 'خصم / ضيافة',
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: cart.isNotEmpty
                                  ? () async {
                                      final disc = await CashierDiscountDialog.show(
                                        context,
                                        orderSubtotal: rawTotals.subtotal,
                                        currentDiscount: posState.selectedDiscount,
                                      );
                                      if (disc != null) {
                                        ref
                                            .read(cashierPOSControllerProvider.notifier)
                                            .applyDiscount(disc);
                                      }
                                    }
                                  : null,
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.stars, size: 14, color: Color(0xFFCA8A04)),
                              label: Text(
                                posState.linkedLoyaltyCustomer != null
                                    ? posState.linkedLoyaltyCustomer!.name
                                    : 'نقاط الولاء',
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: cart.isNotEmpty
                                  ? () async {
                                      final (cust, points) =
                                          await CustomerLoyaltyLookupSheet.show(
                                        context,
                                        orderTotal: finalTotalAmount,
                                        currentCustomer: posState.linkedLoyaltyCustomer,
                                      );
                                      if (cust != null) {
                                        final posNotifier = ref
                                            .read(cashierPOSControllerProvider.notifier);
                                        posNotifier.linkCustomer(cust);
                                        if (points > 0) {
                                          posNotifier.redeemCustomerPoints(points);
                                        }
                                      }
                                    }
                                  : null,
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.call_split, size: 14, color: Color(0xFF10B981)),
                              label: const Text('دفع مجزأ', style: TextStyle(fontSize: 11)),
                              onPressed: cart.isNotEmpty
                                  ? () async {
                                      final splitRes = await SplitTenderDialog.show(
                                        context,
                                        orderId: 'ORD-POS-${DateTime.now().millisecondsSinceEpoch}',
                                        totalAmountDue: finalTotalAmount,
                                      );
                                      if (splitRes != null && splitRes.isFullyPaid) {
                                        await _processCheckout(paymentMethod: PaymentMethod.card);
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      // Totals & Checkout Panel
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (discountAmount > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الخصم المطبق:', style: TextStyle(fontSize: 12, color: Colors.red)),
                                  Text(
                                    '- ${Formatters.formatCurrency(discountAmount)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'المبلغ الإجمالي للدفع:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  Formatters.formatCurrency(finalTotalAmount),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // 2 Big Tender Action Buttons
                            Row(
                              children: [
                                // Cash & Change Tender
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: cart.isNotEmpty && !_processingPayment
                                        ? () async {
                                            final tendered = await QuickTenderSheet.show(
                                              context,
                                              totalAmountDue: finalTotalAmount,
                                            );
                                            if (tendered != null) {
                                              await _processCheckout(
                                                paymentMethod: PaymentMethod.cash,
                                                tenderedCash: tendered,
                                              );
                                            }
                                          }
                                        : null,
                                    icon: const Icon(Icons.payments_rounded),
                                    label: const Text(
                                      '💵 كاش وحاسبة الباقي',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),

                                // Direct Card / Visa Payment
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: cart.isNotEmpty && !_processingPayment
                                        ? () => _processCheckout(paymentMethod: PaymentMethod.card)
                                        : null,
                                    icon: const Icon(Icons.credit_card_rounded),
                                    label: const Text(
                                      '💳 دفع سريع بالفيزا',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
