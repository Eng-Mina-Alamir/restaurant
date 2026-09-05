import 'package:flutter/material.dart';

import '../../../config/constants.dart' show AppConstants;
import '../../../core/theme/spacing.dart';
import '../../../core/theme/status_colors.dart';
import '../animations/fade_slide_transition.dart';
import '../animations/floating_illustration.dart';

/// Consistent empty-state placeholder used across pages that list data.
///
/// Shows an icon with floating animation, a short [message], and an optional [actionLabel] that
/// triggers [onAction] (e.g. "العودة إلى القائمة").
///
/// HUMANIZE: prefer [title] + [subtitle] for a warm headline + explanation.
/// [message] stays as the legacy single-line fallback.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.title,
    this.subtitle,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Warm headline (e.g. "المطبخ هادئ الآن"). When set, [message] renders
  /// as the supporting subtitle unless [subtitle] overrides it.
  final String? title;
  final String? subtitle;

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
              if (title != null) ...[
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                subtitle ?? message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
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

/// Specialized empty state for Kitchen Display System (KDS).
///
/// Uses [HospitalityColors.herb] to communicate calm in the kitchen,
/// with two high-value actions: viewing recent completed tickets or refreshing.
class KdsEmptyState extends StatelessWidget {
  const KdsEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String message;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final herbColor = HospitalityColors.herb(theme.brightness);

    return Center(
      child: FadeSlideTransitionWidget(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingIllustration(
                distance: 8.0,
                duration: const Duration(milliseconds: 2400),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: herbColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sentiment_satisfied_alt_outlined,
                    size: 72,
                    color: herbColor,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ),
              if (primaryActionLabel != null || secondaryActionLabel != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (primaryActionLabel != null && onPrimaryAction != null)
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.history_rounded, size: 18),
                        onPressed: onPrimaryAction,
                        label: Text(primaryActionLabel!),
                      ),
                    if (secondaryActionLabel != null && onSecondaryAction != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        onPressed: onSecondaryAction,
                        label: Text(secondaryActionLabel!),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

