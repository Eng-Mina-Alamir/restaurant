import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer_dietary_entity.dart';
import '../../domain/services/allergen_safety_service.dart';

final allergenSafetyServiceProvider = Provider<AllergenSafetyService>((ref) {
  return const AllergenSafetyService();
});

/// Controller managing customer's health profile, selected allergens, and dietary goals.
class CustomerDietaryController extends StateNotifier<CustomerDietaryProfile> {
  CustomerDietaryController()
      : super(const CustomerDietaryProfile());

  /// Toggles an allergen on or off.
  void toggleAllergen(AllergenType allergen) {
    final current = List<AllergenType>.from(state.allergens);
    if (current.contains(allergen)) {
      current.remove(allergen);
    } else {
      current.add(allergen);
    }
    state = state.copyWith(allergens: current);
  }

  /// Sets the active dietary lifestyle goal.
  void setDietaryGoal(DietaryGoal goal) {
    state = state.copyWith(dietaryGoal: goal);
  }

  /// Toggles strict popup safety warnings when browsing.
  void toggleStrictAlerts(bool enable) {
    state = state.copyWith(strictAllergenAlerts: enable);
  }

  /// Resets profile.
  void resetProfile() {
    state = const CustomerDietaryProfile();
  }
}

final customerDietaryControllerProvider =
    StateNotifierProvider<CustomerDietaryController, CustomerDietaryProfile>((ref) {
  return CustomerDietaryController();
});
