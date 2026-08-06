// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CartItem _$CartItemFromJson(Map<String, dynamic> json) {
  return _CartItem.fromJson(json);
}

/// @nodoc
mixin _$CartItem {
  MenuItem get menuItem => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  List<MenuModifierOption> get selectedModifiers =>
      throw _privateConstructorUsedError;
  String? get specialNotes => throw _privateConstructorUsedError;

  /// Serializes this CartItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CartItemCopyWith<CartItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartItemCopyWith<$Res> {
  factory $CartItemCopyWith(CartItem value, $Res Function(CartItem) then) =
      _$CartItemCopyWithImpl<$Res, CartItem>;
  @useResult
  $Res call({
    MenuItem menuItem,
    int quantity,
    List<MenuModifierOption> selectedModifiers,
    String? specialNotes,
  });

  $MenuItemCopyWith<$Res> get menuItem;
}

/// @nodoc
class _$CartItemCopyWithImpl<$Res, $Val extends CartItem>
    implements $CartItemCopyWith<$Res> {
  _$CartItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menuItem = null,
    Object? quantity = null,
    Object? selectedModifiers = null,
    Object? specialNotes = freezed,
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
          )
          as $Val,
    );
  }

  /// Create a copy of CartItem
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
abstract class _$$CartItemImplCopyWith<$Res>
    implements $CartItemCopyWith<$Res> {
  factory _$$CartItemImplCopyWith(
    _$CartItemImpl value,
    $Res Function(_$CartItemImpl) then,
  ) = __$$CartItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    MenuItem menuItem,
    int quantity,
    List<MenuModifierOption> selectedModifiers,
    String? specialNotes,
  });

  @override
  $MenuItemCopyWith<$Res> get menuItem;
}

/// @nodoc
class __$$CartItemImplCopyWithImpl<$Res>
    extends _$CartItemCopyWithImpl<$Res, _$CartItemImpl>
    implements _$$CartItemImplCopyWith<$Res> {
  __$$CartItemImplCopyWithImpl(
    _$CartItemImpl _value,
    $Res Function(_$CartItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menuItem = null,
    Object? quantity = null,
    Object? selectedModifiers = null,
    Object? specialNotes = freezed,
  }) {
    return _then(
      _$CartItemImpl(
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CartItemImpl extends _CartItem {
  const _$CartItemImpl({
    required this.menuItem,
    this.quantity = 1,
    final List<MenuModifierOption> selectedModifiers =
        const <MenuModifierOption>[],
    this.specialNotes,
  }) : _selectedModifiers = selectedModifiers,
       super._();

  factory _$CartItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$CartItemImplFromJson(json);

  @override
  final MenuItem menuItem;
  @override
  @JsonKey()
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
  String toString() {
    return 'CartItem(menuItem: $menuItem, quantity: $quantity, selectedModifiers: $selectedModifiers, specialNotes: $specialNotes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CartItemImpl &&
            (identical(other.menuItem, menuItem) ||
                other.menuItem == menuItem) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            const DeepCollectionEquality().equals(
              other._selectedModifiers,
              _selectedModifiers,
            ) &&
            (identical(other.specialNotes, specialNotes) ||
                other.specialNotes == specialNotes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    menuItem,
    quantity,
    const DeepCollectionEquality().hash(_selectedModifiers),
    specialNotes,
  );

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CartItemImplCopyWith<_$CartItemImpl> get copyWith =>
      __$$CartItemImplCopyWithImpl<_$CartItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CartItemImplToJson(this);
  }
}

abstract class _CartItem extends CartItem {
  const factory _CartItem({
    required final MenuItem menuItem,
    final int quantity,
    final List<MenuModifierOption> selectedModifiers,
    final String? specialNotes,
  }) = _$CartItemImpl;
  const _CartItem._() : super._();

  factory _CartItem.fromJson(Map<String, dynamic> json) =
      _$CartItemImpl.fromJson;

  @override
  MenuItem get menuItem;
  @override
  int get quantity;
  @override
  List<MenuModifierOption> get selectedModifiers;
  @override
  String? get specialNotes;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CartItemImplCopyWith<_$CartItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
