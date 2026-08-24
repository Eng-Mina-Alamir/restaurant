import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';

/// Types of discount that can be configured.
enum DiscountType {
  percentage, // نسبة مئوية مثل 10%
  fixedAmount, // مبلغ ثابت مثل 20 ر.س
  coupon, // كوبون بكود مخصص
}

/// Represents a discount rule in the system.
class DiscountEntity {
  const DiscountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.isActive,
    this.couponCode,
    this.minOrderAmount,
    this.expiresAt,
  });

  final String id;
  final String name;
  final DiscountType type;
  final double value;
  final bool isActive;
  final String? couponCode;
  final double? minOrderAmount;
  final DateTime? expiresAt;

  String get displayValue {
    switch (type) {
      case DiscountType.percentage:
        return '${value.toStringAsFixed(0)}%';
      case DiscountType.fixedAmount:
        return Formatters.formatCurrency(value);
      case DiscountType.coupon:
        return '${value.toStringAsFixed(0)}% (كوبون)';
    }
  }

  String get typeLabel {
    switch (type) {
      case DiscountType.percentage:
        return 'نسبة مئوية';
      case DiscountType.fixedAmount:
        return 'مبلغ ثابت';
      case DiscountType.coupon:
        return 'كوبون';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case DiscountType.percentage:
        return Icons.percent_rounded;
      case DiscountType.fixedAmount:
        return Icons.attach_money_rounded;
      case DiscountType.coupon:
        return Icons.confirmation_number_outlined;
    }
  }
}

// ── Mock data ──────────────────────────────────────────────────────────────────

final _mockDiscounts = [
  const DiscountEntity(
    id: 'disc-1',
    name: 'خصم الأحد',
    type: DiscountType.percentage,
    value: 15,
    isActive: true,
    minOrderAmount: 50,
  ),
  const DiscountEntity(
    id: 'disc-2',
    name: 'خصم الطلب الأول',
    type: DiscountType.fixedAmount,
    value: 20,
    isActive: true,
  ),
  DiscountEntity(
    id: 'disc-3',
    name: 'عرض رمضان',
    type: DiscountType.coupon,
    value: 25,
    isActive: false,
    couponCode: 'RAMADAN25',
    expiresAt: DateTime(2026, 12, 31),
  ),
  const DiscountEntity(
    id: 'disc-4',
    name: 'خصم العملاء الجدد',
    type: DiscountType.percentage,
    value: 10,
    isActive: true,
    minOrderAmount: 0,
  ),
];

// ── Provider ──────────────────────────────────────────────────────────────────

final discountsProvider = StateProvider<List<DiscountEntity>>(
  (ref) => _mockDiscounts,
);

// ── Page ──────────────────────────────────────────────────────────────────────

/// Manager page for viewing, creating, and toggling discount rules.
class DiscountsPage extends ConsumerStatefulWidget {
  const DiscountsPage({super.key});

  @override
  ConsumerState<DiscountsPage> createState() => _DiscountsPageState();
}

class _DiscountsPageState extends ConsumerState<DiscountsPage> {
  @override
  Widget build(BuildContext context) {
    final discounts = ref.watch(discountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الخصومات والعروض')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDiscount(context),
        icon: const Icon(Icons.add),
        label: const Text('خصم جديد'),
      ),
      body: discounts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text('لا توجد خصومات بعد'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                100,
              ),
              itemCount: discounts.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) =>
                  _DiscountCard(discount: discounts[i], index: i),
            ),
    );
  }

  void _showAddDiscount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _AddDiscountDialog(),
    );
  }
}

// ── Discount card ─────────────────────────────────────────────────────────────

class _DiscountCard extends ConsumerWidget {
  const _DiscountCard({required this.discount, required this.index});

  final DiscountEntity discount;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = discount.isActive;

    return Card(
      elevation: isActive ? 2 : 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Icon(
            discount.typeIcon,
            color: isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          discount.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isActive ? null : colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(discount.typeLabel),
            if (discount.couponCode != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  discount.couponCode!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onTertiaryContainer,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              discount.displayValue,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch(
              value: isActive,
              onChanged: (val) {
                final discounts = List<DiscountEntity>.from(
                  ref.read(discountsProvider),
                );
                discounts[index] = DiscountEntity(
                  id: discount.id,
                  name: discount.name,
                  type: discount.type,
                  value: discount.value,
                  isActive: val,
                  couponCode: discount.couponCode,
                  minOrderAmount: discount.minOrderAmount,
                  expiresAt: discount.expiresAt,
                );
                ref.read(discountsProvider.notifier).state = discounts;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Discount dialog ───────────────────────────────────────────────────────

class _AddDiscountDialog extends ConsumerStatefulWidget {
  const _AddDiscountDialog();

  @override
  ConsumerState<_AddDiscountDialog> createState() => _AddDiscountDialogState();
}

class _AddDiscountDialogState extends ConsumerState<_AddDiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  DiscountType _type = DiscountType.percentage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final newDiscount = DiscountEntity(
      id: 'disc-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      type: _type,
      value: double.tryParse(_valueCtrl.text.trim()) ?? 0,
      isActive: true,
      couponCode: _type == DiscountType.coupon ? _codeCtrl.text.trim() : null,
    );
    final current = List<DiscountEntity>.from(ref.read(discountsProvider));
    current.add(newDiscount);
    ref.read(discountsProvider.notifier).state = current;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة خصم جديد'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم الخصم'),
              validator: (v) => v == null || v.isEmpty ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<DiscountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'نوع الخصم'),
              items: const [
                DropdownMenuItem(
                  value: DiscountType.percentage,
                  child: Text('نسبة مئوية'),
                ),
                DropdownMenuItem(
                  value: DiscountType.fixedAmount,
                  child: Text('مبلغ ثابت'),
                ),
                DropdownMenuItem(
                  value: DiscountType.coupon,
                  child: Text('كوبون'),
                ),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _valueCtrl,
              decoration: InputDecoration(
                labelText: _type == DiscountType.percentage
                    ? 'النسبة (%)'
                    : 'المبلغ (ر.س)',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'القيمة مطلوبة' : null,
            ),
            if (_type == DiscountType.coupon) ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(labelText: 'كود الكوبون'),
                validator: (v) => v == null || v.isEmpty ? 'الكود مطلوب' : null,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppConstants.cancel),
        ),
        FilledButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }
}
