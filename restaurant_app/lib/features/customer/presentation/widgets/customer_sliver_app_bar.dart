import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import 'telegram_stories_actions_bar.dart';

/// Luxury SliverAppBar for the Customer Account & Home interface.
///
/// Combines:
/// - Pinned frosted-glass toolbar with Brand Logo and Quick Actions Hub
/// - Telegram-style expandable quick actions tray in the bottom slot
class CustomerSliverAppBar extends ConsumerWidget {
  const CustomerSliverAppBar({
    super.key,
    required this.storiesAnimation,
    required this.storiesController,
    required this.onToggleStories,
  });

  final Animation<double> storiesAnimation;
  final AnimationController storiesController;
  final VoidCallback onToggleStories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: colorScheme.surface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AppConstants.menuTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          CustomerQuickActionsHubButton(
            animation: storiesAnimation,
            onTap: onToggleStories,
          ),
        ],
      ),
      bottom: storiesController.value > 0.01
          ? PreferredSize(
              preferredSize: Size.fromHeight(storiesController.value * 82),
              child: TelegramStoriesActionsBar(
                animationProgress: storiesAnimation.value,
              ),
            )
          : null,
    );
  }
}

/// Compact Quick Actions Hub Button in AppBar with badge and expand indicator.
class CustomerQuickActionsHubButton extends ConsumerWidget {
  const CustomerQuickActionsHubButton({
    super.key,
    required this.animation,
    required this.onTap,
  });

  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cartItems = ref.watch(cartControllerProvider);
    final cartCount = cartItems.fold<int>(0, (sum, i) => sum + i.quantity);
    final activeTable = ref.watch(activeTableIdProvider);

    return Semantics(
      button: true,
      label: 'الإجراءات والخدمات السريعة',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: animation.value > 0.5
                  ? colorScheme.primaryContainer.withValues(alpha: 0.85)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: animation.value > 0.5
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: animation.value > 0.5
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: animation.value > 0.5
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  'الخدمات',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: animation.value > 0.5
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                if (cartCount > 0) ...[
                  const SizedBox(width: 5),
                  Badge(
                    label: Text('$cartCount'),
                    backgroundColor: colorScheme.primary,
                  ),
                ] else if (activeTable != null) ...[
                  const SizedBox(width: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                const SizedBox(width: 3),
                RotationTransition(
                  turns: Tween<double>(begin: 0.0, end: 0.5).animate(animation),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
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
