// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restaurant_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BusinessHours _$BusinessHoursFromJson(Map<String, dynamic> json) {
  return _BusinessHours.fromJson(json);
}

/// @nodoc
mixin _$BusinessHours {
  String get openTime => throw _privateConstructorUsedError;
  String get closeTime => throw _privateConstructorUsedError;

  /// Serializes this BusinessHours to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BusinessHours
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BusinessHoursCopyWith<BusinessHours> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BusinessHoursCopyWith<$Res> {
  factory $BusinessHoursCopyWith(
    BusinessHours value,
    $Res Function(BusinessHours) then,
  ) = _$BusinessHoursCopyWithImpl<$Res, BusinessHours>;
  @useResult
  $Res call({String openTime, String closeTime});
}

/// @nodoc
class _$BusinessHoursCopyWithImpl<$Res, $Val extends BusinessHours>
    implements $BusinessHoursCopyWith<$Res> {
  _$BusinessHoursCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BusinessHours
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? openTime = null, Object? closeTime = null}) {
    return _then(
      _value.copyWith(
            openTime: null == openTime
                ? _value.openTime
                : openTime // ignore: cast_nullable_to_non_nullable
                      as String,
            closeTime: null == closeTime
                ? _value.closeTime
                : closeTime // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BusinessHoursImplCopyWith<$Res>
    implements $BusinessHoursCopyWith<$Res> {
  factory _$$BusinessHoursImplCopyWith(
    _$BusinessHoursImpl value,
    $Res Function(_$BusinessHoursImpl) then,
  ) = __$$BusinessHoursImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String openTime, String closeTime});
}

/// @nodoc
class __$$BusinessHoursImplCopyWithImpl<$Res>
    extends _$BusinessHoursCopyWithImpl<$Res, _$BusinessHoursImpl>
    implements _$$BusinessHoursImplCopyWith<$Res> {
  __$$BusinessHoursImplCopyWithImpl(
    _$BusinessHoursImpl _value,
    $Res Function(_$BusinessHoursImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusinessHours
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? openTime = null, Object? closeTime = null}) {
    return _then(
      _$BusinessHoursImpl(
        openTime: null == openTime
            ? _value.openTime
            : openTime // ignore: cast_nullable_to_non_nullable
                  as String,
        closeTime: null == closeTime
            ? _value.closeTime
            : closeTime // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BusinessHoursImpl implements _BusinessHours {
  const _$BusinessHoursImpl({
    this.openTime = '10:00',
    this.closeTime = '23:00',
  });

  factory _$BusinessHoursImpl.fromJson(Map<String, dynamic> json) =>
      _$$BusinessHoursImplFromJson(json);

  @override
  @JsonKey()
  final String openTime;
  @override
  @JsonKey()
  final String closeTime;

  @override
  String toString() {
    return 'BusinessHours(openTime: $openTime, closeTime: $closeTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusinessHoursImpl &&
            (identical(other.openTime, openTime) ||
                other.openTime == openTime) &&
            (identical(other.closeTime, closeTime) ||
                other.closeTime == closeTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, openTime, closeTime);

  /// Create a copy of BusinessHours
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusinessHoursImplCopyWith<_$BusinessHoursImpl> get copyWith =>
      __$$BusinessHoursImplCopyWithImpl<_$BusinessHoursImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BusinessHoursImplToJson(this);
  }
}

abstract class _BusinessHours implements BusinessHours {
  const factory _BusinessHours({
    final String openTime,
    final String closeTime,
  }) = _$BusinessHoursImpl;

  factory _BusinessHours.fromJson(Map<String, dynamic> json) =
      _$BusinessHoursImpl.fromJson;

  @override
  String get openTime;
  @override
  String get closeTime;

  /// Create a copy of BusinessHours
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BusinessHoursImplCopyWith<_$BusinessHoursImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RestaurantEntity _$RestaurantEntityFromJson(Map<String, dynamic> json) {
  return _RestaurantEntity.fromJson(json);
}

/// @nodoc
mixin _$RestaurantEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String? get logoUrl => throw _privateConstructorUsedError;
  BusinessHours get hours => throw _privateConstructorUsedError;
  int get totalTables => throw _privateConstructorUsedError;
  List<String> get categories => throw _privateConstructorUsedError;

  /// Serializes this RestaurantEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RestaurantEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RestaurantEntityCopyWith<RestaurantEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RestaurantEntityCopyWith<$Res> {
  factory $RestaurantEntityCopyWith(
    RestaurantEntity value,
    $Res Function(RestaurantEntity) then,
  ) = _$RestaurantEntityCopyWithImpl<$Res, RestaurantEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    String address,
    String phone,
    double latitude,
    double longitude,
    String? logoUrl,
    BusinessHours hours,
    int totalTables,
    List<String> categories,
  });

  $BusinessHoursCopyWith<$Res> get hours;
}

/// @nodoc
class _$RestaurantEntityCopyWithImpl<$Res, $Val extends RestaurantEntity>
    implements $RestaurantEntityCopyWith<$Res> {
  _$RestaurantEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RestaurantEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? phone = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? logoUrl = freezed,
    Object? hours = null,
    Object? totalTables = null,
    Object? categories = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            logoUrl: freezed == logoUrl
                ? _value.logoUrl
                : logoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            hours: null == hours
                ? _value.hours
                : hours // ignore: cast_nullable_to_non_nullable
                      as BusinessHours,
            totalTables: null == totalTables
                ? _value.totalTables
                : totalTables // ignore: cast_nullable_to_non_nullable
                      as int,
            categories: null == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }

  /// Create a copy of RestaurantEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BusinessHoursCopyWith<$Res> get hours {
    return $BusinessHoursCopyWith<$Res>(_value.hours, (value) {
      return _then(_value.copyWith(hours: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RestaurantEntityImplCopyWith<$Res>
    implements $RestaurantEntityCopyWith<$Res> {
  factory _$$RestaurantEntityImplCopyWith(
    _$RestaurantEntityImpl value,
    $Res Function(_$RestaurantEntityImpl) then,
  ) = __$$RestaurantEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String address,
    String phone,
    double latitude,
    double longitude,
    String? logoUrl,
    BusinessHours hours,
    int totalTables,
    List<String> categories,
  });

  @override
  $BusinessHoursCopyWith<$Res> get hours;
}

/// @nodoc
class __$$RestaurantEntityImplCopyWithImpl<$Res>
    extends _$RestaurantEntityCopyWithImpl<$Res, _$RestaurantEntityImpl>
    implements _$$RestaurantEntityImplCopyWith<$Res> {
  __$$RestaurantEntityImplCopyWithImpl(
    _$RestaurantEntityImpl _value,
    $Res Function(_$RestaurantEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RestaurantEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? phone = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? logoUrl = freezed,
    Object? hours = null,
    Object? totalTables = null,
    Object? categories = null,
  }) {
    return _then(
      _$RestaurantEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        logoUrl: freezed == logoUrl
            ? _value.logoUrl
            : logoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        hours: null == hours
            ? _value.hours
            : hours // ignore: cast_nullable_to_non_nullable
                  as BusinessHours,
        totalTables: null == totalTables
            ? _value.totalTables
            : totalTables // ignore: cast_nullable_to_non_nullable
                  as int,
        categories: null == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$RestaurantEntityImpl implements _RestaurantEntity {
  const _$RestaurantEntityImpl({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.latitude = 0,
    this.longitude = 0,
    this.logoUrl,
    this.hours = const BusinessHours(),
    this.totalTables = 0,
    final List<String> categories = const <String>[],
  }) : _categories = categories;

  factory _$RestaurantEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$RestaurantEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String address;
  @override
  final String phone;
  @override
  @JsonKey()
  final double latitude;
  @override
  @JsonKey()
  final double longitude;
  @override
  final String? logoUrl;
  @override
  @JsonKey()
  final BusinessHours hours;
  @override
  @JsonKey()
  final int totalTables;
  final List<String> _categories;
  @override
  @JsonKey()
  List<String> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  String toString() {
    return 'RestaurantEntity(id: $id, name: $name, address: $address, phone: $phone, latitude: $latitude, longitude: $longitude, logoUrl: $logoUrl, hours: $hours, totalTables: $totalTables, categories: $categories)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestaurantEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.hours, hours) || other.hours == hours) &&
            (identical(other.totalTables, totalTables) ||
                other.totalTables == totalTables) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    address,
    phone,
    latitude,
    longitude,
    logoUrl,
    hours,
    totalTables,
    const DeepCollectionEquality().hash(_categories),
  );

  /// Create a copy of RestaurantEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RestaurantEntityImplCopyWith<_$RestaurantEntityImpl> get copyWith =>
      __$$RestaurantEntityImplCopyWithImpl<_$RestaurantEntityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RestaurantEntityImplToJson(this);
  }
}

abstract class _RestaurantEntity implements RestaurantEntity {
  const factory _RestaurantEntity({
    required final String id,
    required final String name,
    required final String address,
    required final String phone,
    final double latitude,
    final double longitude,
    final String? logoUrl,
    final BusinessHours hours,
    final int totalTables,
    final List<String> categories,
  }) = _$RestaurantEntityImpl;

  factory _RestaurantEntity.fromJson(Map<String, dynamic> json) =
      _$RestaurantEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get address;
  @override
  String get phone;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String? get logoUrl;
  @override
  BusinessHours get hours;
  @override
  int get totalTables;
  @override
  List<String> get categories;

  /// Create a copy of RestaurantEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RestaurantEntityImplCopyWith<_$RestaurantEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
