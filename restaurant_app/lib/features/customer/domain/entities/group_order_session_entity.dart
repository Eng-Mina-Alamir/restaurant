import 'package:flutter/foundation.dart';

/// Status of a shared group order room.
enum GroupSessionStatus {
  active,
  locked,
  submitted,
  cancelled;

  String get labelAr {
    switch (this) {
      case GroupSessionStatus.active:
        return 'مفتوحة لاستقبال الطلبات';
      case GroupSessionStatus.locked:
        return 'تم إغلاق الغرفة للمراجعة';
      case GroupSessionStatus.submitted:
        return 'تم إرسال الطلب للمطبخ';
      case GroupSessionStatus.cancelled:
        return 'ملغية';
    }
  }
}

/// Payment mode for group ordering.
enum GroupPaymentMode {
  hostPaysAll,
  splitEvenly,
  payByItem;

  String get labelAr {
    switch (this) {
      case GroupPaymentMode.hostPaysAll:
        return 'المضيف يدفع للجميع';
      case GroupPaymentMode.splitEvenly:
        return 'تقسيم الفاتورة بالتساوي';
      case GroupPaymentMode.payByItem:
        return 'كل شخص يدفع ثمن وجبته';
    }
  }
}

/// A single item added by a member inside a group order session.
@immutable
class GroupMemberItem {
  const GroupMemberItem({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.itemId,
    required this.itemName,
    required this.itemPrice,
    this.quantity = 1,
    this.selectedModifiers = const [],
    this.specialInstructions,
    required this.addedAt,
  });

  final String id;
  final String memberId;
  final String memberName;
  final String itemId;
  final String itemName;
  final double itemPrice;
  final int quantity;
  final List<String> selectedModifiers;
  final String? specialInstructions;
  final DateTime addedAt;

  double get totalPrice => itemPrice * quantity;

  GroupMemberItem copyWith({
    String? id,
    String? memberId,
    String? memberName,
    String? itemId,
    String? itemName,
    double? itemPrice,
    int? quantity,
    List<String>? selectedModifiers,
    String? specialInstructions,
    DateTime? addedAt,
  }) {
    return GroupMemberItem(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemPrice: itemPrice ?? this.itemPrice,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

/// Member summary inside a group order session.
@immutable
class GroupMember {
  const GroupMember({
    required this.id,
    required this.name,
    this.isHost = false,
    required this.joinedAt,
    this.hasPaid = false,
  });

  final String id;
  final String name;
  final bool isHost;
  final DateTime joinedAt;
  final bool hasPaid;
}

/// Aggregate entity representing a live group order session.
@immutable
class GroupOrderSession {
  const GroupOrderSession({
    required this.id,
    required this.roomCode,
    required this.hostId,
    required this.hostName,
    required this.restaurantId,
    this.members = const [],
    this.items = const [],
    this.status = GroupSessionStatus.active,
    this.paymentMode = GroupPaymentMode.hostPaysAll,
    required this.createdAt,
    this.lockedAt,
    this.orderId,
  });

  final String id;
  final String roomCode;
  final String hostId;
  final String hostName;
  final String restaurantId;
  final List<GroupMember> members;
  final List<GroupMemberItem> items;
  final GroupSessionStatus status;
  final GroupPaymentMode paymentMode;
  final DateTime createdAt;
  final DateTime? lockedAt;
  final String? orderId;

  /// Total count of items selected across all members.
  int get totalItemsCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  /// Grand total cost of the group order.
  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Computes the share per member when splitting evenly.
  double get perPersonShare =>
      members.isEmpty ? 0.0 : (subtotal / members.length);

  /// Returns items belonging to a specific member.
  List<GroupMemberItem> itemsForMember(String memberId) =>
      items.where((item) => item.memberId == memberId).toList();

  /// Total sum for a specific member when paying by item.
  double totalForMember(String memberId) =>
      itemsForMember(memberId).fold(0.0, (sum, item) => sum + item.totalPrice);

  GroupOrderSession copyWith({
    String? id,
    String? roomCode,
    String? hostId,
    String? hostName,
    String? restaurantId,
    List<GroupMember>? members,
    List<GroupMemberItem>? items,
    GroupSessionStatus? status,
    GroupPaymentMode? paymentMode,
    DateTime? createdAt,
    DateTime? lockedAt,
    String? orderId,
  }) {
    return GroupOrderSession(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      restaurantId: restaurantId ?? this.restaurantId,
      members: members ?? this.members,
      items: items ?? this.items,
      status: status ?? this.status,
      paymentMode: paymentMode ?? this.paymentMode,
      createdAt: createdAt ?? this.createdAt,
      lockedAt: lockedAt ?? this.lockedAt,
      orderId: orderId ?? this.orderId,
    );
  }
}
