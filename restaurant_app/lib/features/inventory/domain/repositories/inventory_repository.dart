import '../../../orders/domain/entities/order_entity.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/inventory_item_entity.dart';

/// Contract for inventory management repository.
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
}
