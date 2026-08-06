import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/spacing.dart';
import '../../../menu/domain/entities/menu_item.dart';

/// A single menu item card with availability badges, price and an add-to-cart
/// affordance.
class MenuItemTile extends StatelessWidget {
  const MenuItemTile({super.key, required this.item, this.onTap, this.onAdd});

  final MenuItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasModifiers = item.modifierGroups.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                            ),
                          ),
                        ),
                        if (item.isVegetarian) const _Badge('نباتي'),
                        if (item.isSpicy)
                          const _Badge('حار', color: Colors.red),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      Formatters.formatCurrency(item.price),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                icon: const Icon(Icons.add),
                tooltip: hasModifiers ? 'تخصيص الطلب' : 'أضف إلى السلة',
                onPressed: onAdd,
              ),
            ],
          ),
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
