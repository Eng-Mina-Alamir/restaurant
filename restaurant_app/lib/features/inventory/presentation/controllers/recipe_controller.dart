import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recipe_item_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'inventory_controller.dart';

/// State for the recipes and food cost calculations.
class RecipeController
    extends StateNotifier<AsyncValue<List<MenuItemRecipeEntity>>> {
  RecipeController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final InventoryRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    final result = await _repository.getRecipes();
    state = result.when(
      onLeft: (f) => AsyncValue.error(f.message, StackTrace.current),
      onRight: (recipes) => AsyncValue.data(recipes),
    );
  }

  Future<bool> saveRecipe(MenuItemRecipeEntity recipe) async {
    final result = await _repository.saveRecipe(recipe);
    return result.when(
      onLeft: (_) => false,
      onRight: (saved) {
        final current = state.valueOrNull ?? <MenuItemRecipeEntity>[];
        final index = current.indexWhere((r) => r.menuItemId == saved.menuItemId);
        if (index == -1) {
          state = AsyncValue.data(<MenuItemRecipeEntity>[...current, saved]);
        } else {
          final updatedList = List<MenuItemRecipeEntity>.from(current);
          updatedList[index] = saved;
          state = AsyncValue.data(updatedList);
        }
        return true;
      },
    );
  }

  /// Calculates overall restaurant food cost health metric across all configured recipes.
  double get averageFoodCostPercentage {
    final list = state.valueOrNull ?? [];
    final valid = list.where((r) => r.menuItemPrice > 0).toList();
    if (valid.isEmpty) return 0.0;
    final sum = valid.fold<double>(
      0.0,
      (acc, r) => acc + r.foodCostPercentage,
    );
    return sum / valid.length;
  }
}

final recipeControllerProvider =
    StateNotifierProvider<
      RecipeController,
      AsyncValue<List<MenuItemRecipeEntity>>
    >((ref) => RecipeController(ref.watch(inventoryRepositoryProvider)));
