import 'package:flutter/material.dart';

/// Entity representing a physical branch/location in a restaurant chain.
class BranchEntity {
  const BranchEntity({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.phone,
    this.managerId,
    this.managerName,
    this.isOpen = true,
    this.totalTables = 20,
    this.activeOrdersCount = 0,
    this.todaySales = 0.0,
    this.totalOrdersToday = 0,
    this.rating = 4.8,
    this.colorValue = 0xFFC2410C,
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final String phone;
  final String? managerId;
  final String? managerName;
  final bool isOpen;
  final int totalTables;
  final int activeOrdersCount;
  final double todaySales;
  final int totalOrdersToday;
  final double rating;
  final int colorValue;

  Color get color => Color(colorValue);

  BranchEntity copyWith({
    String? id,
    String? name,
    String? city,
    String? address,
    String? phone,
    String? managerId,
    String? managerName,
    bool? isOpen,
    int? totalTables,
    int? activeOrdersCount,
    double? todaySales,
    int? totalOrdersToday,
    double? rating,
    int? colorValue,
  }) {
    return BranchEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      isOpen: isOpen ?? this.isOpen,
      totalTables: totalTables ?? this.totalTables,
      activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount,
      todaySales: todaySales ?? this.todaySales,
      totalOrdersToday: totalOrdersToday ?? this.totalOrdersToday,
      rating: rating ?? this.rating,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'phone': phone,
      'manager_id': managerId,
      'manager_name': managerName,
      'is_open': isOpen,
      'total_tables': totalTables,
      'active_orders_count': activeOrdersCount,
      'today_sales': todaySales,
      'total_orders_today': totalOrdersToday,
      'rating': rating,
      'color_value': colorValue,
    };
  }

  factory BranchEntity.fromJson(Map<String, dynamic> json) {
    return BranchEntity(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'فرع رئيسي',
      city: json['city'] as String? ?? 'القاهرة',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      managerId: json['manager_id'] as String?,
      managerName: json['manager_name'] as String?,
      isOpen: json['is_open'] as bool? ?? true,
      totalTables: json['total_tables'] as int? ?? 20,
      activeOrdersCount: json['active_orders_count'] as int? ?? 0,
      todaySales: (json['today_sales'] as num?)?.toDouble() ?? 0.0,
      totalOrdersToday: json['total_orders_today'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      colorValue: json['color_value'] as int? ?? 0xFFC2410C,
    );
  }
}
