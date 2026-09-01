import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../controllers/scheduled_order_controller.dart';

/// Bottom sheet for selecting an advance scheduled delivery or pickup time slot.
class ScheduleTimePickerSheet extends ConsumerStatefulWidget {
  const ScheduleTimePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ScheduleTimePickerSheet(),
    );
  }

  @override
  ConsumerState<ScheduleTimePickerSheet> createState() => _ScheduleTimePickerSheetState();
}

class _ScheduleTimePickerSheetState extends ConsumerState<ScheduleTimePickerSheet> {
  int _selectedDayOffset = 0; // 0 = Today, 1 = Tomorrow, 2 = After tomorrow
  TimeOfDay _selectedTime = const TimeOfDay(hour: 17, minute: 30);

  final List<TimeOfDay> _availableSlots = const [
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 13, minute: 30),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 17, minute: 30),
    TimeOfDay(hour: 18, minute: 0),
    TimeOfDay(hour: 19, minute: 0),
    TimeOfDay(hour: 20, minute: 0),
    TimeOfDay(hour: 21, minute: 0),
  ];

  DateTime _computeTargetDateTime() {
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: _selectedDayOffset));
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduledSlot = ref.watch(scheduledOrderControllerProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule_rounded, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text(
                    'تحديد موعد استلام الطلب',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              if (scheduledSlot != null)
                TextButton(
                  onPressed: () {
                    ref.read(scheduledOrderControllerProvider.notifier).clearSchedule();
                    Navigator.pop(context);
                  },
                  child: const Text('إلغاء الجدولة (الآن)', style: TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'اختر اليوم والوقت المستهدف وسيبدأ المطبخ الطهي قبله مباشرة لضمان وصول الوجبة طازجة وساخنة.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Divider(height: 24),

          // Day Selection
          const Text('اختر اليوم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDayChip('اليوم', 0),
              const SizedBox(width: 8),
              _buildDayChip('غداً', 1),
              const SizedBox(width: 8),
              _buildDayChip('بعد غد', 2),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Time Slots Selection
          const Text('اختر الوقت المفضل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSlots.map((slot) {
              final isSel = _selectedTime == slot;
              final hourFormatted = slot.hour.toString().padLeft(2, '0');
              final minFormatted = slot.minute.toString().padLeft(2, '0');
              final isPm = slot.hour >= 12;
              final displayPeriod = isPm ? 'م' : 'ص';

              return ChoiceChip(
                label: Text('$hourFormatted:$minFormatted $displayPeriod'),
                selected: isSel,
                onSelected: (val) {
                  if (val) setState(() => _selectedTime = slot);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final target = _computeTargetDateTime();
                ref.read(scheduledOrderControllerProvider.notifier).setSchedule(
                      targetDateTime: target,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تمت جدولة الطلب بنجاح في موعد: ${_selectedDayOffset == 0 ? "اليوم" : (_selectedDayOffset == 1 ? "غداً" : "بعد غد")} الساعة ${_selectedTime.format(context)}',
                    ),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('تأكيد موعد الجدولة', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(String label, int offset) {
    final isSelected = _selectedDayOffset == offset;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedDayOffset = offset);
      },
    );
  }
}
