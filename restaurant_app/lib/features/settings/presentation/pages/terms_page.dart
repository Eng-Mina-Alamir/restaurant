import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

/// Terms & Conditions page governing orders, cancellations, and usage.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('الشروط والأحكام')),
      // Keep the AppBar full-bleed while capping the reading measure so
      // long-form legal text stays scannable on tablets/desktop.
      // 720 is a deliberate content-width cap; AppBreakpoints only models
      // layout breakpoints, not readable line lengths.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.gavel_outlined,
                      color: colorScheme.secondary,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'استخدامك للتطبيق يمثل موافقتك الكاملة على جميع الشروط والأحكام الموضحة أدناه.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _TermsSection(
                title: '1. قبول الطلبات',
                content:
                    'يتم تأكيد الطلب فور استلامه من قبل نظام المطعم أو موافقة المطبخ. يحق للمطعم الاعتذار عن الطلب في حال نفاد الأصناف.',
              ),
              const _TermsSection(
                title: '2. سياسة الإلغاء والاسترجاع',
                content:
                    'يمكن للعميل إلغاء الطلب مجاناً طالما كان في حالة "قيد الانتظار". في حال بدء تحضير الطلب في المطبخ، قد لا يمكن استرداد كامل المبلغ.',
              ),
              const _TermsSection(
                title: '3. الأسعار والضرائب (ZATCA)',
                content:
                    'جميع الأسعار المعروضة في القائمة تشمل ضريبة القيمة المضافة (15%) وفقاً للأنظمة واللوائح المعتمدة من هيئة الزكاة والضريبة والجمارك.',
              ),
              const _TermsSection(
                title: '4. التوصيل والمسؤولية',
                content:
                    'يلتزم السائق بتوصيل الطلب إلى العنوان المحدد في أسرع وقت. في حال تعذر الوصول للعميل بعد عدة محاولات، يتم التعامل مع الطلب وفق سياسة الفرع.',
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  'الإصدار 1.0.0 — ساري المفعول',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.content});

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
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
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
