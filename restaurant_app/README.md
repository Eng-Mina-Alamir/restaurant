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
| Manager    | `/manager`  | Sales analytics, order status breakdown, active orders |
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

> No emulator/device is required for the current milestone: everything is verified with
> `flutter analyze`, `dart format`, and pure-Dart tests.

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
├── features/
│   ├── auth/                     # login, OTP, session
│   ├── customer/                 # dine-in flow
│   ├── menu/                     # categories, items, modifiers
│   ├── cart/                     # cart state
│   ├── orders/                   # order entity & lifecycle
│   ├── table_management/         # waiter tables
│   ├── kds/                      # kitchen display
│   ├── delivery/                 # driver flow
│   └── manager_dashboard/        # analytics
└── shared/                       # widgets, animations, extensions
```

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
- [ ] Live backend integration (Dio datasources, real persistence)
- [ ] Push notifications / audio alerts for new orders
- [ ] QR ordering + self-pay
- [ ] Delivery live tracking (maps)

## Verification

The project is verified entirely offline with:

```bash
flutter analyze     # 0 issues
dart format --set-exit-if-changed .   # consistently formatted
flutter test        # 159 unit + widget tests
```

All feature controllers (cart, orders, tables, delivery, metrics, notifications)
have pure-Dart unit tests; pages have widget smoke tests.
