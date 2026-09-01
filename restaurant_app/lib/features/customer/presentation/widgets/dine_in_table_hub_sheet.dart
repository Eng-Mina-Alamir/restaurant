import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../table_management/domain/entities/table_service_request.dart';
import '../../../table_management/presentation/controllers/table_service_controller.dart';

/// Interactive Table Service Hub for Dine-In customers seated at a table.
class DineInTableHubSheet extends ConsumerStatefulWidget {
  const DineInTableHubSheet({
    super.key,
    required this.tableNumber,
    required this.tableId,
  });

  final int tableNumber;
  final String tableId;

  static Future<void> show(BuildContext context, {required int tableNumber, required String tableId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DineInTableHubSheet(
        tableNumber: tableNumber,
        tableId: tableId,
      ),
    );
  }

  @override
  ConsumerState<DineInTableHubSheet> createState() => _DineInTableHubSheetState();
}

class _DineInTableHubSheetState extends ConsumerState<DineInTableHubSheet> {
  final _noteController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _sendServiceRequest(TableServiceType type, {String? customNote}) async {
    setState(() => _sending = true);
    final note = customNote ?? (type == TableServiceType.cleanTable ? 'تنظيف وترتيب الطاولة' : null);

    try {
      await ref.read(tableServiceControllerProvider.notifier).requestService(
            tableId: widget.tableId,
            tableNumber: widget.tableNumber,
            type: type,
            note: note,
          );
      setState(() => _sending = false);
      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال طلبك لطاقم الصالة لطاولة #${widget.tableNumber}، الويتر في طريقه إليك!',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (_) {
      setState(() => _sending = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء إرسال الطلب، يرجى المحاولة ثانية.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SingleChildScrollView(
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2410C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.table_restaurant_rounded, color: Color(0xFFC2410C)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'خدمات طاولة رقم #${widget.tableNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'اضغط على الخدمة المطلوبة ليصلك الويتر فوراً',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24),

          // Action Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _ServiceActionCard(
                icon: Icons.person_pin_rounded,
                color: const Color(0xFFC2410C),
                title: 'استدعاء الويتر',
                subtitle: 'حضور كابتن الصالة',
                onTap: _sending ? null : () => _sendServiceRequest(TableServiceType.callWaiter),
              ),
              _ServiceActionCard(
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF0284C7),
                title: 'طلب الفاتورة',
                subtitle: 'طباعة الحساب والدفع',
                onTap: _sending ? null : () => _sendServiceRequest(TableServiceType.requestBill),
              ),
              _ServiceActionCard(
                icon: Icons.cleaning_services_rounded,
                color: const Color(0xFF10B981),
                title: 'تنظيف الطاولة',
                subtitle: 'مسح الطاولة وإزالة الأطباق',
                onTap: _sending ? null : () => _sendServiceRequest(TableServiceType.cleanTable),
              ),
              _ServiceActionCard(
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF8B5CF6),
                title: 'ماء ومناديل',
                subtitle: 'طلب مياه ومستلزمات',
                onTap: _sending
                    ? null
                    : () => _sendServiceRequest(
                          TableServiceType.other,
                          customNote: 'طلب ماء ومناديل إضافية للطاولة',
                        ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    ),
  );
  }
}

class _ServiceActionCard extends StatelessWidget {
  const _ServiceActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
