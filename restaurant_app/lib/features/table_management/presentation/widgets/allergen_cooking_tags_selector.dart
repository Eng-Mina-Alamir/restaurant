import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../domain/entities/course_and_allergen_entity.dart';

/// Modal bottom sheet for assigning seat numbers, courses, cooking tags, and allergen alerts to a cart item.
class AllergenCookingTagsSelector extends StatefulWidget {
  const AllergenCookingTagsSelector({
    super.key,
    required this.itemName,
    this.initialSeatNumber = 1,
    this.initialCourse = CourseType.mainCourse,
    this.initialCookingTags = const [],
    this.initialAllergens = const [],
    required this.onSave,
  });

  final String itemName;
  final int initialSeatNumber;
  final CourseType initialCourse;
  final List<String> initialCookingTags;
  final List<AllergenType> initialAllergens;
  final void Function({
    required int seatNumber,
    required CourseType course,
    required List<String> cookingTags,
    required List<AllergenType> allergens,
    required String customNote,
  }) onSave;

  static Future<void> show(
    BuildContext context, {
    required String itemName,
    int initialSeatNumber = 1,
    CourseType initialCourse = CourseType.mainCourse,
    List<String> initialCookingTags = const [],
    List<AllergenType> initialAllergens = const [],
    required void Function({
      required int seatNumber,
      required CourseType course,
      required List<String> cookingTags,
      required List<AllergenType> allergens,
      required String customNote,
    }) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => AllergenCookingTagsSelector(
            itemName: itemName,
            initialSeatNumber: initialSeatNumber,
            initialCourse: initialCourse,
            initialCookingTags: initialCookingTags,
            initialAllergens: initialAllergens,
            onSave: onSave,
          ),
    );
  }

  @override
  State<AllergenCookingTagsSelector> createState() =>
      _AllergenCookingTagsSelectorState();
}

class _AllergenCookingTagsSelectorState
    extends State<AllergenCookingTagsSelector> {
  late int _seatNumber;
  late CourseType _course;
  late Set<String> _selectedCookingTags;
  late Set<AllergenType> _selectedAllergens;
  final TextEditingController _customNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _seatNumber = widget.initialSeatNumber;
    _course = widget.initialCourse;
    _selectedCookingTags = Set<String>.from(widget.initialCookingTags);
    _selectedAllergens = Set<AllergenType>.from(widget.initialAllergens);
  }

  @override
  void dispose() {
    _customNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            children: [
              const Icon(
                Icons.room_service_outlined,
                color: Color(0xFF3B82F6),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'تخصيص المقعد والمرحلة وملاحظات المطبخ',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),

          // 1. Seat Number Selector
          const Text(
            '🪑 رقم المقعد (Seat Number):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(8, (i) {
                final seat = i + 1;
                final isSelected = _seatNumber == seat;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text('مقعد #$seat'),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _seatNumber = seat),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Course Stage Selector
          const Text(
            '⏱️ مرحلة التقديم (Course):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children:
                CourseType.values.map((c) {
                  final isSelected = _course == c;
                  return ChoiceChip(
                    label: Text(c.labelAr),
                    selected: isSelected,
                    selectedColor: const Color(0xFFF97316),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _course = c),
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),

          // 3. Allergen Critical Flags
          const Row(
            children: [
              Text(
                '⚠️ تحذير حساسية الطعام (Allergen Flags):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children:
                AllergenType.values.map((alg) {
                  final isSelected = _selectedAllergens.contains(alg);
                  return FilterChip(
                    label: Text(alg.labelAr),
                    selected: isSelected,
                    selectedColor: const Color(
                      0xFFEF4444,
                    ).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFFEF4444),
                    side: BorderSide(
                      color:
                          isSelected
                              ? const Color(0xFFEF4444)
                              : Colors.grey.withValues(alpha: 0.3),
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedAllergens.add(alg);
                        } else {
                          _selectedAllergens.remove(alg);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),

          // 4. Quick Cooking Tags
          const Text(
            '👨‍🍳 ملاحظات الطهي السريعة (1-Tap Cooking Tags):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children:
                CookingTag.defaultTags.map((tag) {
                  final isSelected = _selectedCookingTags.contains(tag.labelAr);
                  return FilterChip(
                    label: Text('${tag.icon} ${tag.labelAr}'),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primaryContainer,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCookingTags.add(tag.labelAr);
                        } else {
                          _selectedCookingTags.remove(tag.labelAr);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),

          // 5. Custom Note
          TextField(
            controller: _customNoteController,
            decoration: const InputDecoration(
              hintText: 'ملاحظة خاصة إضافية للشيف...',
              prefixIcon: Icon(Icons.edit_note),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          // Save Button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              'حفظ التخصيصات وإضافتها للبون',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              widget.onSave(
                seatNumber: _seatNumber,
                course: _course,
                cookingTags: _selectedCookingTags.toList(),
                allergens: _selectedAllergens.toList(),
                customNote: _customNoteController.text.trim(),
              );
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
