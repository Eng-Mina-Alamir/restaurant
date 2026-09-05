import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase_config.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/restaurant/domain/entities/restaurant_entity.dart';
import '../../features/restaurant/presentation/controllers/restaurant_controller.dart';
import '../../features/subscription/domain/entities/subscription_plan.dart';

/// StateNotifier holding any manual/customer restaurant override (e.g. from QR scan).
class ManualRestaurantIdNotifier extends StateNotifier<String?> {
  ManualRestaurantIdNotifier() : super(null);

  void setRestaurantId(String? id) => state = id;
}

final manualRestaurantIdProvider =
    StateNotifierProvider<ManualRestaurantIdNotifier, String?>((ref) {
  return ManualRestaurantIdNotifier();
});

/// Dynamically resolves the active tenant's restaurant UUID.
///
/// Priority:
/// 1. Authenticated user's restaurantId (from JWT / profiles table)
/// 2. Manually selected / scanned restaurant ID (for customer QR flow)
/// 3. Fallback to [SupabaseConfig.defaultRestaurantId]
final currentRestaurantIdProvider = Provider<String>((ref) {
  final authUser = ref.watch(authControllerProvider).user;
  final restId = authUser?.restaurantId;
  if (restId != null && restId.trim().isNotEmpty) {
    return restId;
  }

  final manualId = ref.watch(manualRestaurantIdProvider);
  if (manualId != null && manualId.trim().isNotEmpty) {
    return manualId;
  }

  return SupabaseConfig.defaultRestaurantId;
});

/// Watcher for the active restaurant's profile entity.
final activeRestaurantProfileProvider = Provider<RestaurantEntity?>((ref) {
  final asyncVal = ref.watch(restaurantSettingsControllerProvider);
  return asyncVal.valueOrNull?.restaurant;
});

/// Evaluates active subscription tier of the current restaurant tenant.
final currentSubscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  final restaurant = ref.watch(activeRestaurantProfileProvider);
  // Default to Pro trial if not loaded yet
  if (restaurant == null) return SubscriptionTier.pro;
  return SubscriptionTier.pro;
});

/// Provider checking whether a specific SaaS feature is unlocked for the tenant.
final isSaaSFeatureEnabledProvider =
    Provider.family<bool, SaaSFeature>((ref, feature) {
  final tier = ref.watch(currentSubscriptionTierProvider);
  return SubscriptionEntitlements.isFeatureAllowed(tier, feature);
});
