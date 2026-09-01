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
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '👤',
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
                    Text(
                      greeting,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
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
                    Icons.chevron_left_rounded,
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
          if (isTable) {
            final tableNum =
                int.tryParse(activeTable!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
            DineInTableHubSheet.show(
              context,
              tableNumber: tableNum,
              tableId: activeTable!,
            );
          } else if (orderType == OrderType.delivery) {
            AddressMapPickerSheet.show(context);
          }
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
}
