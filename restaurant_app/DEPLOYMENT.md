# 🚀 Deployment Guide — Live Supabase Backend

Step-by-step guide for deploying the app against the live Supabase backend,
including the **required v3 + v4 database migrations**, backend toggles, and an
architecture map of the delivery dispatch pipeline.

---

## 1. Schema v3 — dispatch & status log (✅ APPLIED 2026-08-24)

> 🎉 **Already applied to the live project** as tracked migrations
> (`apply_schema_v3_dispatch_and_status_log` and follow-ups). The manual
> SQL-Editor workflow below is **deprecated** — see §1b for the current
> workflow. The root file [`supabase_migration_v3.sql`](supabase_migration_v3.sql)
> is archived reference material only.

<details><summary>Historical manual steps (do NOT use)</summary>

1. Open the **Supabase Dashboard** → select your project.
2. In the left sidebar, open **SQL Editor** → **New query**.
3. Copy the **entire** contents of `supabase_migration_v3.sql` and paste it into the editor.
4. Click **Run** and wait for "Success. No rows returned".

</details>

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

## 2. Schema v4 — chat (✅ APPLIED 2026-08-24)

> 🎉 **Already applied to the live project** as tracked migration
> `apply_schema_v4_chat_messages` (+ composite index in
> `missing_relations_and_indexes`). [`supabase_migration_v4.sql`](supabase_migration_v4.sql)
> is archived reference material only.

> ⚠️ **Do not skip this step.** Without the `chat_messages` table every chat
> send fails with a **Postgres error** (*relation "public.chat_messages" does
> not exist*). Apply it **after** `supabase_migration_v3.sql` — it references
> the `orders`, `profiles`, and `delivery_assignments` objects v3 creates.

### What v4 delivers

| Object | Purpose |
|--------|---------|
| `chat_messages.id` | UUID primary key (`gen_random_uuid()`) |
| `chat_messages.order_id` | FK → `orders.id` **ON DELETE CASCADE**; every conversation is scoped to one order |
| `chat_messages.sender_id` | FK → `profiles.id`; who wrote the message |
| `chat_messages.body` | Message text, `CHECK (char_length BETWEEN 1 AND 1000)` |
| `chat_messages.created_at` | `TIMESTAMPTZ DEFAULT NOW()`; message ordering |
| `idx_chat_messages_order_id` | Index on `order_id` for fast per-order history loads |
| RLS — participant-only reads | SELECT is limited to the order's customer, the assigned driver (`delivery_assignments.driver_id`), and managers/admins |
| RLS — authenticated sends | INSERT requires the same participant set **and binds `sender_id = auth.uid()`**, so a client can only send as itself |

> 🏢 Same single-tenant assumption as v3: manager/admin access via
> `is_manager_or_admin()` is role-global, not restaurant-scoped.

The "SCHEMA V4" section of [`supabase_schema.sql`](supabase_schema.sql)
mirrors this file.

---

## 3. Backend Toggles

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

## 3b. Database Migration Workflow (single source of truth)

**Never paste schema SQL into the Dashboard SQL Editor again.** Manual pasting
is what caused the original v3/v4 drift (repo files existed but the live
database never received them, silently breaking chat, status logs, and
dispatch).

All schema changes go through tracked migrations:

```bash
supabase migration new descriptive_name   # creates supabase/migrations/<ts>_descriptive_name.sql
supabase db push                           # apply pending migrations to the remote project
supabase migration list                    # confirm local history == remote history
supabase db pull descriptive_name          # pull out-of-band changes back into a migration file
```

### Applied migration log (2026-08-24 hardening pass)

| Migration | Contents |
|-----------|----------|
| `recursion_safe_role_helpers` | SECURITY DEFINER role helpers (`get_my_role`, `is_staff`, `is_manager_or_admin`, `has_role`, fixed `is_admin_for_restaurant` → `profiles`) with `SET search_path = ''`; EXECUTE revoked from `anon`/`PUBLIC` |
| `apply_schema_v3_dispatch_and_status_log` | `orders.assigned_kitchen_id/driver_id`, driver profile fields, `order_status_log`, delivery assignment policies |
| `apply_schema_v4_chat_messages` | `chat_messages` table + participant-only RLS |
| `rls_policies_for_unprotected_tables` | Policies for the 15 tables that had RLS but zero policies + storage policy modernization |
| `modernize_legacy_policies_initplan` | All legacy policies rewritten: `(SELECT auth.uid())` InitPlan form, `TO authenticated/anon` clauses (no more deprecated `auth.role()`), `WITH CHECK` on every UPDATE |
| `missing_relations_and_indexes` | FKs for `orders.discount_id`, `reservations.customer_id`, `tables/restaurant_tables.current_order_id`; backing indexes; loyalty partial-unique fix |
| `integrity_constraints_cleanup` | Junction-table composite UNIQUEs, enum CHECK constraints matching Dart enums, timestamp NOT NULL hygiene, mojibake default repairs |
| `revoke_anon_from_remaining_helpers` | Completed the anon lockdown (`is_admin`, loyalty RPCs) |

### RLS performance & recursion rules (must-follow for new policies)

1. **Always write `(SELECT auth.uid()) = user_id`, never `auth.uid() = user_id`.**
   Wrapping the call in a scalar subquery lets Postgres evaluate it **once per
   statement** (InitPlan) instead of once per row — this is the single biggest
   RLS performance lever.
2. Same applies to helper calls inside policies: write `(SELECT public.is_staff())`,
   not bare `public.is_staff()`.
3. **Never subquery `profiles` directly inside a policy** — that causes infinite
   recursion (`42P17`). Always go through the SECURITY DEFINER helpers, which
   read `profiles` as the table owner and therefore terminate.
4. Every UPDATE policy needs both `USING` and `WITH CHECK`.
5. Use explicit `TO authenticated` / `TO anon, authenticated` clauses instead of
   the deprecated `auth.role()`.

---

## 3c. Security Checklist (Dashboard settings)

These cannot be set via SQL migrations — verify in **Dashboard → Authentication**
before going live:

- [ ] **Leaked password protection: ENABLED** (Auth → Settings → "Prevent use
      of compromised passwords"). Currently **OFF** — flagged by Supabase advisors.
- [ ] Email confirmation required for new sign-ups.
- [ ] JWT expiry reviewed (default 1h is fine); refresh-token rotation enabled.
- [ ] Sessions revoked when deleting a user (deleting does not invalidate tokens).
- [ ] No `service_role` / secret keys anywhere in the repo or client builds;
      only the publishable key ships in `lib/config/supabase_config.dart`.

> ℹ️ The remaining advisor WARNs about `authenticated` being able to execute
> SECURITY DEFINER helpers (`is_staff`, `get_my_role`, loyalty RPCs, …) are
> **intentional**: RLS policy expressions run under the caller's role, so
> revoking EXECUTE from `authenticated` would break every guarded query.

---

## 4. Verify the Deployment

From the repository root:

```bash
flutter pub get
flutter analyze     # 0 issues
flutter test        # the full unit + widget suite passes
```

Then smoke-test against live Supabase:

1. Log in as a staff account, place a delivery order → watch `[Dispatch]`
   logs assign a driver automatically.
2. Log in as that driver → the new-assignment alert fires; accept → start →
   complete the run.
3. As customer, open order tracking → real driver name/vehicle appear.
4. As manager, open `/manager/dispatch` → board lists undispatched orders;
   manually reassign one if needed.

### Manual-dispatch half (no free driver → manager fallback)

The steps above only exercise automatic assignment. Verify the manual escape
hatch end-to-end too:

1. **Undispatched:** mark a delivery order ready while every driver is
   unavailable (offline, or at the load cap of 3 active runs) → auto-dispatch
   logs `[Dispatch] outcome=waiting`; on `/manager/dispatch` the order shows
   under **طلبات بانتظار سواق**.
2. **Manual assign:** as manager, tap **تعيين سواق** on that card and pick an
   available driver from the bottom sheet → a `pending` assignment is created
   (`assignment_method = 'manual'`) and broadcast over realtime.
3. **Driver receives it:** log in as the chosen driver → the new-assignment
   alert fires and the order appears as a pending card.
4. **Fail the run:** have the driver mark the delivery FAILED
   (`DeliveryController.fail`; if your build has no failure button, set
   `delivery_status = 'failed'` on the assignment row in Supabase Studio) →
   back on `/manager/dispatch` the order moves to **إعادة تعيين (فشل سابق)**,
   listing the failed driver's id on its card.
5. **Re-dispatch upserts the SAME row:** assign again to a different driver →
   the original row id is reused (reset to `pending`, stamped `manual`) — no
   duplicate assignment forks for the same order (check
   `delivery_assignments` by `order_id`: still one row).
6. **Terminal states free capacity:** note that `delivered` and `failed` are
   both end-of-line statuses — either immediately drops off the driver's
   active-run count (`getAvailableDrivers` counts only non-terminal rows), so
   the driver becomes dispatchable again right away without any cleanup step.

---

## 5. Delivery Dispatch Architecture

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

**Order-scoped chat (v4):** from an active order both sides can open
`/chat/:orderId` — customer via the order-tracking page, driver via the active
assignment card — and the chat page reads/writes `chat_messages`, streamed
live through RealtimeService.
