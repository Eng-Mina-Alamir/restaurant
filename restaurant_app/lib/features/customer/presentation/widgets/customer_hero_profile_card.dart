import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/haptics.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../controllers/customer_wallet_controller.dart';
import 'address_map_picker_sheet.dart';
import 'dine_in_table_hub_sheet.dart';

/// Luxury Hero Profile & Greeting Card displayed in the expanded SliverAppBar.
///
/// Integrates:
/// - Personalized time-aware greeting + customer name + avatar
/// - Active dining/delivery location pill with interactive switcher
/// - Quick loyalty tier & points pill (navigates to `/customer/loyalty`)
/// - Wallet balance pill (navigates to `/customer/gift-cards`)
class CustomerHeroProfileCard extends ConsumerWidget {
  const CustomerHeroProfileCard({
    super.key,
    this.compactMode = false,
  });

  /// When true, renders a slightly more compact vertical layout.
  final bool compactMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final activeTable = ref.watch(activeTableIdProvider);
    final orderType = ref.watch(selectedOrderTypeProvider);
    final deliveryAddress = ref.watch(selectedDeliveryAddressProvider);
    final walletBalance = ref.watch(customerWalletBalanceProvider);
    final points = ref.watch(customerLoyaltyPointsProvider);

    final greeting = _getGreetingMessage();
    final rawName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name.trim()
        : 'ضيفنا العزيز';
    final displayName = rawName.replaceAll(RegExp(r'\(.*?\)'), '').trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.85),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Greeting & Name + Dining/Delivery Location Pill
          Row(
            children: [
              // Interactive Avatar + Greeting & Name
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      AppHaptics.selectionTap();
                      _showAccountSummarySheet(context, ref, displayName, user?.email ?? 'customer@demo.local');
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          // Avatar with gradient border
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.tertiary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              backgroundColor: colorScheme.surface,
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '👤',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // Greeting & Customer Name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        greeting,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 13,
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // Dining / Delivery Service Mode Pill
              _ServiceModePill(
                activeTable: activeTable,
                orderType: orderType,
                deliveryAddress: deliveryAddress,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, thickness: 0.6),
          const SizedBox(height: AppSpacing.sm),

          // Bottom Row: Quick Loyalty Level + Wallet Balance Pills
          Row(
            children: [
              // 1. Loyalty Tier & Points Pill
              Expanded(
                child: _GlassStatPill(
                  icon: Icons.stars_rounded,
                  iconColor: const Color(0xFFF57C00),
                  title: 'نقاط الولاء',
                  value: '$points نقطة',
                  tooltip: 'عرض برنامج الولاء والمكافآت',
                  onTap: () {
                    AppHaptics.selectionTap();
                    context.push('/customer/loyalty');
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // 2. Wallet Balance Pill
              Expanded(
                child: _GlassStatPill(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF0F766E),
                  title: 'رصيد المحفظة',
                  value: '${walletBalance.toStringAsFixed(0)} ج.م',
                  tooltip: 'كروت الهدايا ورصيد المحفظة',
                  onTap: () {
                    AppHaptics.selectionTap();
                    context.push('/customer/gift-cards');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAccountSummarySheet(
    BuildContext context,
    WidgetRef ref,
    String name,
    String email,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '👤',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'عميل مميز 👑',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            ListTile(
              dense: true,
              leading: const Icon(Icons.receipt_long_rounded),
              title: const Text('سجل طلباتي'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/customer/orders');
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.event_seat_rounded),
              title: const Text('حجز طاولة مسبقاً'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/customer/reservations');
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.health_and_safety_rounded),
              title: const Text('الملف الصحي ومسببات الحساسية'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/customer/dietary-profile');
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.wallet_giftcard_rounded),
              title: const Text('كروت الهدايا والمحفظة الرقمية'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/customer/gift-cards');
              },
            ),
            const Divider(height: 16),
            ListTile(
              dense: true,
              leading: Icon(Icons.logout_rounded, color: colorScheme.error),
              title: Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'صباح الخير والبركة ☀️';
    } else if (hour >= 12 && hour < 17) {
      return 'نهارك سعيد ولذيذ 🍽️';
    } else {
      return 'مساء الخير والأنوار 🌙';
    }
  }
}

/// Compact glass stat pill for loyalty points & wallet balance.
class _GlassStatPill extends StatelessWidget {
  const _GlassStatPill({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      button: true,
      label: tooltip ?? '$title: $value',
      child: Tooltip(
        message: tooltip ?? title,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isRtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dining or Delivery Mode Pill indicating Table # or Delivery Address.
class _ServiceModePill extends ConsumerWidget {
  const _ServiceModePill({
    required this.activeTable,
    required this.orderType,
    required this.deliveryAddress,
  });

  final String? activeTable;
  final OrderType orderType;
  final String? deliveryAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isTable = activeTable != null;
    final label = isTable
        ? 'طاولة $activeTable'
        : (orderType == OrderType.delivery
            ? (deliveryAddress?.split('،').first ?? 'توصيل')
            : 'استلام سفري');

    final icon = isTable
        ? Icons.table_restaurant_rounded
        : (orderType == OrderType.delivery
            ? Icons.delivery_dining_rounded
            : Icons.shopping_bag_outlined);

    final bgAccent = isTable
        ? const Color(0xFF2E7D32)
        : (orderType == OrderType.delivery
            ? colorScheme.primary
            : const Color(0xFFD84315));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.selectionTap();
          _showServiceModeSelectorSheet(context, ref);
        },
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: bgAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: bgAccent.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: bgAccent),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: bgAccent,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: bgAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showServiceModeSelectorSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        final currentType = ref.watch(selectedOrderTypeProvider);
        final activeTable = ref.watch(activeTableIdProvider);
        final deliveryAddress = ref.watch(selectedDeliveryAddressProvider);

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'اختر نوع وطريقة استلام الطلب',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'حدد الطريقة المناسبة لك للاستمتاع بوجبتك',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),

                // 1. Delivery Option
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: currentType == OrderType.delivery
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    foregroundColor: currentType == OrderType.delivery
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    child: const Icon(Icons.delivery_dining_rounded),
                  ),
                  title: const Text('توصيل إلى موقعك', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    deliveryAddress != null && deliveryAddress.isNotEmpty
                        ? deliveryAddress
                        : 'انقر لتحديد عنوان التوصيل على الخريطة',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: currentType == OrderType.delivery
                      ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(selectedOrderTypeProvider.notifier).state = OrderType.delivery;
                    Navigator.of(sheetContext).pop();
                    AddressMapPickerSheet.show(context);
                  },
                ),

                const Divider(height: 1),

                // 2. Dine-in Option
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: currentType == OrderType.dineIn
                        ? const Color(0xFF2E7D32)
                        : colorScheme.surfaceContainerHighest,
                    foregroundColor: currentType == OrderType.dineIn
                        ? Colors.white
                        : colorScheme.onSurfaceVariant,
                    child: const Icon(Icons.table_restaurant_rounded),
                  ),
                  title: const Text('تناول في الصالة (محلي)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    activeTable != null && activeTable.isNotEmpty
                        ? 'طاولة رقم #${activeTable.replaceAll(RegExp(r'[^0-9]'), '')}'
                        : 'انقر لتحديد رقم الطاولة أو فتح مركز الصالة',
                  ),
                  trailing: currentType == OrderType.dineIn
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32))
                      : null,
                  onTap: () {
                    ref.read(selectedOrderTypeProvider.notifier).state = OrderType.dineIn;
                    Navigator.of(sheetContext).pop();
                    final tableNum = activeTable != null
                        ? (int.tryParse(activeTable.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1)
                        : 1;
                    DineInTableHubSheet.show(
                      context,
                      tableNumber: tableNum,
                      tableId: activeTable ?? 'table-1',
                    );
                  },
                ),

                const Divider(height: 1),

                // 3. Takeaway Option
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: currentType == OrderType.takeaway
                        ? const Color(0xFFD84315)
                        : colorScheme.surfaceContainerHighest,
                    foregroundColor: currentType == OrderType.takeaway
                        ? Colors.white
                        : colorScheme.onSurfaceVariant,
                    child: const Icon(Icons.shopping_bag_rounded),
                  ),
                  title: const Text('استلام من الفرع (سفري)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('تجهيز الطلب للاستلام الفوري من كاونتر المطعم'),
                  trailing: currentType == OrderType.takeaway
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFFD84315))
                      : null,
                  onTap: () {
                    ref.read(selectedOrderTypeProvider.notifier).state = OrderType.takeaway;
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تفعيل وضع الاستلام من الفرع (سفري) 🛍️'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
