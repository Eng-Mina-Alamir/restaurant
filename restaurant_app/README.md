# 🏪 مطعمي — Restaurant Ordering & Operations App

Multi-role Flutter mobile application for restaurant operations: from dine-in QR ordering to the
kitchen display system, delivery dispatch, and manager analytics.

Built with **Clean Architecture** (presentation / domain / data), **Riverpod**, **freezed**,
**go_router** role-based routing, and an Arabic-first (RTL) Material 3 UI.

## Roles

| Role       | Entry route | Purpose                                   |
|------------|-------------|-------------------------------------------|
| Customer   | `/customer` | QR scan, browse menu, order, self-pay     |
| Waiter     | `/waiter`   | Table management, take orders, statuses    |
| Kitchen    | `/kds`      | Kitchen Display System (order columns)     |
| Manager    | `/manager`  | Sales analytics, discounts, staff          |
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
- [ ] Customer menu browsing, cart, ordering
- [ ] Waiter table management + order taking
- [ ] KDS order columns, timers, alerts
- [ ] Delivery driver flow + live tracking
- [ ] Manager dashboard analytics
