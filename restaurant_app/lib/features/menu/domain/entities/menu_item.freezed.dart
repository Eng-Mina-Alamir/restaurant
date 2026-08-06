// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MenuModifierOption _$MenuModifierOptionFromJson(Map<String, dynamic> json) {
  return _MenuModifierOption.fromJson(json);
}

/// @nodoc
mixin _$MenuModifierOption {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get extraPrice => throw _privateConstructorUsedError;
  bool get isAvailable => throw _privateConstructorUsedError;

  /// Serializes this MenuModifierOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuModifierOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuModifierOptionCopyWith<MenuModifierOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuModifierOptionCopyWith<$Res> {
  factory $MenuModifierOptionCopyWith(
    MenuModifierOption value,
    $Res Function(MenuModifierOption) then,
  ) = _$MenuModifierOptionCopyWithImpl<$Res, MenuModifierOption>;
  @useResult
  $Res call({String id, String name, double extraPrice, bool isAvailable});
}

/// @nodoc
class _$MenuModifierOptionCopyWithImpl<$Res, $Val extends MenuModifierOption>
    implements $MenuModifierOptionCopyWith<$Res> {
  _$MenuModifierOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuModifierOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? extraPrice = null,
    Object? isAvailable = null,
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
            extraPrice: null == extraPrice
                ? _value.extraPrice
                : extraPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            isAvailable: null == isAvailable
                ? _value.isAvailable
                : isAvailable // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MenuModifierOptionImplCopyWith<$Res>
    implements $MenuModifierOptionCopyWith<$Res> {
  factory _$$MenuModifierOptionImplCopyWith(
    _$MenuModifierOptionImpl value,
    $Res Function(_$MenuModifierOptionImpl) then,
  ) = __$$MenuModifierOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, double extraPrice, bool isAvailable});
}

/// @nodoc
class __$$MenuModifierOptionImplCopyWithImpl<$Res>
    extends _$MenuModifierOptionCopyWithImpl<$Res, _$MenuModifierOptionImpl>
    implements _$$MenuModifierOptionImplCopyWith<$Res> {
  __$$MenuModifierOptionImplCopyWithImpl(
    _$MenuModifierOptionImpl _value,
    $Res Function(_$MenuModifierOptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MenuModifierOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? extraPrice = null,
    Object? isAvailable = null,
  }) {
    return _then(
      _$MenuModifierOptionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        extraPrice: null == extraPrice
            ? _value.extraPrice
            : extraPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        isAvailable: null == isAvailable
            ? _value.isAvailable
            : isAvailable // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuModifierOptionImpl implements _MenuModifierOption {
  const _$MenuModifierOptionImpl({
    required this.id,
    required this.name,
    this.extraPrice = 0,
    this.isAvailable = true,
  });

  factory _$MenuModifierOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuModifierOptionImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final double extraPrice;
  @override
  @JsonKey()
  final bool isAvailable;

  @override
  String toString() {
    return 'MenuModifierOption(id: $id, name: $name, extraPrice: $extraPrice, isAvailable: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuModifierOptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.extraPrice, extraPrice) ||
                other.extraPrice == extraPrice) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, extraPrice, isAvailable);

  /// Create a copy of MenuModifierOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuModifierOptionImplCopyWith<_$MenuModifierOptionImpl> get copyWith =>
      __$$MenuModifierOptionImplCopyWithImpl<_$MenuModifierOptionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuModifierOptionImplToJson(this);
  }
}

abstract class _MenuModifierOption implements MenuModifierOption {
  const factory _MenuModifierOption({
    required final String id,
    required final String name,
    final double extraPrice,
    final bool isAvailable,
  }) = _$MenuModifierOptionImpl;

  factory _MenuModifierOption.fromJson(Map<String, dynamic> json) =
      _$MenuModifierOptionImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get extraPrice;
  @override
  bool get isAvailable;

  /// Create a copy of MenuModifierOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuModifierOptionImplCopyWith<_$MenuModifierOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MenuModifierGroup _$MenuModifierGroupFromJson(Map<String, dynamic> json) {
  return _MenuModifierGroup.fromJson(json);
}

/// @nodoc
mixin _$MenuModifierGroup {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  bool get isRequired => throw _privateConstructorUsedError;
  int get maxSelection => throw _privateConstructorUsedError;
  List<MenuModifierOption> get options => throw _privateConstructorUsedError;

  /// Serializes this MenuModifierGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuModifierGroupCopyWith<MenuModifierGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuModifierGroupCopyWith<$Res> {
  factory $MenuModifierGroupCopyWith(
    MenuModifierGroup value,
    $Res Function(MenuModifierGroup) then,
  ) = _$MenuModifierGroupCopyWithImpl<$Res, MenuModifierGroup>;
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    bool isRequired,
    int maxSelection,
    List<MenuModifierOption> options,
  });
}

/// @nodoc
class _$MenuModifierGroupCopyWithImpl<$Res, $Val extends MenuModifierGroup>
    implements $MenuModifierGroupCopyWith<$Res> {
  _$MenuModifierGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? isRequired = null,
    Object? maxSelection = null,
    Object? options = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            isRequired: null == isRequired
                ? _value.isRequired
                : isRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
            maxSelection: null == maxSelection
                ? _value.maxSelection
                : maxSelection // ignore: cast_nullable_to_non_nullable
                      as int,
            options: null == options
                ? _value.options
                : options // ignore: cast_nullable_to_non_nullable
                      as List<MenuModifierOption>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MenuModifierGroupImplCopyWith<$Res>
    implements $MenuModifierGroupCopyWith<$Res> {
  factory _$$MenuModifierGroupImplCopyWith(
    _$MenuModifierGroupImpl value,
    $Res Function(_$MenuModifierGroupImpl) then,
  ) = __$$MenuModifierGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    bool isRequired,
    int maxSelection,
    List<MenuModifierOption> options,
  });
}

/// @nodoc
class __$$MenuModifierGroupImplCopyWithImpl<$Res>
    extends _$MenuModifierGroupCopyWithImpl<$Res, _$MenuModifierGroupImpl>
    implements _$$MenuModifierGroupImplCopyWith<$Res> {
  __$$MenuModifierGroupImplCopyWithImpl(
    _$MenuModifierGroupImpl _value,
    $Res Function(_$MenuModifierGroupImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MenuModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? isRequired = null,
    Object? maxSelection = null,
    Object? options = null,
  }) {
    return _then(
      _$MenuModifierGroupImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        isRequired: null == isRequired
            ? _value.isRequired
            : isRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
        maxSelection: null == maxSelection
            ? _value.maxSelection
            : maxSelection // ignore: cast_nullable_to_non_nullable
                  as int,
        options: null == options
            ? _value._options
            : options // ignore: cast_nullable_to_non_nullable
                  as List<MenuModifierOption>,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MenuModifierGroupImpl implements _MenuModifierGroup {
  const _$MenuModifierGroupImpl({
    required this.id,
    required this.title,
    this.description,
    this.isRequired = false,
    this.maxSelection = 1,
    final List<MenuModifierOption> options = const <MenuModifierOption>[],
  }) : _options = options;

  factory _$MenuModifierGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuModifierGroupImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey()
  final bool isRequired;
  @override
  @JsonKey()
  final int maxSelection;
  final List<MenuModifierOption> _options;
  @override
  @JsonKey()
  List<MenuModifierOption> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  @override
  String toString() {
    return 'MenuModifierGroup(id: $id, title: $title, description: $description, isRequired: $isRequired, maxSelection: $maxSelection, options: $options)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuModifierGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isRequired, isRequired) ||
                other.isRequired == isRequired) &&
            (identical(other.maxSelection, maxSelection) ||
                other.maxSelection == maxSelection) &&
            const DeepCollectionEquality().equals(other._options, _options));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    isRequired,
    maxSelection,
    const DeepCollectionEquality().hash(_options),
  );

  /// Create a copy of MenuModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuModifierGroupImplCopyWith<_$MenuModifierGroupImpl> get copyWith =>
      __$$MenuModifierGroupImplCopyWithImpl<_$MenuModifierGroupImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuModifierGroupImplToJson(this);
  }
}

abstract class _MenuModifierGroup implements MenuModifierGroup {
  const factory _MenuModifierGroup({
    required final String id,
    required final String title,
    final String? description,
    final bool isRequired,
    final int maxSelection,
    final List<MenuModifierOption> options,
  }) = _$MenuModifierGroupImpl;

  factory _MenuModifierGroup.fromJson(Map<String, dynamic> json) =
      _$MenuModifierGroupImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  bool get isRequired;
  @override
  int get maxSelection;
  @override
  List<MenuModifierOption> get options;

  /// Create a copy of MenuModifierGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuModifierGroupImplCopyWith<_$MenuModifierGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MenuItem _$MenuItemFromJson(Map<String, dynamic> json) {
  return _MenuItem.fromJson(json);
}

/// @nodoc
mixin _$MenuItem {
  String get id => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  bool get isAvailable => throw _privateConstructorUsedError;
  bool get isVegetarian => throw _privateConstructorUsedError;
  bool get isSpicy => throw _privateConstructorUsedError;
  double? get preparationTime => throw _privateConstructorUsedError;
  List<MenuModifierGroup> get modifierGroups =>
      throw _privateConstructorUsedError;
  double? get rating => throw _privateConstructorUsedError;
  int? get orderCount => throw _privateConstructorUsedError;

  /// Serializes this MenuItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuItemCopyWith<MenuItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuItemCopyWith<$Res> {
  factory $MenuItemCopyWith(MenuItem value, $Res Function(MenuItem) then) =
      _$MenuItemCopyWithImpl<$Res, MenuItem>;
  @useResult
  $Res call({
    String id,
    String categoryId,
    String name,
    String description,
    double price,
    String? imageUrl,
    bool isAvailable,
    bool isVegetarian,
    bool isSpicy,
    double? preparationTime,
    List<MenuModifierGroup> modifierGroups,
    double? rating,
    int? orderCount,
  });
}

/// @nodoc
class _$MenuItemCopyWithImpl<$Res, $Val extends MenuItem>
    implements $MenuItemCopyWith<$Res> {
  _$MenuItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? imageUrl = freezed,
    Object? isAvailable = null,
    Object? isVegetarian = null,
    Object? isSpicy = null,
    Object? preparationTime = freezed,
    Object? modifierGroups = null,
    Object? rating = freezed,
    Object? orderCount = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            isAvailable: null == isAvailable
                ? _value.isAvailable
                : isAvailable // ignore: cast_nullable_to_non_nullable
                      as bool,
            isVegetarian: null == isVegetarian
                ? _value.isVegetarian
                : isVegetarian // ignore: cast_nullable_to_non_nullable
                      as bool,
            isSpicy: null == isSpicy
                ? _value.isSpicy
                : isSpicy // ignore: cast_nullable_to_non_nullable
                      as bool,
            preparationTime: freezed == preparationTime
                ? _value.preparationTime
                : preparationTime // ignore: cast_nullable_to_non_nullable
                      as double?,
            modifierGroups: null == modifierGroups
                ? _value.modifierGroups
                : modifierGroups // ignore: cast_nullable_to_non_nullable
                      as List<MenuModifierGroup>,
            rating: freezed == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double?,
            orderCount: freezed == orderCount
                ? _value.orderCount
                : orderCount // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MenuItemImplCopyWith<$Res>
    implements $MenuItemCopyWith<$Res> {
  factory _$$MenuItemImplCopyWith(
    _$MenuItemImpl value,
    $Res Function(_$MenuItemImpl) then,
  ) = __$$MenuItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String categoryId,
    String name,
    String description,
    double price,
    String? imageUrl,
    bool isAvailable,
    bool isVegetarian,
    bool isSpicy,
    double? preparationTime,
    List<MenuModifierGroup> modifierGroups,
    double? rating,
    int? orderCount,
  });
}

/// @nodoc
class __$$MenuItemImplCopyWithImpl<$Res>
    extends _$MenuItemCopyWithImpl<$Res, _$MenuItemImpl>
    implements _$$MenuItemImplCopyWith<$Res> {
  __$$MenuItemImplCopyWithImpl(
    _$MenuItemImpl _value,
    $Res Function(_$MenuItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? categoryId = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? imageUrl = freezed,
    Object? isAvailable = null,
    Object? isVegetarian = null,
    Object? isSpicy = null,
    Object? preparationTime = freezed,
    Object? modifierGroups = null,
    Object? rating = freezed,
    Object? orderCount = freezed,
  }) {
    return _then(
      _$MenuItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        isAvailable: null == isAvailable
            ? _value.isAvailable
            : isAvailable // ignore: cast_nullable_to_non_nullable
                  as bool,
        isVegetarian: null == isVegetarian
            ? _value.isVegetarian
            : isVegetarian // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSpicy: null == isSpicy
            ? _value.isSpicy
            : isSpicy // ignore: cast_nullable_to_non_nullable
                  as bool,
        preparationTime: freezed == preparationTime
            ? _value.preparationTime
            : preparationTime // ignore: cast_nullable_to_non_nullable
                  as double?,
        modifierGroups: null == modifierGroups
            ? _value._modifierGroups
            : modifierGroups // ignore: cast_nullable_to_non_nullable
                  as List<MenuModifierGroup>,
        rating: freezed == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double?,
        orderCount: freezed == orderCount
            ? _value.orderCount
            : orderCount // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MenuItemImpl implements _MenuItem {
  const _$MenuItemImpl({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.isVegetarian = false,
    this.isSpicy = false,
    this.preparationTime,
    final List<MenuModifierGroup> modifierGroups = const <MenuModifierGroup>[],
    this.rating,
    this.orderCount,
  }) : _modifierGroups = modifierGroups;

  factory _$MenuItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuItemImplFromJson(json);

  @override
  final String id;
  @override
  final String categoryId;
  @override
  final String name;
  @override
  final String description;
  @override
  final double price;
  @override
  final String? imageUrl;
  @override
  @JsonKey()
  final bool isAvailable;
  @override
  @JsonKey()
  final bool isVegetarian;
  @override
  @JsonKey()
  final bool isSpicy;
  @override
  final double? preparationTime;
  final List<MenuModifierGroup> _modifierGroups;
  @override
  @JsonKey()
  List<MenuModifierGroup> get modifierGroups {
    if (_modifierGroups is EqualUnmodifiableListView) return _modifierGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifierGroups);
  }

  @override
  final double? rating;
  @override
  final int? orderCount;

  @override
  String toString() {
    return 'MenuItem(id: $id, categoryId: $categoryId, name: $name, description: $description, price: $price, imageUrl: $imageUrl, isAvailable: $isAvailable, isVegetarian: $isVegetarian, isSpicy: $isSpicy, preparationTime: $preparationTime, modifierGroups: $modifierGroups, rating: $rating, orderCount: $orderCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.isVegetarian, isVegetarian) ||
                other.isVegetarian == isVegetarian) &&
            (identical(other.isSpicy, isSpicy) || other.isSpicy == isSpicy) &&
            (identical(other.preparationTime, preparationTime) ||
                other.preparationTime == preparationTime) &&
            const DeepCollectionEquality().equals(
              other._modifierGroups,
              _modifierGroups,
            ) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.orderCount, orderCount) ||
                other.orderCount == orderCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    categoryId,
    name,
    description,
    price,
    imageUrl,
    isAvailable,
    isVegetarian,
    isSpicy,
    preparationTime,
    const DeepCollectionEquality().hash(_modifierGroups),
    rating,
    orderCount,
  );

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuItemImplCopyWith<_$MenuItemImpl> get copyWith =>
      __$$MenuItemImplCopyWithImpl<_$MenuItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuItemImplToJson(this);
  }
}

abstract class _MenuItem implements MenuItem {
  const factory _MenuItem({
    required final String id,
    required final String categoryId,
    required final String name,
    required final String description,
    required final double price,
    final String? imageUrl,
    final bool isAvailable,
    final bool isVegetarian,
    final bool isSpicy,
    final double? preparationTime,
    final List<MenuModifierGroup> modifierGroups,
    final double? rating,
    final int? orderCount,
  }) = _$MenuItemImpl;

  factory _MenuItem.fromJson(Map<String, dynamic> json) =
      _$MenuItemImpl.fromJson;

  @override
  String get id;
  @override
  String get categoryId;
  @override
  String get name;
  @override
  String get description;
  @override
  double get price;
  @override
  String? get imageUrl;
  @override
  bool get isAvailable;
  @override
  bool get isVegetarian;
  @override
  bool get isSpicy;
  @override
  double? get preparationTime;
  @override
  List<MenuModifierGroup> get modifierGroups;
  @override
  double? get rating;
  @override
  int? get orderCount;

  /// Create a copy of MenuItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuItemImplCopyWith<_$MenuItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
