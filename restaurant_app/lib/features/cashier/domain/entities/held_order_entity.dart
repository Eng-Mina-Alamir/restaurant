import '../../../cart/domain/entities/cart_item.dart';

/// Represents an order parked / held by the cashier to serve the next customer in queue.
class HeldOrderEntity {
  const HeldOrderEntity({
    required this.id,
    required this.label,
    required this.items,
    required this.parkedAt,
    this.customerPhone,
    this.tableNumber,
    this.notes,
  });

  final String id;
  final String label;
  final List<CartItem> items;
  final DateTime parkedAt;
  final String? customerPhone;
  final int? tableNumber;
  final String? notes;

  double get totalAmount => items.fold<double>(0.0, (acc, it) => acc + it.linePrice);

  int get totalItemsCount => items.fold<int>(0, (acc, it) => acc + it.quantity);

  HeldOrderEntity copyWith({
    String? id,
    String? label,
    List<CartItem>? items,
    DateTime? parkedAt,
    String? customerPhone,
    int? tableNumber,
    String? notes,
  }) {
    return HeldOrderEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      items: items ?? this.items,
      parkedAt: parkedAt ?? this.parkedAt,
      customerPhone: customerPhone ?? this.customerPhone,
      tableNumber: tableNumber ?? this.tableNumber,
      notes: notes ?? this.notes,
    );
  }
}
