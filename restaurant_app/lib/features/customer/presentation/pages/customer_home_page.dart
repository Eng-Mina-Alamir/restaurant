import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dine-in customer home.
///
/// Placeholder landing shell for the customer flow (QR scanning, menu browsing).
class CustomerHomePage extends ConsumerWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final userName = auth.user?.name ?? AppConstants.welcome;

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.menuTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$userName 👋',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(AppConstants.ordersTitle),
          ],
        ),
      ),
    );
  }
}
