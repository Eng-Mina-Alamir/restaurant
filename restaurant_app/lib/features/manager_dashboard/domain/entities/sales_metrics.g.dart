// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SalesMetrics _$SalesMetricsFromJson(Map<String, dynamic> json) =>
    _SalesMetrics(
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0,
      itemsSold:
          (json['itemsSold'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      categoryRevenue:
          (json['categoryRevenue'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const <String, double>{},
      paymentMethodRevenue:
          (json['paymentMethodRevenue'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const <String, double>{},
      peakHour: (json['peakHour'] as num?)?.toDouble() ?? 0,
      prepTimeAverage: (json['prepTimeAverage'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$SalesMetricsToJson(_SalesMetrics instance) =>
    <String, dynamic>{
      'totalSales': instance.totalSales,
      'totalOrders': instance.totalOrders,
      'averageOrderValue': instance.averageOrderValue,
      'itemsSold': instance.itemsSold,
      'categoryRevenue': instance.categoryRevenue,
      'paymentMethodRevenue': instance.paymentMethodRevenue,
      'peakHour': instance.peakHour,
      'prepTimeAverage': instance.prepTimeAverage,
    };
