import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../shared/animations/fade_slide_transition.dart';
import '../../../../shared/animations/scale_button.dart';

/// Interactive onboarding walkthrough introducing the restaurant app features.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _slides = const [
    _OnboardingItem(
      title: 'طلب ذكي ومباشر من طاولتك 🍽️',
      description:
          'امسح رمز QR على طاولتك، تصفح المنيو المصور مع خيارات التخصيص الكاملة، وأرسل طلبك للمطبخ بلمسة واحدة.',
      icon: Icons.qr_code_scanner_rounded,
      tone: SemanticTone.warning,
    ),
    _OnboardingItem(
      title: 'متابعة حية لحظة بلحظة ⏱️',
      description:
          'شاهد مراحل تحضير طعامك في شاشة المطبخ KDS وتتبع مسار سائق التوصيل على الخريطة المباشرة بدقة.',
      icon: Icons.timer_outlined,
      tone: SemanticTone.success,
    ),
    _OnboardingItem(
      title: 'دفع متعدد ونقاط ولاء ومكافآت 🎁',
      description:
          'ادفع بالطريقة التي تفضلها (نقدي، بطاقة، محفظة، دفع إلكتروني) واكسب نقاط ولاء مع كل طلب لاستبدالها بوجبات مجانية.',
      icon: Icons.card_giftcard_rounded,
      tone: SemanticTone.info,
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      // Honor the OS reduce-motion setting by switching pages instantly
      // instead of animating between them.
      if (MediaQuery.disableAnimationsOf(context)) {
        _pageController.jumpToPage(_currentPage + 1);
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    } else {
      context.go('/customer');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: TextButton(
                onPressed: () => context.go('/customer'),
                child: Text('تخطي', style: theme.textTheme.bodyLarge),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  // Resolve the audited accent once per build so light/dark
                  // modes both keep their >= 4.5:1 contrast bar.
                  final accent = StatusColors.tone(
                    slide.tone,
                    theme.brightness,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: FadeSlideTransitionWidget(
                      key: ValueKey(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: accent.withValues(
                                alpha: isDark ? 0.25 : 0.12,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              slide.icon,
                              size: 70,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _slides.length,
                      (idx) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == idx ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == idx
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                      ),
                    ),
                  ),
                  ScaleButton(
                    onTap: _next,
                    child: FilledButton.icon(
                      onPressed: _next,
                      icon: Icon(
                        _currentPage == _slides.length - 1
                            ? Icons.check
                            : Icons.arrow_forward,
                      ),
                      label: Text(
                        _currentPage == _slides.length - 1
                            ? 'ابدأ الآن'
                            : 'التالي',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String description;
  final IconData icon;

  /// Semantic accent tone; resolved to a brightness-aware audited color via
  /// [StatusColors.tone] at build time (never a raw hardcoded hue).
  final SemanticTone tone;
}
