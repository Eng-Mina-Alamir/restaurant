import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_config.dart';
import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../auth/data/datasources/demo_auth_datasource.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Authentication entry page.
///
/// Supports login with an email/phone identifier + password. On success the
/// role-based router automatically redirects to the user's home route.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authState = ref.read(authControllerProvider);
    if (authState.status == AuthStatus.unknown && _submitting) {
      return;
    }
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);
    await ref
        .read(authControllerProvider.notifier)
        .login(_identifierController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() => _submitting = false);

    final updated = ref.read(authControllerProvider);
    if (updated.authFailure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(updated.authFailure!.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themed = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppConfig.appName,
                    textAlign: TextAlign.center,
                    style: themed.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppConstants.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: themed.textTheme.bodyMedium?.copyWith(
                      color: themed.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // One AutofillGroup spans both credential fields so password
                  // managers can save/fill them as a single unit.
                  AutofillGroup(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: AppConstants.emailLabel,
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? AppConstants.requiredField
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: AppConstants.passwordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              // Tooltip mirrors the action so screen readers hear
                              // what pressing will do, not just the current state.
                              tooltip: _obscurePassword
                                  ? 'إظهار كلمة المرور'
                                  : 'إخفاء كلمة المرور',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? AppConstants.requiredField
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _DemoAccounts(
                    visible: AppConfig.useDemoAuth,
                    onSelect: (role) {
                      _identifierController.text =
                          DemoAuthDataSource.accounts[role]!;
                      _passwordController.text = DemoAuthDataSource.password;
                      _submit();
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppConstants.loginButton),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('ليس لديك حساب؟'),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('إنشاء حساب جديد'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Demo-account quick login shown when offline auth is enabled, so reviewers
/// can jump into any role with a single tap.
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.visible, required this.onSelect});

  final bool visible;
  final ValueChanged<UserRole> onSelect;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppConstants.demoAccountsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppConstants.demoPasswordHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final role in DemoAuthDataSource.supportedRoles)
                  ActionChip(
                    avatar: Icon(_roleIcon(role), size: 18),
                    label: Text(role.labelAr),
                    onPressed: () => onSelect(role),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return Icons.person;
      case UserRole.waiter:
        return Icons.restaurant_menu;
      case UserRole.kitchen:
        return Icons.local_fire_department;
      case UserRole.manager:
        return Icons.insights;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.driver:
        return Icons.delivery_dining;
      case UserRole.cashier:
        return Icons.point_of_sale;
    }
  }
}
