import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../domain/entities/purchase_order_entity.dart';
import '../controllers/purchase_order_controller.dart';

/// Supplier Purchase Orders & Goods Receiving Station for Restaurant Managers.
class PurchaseOrdersPage extends ConsumerWidget {
  const PurchaseOrdersPage({super.key});

  void _showCreatePODialog(BuildContext context, WidgetRef ref) {
    final supplierCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final itemNameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '10');
    final priceCtrl = TextEditingController(text: '100');
    String unit = 'كجم';

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF3B82F6), size: 24),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Text(
                          'إنشاء أمر شراء مورد جديد (Purchase Order)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),

                    TextField(
                      controller: supplierCtrl,
                      decoration: InputDecoration(
                        labelText: 'اسم المورد / الشركة *',
                        prefixIcon: const Icon(Icons.store_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم هاتف المورد',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    const Text('الصنف المطلوب توريده:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: itemNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'اسم المادة الخام (مثال: صدور دجاج متبلة)',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'الكمية المطلوبة',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: unit,
                            decoration: InputDecoration(
                              labelText: 'الوحدة',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'كجم', child: Text('كيلوجرام (كجم)')),
                              DropdownMenuItem(value: 'لتر', child: Text('لتر')),
                              DropdownMenuItem(value: 'كرتونة', child: Text('كرتونة')),
                              DropdownMenuItem(value: 'قطعة', child: Text('قطعة')),
                            ],
                            onChanged: (v) => setState(() => unit = v ?? 'كجم'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'السعر التقديري',
                              suffixText: 'ج.م',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                            onPressed: () {
                              final supplier = supplierCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();
                              final item = itemNameCtrl.text.trim();
                              final qty = double.tryParse(qtyCtrl.text.trim()) ?? 10.0;
                              final price = double.tryParse(priceCtrl.text.trim()) ?? 100.0;

                              if (supplier.isEmpty || item.isEmpty) return;

                              ref.read(purchaseOrderControllerProvider.notifier).createPO(
                                    supplierName: supplier,
                                    supplierPhone: phone.isEmpty ? '01000000000' : phone,
                                    items: [
                                      POItem(
                                        ingredientId: 'ing-${DateTime.now().millisecondsSinceEpoch}',
                                        ingredientName: item,
                                        unit: unit,
                                        orderedQuantity: qty,
                                        estimatedUnitPrice: price,
                                      ),
                                    ],
                                  );

                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم إصدار أمر الشراء وإرساله للمورد بنجاح ✅'),
                                  backgroundColor: Color(0xFF3B82F6),
                                ),
                              );
                            },
                            icon: const Icon(Icons.send_rounded),
                            label: const Text('إصدار وإرسال أمر الشراء'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReceiveDialog(BuildContext context, WidgetRef ref, PurchaseOrderEntity po) {
    final invoiceCtrl = TextEditingController();
    final actualPriceCtrl = TextEditingController(
      text: po.items.isNotEmpty ? po.items.first.estimatedUnitPrice.toStringAsFixed(0) : '0',
    );
    final receivedQtyCtrl = TextEditingController(
      text: po.items.isNotEmpty ? po.items.first.orderedQuantity.toStringAsFixed(0) : '0',
    );

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.fact_check_rounded, color: Color(0xFF10B981), size: 24),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('فحص واستلام أمر الشراء #${po.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(po.supplierName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),

                TextField(
                  controller: invoiceCtrl,
                  decoration: InputDecoration(
                    labelText: 'رقم فاتورة المورد *',
                    prefixIcon: const Icon(Icons.receipt_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                TextField(
                  controller: receivedQtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'الكمية المستلمة فعلياً بالمخزن',
                    suffixText: po.items.isNotEmpty ? po.items.first.unit : '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                TextField(
                  controller: actualPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'سعر الوحدة الفعلي بالفاتورة (ج.م)',
                    suffixText: 'ج.م',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        onPressed: () {
                          final inv = invoiceCtrl.text.trim();
                          if (inv.isEmpty) return;

                          final rQty = double.tryParse(receivedQtyCtrl.text.trim()) ?? 0.0;
                          final aPrice = double.tryParse(actualPriceCtrl.text.trim()) ?? 0.0;

                          final updatedItems = po.items.map((it) {
                            return it.copyWith(
                              receivedQuantity: rQty > 0 ? rQty : it.orderedQuantity,
                              actualUnitPrice: aPrice > 0 ? aPrice : it.estimatedUnitPrice,
                            );
                          }).toList();

                          ref.read(purchaseOrderControllerProvider.notifier).markReceived(
                                poId: po.id,
                                supplierInvoiceNumber: inv,
                                receivedItems: updatedItems,
                              );

                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم استلام البضائع وزيادة أرصدة المخزون آلياً ✅'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('تأكيد الاستلام بالمخزن'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final poState = ref.watch(purchaseOrderControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('أوامر الشراء والموردين (Purchase Orders)'),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () => _showCreatePODialog(context, ref),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('أمر شراء جديد'),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── 1. Top Procurement Stats ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إجمالي مشتريات المخزون:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatCurrency(poState.totalActualSpend),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('طلبات قيد التوريد:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${poState.activePendingOrders.length} أوامر نشطة',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 2. Purchase Orders List ──────────────────────────────────────
            Text(
              'قائمة أوامر الشراء الصادرة للموردين (${poState.orders.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: poState.orders.length,
              separatorBuilder: (ctx, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final po = poState.orders[index];
                final isReceived = po.status == POStatus.received;

                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isReceived ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '#${po.id} • ${po.supplierName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isReceived ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              po.status.labelAr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isReceived ? const Color(0xFF15803D) : const Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'الأصناف: ${po.items.map((i) => "${i.ingredientName} (${i.orderedQuantity} ${i.unit})").join(" • ")}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'التكلفة الإجمالية: ${Formatters.formatCurrency(isReceived ? po.totalActualCost : po.totalEstimatedCost)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          if (!isReceived)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              onPressed: () => _showReceiveDialog(context, ref, po),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('فحص واستلام', style: TextStyle(fontSize: 12)),
                            )
                          else if (po.supplierInvoiceNumber != null)
                            Text(
                              'فاتورة مورد: #${po.supplierInvoiceNumber}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
