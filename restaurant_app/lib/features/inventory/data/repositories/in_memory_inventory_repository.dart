import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/repositories/inventory_repository.dart';

/// In-memory implementation of [InventoryRepository] with realistic seed items.
class InMemoryInventoryRepository implements InventoryRepository {
  InMemoryInventoryRepository([List<InventoryItemEntity>? initial]) {
    _items = initial ??
        [
          const InventoryItemEntity(
            id: 'inv-1',
            name: 'لحم بقري مفروم (أنجوس)',
            category: 'لحوم',
            currentStock: 18.5,
            unit: 'كغ',
            minThreshold: 8.0,
            costPerUnit: 55.0,
          ),
          const InventoryItemEntity(
            id: 'inv-2',
            name: 'خبز برجر بريوش طازج',
            category: 'مخبوزات',
            currentStock: 4.0,
            unit: 'كرتون',
            minThreshold: 6.0,
            costPerUnit: 25.0,
          ),
          const InventoryItemEntity(
            id: 'inv-3',
            name: 'زيت نباتي للقلي',
            category: 'مواد غذائية',
            currentStock: 2.0,
            unit: 'لتر',
            minThreshold: 15.0,
            costPerUnit: 12.0,
          ),
          const InventoryItemEntity(
            id: 'inv-4',
            name: 'طماطم شيري وهولندية طازجة',
            category: 'خضروات',
            currentStock: 22.0,
            unit: 'كغ',
            minThreshold: 10.0,
            costPerUnit: 7.5,
          ),
          const InventoryItemEntity(
            id: 'inv-5',
            name: 'جبن شيدر أصفر مبشور',
            category: 'ألبان',
            currentStock: 5.0,
            unit: 'كغ',
            minThreshold: 6.0,
            costPerUnit: 48.0,
          ),
          const InventoryItemEntity(
            id: 'inv-6',
            name: 'صدور دجاج طازجة متبلة',
            category: 'لحوم',
            currentStock: 28.0,
            unit: 'كغ',
            minThreshold: 12.0,
            costPerUnit: 32.0,
          ),
          const InventoryItemEntity(
            id: 'inv-7',
            name: 'أرز بسمتي هندي فاخر',
            category: 'مواد غذائية',
            currentStock: 45.0,
            unit: 'كغ',
            minThreshold: 15.0,
            costPerUnit: 14.0,
          ),
          const InventoryItemEntity(
            id: 'inv-8',
            name: 'صلصة ترفل سرية',
            category: 'صلصات',
            currentStock: 1.5,
            unit: 'لتر',
            minThreshold: 3.0,
            costPerUnit: 85.0,
          ),
        ];
  }

  late List<InventoryItemEntity> _items;

  @override
  Future<Either<Failure, List<InventoryItemEntity>>> getInventoryItems() async {
    return Right(List.unmodifiable(_items));
  }

  @override
  Future<Either<Failure, InventoryItemEntity>> addItem(
    InventoryItemEntity item,
  ) async {
    _items = [..._items, item];
    return Right(item);
  }

  @override
  Future<Either<Failure, InventoryItemEntity>> updateItem(
    InventoryItemEntity item,
  ) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      return const Left(NotFoundFailure('الصنف غير موجود في المخزون'));
    }
    _items = [..._items]..[index] = item;
    return Right(item);
  }

  @override
  Future<Either<Failure, void>> deleteItem(String id) async {
    _items = _items.where((i) => i.id != id).toList();
    return const Right(null);
  }

  @override
  Future<Either<Failure, InventoryItemEntity>> restock(
    String id,
    double amount,
  ) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      return const Left(NotFoundFailure('الصنف غير موجود في المخزون'));
    }
    final existing = _items[index];
    final updated = existing.copyWith(
      currentStock: (existing.currentStock + amount).clamp(0.0, 999999.0),
    );
    _items = [..._items]..[index] = updated;
    return Right(updated);
  }
}
