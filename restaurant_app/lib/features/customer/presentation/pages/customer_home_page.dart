import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../pages/menu_item_detail_sheet.dart';
import '../widgets/category_chips.dart';
import '../widgets/menu_item_tile.dart';

/// Dine-in customer home: browse categories, view items, add to cart.
class CustomerHomePage extends ConsumerWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuControllerProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.menuTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: AppConstants.cartTitle,
            onPressed: () => _openCart(context),
          ),
        ],
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (menu) {
          final items = filterMenu(menu, selected);
          return Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              CategoryChips(
                categories: menu.categories,
                selected: selected,
                onSelected: (category) =>
                    ref.read(selectedCategoryProvider.notifier).state =
                        category,
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text(AppConstants.noItemsFound))
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
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
