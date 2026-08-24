import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/menu.dart';
import '../entities/menu_item.dart';

/// Domain contract for menu data access and mutations.
abstract class MenuRepository {
  /// Loads the full restaurant [Menu].
  Future<Either<Failure, Menu>> getMenu();

  /// Adds a new menu item.
  Future<Either<Failure, MenuItem>> addMenuItem(MenuItem item);

  /// Updates an existing menu item.
  Future<Either<Failure, MenuItem>> updateMenuItem(MenuItem item);

  /// Deletes a menu item by ID.
  Future<Either<Failure, void>> deleteMenuItem(String itemId);

  /// Adds a new category name.
  Future<Either<Failure, void>> addCategory(String categoryName);

  /// Deletes a category and its items.
  Future<Either<Failure, void>> deleteCategory(String categoryName);

  /// Toggles availability status of an item.
  Future<Either<Failure, MenuItem>> toggleAvailability(
    String itemId,
    bool isAvailable,
  );
}
