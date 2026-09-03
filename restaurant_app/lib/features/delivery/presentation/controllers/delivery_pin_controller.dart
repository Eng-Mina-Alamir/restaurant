import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/data/app_cache.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../data/repositories/in_memory_delivery_pin_repository.dart';
import '../../data/repositories/supabase_delivery_pin_repository.dart';
import '../../domain/repositories/delivery_pin_repository.dart';

/// Shared [DeliveryPinRepository].
///
/// Supabase backend when enabled, otherwise in-memory (Hive has no PIN table
/// yet — codes live for the session, which is enough for demo/offline).
final deliveryPinRepositoryProvider = Provider<DeliveryPinRepository>((ref) {
  if (AppConfig.useSupabase) {
    return SupabaseDeliveryPinRepository(
      supabase: ref.watch(supabaseClientProvider),
    );
  }
  final cache = ref.watch(localCacheServiceProvider);
  if (cache != null) {
    // Hive-backed deliveries still use the in-memory PIN store: PINs are
    // short-lived session secrets, no need for disk persistence.
    return InMemoryDeliveryPinRepository();
  }
  return InMemoryDeliveryPinRepository();
});

/// Per-order verification code for the customer tracking UI.
///
/// Calls [DeliveryPinRepository.ensurePin] so the first view mints the code
/// and later views (customer reopen, driver dialog) read the SAME code.
/// Auto-dispose: re-fetched whenever the tracking page is opened.
final deliveryPinProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, orderId) async {
      final repo = ref.watch(deliveryPinRepositoryProvider);
      final result = await repo.ensurePin(orderId);
      return result.when(onLeft: (_) => null, onRight: (pin) => pin);
    });
