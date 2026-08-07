import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/spacing.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../menu/domain/entities/menu_item.dart';

/// Bottom sheet allowing the customer to pick modifiers for [menuItem] and add
/// the configured product to the cart.
class MenuItemDetailSheet extends ConsumerStatefulWidget {
  const MenuItemDetailSheet({super.key, required this.menuItem});

  final MenuItem menuItem;

  /// Shows the sheet from [context] and returns when dismissed.
  static Future<void> show(BuildContext context, MenuItem menuItem) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MenuItemDetailSheet(menuItem: menuItem),
    );
  }

  @override
  ConsumerState<MenuItemDetailSheet> createState() =>
      _MenuItemDetailSheetState();
}

class _MenuItemDetailSheetState extends ConsumerState<MenuItemDetailSheet> {
  final Map<String, String?> _selectedOptionByGroup = {};
  final Set<String> _checkedOptionIds = {};
  final TextEditingController _notesController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.menuItem;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          top: AppSpacing.sm,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (item.isVegetarian || item.isSpicy || !item.isAvailable)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (item.isVegetarian)
                        const _DetailBadge(
                          icon: Icons.eco,
                          label: AppConstants.dietVegetarian,
                        ),
                      if (item.isSpicy)
                        const _DetailBadge(
                          icon: Icons.local_fire_department,
                          label: AppConstants.dietSpicy,
                        ),
                      if (!item.isAvailable)
                        const _DetailBadge(
                          icon: Icons.block,
                          label: AppConstants.itemUnavailable,
                          isError: true,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                Formatters.formatCurrency(_unitPrice(item) * _quantity),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (item.modifierGroups.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                ...item.modifierGroups.map(_buildGroup),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: AppConstants.specialNotesLabel,
                  hintText: AppConstants.specialNotesHint,
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _QuantityStepper(
                    quantity: _quantity,
                    onDecrement: () => setState(() {
                      if (_quantity > 1) _quantity--;
                    }),
                    onIncrement: () => setState(() => _quantity++),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _canSubmit ? _addToCart : null,
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text(AppConstants.addToCart),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSubmit {
    for (final group in widget.menuItem.modifierGroups) {
      if (group.isRequired) {
        final selected = _selectedOptionByGroup[group.id];
        if (selected == null) return false;
      }
    }
    return true;
  }

  double _unitPrice(MenuItem item) {
    final extras = _checkedOptionIds.fold<double>(
      0,
      (sum, id) => sum + _extraPriceOf(id),
    );
    return item.price + extras;
  }

  double _extraPriceOf(String optionId) {
    for (final group in widget.menuItem.modifierGroups) {
      for (final option in group.options) {
        if (option.id == optionId) return option.extraPrice;
      }
    }
    return 0;
  }

  void _addToCart() {
    final selectedOptions = widget.menuItem.modifierGroups
        .map(
          (g) => g.options
              .where(
                (o) =>
                    _selectedOptionByGroup[g.id] == o.id ||
                    _checkedOptionIds.contains(o.id),
              )
              .toList(),
        )
        .expand((list) => list)
        .toList();

    ref
        .read(cartControllerProvider.notifier)
        .addItem(
          CartItem(
            menuItem: widget.menuItem,
            quantity: _quantity,
            selectedModifiers: selectedOptions,
            specialNotes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
        );
    Navigator.of(context).pop();
  }

  /// Renders a modifier group as radio/checkbox rows plus a counter.
  Widget _buildGroup(MenuModifierGroup group) {
    final single = group.maxSelection <= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text(
              group.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (group.isRequired) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppConstants.requiredField,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        if (group.description != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            group.description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        ...group.options.map((option) {
          final selectedSingle = _selectedOptionByGroup[group.id] == option.id;
          final selectedMulti = _checkedOptionIds.contains(option.id);
          return CheckboxListTile(
            dense: true,
            value: single ? selectedSingle : selectedMulti,
            title: Text(
              option.extraPrice > 0
                  ? '${option.name} (+${Formatters.formatCurrency(option.extraPrice)})'
                  : option.name,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: single
                ? (_) => setState(() {
                    _selectedOptionByGroup[group.id] = selectedSingle
                        ? null
                        : option.id;
                  })
                : (_) => setState(() {
                    if (selectedMulti) {
                      _checkedOptionIds.remove(option.id);
                    } else if (_checkedOptionIds.length < group.maxSelection) {
                      _checkedOptionIds.add(option.id);
                    }
                  }),
          );
        }),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          icon: const Icon(Icons.remove),
          onPressed: onDecrement,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '$quantity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.outlined(
          icon: const Icon(Icons.add),
          onPressed: onIncrement,
        ),
      ],
    );
  }
}

/// Small pill shown in the detail sheet for dietary/availability attributes.
class _DetailBadge extends StatelessWidget {
  const _DetailBadge({
    required this.icon,
    required this.label,
    this.isError = false,
  });

  final IconData icon;
  final String label;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    final background = isError
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.secondaryContainer;
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      labelStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: color),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
