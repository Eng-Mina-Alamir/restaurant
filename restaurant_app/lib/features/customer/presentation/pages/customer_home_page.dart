import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/animations/staggered_fade_slide_list.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../../../table_management/domain/entities/table_service_request.dart';
import '../../../table_management/presentation/controllers/table_service_controller.dart';
import '../pages/menu_item_detail_sheet.dart';
import '../widgets/category_chips.dart';
import '../widgets/customer_hero_profile_card.dart';
import '../widgets/customer_sliver_app_bar.dart';
import '../widgets/dine_in_table_hub_sheet.dart';
import '../widgets/floating_cart_bar.dart';
import '../widgets/menu_item_tile.dart';
import '../widgets/promo_banner_carousel.dart';

/// Customer menu browsing page with search, category filtering, and Telegram-style expandable quick actions stories bar.
class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({super.key});

  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _storiesController;
  late final Animation<double> _storiesAnimation;

  @override
  void initState() {
    super.initState();
    _storiesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _storiesAnimation = CurvedAnimation(
      parent: _storiesController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInOutCubic,
    );
    _storiesController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _storiesController.dispose();
    super.dispose();
  }

  void _toggleStories() {
    AppHaptics.selectionTap();
    if (_storiesController.value > 0.5) {
      _storiesController.reverse();
    } else {
      _storiesController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuControllerProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final query = ref.watch(menuSearchQueryProvider);
    final diet = ref.watch(menuDietFilterProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Ignore horizontal scroll notifications (such as swiping the stories bar or categories)
              if (notification.metrics.axis != Axis.vertical ||
                  notification.depth != 0) {
                return false;
              }

              // Pulling down at top of vertical scroll expands the stories tray (Telegram style)
              if (notification is OverscrollNotification) {
                if (notification.overscroll < -6) {
                  if (_storiesController.value < 0.5 &&
                      !_storiesController.isAnimating) {
                    _storiesController.forward();
                  }
                }
              } else if (notification is ScrollUpdateNotification) {
                if (notification.metrics.pixels < -15) {
                  if (_storiesController.value < 0.5 &&
                      !_storiesController.isAnimating) {
                    _storiesController.forward();
                  }
                } else if (notification.metrics.pixels > 70) {
                  // Scrolling down the vertical menu collapses the stories bar
                  if (_storiesController.value > 0.1 &&
                      !_storiesController.isAnimating) {
                    _storiesController.reverse();
                  }
                }
              }
              return false;
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              cacheExtent: 1500,
              slivers: [
                // 1. Sleek Customer SliverAppBar with Quick Actions Hub
                CustomerSliverAppBar(
                  storiesAnimation: _storiesAnimation,
                  storiesController: _storiesController,
                  onToggleStories: _toggleStories,
                ),

                // 2. Main Content
                ...menuAsync.when(
                  loading: () => [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.sm),
                            child: SkeletonBox(
                              width: double.infinity,
                              height: 90,
                              borderRadius: AppRadius.md,
                            ),
                          ),
                          childCount: 6,
                        ),
                      ),
                    ),
                  ],
                  error: (error, _) => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorState(
                        message: AppConstants.errorLoadingData,
                        errorDetail: error,
                        onRetry: () => ref.refresh(menuControllerProvider),
                      ),
                    ),
                  ],
                  data: (menu) {
                    final items = filterMenu(menu, selected, query, diet);
                    return [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xs),
                            // Luxury Customer Hero Profile & Greeting Card
                            const CustomerHeroProfileCard(),

                            // Active Table Service Banner (if dine-in)
                            const _TableServiceBanner(),

                            // Search Field
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.md,
                                AppSpacing.xs,
                              ),
                              child: TextField(
                                onChanged: (value) => ref
                                    .read(menuSearchQueryProvider.notifier)
                                    .state = value,
                                decoration: InputDecoration(
                                  hintText: AppConstants.searchMenuHint,
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  isDense: true,
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),

                            // Category Chips
                            CategoryChips(
                              categories: menu.categories,
                              selected: selected,
                              onSelected: (category) => ref
                                  .read(selectedCategoryProvider.notifier)
                                  .state = category,
                            ),
                            const SizedBox(height: AppSpacing.xs),

                            // Dietary Filter Chips
                            _DietChips(
                              selected: diet,
                              onSelected: (value) => ref
                                  .read(menuDietFilterProvider.notifier)
                                  .state = value,
                            ),

                            // Promotional Banners Carousel
                            if (selected == kAllCategoriesFilter &&
                                query.isEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              const PromoBannerCarousel(),
                              const SizedBox(height: AppSpacing.xs),
                            ],
                          ],
                        ),
                      ),

                      // Menu Items or Empty State
                      if (items.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            message: AppConstants.noItemsFound,
                            icon: Icons.search_off,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            80, // Space for floating cart bar
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = items[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xs,
                                  ),
                                  child: AnimatedListItem(
                                    index: index,
                                    staggerDuration:
                                        const Duration(milliseconds: 40),
                                    duration:
                                        const Duration(milliseconds: 350),
                                    child: MenuItemTile(
                                      item: item,
                                      onTap: () =>
                                          _showItemDetail(context, ref, item),
                                      onAdd: () => _quickAdd(ref, item),
                                    ),
                                  ),
                                );
                              },
                              childCount: items.length,
                            ),
                          ),
                        ),
                    ];
                  },
                ),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingCartBar(),
          ),
        ],
      ),
    );
  }

  /// Adds an item directly, or opens the detail sheet when it has modifiers.
  void _quickAdd(WidgetRef ref, MenuItem item) {
    if (item.modifierGroups.isEmpty) {
      ref
          .read(cartControllerProvider.notifier)
          .addItem(CartItem(menuItem: item, quantity: 1));
    } else {
      _showItemDetail(ref.context, ref, item);
    }
  }

  void _showItemDetail(BuildContext context, WidgetRef ref, MenuItem item) {
    MenuItemDetailSheet.show(context, item);
  }
}

/// Horizontal row of dietary filter chips (all / vegetarian / spicy).
class _DietChips extends StatelessWidget {
  const _DietChips({required this.selected, required this.onSelected});

  final MenuDietFilter selected;
  final ValueChanged<MenuDietFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (final filter in MenuDietFilter.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(_label(filter)),
                selected: selected == filter,
                onSelected: (_) => onSelected(filter),
              ),
            ),
        ],
      ),
    );
  }

  String _label(MenuDietFilter filter) => switch (filter) {
    MenuDietFilter.none => AppConstants.dietAll,
    MenuDietFilter.vegetarian => AppConstants.dietVegetarian,
    MenuDietFilter.spicy => AppConstants.dietSpicy,
  };
}

/// Quick action banner for dine-in customers with an active table (Call Waiter / Request Bill).
class _TableServiceBanner extends ConsumerWidget {
  const _TableServiceBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTable = ref.watch(activeTableIdProvider);
    if (activeTable == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tableNum =
        int.tryParse(activeTable.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final requests = ref.watch(tableServiceControllerProvider);
    final activeForThisTable =
        requests.where((r) => r.tableId == activeTable && !r.isHandled).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Card(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.table_restaurant,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'أنت جالس على طاولة $activeTable',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (activeForThisTable.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: StatusColors.tone(
                          SemanticTone.warning,
                          theme.brightness,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        'طلبك قيد المتابعة...',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: StatusColors.tone(
                            SemanticTone.warning,
                            theme.brightness,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                      ),
                      label: const Text('طلب النادل'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        ref
                            .read(tableServiceControllerProvider.notifier)
                            .requestService(
                              tableId: activeTable,
                              tableNumber: tableNum,
                              type: TableServiceType.callWaiter,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم إرسال طلب استدعاء النادل لطاولتك 🔔',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(
                        Icons.receipt_long_outlined,
                        size: 18,
                      ),
                      label: const Text('طلب الحساب'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        ref
                            .read(tableServiceControllerProvider.notifier)
                            .requestService(
                              tableId: activeTable,
                              tableNumber: tableNum,
                              type: TableServiceType.requestBill,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم إرسال طلب الفاتورة للنادل 🧾',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.room_service_outlined, size: 18),
                    tooltip: 'خدمات الطاولة',
                    onPressed: () => DineInTableHubSheet.show(
                      context,
                      tableNumber: tableNum,
                      tableId: activeTable,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
