import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../data/repositories/supabase_customer_profile_repository.dart';
import '../../domain/entities/customer_dietary_entity.dart';
import '../../domain/services/allergen_safety_service.dart';

final allergenSafetyServiceProvider = Provider<AllergenSafetyService>((ref) {
  return const AllergenSafetyService();
});

/// Controller managing customer's health profile, selected allergens, and dietary goals.
class CustomerDietaryController extends StateNotifier<CustomerDietaryProfile> {
  CustomerDietaryController([this._repository, this._userId])
      : super(const CustomerDietaryProfile()) {
    loadProfile();
  }

  final SupabaseCustomerProfileRepository? _repository;
  final String? _userId;

  Future<void> loadProfile() async {
    if (_repository == null || _userId == null) return;
    final result = await _repository.getDietaryProfile(_userId);
    result.when(
      onLeft: (_) {},
      onRight: (profile) {
        if (mounted) state = profile;
      },
    );
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
    _save();
  }

  /// Sets the active dietary lifestyle goal.
  void setDietaryGoal(DietaryGoal goal) {
    state = state.copyWith(dietaryGoal: goal);
    _save();
  }

  /// Toggles strict popup safety warnings when browsing.
  void toggleStrictAlerts(bool enable) {
    state = state.copyWith(strictAllergenAlerts: enable);
    _save();
  }

  /// Resets profile.
  void resetProfile() {
    state = const CustomerDietaryProfile();
    _save();
  }

  void _save() {
    if (_userId != null && _repository != null) {
      _repository.saveDietaryProfile(_userId, state);
    }
  }
}

final customerDietaryControllerProvider =
    StateNotifierProvider<CustomerDietaryController, CustomerDietaryProfile>((ref) {
  final repo = ref.watch(supabaseCustomerProfileRepositoryProvider);
  final user = ref.watch(supabaseCurrentUserProvider);
  return CustomerDietaryController(repo, user?.id);
});

