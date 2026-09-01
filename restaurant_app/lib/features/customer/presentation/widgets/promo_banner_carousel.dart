import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';

/// Promotional banner item model.
class PromoBannerItem {
  const PromoBannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradientColors,
    this.targetCategory,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> gradientColors;
  final String? targetCategory;
}

/// Dynamic auto-advancing promotional banners carousel for customer home page.
class PromoBannerCarousel extends ConsumerStatefulWidget {
  const PromoBannerCarousel({super.key});

  static const List<PromoBannerItem> defaultBanners = [
    PromoBannerItem(
      id: 'banner-grills',
      title: 'خصم 20% على قسم المشويات',
      subtitle: 'أشهى المشويات على الفحم مع أرز وسلطات',
      badge: 'عرض اليوم 🔥',
      icon: Icons.local_fire_department_rounded,
      gradientColors: [Color(0xFFE65100), Color(0xFFFF8F00)],
      targetCategory: 'مشويات ومأكولات شرقية',
    ),
    PromoBannerItem(
      id: 'banner-delivery',
      title: 'توصيل مجاني لطلبك الأول',
      subtitle: 'استخدم كوبون FIRSTFREE عند الدفع',
      badge: 'توصيل مجاني 🛵',
      icon: Icons.delivery_dining_rounded,
      gradientColors: [Color(0xFF1B5E20), Color(0xFF43A047)],
    ),
    PromoBannerItem(
      id: 'banner-desserts',
      title: 'عروض الحلى والقهوة ☕',
      subtitle: 'أم علي وكنافة نابلسية بالجبنة مع مشروبك المفضل',
      badge: 'حلي يومك 🍰',
      icon: Icons.cake_rounded,
      gradientColors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
      targetCategory: 'حلويات',
    ),
  ];

  @override
  ConsumerState<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends ConsumerState<PromoBannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % PromoBannerCarousel.defaultBanners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const banners = PromoBannerCarousel.defaultBanners;

    return Column(
      children: [
        SizedBox(
          height: 115,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: _BannerCard(banner: banner),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends ConsumerWidget {
  const _BannerCard({required this.banner});

  final PromoBannerItem banner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () {
        if (banner.targetCategory != null) {
          ref.read(selectedCategoryProvider.notifier).state = banner.targetCategory!;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: banner.gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: banner.gradientColors.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background icon
            PositionedDirectional(
              end: -20,
              bottom: -20,
              child: Icon(
                banner.icon,
                size: 110,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      banner.badge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    banner.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    banner.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
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
