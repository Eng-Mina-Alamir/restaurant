import 'package:flutter/material.dart';

import '../../../config/constants.dart' show AppConstants;
import '../../../core/theme/spacing.dart';
import '../animations/fade_slide_transition.dart';
import '../animations/floating_illustration.dart';

/// Consistent empty-state placeholder used across pages that list data.
///
/// Shows an icon with floating animation, a short [message], and an optional [actionLabel] that
/// triggers [onAction] (e.g. "العودة إلى القائمة").
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: FadeSlideTransitionWidget(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingIllustration(
                distance: 8.0,
                duration: const Duration(milliseconds: 2200),
                child: Icon(
                  icon,
                  size: 56,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience: the generic "no orders yet" empty state.
class EmptyOrdersState extends StatelessWidget {
  const EmptyOrdersState({super.key, this.onAction});

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: AppConstants.emptyOrders,
      icon: Icons.receipt_long_outlined,
      actionLabel: onAction != null ? AppConstants.backToMenu : null,
      onAction: onAction,
    );
  }
}
