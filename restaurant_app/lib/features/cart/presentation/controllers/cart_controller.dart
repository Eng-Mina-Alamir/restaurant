import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/utils/financial_calculator.dart';
import '../../../../core/utils/haptics.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/supabase_cart_repository.dart';
import '../../domain/cart_totals.dart';
import '../../domain/entities/cart_item.dart';

/// Manages the list of [CartItem]s in the customer's cart.
///
/// Items are merged by [CartItem.configKey]: adding the same product
/// configuration again increments its quantity rather than appending a
/// duplicate entry.
///
/// When a [SupabaseCartRepository] is supplied the controller also mirrors
/// every mutation to `cart_items` / `cart_item_modifiers` (debounced,
/// fire-and-forget) and can [restoreFromCloud] on session start. Both cloud
/// dependencies are optional so offline/demo mode and existing tests keep
/// working unchanged.
class CartController extends StateNotifier<List<CartItem>> {
  CartController({
    SupabaseCartRepository? cloudRepository,
    String? Function()? currentUserId,
  }) : _cloud = cloudRepository,
       _currentUserId = currentUserId,
       super(const []);

  final SupabaseCartRepository? _cloud;
  final String? Function()? _currentUserId;
  Timer? _syncDebounce;

  /// Debounce window coalescing rapid mutations into one server write.
  static const Duration kCloudSyncDebounce = Duration(milliseconds: 600);

  /// Upper bound for a single cart line. Protects money math and the UI from
  /// runaway quantities (fat-finger taps or hostile `copyWith` input).
  static const int kMaxQuantityPerLine = 99;

  /// The table ID set by QR scanning. Null means takeaway / no table.
  String? _tableId;

  /// The table ID currently linked to this cart session (set via QR scan).
  String? get activeTableId => _tableId;

  /// Links this cart session to a dine-in [tableId] (from QR scan).
  void setTableId(String tableId) => _tableId = tableId;

  /// Clears the linked table (e.g. on logout or new session).
  void clearTableId() => _tableId = null;

  /// Number of distinct line items.
  int get itemCount => state.length;

  /// Total count of physical units across all lines.
  int get unitCount => state.fold(0, (sum, item) => sum + item.quantity);

  /// Derived money figures for the current cart contents.
  CartTotals get totals => CartTotals.fromItems(state);

  /// Adds [item], merging with an existing same-configuration entry.
  ///
  /// Unavailable items (currently out of stock) are rejected so customers
  /// cannot add products the kitchen can no longer prepare.
  void addItem(CartItem item) {
    if (item.quantity <= 0 || item.menuItem.id.isEmpty) return;
    if (!item.menuItem.isAvailable) return;
    final index = state.indexWhere((e) => e.configKey == item.configKey);
    if (index == -1) {
      final capped = item.copyWith(
        quantity: item.quantity.clamp(1, kMaxQuantityPerLine),
      );
      state = [...state, capped];
    } else {
      final existing = state[index];
      final merged = existing.copyWith(
        quantity: (existing.quantity + item.quantity).clamp(
          1,
          kMaxQuantityPerLine,
        ),
      );
      state = [...state]..[index] = merged;
    }
    // Success confirmation only — never fires on rejected items.
    AppHaptics.selectionTap();
    _scheduleCloudSync();
  }

  /// Increases the quantity of the matching line item, capped at
  /// [kMaxQuantityPerLine].
  void increment(String configKey) {
    _mutate(configKey, (item) {
      if (item.quantity >= kMaxQuantityPerLine) return item;
      return item.copyWith(quantity: item.quantity + 1);
    });
    _scheduleCloudSync();
  }

  /// Decreases the quantity of the matching line, removing it at zero.
  void decrement(String configKey) {
    final index = state.indexWhere((e) => e.configKey == configKey);
    if (index == -1) return;
    final existing = state[index];
    if (existing.quantity <= 1) {
      removeItem(configKey);
      return;
    }
    final updated = existing.copyWith(quantity: existing.quantity - 1);
    state = [...state]..[index] = updated;
    _scheduleCloudSync();
  }

  /// Removes the line matching [configKey].
  void removeItem(String configKey) {
    state = state.where((e) => e.configKey != configKey).toList();
    _scheduleCloudSync();
  }

  /// Empties the cart and clears the linked table.
  void clear() {
    state = const [];
    _tableId = null;
    _scheduleCloudSync();
  }

  /// Replaces local state with the persisted cloud cart (if any).
  ///
  /// Called once when a logged-in customer session starts; a no-op for
  /// anonymous users, offline mode, or when the cloud already matches.
  /// Non-UUID identities (demo/guest) never touch the server: their rows
  /// could never satisfy the `cart_items.user_id -> profiles(id)` FK.
  Future<void> restoreFromCloud() async {
    final repo = _cloud;
    final userId = _currentUserId?.call();
    if (repo == null || userId == null || userId.isEmpty) return;
    if (!_isUuid(userId)) return;
    if (state.isNotEmpty) return;
    final result = await repo.loadCart(userId);
    result.when(
      onLeft: (_) {},
      onRight: (items) {
        if (items.isNotEmpty && state.isEmpty && mounted) {
          state = items;
        }
      },
    );
  }

  /// Coalesces mutations into a single debounced server write.
  ///
  /// Skips demo/guest identities (non-UUID): persisting them server-side
  /// would only produce FK/RLS rejections, and the debounce timer may
  /// otherwise fire after a logout under the previous account's id.
  void _scheduleCloudSync() {
    final repo = _cloud;
    final userId = _currentUserId?.call();
    if (repo == null || userId == null || userId.isEmpty) return;
    if (!_isUuid(userId)) return;
    _syncDebounce?.cancel();
    _syncDebounce = Timer(kCloudSyncDebounce, () {
      final snapshot = List<CartItem>.of(state);
      // Fire-and-forget: persistence failures must never break the UX.
      repo.saveCart(userId, snapshot);
    });
  }

  /// Returns the per-person amount when splitting the total evenly across
  /// [numPersons].
  double splitTotal(int numPersons) {
    return FinancialCalculator.splitTotal(totals.totalAmount, numPersons);
  }

  /// Returns an exact list of per-person amounts across [numPersons] where
  /// the sum is guaranteed to equal [totals.totalAmount] with remainder cents allocated.
  List<double> splitTotalDetailed(int numPersons) {
    return FinancialCalculator.splitBillDetailed(
      totals.totalAmount,
      numPersons,
    );
  }

  void _mutate(String configKey, CartItem Function(CartItem) transform) {
    final index = state.indexWhere((e) => e.configKey == configKey);
    if (index == -1) return;
    final updated = transform(state[index]);
    state = [...state]..[index] = updated;
    _scheduleCloudSync();
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    super.dispose();
  }

  /// Strict UUID check shared by the cloud guards above.
  static bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}

/// Provider for [CartController].
///
/// When Supabase mode is active *and* the SDK was actually initialized
/// (production app), the controller is wired to the cloud cart repository and
/// restores the persisted cart for the signed-in customer. In tests / offline
/// runs the SDK is uninitialized, the wiring degrades to the plain
/// in-memory controller, and nothing touches the network.
final cartControllerProvider =
    StateNotifierProvider<CartController, List<CartItem>>((ref) {
      final controller = CartController(
        cloudRepository: _resolveCloudRepository(),
        // Single source of truth: the authenticated domain user first,
        // Supabase session as fallback. (These can diverge after a token
        // expiry or a server-side sign-out; the domain session wins so the
        // cart is never persisted under a stale identity.)
        currentUserId: () =>
            ref.read(authControllerProvider).user?.id ??
            ref.read(supabaseCurrentUserProvider)?.id,
      );
      unawaited(controller.restoreFromCloud());
      return controller;
    });

SupabaseCartRepository? _resolveCloudRepository() {
  if (!AppConfig.useSupabase) return null;
  try {
    // Throws when Supabase.initialize was never called (tests/offline).
    final client = Supabase.instance.client;
    return SupabaseCartRepository(client);
  } catch (_) {
    return null;
  }
}

/// The payment method the customer has selected at checkout.
final selectedPaymentMethodProvider = StateProvider<PaymentMethod>(
  (ref) => PaymentMethod.cash,
);

/// The order type (dineIn, takeaway, delivery) selected by the customer.
final selectedOrderTypeProvider = StateProvider<OrderType>(
  (ref) => OrderType.dineIn,
);

/// Exposes the active table id from the cart controller (read-only).
final activeTableIdProvider = Provider<String?>(
  (ref) => ref.watch(cartControllerProvider.notifier).activeTableId,
);

/// The selected delivery address string resolved from the interactive map picker.
final selectedDeliveryAddressProvider = StateProvider<String?>(
  (ref) => 'حي الزمالك، شارع 26 يوليو، القاهرة',
);
