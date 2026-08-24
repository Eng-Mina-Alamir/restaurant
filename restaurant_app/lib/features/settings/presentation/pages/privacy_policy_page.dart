import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

/// Privacy Policy page detailing data protection and user privacy rights.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'نحن نلتزم بحماية بياناتك الشخصية ومعاملاتك المالية بأعلى معايير الأمان والتشفير.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _PolicySection(
            icon: Icons.person_search_outlined,
            title: '1. البيانات التي نجمعها',
            content:
                'نقوم بجمع البيانات الضرورية لتقديم خدمة الطلب والتوصيل بكفاءة، وتشمل: الاسم، رقم الهاتف، الموقع الجغرافي للتوصيل، وسجل الطلبات وتفضيلات الوجبات.',
          ),
          const _PolicySection(
            icon: Icons.lock_outline,
            title: '2. أمان المدفوعات والمعاملات',
            content:
                'تتم معالجة جميع عمليات الدفع الإلكتروني (مدى، آبل باي، البطاقات الائتمانية) عبر بوابات دفع معتمدة ومطابقة لمعايير PCI-DSS دون حفظ أرقام البطاقات في خوادمنا.',
          ),
          const _PolicySection(
            icon: Icons.location_on_outlined,
            title: '3. استخدام الموقع الجغرافي',
            content:
                'يتم استخدام إحداثيات الموقع الجغرافي لغرض تتبع مسار توصيل الطلب بالوقت الفعلي وتحديد أقرب فرع مطعم للعميل.',
          ),
          const _PolicySection(
            icon: Icons.verified_user_outlined,
            title: '4. حقوق المستخدم',
            content:
                'يحق للمستخدم طلب تعديل أو حذف بياناته الشخصية في أي وقت من خلال التواصل مع إدارة الدعم الفني للمطعم.',
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              'آخر تحديث: 2026',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.icon,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: colorScheme.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
