import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../domain/entities/customer_dietary_entity.dart';
import '../controllers/customer_dietary_controller.dart';

/// Settings page for customer's food allergy preferences, health goals, and dietary alerts.
class CustomerDietaryProfilePage extends ConsumerWidget {
  const CustomerDietaryProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(customerDietaryControllerProvider);
    final controller = ref.read(customerDietaryControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الصحي والحساسية الغذائية'),
        actions: [
          TextButton(
            onPressed: () {
              controller.resetProfile();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت إعادة ضبط التفضيلات الصحية')),
              );
            },
            child: const Text('إعادة ضبط', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Top Banner ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.health_and_safety_rounded, color: Color(0xFF10B981), size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أمانك وسلامتك أولويتنا القصوى',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'حدد مسببات الحساسية ونمطك الغذائي لتحذيرك فوراً وتصفية قائمة الطعام بما يناسب صحتك.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Dietary Goals Section ─────────────────────────────────────
            Text(
              'الهدف والنمط الغذائي المفضل:',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DietaryGoal.values.map((goal) {
                final isSelected = profile.dietaryGoal == goal;
                return ChoiceChip(
                  label: Text(goal.labelAr),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primaryContainer,
                  onSelected: (val) {
                    if (val) controller.setDietaryGoal(goal);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Allergens Selection Section ───────────────────────────────
            Text(
              'مسببات الحساسية التي تتحسس منها (Allergens):',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'سنقوم بإظهار تنبيه أحمر فوري عند فتح أي طبق يحتوي على هذه المكونات.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.sm),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AllergenType.values.map((allergen) {
                final hasAllergy = profile.hasAllergyTo(allergen);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(allergen.iconEmoji),
                      const SizedBox(width: 6),
                      Text(allergen.labelAr),
                    ],
                  ),
                  selected: hasAllergy,
                  selectedColor: Colors.red.shade100,
                  checkmarkColor: Colors.red.shade900,
                  labelStyle: TextStyle(
                    color: hasAllergy ? Colors.red.shade900 : theme.colorScheme.onSurface,
                    fontWeight: hasAllergy ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: hasAllergy ? Colors.redAccent : theme.colorScheme.outlineVariant,
                  ),
                  onSelected: (_) => controller.toggleAllergen(allergen),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Strict Warnings Switch ────────────────────────────────────
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                title: const Text('تنبيهات الأمان الصارمة'),
                subtitle: const Text('إظهار نافذة تأكيد إضافية قبل إضافة أي طبق قد يتعارض مع حساسيتك.'),
                value: profile.strictAllergenAlerts,
                onChanged: controller.toggleStrictAlerts,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
