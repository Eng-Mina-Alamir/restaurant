// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) {
  return _OrderItem.fromJson(json);
}

/// @nodoc
mixin _$OrderItem {
  MenuItem get menuItem => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  List<MenuModifierOption> get selectedModifiers =>
      throw _privateConstructorUsedError;
  String? get specialNotes => throw _privateConstructorUsedError;
  double get itemTotal => throw _privateConstructorUsedError;
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  DateTime get addedAt => throw _privateConstructorUsedError;

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderItemCopyWith<OrderItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderItemCopyWith<$Res> {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) then) =
      _$OrderItemCopyWithImpl<$Res, OrderItem>;
  @useResult
  $Res call({
    MenuItem menuItem,
    int quantity,
    List<MenuModifierOption> selectedModifiers,
    String? specialNotes,
    double itemTotal,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    DateTime addedAt,
  });

  $MenuItemCopyWith<$Res> get menuItem;
}

/// @nodoc
class _$OrderItemCopyWithImpl<$Res, $Val extends OrderItem>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menuItem = null,
    Object? quantity = null,
    Object? selectedModifiers = null,
    Object? specialNotes = freezed,
    Object? itemTotal = null,
    Object? addedAt = null,
  }) {
    return _then(
      _value.copyWith(
            menuItem: null == menuItem
                ? _value.menuItem
                : menuItem // ignore: cast_nullable_to_non_nullable
                      as MenuItem,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            selectedModifiers: null == selectedModifiers
                ? _value.selectedModifiers
                : selectedModifiers // ignore: cast_nullable_to_non_nullable
                      as List<MenuModifierOption>,
            specialNotes: freezed == specialNotes
                ? _value.specialNotes
                : specialNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            itemTotal: null == itemTotal
                ? _value.itemTotal
                : itemTotal // ignore: cast_nullable_to_non_nullable
                      as double,
            addedAt: null == addedAt
                ? _value.addedAt
                : addedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MenuItemCopyWith<$Res> get menuItem {
    return $MenuItemCopyWith<$Res>(_value.menuItem, (value) {
      return _then(_value.copyWith(menuItem: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OrderItemImplCopyWith<$Res>
    implements $OrderItemCopyWith<$Res> {
  factory _$$OrderItemImplCopyWith(
    _$OrderItemImpl value,
    $Res Function(_$OrderItemImpl) then,
  ) = __$$OrderItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    MenuItem menuItem,
    int quantity,
    List<MenuModifierOption> selectedModifiers,
    String? specialNotes,
    double itemTotal,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    DateTime addedAt,
  });

  @override
  $MenuItemCopyWith<$Res> get menuItem;
}

/// @nodoc
class __$$OrderItemImplCopyWithImpl<$Res>
    extends _$OrderItemCopyWithImpl<$Res, _$OrderItemImpl>
    implements _$$OrderItemImplCopyWith<$Res> {
  __$$OrderItemImplCopyWithImpl(
    _$OrderItemImpl _value,
    $Res Function(_$OrderItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menuItem = null,
    Object? quantity = null,
    Object? selectedModifiers = null,
    Object? specialNotes = freezed,
    Object? itemTotal = null,
    Object? addedAt = null,
  }) {
    return _then(
      _$OrderItemImpl(
        menuItem: null == menuItem
            ? _value.menuItem
            : menuItem // ignore: cast_nullable_to_non_nullable
                  as MenuItem,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        selectedModifiers: null == selectedModifiers
            ? _value._selectedModifiers
            : selectedModifiers // ignore: cast_nullable_to_non_nullable
                  as List<MenuModifierOption>,
        specialNotes: freezed == specialNotes
            ? _value.specialNotes
            : specialNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        itemTotal: null == itemTotal
            ? _value.itemTotal
            : itemTotal // ignore: cast_nullable_to_non_nullable
                  as double,
        addedAt: null == addedAt
            ? _value.addedAt
            : addedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$OrderItemImpl extends _OrderItem {
  const _$OrderItemImpl({
    required this.menuItem,
    required this.quantity,
    final List<MenuModifierOption> selectedModifiers =
        const <MenuModifierOption>[],
    this.specialNotes,
    this.itemTotal = 0,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required this.addedAt,
  }) : _selectedModifiers = selectedModifiers,
       super._();

  factory _$OrderItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderItemImplFromJson(json);

  @override
  final MenuItem menuItem;
  @override
  final int quantity;
  final List<MenuModifierOption> _selectedModifiers;
  @override
  @JsonKey()
  List<MenuModifierOption> get selectedModifiers {
    if (_selectedModifiers is EqualUnmodifiableListView)
      return _selectedModifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedModifiers);
  }

  @override
  final String? specialNotes;
  @override
  @JsonKey()
  final double itemTotal;
  @override
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  final DateTime addedAt;

  @override
  String toString() {
    return 'OrderItem(menuItem: $menuItem, quantity: $quantity, selectedModifiers: $selectedModifiers, specialNotes: $specialNotes, itemTotal: $itemTotal, addedAt: $addedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderItemImpl &&
            (identical(other.menuItem, menuItem) ||
                other.menuItem == menuItem) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            const DeepCollectionEquality().equals(
              other._selectedModifiers,
              _selectedModifiers,
            ) &&
            (identical(other.specialNotes, specialNotes) ||
                other.specialNotes == specialNotes) &&
            (identical(other.itemTotal, itemTotal) ||
                other.itemTotal == itemTotal) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    menuItem,
    quantity,
    const DeepCollectionEquality().hash(_selectedModifiers),
    specialNotes,
    itemTotal,
    addedAt,
  );

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      __$$OrderItemImplCopyWithImpl<_$OrderItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderItemImplToJson(this);
  }
}

abstract class _OrderItem extends OrderItem {
  const factory _OrderItem({
    required final MenuItem menuItem,
    required final int quantity,
    final List<MenuModifierOption> selectedModifiers,
    final String? specialNotes,
    final double itemTotal,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required final DateTime addedAt,
  }) = _$OrderItemImpl;
  const _OrderItem._() : super._();

  factory _OrderItem.fromJson(Map<String, dynamic> json) =
      _$OrderItemImpl.fromJson;

  @override
  MenuItem get menuItem;
  @override
  int get quantity;
  @override
  List<MenuModifierOption> get selectedModifiers;
  @override
  String? get specialNotes;
  @override
  double get itemTotal;
  @override
  @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
  DateTime get addedAt;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
