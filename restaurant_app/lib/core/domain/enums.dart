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
  driver;

  String get labelAr {
    switch (this) {
      case UserRole.customer:
        return AppConstants.roleCustomer;
      case UserRole.waiter:
        return AppConstants.roleWaiter;
      case UserRole.kitchen:
        return AppConstants.roleKitchen;
      case UserRole.manager:
        return AppConstants.roleManager;
      case UserRole.admin:
        return AppConstants.roleAdmin;
      case UserRole.driver:
        return AppConstants.roleDriver;
    }
  }

  /// Base route for the role used by the role-based router guard.
  String get homeRoute {
    switch (this) {
      case UserRole.customer:
        return '/customer';
      case UserRole.waiter:
        return '/waiter';
      case UserRole.kitchen:
        return '/kds';
      case UserRole.manager:
      case UserRole.admin:
        return '/manager';
      case UserRole.driver:
        return '/driver';
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
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      case 'driver':
        return UserRole.driver;
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
