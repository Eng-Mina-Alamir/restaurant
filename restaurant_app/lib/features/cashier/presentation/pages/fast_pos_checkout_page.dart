import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/printing/ticket_printer_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../cart/domain/cart_totals.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../customer/presentation/pages/menu_item_detail_sheet.dart';
import '../../../manager_dashboard/presentation/controllers/shift_controller.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../../table_management/presentation/controllers/table_controller.dart';
import '../controllers/cashier_pos_controller.dart';
import '../controllers/held_orders_controller.dart';
import '../widgets/cashier_discount_dialog.dart';
import '../widgets/customer_loyalty_lookup_sheet.dart';
import '../widgets/held_orders_modal.dart';
import '../widgets/quick_tender_sheet.dart';
import '../widgets/split_tender_dialog.dart';

/// Ultra-Fast Counter & Takeaway POS Page designed specifically for frontline Cashiers.
///
/// Fully responsive:
/// - Desktop / Tablet (>= 750px): Dual-pane layout (Menu grid on left, Cart & Tender on right).
/// - Mobile (< 750px): Full width touch-optimized Menu grid with sticky bottom bar & slide-up Cart/Tender sheet.
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
    BuildContext? modalContext,
  }) async {
    if (_processingPayment) return;
    final cart = ref.read(cartControllerProvider);
    if (cart.isEmpty) return;

    setState(() => _processingPayment = true);

    try {
      final posState = ref.read(cashierPOSControllerProvider);
      final rawTotals = CartTotals.fromItems(cart);
      final discountAmount = posState.calculateTotalDiscount(rawTotals.subtotal);
      // Server is the source of truth: VAT applies to (subtotal - discount),
      // so recompute via CartTotals instead of subtracting after VAT.
      final finalTotal = CartTotals.fromItems(
        cart,
        discountAmount: discountAmount,
      ).totalAmount;

      final orderNotifier = ref.read(ordersControllerProvider.notifier);
      OrderEntity? order;
      if (posState.orderType == OrderType.dineIn && posState.selectedTableNumber != null) {
        // Resolve the real tables.id by table_number (numeric strings like
        // "11" parse server-side; the old 't5' placeholder parsed to null and
        // silently dropped the table link).
        final tables = ref.read(tableControllerProvider);
        String tableId = '${posState.selectedTableNumber}';
        for (final t in tables) {
          if (t.tableNumber == posState.selectedTableNumber) {
            tableId = t.id;
            break;
          }
        }
        order = await orderNotifier.placeOrderForTable(
          tableId,
          paymentMethod: paymentMethod,
          discountAmountOverride: discountAmount,
        );
      } else {
        order = await orderNotifier.placeOrder(
          orderType: posState.orderType,
          paymentMethod: paymentMethod,
          discountAmountOverride: discountAmount,
        );
      }

      // Fast-POS is immediate tender: close + pay right away so the sale
      // lands in completed + payments (leaving it pending while the UI
      // claims it was collected corrupts cashier totals — F4). The payment
      // row itself is persisted by the onPaymentRecorded hook.
      if (order != null) {
        final closed = await orderNotifier.completeAndPayOrder(
          order.id,
          paymentMethod: paymentMethod,
          discountAmount: discountAmount > 0 ? discountAmount : null,
        );
        if (closed != null) order = closed;
        // Auto print invoice ticket
        final printer = ref.read(ticketPrinterServiceProvider);
        unawaited(printer.printCustomerInvoice(order));

        // Clear cart and POS state
        ref.read(cartControllerProvider.notifier).clear();
        ref.read(cashierPOSControllerProvider.notifier).reset();

        // If modal was open, close it
        if (modalContext != null && modalContext.mounted) {
          Navigator.of(modalContext).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم تحصيل طلب #${Formatters.formatOrderId(order.id)} بقيمة ${Formatters.formatCurrency(finalTotal)} وإرساله للمطبخ بنجاح 👨‍🍳✅',
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

  void _openMobileCartSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MobileCartBottomSheet(
        onProcessCheckout: (method, tendered) => _processCheckout(
          paymentMethod: method,
          tenderedCash: tendered,
          modalContext: ctx,
        ),
        isProcessing: _processingPayment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(menuControllerProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final cart = ref.watch(cartControllerProvider);
    final heldOrdersCount = ref.watch(heldOrdersControllerProvider).length;
    final shiftState = ref.watch(shiftControllerProvider);

    final totalQuantity = cart.fold<int>(0, (sum, i) => sum + i.quantity);
    final posState = ref.watch(cashierPOSControllerProvider);
    final rawTotals = CartTotals.fromItems(cart);
    final discountAmount = posState.calculateTotalDiscount(rawTotals.subtotal);
    // Same single source as checkout: VAT on (subtotal - discount).
    final finalTotalAmount = CartTotals.fromItems(
      cart,
      discountAmount: discountAmount,
    ).totalAmount;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.point_of_sale_rounded, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'نقطة البيع السريعة',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (shiftState.activeShift != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      'وردية #${shiftState.activeShift!.id}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 750;

          if (!isWide) {
            // Mobile Portrait / Compact View
            return Column(
              children: [
                // Menu Catalog takes entire width
                Expanded(
                  child: _MenuCatalogSection(
                    searchCtrl: _searchCtrl,
                    query: _query,
                    onQueryChanged: (v) => setState(() => _query = v),
                    menu: menu,
                    selectedCategory: selectedCategory,
                    onCategorySelected: (cat) =>
                        ref.read(selectedCategoryProvider.notifier).state = cat,
                    onItemTap: _addItem,
                    cart: cart,
                    isWide: false,
                    maxWidth: constraints.maxWidth,
                  ),
                ),

                // Sticky Mobile Bottom Bar for Cart & Quick Checkout
                _MobileStickyCartBar(
                  itemCount: totalQuantity,
                  distinctCount: cart.length,
                  totalAmount: finalTotalAmount,
                  onOpenCart: () => _openMobileCartSheet(context),
                  onQuickCash: cart.isNotEmpty && !_processingPayment
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
                ),
              ],
            );
          }

          // Tablet / Desktop Dual-Pane Layout
          return Row(
            children: [
              // Left: Menu catalog
              Expanded(
                flex: constraints.maxWidth > 1050 ? 6 : 5,
                child: _MenuCatalogSection(
                  searchCtrl: _searchCtrl,
                  query: _query,
                  onQueryChanged: (v) => setState(() => _query = v),
                  menu: menu,
                  selectedCategory: selectedCategory,
                  onCategorySelected: (cat) =>
                      ref.read(selectedCategoryProvider.notifier).state = cat,
                  onItemTap: _addItem,
                  cart: cart,
                  isWide: true,
                  maxWidth: constraints.maxWidth,
                ),
              ),

              // Vertical separator
              VerticalDivider(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),

              // Right: Active POS Cart & Tender Station
              Expanded(
                flex: constraints.maxWidth > 1050 ? 4 : 5,
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surfaceContainerLow
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  child: _POSCartPanel(
                    onProcessCheckout: (method, tendered) => _processCheckout(
                      paymentMethod: method,
                      tenderedCash: tendered,
                    ),
                    isProcessing: _processingPayment,
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

// ─────────────────────────────────────────────────────────────────────────────
// MENU CATALOG SECTION (Search + Category Filter + POS Item Grid)
// ─────────────────────────────────────────────────────────────────────────────

class _MenuCatalogSection extends StatelessWidget {
  const _MenuCatalogSection({
    required this.searchCtrl,
    required this.query,
    required this.onQueryChanged,
    required this.menu,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onItemTap,
    required this.cart,
    required this.isWide,
    required this.maxWidth,
  });

  final TextEditingController searchCtrl;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final AsyncValue<dynamic> menu;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<MenuItem> onItemTap;
  final List<CartItem> cart;
  final bool isWide;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 4),
          child: TextField(
            controller: searchCtrl,
            onChanged: (v) => onQueryChanged(v.trim()),
            decoration: InputDecoration(
              hintText: 'بحث سريع بالاسم أو الكود...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        searchCtrl.clear();
                        onQueryChanged('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),

        // Categories Chips Bar
        menu.maybeWhen(
          data: (itemsData) {
            final categories = [
              kAllCategoriesFilter,
              ...itemsData.categories,
            ];

            return SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (ctx, index) {
                  final cat = categories[index];
                  final isSelected = selectedCategory == cat;
                  final label = cat == kAllCategoriesFilter ? '✨ الكل' : cat;

                  return ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: colorScheme.primary,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    onSelected: (selected) => onCategorySelected(cat),
                  );
                },
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),

        const Divider(height: 1, thickness: 0.5),

        // Grid of POS Items
        Expanded(
          child: menu.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stack) => ErrorState(
              message: 'خطأ في تحميل المنيو',
              errorDetail: e,
              onRetry: () => onCategorySelected(selectedCategory),
            ),
            data: (itemsData) {
              final items = filterMenu(itemsData, selectedCategory, query);
              if (items.isEmpty) {
                return const EmptyState(
                  message: 'لا توجد أصناف مطابقة • جرّب البحث باسم آخر',
                );
              }

              // Compute column count cleanly
              final int crossAxisCount;
              final double aspectRatio;

              if (isWide) {
                if (maxWidth > 1200) {
                  crossAxisCount = 4;
                  aspectRatio = 0.88;
                } else if (maxWidth > 950) {
                  crossAxisCount = 3;
                  aspectRatio = 0.85;
                } else {
                  crossAxisCount = 2;
                  aspectRatio = 0.92;
                }
              } else {
                if (maxWidth > 480) {
                  crossAxisCount = 3;
                  aspectRatio = 0.85;
                } else {
                  crossAxisCount = 2;
                  aspectRatio = 0.82;
                }
              }

              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.sm),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: items.length,
                itemBuilder: (ctx, index) {
                  final item = items[index];
                  // Find current quantity in cart
                  final cartQty = cart
                      .where((c) => c.menuItem.id == item.id)
                      .fold<int>(0, (sum, c) => sum + c.quantity);

                  return _POSMenuItemCard(
                    item: item,
                    cartQuantity: cartQty,
                    onTap: () => onItemTap(item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOUCH-OPTIMIZED POS MENU ITEM CARD
// ─────────────────────────────────────────────────────────────────────────────

class _POSMenuItemCard extends StatelessWidget {
  const _POSMenuItemCard({
    required this.item,
    required this.cartQuantity,
    required this.onTap,
  });

  final MenuItem item;
  final int cartQuantity;
  final VoidCallback onTap;

  static IconData _getCategoryPlaceholderIcon(String categoryId) {
    if (categoryId.contains('برجر')) return Icons.lunch_dining_rounded;
    if (categoryId.contains('بيتزا')) return Icons.local_pizza_rounded;
    if (categoryId.contains('مشوي')) return Icons.outdoor_grill_rounded;
    if (categoryId.contains('طواج')) return Icons.ramen_dining_rounded;
    if (categoryId.contains('مشروب')) return Icons.local_bar_rounded;
    if (categoryId.contains('حلو')) return Icons.cake_rounded;
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasModifiers = item.modifierGroups.isNotEmpty;

    return AnimatedPressCard(
      onTap: item.isAvailable ? onTap : null,
      color: item.isAvailable
          ? (cartQuantity > 0
              ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08)
              : (isDark ? colorScheme.surfaceContainerHigh : Colors.white))
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: AppRadius.md,
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: cartQuantity > 0
                ? const Color(0xFF10B981)
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: cartQuantity > 0 ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image / Icon Header
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? AppImageUtils.buildOptimizedImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md - 1)),
                          errorWidget: _buildFallback(colorScheme),
                        )
                      : _buildFallback(colorScheme),

                  // Out of stock overlay
                  if (!item.isAvailable)
                    Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: const Text(
                        'غير متوفر',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // In-Cart Badge Indicator
                  if (cartQuantity > 0)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '$cartQuantity×',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                  // Dietary / Customizer Tag
                  if (hasModifiers)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'خيارات',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Details: Name & Price
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.isAvailable ? null : Colors.grey,
                        height: 1.15,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            Formatters.formatCurrency(item.price),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: item.isAvailable
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: item.isAvailable
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 14,
                            color: item.isAvailable
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primaryContainer.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: Icon(
        _getCategoryPlaceholderIcon(item.categoryId),
        size: 32,
        color: colorScheme.primary.withValues(alpha: 0.7),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL CART & TENDER PANEL (Shared for Desktop Right-Pane & Mobile Modal Sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _POSCartPanel extends ConsumerWidget {
  const _POSCartPanel({
    required this.onProcessCheckout,
    required this.isProcessing,
  });

  final void Function(PaymentMethod method, double? tenderedCash) onProcessCheckout;
  final bool isProcessing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final cart = ref.watch(cartControllerProvider);
    final posState = ref.watch(cashierPOSControllerProvider);

    final rawTotals = CartTotals.fromItems(cart);
    final discountAmount = posState.calculateTotalDiscount(rawTotals.subtotal);
    final finalTotalAmount =
        (rawTotals.totalAmount - discountAmount).clamp(0.0, rawTotals.totalAmount);

    return Column(
      children: [
        // Cart Header & Hold/Clear Actions
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 8,
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
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'السلة (${cart.length})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Park / Hold Order Button
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                ),
                onPressed: cart.isNotEmpty
                    ? () {
                        final held = ref
                            .read(heldOrdersControllerProvider.notifier)
                            .holdOrder(cartItems: List<CartItem>.from(cart));
                        if (held != null) {
                          ref.read(cartControllerProvider.notifier).clear();
                          ref.read(cashierPOSControllerProvider.notifier).reset();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم تعليق الطلب (${held.label}) بنجاح ⏸️'),
                              backgroundColor: const Color(0xFFF59E0B),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.pause_circle_outline, size: 16, color: Color(0xFFF59E0B)),
                label: const Text(
                  'تعليق',
                  style: TextStyle(fontSize: 12, color: Color(0xFFF59E0B)),
                ),
              ),
              // Clear Cart Button
              IconButton(
                tooltip: 'تفريغ السلة',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: cart.isNotEmpty
                    ? () {
                        ref.read(cartControllerProvider.notifier).clear();
                        ref.read(cashierPOSControllerProvider.notifier).reset();
                      }
                    : null,
              ),
            ],
          ),
        ),

        // Order Type & Table Selector (Takeaway / Dine-in / Delivery)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<OrderType>(
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: OrderType.takeaway,
                      label: Text('سفري', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.takeout_dining, size: 14),
                    ),
                    ButtonSegment(
                      value: OrderType.dineIn,
                      label: Text('صالة', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.table_restaurant, size: 14),
                    ),
                    ButtonSegment(
                      value: OrderType.delivery,
                      label: Text('توصيل', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.delivery_dining, size: 14),
                    ),
                  ],
                  selected: {posState.orderType},
                  onSelectionChanged: (set) {
                    ref.read(cashierPOSControllerProvider.notifier).setOrderType(set.first);
                  },
                ),
              ),
              if (posState.orderType == OrderType.dineIn) ...[
                const SizedBox(width: 6),
                PopupMenuButton<int>(
                  tooltip: 'اختر رقم الطاولة',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      posState.selectedTableNumber != null
                          ? 'طاولة ${posState.selectedTableNumber}'
                          : 'طاولة؟',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  onSelected: (tableNum) {
                    ref.read(cashierPOSControllerProvider.notifier).setSelectedTableNumber(tableNum);
                  },
                  itemBuilder: (ctx) => [
                    for (int i = 1; i <= 20; i++)
                      PopupMenuItem(value: i, child: Text('طاولة $i')),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Cart Items List
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'السلة فارغة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'اضغط على الأصناف لإضافتها',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  itemCount: cart.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 4),
                  itemBuilder: (ctx, index) {
                    final item = cart[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                if (item.selectedModifiers.isNotEmpty)
                                  Text(
                                    item.selectedModifiers.map((m) => m.name).join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                Text(
                                  Formatters.formatCurrency(item.unitPrice),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.formatCurrency(item.linePrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Decrement
                          InkWell(
                            onTap: () => ref
                                .read(cartControllerProvider.notifier)
                                .decrement(item.configKey),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(Icons.remove_circle_outline, size: 18),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // Increment
                          InkWell(
                            onTap: () => ref
                                .read(cartControllerProvider.notifier)
                                .increment(item.configKey),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(Icons.add_circle_outline, size: 18),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Fast Tool Actions Bar: (Discount, Loyalty, Split)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Discount Chip
                ActionChip(
                  avatar: const Icon(Icons.percent, size: 13, color: Color(0xFF8B5CF6)),
                  label: Text(
                    posState.selectedDiscount != null
                        ? posState.selectedDiscount!.nameAr
                        : 'خصم / ضيافة',
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
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
                const SizedBox(width: 6),

                // Loyalty Chip
                ActionChip(
                  avatar: const Icon(Icons.stars, size: 13, color: Color(0xFFCA8A04)),
                  label: Text(
                    posState.linkedLoyaltyCustomer != null
                        ? posState.linkedLoyaltyCustomer!.name
                        : 'نقاط الولاء',
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: cart.isNotEmpty
                      ? () async {
                          final (cust, points) =
                              await CustomerLoyaltyLookupSheet.show(
                            context,
                            orderTotal: finalTotalAmount,
                            currentCustomer: posState.linkedLoyaltyCustomer,
                          );
                          if (cust != null) {
                            final posNotifier =
                                ref.read(cashierPOSControllerProvider.notifier);
                            posNotifier.linkCustomer(cust);
                            if (points > 0) {
                              posNotifier.redeemCustomerPoints(points);
                            }
                          }
                        }
                      : null,
                ),
                const SizedBox(width: 6),

                // Split Tender Chip
                ActionChip(
                  avatar: const Icon(Icons.call_split, size: 13, color: Color(0xFF10B981)),
                  label: const Text('دفع مجزأ', style: TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  onPressed: cart.isNotEmpty
                      ? () async {
                          final splitRes = await SplitTenderDialog.show(
                            context,
                            orderId: 'ORD-POS-${DateTime.now().millisecondsSinceEpoch}',
                            totalAmountDue: finalTotalAmount,
                          );
                          if (splitRes != null && splitRes.isFullyPaid) {
                            onProcessCheckout(PaymentMethod.card, null);
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),

        // Totals & Tender Buttons Panel
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الخصم المطبق:', style: TextStyle(fontSize: 11, color: Colors.red)),
                      Text(
                        '- ${Formatters.formatCurrency(discountAmount)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الإجمالي للدفع:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(finalTotalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2 Tender Action Buttons
              Row(
                children: [
                  // Cash Tender
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: cart.isNotEmpty && !isProcessing
                          ? () async {
                              final tendered = await QuickTenderSheet.show(
                                context,
                                totalAmountDue: finalTotalAmount,
                              );
                              if (tendered != null) {
                                onProcessCheckout(PaymentMethod.cash, tendered);
                              }
                            }
                          : null,
                      icon: const Icon(Icons.payments_rounded, size: 16),
                      label: const Text(
                        '💵 كاش وباقي',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Visa / Card Direct
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: cart.isNotEmpty && !isProcessing
                          ? () => onProcessCheckout(PaymentMethod.card, null)
                          : null,
                      icon: const Icon(Icons.credit_card_rounded, size: 16),
                      label: const Text(
                        '💳 فيزا سريعة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE STICKY BOTTOM CART BAR
// ─────────────────────────────────────────────────────────────────────────────

class _MobileStickyCartBar extends StatelessWidget {
  const _MobileStickyCartBar({
    required this.itemCount,
    required this.distinctCount,
    required this.totalAmount,
    required this.onOpenCart,
    required this.onQuickCash,
  });

  final int itemCount;
  final int distinctCount;
  final double totalAmount;
  final VoidCallback onOpenCart;
  final VoidCallback? onQuickCash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cart Summary (Clickable to open sheet)
            InkWell(
              onTap: onOpenCart,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shopping_cart_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$itemCount صنف ($distinctCount نوع)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      Formatters.formatCurrency(totalAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            // Quick Cash Tender Button
            if (itemCount > 0 && onQuickCash != null) ...[
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onPressed: onQuickCash,
                icon: const Icon(Icons.payments_rounded, size: 16),
                label: const Text('💵 كاش', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
            ],

            // View Cart & Checkout Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: onOpenCart,
              icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
              label: Text(
                itemCount > 0 ? 'السلة والدفع' : 'عرض السلة',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE CART BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _MobileCartBottomSheet extends StatelessWidget {
  const _MobileCartBottomSheet({
    required this.onProcessCheckout,
    required this.isProcessing,
  });

  final void Function(PaymentMethod method, double? tenderedCash) onProcessCheckout;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Inner Cart Panel
          Expanded(
            child: _POSCartPanel(
              onProcessCheckout: onProcessCheckout,
              isProcessing: isProcessing,
            ),
          ),
        ],
      ),
    );
  }
}
