// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sales_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SalesMetrics {

 double get totalSales; int get totalOrders; double get averageOrderValue; Map<String, int> get itemsSold; Map<String, double> get categoryRevenue; Map<String, double> get paymentMethodRevenue; double get peakHour; double get prepTimeAverage;
/// Create a copy of SalesMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesMetricsCopyWith<SalesMetrics> get copyWith => _$SalesMetricsCopyWithImpl<SalesMetrics>(this as SalesMetrics, _$identity);

  /// Serializes this SalesMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesMetrics&&(identical(other.totalSales, totalSales) || other.totalSales == totalSales)&&(identical(other.totalOrders, totalOrders) || other.totalOrders == totalOrders)&&(identical(other.averageOrderValue, averageOrderValue) || other.averageOrderValue == averageOrderValue)&&const DeepCollectionEquality().equals(other.itemsSold, itemsSold)&&const DeepCollectionEquality().equals(other.categoryRevenue, categoryRevenue)&&const DeepCollectionEquality().equals(other.paymentMethodRevenue, paymentMethodRevenue)&&(identical(other.peakHour, peakHour) || other.peakHour == peakHour)&&(identical(other.prepTimeAverage, prepTimeAverage) || other.prepTimeAverage == prepTimeAverage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalSales,totalOrders,averageOrderValue,const DeepCollectionEquality().hash(itemsSold),const DeepCollectionEquality().hash(categoryRevenue),const DeepCollectionEquality().hash(paymentMethodRevenue),peakHour,prepTimeAverage);

@override
String toString() {
  return 'SalesMetrics(totalSales: $totalSales, totalOrders: $totalOrders, averageOrderValue: $averageOrderValue, itemsSold: $itemsSold, categoryRevenue: $categoryRevenue, paymentMethodRevenue: $paymentMethodRevenue, peakHour: $peakHour, prepTimeAverage: $prepTimeAverage)';
}


}

/// @nodoc
abstract mixin class $SalesMetricsCopyWith<$Res>  {
  factory $SalesMetricsCopyWith(SalesMetrics value, $Res Function(SalesMetrics) _then) = _$SalesMetricsCopyWithImpl;
@useResult
$Res call({
 double totalSales, int totalOrders, double averageOrderValue, Map<String, int> itemsSold, Map<String, double> categoryRevenue, Map<String, double> paymentMethodRevenue, double peakHour, double prepTimeAverage
});




}
/// @nodoc
class _$SalesMetricsCopyWithImpl<$Res>
    implements $SalesMetricsCopyWith<$Res> {
  _$SalesMetricsCopyWithImpl(this._self, this._then);

  final SalesMetrics _self;
  final $Res Function(SalesMetrics) _then;

/// Create a copy of SalesMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalSales = null,Object? totalOrders = null,Object? averageOrderValue = null,Object? itemsSold = null,Object? categoryRevenue = null,Object? paymentMethodRevenue = null,Object? peakHour = null,Object? prepTimeAverage = null,}) {
  return _then(_self.copyWith(
totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as double,totalOrders: null == totalOrders ? _self.totalOrders : totalOrders // ignore: cast_nullable_to_non_nullable
as int,averageOrderValue: null == averageOrderValue ? _self.averageOrderValue : averageOrderValue // ignore: cast_nullable_to_non_nullable
as double,itemsSold: null == itemsSold ? _self.itemsSold : itemsSold // ignore: cast_nullable_to_non_nullable
as Map<String, int>,categoryRevenue: null == categoryRevenue ? _self.categoryRevenue : categoryRevenue // ignore: cast_nullable_to_non_nullable
as Map<String, double>,paymentMethodRevenue: null == paymentMethodRevenue ? _self.paymentMethodRevenue : paymentMethodRevenue // ignore: cast_nullable_to_non_nullable
as Map<String, double>,peakHour: null == peakHour ? _self.peakHour : peakHour // ignore: cast_nullable_to_non_nullable
as double,prepTimeAverage: null == prepTimeAverage ? _self.prepTimeAverage : prepTimeAverage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SalesMetrics].
extension SalesMetricsPatterns on SalesMetrics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SalesMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SalesMetrics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SalesMetrics value)  $default,){
final _that = this;
switch (_that) {
case _SalesMetrics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SalesMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _SalesMetrics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double totalSales,  int totalOrders,  double averageOrderValue,  Map<String, int> itemsSold,  Map<String, double> categoryRevenue,  Map<String, double> paymentMethodRevenue,  double peakHour,  double prepTimeAverage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SalesMetrics() when $default != null:
return $default(_that.totalSales,_that.totalOrders,_that.averageOrderValue,_that.itemsSold,_that.categoryRevenue,_that.paymentMethodRevenue,_that.peakHour,_that.prepTimeAverage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double totalSales,  int totalOrders,  double averageOrderValue,  Map<String, int> itemsSold,  Map<String, double> categoryRevenue,  Map<String, double> paymentMethodRevenue,  double peakHour,  double prepTimeAverage)  $default,) {final _that = this;
switch (_that) {
case _SalesMetrics():
return $default(_that.totalSales,_that.totalOrders,_that.averageOrderValue,_that.itemsSold,_that.categoryRevenue,_that.paymentMethodRevenue,_that.peakHour,_that.prepTimeAverage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double totalSales,  int totalOrders,  double averageOrderValue,  Map<String, int> itemsSold,  Map<String, double> categoryRevenue,  Map<String, double> paymentMethodRevenue,  double peakHour,  double prepTimeAverage)?  $default,) {final _that = this;
switch (_that) {
case _SalesMetrics() when $default != null:
return $default(_that.totalSales,_that.totalOrders,_that.averageOrderValue,_that.itemsSold,_that.categoryRevenue,_that.paymentMethodRevenue,_that.peakHour,_that.prepTimeAverage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SalesMetrics implements SalesMetrics {
  const _SalesMetrics({this.totalSales = 0, this.totalOrders = 0, this.averageOrderValue = 0, final  Map<String, int> itemsSold = const <String, int>{}, final  Map<String, double> categoryRevenue = const <String, double>{}, final  Map<String, double> paymentMethodRevenue = const <String, double>{}, this.peakHour = 0, this.prepTimeAverage = 0}): _itemsSold = itemsSold,_categoryRevenue = categoryRevenue,_paymentMethodRevenue = paymentMethodRevenue;
  factory _SalesMetrics.fromJson(Map<String, dynamic> json) => _$SalesMetricsFromJson(json);

@override@JsonKey() final  double totalSales;
@override@JsonKey() final  int totalOrders;
@override@JsonKey() final  double averageOrderValue;
 final  Map<String, int> _itemsSold;
@override@JsonKey() Map<String, int> get itemsSold {
  if (_itemsSold is EqualUnmodifiableMapView) return _itemsSold;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_itemsSold);
}

 final  Map<String, double> _categoryRevenue;
@override@JsonKey() Map<String, double> get categoryRevenue {
  if (_categoryRevenue is EqualUnmodifiableMapView) return _categoryRevenue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoryRevenue);
}

 final  Map<String, double> _paymentMethodRevenue;
@override@JsonKey() Map<String, double> get paymentMethodRevenue {
  if (_paymentMethodRevenue is EqualUnmodifiableMapView) return _paymentMethodRevenue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_paymentMethodRevenue);
}

@override@JsonKey() final  double peakHour;
@override@JsonKey() final  double prepTimeAverage;

/// Create a copy of SalesMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SalesMetricsCopyWith<_SalesMetrics> get copyWith => __$SalesMetricsCopyWithImpl<_SalesMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SalesMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SalesMetrics&&(identical(other.totalSales, totalSales) || other.totalSales == totalSales)&&(identical(other.totalOrders, totalOrders) || other.totalOrders == totalOrders)&&(identical(other.averageOrderValue, averageOrderValue) || other.averageOrderValue == averageOrderValue)&&const DeepCollectionEquality().equals(other._itemsSold, _itemsSold)&&const DeepCollectionEquality().equals(other._categoryRevenue, _categoryRevenue)&&const DeepCollectionEquality().equals(other._paymentMethodRevenue, _paymentMethodRevenue)&&(identical(other.peakHour, peakHour) || other.peakHour == peakHour)&&(identical(other.prepTimeAverage, prepTimeAverage) || other.prepTimeAverage == prepTimeAverage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalSales,totalOrders,averageOrderValue,const DeepCollectionEquality().hash(_itemsSold),const DeepCollectionEquality().hash(_categoryRevenue),const DeepCollectionEquality().hash(_paymentMethodRevenue),peakHour,prepTimeAverage);

@override
String toString() {
  return 'SalesMetrics(totalSales: $totalSales, totalOrders: $totalOrders, averageOrderValue: $averageOrderValue, itemsSold: $itemsSold, categoryRevenue: $categoryRevenue, paymentMethodRevenue: $paymentMethodRevenue, peakHour: $peakHour, prepTimeAverage: $prepTimeAverage)';
}


}

/// @nodoc
abstract mixin class _$SalesMetricsCopyWith<$Res> implements $SalesMetricsCopyWith<$Res> {
  factory _$SalesMetricsCopyWith(_SalesMetrics value, $Res Function(_SalesMetrics) _then) = __$SalesMetricsCopyWithImpl;
@override @useResult
$Res call({
 double totalSales, int totalOrders, double averageOrderValue, Map<String, int> itemsSold, Map<String, double> categoryRevenue, Map<String, double> paymentMethodRevenue, double peakHour, double prepTimeAverage
});




}
/// @nodoc
class __$SalesMetricsCopyWithImpl<$Res>
    implements _$SalesMetricsCopyWith<$Res> {
  __$SalesMetricsCopyWithImpl(this._self, this._then);

  final _SalesMetrics _self;
  final $Res Function(_SalesMetrics) _then;

/// Create a copy of SalesMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalSales = null,Object? totalOrders = null,Object? averageOrderValue = null,Object? itemsSold = null,Object? categoryRevenue = null,Object? paymentMethodRevenue = null,Object? peakHour = null,Object? prepTimeAverage = null,}) {
  return _then(_SalesMetrics(
totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as double,totalOrders: null == totalOrders ? _self.totalOrders : totalOrders // ignore: cast_nullable_to_non_nullable
as int,averageOrderValue: null == averageOrderValue ? _self.averageOrderValue : averageOrderValue // ignore: cast_nullable_to_non_nullable
as double,itemsSold: null == itemsSold ? _self._itemsSold : itemsSold // ignore: cast_nullable_to_non_nullable
as Map<String, int>,categoryRevenue: null == categoryRevenue ? _self._categoryRevenue : categoryRevenue // ignore: cast_nullable_to_non_nullable
as Map<String, double>,paymentMethodRevenue: null == paymentMethodRevenue ? _self._paymentMethodRevenue : paymentMethodRevenue // ignore: cast_nullable_to_non_nullable
as Map<String, double>,peakHour: null == peakHour ? _self.peakHour : peakHour // ignore: cast_nullable_to_non_nullable
as double,prepTimeAverage: null == prepTimeAverage ? _self.prepTimeAverage : prepTimeAverage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
