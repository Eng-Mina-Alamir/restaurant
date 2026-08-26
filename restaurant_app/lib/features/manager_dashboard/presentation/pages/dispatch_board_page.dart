import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../delivery/domain/entities/driver_info.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../controllers/dispatch_controller.dart';

/// Manager's manual dispatch fallback board.
///
/// Lists delivery orders that the auto-assign flow could not dispatch (no
/// driver free at "ready" time) or whose assignment FAILED, and lets the
/// manager hand-pick an available driver — completing the hybrid
/// (auto + manual) dispatch promise.
class DispatchBoardPage extends ConsumerWidget {
  const DispatchBoardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBoard = ref.watch(dispatchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التوصيل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () =>
                ref.read(dispatchControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: asyncBoard.when(
        loading: () => const _DispatchBoardSkeleton(),
        error: (error, _) => ErrorState(
          message: 'حدث خطأ في تحميل لوحة التوصيل',
          errorDetail: error,
          onRetry: () =>
              ref.read(dispatchControllerProvider.notifier).refresh(),
        ),
        data: (board) => RefreshIndicator(
          onRefresh: ref.read(dispatchControllerProvider.notifier).refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (board.errorMessage != null) ...[
                _ErrorBanner(message: board.errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Undispatched orders ──────────────────────────────────────
              _SectionHeader(
                title: 'طلبات بانتظار سواق',
                count: board.undispatchedOrders.length,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (board.undispatchedOrders.isEmpty)
                const EmptyState(
                  message: 'لا توجد طلبات بانتظار سواق',
                  icon: Icons.inbox_outlined,
                )
              else
                for (final order in board.undispatchedOrders)
                  _OrderDispatchCard(
                    order: order,
                    drivers: board.availableDrivers,
                  ),

              const SizedBox(height: AppSpacing.lg),

              // ── Failed assignments (reassignable) ────────────────────────
              _SectionHeader(
                title: 'إعادة تعيين (فشل سابق)',
                count: board.failedAssignments.length,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (board.failedAssignments.isEmpty)
                const EmptyState(
                  message: 'لا توجد تكليفات فاشلة',
                  icon: Icons.inbox_outlined,
                )
              else
                for (final entry in board.failedAssignments)
                  _OrderDispatchCard(
                    order: entry.order,
                    drivers: board.availableDrivers,
                    failedDriverId: entry.assignment.driverId,
                  ),

              if (board.availableDrivers.isEmpty &&
                  (board.undispatchedOrders.isNotEmpty ||
                      board.failedAssignments.isNotEmpty)) ...[
                const SizedBox(height: AppSpacing.lg),
                const _ErrorBanner(message: 'لا يوجد سائقون متاحون حالياً'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: AppSpacing.xs),
        Chip(
          label: Text('$count'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

// ── Loading skeleton ─────────────────────────────────────────────────────────

/// Shimmer placeholder mirroring the board while orders load: section header
/// rows with stacked order-card placeholders (title + status pill, address
/// line, trailing assign button).
class _DispatchBoardSkeleton extends StatelessWidget {
  const _DispatchBoardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Undispatched orders ──
        const _SectionHeaderSkeleton(),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < 3; i++) const _OrderCardSkeleton(),

        const SizedBox(height: AppSpacing.lg),

        // ── Failed assignments ──
        const _SectionHeaderSkeleton(),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < 2; i++) const _OrderCardSkeleton(),
      ],
    );
  }
}

/// Shimmer stand-in for a `_SectionHeader`: title bar plus count chip.
class _SectionHeaderSkeleton extends StatelessWidget {
  const _SectionHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonBox(width: 150, height: 18, borderRadius: AppRadius.sm),
        SizedBox(width: AppSpacing.xs),
        SkeletonBox(width: 36, height: 26, borderRadius: AppRadius.full),
      ],
    );
  }
}

/// Shimmer stand-in for one `_OrderDispatchCard`.
class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SkeletonBox(
                    width: double.infinity,
                    height: 14,
                    borderRadius: AppRadius.xs,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                SkeletonBox(width: 64, height: 24, borderRadius: AppRadius.full),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            SkeletonBox(width: 200, height: 12, borderRadius: AppRadius.xs),
            SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SkeletonBox(
                width: 120,
                height: 40,
                borderRadius: AppRadius.full,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // Error identity is conveyed visually by the error-container color and
    // warning icon; name it for screen readers and announce it live when the
    // banner appears while the board is open.
    return Semantics(
      label: 'خطأ: $message',
      liveRegion: true,
      excludeSemantics: true,
      child: Material(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDispatchCard extends ConsumerWidget {
  const _OrderDispatchCard({
    required this.order,
    required this.drivers,
    this.failedDriverId,
  });

  final OrderEntity order;
  final List<DriverInfo> drivers;

  /// Set when this card represents a FAILED assignment being re-dispatched.
  final String? failedDriverId;

  Future<void> _openDriverPicker(BuildContext context, WidgetRef ref) async {
    final driverId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: drivers.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('لا يوجد سائقون متاحون حالياً'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      'اختر سائقاً',
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                  for (final driver in drivers)
                    ListTile(
                      leading: const Icon(Icons.delivery_dining),
                      title: Text(driver.name),
                       subtitle: Row(
                         children: [
                           Icon(
                             Icons.star_rounded,
                             size: 16,
                             color: StatusColors.tone(
                               SemanticTone.warning,
                               Theme.of(sheetContext).brightness,
                             ),
                           ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(driver.rating.toStringAsFixed(1)),
                        ],
                      ),
                      trailing: Chip(
                        label: Text('${driver.activeAssignments} نشطة'),
                        visualDensity: VisualDensity.compact,
                      ),
                      onTap: () => Navigator.of(sheetContext).pop(driver.id),
                    ),
                ],
              ),
      ),
    );

    if (driverId == null || !context.mounted) return;

    final ok = await ref
        .read(dispatchControllerProvider.notifier)
        .assignDriver(order.id, driverId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'تم تعيين السائق بنجاح' : 'فشل تعيين السائق، حاول مرة أخرى',
        ),
        backgroundColor: ok
            ? StatusColors.tone(
                SemanticTone.success,
                Theme.of(context).brightness,
              )
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  static String _shortId(String id) =>
      id.length <= 8 ? id : '${id.substring(0, 8)}…';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    Formatters.formatOrderId(order.id),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Chip(
                  label: Text(order.status.labelAr),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    (order.deliveryAddress?.isNotEmpty ?? false)
                        ? order.deliveryAddress!
                        : 'بدون عنوان',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (failedDriverId != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: StatusColors.tone(
                      SemanticTone.warning,
                      Theme.of(context).brightness,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'فشل التكليف السابق (${_shortId(failedDriverId!)})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                icon: const Icon(Icons.local_shipping_rounded, size: 18),
                label: const Text('تعيين سواق'),
                onPressed: () => _openDriverPicker(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
