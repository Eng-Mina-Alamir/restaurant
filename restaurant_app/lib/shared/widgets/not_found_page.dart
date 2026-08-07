import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import 'empty_state.dart';

/// Fallback page shown for unmatched routes (404 equivalent).
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.notFoundTitle)),
      body: EmptyState(
        message: AppConstants.notFoundTitle,
        icon: Icons.search_off,
        actionLabel: AppConstants.notFoundAction,
        onAction: () => context.go('/'),
      ),
    );
  }
}
