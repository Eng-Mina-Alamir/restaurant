import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
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
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
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
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: AppConstants.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
