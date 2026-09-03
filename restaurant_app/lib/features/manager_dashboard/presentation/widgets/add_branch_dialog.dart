import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../restaurant/domain/entities/branch_entity.dart';
import '../../../restaurant/presentation/controllers/branch_controller.dart';

/// Modern dialog for adding a new branch to the restaurant chain.
class AddBranchDialog extends ConsumerStatefulWidget {
  const AddBranchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AddBranchDialog(),
    );
  }

  @override
  ConsumerState<AddBranchDialog> createState() => _AddBranchDialogState();
}

class _AddBranchDialogState extends ConsumerState<AddBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController(text: 'القاهرة');
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _managerController = TextEditingController();
  final _tablesController = TextEditingController(text: '25');
  int _selectedColorValue = 0xFFC2410C;

  final _colors = [
    0xFFC2410C, // Warm Orange
    0xFF0F766E, // Teal
    0xFF7C3AED, // Purple
    0xFF0284C7, // Sky Blue
    0xFF10B981, // Emerald
    0xFFD97706, // Amber
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _managerController.dispose();
    _tablesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final strings = ref.read(appStringsProvider);

    final newBranch = BranchEntity(
      id: 'branch-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      managerName: _managerController.text.trim().isNotEmpty
          ? _managerController.text.trim()
          : strings.notAssigned,
      totalTables: int.tryParse(_tablesController.text) ?? 20,
      isOpen: true,
      todaySales: 0.0,
      totalOrdersToday: 0,
      activeOrdersCount: 0,
      colorValue: _selectedColorValue,
    );

    ref.read(branchesControllerProvider.notifier).addBranch(newBranch);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newBranch.name} • ${strings.branchAddedSuccess} 🎉'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      backgroundColor: isDark ? colorScheme.surfaceContainerLow : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.add_business_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.addBranchDialogTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              strings.addBranchDialogSubtitle,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '${strings.branchNameLabel} *',
                      hintText: strings.branchNameHint,
                      prefixIcon: const Icon(Icons.storefront_rounded),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? strings.branchNameRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: strings.cityLabel,
                            prefixIcon: const Icon(Icons.location_city_rounded),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? strings.cityRequired
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _tablesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: strings.tablesTitle,
                            prefixIcon: const Icon(Icons.table_restaurant_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: '${strings.branchAddressLabel} *',
                      hintText: strings.branchAddressHint,
                      prefixIcon: const Icon(Icons.place_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? strings.branchAddressRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: strings.branchPhoneLabel,
                            prefixIcon: const Icon(Icons.phone_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _managerController,
                          decoration: InputDecoration(
                            labelText: strings.branchManagerLabel,
                            prefixIcon: const Icon(Icons.person_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    strings.branchAccentColor,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      for (final col in _colors)
                        GestureDetector(
                          onTap: () => setState(() => _selectedColorValue = col),
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(col),
                              shape: BoxShape.circle,
                              border: _selectedColorValue == col
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: _selectedColorValue == col
                                  ? AppShadows.glow(Color(col), opacity: 0.4)
                                  : null,
                            ),
                            child: _selectedColorValue == col
                                ? const Icon(Icons.check, size: 18, color: Colors.white)
                                : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(strings.cancel),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(strings.saveBranch),
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
