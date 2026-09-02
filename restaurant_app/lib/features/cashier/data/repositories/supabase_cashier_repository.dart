import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/cash_drawer_transaction_entity.dart';
import '../../domain/entities/held_order_entity.dart';
import '../../domain/entities/loyalty_customer_entity.dart';

/// Supabase-backed repository for Cashier POS, cash drawer movements, held orders, and loyalty search.
class SupabaseCashierRepository {
  SupabaseCashierRepository({
    required SupabaseClient supabase,
    LocalCacheService? cache,
  })  : _supabase = supabase,
        _cache = cache;

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;

  static const String _drawerCacheKeyPrefix = 'cash_drawer_';
  static const String _heldOrdersCacheKey = 'held_orders_v1';

  // ── Cash Drawer ─────────────────────────────────────────────────────────────

  Future<Either<Failure, List<CashDrawerTransaction>>> getTransactions(String shiftId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.cashDrawerTransactionsTable)
          .select()
          .eq('shift_id', shiftId)
          .order('created_at', ascending: false);

      final list = (response as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return CashDrawerTransaction(
          id: map['id']?.toString() ?? '',
          shiftId: map['shift_id'] as String? ?? shiftId,
          type: CashDrawerTransactionType.values.firstWhere(
            (t) => t.name == map['type'],
            orElse: () => CashDrawerTransactionType.payIn,
          ),
          amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
          reason: map['reason'] as String? ?? '',
          timestamp: map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
          recipientOrDepositor: map['recipient_or_depositor'] as String?,
          authorizedByManagerPin: map['authorized_by_manager_pin'] as String?,
        );
      }).toList();

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          '$_drawerCacheKeyPrefix$shiftId',
          list.map((tx) => {
            'id': tx.id,
            'shiftId': tx.shiftId,
            'type': tx.type.name,
            'amount': tx.amount,
            'reason': tx.reason,
            'timestamp': tx.timestamp.toIso8601String(),
            'recipientOrDepositor': tx.recipientOrDepositor,
            'authorizedByManagerPin': tx.authorizedByManagerPin,
          }).toList(),
        );
      }

      return Right(list);
    } catch (e, st) {
      AppLogger.warning('Supabase getTransactions failed: $e, using local cache', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readList('$_drawerCacheKeyPrefix$shiftId');
        if (cached.isNotEmpty) {
          final list = cached.map((map) {
            return CashDrawerTransaction(
              id: map['id']?.toString() ?? '',
              shiftId: map['shiftId'] as String? ?? shiftId,
              type: CashDrawerTransactionType.values.firstWhere(
                (t) => t.name == map['type'],
                orElse: () => CashDrawerTransactionType.payIn,
              ),
              amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
              reason: map['reason'] as String? ?? '',
              timestamp: map['timestamp'] != null
                  ? DateTime.parse(map['timestamp'] as String)
                  : DateTime.now(),
              recipientOrDepositor: map['recipientOrDepositor'] as String?,
              authorizedByManagerPin: map['authorizedByManagerPin'] as String?,
            );
          }).toList();
          return Right(list);
        }
      }
      return const Right([]);
    }
  }

  Future<Either<Failure, CashDrawerTransaction>> recordTransaction(CashDrawerTransaction tx) async {
    try {
      final payload = {
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
        'shift_id': tx.shiftId,
        'type': tx.type.name,
        'amount': tx.amount,
        'reason': tx.reason,
        'recipient_or_depositor': tx.recipientOrDepositor,
        'authorized_by_manager_pin': tx.authorizedByManagerPin,
        'created_at': tx.timestamp.toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseConfig.cashDrawerTransactionsTable)
          .insert(payload)
          .select()
          .single();

      final created = tx.copyWith(id: response['id']?.toString() ?? tx.id);
      return Right(created);
    } catch (e, st) {
      AppLogger.error('Supabase recordTransaction failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل تسجيل حركة الدرج: $e'));
    }
  }

  // ── Held Orders ─────────────────────────────────────────────────────────────

  Future<Either<Failure, List<HeldOrderEntity>>> getHeldOrders() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.heldOrdersTable)
          .select()
          .order('created_at', ascending: false);

      final list = (response as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final itemsRaw = map['cart_items_json'] as List? ?? [];
        final items = itemsRaw
            .whereType<Map>()
            .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        return HeldOrderEntity(
          id: map['id']?.toString() ?? '',
          label: map['custom_label'] as String? ?? 'طلب معلق',
          items: items,
          parkedAt: map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
          customerPhone: map['customer_phone'] as String?,
          tableNumber: (map['table_number'] as num?)?.toInt(),
          notes: map['notes'] as String?,
        );
      }).toList();

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _heldOrdersCacheKey,
          list.map((h) => {
            'id': h.id,
            'label': h.label,
            'items': h.items.map((i) => i.toJson()).toList(),
            'parkedAt': h.parkedAt.toIso8601String(),
            'customerPhone': h.customerPhone,
            'tableNumber': h.tableNumber,
            'notes': h.notes,
          }).toList(),
        );
      }

      return Right(list);
    } catch (e, st) {
      AppLogger.warning('Supabase getHeldOrders failed: $e, using local cache', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readList(_heldOrdersCacheKey);
        if (cached.isNotEmpty) {
          final list = cached.map((map) {
            final itemsRaw = map['items'] as List? ?? [];
            final items = itemsRaw
                .whereType<Map>()
                .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
                .toList();

            return HeldOrderEntity(
              id: map['id']?.toString() ?? '',
              label: map['label'] as String? ?? 'طلب معلق',
              items: items,
              parkedAt: map['parkedAt'] != null
                  ? DateTime.parse(map['parkedAt'] as String)
                  : DateTime.now(),
              customerPhone: map['customerPhone'] as String?,
              tableNumber: (map['tableNumber'] as num?)?.toInt(),
              notes: map['notes'] as String?,
            );
          }).toList();
          return Right(list);
        }
      }
      return const Right([]);
    }
  }

  Future<Either<Failure, HeldOrderEntity>> saveHeldOrder(HeldOrderEntity heldOrder) async {
    try {
      final payload = {
        'id': heldOrder.id,
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
        'cart_items_json': heldOrder.items.map((i) => i.toJson()).toList(),
        'custom_label': heldOrder.label,
        'customer_phone': heldOrder.customerPhone,
        'table_number': heldOrder.tableNumber,
        'notes': heldOrder.notes,
        'created_at': heldOrder.parkedAt.toIso8601String(),
      };

      await _supabase.from(SupabaseConfig.heldOrdersTable).upsert(payload);
      return Right(heldOrder);
    } catch (e, st) {
      AppLogger.error('Supabase saveHeldOrder failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل تعليق الطلب في السيرفر: $e'));
    }
  }

  Future<Either<Failure, void>> deleteHeldOrder(String heldOrderId) async {
    try {
      await _supabase
          .from(SupabaseConfig.heldOrdersTable)
          .delete()
          .eq('id', heldOrderId);
      return const Right(null);
    } catch (e, st) {
      AppLogger.error('Supabase deleteHeldOrder failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل حذف الطلب المعلق: $e'));
    }
  }

  // ── Customer Loyalty Search ─────────────────────────────────────────────────

  Future<Either<Failure, List<LoyaltyCustomer>>> searchLoyaltyCustomers(String query) async {
    try {
      final clean = query.trim();
      if (clean.isEmpty) return const Right([]);

      // Search profiles matching name or phone
      final profiles = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('id, name, phone, created_at')
          .or('name.ilike.%$clean%,phone.ilike.%$clean%')
          .limit(10);

      final List<LoyaltyCustomer> results = [];
      for (final raw in (profiles as List)) {
        final profile = Map<String, dynamic>.from(raw as Map);
        final userId = profile['id']?.toString() ?? '';

        int points = 0;
        try {
          final accountRaw = await _supabase
              .from(SupabaseConfig.loyaltyAccountsTable)
              .select('current_points')
              .eq('user_id', userId)
              .maybeSingle();
          if (accountRaw != null) {
            points = (accountRaw['current_points'] as num?)?.toInt() ?? 0;
          }
        } catch (_) {}

        final membershipTier = points >= 800
            ? LoyaltyTier.vip
            : points >= 400
                ? LoyaltyTier.gold
                : points >= 150
                    ? LoyaltyTier.silver
                    : LoyaltyTier.bronze;

        results.add(
          LoyaltyCustomer(
            id: userId,
            name: profile['name'] as String? ?? 'عميل',
            phoneNumber: profile['phone'] as String? ?? '',
            pointsBalance: points,
            tier: membershipTier,
            totalOrdersCount: 0,
            lastVisitAt: profile['created_at'] != null
                ? DateTime.parse(profile['created_at'] as String)
                : DateTime.now(),
          ),
        );
      }

      return Right(results);
    } catch (e, st) {
      AppLogger.warning('Supabase searchLoyaltyCustomers failed: $e', error: e, stackTrace: st);
      final matches = LoyaltyCustomer.demoCustomers.where(
        (c) => c.phoneNumber.contains(query) || c.name.contains(query),
      ).toList();
      return Right(matches);
    }
  }
}
