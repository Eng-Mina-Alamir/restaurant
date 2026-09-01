import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';

/// Horizontal, scrollable set of category filter chips with visual emojis.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final all = [kAllCategoriesFilter, ...categories];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: all.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = all[index];
          final isSelected = category == selected;
          final label = category == kAllCategoriesFilter
              ? AppConstants.dietAll
              : category;

          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }
}
