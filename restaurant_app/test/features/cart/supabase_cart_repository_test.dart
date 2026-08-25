import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/cart/data/repositories/supabase_cart_repository.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal in-process stand-in for the PostgREST surface the cart repository
/// touches (`cart_items` / `cart_item_modifiers`). Binds an ephemeral loopback
/// port — the same real-socket approach as the offline failure-branch suites,
/// but able to serve canned responses so the SUCCESS branches are verifiable
/// without a live database.
class _CapturedRequest {
  _CapturedRequest(this.method, this.path, this.query, this.body);

  final String method;
  final String path;
  final Map<String, String> query;
  final dynamic body;

  bool get isInsert => method == 'POST';
}

class _FakePostgrestServer {
  final List<_CapturedRequest> captured = <_CapturedRequest>[];

  /// Serves canned rows for GET requests on the given path + decoded query.
  List<Map<String, dynamic>> Function(String path, Map<String, String> query)?
  onSelect;

  HttpServer? _server;

  int get port => _server!.port;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen((request) => _handle(request));
  }

  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handle(HttpRequest request) async {
    final bodyText = await utf8.decoder.bind(request).join();
    dynamic body;
    if (bodyText.isNotEmpty) {
      try {
        body = jsonDecode(bodyText);
      } catch (_) {
        body = bodyText;
      }
    }
    captured.add(
      _CapturedRequest(
        request.method,
        request.uri.path,
        request.uri.queryParameters,
        body,
      ),
    );

    final prefer = request.headers.value('prefer') ?? '';
    if (request.method == 'GET') {
      final rows =
          onSelect?.call(request.uri.path, request.uri.queryParameters) ??
          const <Map<String, dynamic>>[];
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(rows));
      await request.response.close();
      return;
    }

    // Writes: honour `return=representation` by echoing the posted payload,
    // otherwise answer with an empty 201/204.
    if (request.method == 'POST' && prefer.contains('representation')) {
      request.response.statusCode = HttpStatus.created;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(body ?? <dynamic>[]));
      await request.response.close();
      return;
    }
    request.response.statusCode = request.method == 'POST'
        ? HttpStatus.created
        : HttpStatus.noContent;
    await request.response.close();
  }
}

// ── fixtures ─────────────────────────────────────────────────────────────────

const String _userId = '77770c66-6fb4-4723-9215-2e319405a6bd';
// userId.replaceAll('-','').substring(0,12)
const String _expectedPrefix = '77770c666fb4';

MenuItem _menuItem(String id, {String name = 'عنصر', double price = 10}) =>
    MenuItem(
      id: id,
      categoryId: 'cat',
      name: name,
      description: 'وصف',
      price: price,
    );

CartItem _cartItem(
  String menuItemId, {
  int quantity = 1,
  List<MenuModifierOption> modifiers = const [],
  String? notes,
}) => CartItem(
  menuItem: _menuItem(menuItemId),
  quantity: quantity,
  selectedModifiers: modifiers,
  specialNotes: notes,
);

MenuModifierOption _modifier(String id, {double extraPrice = 0}) =>
    MenuModifierOption(id: id, name: 'إضافة $id', extraPrice: extraPrice);

void main() {
  group('SupabaseCartRepository success branches (fake PostgREST)', () {
    late _FakePostgrestServer server;
    late SupabaseCartRepository repo;

    setUp(() async {
      server = _FakePostgrestServer();
      await server.start();
      repo = SupabaseCartRepository(
        SupabaseClient(
          'http://127.0.0.1:${server.port}',
          'anon',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
    });

    tearDown(() async {
      await server.close();
    });

    test('saveCart replaces the stored cart with two batch inserts '
        '(deterministic ids, delete before insert)', () async {
      final result = await repo.saveCart(_userId, [
        _cartItem(
          'm1',
          quantity: 2,
          modifiers: [_modifier('mo1', extraPrice: 5)],
          notes: 'بدون بصل',
        ),
        _cartItem('m2'),
      ]);

      expect(result.isRight, isTrue);

      final posts = server.captured.where((r) => r.isInsert).toList();
      expect(posts, hasLength(2), reason: 'exactly one batch insert per table');
      expect(posts[0].path, endsWith('/rest/v1/cart_items'));
      expect(posts[1].path, endsWith('/rest/v1/cart_item_modifiers'));

      // Delete-then-insert ordering: the old-row DELETE precedes both POSTs.
      final deleteIndex = server.captured.indexWhere(
        (r) => r.method == 'DELETE',
      );
      expect(deleteIndex, greaterThanOrEqualTo(0));
      expect(deleteIndex, lessThan(server.captured.indexOf(posts.first)));

      // cart_items rows: deterministic ids, clamped quantities, notes kept.
      final itemRows = posts[0].body as List<dynamic>;
      expect(itemRows, hasLength(2));
      expect(itemRows[0]['id'], '${_expectedPrefix}ci0');
      expect(itemRows[1]['id'], '${_expectedPrefix}ci1');
      expect(itemRows[0]['user_id'], _userId);
      expect(itemRows[0]['menu_item_id'], 'm1');
      expect(itemRows[0]['quantity'], 2);
      expect(itemRows[0]['special_notes'], 'بدون بصل');
      // Rows without special notes simply omit the column.
      expect(itemRows[1].containsKey('special_notes'), isFalse);

      // cart_item_modifiers rows: only the line that actually has modifiers.
      final modifierRows = posts[1].body as List<dynamic>;
      expect(modifierRows, hasLength(1));
      expect(modifierRows.single['id'], '${_expectedPrefix}cim0_0');
      expect(modifierRows.single['cart_item_id'], '${_expectedPrefix}ci0');
      expect(modifierRows.single['modifier_option_id'], 'mo1');
    });

    test(
      'saveCart pads short user ids instead of throwing RangeError',
      () async {
        final result = await repo.saveCart('short-user', [_cartItem('m9')]);

        expect(result.isRight, isTrue);
        final itemRow =
            (server.captured.firstWhere((r) => r.isInsert).body
                        as List<dynamic>)
                    .single
                as Map<String, dynamic>;
        // 'short-user' has 9 chars once dashes are stripped → padded to 12.
        expect(itemRow['id'], 'shortuserxxxci0');
      },
    );

    test('loadCart rebuilds menu items and modifiers from the PostgREST '
        'embedding and skips rows whose menu join is null', () async {
      server.onSelect = (path, query) {
        if (!path.endsWith('/rest/v1/cart_items')) return const [];
        if (query['select'] != null && !query['select']!.startsWith('*')) {
          return const []; // `select id` probe issued by _deleteUserRows
        }
        return <Map<String, dynamic>>[
          {
            'id': 'row-1',
            'user_id': _userId,
            'menu_item_id': 'm1',
            'quantity': 3,
            'special_notes': 'ساخنة',
            'menu_items': {
              'id': 'm1',
              'category_id': 'cat1',
              'name': 'كشري',
              'description': 'طبق مصري',
              'price': 30.0,
              'is_available': true,
              'rating': 4.5,
            },
            'cart_item_modifiers': [
              {
                'id': 'cim-1',
                'cart_item_id': 'row-1',
                'modifier_option_id': 'mo1',
                'menu_modifier_options': {
                  'id': 'mo1',
                  'name': 'جبنة إضافية',
                  'extra_price': 5.0,
                  'is_available': true,
                },
              },
            ],
          },
          {
            // Orphaned row (menu item deleted since) → must be skipped.
            'id': 'row-2',
            'user_id': _userId,
            'menu_item_id': 'ghost',
            'quantity': 1,
            'menu_items': null,
            'cart_item_modifiers': [],
          },
        ];
      };

      final result = await repo.loadCart(_userId);

      expect(result.isRight, isTrue);
      final items = (result as Right<Failure, List<CartItem>>).value;
      expect(items, hasLength(1), reason: 'null menu_items join is skipped');

      final restored = items.single;
      expect(restored.menuItem.id, 'm1');
      expect(restored.menuItem.name, 'كشري');
      expect(restored.menuItem.price, 30.0);
      expect(restored.quantity, 3);
      expect(restored.specialNotes, 'ساخنة');
      expect(restored.selectedModifiers.single.id, 'mo1');
      expect(restored.selectedModifiers.single.extraPrice, 5.0);
    });

    test('loadCart returns an empty list when nothing is stored', () async {
      server.onSelect = (path, query) => const [];

      final result = await repo.loadCart(_userId);

      expect(result.isRight, isTrue);
      expect((result as Right<Failure, List<CartItem>>).value, isEmpty);
    });

    test('clearCart removes modifier rows then the cart rows', () async {
      server.onSelect = (path, query) {
        // `select id` probe used to find owned rows.
        if (query['select'] == 'id') {
          return [
            {'id': 'x'},
            {'id': 'y'},
          ];
        }
        return const [];
      };

      final result = await repo.clearCart(_userId);

      expect(result.isRight, isTrue);
      final deletes = server.captured
          .where((r) => r.method == 'DELETE')
          .toList();
      expect(deletes, hasLength(2));
      expect(deletes[0].path, endsWith('/rest/v1/cart_item_modifiers'));
      expect(deletes[0].query['cart_item_id'], contains('x'));
      expect(deletes[0].query['cart_item_id'], contains('y'));
      expect(deletes[1].path, endsWith('/rest/v1/cart_items'));
      expect(deletes[1].query['user_id'], 'eq.$_userId');
    });
  });

  // Loopback refusals can take multiple seconds on firewalled hosts; give
  // every failure-branch test ample headroom (same pattern as the orders suite).
  const testTimeout = Timeout.factor(6);

  group('SupabaseCartRepository offline failure branches', () {
    // Port 9 (discard protocol): connection refused deterministically.
    late SupabaseCartRepository repo;

    setUp(() {
      repo = SupabaseCartRepository(
        SupabaseClient(
          'http://127.0.0.1:9',
          'offline-anon',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
    });

    test(
      'saveCart returns Left(ServerFailure) without crashing',
      timeout: testTimeout,
      () async {
        final result = await repo.saveCart(_userId, [_cartItem('m1')]);

        expect(result.isLeft, isTrue);
        expect((result as Left<Failure, void>).value, isA<ServerFailure>());
      },
    );

    test(
      'loadCart returns Left(ServerFailure) without crashing',
      timeout: testTimeout,
      () async {
        final result = await repo.loadCart(_userId);

        expect(result.isLeft, isTrue);
        expect(
          (result as Left<Failure, List<CartItem>>).value,
          isA<ServerFailure>(),
        );
      },
    );

    test(
      'clearCart returns Left(ServerFailure) without crashing',
      timeout: testTimeout,
      () async {
        final result = await repo.clearCart(_userId);

        expect(result.isLeft, isTrue);
        expect((result as Left<Failure, void>).value, isA<ServerFailure>());
      },
    );
  });
}
