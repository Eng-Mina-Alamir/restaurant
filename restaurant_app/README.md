# Restaurant App

A restaurant management application built with Flutter that covers the full
restaurant workflow: point-of-sale menu management, cart, orders, table
management, kitchen display system (KDS), delivery and a manager dashboard.

## Architecture

The project follows **Clean Architecture** principles, split into three layers:

- **`data/`** - Data sources (remote/local), models (JSON-serializable) and
  repository implementations.
- **`domain/`** - Entities, repository contracts (interfaces) and use cases.
- **`presentation/`** - State controllers and UI pages/widgets.

### Folder structure

```
lib/
├── config/                     # App configuration & constants
├── core/
│   ├── di/                     # Dependency injection (Riverpod providers)
│   ├── network/                # Dio client, interceptors, API wrappers
│   ├── theme/                  # Theme, colors, typography
│   ├── storage/                # Hive / secure storage wrappers
│   ├── utils/                  # Shared helpers
│   └── errors/                 # Domain errors & failure types
├── features/
│   ├── auth/                   # Authentication & authorization
│   ├── menu/                   # Menu & product catalog
│   ├── cart/                   # Shopping cart
│   ├── orders/                 # Order lifecycle
│   ├── table_management/       # Table & reservation management
│   ├── kds/                    # Kitchen display system
│   ├── delivery/               # Delivery & riders
│   └── manager_dashboard/      # Manager reports & dashboards
└── shared/
    ├── widgets/                # Reusable widgets
    ├── animations/             # Shared animations
    └── extensions/             # Extension helpers
```

## Tech stack

- **State management:** flutter_riverpod
- **Routing:** go_router
- **Networking:** dio
- **Code generation:** freezed + json_serializable (build_runner)
- **Local storage:** hive / hive_flutter, flutter_secure_storage
- **Formatting / localization:** intl

## Setup

```bash
flutter pub get
flutter run
```

To regenerate Freezed/JSON model code:

```bash
dart run build_runner build --delete-conflicting-outputs
```
