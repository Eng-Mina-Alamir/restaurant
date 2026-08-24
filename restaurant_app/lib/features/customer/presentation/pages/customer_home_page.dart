import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/animations/staggered_fade_slide_list.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../../../shared/widgets/theme_mode_switch_button.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../pages/menu_item_detail_sheet.dart';
import '../pages/qr_scan_page.dart';
import '../widgets/category_chips.dart';
import '../widgets/menu_item_tile.dart';

/// Dine-in customer home: browse categories, view items, add to cart with smooth animations.
class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({super.key});

  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuControllerProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final query = ref.watch(menuSearchQueryProvider);
    final diet = ref.watch(menuDietFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.menuTitle),
        actions: [
          const ThemeModeSwitchButton(),
          Consumer(
            builder: (context, ref, _) {
              final activeTable = ref.watch(activeTableIdProvider);
              return IconButton(
                icon: Icon(
                  activeTable != null
                      ? Icons.table_restaurant
                      : Icons.qr_code_scanner,
                ),
                tooltip: activeTable != null
                    ? 'طاولة $activeTable'
                    : 'مسح QR الطاولة',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScanPage()),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.stars_rounded),
            tooltip: 'برنامج الولاء والمكافآت',
            color: Colors.amber.shade700,
            onPressed: () => context.push('/customer/loyalty'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: AppConstants.orderHistoryTitle,
            onPressed: () => context.push('/customer/orders'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'الإشعارات والتنبيهات',
            onPressed: () => context.push('/notifications'),
          ),

          IconButton(
            icon: Badge(
              isLabelVisible: ref.watch(
                cartControllerProvider.select((c) => c.isNotEmpty),
              ),
              label: Text(
                '${ref.watch(cartControllerProvider.select((c) => c.fold<int>(0, (sum, item) => sum + item.quantity)))}',
              ),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            tooltip: AppConstants.cartTitle,
            onPressed: () => _openCart(context),
          ),
          const LogoutActionButton(),
        ],
      ),
      body: menuAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 6,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: SkeletonBox(
              width: double.infinity,
              height: 90,
              borderRadius: AppRadius.md,
            ),
          ),
        ),
        error: (error, _) => Center(child: Text('$error')),
        data: (menu) {
          final items = filterMenu(menu, selected, query, diet);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: TextField(
                  onChanged: (value) =>
                      ref.read(menuSearchQueryProvider.notifier).state = value,
                  decoration: InputDecoration(
                    hintText: AppConstants.searchMenuHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CategoryChips(
                categories: menu.categories,
                selected: selected,
                onSelected: (category) =>
                    ref.read(selectedCategoryProvider.notifier).state =
                        category,
              ),
              const SizedBox(height: AppSpacing.sm),
              _DietChips(
                selected: diet,
                onSelected: (value) =>
                    ref.read(menuDietFilterProvider.notifier).state = value,
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        message: AppConstants.noItemsFound,
                        icon: Icons.search_off,
                      )
                    : StaggeredFadeSlideList(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: items.length,
                        staggerDuration: const Duration(milliseconds: 40),
                        animationDuration: const Duration(milliseconds: 350),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: MenuItemTile(
                              item: item,
                              onTap: () => _showItemDetail(context, ref, item),
                              onAdd: () => _quickAdd(ref, item),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
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

  void _openCart(BuildContext context) {
    context.push('/customer/cart');
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
