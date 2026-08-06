import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../core/theme/spacing.dart';

/// Fallback page shown for unmatched routes (404 equivalent).
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.back)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48),
            SizedBox(height: AppSpacing.md),
            Text('الصفحة غير موجودة'),
          ],
        ),
      ),
    );
  }
}
