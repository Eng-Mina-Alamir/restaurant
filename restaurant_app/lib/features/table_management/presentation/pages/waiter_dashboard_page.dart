import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../controllers/table_controller.dart';
import 'waiter_table_card.dart';

/// Waiter / captain dashboard: a grid of restaurant tables with status-aware
/// actions (take order, release, clean, reserve).
class WaiterDashboardPage extends ConsumerWidget {
  const WaiterDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tableControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.tablesTitle)),
      body: tables.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.15,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return WaiterTableCard(
                  table: table,
                  onTap: () {
                    context.push('/waiter/table/${table.id}');
                  },
                  onTakeOrder: () {
                    context.push('/waiter/order/${table.id}');
                  },
                  onRelease: () => ref
                      .read(tableControllerProvider.notifier)
                      .release(table.id),
                  onReserve: () => ref
                      .read(tableControllerProvider.notifier)
                      .setReserved(table.id, reserved: true),
                );
              },
            ),
    );
  }
}

/// Resolves the Arabic label for a [TableStatus].
String tableStatusLabel(TableStatus status) {
  switch (status) {
    case TableStatus.available:
      return AppConstants.tableStatusAvailable;
    case TableStatus.occupied:
      return AppConstants.tableStatusOccupied;
    case TableStatus.reserved:
      return AppConstants.tableStatusReserved;
    case TableStatus.needsCleaning:
      return AppConstants.tableStatusNeedsCleaning;
  }
}

/// Color used to signal the table status in the grid.
Color tableStatusColor(TableStatus status) {
  switch (status) {
    case TableStatus.available:
      return Colors.green;
    case TableStatus.occupied:
      return Colors.deepOrange;
    case TableStatus.reserved:
      return Colors.blue;
    case TableStatus.needsCleaning:
      return Colors.brown;
  }
}
