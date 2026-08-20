import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../menu/domain/entities/menu_item.dart';

/// A single menu item card with availability badges, price and an add-to-cart
/// affordance with tactile micro-interactions.
class MenuItemTile extends StatelessWidget {
  const MenuItemTile({super.key, required this.item, this.onTap, this.onAdd});

  final MenuItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasModifiers = item.modifierGroups.isNotEmpty;

    return AnimatedPressCard(
      onTap: item.isAvailable ? onTap : null,
      color: item.isAvailable
          ? theme.cardTheme.color
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
      borderRadius: AppRadius.md,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (item.isVegetarian)
                        const _Badge(AppConstants.dietVegetarian),
                      if (item.isSpicy)
                        const _Badge(
                          AppConstants.dietSpicy,
                          color: Colors.red,
                        ),
                      if (!item.isAvailable)
                        const _Badge(
                          AppConstants.itemUnavailable,
                          color: Colors.grey,
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
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Text(
                        Formatters.formatCurrency(item.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: item.isAvailable
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.rating != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item.rating!.toStringAsFixed(1),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              icon: const Icon(Icons.add),
              tooltip: hasModifiers
                  ? AppConstants.customizeOrder
                  : AppConstants.addToCart,
              onPressed: item.isAvailable ? onAdd : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.color = Colors.green});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
