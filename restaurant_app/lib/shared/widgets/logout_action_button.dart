import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

/// An app-bar action that logs the current user out and lets the router
/// redirect them to the login page.
class LogoutActionButton extends ConsumerWidget {
  const LogoutActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: AppConstants.logout,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        await ref.read(authControllerProvider.notifier).logout();
        messenger.showSnackBar(
          const SnackBar(content: Text(AppConstants.logoutMessage)),
        );
      },
    );
  }
}
