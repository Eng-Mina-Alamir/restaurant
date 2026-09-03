import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/offline_queue_service.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';

/// Stale data banner displayed on operational staff screens (KDS, Waiter, Cashier)
/// when the device is disconnected from Supabase and operating on a local cached mirror.
class StaleDataBanner extends ConsumerWidget {
  const StaleDataBanner({
    super.key,
    required this.lastUpdated,
    this.onRetry,
  });

  final DateTime lastUpdated;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final formattedTime = Formatters.formatTime(lastUpdated);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.amber.shade400, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: Colors.amber.shade900,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بيانات غير محدثة — آخر تحديث: $formattedTime (وضع عدم الاتصال)',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (pendingCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'يوجد $pendingCount عملية بانتظار المزامنة التلقائية عند عودة الاتصال',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('إعادة المحاولة'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber.shade900,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
