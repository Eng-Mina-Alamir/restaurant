import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../menu/domain/entities/menu_item.dart';

/// A single menu item card with dish thumbnails, availability badges,
/// preparation time, rating and an add-to-cart affordance with tactile micro-interactions.
class MenuItemTile extends StatelessWidget {
  const MenuItemTile({super.key, required this.item, this.onTap, this.onAdd});

  final MenuItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

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
    final hasModifiers = item.modifierGroups.isNotEmpty;
    final isPopular = (item.orderCount ?? 0) > 200;

    return AnimatedPressCard(
      onTap: item.isAvailable ? onTap : null,
      color: item.isAvailable
          ? theme.cardTheme.color
          : colorScheme.surfaceContainerHighest.withValues(alpha: .5),
      borderRadius: AppRadius.md,
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dish Thumbnail / Leading Visual ──────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    AppImageUtils.buildOptimizedImage(
                      imageUrl: item.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      placeholder: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      errorWidget: Icon(
                        _getCategoryPlaceholderIcon(item.categoryId),
                        size: 38,
                        color: colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    )
                  else
                    Icon(
                      _getCategoryPlaceholderIcon(item.categoryId),
                      size: 38,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  if (item.isVegetarian)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: StatusColors.tone(SemanticTone.success, theme.brightness),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // ── Details Column ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: item.isAvailable
                                ? null
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (item.isVegetarian)
                        const _Badge(
                          AppConstants.dietVegetarian,
                          tone: SemanticTone.success,
                        ),
                      if (item.isSpicy)
                        const _Badge(
                          AppConstants.dietSpicy,
                          tone: SemanticTone.danger,
                        ),
                      if (!item.isAvailable)
                        const _Badge(
                          AppConstants.itemUnavailable,
                          tone: SemanticTone.neutral,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: item.isAvailable
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.outline,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Metadata row: price + rating + prep time / popular tag
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        Formatters.formatCurrency(item.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: item.isAvailable
                              ? colorScheme.primary
                              : colorScheme.outline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.rating != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: StatusColors.tone(
                                SemanticTone.warning,
                                theme.brightness,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.rating!.toStringAsFixed(1),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      if (item.preparationTime != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${item.preparationTime!.toInt()} دقيقة',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      if (isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            '🔥 مميز',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.deepOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // ── Add Button ──────────────────────────────────────────
            IconButton.filled(
              icon: const Icon(Icons.add),
              tooltip: hasModifiers
                  ? AppConstants.customizeOrder
                  : AppConstants.addToCart,
              style: IconButton.styleFrom(
                backgroundColor: item.isAvailable
                    ? (hasModifiers ? colorScheme.secondaryContainer : colorScheme.primary)
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: item.isAvailable
                    ? (hasModifiers ? colorScheme.onSecondaryContainer : colorScheme.onPrimary)
                    : colorScheme.outline,
              ),
              onPressed: item.isAvailable ? onAdd : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.tone = SemanticTone.success});

  final String label;
  final SemanticTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = StatusColors.tone(tone, theme.brightness);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
