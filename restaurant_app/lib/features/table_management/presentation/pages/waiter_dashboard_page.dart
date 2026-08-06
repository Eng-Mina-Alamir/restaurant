import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

/// Waiter / captain role placeholder.
class WaiterDashboardPage extends StatelessWidget {
  const WaiterDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة النادل')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 48),
            SizedBox(height: AppSpacing.md),
            Text('إدارة الطاولات وأخذ الطلبات'),
          ],
        ),
      ),
    );
  }
}
