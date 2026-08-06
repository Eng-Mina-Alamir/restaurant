import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

/// Delivery driver home placeholder.
class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تطبيق السائق')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining_outlined, size: 48),
            SizedBox(height: AppSpacing.md),
            Text('الطلبات المتاحة للتوصيل'),
          ],
        ),
      ),
    );
  }
}
