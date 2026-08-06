// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sales_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SalesMetrics _$SalesMetricsFromJson(Map<String, dynamic> json) {
  return _SalesMetrics.fromJson(json);
}

/// @nodoc
mixin _$SalesMetrics {
  double get totalSales => throw _privateConstructorUsedError;
  int get totalOrders => throw _privateConstructorUsedError;
  double get averageOrderValue => throw _privateConstructorUsedError;
  Map<String, int> get itemsSold => throw _privateConstructorUsedError;
  Map<String, double> get categoryRevenue => throw _privateConstructorUsedError;
  Map<String, double> get paymentMethodRevenue =>
      throw _privateConstructorUsedError;
  double get peakHour => throw _privateConstructorUsedError;
  double get prepTimeAverage => throw _privateConstructorUsedError;

  /// Serializes this SalesMetrics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SalesMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SalesMetricsCopyWith<SalesMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SalesMetricsCopyWith<$Res> {
  factory $SalesMetricsCopyWith(
    SalesMetrics value,
    $Res Function(SalesMetrics) then,
  ) = _$SalesMetricsCopyWithImpl<$Res, SalesMetrics>;
  @useResult
  $Res call({
    double totalSales,
    int totalOrders,
    double averageOrderValue,
    Map<String, int> itemsSold,
    Map<String, double> categoryRevenue,
    Map<String, double> paymentMethodRevenue,
    double peakHour,
    double prepTimeAverage,
  });
}

/// @nodoc
class _$SalesMetricsCopyWithImpl<$Res, $Val extends SalesMetrics>
    implements $SalesMetricsCopyWith<$Res> {
  _$SalesMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SalesMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalSales = null,
    Object? totalOrders = null,
    Object? averageOrderValue = null,
    Object? itemsSold = null,
    Object? categoryRevenue = null,
    Object? paymentMethodRevenue = null,
    Object? peakHour = null,
    Object? prepTimeAverage = null,
  }) {
    return _then(
      _value.copyWith(
            totalSales: null == totalSales
                ? _value.totalSales
                : totalSales // ignore: cast_nullable_to_non_nullable
                      as double,
            totalOrders: null == totalOrders
                ? _value.totalOrders
                : totalOrders // ignore: cast_nullable_to_non_nullable
                      as int,
            averageOrderValue: null == averageOrderValue
                ? _value.averageOrderValue
                : averageOrderValue // ignore: cast_nullable_to_non_nullable
                      as double,
            itemsSold: null == itemsSold
                ? _value.itemsSold
                : itemsSold // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            categoryRevenue: null == categoryRevenue
                ? _value.categoryRevenue
                : categoryRevenue // ignore: cast_nullable_to_non_nullable
                      as Map<String, double>,
            paymentMethodRevenue: null == paymentMethodRevenue
                ? _value.paymentMethodRevenue
                : paymentMethodRevenue // ignore: cast_nullable_to_non_nullable
                      as Map<String, double>,
            peakHour: null == peakHour
                ? _value.peakHour
                : peakHour // ignore: cast_nullable_to_non_nullable
                      as double,
            prepTimeAverage: null == prepTimeAverage
                ? _value.prepTimeAverage
                : prepTimeAverage // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SalesMetricsImplCopyWith<$Res>
    implements $SalesMetricsCopyWith<$Res> {
  factory _$$SalesMetricsImplCopyWith(
    _$SalesMetricsImpl value,
    $Res Function(_$SalesMetricsImpl) then,
  ) = __$$SalesMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double totalSales,
    int totalOrders,
    double averageOrderValue,
    Map<String, int> itemsSold,
    Map<String, double> categoryRevenue,
    Map<String, double> paymentMethodRevenue,
    double peakHour,
    double prepTimeAverage,
  });
}

/// @nodoc
class __$$SalesMetricsImplCopyWithImpl<$Res>
    extends _$SalesMetricsCopyWithImpl<$Res, _$SalesMetricsImpl>
    implements _$$SalesMetricsImplCopyWith<$Res> {
  __$$SalesMetricsImplCopyWithImpl(
    _$SalesMetricsImpl _value,
    $Res Function(_$SalesMetricsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SalesMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalSales = null,
    Object? totalOrders = null,
    Object? averageOrderValue = null,
    Object? itemsSold = null,
    Object? categoryRevenue = null,
    Object? paymentMethodRevenue = null,
    Object? peakHour = null,
    Object? prepTimeAverage = null,
  }) {
    return _then(
      _$SalesMetricsImpl(
        totalSales: null == totalSales
            ? _value.totalSales
            : totalSales // ignore: cast_nullable_to_non_nullable
                  as double,
        totalOrders: null == totalOrders
            ? _value.totalOrders
            : totalOrders // ignore: cast_nullable_to_non_nullable
                  as int,
        averageOrderValue: null == averageOrderValue
            ? _value.averageOrderValue
            : averageOrderValue // ignore: cast_nullable_to_non_nullable
                  as double,
        itemsSold: null == itemsSold
            ? _value._itemsSold
            : itemsSold // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        categoryRevenue: null == categoryRevenue
            ? _value._categoryRevenue
            : categoryRevenue // ignore: cast_nullable_to_non_nullable
                  as Map<String, double>,
        paymentMethodRevenue: null == paymentMethodRevenue
            ? _value._paymentMethodRevenue
            : paymentMethodRevenue // ignore: cast_nullable_to_non_nullable
                  as Map<String, double>,
        peakHour: null == peakHour
            ? _value.peakHour
            : peakHour // ignore: cast_nullable_to_non_nullable
                  as double,
        prepTimeAverage: null == prepTimeAverage
            ? _value.prepTimeAverage
            : prepTimeAverage // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SalesMetricsImpl implements _SalesMetrics {
  const _$SalesMetricsImpl({
    this.totalSales = 0,
    this.totalOrders = 0,
    this.averageOrderValue = 0,
    final Map<String, int> itemsSold = const <String, int>{},
    final Map<String, double> categoryRevenue = const <String, double>{},
    final Map<String, double> paymentMethodRevenue = const <String, double>{},
    this.peakHour = 0,
    this.prepTimeAverage = 0,
  }) : _itemsSold = itemsSold,
       _categoryRevenue = categoryRevenue,
       _paymentMethodRevenue = paymentMethodRevenue;

  factory _$SalesMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SalesMetricsImplFromJson(json);

  @override
  @JsonKey()
  final double totalSales;
  @override
  @JsonKey()
  final int totalOrders;
  @override
  @JsonKey()
  final double averageOrderValue;
  final Map<String, int> _itemsSold;
  @override
  @JsonKey()
  Map<String, int> get itemsSold {
    if (_itemsSold is EqualUnmodifiableMapView) return _itemsSold;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_itemsSold);
  }

  final Map<String, double> _categoryRevenue;
  @override
  @JsonKey()
  Map<String, double> get categoryRevenue {
    if (_categoryRevenue is EqualUnmodifiableMapView) return _categoryRevenue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_categoryRevenue);
  }

  final Map<String, double> _paymentMethodRevenue;
  @override
  @JsonKey()
  Map<String, double> get paymentMethodRevenue {
    if (_paymentMethodRevenue is EqualUnmodifiableMapView)
      return _paymentMethodRevenue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_paymentMethodRevenue);
  }

  @override
  @JsonKey()
  final double peakHour;
  @override
  @JsonKey()
  final double prepTimeAverage;

  @override
  String toString() {
    return 'SalesMetrics(totalSales: $totalSales, totalOrders: $totalOrders, averageOrderValue: $averageOrderValue, itemsSold: $itemsSold, categoryRevenue: $categoryRevenue, paymentMethodRevenue: $paymentMethodRevenue, peakHour: $peakHour, prepTimeAverage: $prepTimeAverage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SalesMetricsImpl &&
            (identical(other.totalSales, totalSales) ||
                other.totalSales == totalSales) &&
            (identical(other.totalOrders, totalOrders) ||
                other.totalOrders == totalOrders) &&
            (identical(other.averageOrderValue, averageOrderValue) ||
                other.averageOrderValue == averageOrderValue) &&
            const DeepCollectionEquality().equals(
              other._itemsSold,
              _itemsSold,
            ) &&
            const DeepCollectionEquality().equals(
              other._categoryRevenue,
              _categoryRevenue,
            ) &&
            const DeepCollectionEquality().equals(
              other._paymentMethodRevenue,
              _paymentMethodRevenue,
            ) &&
            (identical(other.peakHour, peakHour) ||
                other.peakHour == peakHour) &&
            (identical(other.prepTimeAverage, prepTimeAverage) ||
                other.prepTimeAverage == prepTimeAverage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalSales,
    totalOrders,
    averageOrderValue,
    const DeepCollectionEquality().hash(_itemsSold),
    const DeepCollectionEquality().hash(_categoryRevenue),
    const DeepCollectionEquality().hash(_paymentMethodRevenue),
    peakHour,
    prepTimeAverage,
  );

  /// Create a copy of SalesMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SalesMetricsImplCopyWith<_$SalesMetricsImpl> get copyWith =>
      __$$SalesMetricsImplCopyWithImpl<_$SalesMetricsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SalesMetricsImplToJson(this);
  }
}

abstract class _SalesMetrics implements SalesMetrics {
  const factory _SalesMetrics({
    final double totalSales,
    final int totalOrders,
    final double averageOrderValue,
    final Map<String, int> itemsSold,
    final Map<String, double> categoryRevenue,
    final Map<String, double> paymentMethodRevenue,
    final double peakHour,
    final double prepTimeAverage,
  }) = _$SalesMetricsImpl;

  factory _SalesMetrics.fromJson(Map<String, dynamic> json) =
      _$SalesMetricsImpl.fromJson;

  @override
  double get totalSales;
  @override
  int get totalOrders;
  @override
  double get averageOrderValue;
  @override
  Map<String, int> get itemsSold;
  @override
  Map<String, double> get categoryRevenue;
  @override
  Map<String, double> get paymentMethodRevenue;
  @override
  double get peakHour;
  @override
  double get prepTimeAverage;

  /// Create a copy of SalesMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SalesMetricsImplCopyWith<_$SalesMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
