import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';

/// Performance record for a single staff member.
class StaffPerformance {
  const StaffPerformance({
    required this.id,
    required this.name,
    required this.role,
    required this.ordersHandled,
    required this.avgResponseMinutes,
    required this.rating,
    required this.tablesServed,
  });

  final String id;
  final String name;
  final String role;
  final int ordersHandled;
  final double avgResponseMinutes;
  final double rating;
  final int tablesServed;

  String get ratingDisplay => rating.toStringAsFixed(1);

  Color ratingColor(ColorScheme cs) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.orange;
    return cs.error;
  }
}

// ── Mock data ──────────────────────────────────────────────────────────────────

final _mockStaff = [
  const StaffPerformance(
    id: 'staff-1',
    name: 'أحمد محمد',
    role: 'نادل',
    ordersHandled: 47,
    avgResponseMinutes: 4.2,
    rating: 4.8,
    tablesServed: 18,
  ),
  const StaffPerformance(
    id: 'staff-2',
    name: 'سارة خالد',
    role: 'نادل',
    ordersHandled: 35,
    avgResponseMinutes: 5.8,
    rating: 4.2,
    tablesServed: 14,
  ),
  const StaffPerformance(
    id: 'staff-3',
    name: 'محمد عبد الله',
    role: 'موظف مطبخ',
    ordersHandled: 82,
    avgResponseMinutes: 7.1,
    rating: 4.6,
    tablesServed: 0,
  ),
  const StaffPerformance(
    id: 'staff-4',
    name: 'فاطمة أحمد',
    role: 'سائق توصيل',
    ordersHandled: 23,
    avgResponseMinutes: 25.4,
    rating: 4.9,
    tablesServed: 0,
  ),
];

// ── Provider ──────────────────────────────────────────────────────────────────

final staffPerformanceProvider = Provider<List<StaffPerformance>>(
  (ref) => _mockStaff,
);

// ── Page ──────────────────────────────────────────────────────────────────────

/// Manager page for monitoring staff performance metrics.
class StaffPerformancePage extends ConsumerWidget {
  const StaffPerformancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final staff = ref.watch(staffPerformanceProvider);

    final topPerformer = staff.reduce((a, b) => a.rating >= b.rating ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('أداء الموظفين')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Top performer banner
          _TopPerformerBanner(
            performer: topPerformer,
            colorScheme: colorScheme,
            theme: theme,
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'تفاصيل الأداء',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          ...staff.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _StaffCard(
                performer: s,
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top performer banner ──────────────────────────────────────────────────────

class _TopPerformerBanner extends StatelessWidget {
  const _TopPerformerBanner({
    required this.performer,
    required this.colorScheme,
    required this.theme,
  });

  final StaffPerformance performer;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أفضل موظف اليوم',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Text(
                  performer.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  performer.role,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                performer.ratingDisplay,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < performer.rating.round()
                        ? Icons.star
                        : Icons.star_outline,
                    color: Colors.amber,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Staff card ─────────────────────────────────────────────────────────────────

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.performer,
    required this.colorScheme,
    required this.theme,
  });

  final StaffPerformance performer;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    performer.name[0],
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        performer.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        performer.role,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: performer
                        .ratingColor(colorScheme)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: performer.ratingColor(colorScheme),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        performer.ratingDisplay,
                        style: TextStyle(
                          color: performer.ratingColor(colorScheme),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _StatChip(
                  icon: Icons.receipt_long,
                  label: 'طلبات',
                  value: '${performer.ordersHandled}',
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatChip(
                  icon: Icons.timer_outlined,
                  label: 'متوسط الرد',
                  value: '${performer.avgResponseMinutes.toStringAsFixed(1)} د',
                  colorScheme: colorScheme,
                ),
                if (performer.tablesServed > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _StatChip(
                    icon: Icons.table_restaurant,
                    label: 'طاولات',
                    value: '${performer.tablesServed}',
                    colorScheme: colorScheme,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
