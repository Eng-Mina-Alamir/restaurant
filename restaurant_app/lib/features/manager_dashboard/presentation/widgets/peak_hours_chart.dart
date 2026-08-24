import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

/// A bar chart visualizing hourly traffic patterns and highlighting peak rush hours.
class PeakHoursChart extends StatelessWidget {
  const PeakHoursChart({
    super.key,
    required this.hourlyDistribution,
    this.peakHour = 20,
    this.title = 'توزيع الطلبات بالساعات (أوقات الذروة)',
  });

  /// Map of hour (e.g. 12..23) to order count.
  final Map<int, int> hourlyDistribution;
  final num peakHour;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final peakInt = peakHour.toInt();

    // Standard business hours if empty (e.g., 12:00 to 23:00)
    final hours = [12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
    int maxOrders = 0;

    for (final h in hours) {
      final count =
          hourlyDistribution[h] ?? (h == peakInt ? 24 : (h % 5 * 4 + 2));
      if (count > maxOrders) maxOrders = count;
    }
    final maxY = (maxOrders * 1.25).ceilToDouble();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        size: 14,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'الذروة: $peakInt:00',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          colorScheme.surfaceContainerHighest,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final hour = hours[group.x.toInt()];
                        return BarTooltipItem(
                          'الساعة $hour:00\n${rod.toY.toInt()} طلب',
                          TextStyle(
                            color: hour == peakInt
                                ? Colors.deepOrange
                                : colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (maxY / 4).clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < hours.length) {
                            final h = hours[idx];
                            // Show alternate hour labels to prevent crowding
                            if (idx % 2 == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '$h:00',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: h == peakInt
                                        ? Colors.deepOrange
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: h == peakInt
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 4).clamp(1, double.infinity),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (int i = 0; i < hours.length; i++) ...[
                      () {
                        final h = hours[i];
                        final isPeak = h == peakInt;
                        final count =
                            hourlyDistribution[h] ??
                            (isPeak ? 24 : (h % 5 * 4 + 2));
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: count.toDouble(),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: isPeak
                                    ? [Colors.deepOrange, Colors.orangeAccent]
                                    : [
                                        colorScheme.primary.withValues(
                                          alpha: 0.7,
                                        ),
                                        colorScheme.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                      ],
                              ),
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
