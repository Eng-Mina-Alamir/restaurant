import '../../../orders/domain/entities/order_entity.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/inventory_item_entity.dart';
import '../entities/recipe_item_entity.dart';
import '../entities/waste_log_entity.dart';

/// Contract for inventory management, recipe Bill-of-Materials (BOM), and waste logging.
abstract class InventoryRepository {
  Future<Either<Failure, List<InventoryItemEntity>>> getInventoryItems();

  Future<Either<Failure, InventoryItemEntity>> addItem(
    InventoryItemEntity item,
  );

  Future<Either<Failure, InventoryItemEntity>> updateItem(
    InventoryItemEntity item,
  );

  Future<Either<Failure, void>> deleteItem(String id);

  Future<Either<Failure, InventoryItemEntity>> restock(
    String id,
    double amount,
  );

  /// Deducts recipe ingredients and stock units when an order is completed.
  Future<Either<Failure, void>> deductStockForOrder(OrderEntity order);

  /// Recipes (BOM) management
  Future<Either<Failure, List<MenuItemRecipeEntity>>> getRecipes();

  Future<Either<Failure, MenuItemRecipeEntity?>> getRecipeForMenuItem(
    String menuItemId,
  );

  Future<Either<Failure, MenuItemRecipeEntity>> saveRecipe(
    MenuItemRecipeEntity recipe,
  );

  /// Waste & Spoilage tracking
  Future<Either<Failure, List<WasteLogEntity>>> getWasteLogs();

  Future<Either<Failure, WasteLogEntity>> logWaste(WasteLogEntity wasteLog);
}
