import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/coupon_entity.dart';
import '../controllers/coupon_controller.dart';

class CouponManagementPage extends ConsumerWidget {
  const CouponManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(couponManagementControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الكوبونات وأكواد الخصم'),
        actions: [
          IconButton(
            tooltip: 'إضافة كوبون جديد',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showCouponModal(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCouponModal(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('إنشاء كوبون'),
      ),
      body: couponsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(AppConstants.errorWithDetail(err))),
        data: (coupons) {
          if (coupons.isEmpty) {
            return const EmptyState(
              message: 'لا توجد كوبونات مضافة حالياً',
              icon: Icons.local_offer_outlined,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              80,
            ),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              final isExpired =
                  coupon.validUntil != null &&
                  DateTime.now().isAfter(coupon.validUntil!);

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  coupon.code,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: colorScheme.primary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              if (!coupon.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'معطل',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (isExpired)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'منتهي',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'نشط',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showCouponModal(context, ref, coupon: coupon);
                              } else if (val == 'toggle') {
                                ref
                                    .read(
                                      couponManagementControllerProvider
                                          .notifier,
                                    )
                                    .updateCoupon(
                                      coupon.copyWith(
                                        isActive: !coupon.isActive,
                                      ),
                                    );
                              } else if (val == 'delete') {
                                _confirmDelete(context, ref, coupon);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      coupon.isActive
                                          ? Icons.block
                                          : Icons.check_circle_outline,
                                      size: 18,
                                      color: coupon.isActive
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(coupon.isActive ? 'تعطيل' : 'تفعيل'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('تعديل'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      AppConstants.delete,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        coupon.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        coupon.discountType == CouponDiscountType.percentage
                            ? 'خصم ${coupon.discountValue}% (حد أقصى ${coupon.maxDiscountAmount ?? 'غير محدد'} ريال)'
                            : 'خصم ثابت ${coupon.discountValue} ريال',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'حد أدنى للطلب: ${coupon.minOrderAmount} ريال',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          if (coupon.validUntil != null) ...[
                            Icon(
                              Icons.event_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ينتهي: ${Formatters.formatDate(coupon.validUntil!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'الاستخدام: ${coupon.usageCount} ${coupon.usageLimit != null ? '/ ${coupon.usageLimit}' : 'مرات'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCouponModal(
    BuildContext context,
    WidgetRef ref, {
    CouponEntity? coupon,
  }) {
    final codeCtrl = TextEditingController(text: coupon?.code ?? '');
    final titleCtrl = TextEditingController(text: coupon?.title ?? '');
    final valueCtrl = TextEditingController(
      text: coupon?.discountValue.toString() ?? '20',
    );
    final minOrderCtrl = TextEditingController(
      text: coupon?.minOrderAmount.toString() ?? '50',
    );
    final maxDiscountCtrl = TextEditingController(
      text: coupon?.maxDiscountAmount?.toString() ?? '30',
    );
    final usageLimitCtrl = TextEditingController(
      text: coupon?.usageLimit?.toString() ?? '100',
    );
    CouponDiscountType discountType =
        coupon?.discountType ?? CouponDiscountType.percentage;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      coupon == null ? 'إنشاء كود خصم جديد' : 'تعديل كود الخصم',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'كود الخصم (مثال: SAVE20) *',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان العرض أو الوصف *',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<CouponDiscountType>(
                  initialValue: discountType,
                  items: CouponDiscountType.values
                      .map(
                        (t) =>
                            DropdownMenuItem(value: t, child: Text(t.labelAr)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => discountType = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'نوع الخصم *',
                    prefixIcon: Icon(Icons.percent),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: discountType == CouponDiscountType.percentage
                        ? 'نسبة الخصم (%) *'
                        : 'قيمة الخصم الثابتة (ريال) *',
                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: minOrderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الحد الأدنى للطلب (ريال)',
                    prefixIcon: Icon(Icons.shopping_cart_outlined),
                  ),
                ),
                if (discountType == CouponDiscountType.percentage) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: maxDiscountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الحد الأقصى للخصم (ريال)',
                      prefixIcon: Icon(Icons.vertical_align_top),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: usageLimitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الحد الأقصى لمرات الاستخدام',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () async {
                    final code = codeCtrl.text.trim().toUpperCase();
                    final title = titleCtrl.text.trim();
                    final value = double.tryParse(valueCtrl.text.trim()) ?? 0.0;
                    final minOrder =
                        double.tryParse(minOrderCtrl.text.trim()) ?? 0.0;
                    final maxDiscount = double.tryParse(
                      maxDiscountCtrl.text.trim(),
                    );
                    final usageLimit = int.tryParse(usageLimitCtrl.text.trim());

                    if (code.isEmpty || title.isEmpty || value <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى ملء جميع الحقول الإلزامية'),
                        ),
                      );
                      return;
                    }

                    final newCoupon = CouponEntity(
                      id:
                          coupon?.id ??
                          'cpn-${DateTime.now().millisecondsSinceEpoch}',
                      code: code,
                      title: title,
                      discountType: discountType,
                      discountValue: value,
                      minOrderAmount: minOrder,
                      maxDiscountAmount: maxDiscount,
                      validUntil: DateTime.now().add(const Duration(days: 30)),
                      usageLimit: usageLimit,
                      usageCount: coupon?.usageCount ?? 0,
                      isActive: coupon?.isActive ?? true,
                    );

                    final controller = ref.read(
                      couponManagementControllerProvider.notifier,
                    );
                    final err = coupon == null
                        ? await controller.createCoupon(newCoupon)
                        : await controller.updateCoupon(newCoupon);

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  },
                  child: Text(coupon == null ? 'إنشاء الكود' : 'حفظ التعديلات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CouponEntity coupon,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الكود'),
        content: Text('هل أنت متأكد من حذف كود الخصم "${coupon.code}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppConstants.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref
                  .read(couponManagementControllerProvider.notifier)
                  .deleteCoupon(coupon.id);
              Navigator.pop(ctx);
            },
            child: const Text(AppConstants.delete),
          ),
        ],
      ),
    );
  }
}
