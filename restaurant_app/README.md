# 🏪 مطعمي — Restaurant Ordering & Operations App

Multi-role Flutter mobile application for restaurant operations: from dine-in QR ordering to the
kitchen display system, delivery dispatch, and manager analytics.

Built with **Clean Architecture** (presentation / domain / data), **Riverpod**, **freezed**,
**go_router** role-based routing, and an Arabic-first (RTL) Material 3 UI.

## Roles

| Role       | Entry route | Purpose                                   |
|------------|-------------|-------------------------------------------|
| Customer   | `/customer` | Browse menu, dietary filters, order, self-pay |
| Waiter     | `/waiter`   | Table management (zones), take orders, statuses |
| Kitchen    | `/kds`      | Kitchen Display System (order columns)     |
| Manager    | `/manager`  | Sales analytics, order status breakdown, active orders, delivery dispatch board (`/manager/dispatch`) |
| Driver     | `/driver`   | Accept deliveries, live tracking, statuses |

## Architecture

```
┌──────────────────────────────┐
│ 🎨 PRESENTATION              │  pages · widgets · controllers (Riverpod)
├──────────────────────────────┤
│ 📦 DOMAIN                    │  entities (freezed) · use cases · repositories
├──────────────────────────────┤
│ 💾 DATA                      │  DTOs (freezed+json) · Dio datasources · repos
└──────────────────────────────┘
```

- **State:** `flutter_riverpod` (`StateNotifierProvider` for auth, providers for DI)
- **Routing:** `go_router` with role-based `redirect` (`lib/core/routing/app_router.dart`)
- **Models:** `freezed` + `json_serializable` — run `dart run build_runner build` after edits
- **Networking:** `dio` + JWT `AuthInterceptor` with 401 → refresh flow
- **Storage:** `flutter_secure_storage` (tokens) · `hive` (offline cache)
- **i18n:** Arabic default via `flutter_localizations`, Material 3 theme

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate freezed/json code
flutter analyze                                             # static checks
flutter test                                                # unit + widget tests
```

> 🚀 **Deploying against live Supabase?** Read [`DEPLOYMENT.md`](DEPLOYMENT.md)
> first — it walks through the required `supabase_migration_v3.sql` and
> `supabase_migration_v4.sql` (customer ↔ driver chat) migrations, backend
> toggles, and a dispatch-pipeline architecture map.

> No emulator/device is required: everything is verified with
> `flutter analyze`, `dart format`, and the offline test suite.

## Demo login

The app runs fully offline with demo accounts (one-tap role chips on the login screen):

| Account               | Password | Role    |
|-----------------------|----------|---------|
| `customer@demo.com`   | `123456` | Customer |
| `waiter@demo.com`     | `123456` | Waiter  |
| `kitchen@demo.com`    | `123456` | Kitchen |
| `manager@demo.com`    | `123456` | Manager |
| `driver@demo.com`     | `123456` | Driver  |

Sessions persist across restarts; use the logout action in any role home to switch users.
Signed-in customers additionally get their cart restored from the cloud (`cart_items` /
`cart_item_modifiers`) when a session starts — offline, the cart simply keeps working locally.

## Environment

Switch backends in `lib/config/environment.dart` (`Environment.dev` / `staging` / `production`).

## Folder layout (highlights)

```
lib/
├── main.dart / app.dart          # entry + router wiring
├── config/                       # env, constants (Arabic), app config
├── core/
│   ├── di/                       # Riverpod providers
│   ├── network/                  # Dio client, auth interceptor, endpoints
│   ├── storage/                  # secure storage, hive cache
│   ├── theme/                    # Material 3 Arabic RTL theme
│   ├── utils/                    # validators, formatters, logger
│   └── errors/                   # failures, exceptions, Either
├── features/                     # 19 modules
│   ├── auth/                       # login, OTP, session
│   ├── cart/                       # cart state — cloud-persisted via Supabase (debounced sync), local fallback offline
│   ├── chat/                     # customer ↔ driver realtime order chat
│   ├── coupons/                  # coupon codes & discounts
│   ├── customer/                 # dine-in flow, live tracking, cancellation
│   ├── delivery/                 # driver flow & assignments
│   ├── inventory/                # stock levels & shortage tracking
│   ├── kds/                      # kitchen display (multi-chef claim/revert)
│   ├── loyalty/                  # points & rewards
│   ├── manager_dashboard/        # analytics + dispatch board
│   ├── menu/                     # categories, items, modifiers
│   ├── notifications/            # KDS/waiter/driver alert services
│   ├── onboarding/               # first-run intro screens
│   ├── orders/                   # order entity & lifecycle
│   ├── ratings/                  # service ratings
│   ├── reservations/             # table reservations
│   ├── restaurant/               # restaurant profile & info
│   ├── settings/                   # app settings
│   └── table_management/          # waiter tables
└── shared/                         # widgets, animations, extensions

supabase/
└── migrations/                     # versioned SQL migrations — source of truth (DEPLOYMENT.md §3b)

integration_tests/                  # end-to-end flows + DB smoke SQL
```

## Feature matrix

| Capability | Where |
|------------|-------|
| Cloud-persisted cart (debounced Supabase sync, restore on sign-in, offline fallback) | `features/cart` |
| Delivery auto-dispatch (weighted driver scoring, 30 s retry) + manual dispatch board | `/manager/dispatch` |
| KDS multi-chef claim/revert with max-2 concurrent claims per chef | `features/kds` |
| Order audit trail viewer (`order_status_log`) | `features/orders` |
| Waiter ready-for-pickup + driver new-assignment alerts (audio + in-app) | `lib/core/notifications/{kds,waiter,driver}_alert_service.dart` |
| Live delivery tracking with real driver GPS data | `features/customer` |
| Pending-only order cancellation | `features/customer` |
| Realtime customer ↔ driver chat — Hive-persisted read receipts, 50-message cap | `features/chat` |
| Offline order queue with idempotency keys (Hive) | `core/data` |
| Loyalty points & rewards | `features/loyalty` |
| Table reservations | `features/reservations` |
| Coupons & discounts | `features/coupons` |

## Roadmap status

- [x] Project scaffold + Clean Architecture folder structure
- [x] Core config / theme / errors / utils
- [x] Domain entities + enums (freezed) with JSON round-trip tests
- [x] Auth data layer (Dio + JWT + secure storage + repository + use cases)
- [x] Auth presentation + role-based go_router navigation + Arabic RTL
- [x] Core unit tests + docs + git
- [x] Offline menu repository with Arabic seed data + customer menu browsing
- [x] Cart domain (totals + 15% tax), CartController (merge-on-add), cart UI
- [x] Modifier detail sheet + customer order creation from cart + confirmation
- [x] Waiter table management (grid + statuses) and order intake → kitchen
- [x] Kitchen Display System (pending/preparing/ready columns + status advance)
- [x] New-order notification service with KDS badge
- [x] Delivery driver flow (accept / start / complete assignments)
- [x] Manager dashboard (sales metrics, active orders, top items, status breakdown)
- [x] Demo auth with persisted sessions + one-tap role login + logout
- [x] Menu item details: dietary/availability badges, ratings, search + filters
- [x] Table zone locations, KDS order summaries, driver delivery details
- [x] Live backend integration (Supabase datasources, realtime, persistence)
- [x] Auto delivery dispatch pipeline (weighted driver scoring, 30 s retry) + manager dispatch board (`/manager/dispatch`)
- [x] KDS multi-chef claim with guarded revert + `order_status_log` audit trail
- [x] Alerts: waiter ready-for-pickup, driver new-assignment (realtime)
- [x] Customer live delivery tracking (real driver data, pending-only cancel)
- [x] Customer ↔ driver order chat (`/chat/:orderId`, realtime, schema v4)
- [ ] FCM remote push polish (local audio/in-app alerts already shipped via the alert services)
- [ ] QR ordering + self-pay

## Verification

```bash
flutter analyze     # 0 issues
dart format --set-exit-if-changed .   # consistently formatted
flutter test        # the full unit + widget suite passes
```

All feature controllers (cart, orders, tables, delivery, dispatch, metrics,
notifications, KDS claim/revert) have pure-Dart unit tests; pages have widget
smoke tests. Tests run fully offline via the in-memory repository overrides in
`test/helpers/test_container.dart`.

Page-coverage guarantee: **all 37 pages** have convention-matching widget tests.
