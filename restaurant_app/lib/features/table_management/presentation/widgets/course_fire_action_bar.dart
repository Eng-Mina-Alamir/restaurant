import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../controllers/table_controller.dart';
import '../../domain/entities/course_and_allergen_entity.dart';

/// Interactive action bar allowing waiters to sequence courses (Appetizer, Main, Dessert)
/// and send immediate "Fire" commands to the Kitchen Display System (KDS).
class CourseFireActionBar extends ConsumerStatefulWidget {
  const CourseFireActionBar({
    super.key,
    required this.tableId,
    required this.tableNumber,
    required this.orderId,
  });

  final String tableId;
  final int tableNumber;
  final String orderId;

  @override
  ConsumerState<CourseFireActionBar> createState() =>
      _CourseFireActionBarState();
}

class _CourseFireActionBarState extends ConsumerState<CourseFireActionBar> {
  CourseType _selectedCourse = CourseType.mainCourse;
  final Set<CourseType> _firedCourses = <CourseType>{CourseType.appetizer};

  void _fireCourse(CourseType course) {
    ref.read(tableControllerProvider.notifier).fireCourse(
      tableId: widget.tableId,
      orderId: widget.orderId,
      courseCode: course.code,
    );

    setState(() {
      _firedCourses.add(course);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔥 تم إرسال أمر طهي (${course.labelAr}) لطاولة ${widget.tableNumber} للمطبخ فوراً!',
        ),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFF97316),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'توقيت مراحل الطعام (Course Timing)',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'KDS Connected',
                  style: TextStyle(color: Color(0xFFF97316), fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Course selection pills
          Wrap(
            spacing: 8,
            children: CourseType.values.map((course) {
              final isFired = _firedCourses.contains(course);
              final isSelected = _selectedCourse == course;

              return ChoiceChip(
                label: Text(
                  isFired ? '${course.labelAr} (تم الإرسال 🔥)' : course.labelAr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isFired ? Colors.white : (isSelected ? Colors.white : Colors.white70),
                    fontWeight: isFired ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selectedColor: isFired ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                backgroundColor: const Color(0xFF334155),
                selected: isSelected || isFired,
                onSelected: (_) {
                  setState(() => _selectedCourse = course);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // Fire Action Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: Text(
                'إرسال أمر طهي (${_selectedCourse.labelAr}) للمطبخ الآن 🔥',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () => _fireCourse(_selectedCourse),
            ),
          ),
        ],
      ),
    );
  }
}
