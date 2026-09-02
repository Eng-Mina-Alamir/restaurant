import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/curbside_pickup_entity.dart';
import '../../domain/entities/customer_dietary_entity.dart';
import '../../domain/entities/customer_wallet_entity.dart';

/// Supabase-backed repository for customer profile: dietary preferences, in-app wallet,
/// gift card redemption, and curbside pickup tracking.
class SupabaseCustomerProfileRepository {
  SupabaseCustomerProfileRepository({
    required SupabaseClient supabase,
    LocalCacheService? cache,
  })  : _supabase = supabase,
        _cache = cache;

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;

  static const String _dietaryCacheKey = 'cust_dietary_';
  static const String _walletCacheKey = 'cust_wallet_';

  // ── Customer Dietary Profile ────────────────────────────────────────────────

  Future<Either<Failure, CustomerDietaryProfile>> getDietaryProfile(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.customerDietaryProfilesTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return const Right(CustomerDietaryProfile());
      }

      final map = Map<String, dynamic>.from(response);
      final rawAllergens = (map['allergens'] as List? ?? []).map((e) => e.toString()).toList();
      final allergens = rawAllergens.map((name) {
        return AllergenType.values.firstWhere(
          (a) => a.name == name,
          orElse: () => AllergenType.gluten,
        );
      }).toList();

      final goal = DietaryGoal.values.firstWhere(
        (g) => g.name == map['dietary_goal'],
        orElse: () => DietaryGoal.all,
      );

      final profile = CustomerDietaryProfile(
        allergens: allergens,
        dietaryGoal: goal,
        strictAllergenAlerts: map['strict_allergen_alerts'] as bool? ?? true,
      );

      final cache = _cache;
      if (cache != null) {
        await cache.writeMap('$_dietaryCacheKey$userId', {
          'allergens': allergens.map((a) => a.name).toList(),
          'dietaryGoal': goal.name,
          'strictAllergenAlerts': profile.strictAllergenAlerts,
        });
      }

      return Right(profile);
    } catch (e, st) {
      AppLogger.warning('Supabase getDietaryProfile fallback: $e', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readMap('$_dietaryCacheKey$userId');
        if (cached != null) {
          final rawAllergens = (cached['allergens'] as List? ?? []).map((e) => e.toString()).toList();
          final allergens = rawAllergens.map((name) {
            return AllergenType.values.firstWhere(
              (a) => a.name == name,
              orElse: () => AllergenType.gluten,
            );
          }).toList();

          final goal = DietaryGoal.values.firstWhere(
            (g) => g.name == cached['dietaryGoal'],
            orElse: () => DietaryGoal.all,
          );

          return Right(
            CustomerDietaryProfile(
              allergens: allergens,
              dietaryGoal: goal,
              strictAllergenAlerts: cached['strictAllergenAlerts'] as bool? ?? true,
            ),
          );
        }
      }
      return const Right(CustomerDietaryProfile());
    }
  }

  Future<Either<Failure, CustomerDietaryProfile>> saveDietaryProfile(
    String userId,
    CustomerDietaryProfile profile,
  ) async {
    try {
      final payload = {
        'user_id': userId,
        'allergens': profile.allergens.map((a) => a.name).toList(),
        'dietary_goal': profile.dietaryGoal.name,
        'strict_allergen_alerts': profile.strictAllergenAlerts,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from(SupabaseConfig.customerDietaryProfilesTable)
          .upsert(payload, onConflict: 'user_id');

      final cache = _cache;
      if (cache != null) {
        await cache.writeMap('$_dietaryCacheKey$userId', {
          'allergens': profile.allergens.map((a) => a.name).toList(),
          'dietaryGoal': profile.dietaryGoal.name,
          'strictAllergenAlerts': profile.strictAllergenAlerts,
        });
      }

      return Right(profile);
    } catch (e, st) {
      AppLogger.error('Supabase saveDietaryProfile failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل حفظ الملف الغذائي: $e'));
    }
  }

  // ── Customer In-App Wallet ──────────────────────────────────────────────────

  Future<Either<Failure, CustomerWalletState>> getWallet(String userId) async {
    try {
      final walletRow = await _supabase
          .from(SupabaseConfig.customerWalletsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final balance = walletRow != null
          ? (walletRow['balance'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      final txRows = await _supabase
          .from(SupabaseConfig.customerWalletTransactionsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);

      final transactions = (txRows as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return WalletTransaction(
          id: map['id']?.toString() ?? '',
          title: map['title'] as String? ?? 'معاملة',
          amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
          date: map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
          isCredit: map['is_credit'] as bool? ?? true,
        );
      }).toList();

      final state = CustomerWalletState(
        balance: balance,
        transactions: transactions,
      );

      final cache = _cache;
      if (cache != null) {
        await cache.writeMap('$_walletCacheKey$userId', {
          'balance': state.balance,
          'transactions': transactions.map((t) => {
            'id': t.id,
            'title': t.title,
            'amount': t.amount,
            'date': t.date.toIso8601String(),
            'isCredit': t.isCredit,
          }).toList(),
        });
      }

      return Right(state);
    } catch (e, st) {
      AppLogger.warning('Supabase getWallet fallback: $e', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readMap('$_walletCacheKey$userId');
        if (cached != null) {
          final txsRaw = cached['transactions'] as List? ?? [];
          final txs = txsRaw.whereType<Map>().map((m) {
            final map = Map<String, dynamic>.from(m);
            return WalletTransaction(
              id: map['id']?.toString() ?? '',
              title: map['title'] as String? ?? 'معاملة',
              amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
              date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
              isCredit: map['isCredit'] as bool? ?? true,
            );
          }).toList();
          return Right(CustomerWalletState(
            balance: (cached['balance'] as num?)?.toDouble() ?? 0.0,
            transactions: txs,
          ));
        }
      }
      return const Right(CustomerWalletState());
    }
  }

  Future<Either<Failure, double>> addFunds(
    String userId,
    double amount, {
    required String title,
  }) async {
    try {
      final walletRow = await _supabase
          .from(SupabaseConfig.customerWalletsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final currentBalance = walletRow != null
          ? (walletRow['balance'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      final newBalance = currentBalance + amount;

      await _supabase.from(SupabaseConfig.customerWalletsTable).upsert({
        'user_id': userId,
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      await _supabase.from(SupabaseConfig.customerWalletTransactionsTable).insert({
        'id': 'TX-${DateTime.now().millisecondsSinceEpoch}',
        'user_id': userId,
        'title': title,
        'amount': amount,
        'is_credit': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      return Right(newBalance);
    } catch (e, st) {
      AppLogger.error('Supabase addFunds failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل شحن المحفظة: $e'));
    }
  }

  // ── Gift Cards ──────────────────────────────────────────────────────────────

  Future<Either<Failure, double>> redeemGiftCard(String userId, String code) async {
    try {
      final cardRaw = await _supabase
          .from(SupabaseConfig.giftCardsTable)
          .select()
          .eq('code', code.trim().toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (cardRaw == null) {
        return const Left(NotFoundFailure('كود كارت الهدية غير صحيح أو مستخدم مسبقاً'));
      }

      final balance = (cardRaw['current_balance'] as num?)?.toDouble() ?? 0.0;
      if (balance <= 0) {
        return const Left(ValidationFailure('رصيد كارت الهدية 0 ج.م'));
      }

      await _supabase
          .from(SupabaseConfig.giftCardsTable)
          .update({'is_active': false, 'current_balance': 0})
          .eq('id', cardRaw['id']);

      await addFunds(userId, balance, title: 'شحن كارت هدية ($code)');

      return Right(balance);
    } catch (e, st) {
      AppLogger.error('Supabase redeemGiftCard failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل استرداد كارت الهدية: $e'));
    }
  }

  // ── Curbside Pickups ────────────────────────────────────────────────────────

  Future<Either<Failure, CurbsideVehicleInfo>> registerCurbside({
    required int orderId,
    required String? customerId,
    required String carModel,
    required String carColor,
    required String licensePlate,
    String? parkingSpotNote,
  }) async {
    try {
      final payload = {
        'order_id': orderId,
        'customer_id': customerId,
        'car_model': carModel,
        'car_color': carColor,
        'license_plate': licensePlate,
        'parking_spot_note': parkingSpotNote,
        'status': CurbsideArrivalStatus.onTheWay.name,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(SupabaseConfig.curbsidePickupsTable).insert(payload);

      return Right(
        CurbsideVehicleInfo(
          carModel: carModel,
          carColor: carColor,
          licensePlate: licensePlate,
          parkingSpotNote: parkingSpotNote,
          status: CurbsideArrivalStatus.onTheWay,
        ),
      );
    } catch (e, st) {
      AppLogger.error('Supabase registerCurbside failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل تسجيل استلام السيارة: $e'));
    }
  }

  Future<Either<Failure, void>> signalCurbsideArrival(int orderId) async {
    try {
      await _supabase
          .from(SupabaseConfig.curbsidePickupsTable)
          .update({
            'status': CurbsideArrivalStatus.arrivedOutside.name,
            'arrived_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId);
      return const Right(null);
    } catch (e, st) {
      AppLogger.error('Supabase signalCurbsideArrival failed: $e', error: e, stackTrace: st);
      return Left(ServerFailure('فشل إرسال إشعار الوصول: $e'));
    }
  }
}
