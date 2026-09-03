import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/app_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/customer_dietary_entity.dart';
import '../../domain/services/allergen_safety_service.dart';

final allergenSafetyServiceProvider = Provider<AllergenSafetyService>((ref) {
  return const AllergenSafetyService();
});

/// Controller managing customer's health profile, selected allergens, and dietary goals.
class CustomerDietaryController extends StateNotifier<CustomerDietaryProfile> {
  CustomerDietaryController({
    SupabaseClient? supabase,
    String? userId,
  })  : _supabase = supabase,
        _userId = userId,
        super(const CustomerDietaryProfile()) {
    if (_supabase != null && _userId != null) {
      _loadFromSupabase();
    }
  }

  final SupabaseClient? _supabase;
  final String? _userId;

  Future<void> _loadFromSupabase() async {
    final client = _supabase;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      final row = await client
          .from('customer_dietary_profiles')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (row != null) {
        final List<AllergenType> allergens = [];
        final rawAllergens = row['allergens'] as List? ?? [];
        for (final item in rawAllergens) {
          final str = item.toString();
          final match = AllergenType.values.where((a) => a.name == str);
          if (match.isNotEmpty) allergens.add(match.first);
        }

        final goalStr = row['dietary_goal']?.toString() ?? 'all';
        final goal = DietaryGoal.values.firstWhere(
          (g) => g.name == goalStr,
          orElse: () => DietaryGoal.all,
        );

        state = CustomerDietaryProfile(
          allergens: allergens,
          dietaryGoal: goal,
          strictAllergenAlerts: row['strict_allergen_alerts'] as bool? ?? false,
        );
      }
    } catch (e) {
      AppLogger.warning('CustomerDietaryController loadFromSupabase error: $e');
    }
  }

  void _syncToSupabase() {
    final client = _supabase;
    final uid = _userId;
    if (client == null || uid == null) return;
    Future.microtask(() async {
      try {
        await client.from('customer_dietary_profiles').upsert({
          'user_id': uid,
          'allergens': state.allergens.map((a) => a.name).toList(),
          'dietary_goal': state.dietaryGoal.name,
          'strict_allergen_alerts': state.strictAllergenAlerts,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        AppLogger.warning('CustomerDietaryController syncToSupabase error: $e');
      }
    });
  }

  /// Toggles an allergen on or off.
  void toggleAllergen(AllergenType allergen) {
    final current = List<AllergenType>.from(state.allergens);
    if (current.contains(allergen)) {
      current.remove(allergen);
    } else {
      current.add(allergen);
    }
    state = state.copyWith(allergens: current);
    _syncToSupabase();
  }

  /// Sets the active dietary lifestyle goal.
  void setDietaryGoal(DietaryGoal goal) {
    state = state.copyWith(dietaryGoal: goal);
    _syncToSupabase();
  }

  /// Toggles strict popup safety warnings when browsing.
  void toggleStrictAlerts(bool enable) {
    state = state.copyWith(strictAllergenAlerts: enable);
    _syncToSupabase();
  }

  /// Resets profile.
  void resetProfile() {
    state = const CustomerDietaryProfile();
    _syncToSupabase();
  }
}

final customerDietaryControllerProvider =
    StateNotifierProvider<CustomerDietaryController, CustomerDietaryProfile>((ref) {
  final supabase = AppConfig.useSupabase ? ref.watch(supabaseClientProvider) : null;
  final authState = ref.watch(authControllerProvider);
  final userId = authState.user?.id;
  return CustomerDietaryController(
    supabase: supabase,
    userId: userId,
  );
});
