import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/menu.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';
import '../menu_seed_data.dart';

/// In-memory and seeded [MenuRepository] supporting dynamic CRUD operations.
class MenuRepositoryImpl implements MenuRepository {
  MenuRepositoryImpl() : _currentMenu = MenuSeedData.buildMenu();

  Menu _currentMenu;

  @override
  Future<Either<Failure, Menu>> getMenu() async {
    return Right<Failure, Menu>(_currentMenu);
  }

  @override
  Future<Either<Failure, MenuItem>> addMenuItem(MenuItem item) async {
    final updatedItems = [..._currentMenu.items, item];
    final updatedCategories =
        _currentMenu.categories.contains(item.categoryId)
            ? _currentMenu.categories
            : [..._currentMenu.categories, item.categoryId];
    _currentMenu = _currentMenu.copyWith(
      items: updatedItems,
      categories: updatedCategories,
    );
    return Right<Failure, MenuItem>(item);
  }

  @override
  Future<Either<Failure, MenuItem>> updateMenuItem(MenuItem item) async {
    final index = _currentMenu.items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      return const Left(ValidationFailure('الصنف المطلوب غير موجود'));
    }
    final updatedItems = [..._currentMenu.items]..[index] = item;
    _currentMenu = _currentMenu.copyWith(items: updatedItems);
    return Right<Failure, MenuItem>(item);
  }

  @override
  Future<Either<Failure, void>> deleteMenuItem(String itemId) async {
    final updatedItems =
        _currentMenu.items.where((i) => i.id != itemId).toList();
    _currentMenu = _currentMenu.copyWith(items: updatedItems);
    return const Right<Failure, void>(null);
  }

  @override
  Future<Either<Failure, void>> addCategory(String categoryName) async {
    if (!_currentMenu.categories.contains(categoryName.trim())) {
      _currentMenu = _currentMenu.copyWith(
        categories: [..._currentMenu.categories, categoryName.trim()],
      );
    }
    return const Right<Failure, void>(null);
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String categoryName) async {
    final updatedCategories =
        _currentMenu.categories.where((c) => c != categoryName).toList();
    final updatedItems =
        _currentMenu.items.where((i) => i.categoryId != categoryName).toList();
    _currentMenu = _currentMenu.copyWith(
      categories: updatedCategories,
      items: updatedItems,
    );
    return const Right<Failure, void>(null);
  }

  @override
  Future<Either<Failure, MenuItem>> toggleAvailability(
    String itemId,
    bool isAvailable,
  ) async {
    final index = _currentMenu.items.indexWhere((i) => i.id == itemId);
    if (index == -1) {
      return const Left(ValidationFailure('الصنف غير موجود'));
    }
    final updatedItem =
        _currentMenu.items[index].copyWith(isAvailable: isAvailable);
    final updatedItems = [..._currentMenu.items]..[index] = updatedItem;
    _currentMenu = _currentMenu.copyWith(items: updatedItems);
    return Right<Failure, MenuItem>(updatedItem);
  }
}

