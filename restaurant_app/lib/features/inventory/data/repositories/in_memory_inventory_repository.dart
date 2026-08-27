import '../../../orders/domain/entities/order_entity.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/repositories/inventory_repository.dart';

/// In-memory implementation of [InventoryRepository] with realistic Egyptian restaurant ingredients.
class InMemoryInventoryRepository implements InventoryRepository {
  InMemoryInventoryRepository([List<InventoryItemEntity>? initial]) {
    _items =
        initial ??
        [
          const InventoryItemEntity(
            id: 'inv-1',
            name: 'لحم ضاني وكندوز بلدي طازج',
            category: 'لحوم',
            currentStock: 35.0,
            unit: 'كغ',
            minThreshold: 15.0,
            costPerUnit: 380.0,
          ),
          const InventoryItemEntity(
            id: 'inv-2',
            name: 'عيش بلدي طازج مخبوز بالردة',
            category: 'مخبوزات',
            currentStock: 120.0,
            unit: 'رغيف',
            minThreshold: 50.0,
            costPerUnit: 2.5,
          ),
          const InventoryItemEntity(
            id: 'inv-3',
            name: 'سمن بلدي فلاحي جاموسي نقي',
            category: 'ألبان ودهون',
            currentStock: 14.0,
            unit: 'كغ',
            minThreshold: 8.0,
            costPerUnit: 260.0,
          ),
          const InventoryItemEntity(
            id: 'inv-4',
            name: 'ملوخية خضراء فلاحي طازجة',
            category: 'خضروات',
            currentStock: 25.0,
            unit: 'كغ',
            minThreshold: 10.0,
            costPerUnit: 20.0,
          ),
          const InventoryItemEntity(
            id: 'inv-5',
            name: 'أرز مصري درجة أولى (الحبة الرفيعة)',
            category: 'حبوب',
            currentStock: 80.0,
            unit: 'كغ',
            minThreshold: 30.0,
            costPerUnit: 32.0,
          ),
          const InventoryItemEntity(
            id: 'inv-6',
            name: 'دجاج مزارع بلدي طازج للتحمير',
            category: 'دواجن',
            currentStock: 40.0,
            unit: 'دجاجة',
            minThreshold: 15.0,
            costPerUnit: 125.0,
          ),
          const InventoryItemEntity(
            id: 'inv-7',
            name: 'طحينة سمسم بلدي نقية خام',
            category: 'صلصات',
            currentStock: 18.0,
            unit: 'كغ',
            minThreshold: 10.0,
            costPerUnit: 110.0,
          ),
          const InventoryItemEntity(
            id: 'inv-8',
            name: 'مانجو عويس وسكري فريش للعصير',
            category: 'فواكه',
            currentStock: 3.5,
            unit: 'قفص',
            minThreshold: 5.0,
            costPerUnit: 180.0,
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

  @override
  Future<Either<Failure, void>> deductStockForOrder(OrderEntity order) async {
    for (final orderItem in order.items) {
      final name = orderItem.menuItem.name.toLowerCase();
      final qty = orderItem.quantity.toDouble();

      for (var i = 0; i < _items.length; i++) {
        final inv = _items[i];
        final invName = inv.name.toLowerCase();

        double deduction = 0.0;
        if (invName.contains('لحم') &&
            (name.contains('لحم') ||
                name.contains('كباب') ||
                name.contains('طاجن') ||
                name.contains('برجر') ||
                name.contains('كفتة'))) {
          deduction = 0.25 * qty;
        } else if (invName.contains('دجاج') &&
            (name.contains('دجاج') ||
                name.contains('فراخ') ||
                name.contains('شاورما') ||
                name.contains('شيش'))) {
          deduction = 0.3 * qty;
        } else if (invName.contains('أرز') &&
            (name.contains('أرز') ||
                name.contains('فتة') ||
                name.contains('وجبة') ||
                name.contains('برياني'))) {
          deduction = 0.2 * qty;
        } else if (invName.contains('عيش') &&
            (name.contains('حواوشي') ||
                name.contains('ساندوتش') ||
                name.contains('فتة') ||
                name.contains('خبز'))) {
          deduction = 2.0 * qty;
        } else if (invName.contains('سمن') &&
            (name.contains('طاجن') ||
                name.contains('ملوخية') ||
                name.contains('فتة') ||
                name.contains('كوارع'))) {
          deduction = 0.05 * qty;
        } else if (invName.contains('ملوخية') && name.contains('ملوخية')) {
          deduction = 0.3 * qty;
        } else if (invName.contains('طحينة') &&
            (name.contains('سلطة') ||
                name.contains('مشاوي') ||
                name.contains('كباب') ||
                name.contains('شاورما'))) {
          deduction = 0.05 * qty;
        } else if (invName.contains('مانجو') &&
            (name.contains('مانجو') ||
                name.contains('عصير') ||
                name.contains('مشروب'))) {
          deduction = 0.25 * qty;
        }

        if (deduction > 0) {
          final newStock = (inv.currentStock - deduction).clamp(0.0, 999999.0);
          _items[i] = inv.copyWith(currentStock: newStock);
        }
      }
    }
    return const Right(null);
  }
}
