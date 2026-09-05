import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/cart/data/repositories/supabase_cart_repository.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Records cloud calls instead of touching PostgREST. Extends the concrete
/// repository (the controller's dependency type) so no mocking package is
/// needed; the offline client handed to `super` is never used because every
/// method is overridden.
class _RecordingCloudRepo extends SupabaseCartRepository {
  _RecordingCloudRepo({List<CartItem> storedItems = const []})
    : storedItems = List.of(storedItems),
      // autoRefreshToken off: GoTrue's periodic refresh timer would otherwise
      // be created inside testWidgets' fake-async zone and trip the
      // "Timer is still pending" invariant.
      super(
        SupabaseClient(
          'http://127.0.0.1:9',
          'offline-anon',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  int saveCalls = 0;
  int loadCalls = 0;
  final List<List<CartItem>> savedCarts = <List<CartItem>>[];

  /// Rows served by [loadCart].
  final List<CartItem> storedItems;

  /// When true, saves fail exactly like an unreachable backend.
  bool failSaves = false;

  @override
  Future<Either<Failure, void>> saveCart(
    String userId,
    List<CartItem> items,
  ) async {
    saveCalls++;
    if (failSaves) {
      return const Left<Failure, void>(ServerFailure('boom'));
    }
    savedCarts.add(items);
    return const Right<Failure, void>(null);
  }

  @override
  Future<Either<Failure, List<CartItem>>> loadCart(String userId) async {
    loadCalls++;
    return Right<Failure, List<CartItem>>(List.of(storedItems));
  }
}

// ── fixtures ─────────────────────────────────────────────────────────────────

MenuItem _menuItem(String id) => MenuItem(
  id: id,
  categoryId: 'cat',
  name: 'عنصر $id',
  description: '',
  price: 10,
);

CartItem _cartItem(String menuItemId, {int quantity = 1}) =>
    CartItem(menuItem: _menuItem(menuItemId), quantity: quantity);

const _kTestUuid = 'a0000000-0000-0000-0000-000000000001';

CartController _controller(
  _RecordingCloudRepo? repo,
  String? Function()? user,
) {
  final controller = CartController(cloudRepository: repo, currentUserId: user);
  return controller;
}

void main() {
  group('CartController.restoreFromCloud', () {
    test(
      'is a no-op when no cloud repository is wired (offline/demo mode)',
      () async {
        final controller = _controller(null, () => _kTestUuid);
        addTearDown(controller.dispose);

        await controller.restoreFromCloud();

        expect(controller.state, isEmpty);
      },
    );

    test('skips loading when the resolved user id is null', () async {
      final repo = _RecordingCloudRepo();
      final controller = _controller(repo, () => null);
      addTearDown(controller.dispose);

      await controller.restoreFromCloud();

      expect(repo.loadCalls, 0);
      expect(controller.state, isEmpty);
    });

    test('keeps the local cart untouched when it is not empty', () async {
      final repo = _RecordingCloudRepo(storedItems: [_cartItem('m-cloud')]);
      final controller = _controller(repo, () => _kTestUuid);
      addTearDown(controller.dispose);
      controller.addItem(_cartItem('m-local', quantity: 2));

      await controller.restoreFromCloud();

      expect(repo.loadCalls, 0, reason: 'never clobber a cart in progress');
      expect(controller.state.single.menuItem.id, 'm-local');
      expect(controller.state.single.quantity, 2);
    });

    test('populates an empty cart from the persisted cloud rows', () async {
      final repo = _RecordingCloudRepo(
        storedItems: [_cartItem('m1', quantity: 3), _cartItem('m2')],
      );
      final controller = _controller(repo, () => _kTestUuid);
      addTearDown(controller.dispose);

      await controller.restoreFromCloud();

      expect(repo.loadCalls, 1);
      expect(controller.state.map((e) => e.menuItem.id), ['m1', 'm2']);
      expect(controller.state.first.quantity, 3);
    });
  });

  // Timers are driven by the binding's fake clock: pump() advances the
  // debounce window without real waiting.
  group('CartController debounced cloud sync', () {
    testWidgets(
      'coalesces rapid mutations into a single saveCart after the debounce window',
      (tester) async {
        final repo = _RecordingCloudRepo();
        final controller = _controller(repo, () => _kTestUuid);
        addTearDown(controller.dispose);

        controller.addItem(_cartItem('m1'));
        await tester.pump(); // flush microtasks
        controller.increment('m1|');
        controller.addItem(_cartItem('m2'));

        expect(
          repo.saveCalls,
          0,
          reason: 'no server write before kCloudSyncDebounce elapses',
        );

        await tester.pump(CartController.kCloudSyncDebounce);

        expect(repo.saveCalls, 1, reason: 'three mutations collapse into one');
        final snapshot = repo.savedCarts.single;
        expect(snapshot, hasLength(2));
        expect(snapshot.firstWhere((e) => e.menuItem.id == 'm1').quantity, 2);
      },
    );

    testWidgets('a failed cloud save never breaks the local cart state', (
      tester,
    ) async {
      final repo = _RecordingCloudRepo()..failSaves = true;
      final controller = _controller(repo, () => _kTestUuid);
      addTearDown(controller.dispose);

      controller.addItem(_cartItem('m1'));
      await tester.pump(CartController.kCloudSyncDebounce);

      expect(repo.saveCalls, 1);
      expect(controller.state.single.menuItem.id, 'm1');
    });

    testWidgets(
      'mutations schedule nothing when the resolved user id is null',
      (tester) async {
        final repo = _RecordingCloudRepo();
        final controller = _controller(repo, () => null);
        addTearDown(controller.dispose);

        controller.addItem(_cartItem('m1'));
        await tester.pump(CartController.kCloudSyncDebounce);

        expect(repo.saveCalls, 0);
      },
    );
  });
}
