import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/haptics.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../controllers/customer_wallet_controller.dart';
import '../pages/qr_scan_page.dart';

/// Single Story Item Model for Telegram-style quick action tray.
class StoryActionItem {
  const StoryActionItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.badgeText,
    this.showBadge = false,
    this.badgeColor,
    this.isActive = false,
    this.tooltip,
  });

  final String id;
  final String label;
  final Widget icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final String? badgeText;
  final bool showBadge;
  final Color? badgeColor;
  final bool isActive;
  final String? tooltip;
}

/// Telegram-style Stories Action Tray that expands when pulled down or tapped.
class TelegramStoriesActionsBar extends ConsumerWidget {
  const TelegramStoriesActionsBar({
    super.key,
    required this.animationProgress,
  });

  /// Progress from 0.0 (fully collapsed) to 1.0 (fully expanded).
  final double animationProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (animationProgress <= 0.01) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeTable = ref.watch(activeTableIdProvider);
    final brightness = theme.brightness;
    final themeMode = ref.watch(themeModeControllerProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && brightness == Brightness.dark);

    final cartItems = ref.watch(cartControllerProvider);
    final cartUnitCount = cartItems.fold<int>(0, (sum, i) => sum + i.quantity);
    final walletBalance = ref.watch(customerWalletBalanceProvider);

    final stories = <StoryActionItem>[
      // 1. Dark / Light Mode Switch
      StoryActionItem(
        id: 'theme',
        label: isDark ? 'نهاري' : 'ليلي',
        tooltip: 'تبديل المظهر',
        gradientColors: isDark
            ? const [Color(0xFFFFA000), Color(0xFFFFD54F)]
            : const [Color(0xFF303F9F), Color(0xFF7986CB)],
        icon: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          size: 22,
          color: isDark ? const Color(0xFFFFA000) : const Color(0xFF3949AB),
        ),
        onTap: () {
          AppHaptics.selectionTap();
          ref.read(themeModeControllerProvider.notifier).toggleTheme(brightness);
        },
      ),

      // 2. Table QR Scanner
      StoryActionItem(
        id: 'qr_table',
        label: activeTable != null ? 'طاولة $activeTable' : 'مسح QR',
        tooltip: activeTable != null ? 'طاولة رقم $activeTable' : 'مسح QR الطاولة',
        isActive: activeTable != null,
        showBadge: activeTable != null,
        badgeText: activeTable != null ? '✓' : null,
        badgeColor: const Color(0xFF2E7D32),
        gradientColors: activeTable != null
            ? const [Color(0xFF2E7D32), Color(0xFF66BB6A)]
            : const [Color(0xFF00838F), Color(0xFF4DD0E1)],
        icon: Icon(
          activeTable != null ? Icons.table_restaurant_rounded : Icons.qr_code_scanner_rounded,
          size: 22,
          color: activeTable != null ? const Color(0xFF2E7D32) : const Color(0xFF00838F),
        ),
        onTap: () {
          AppHaptics.selectionTap();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QrScanPage()),
          );
        },
      ),

      // 2b. Table Reservation
      StoryActionItem(
        id: 'reservations',
        label: 'حجز طاولة',
        tooltip: 'حجز طاولة مسبقاً في المطعم',
        gradientColors: const [Color(0xFF0D9488), Color(0xFF2DD4BF)],
        icon: const Icon(
          Icons.event_seat_rounded,
          size: 22,
          color: Color(0xFF0D9488),
        ),
        onTap: () {
          AppHaptics.selectionTap();
          context.push('/customer/reservations');
        },
      ),

      // 3. Loyalty & Rewards Points
      StoryActionItem(
        id: 'loyalty',
        label: 'المكافآت',
        tooltip: 'برنامج الولاء والمكافآت',
        gradientColors: const [Color(0xFFF57C00), Color(0xFFFFB74D)],
        icon: const Icon(
          Icons.stars_rounded,
          size: 24,
          color: Color(0xFFF57C00),
        ),
        onTap: () {
          AppHaptics.selectionTap();
          context.push('/customer/loyalty');
        },
      ),

      // 4. Order History
      StoryActionItem(
        id: 'orders',
        label: 'الطلبات',
        tooltip: AppConstants.orderHistoryTitle,
        gradientColors: const [Color(0xFF1565C0), Color(0xFF64B5F6)],
        icon: const Icon(
          Icons.receipt_long_rounded,
          size: 22,
          color: Color(0xFF1565C0),
        ),
        onTap: () {
          AppHaptics.selectionTap();
          context.push('/customer/orders');
        },
      ),

      // 5. Notifications
      StoryActionItem(
        id: 'notifications',
        label: 'التنبيهات',
        tooltip: 'الإشعارات والتنبيهات',
        gradientColors: const [Color(0xFF6A1B9A), Color(0xFFBA68C8)],
        icon: const Icon(
          Icons.notifications_active_rounded,
          size: 22,
          color: Color(0xFF6A1B9A),
        ),
        onTap: () {
          AppHaptics.selectionTap();
          context.push('/notifications');
        },
      ),

      // 6. Shopping Cart
      StoryActionItem(
        id: 'cart',
        label: 'السلة',
        tooltip: AppConstants.cartTitle,
        showBadge: cartUnitCount > 0,
        badgeText: '$cartUnitCount',
        gradientColors: const [Color(0xFFD84315), Color(0xFFFF8A65)],
        icon: const Icon(
          Icons.shopping_cart_rounded,
          size: 22,
          color: Color(0xFFD84315),
        ),
        onTap: () {
          AppHaptics.selectionTap();
          context.push('/customer/cart');
        },
      ),

      // 7. Group Order
      StoryActionItem(
        id: 'group_order',
        label: 'طلب جماعي',
        tooltip: 'غرفة الطلب الجماعي ومشاركة السلة',
        gradientColors: const [Color(0xFFC2410C), Color(0xFFFB923C)],
        icon: const Icon(
          Icons.groups_rounded,
          size: 24,
          color: Color(0xFFC2410C),
        ),
        onTap: () {
          AppHaptics.selectionTap();
          context.push('/customer/group-order');
        },
      ),

      // 8. Gift Cards & Wallet
      StoryActionItem(
        id: 'gift_cards',
        label: walletBalance > 0 ? 'المحفظة' : 'كروت هدايا',
        tooltip: 'بطاقات الهدايا ومحفظة الرصيد',
        showBadge: walletBalance > 0,
        badgeText: walletBalance > 0 ? '${walletBalance.toInt()}ج' : null,
        badgeColor: const Color(0xFF0F766E),
        gradientColors: const [Color(0xFF0F766E), Color(0xFF5EEAD4)],
        icon: const Icon(
          Icons.account_balance_wallet_rounded,
          size: 22,
          color: Color(0xFF0F766E),
        ),
        onTap: () {
          AppHaptics.selectionTap();
          context.push('/customer/gift-cards');
        },
      ),

      // 9. Dietary & Allergens Health Profile
      StoryActionItem(
        id: 'dietary',
        label: 'ملف صحي',
        tooltip: 'الحساسية الغذائية والأنظمة الصحية',
        gradientColors: const [Color(0xFF059669), Color(0xFF34D399)],
        icon: const Icon(
          Icons.health_and_safety_rounded,
          size: 22,
          color: Color(0xFF059669),
        ),
        onTap: () {
          AppHaptics.selectionTap();
          context.push('/customer/dietary-profile');
        },
      ),

      // 10. Logout
      StoryActionItem(
        id: 'logout',
        label: 'خروج',
        tooltip: AppConstants.logout,
        gradientColors: const [Color(0xFFC2185B), Color(0xFFF06292)],
        icon: const Icon(
          Icons.logout_rounded,
          size: 22,
          color: Color(0xFFC2185B),
        ),
        onTap: () async {
          AppHaptics.selectionTap();
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('تسجيل الخروج'),
              content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(AppConstants.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('خروج'),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            final messenger = ScaffoldMessenger.of(context);
            await ref.read(authControllerProvider.notifier).logout();
            messenger.showSnackBar(
              const SnackBar(content: Text(AppConstants.logoutMessage)),
            );
          }
        },
      ),
    ];

    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: animationProgress.clamp(0.0, 1.0),
        child: Opacity(
          opacity: animationProgress.clamp(0.0, 1.0),
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < stories.length; i++) ...[
                    _StoryActionCircle(item: stories[i]),
                    if (i < stories.length - 1)
                      const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular Telegram-style Story Icon with Gradient Ring & Label.
class _StoryActionCircle extends StatelessWidget {
  const _StoryActionCircle({required this.item});

  final StoryActionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: item.tooltip ?? item.label,
      child: Tooltip(
        message: item.tooltip ?? item.label,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Story Avatar with Gradient Ring
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Outer Gradient Ring (Telegram style)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: item.gradientColors,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: item.gradientColors.first.withValues(alpha: 0.25),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2), // Ring thickness
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surface,
                        ),
                        child: Center(
                          child: item.icon,
                        ),
                      ),
                    ),

                    // Badge counter / indicator
                    if (item.showBadge && item.badgeText != null)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: item.badgeColor ?? colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            item.badgeText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),

                // Story Label
                SizedBox(
                  width: 52,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10.5,
                      fontWeight: item.isActive ? FontWeight.bold : FontWeight.w600,
                      color: item.isActive
                          ? colorScheme.primary
                          : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
