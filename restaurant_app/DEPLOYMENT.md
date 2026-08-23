# 🚀 Deployment Guide — Live Supabase Backend

Step-by-step guide for deploying the app against the live Supabase backend,
including the **required v3 database migration**, backend toggles, and an
architecture map of the delivery dispatch pipeline.

---

## 1. Apply `supabase_migration_v3.sql` (REQUIRED)

The migration file lives at the repository root: [`supabase_migration_v3.sql`](supabase_migration_v3.sql).

### Steps

1. Open the **Supabase Dashboard** → select your project.
2. In the left sidebar, open **SQL Editor**.
3. Click **New query**.
4. Copy the **entire** contents of `supabase_migration_v3.sql` and paste it into the editor.
5. Click **Run** and wait for "Success. No rows returned".
6. Done — no further action needed.

> ✅ **Idempotent:** every statement uses `IF NOT EXISTS`, so re-running the
> whole file is safe (e.g. to verify or after restoring a branch).

> ⚠️ **Do not skip this step.** Without the new `orders` columns
> (`assigned_kitchen_id` / `driver_id`) every order insert that touches them
> fails with **PGRST204** (*Could not find the 'assigned_kitchen_id' column of
> 'orders' in the schema cache*). The migration must be applied **before**
> deploying app v3.

### What v3 delivers

| Object | Purpose |
|--------|---------|
| `orders.assigned_kitchen_id` | FK → `profiles.id`; which kitchen chef claimed the order |
| `orders.driver_id` | FK → `profiles.id`; which driver is delivering the order |
| `profiles.is_available` | Driver availability toggle (default `TRUE`) |
| `profiles.rating` | Driver rating 1.0–5.0 (default `5.0`) |
| `profiles.vehicle_info` | Free-text vehicle description |
| `delivery_assignments` | One row per driver run: order ↔ driver link, pickup/delivered timestamps, status (`pending` → `accepted` → `pickedUp` → `inTransit` → `delivered`/`failed`), fee, GPS coords, and `assignment_method` (`auto`/`manual`) |
| `delivery_assignments` RLS | Drivers see & progress only their own rows; **staff insert policy** allows waiter/kitchen/cashier/manager/admin to dispatch; managers/admins full control |
| `order_status_log` | Audit trail of status transitions (`from_status` → `to_status`, `changed_by`, `reason`, `is_revert`) backing KDS guarded-revert history; staff can insert, managers audit all, drivers/customers read their own orders' history |

Indexes are created on `delivery_assignments(order_id)`,
`delivery_assignments(driver_id)` and `order_status_log(order_id)`.

> 🏢 **Single-tenant assumption:** manager/admin RLS on `delivery_assignments`
> and `order_status_log` is **role-global** — `is_manager_or_admin()` checks
> only the caller's role, with no restaurant scoping, and
> `delivery_assignments` itself has no `restaurant_id` column. This is fine for
> the current single-restaurant deployment; revisit both before any
> multi-tenant rollout.

The full baseline schema remains in [`supabase_schema.sql`](supabase_schema.sql);
v3 mirrors its "SCHEMA V3" section.

---

## 2. Backend Toggles

All toggles live in `lib/config/`.

| File | Setting | Current value | Effect |
|------|---------|---------------|--------|
| `lib/config/app_config.dart` | `AppConfig.useSupabase` | `true` | Routes data/realtime/storage through live Supabase. Set `false` for offline/demo mode. |
| `lib/config/app_config.dart` | `AppConfig.useDemoAuth` | `false` | When `true`, one-tap demo role logins bypass Supabase Auth. Must be `false` in production to enforce email/password verification. |
| `lib/config/environment.dart` | `EnvironmentConfig.current` | `Environment.production` | Compile-time environment switch (`dev` / `staging` / `production`). Production resolves base URLs from `SupabaseConfig.url`. |

### Keeping tests offline

Tests must never touch the network. The shared helper
[`test/helpers/test_container.dart`](test/helpers/test_container.dart) builds a
Riverpod `ProviderContainer` whose repository providers are overridden with
in-memory fakes:

```dart
final container = createTestContainer(
  seedCheckoutFixtures: true,        // canonical b1/f1 fixture menu
  extraCheckoutItems: const [],      // optional extras extend the fixtures
  additionalOverrides: const [],     // suite-specific overrides
);
await primeMenuForCheckout(container); // warm menu before checkout flows
```

Every repository (menu, orders, delivery, tables, coupons, reservations,
ratings, inventory, loyalty) is swapped for its `InMemory*Repository`, so the
full suite runs offline regardless of the `AppConfig.useSupabase` flag.

---

## 3. Verify the Deployment

From the repository root:

```bash
flutter pub get
flutter analyze     # 0 issues
flutter test        # 939 unit + widget tests, all green
```

Then smoke-test against live Supabase:

1. Log in as a staff account, place a delivery order → watch `[Dispatch]`
   logs assign a driver automatically.
2. Log in as that driver → the new-assignment alert fires; accept → start →
   complete the run.
3. As customer, open order tracking → real driver name/vehicle appear.
4. As manager, open `/manager/dispatch` → board lists undispatched orders;
   manually reassign one if needed.

---

## 4. Delivery Dispatch Architecture

```
                       ┌──────────────────────────────────────────────┐
                       │            AUTO-DISPATCH PIPELINE            │
                       └──────────────────────────────────────────────┘

  Order marked ready          OrdersController [Dispatch] hook
  (KDS / waiter)   ────────►  deliveryRepo.getAvailableDrivers()
                                        │
                                        ▼
                          DriverAssignmentService.assign()
                          (filters: available, load cap ≤ 3,
                           radius ≤ 5 km; score: distance .5 /
                           load .3 / rating .2; ties → driver id)
                                        │
                              Assigned └────► Waiting (no driver yet)
                                        │                 │
                                        ▼                 ▼
                        deliveryRepo.createAssignment()   queued for retry
                                        │                 (every 30 s,
                                        ▼                  _dispatchRetryInterval)
                     RealtimeService.broadcastDeliveryAssignmentCreated()
                                        │
              ┌─────────────────────────┴─────────────────────────┐
              ▼                                                   ▼
  Driver DeliveryController                          Customer deliveryAssignmentForOrderProvider
  realtime stream → new-assignment alert             (order tracking page: live driver
  accept → pickedUp → delivered                      name, vehicle, status; cancel only
                                                     while assignment still pending)

                       ┌──────────────────────────────────────────────┐
                       │           MANUAL ESCAPE HATCH                │
                       └──────────────────────────────────────────────┘

  Manager  ────────►  /manager/dispatch (DispatchBoardPage)
                      pick order → pick driver → createAssignment(method: manual,
                      same id upserts) → broadcast → same downstream flow
```

Every pipeline step logs under the `[Dispatch]` prefix
(`attempt-start`, `waiting`, `assigned`, `create-rejected`, `retry-attempt`,
`hook-failure`, …) so production incidents can be traced from a single grep.
