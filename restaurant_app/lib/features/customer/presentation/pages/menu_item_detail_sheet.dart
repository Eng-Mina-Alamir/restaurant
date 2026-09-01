import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../ratings/domain/entities/rating_entity.dart';
import '../../../ratings/presentation/widgets/rating_dialog.dart';
import '../controllers/customer_dietary_controller.dart';

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
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

  static const List<String> _quickNotes = [
    'بدون بصل 🧅',
    'صوص جانبي 🥣',
    'حار إضافي 🌶️',
    'بدون ملح 🧂',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  static IconData _getCategoryIcon(String categoryId) {
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
    final item = widget.menuItem;
    final totalPrice = _unitPrice(item) * _quantity;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          top: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Hero Visual Header ────────────────────────────────
                    Container(
                      height: 85,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer.withValues(alpha: 0.7),
                            colorScheme.secondaryContainer.withValues(alpha: 0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(item.categoryId),
                          size: 48,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // ── Title and Diet Badges ──────────────────────────────
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
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
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

                    // ── Allergen Conflict Alert ───────────────────────────
                    Builder(
                      builder: (context) {
                        final dietaryProfile = ref.watch(customerDietaryControllerProvider);
                        final allergenService = ref.watch(allergenSafetyServiceProvider);
                        final conflicts = allergenService.detectAllergenConflicts(
                          itemName: item.name,
                          profile: dietaryProfile,
                        );

                        if (conflicts.isEmpty) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.only(top: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'تنبيه أمان: هذا الصنف يحتوي على (${conflicts.map((a) => a.labelAr).join("، ")}) المسجلة في ملفك الصحي!',
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // ── Price & Rating Card ───────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'السعر الأساسي',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(totalPrice),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: Icon(
                              Icons.star_rounded,
                              color: StatusColors.starRating(theme.brightness),
                              size: 22,
                            ),
                            label: Text(
                              '${item.rating ?? 4.8} (تقييم الوجبة)',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              RatingDialog.show(
                                context,
                                targetId: item.id,
                                targetType: RatingTargetType.menuItem,
                                title: 'تقييم وجبة ${item.name}',
                                subtitle: 'ما رأيك في المذاق والجودة؟',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs + 2),

                    // ── Nutritional Facts & Calories Row ──────────────────
                    Builder(
                      builder: (context) {
                        final allergenService = ref.watch(allergenSafetyServiceProvider);
                        final macros = allergenService.getNutritionalFactsForItem(item.id, item.name);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _MacroStat(label: 'سعرة', value: '${macros.calories}', icon: '⚡'),
                              _MacroStat(label: 'بروتين', value: '${macros.proteinGrams.toInt()}g', icon: '🥩'),
                              _MacroStat(label: 'كارب', value: '${macros.carbsGrams.toInt()}g', icon: '🍞'),
                              _MacroStat(label: 'دهون', value: '${macros.fatGrams.toInt()}g', icon: '🧈'),
                            ],
                          ),
                        );
                      },
                    ),

                    // ── Modifier Groups ───────────────────────────────────
                    if (item.modifierGroups.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ...item.modifierGroups.map(_buildGroup),
                    ],

                    const SizedBox(height: AppSpacing.sm),

                    // ── Special Instructions with quick chips ────────────
                    Text(
                      AppConstants.specialNotesLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _quickNotes.map((note) {
                          final cleanNote = note.split(' ').first;
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                            child: ActionChip(
                              label: Text(note, style: const TextStyle(fontSize: 12)),
                              onPressed: () {
                                final current = _notesController.text.trim();
                                if (current.isEmpty) {
                                  _notesController.text = cleanNote;
                                } else if (!current.contains(cleanNote)) {
                                  _notesController.text = '$current، $cleanNote';
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: AppConstants.specialNotesHint,
                        prefixIcon: const Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Sticky Bottom Action Row (Stepper + CTA) ──────────
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
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text(
                      AppConstants.addToCart,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit {
    if (!widget.menuItem.isAvailable) return false;
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
    final singleExtras = _selectedOptionByGroup.values.fold<double>(
      0,
      (sum, id) => sum + (id != null ? _extraPriceOf(id) : 0),
    );
    return item.price + extras + singleExtras;
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

  /// Renders a modifier group as radio/checkbox rows.
  Widget _buildGroup(MenuModifierGroup group) {
    final single = group.maxSelection <= 1;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: group.isRequired && _selectedOptionByGroup[group.id] == null
              ? colorScheme.error.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (group.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    AppConstants.requiredField,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Text(
                  'اختياري (حتى ${group.maxSelection})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
            ],
          ),
          if (group.description != null) ...[
            const SizedBox(height: 2),
            Text(
              group.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          ...group.options.map((option) {
            final selectedSingle = _selectedOptionByGroup[group.id] == option.id;
            final selectedMulti = _checkedOptionIds.contains(option.id);
            final isChosen = single ? selectedSingle : selectedMulti;

            final priceBadge = option.extraPrice > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      '+${Formatters.formatCurrency(option.extraPrice)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  )
                : null;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isChosen
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: single
                  ? ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      leading: Icon(
                        isChosen
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isChosen
                            ? colorScheme.primary
                            : colorScheme.outline,
                        size: 20,
                      ),
                      title: Text(
                        option.name,
                        style: TextStyle(
                          fontWeight:
                              isChosen ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: priceBadge,
                      onTap: () => setState(() {
                        _selectedOptionByGroup[group.id] = isChosen
                            ? (group.isRequired ? option.id : null)
                            : option.id;
                      }),
                    )
                  : CheckboxListTile(
                      dense: true,
                      value: isChosen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      title: Text(
                        option.name,
                        style: TextStyle(
                          fontWeight:
                              isChosen ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      secondary: priceBadge,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (_) => setState(() {
                        if (selectedMulti) {
                          _checkedOptionIds.remove(option.id);
                        } else if (_checkedOptionIds.length <
                            group.maxSelection) {
                          _checkedOptionIds.add(option.id);
                        }
                      }),
                    ),
            );
          }),
        ],
      ),
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: quantity > 1 ? onDecrement : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              '$quantity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

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
    final theme = Theme.of(context);
    final color = isError
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  const _MacroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

