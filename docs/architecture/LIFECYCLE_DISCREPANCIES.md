# Lifecycle Review — Discrepancies & Fixes

> Generated: 2026-06-17  
> Source: Cross-validation of ENTITY_LIFECYCLE.md against migrations 01–12 and domain entities

---

## CRITICAL (Fix before launch)

### D-001: `open_for_booking` trip status does not exist in DB

**Finding:**  
`OperationTripStatus.openForBooking` in Flutter maps `.dbValue` to `'scheduled'`, making it indistinguishable from a trip that is scheduled but not yet ready for booking. The `update_trip_status` RPC only knows `scheduled → boarding/cancelled`. There is no `open_for_booking` state in the DB.

**Impact:**  
- Clients can discover `scheduled` trips (RLS allows it) even if pricing hasn't been configured yet
- Dashboard cannot distinguish "created but not published" from "open for booking"
- The `openForBooking` UI concept has no DB enforcement

**Fix:**  
- migration_13: Add `open_for_booking` to `update_trip_status` transition machine
- migration_13: Update RLS to expose only `open_for_booking` (not `scheduled`) to clients
- Code: Change `OperationTripStatus.openForBooking.dbValue` from `'scheduled'` to `'open_for_booking'`
- Code: Update all queries that filter trips for clients to use `open_for_booking`

**Status:** Fixed in migration_13 + code update

---

### D-002: `DATABASE_SCHEMA.md` status enums are outdated

**Finding:**  
`DATABASE_SCHEMA.md` documents typed Postgres ENUMs for driver, vehicle, booking, and trip statuses. In reality, all `status` columns are `text` (not typed enums). The actual values differ significantly from the documentation:

| Entity | Documented in Schema.md | Actual DB values (from migrations) |
|--------|--------------------------|-------------------------------------|
| `operation_bookings.status` | `pending, confirmed, cancelled, refunded` | `newRequest, paymentUploaded, underReview, approved, rejected, requestReupload, confirmed, cancelled` |
| `operation_trips.status` | `scheduled, boarding, in_progress, completed, cancelled` | Same — correct |
| `drivers.status` | `available, assigned, on_trip, suspended, license_expired` | Unknown from migrations — code uses `active, suspended, archived` |
| `vehicles.status` | `available, assigned, in_maintenance, on_trip, inactive` | Unknown from migrations — code uses `active, maintenance, suspended, archived` |
| `routes.status` | `draft, active, archived` | Code also uses `paused` — not in schema doc |
| `subscriptions.status` | `active, expired, cancelled` | Code also uses `pendingPayment` — not in schema doc |

**Fix:** Update `DATABASE_SCHEMA.md` to reflect actual text-column values.

**Status:** Updated inline below.

---

### D-003: `paused` route status and `pendingPayment` subscription status are code-only

**Finding:**  
`OperationRouteStatus.paused` and `SubscriptionStatus.pendingPayment` exist in Dart code and are written to the DB (text column), but:
- No RLS policy accounts for `paused` routes
- No `update_trip_status`-style RPC enforces valid route status transitions
- No DB index covers `paused` or `pendingPayment`

**Impact:**  
- A paused route is still discoverable by clients (RLS only checks `status = 'active'`, it doesn't block `paused`)
  - Actually wait: the RLS says `status = 'active' OR has_role('operations_manager')` — so `paused` routes ARE blocked from clients ✓
  - But if RLS is re-evaluated and the check is changed, `paused` routes could leak
- `pendingPayment` subscriptions: no server-side validation prevents using them for booking

**Fix:**  
- migration_13: Add explicit DB comments on these status values
- migration_13: Add check constraint on `subscriptions.status` to prevent using `pendingPayment` subscriptions for seat booking (add to `book_trip_seat` RPC)

---

## HIGH (Fix before beta)

### D-004: Realtime channels implemented vs documented

The following channels are **actually implemented** in code:

| Channel | Where | Used For |
|---------|-------|---------|
| `live_location:{trip_id}` (broadcast) | `location_background_service.dart` | Captain → Dashboard GPS |
| `stream(primaryKey: ['id'])` on `trip_passengers` | `passenger_manifest_datasource.dart` | Captain manifest |
| `stream(primaryKey: ['id'])` on `operation_trips` filtered by `driver_id` | `captain_trip_remote_datasource.dart` | Captain assigned trips |
| `stream(primaryKey: ['id'])` on `captain_messages` | `supabase_chat_datasource.dart` | Captain chat |
| `stream(primaryKey: ['id'])` on `operation_bookings` | `supabase_bookings_datasource.dart` | Dashboard bookings |

The following channels are **documented in ENTITY_LIFECYCLE.md but NOT implemented**:

| Channel | Missing From |
|---------|-------------|
| `trip.published` / `trip.boarding_started` / `trip.started` / `trip.completed` | Dashboard Trips module + Client App |
| `booking.approved` / `booking.rejected` push to client | Client booking status |
| `passenger.boarded` to Dashboard manifest panel | Dashboard Trips module |
| `route.*` events | Dashboard Routes |
| `assignment.created` / `assignment.ended` | Dashboard Fleet |
| `subscription.activated` / `subscription.expired` | Client App |

**Fix:**  
The missing channels are all Push Notification equivalents rather than true realtime. The `stream()` approach (Supabase's `postgres_changes` wrapper) already covers manifest updates and booking queue updates. The named channels in the lifecycle doc should be re-labelled as "Push Notification events" not "Realtime channels". Add the `trip.boarding_started` and `booking.approved` client notifications as part of the RPC side-effect flow.

---

### D-005: No-show handling is automatic but not in any lifecycle doc

**Finding:**  
When `update_trip_status` is called with `completed`, the RPC automatically marks all `trip_passengers` with status not in `('confirmed', 'cancelled', 'no_show', 'completed')` as `no_show`. This is implemented in migration_09 but was not documented in the lifecycle doc.

**Fix:** Added to ENTITY_LIFECYCLE.md under Trip → `in_progress → completed` side effects. ✓

---

### D-006: `scan_passenger_ticket` marks booking `confirmed`, not `trip_passengers`

**Finding:**  
The lifecycle doc says QR scanning marks `operation_bookings.status = 'confirmed'`. Migration_07 confirms:
```sql
SET status = 'confirmed', updated_at = now()  -- on operation_bookings
SET status = 'confirmed', updated_at = now()  -- on trip_passengers
```
Both records are updated simultaneously in the same RPC. Correct — no fix needed, but both tables are updated not just bookings.

---

## MEDIUM (Fix in P1)

### D-007: `FleetDriverStatus` doesn't match DB driver status

**Finding:**  
Code uses `active / suspended / archived` for `FleetDriverStatus`. The `DATABASE_SCHEMA.md` says `available / assigned / on_trip / suspended / license_expired`. Neither is confirmed by the migration SQL (migrations don't show driver status change logic — it's done via direct UPDATE). The operational sub-statuses (`available`, `assigned`, `on_trip`) need to be either:
a) Tracked as separate fields (`is_assigned bool`, `is_on_trip bool`), or
b) Derived from related tables (has active assignment → `assigned`, has active trip → `on_trip`)

**Recommendation:** Keep `drivers.status` as the administrative state (`active/suspended/archived`). Derive operational state from `assignments` and `operation_trips` tables. Update code to compute sub-status from joins rather than storing it.

---

## CORRECTED DATABASE_SCHEMA

The following table supersedes the relevant sections of `DATABASE_SCHEMA.md`:

### `operation_bookings.status` (text)
Values: `newRequest` | `paymentUploaded` | `underReview` | `requestReupload` | `approved` | `rejected` | `confirmed` | `cancelled`

### `operation_trips.status` (text)  
Values: `scheduled` | `open_for_booking`* | `boarding` | `in_progress` | `completed` | `cancelled`  
*Added in migration_13

### `operation_routes.status` (text)
Values: `draft` | `active` | `paused` | `archived`

### `subscriptions.status` (text)
Values: `pendingPayment` | `active` | `expired` | `cancelled`

### `drivers.status` (text)
Values: `active` | `suspended` | `archived`

### `vehicles.status` (text)
Values: `active` | `maintenance` | `suspended` | `archived`

### `assignments.status` (text)
Values: `active` | `ended`

### `trip_seats.state` (text)
Values: `available` | `reserved` | `paid` | `subscription` | `blocked`

### `trip_passengers.status` (text)
Values: `reserved` | `confirmed` | `no_show` | `cancelled` | `completed`
