import 'package:freezed_annotation/freezed_annotation.dart';

part 'sales_metrics.freezed.dart';
part 'sales_metrics.g.dart';

@freezed
abstract class SalesMetrics with _$SalesMetrics {
  const factory SalesMetrics({
    @Default(0) double totalSales,
    @Default(0) int totalOrders,
    @Default(0) double averageOrderValue,
    @Default(<String, int>{}) Map<String, int> itemsSold,
    @Default(0) double peakHour,
    @Default(0) double prepTimeAverage,
  }) = _SalesMetrics;

  factory SalesMetrics.fromJson(Map<String, dynamic> json) =>
      _$SalesMetricsFromJson(json);
}
