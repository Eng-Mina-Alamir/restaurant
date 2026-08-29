# Real-Time Architecture Analysis & Migration Status

> [!NOTE]
> **Status: Migration Completed & Consolidated onto Supabase Realtime.**
> The custom WebSocket service has been fully eliminated and all real-time events are now powered natively by Supabase Realtime Postgres Changes.

---

## 1. What's New: Modern Consolidated Architecture

We transitioned from two parallel, overlapping real-time systems to a **single source of truth** powered directly by Postgres database changes via Supabase Realtime.

### Summary of Changes

| Area | Previous State | New Architecture |
|---|---|---|
| **Realtime Engine** | Custom WebSocket client (`realtime_service.dart`) + Supabase Realtime | **Unified Supabase Realtime** (`supabase_realtime_service.dart`) |
| **Event Triggers** | Manual client `broadcast*()` calls + DB change triggers (duplicate events) | **Zero manual broadcasts**; all events fire automatically upon DB writes |
| **Table Service Requests** | In-memory only; lost on restart; manual loopback | Persistent `table_service_requests` table with RLS & Realtime publication |
| **Event Definitions** | Tied to custom WebSocket client | Clean domain entities in `lib/core/network/realtime_event.dart` |
| **Config & URLs** | Hardcoded/derived `wsUrl` in `EnvironmentConfig` | Cleaned up; managed transparently by Supabase SDK |
| **Code Footprint** | ~400 lines of custom socket reconnect/parser boilerplate | **Removed legacy WebSocket file completely** |

---

## 2. Realtime Event Streams Matrix

All 5 core application event streams now flow through Supabase Realtime (`onPostgresChanges`):

| Event Type | Table Triggered | Action / Filter | Target Consumers |
|---|---|---|---|
| `orderCreated` | `orders` | `PostgresChangeEvent.insert` | Kitchen KDS, Waiters, Manager Dashboard |
| `orderStatusChanged` | `orders` | `PostgresChangeEvent.update` | Customer Tracking, Waiters, KDS, Manager |
| `orderReadyForPickup` | `orders` | `PostgresChangeEvent.update` (`status == 'ready' && order_type == 'dineIn'`) | Waiter notification & pickup chime |
| `tableStatusChanged` | `tables` | `PostgresChangeEvent.all` | Table Management & Floor Map |
| `driverLocationUpdated` | `driver_locations` | `PostgresChangeEvent.all` | Live GPS Map Tracking for Customer & Dispatch |
| `tableServiceRequested` | `table_service_requests` | `PostgresChangeEvent.insert` | Waiter Table Service alerts |
| `tableServiceHandled` | `table_service_requests` | `PostgresChangeEvent.update` (`is_handled == true`) | Waiter / Table state sync |
| `deliveryAssignmentCreated` | `delivery_assignments` | `PostgresChangeEvent.insert` / `update` | Driver Home Page & Dispatch Board |
| `chatMessages` | `chat_messages` | `PostgresChangeEvent.insert` | Customer & Driver Live Chat |

---

## 3. Database Migration Applied (`table_service_requests`)

- **Migration File**: `supabase/migrations/20260829152500_create_table_service_requests.sql`
- **Schema**:
  - `id`: Text Primary Key (e.g. `req-tbl-1-...`)
  - `table_id`: Text / UUID reference to `tables`
  - `table_number`: Integer
  - `type`: Text (`callWaiter`, `requestBill`, `cleanTable`, `other`)
  - `note`: Text nullable
  - `requested_at`: Timestamptz default `now()`
  - `is_handled`: Boolean default `false`
  - `handled_at`: Timestamptz nullable
  - `handled_by_waiter_id`: Text nullable
- **Row Level Security (RLS)**:
  - `SELECT`: Authenticated users can view service requests.
  - `INSERT`: Authenticated users can create service requests.
  - `UPDATE`: Staff members only (`(SELECT public.is_staff())`).
  - `DELETE`: Managers and admins only (`(SELECT public.is_manager_or_admin())`).
- **Realtime Publication**:
  ```sql
  ALTER PUBLICATION supabase_realtime ADD TABLE public.table_service_requests;
  ```

---

## 4. Key Architecture Files

- **Event Definitions**: [`lib/core/network/realtime_event.dart`](file:///d:/Flutter%20projects/restaurant/restaurant_app/lib/core/network/realtime_event.dart)
- **Realtime Service**: [`lib/core/supabase/supabase_realtime_service.dart`](file:///d:/Flutter%20projects/restaurant/restaurant_app/lib/core/supabase/supabase_realtime_service.dart)
- **Table Service Repository (Domain)**: [`lib/features/table_management/domain/repositories/table_service_repository.dart`](file:///d:/Flutter%20projects/restaurant/restaurant_app/lib/features/table_management/domain/repositories/table_service_repository.dart)
- **Table Service Repository (Supabase Data)**: [`lib/features/table_management/data/repositories/supabase_table_service_repository.dart`](file:///d:/Flutter%20projects/restaurant/restaurant_app/lib/features/table_management/data/repositories/supabase_table_service_repository.dart)
- **Table Service Repository (In-Memory Fallback)**: [`lib/features/table_management/data/repositories/in_memory_table_service_repository.dart`](file:///d:/Flutter%20projects/restaurant/restaurant_app/lib/features/table_management/data/repositories/in_memory_table_service_repository.dart)
- **Table Service Controller**: [`lib/features/table_management/presentation/controllers/table_service_controller.dart`](file:///d:/Flutter%20projects/restaurant/restaurant_app/lib/features/table_management/presentation/controllers/table_service_controller.dart)
