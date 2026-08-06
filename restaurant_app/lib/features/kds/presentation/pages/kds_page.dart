import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

/// Kitchen Display System placeholder — shows order columns (pending/preparing/ready).
class KdsPage extends StatelessWidget {
  const KdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شاشة المطبخ')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.soup_kitchen_outlined, size: 48),
            SizedBox(height: AppSpacing.md),
            Text('عرض الطلبات والتعامل معها'),
          ],
        ),
      ),
    );
  }
}
