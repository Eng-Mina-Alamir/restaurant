/// Domain-level enums shared across features.
///
/// Each enum provides:
/// - [labelAr]: user-facing Arabic label.
/// - [fromName]: tolerant string lookup used by JSON deserialization.
library;

import '../../config/constants.dart';

// ── Order type ────────────────────────────────────────────────────────────────

enum OrderType {
  dineIn,
  takeaway,
  delivery;

  String get labelAr {
    switch (this) {
      case OrderType.dineIn:
        return AppConstants.orderTypeDineIn;
      case OrderType.takeaway:
        return AppConstants.orderTypeTakeaway;
      case OrderType.delivery:
        return AppConstants.orderTypeDelivery;
    }
  }

  String get labelEn {
    switch (this) {
      case OrderType.dineIn:
        return 'Dine-In';
      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.delivery:
        return 'Delivery';
    }
  }

  String localizedLabel(bool isArabic) => isArabic ? labelAr : labelEn;

  static OrderType fromName(String? name) {
    switch (name?.toLowerCase()) {
      case 'dinein':
      case 'dine_in':
        return OrderType.dineIn;
      case 'takeaway':
      case 'take_away':
        return OrderType.takeaway;
      case 'delivery':
        return OrderType.delivery;
      default:
        return OrderType.dineIn;
    }
  }
}

// ── Order status ──────────────────────────────────────────────────────────────

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  served,
  completed,
  cancelled;

  String get labelAr => OrderStatusAr.labelOf(name);

  String get labelEn {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.served:
        return 'Served';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String localizedLabel(bool isArabic) => isArabic ? labelAr : labelEn;

  /// Whether the order reached a final state and no longer needs action.
  bool get isTerminal =>
      this == OrderStatus.completed || this == OrderStatus.cancelled;

  /// Checks whether moving from this status to [next] is a valid business transition.
  bool canTransitionTo(OrderStatus next) {
    if (this == next) return true;
    if (isTerminal) return false;

    switch (this) {
      case OrderStatus.pending:
        return next == OrderStatus.confirmed ||
            next == OrderStatus.preparing ||
            next == OrderStatus.completed ||
            next == OrderStatus.cancelled;
      case OrderStatus.confirmed:
        return next == OrderStatus.preparing ||
            next == OrderStatus.completed ||
            next == OrderStatus.cancelled;
      case OrderStatus.preparing:
        return next == OrderStatus.ready || next == OrderStatus.cancelled;
      case OrderStatus.ready:
        return next == OrderStatus.served ||
            next == OrderStatus.completed ||
            next == OrderStatus.cancelled;
      case OrderStatus.served:
        return next == OrderStatus.completed;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return false;
    }
  }

  /// Whether a realtime status event may legally move this status BACK to
  /// [previous] (operator correction — e.g. the kitchen marked an order ready
  /// by mistake and needs to send it back to preparing).
  ///
  /// Business rules:
  /// - Only single-step backward moves between active statuses are allowed:
  ///   ready → preparing and served → ready.
  /// - Terminal statuses ([completed], [cancelled]) never participate in a
  ///   revert, neither as the current status nor as the target: an order that
  ///   reached a final state is immutable.
  bool canRevertTo(OrderStatus previous) {
    if (isTerminal || previous.isTerminal) return false;
    return (this == OrderStatus.ready && previous == OrderStatus.preparing) ||
        (this == OrderStatus.served && previous == OrderStatus.ready);
  }

  static OrderStatus fromName(String? name) {
    switch (name?.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'served':
        return OrderStatus.served;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

// ── Table status ──────────────────────────────────────────────────────────────

enum TableStatus {
  available,
  occupied,
  reserved,
  needsCleaning;

  String get labelAr {
    switch (this) {
      case TableStatus.available:
        return AppConstants.tableStatusAvailable;
      case TableStatus.occupied:
        return AppConstants.tableStatusOccupied;
      case TableStatus.reserved:
        return AppConstants.tableStatusReserved;
      case TableStatus.needsCleaning:
        return AppConstants.tableStatusNeedsCleaning;
    }
  }

  String get labelEn {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.needsCleaning:
        return 'Needs Cleaning';
    }
  }

  String localizedLabel(bool isArabic) => isArabic ? labelAr : labelEn;

  static TableStatus fromName(String? name) {
    switch (name?.toLowerCase()) {
      case 'available':
        return TableStatus.available;
      case 'occupied':
        return TableStatus.occupied;
      case 'reserved':
        return TableStatus.reserved;
      case 'needscleaning':
      case 'needs_cleaning':
        return TableStatus.needsCleaning;
      default:
        return TableStatus.available;
    }
  }
}

// ── User role ─────────────────────────────────────────────────────────────────

enum UserRole {
  customer,
  waiter,
  kitchen,
  manager,
  admin,
  driver,
  cashier,
  managerChef;

  String get labelAr {
    switch (this) {
      case UserRole.customer:
        return AppConstants.roleCustomer;
      case UserRole.waiter:
        return AppConstants.roleWaiter;
      case UserRole.kitchen:
        return AppConstants.roleKitchen;
      case UserRole.managerChef:
        return AppConstants.roleManagerChef;
      case UserRole.manager:
        return AppConstants.roleManager;
      case UserRole.admin:
        return AppConstants.roleAdmin;
      case UserRole.driver:
        return AppConstants.roleDriver;
      case UserRole.cashier:
        return AppConstants.roleCashier;
    }
  }

  String get labelEn {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.waiter:
        return 'Waiter';
      case UserRole.kitchen:
        return 'Kitchen Chef';
      case UserRole.managerChef:
        return 'Manager Chef';
      case UserRole.manager:
        return 'Branch Manager';
      case UserRole.admin:
        return 'Chain Admin';
      case UserRole.driver:
        return 'Delivery Driver';
      case UserRole.cashier:
        return 'Cashier';
    }
  }

  String localizedLabel(bool isArabic) => isArabic ? labelAr : labelEn;

  /// Base route for the role used by the role-based router guard.
  String get homeRoute {
    switch (this) {
      case UserRole.customer:
        return '/customer';
      case UserRole.waiter:
        return '/waiter';
      case UserRole.kitchen:
      case UserRole.managerChef:
        return '/kds';
      case UserRole.manager:
      case UserRole.admin:
        return '/manager';
      case UserRole.driver:
        return '/driver';
      case UserRole.cashier:
        return '/cashier';
    }
  }

  static UserRole fromName(String? name) {
    switch (name?.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'waiter':
        return UserRole.waiter;
      case 'kitchen':
      case 'kds':
        return UserRole.kitchen;
      case 'managerchef':
      case 'manager_chef':
      case 'headchef':
      case 'head_chef':
        return UserRole.managerChef;
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      case 'driver':
        return UserRole.driver;
      case 'cashier':
        return UserRole.cashier;
      default:
        return UserRole.customer;
    }
  }
}

// ── Payment method ────────────────────────────────────────────────────────────

enum PaymentMethod {
  cash,
  card,
  wallet,
  online;

  String get labelAr {
    switch (this) {
      case PaymentMethod.cash:
        return AppConstants.paymentCash;
      case PaymentMethod.card:
        return AppConstants.paymentCard;
      case PaymentMethod.wallet:
        return AppConstants.paymentWallet;
      case PaymentMethod.online:
        return AppConstants.paymentOnline;
    }
  }

  String get labelEn {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card / Visa';
      case PaymentMethod.wallet:
        return 'Digital Wallet';
      case PaymentMethod.online:
        return 'Online Payment';
    }
  }

  String localizedLabel(bool isArabic) => isArabic ? labelAr : labelEn;

  static PaymentMethod fromName(String? name) {
    switch (name?.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'wallet':
        return PaymentMethod.wallet;
      case 'online':
        return PaymentMethod.online;
      default:
        return PaymentMethod.cash;
    }
  }
}

// ── Delivery status ───────────────────────────────────────────────────────────

enum DeliveryStatus {
  pending,
  accepted,
  pickedUp,
  inTransit,
  delivered,
  failed;

  String get labelAr {
    switch (this) {
      case DeliveryStatus.pending:
        return AppConstants.deliveryPending;
      case DeliveryStatus.accepted:
        return AppConstants.deliveryAccepted;
      case DeliveryStatus.pickedUp:
        return AppConstants.deliveryPickedUp;
      case DeliveryStatus.inTransit:
        return AppConstants.deliveryInTransit;
      case DeliveryStatus.delivered:
        return AppConstants.deliveryDelivered;
      case DeliveryStatus.failed:
        return AppConstants.deliveryFailed;
    }
  }

  String get labelEn {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pending Assignment';
      case DeliveryStatus.accepted:
        return 'Accepted by Driver';
      case DeliveryStatus.pickedUp:
        return 'Picked Up';
      case DeliveryStatus.inTransit:
        return 'In Transit';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.failed:
        return 'Failed / Cancelled';
    }
  }

  String localizedLabel(bool isArabic) => isArabic ? labelAr : labelEn;

  static DeliveryStatus fromName(String? name) {
    switch (name?.toLowerCase()) {
      case 'pending':
        return DeliveryStatus.pending;
      case 'accepted':
        return DeliveryStatus.accepted;
      case 'pickedup':
      case 'picked_up':
        return DeliveryStatus.pickedUp;
      case 'intransit':
      case 'in_transit':
      case 'delivering':
        return DeliveryStatus.inTransit;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'failed':
      case 'cancelled':
        return DeliveryStatus.failed;
      default:
        return DeliveryStatus.pending;
    }
  }
}
