import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/haptics.dart';
import '../../domain/entities/subscription_plan.dart';

/// Modal dialog showing the available SaaS plans and allowing the manager to switch/upgrade.
class UpgradePlanDialog extends ConsumerStatefulWidget {
  const UpgradePlanDialog({super.key, this.currentTier = SubscriptionTier.pro});

  final SubscriptionTier currentTier;

  static Future<void> show(BuildContext context, {SubscriptionTier? currentTier}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => UpgradePlanDialog(
        currentTier: currentTier ?? SubscriptionTier.pro,
      ),
    );
  }

  @override
  ConsumerState<UpgradePlanDialog> createState() => _UpgradePlanDialogState();
}

class _UpgradePlanDialogState extends ConsumerState<UpgradePlanDialog> {
  late SubscriptionTier _selectedTier = widget.currentTier;
  String _currency = 'ج.م';
  final bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.workspace_premium_rounded,
                color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'باقات الاشتراك والترقية السحابية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('عرض الأسعار بعملة:'),
                  DropdownButton<String>(
                    value: _currency,
                    items: const [
                      DropdownMenuItem(value: 'ج.م', child: Text('جنيه مصري (EGP)')),
                      DropdownMenuItem(value: 'ر.س', child: Text('ريال سعودي (SAR)')),
                      DropdownMenuItem(value: '\$', child: Text('دولار أمريكي (USD)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _currency = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _PlanSelectTile(
                tier: SubscriptionTier.starter,
                isSelected: _selectedTier == SubscriptionTier.starter,
                currency: _currency,
                onTap: () => setState(() => _selectedTier = SubscriptionTier.starter),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PlanSelectTile(
                tier: SubscriptionTier.pro,
                isPopular: true,
                isSelected: _selectedTier == SubscriptionTier.pro,
                currency: _currency,
                onTap: () => setState(() => _selectedTier = SubscriptionTier.pro),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PlanSelectTile(
                tier: SubscriptionTier.enterprise,
                isSelected: _selectedTier == SubscriptionTier.enterprise,
                currency: _currency,
                onTap: () => setState(() => _selectedTier = SubscriptionTier.enterprise),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _saving
              ? null
              : () {
                  AppHaptics.actionSuccess();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم اختيار ${_selectedTier.nameAr} بنجاح!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
          icon: const Icon(Icons.check_rounded),
          label: const Text('تأكيد واشتراك'),
        ),
      ],
    );
  }
}

class _PlanSelectTile extends StatelessWidget {
  const _PlanSelectTile({
    required this.tier,
    required this.isSelected,
    required this.currency,
    required this.onTap,
    this.isPopular = false,
  });

  final SubscriptionTier tier;
  final bool isSelected;
  final String currency;
  final VoidCallback onTap;
  final bool isPopular;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = SubscriptionEntitlements.getTierHighlights(tier);

    final priceStr = currency == 'ر.س'
        ? '${tier.priceSar} ر.س / شهرياً'
        : currency == '\$'
            ? '\$${tier.priceUsd} / month'
            : '${tier.priceEgp} ج.م / شهرياً';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
              : theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tier.nameAr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'الأكثر اختياراً',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              priceStr,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            for (final p in points.take(2))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
