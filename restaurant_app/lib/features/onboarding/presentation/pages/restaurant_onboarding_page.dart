import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/animations/scale_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../restaurant/presentation/controllers/restaurant_controller.dart';
import '../../../subscription/domain/entities/subscription_plan.dart';

/// Self-service onboarding wizard for new restaurant owners to start a SaaS subscription.
class RestaurantOnboardingPage extends ConsumerStatefulWidget {
  const RestaurantOnboardingPage({super.key});

  @override
  ConsumerState<RestaurantOnboardingPage> createState() =>
      _RestaurantOnboardingPageState();
}

class _RestaurantOnboardingPageState
    extends ConsumerState<RestaurantOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxNumberController = TextEditingController();

  // Account creation fields (if unauthenticated)
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();

  String _selectedCurrency = 'ج.م';
  SubscriptionTier _selectedTier = SubscriptionTier.pro;
  int _currentStep = 0;
  bool _submitting = false;

  final List<String> _currencies = const ['ج.م', 'ر.س', 'د.إ', '\$'];

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _taxNumberController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate step 1 fields
      if (!(_formKey.currentState?.validate() ?? false)) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    } else {
      _submitOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _submitOnboarding() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _submitting = true);
    AppHaptics.actionSuccess();

    try {
      final auth = ref.read(authControllerProvider);
      final repo = ref.read(restaurantRepositoryProvider);

      // If user is not logged in yet, register their account first with default restaurant,
      // then promote/link to the newly created tenant.
      if (auth.user == null) {
        final authNotifier = ref.read(authControllerProvider.notifier);
        await authNotifier.register(
          name: _ownerNameController.text.trim(),
          email: _ownerEmailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _ownerPasswordController.text,
          restaurantId: SupabaseConfig.defaultRestaurantId,
          role: UserRole.admin,
        );

        final updatedAuth = ref.read(authControllerProvider);
        if (updatedAuth.authFailure != null) {
          if (!mounted) return;
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(updatedAuth.authFailure!.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        }
      }

      // Call database RPC to register the new tenant restaurant
      final result = await repo.registerNewTenant(
        name: _restaurantNameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? 'الفرع الرئيسي'
            : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? '01000000000'
            : _phoneController.text.trim(),
        currency: _selectedCurrency,
        vatNumber: _taxNumberController.text.trim().isEmpty
            ? null
            : _taxNumberController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      result.when(
        onLeft: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        onRight: (data) async {
          AppHaptics.actionSuccess();
          // Invalidate and refresh auth and restaurant state
          await ref.read(authControllerProvider.notifier).bootstrap();
          ref.invalidate(restaurantSettingsControllerProvider);

          if (!mounted) return;
          _showCelebrationDialog(data['name']?.toString() ?? 'مطعمك الجديد');
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ غير متوقع: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showCelebrationDialog(String restaurantName) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'مبروك! تم تفعيل $restaurantName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تم إنشاء منصتك السحابية وتفعيل فترة تجريبية مجانية لمدة 14 يوماً بكامل المزايا (باقة Pro).',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم إعداد المنيو المبدئي والطاولات لتتمكن من بدء العمل فوراً!',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/manager');
            },
            icon: const Icon(Icons.dashboard_customize_rounded),
            label: const Text('دخول لوحة التحكم المركزية'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إنشاء مطعم سحابي جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── 1. Sleek, Overflow-Free Step Progress Indicator ──────────
              _OnboardingStepHeader(
                currentStep: _currentStep,
                onStepTapped: (step) {
                  // Only allow jumping backwards or to already reached steps
                  if (step < _currentStep) {
                    setState(() => _currentStep = step);
                  } else if (step == 1 && _currentStep == 0) {
                    _nextStep();
                  }
                },
              ),
              const Divider(height: 1),

              // ── 2. Scrollable Step Content ──────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _buildCurrentStep(context),
                    ),
                  ),
                ),
              ),

              // ── 3. Bottom Sticky Action Navigation Bar ──────────────────
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildRestaurantIdentityStep(context);
      case 1:
        return _buildSubscriptionPlanStep(context);
      case 2:
      default:
        return _buildOwnerAccountStep(context);
    }
  }

  Widget _buildRestaurantIdentityStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _restaurantNameController,
          decoration: const InputDecoration(
            labelText: 'اسم المطعم أو العلامة التجارية *',
            prefixIcon: Icon(Icons.storefront_rounded),
            hintText: 'مثال: برجر هاوس، شاورما النخيل',
          ),
          validator: (val) => (val == null || val.trim().isEmpty)
              ? 'يرجى إدخال اسم المطعم'
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم هاتف الإدارة *',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'يرجى إدخال رقم الهاتف'
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'العملة',
                ),
                items: _currencies
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCurrency = val);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'عنوان الفرع الرئيسي',
            prefixIcon: Icon(Icons.location_on_outlined),
            hintText: 'مثال: التجمع الخامس، القاهرة',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _taxNumberController,
          decoration: const InputDecoration(
            labelText: 'الرقم الضريبي (اختياري)',
            prefixIcon: Icon(Icons.receipt_long_rounded),
            hintText: '300XXXXXXXXXXXX',
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionPlanStep(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'جميع الباقات تشمل 14 يوماً تجربة مجانية بكامل المزايا وبدون أي رسوم خفية!',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _TierCard(
          tier: SubscriptionTier.starter,
          selected: _selectedTier == SubscriptionTier.starter,
          currency: _selectedCurrency,
          onSelect: () =>
              setState(() => _selectedTier = SubscriptionTier.starter),
        ),
        const SizedBox(height: AppSpacing.sm),
        _TierCard(
          tier: SubscriptionTier.pro,
          isPopular: true,
          selected: _selectedTier == SubscriptionTier.pro,
          currency: _selectedCurrency,
          onSelect: () => setState(() => _selectedTier = SubscriptionTier.pro),
        ),
        const SizedBox(height: AppSpacing.sm),
        _TierCard(
          tier: SubscriptionTier.enterprise,
          selected: _selectedTier == SubscriptionTier.enterprise,
          currency: _selectedCurrency,
          onSelect: () =>
              setState(() => _selectedTier = SubscriptionTier.enterprise),
        ),
      ],
    );
  }

  Widget _buildOwnerAccountStep(BuildContext context) {
    final isAuthenticated =
        ref.watch(authControllerProvider).status == AuthStatus.authenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAuthenticated) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.green),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'أنت مسجل الدخول حالياً بحساب:\n${ref.watch(authControllerProvider).user?.email ?? ""}\nسيتم تعيين هذا الحساب كمالك ومسؤول أعلى (Admin) للمطعم الجديد.',
                    style: const TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          TextFormField(
            controller: _ownerNameController,
            decoration: const InputDecoration(
              labelText: 'اسم صاحب المطعم / المدير *',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            validator: (val) =>
                (val == null || val.trim().isEmpty) ? 'يرجى كتابة الاسم' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _ownerEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني للإدارة *',
              prefixIcon: Icon(Icons.email_rounded),
            ),
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _ownerPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة مرور حساب الإدارة *',
              prefixIcon: Icon(Icons.lock_rounded),
            ),
            validator: (val) => (val == null || val.length < 6)
                ? 'كلمة المرور يجب أن لا تقل عن 6 أحرف'
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isLast = _currentStep == 2;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ScaleButton(
              onTap: _submitting ? null : _nextStep,
              child: FilledButton(
                onPressed: _submitting ? null : _nextStep,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isLast
                            ? 'تفعيل المطعم وبدء التجربة المجانية 🚀'
                            : 'التالي',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
          if (_currentStep > 0) ...[
            const SizedBox(width: AppSpacing.md),
            OutlinedButton(
              onPressed: _submitting ? null : _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              child: const Text('السابق'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom responsive step header that cleanly adapts to any screen width without overflow.
class _OnboardingStepHeader extends StatelessWidget {
  const _OnboardingStepHeader({
    required this.currentStep,
    required this.onStepTapped,
  });

  final int currentStep;
  final ValueChanged<int> onStepTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final steps = [
      ('بيانات المطعم', Icons.storefront_rounded),
      ('باقة الاشتراك', Icons.workspace_premium_rounded),
      ('حساب المالك', Icons.person_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            InkWell(
              onTap: () => onStepTapped(i),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: i == currentStep
                      ? colorScheme.primary
                      : (i < currentStep
                          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                          : colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: i == currentStep
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      i < currentStep
                          ? Icons.check_circle_rounded
                          : steps[i].$2,
                      size: 15,
                      color: i == currentStep
                          ? colorScheme.onPrimary
                          : (i < currentStep
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      steps[i].$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == currentStep
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: i == currentStep
                            ? colorScheme.onPrimary
                            : (i < currentStep
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i < currentStep
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.selected,
    required this.currency,
    required this.onSelect,
    this.isPopular = false,
  });

  final SubscriptionTier tier;
  final bool selected;
  final String currency;
  final VoidCallback onSelect;
  final bool isPopular;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlights = SubscriptionEntitlements.getTierHighlights(tier);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : (isPopular
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.outlineVariant),
            width: selected ? 2.5 : 1.0,
          ),
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
              : theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tier.nameAr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isPopular)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'الأكثر طلباً ⭐',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currency == 'ر.س'
                  ? '${tier.priceSar} ر.س / شهرياً'
                  : currency == '\$'
                      ? '\$${tier.priceUsd} / month'
                      : '${tier.priceEgp} ج.م / شهرياً',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(height: 16),
            for (final point in highlights.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        point,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
