import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../coupons/presentation/controllers/coupon_controller.dart';
import '../../../customer/presentation/controllers/curbside_controller.dart';
import '../../../customer/presentation/controllers/customer_wallet_controller.dart';
import '../../../customer/presentation/controllers/scheduled_order_controller.dart';
import '../../../customer/presentation/widgets/address_map_picker_sheet.dart';
import '../../../customer/presentation/widgets/curbside_pickup_sheet.dart';
import '../../../customer/presentation/widgets/schedule_time_picker_sheet.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../domain/cart_totals.dart';
import '../../domain/entities/cart_item.dart';
import '../controllers/cart_controller.dart';
import '../widgets/split_bill_sheet.dart';

/// Shows the cart contents with quantity controls, coupons, delivery/payment selectors,
/// and a sticky checkout bottom bar.
class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _placing = false;
  final _couponTextController = TextEditingController();
  bool _validatingCoupon = false;
  bool _useWalletCredit = true;

  @override
  void dispose() {
    _couponTextController.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    if (_placing) return;
    final payment = ref.read(selectedPaymentMethodProvider);
    final orderType = ref.read(selectedOrderTypeProvider);
    final deliveryAddress = ref.read(selectedDeliveryAddressProvider);

    if (orderType == OrderType.delivery &&
        (deliveryAddress == null || deliveryAddress.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('من فضلك أدخل عنوان التوصيل أولاً'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final walletState = ref.read(customerWalletProvider);
    final cart = ref.read(cartControllerProvider);
    final appliedCoupon = ref.read(appliedCouponProvider);
    final rawSubtotal = cart.fold<double>(0, (sum, item) => sum + item.linePrice);
    final discountAmount = appliedCoupon != null ? appliedCoupon.calculateDiscount(rawSubtotal) : 0.0;
    final totals = CartTotals.fromItems(cart, discountAmount: discountAmount);
    final walletDeduction = (_useWalletCredit && walletState.balance > 0)
        ? walletState.balance.clamp(0.0, totals.totalAmount)
        : 0.0;

    setState(() => _placing = true);
    final order = await ref
        .read(ordersControllerProvider.notifier)
        .placeOrder(
          paymentMethod: payment,
          orderType: orderType,
          deliveryAddress: deliveryAddress,
        );

    if (!mounted) return;
    setState(() => _placing = false);

    if (order != null) {
      if (walletDeduction > 0) {
        ref.read(customerWalletProvider.notifier).deductFunds(
              walletDeduction,
              title: 'سداد طلب من رصيد المحفظة',
            );
      }
      AppHaptics.actionSuccess();
      context.push('/customer/order-confirmation', extra: order);
    }
  }

  Future<void> _applyCoupon(double subtotal) async {
    final code = _couponTextController.text.trim();
    if (code.isEmpty) return;

    setState(() => _validatingCoupon = true);
    final repo = ref.read(couponRepositoryProvider);
    final result = await repo.validateAndGetCoupon(code, subtotal);
    if (!mounted) return;
    setState(() => _validatingCoupon = false);

    result.when(
      onLeft: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      onRight: (coupon) {
        ref.read(appliedCouponProvider.notifier).apply(coupon);
        _couponTextController.clear();
        AppHaptics.actionSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تطبيق كود الخصم "${coupon.code}" بنجاح!'),
          ),
        );
      },
    );
  }

  void _clearCart() {
    ref.read(cartControllerProvider.notifier).clear();
    ref.read(appliedCouponProvider.notifier).remove();
    AppHaptics.actionSuccess();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppConstants.cartCleared)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final rawSubtotal = cart.fold<double>(
      0,
      (sum, item) => sum + item.linePrice,
    );
    final discountAmount = appliedCoupon != null
        ? appliedCoupon.calculateDiscount(rawSubtotal)
        : 0.0;
    final totals = CartTotals.fromItems(cart, discountAmount: discountAmount);
    final walletState = ref.watch(customerWalletProvider);
    final walletAvailable = walletState.balance;
    final walletDeduction = (_useWalletCredit && walletAvailable > 0)
        ? walletAvailable.clamp(0.0, totals.totalAmount)
        : 0.0;
    final finalPayableAmount = (totals.totalAmount - walletDeduction).clamp(0.0, double.infinity);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              AppConstants.cartTitle,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (cart.isNotEmpty)
              Text(
                '${cart.length} أصناف • ${ref.watch(cartControllerProvider.select((c) => c.fold<int>(0, (s, i) => s + i.quantity)))} قطعة',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (cart.isNotEmpty) ...[
            IconButton(
              tooltip: 'تقسيم الفاتورة',
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () => showSplitBillSheet(context),
            ),
            IconButton(
              tooltip: AppConstants.clearCart,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _clearCart,
            ),
          ],
        ],
      ),
      body: cart.isEmpty
          ? EmptyState(
              message: AppConstants.cartEmpty,
              icon: Icons.shopping_cart_outlined,
              actionLabel: AppConstants.cartEmptyBrowse,
              onAction: () => context.go('/customer'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    children: [
                      // ── 1. Items List ──
                      for (final item in cart) ...[
                        _CartLineCard(
                          item: item,
                          onIncrement: () => ref
                              .read(cartControllerProvider.notifier)
                              .increment(item.configKey),
                          onDecrement: () => ref
                              .read(cartControllerProvider.notifier)
                              .decrement(item.configKey),
                          onRemove: () => ref
                              .read(cartControllerProvider.notifier)
                              .removeItem(item.configKey),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      const SizedBox(height: AppSpacing.sm),

                      // ── 2. Order Options & Delivery ──
                      _SectionContainer(
                        title: 'نوع الطلب',
                        icon: Icons.delivery_dining_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OrderTypeSelector(
                              orderType: ref.watch(selectedOrderTypeProvider),
                              onChanged: (t) {
                                AppHaptics.selectionTap();
                                ref.read(selectedOrderTypeProvider.notifier).state = t;
                              },
                            ),
                            if (ref.watch(selectedOrderTypeProvider) == OrderType.delivery) ...[
                              const SizedBox(height: AppSpacing.sm),
                              InkWell(
                                onTap: () async {
                                  final result = await AddressMapPickerSheet.show(context);
                                  if (result != null) {
                                    ref.read(selectedDeliveryAddressProvider.notifier).state =
                                        result.formattedAddress;
                                  }
                                },
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(
                                      color: colorScheme.primary.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        color: colorScheme.primary,
                                        size: 22,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'عنوان التوصيل',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              ref.watch(selectedDeliveryAddressProvider) ??
                                                  'انقر لتحديد العنوان على الخريطة',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.edit_location_alt_outlined,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // ── 2.5 Schedule Order & Curbside Pickup ──
                      Builder(
                        builder: (context) {
                          final scheduled = ref.watch(scheduledOrderControllerProvider);
                          final curbside = ref.watch(curbsideControllerProvider);
                          final orderType = ref.watch(selectedOrderTypeProvider);
                          final isTakeaway = orderType == OrderType.takeaway;

                          return Column(
                            children: [
                              // Schedule Slot Tile
                              InkWell(
                                onTap: () => ScheduleTimePickerSheet.show(context),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(
                                      color: scheduled != null ? const Color(0xFF0284C7) : colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        color: scheduled != null ? const Color(0xFF0284C7) : colorScheme.onSurfaceVariant,
                                        size: 22,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              scheduled != null ? 'موعد استلام مجدول' : 'وقت التجهيز والتوصيل',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: scheduled != null ? const Color(0xFF0284C7) : colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              scheduled != null
                                                  ? 'محدد في: ${scheduled.targetDateTime.hour.toString().padLeft(2, '0')}:${scheduled.targetDateTime.minute.toString().padLeft(2, '0')}'
                                                  : 'الآن بأسرع وقت (فوري) - اضغط للجدولة',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),

                              // Curbside Tile (visible on Takeaway or if configured)
                              if (isTakeaway || curbside != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                InkWell(
                                  onTap: () => CurbsidePickupSheet.show(context),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC2410C).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      border: Border.all(color: const Color(0xFFC2410C).withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.directions_car_filled_rounded, color: Color(0xFFC2410C), size: 22),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'استلام من السيارة (Curbside Pickup)',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFC2410C)),
                                              ),
                                              Text(
                                                curbside != null
                                                    ? '${curbside.carModel} (${curbside.carColor}) - ${curbside.licensePlate}'
                                                    : 'حدد بيانات سيارتك لنسلمك الطلب بالخارج فور وصولك',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFC2410C)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // ── 3. Coupon / Promo Code ──
                      _SectionContainer(
                        title: 'كوبون الخصم',
                        icon: Icons.local_offer_outlined,
                        child: appliedCoupon == null
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _couponTextController,
                                      textCapitalization: TextCapitalization.characters,
                                      decoration: const InputDecoration(
                                        hintText: 'أدخل كود الخصم (مثل WELCOME50)',
                                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(72, 44),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    onPressed: _validatingCoupon
                                        ? null
                                        : () => _applyCoupon(totals.subtotal),
                                    child: _validatingCoupon
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('تطبيق'),
                                  ),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(color: colorScheme.tertiary),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: colorScheme.tertiary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'تم تطبيق: ${appliedCoupon.code} (${appliedCoupon.title})',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onTertiaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: colorScheme.error,
                                      ),
                                      tooltip: 'إلغاء الكوبون',
                                      onPressed: () {
                                        ref.read(appliedCouponProvider.notifier).remove();
                                        AppHaptics.selectionTap();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // ── 3.5 Digital Wallet / Gift Card Credit ──
                      if (walletAvailable > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _SectionContainer(
                          title: 'المحفظة وبطاقات الهدايا',
                          icon: Icons.account_balance_wallet_outlined,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.wallet_giftcard_rounded, color: Color(0xFF0F766E), size: 20),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'استخدام رصيد المحفظة / الهدية',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'الرصيد المتاح: ${Formatters.formatCurrency(walletAvailable)} (يخصم ${Formatters.formatCurrency(walletDeduction)})',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _useWalletCredit,
                                  activeThumbColor: const Color(0xFF0F766E),
                                  onChanged: (val) => setState(() => _useWalletCredit = val),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.sm),

                      // ── 4. Payment Method Selector ──
                      _SectionContainer(
                        title: AppConstants.paymentMethodLabel,
                        icon: Icons.payments_outlined,
                        child: _PaymentSelector(
                          paymentMethod: ref.watch(selectedPaymentMethodProvider),
                          onChanged: (m) {
                            AppHaptics.selectionTap();
                            ref.read(selectedPaymentMethodProvider.notifier).state = m;
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // ── 5. Bill Breakdown Summary ──
                      _SectionContainer(
                        title: 'ملخص الحساب',
                        icon: Icons.receipt_long_outlined,
                        child: Column(
                          children: [
                            _SummaryRow(
                              label: AppConstants.subtotalLabel,
                              value: Formatters.formatCurrency(totals.subtotal),
                            ),
                            if (totals.discountAmount > 0) ...[
                              const SizedBox(height: AppSpacing.xs),
                              _SummaryRow(
                                label: 'خصم الكوبون',
                                value: '- ${Formatters.formatCurrency(totals.discountAmount)}',
                                valueColor: colorScheme.tertiary,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            _SummaryRow(
                              label: AppConstants.taxLabel,
                              value: Formatters.formatCurrency(totals.taxAmount),
                            ),
                            if (walletDeduction > 0) ...[
                              const SizedBox(height: AppSpacing.xs),
                              _SummaryRow(
                                label: 'خصم رصيد المحفظة / الهدية',
                                value: '- ${Formatters.formatCurrency(walletDeduction)}',
                                valueColor: const Color(0xFF0F766E),
                              ),
                            ],
                            const Divider(height: AppSpacing.md),
                            _SummaryRow(
                              label: AppConstants.orderTotalLabel,
                              value: Formatters.formatCurrency(finalPayableAmount),
                              emphasized: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),

                // ── Sticky Checkout Bottom Bar ──
                _StickyCheckoutBar(
                  totalAmount: finalPayableAmount,
                  placing: _placing,
                  onCheckout: _checkout,
                ),
              ],
            ),
    );
  }
}

/// Card showing single line item with thumbnail, details, price and quantity stepper.
class _CartLineCard extends StatelessWidget {
  const _CartLineCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  static IconData _getCategoryIcon(String categoryId) {
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
    final modifiers = item.selectedModifiers.map((m) => m.name).join('، ');

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dish visual thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: item.menuItem.imageUrl != null && item.menuItem.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.network(
                        item.menuItem.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(
                            _getCategoryIcon(item.menuItem.categoryId),
                            size: 28,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        _getCategoryIcon(item.menuItem.categoryId),
                        size: 28,
                        color: colorScheme.primary,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Item metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuItem.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (modifiers.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      modifiers,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (item.specialNotes?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${AppConstants.specialNotesLabel}: ${item.specialNotes}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Formatters.formatCurrency(item.linePrice),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // Stepper controls (+ / -)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'تقليل الكمية',
                    icon: const Icon(Icons.remove),
                    onPressed: onDecrement,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      '${item.quantity}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'زيادة الكمية',
                    icon: const Icon(Icons.add),
                    onPressed: onIncrement,
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.xs),

            // Delete button
            IconButton(
              iconSize: 20,
              icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
              tooltip: AppConstants.delete,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic Card wrapper for form sections in CartPage.
class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Order type selector segment (Dine-in / Takeaway / Delivery).
class _OrderTypeSelector extends StatelessWidget {
  const _OrderTypeSelector({required this.orderType, required this.onChanged});

  final OrderType orderType;
  final ValueChanged<OrderType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<OrderType>(
        segments: const [
          ButtonSegment<OrderType>(
            value: OrderType.dineIn,
            icon: Icon(Icons.table_restaurant, size: 16),
            label: Text('تناول محلي', style: TextStyle(fontSize: 12)),
          ),
          ButtonSegment<OrderType>(
            value: OrderType.takeaway,
            icon: Icon(Icons.shopping_bag_outlined, size: 16),
            label: Text('سفري', style: TextStyle(fontSize: 12)),
          ),
          ButtonSegment<OrderType>(
            value: OrderType.delivery,
            icon: Icon(Icons.delivery_dining_outlined, size: 16),
            label: Text('توصيل', style: TextStyle(fontSize: 12)),
          ),
        ],
        selected: {orderType},
        onSelectionChanged: (Set<OrderType> selection) {
          if (selection.isNotEmpty) {
            onChanged(selection.first);
          }
        },
      ),
    );
  }
}

/// Payment method chips.
class _PaymentSelector extends StatelessWidget {
  const _PaymentSelector({
    required this.paymentMethod,
    required this.onChanged,
  });

  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PaymentChip(
            method: PaymentMethod.cash,
            icon: Icons.payments_outlined,
            label: AppConstants.paymentCash,
            isSelected: paymentMethod == PaymentMethod.cash,
            onTap: () => onChanged(PaymentMethod.cash),
          ),
          const SizedBox(width: AppSpacing.xs),
          _PaymentChip(
            method: PaymentMethod.card,
            icon: Icons.credit_card,
            label: AppConstants.paymentCard,
            isSelected: paymentMethod == PaymentMethod.card,
            onTap: () => onChanged(PaymentMethod.card),
          ),
          const SizedBox(width: AppSpacing.xs),
          _PaymentChip(
            method: PaymentMethod.wallet,
            icon: Icons.account_balance_wallet_outlined,
            label: AppConstants.paymentWallet,
            isSelected: paymentMethod == PaymentMethod.wallet,
            onTap: () => onChanged(PaymentMethod.wallet),
          ),
          const SizedBox(width: AppSpacing.xs),
          _PaymentChip(
            method: PaymentMethod.online,
            icon: Icons.language,
            label: AppConstants.paymentOnline,
            isSelected: paymentMethod == PaymentMethod.online,
            onTap: () => onChanged(PaymentMethod.online),
          ),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.method,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethod method;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: emphasized
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )
              : theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: emphasized
              ? theme.textTheme.titleLarge?.copyWith(
                  color: valueColor ?? colorScheme.primary,
                  fontWeight: FontWeight.w900,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: valueColor != null ? FontWeight.bold : null,
                ),
        ),
      ],
    );
  }
}

/// Sticky bottom checkout bar showing final total and large checkout button.
class _StickyCheckoutBar extends StatelessWidget {
  const _StickyCheckoutBar({
    required this.totalAmount,
    required this.placing,
    required this.onCheckout,
  });

  final double totalAmount;
  final bool placing;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الإجمالي للدفع',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(totalAmount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  icon: placing
                      ? const SizedBox.shrink()
                      : const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: placing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          AppConstants.checkout,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  onPressed: placing ? null : onCheckout,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
