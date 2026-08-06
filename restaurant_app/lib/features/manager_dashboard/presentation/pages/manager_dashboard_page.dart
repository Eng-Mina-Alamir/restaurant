import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

/// Manager / admin dashboard placeholder.
class ManagerDashboardPage extends StatelessWidget {
  const ManagerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة المدير')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats, size: 48),
            SizedBox(height: AppSpacing.md),
            Text('التحليلات والمبيعات'),
          ],
        ),
      ),
    );
  }
}
