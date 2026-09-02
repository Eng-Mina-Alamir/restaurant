import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../domain/entities/cart_item.dart';

/// Persists the customer cart in Supabase (`cart_items` +
/// `cart_item_modifiers`) so a cart survives app restarts and device swaps.
///
/// Save is delete-then-insert: the server always mirrors the last local
/// snapshot, which keeps the operation idempotent and sidesteps merge logic.
/// Row ids are deterministic (`<userHash>ci<i>` / `...cim<i>_<j>`) so re-saving
/// the same cart never collides with the composite UNIQUE pairs added by the
/// integrity migration.
class SupabaseCartRepository {
  SupabaseCartRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Replaces the stored cart for [userId] with [items].
  ///
  /// Issues at most two insert calls per save (one batch per table) so a
  /// large cart never costs N+1 round trips.
  Future<Either<Failure, void>> saveCart(
    String userId,
    List<CartItem> items,
  ) async {
    try {
      await _deleteUserRows(userId);

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final menuItemId = int.tryParse(item.menuItem.id) ?? item.menuItem.id;
        final insertedItem = await _supabase.from(SupabaseConfig.cartItemsTable).insert({
          'user_id': userId,
          'menu_item_id': menuItemId,
          'quantity': item.quantity.clamp(1, 99),
          if (item.specialNotes != null) 'special_notes': item.specialNotes,
        }).select('id').single();

        final dynamic generatedCartItemId = insertedItem['id'];
        final modifierRows = <Map<String, dynamic>>[];
        for (final mod in item.selectedModifiers) {
          final modOptionId = int.tryParse(mod.id) ?? mod.id;
          modifierRows.add({
            'cart_item_id': generatedCartItemId,
            'modifier_option_id': modOptionId,
          });
        }
        if (modifierRows.isNotEmpty) {
          await _supabase
              .from(SupabaseConfig.cartItemModifiersTable)
              .insert(modifierRows);
        }
      }
      return const Right<Failure, void>(null);
    } catch (e) {
      AppLogger.warning('Supabase saveCart failed for $userId: $e');
      return Left<Failure, void>(ServerFailure('فشل حفظ السلة: $e'));
    }
  }

  /// Loads the persisted cart for [userId], or an empty list when nothing is
  /// stored. Menu/modifier details are rebuilt through PostgREST embeddings on
  /// the existing FKs (`menu_items`, `menu_modifier_options`).
  Future<Either<Failure, List<CartItem>>> loadCart(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.cartItemsTable)
          .select(
            '*, menu_items(*), cart_item_modifiers(*, '
            'menu_modifier_options(*))',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      final items = <CartItem>[];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final menuItem = _menuItemFromJoin(
          map['menu_items'] == null
              ? null
              : Map<String, dynamic>.from(map['menu_items'] as Map),
        );
        if (menuItem == null) continue;

        final modifierRows = (map['cart_item_modifiers'] as List?) ?? const [];
        final modifiers = modifierRows
            .map((m) => _modifierFromJoin(Map<String, dynamic>.from(m as Map)))
            .whereType<MenuModifierOption>()
            .toList();

        items.add(
          CartItem(
            menuItem: menuItem,
            quantity: (map['quantity'] as num?)?.toInt() ?? 1,
            selectedModifiers: modifiers,
            specialNotes: map['special_notes'] as String?,
          ),
        );
      }
      return Right<Failure, List<CartItem>>(items);
    } catch (e) {
      AppLogger.warning('Supabase loadCart failed for $userId: $e');
      return Left<Failure, List<CartItem>>(
        ServerFailure('فشل استرجاع السلة: $e'),
      );
    }
  }

  /// Removes every stored row for [userId].
  Future<Either<Failure, void>> clearCart(String userId) async {
    try {
      await _deleteUserRows(userId);
      return const Right<Failure, void>(null);
    } catch (e) {
      AppLogger.warning('Supabase clearCart failed for $userId: $e');
      return Left<Failure, void>(ServerFailure('فشل تفريغ السلة المخزنة: $e'));
    }
  }

  // ── internals ──────────────────────────────────────────────────────────────

  Future<void> _deleteUserRows(String userId) async {
    final owned = await _supabase
        .from(SupabaseConfig.cartItemsTable)
        .select('id')
        .eq('user_id', userId);
    final ids = [
      for (final raw in (owned as List))
        (Map<String, dynamic>.from(raw as Map))['id'],
    ].where((id) => id != null).toList();
    if (ids.isNotEmpty) {
      await _supabase
          .from(SupabaseConfig.cartItemModifiersTable)
          .delete()
          .inFilter('cart_item_id', ids);
    }
    await _supabase
        .from(SupabaseConfig.cartItemsTable)
        .delete()
        .eq('user_id', userId);
  }


  MenuItem? _menuItemFromJoin(Map<String, dynamic>? map) {
    if (map == null) return null;
    return MenuItem(
      id: map['id']?.toString() ?? '',
      categoryId: map['category_id'] as String? ?? 'عام',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image_url'] as String?,
      isAvailable: map['is_available'] as bool? ?? true,
      isVegetarian: map['is_vegetarian'] as bool? ?? false,
      isSpicy: map['is_spicy'] as bool? ?? false,
      preparationTime: (map['preparation_time'] as num?)?.toDouble(),
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      orderCount: (map['order_count'] as num?)?.toInt() ?? 0,
    );
  }

  MenuModifierOption? _modifierFromJoin(Map<String, dynamic> row) {
    final option = row['menu_modifier_options'];
    if (option == null) return null;
    final map = Map<String, dynamic>.from(option as Map);
    return MenuModifierOption(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      extraPrice: (map['extra_price'] as num?)?.toDouble() ?? 0.0,
      isAvailable: map['is_available'] as bool? ?? true,
    );
  }
}
