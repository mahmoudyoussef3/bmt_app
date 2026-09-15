# Dashboard · Trips (الرحلات)

The office's trip planner and trip workspace: list (newest 1 500), create (driver-first — the
vehicle and seat map are derived from the driver's assignment), edit planning fields, delete
(narrowly), lifecycle transitions through the server state machine, cancel with a reason, close a
departure whose day passed, seat state edits, passenger edits/moves/cancellation, the per-stop-pair
fare table with per-package prices and notes, trip-scoped ad-hoc packages, the event log, and two
realtime channels.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/trips/`) |
|---|---|
| Screens | `presentation/screens/` (`DashboardRoutes.trips` = `/trips`; the workspace opens a trip in a detail pane with tabs: seats, passengers, pricing, events) |
| Cubits | `trip_management/presentation/cubit/trips_cubit.dart`, `trip_creation/presentation/cubit/trip_creation_cubit.dart`, `trip_pricing/presentation/cubit/trip_pricing_cubit.dart`, `trip_seats/…`, `trip_passengers/…` |
| Use cases | `trip_management/domain/usecases/trip_management_usecases.dart`, `trip_creation/domain/usecases/trip_creation_usecases.dart` (`CreateTripUseCase` — **orchestrates T3 + T14 + T12 in a loop**) |
| Repo | `trip_management/data/repositories/trips_repository_impl.dart` (client-side pre-checks: lifecycle, publish blockers, driver assignment) |
| **Datasource** | `trip_management/data/datasources/supabase_trips_datasource.dart` (`SupabaseTripsDatasource implements TripsDatasource`) |
| Models / entities | `shared/data/models/operation_trip_model.dart` (`OperationTripModel`, `TripRoutePointModel`, `TripSeatModel`, `TripPassengerModel`, `TripEventModel`), `shared/data/models/trip_pricing_model.dart`; `shared/domain/entities/operation_trip.dart` (`OperationTripStatus`, `TripSeatState`), `trip_lifecycle.dart` (`TripLifecycle`, `TripPublishBlocker`, `StaleTripOutcome`), `trip_pricing.dart`, `trip_pricable_package.dart`, `trip_package_offer.dart`, `trip_creation/domain/entities/trip_driver_option.dart` |
| DI | `trips_di.dart` |
| Permission | `DashboardPermission.trips` (admin only); feature key `trips`; limit feature `max_trips_per_month` (flow meter — enforced server-side on create) |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| T1 | List trips (newest 1 500, full embed) | `GET operation_trips?select=*,route:…,driver:…,vehicle:…,route_points:…,seats:…,passengers:…,events:…&office_id=eq.&order=trip_date.desc,departure_time.desc&limit=1500` | `GET /api/v1/dashboard/trips` |
| T2 | One trip | same select `&id=eq.` (`.single()`) | `GET /api/v1/dashboard/trips/{tripId}` |
| T3 | Create trip | `GET route_stations` → `POST rpc/office_create_trip` → T2 | `POST /api/v1/dashboard/trips` |
| T4 | Edit planning fields | `PATCH operation_trips` + T13 log + T2 | `PATCH /api/v1/dashboard/trips/{tripId}` |
| T5 | Delete trip | `DELETE operation_trips?id=eq.` | `DELETE /api/v1/dashboard/trips/{tripId}` |
| T6 | Lifecycle transition | `POST rpc/office_update_trip_status` → T2 | `POST /api/v1/dashboard/trips/{tripId}/status` |
| T7 | Cancel with reason | `POST rpc/office_cancel_trip` → T2 | `POST /api/v1/dashboard/trips/{tripId}/cancel` |
| T8 | Close a stale trip | `POST rpc/office_close_stale_trip` → T2 | `POST /api/v1/dashboard/trips/{tripId}/close-stale` |
| T9 | Seat state | `GET trip_seats(seat_label)` → `PATCH trip_seats` + log + T2 | `PATCH /api/v1/dashboard/trips/{tripId}/seats/{seatId}` |
| T10 | Edit passenger | `PATCH trip_passengers` + log + T2 | `PATCH /api/v1/dashboard/trip-passengers/{id}` |
| T10b | Cancel passenger | `GET trip_passengers` → `PATCH trip_passengers` → `PATCH trip_seats` + log + T2 | `POST /api/v1/dashboard/trip-passengers/{id}/cancel` |
| T10c | Move passenger to seat | 2 `GET`s → 3 `PATCH`es + log + T2 | `POST /api/v1/dashboard/trip-passengers/{id}/move` |
| T11 | Fare table | `GET trip_pricing?select=*,trip_package_prices(package_id,price,note)&trip_id=eq.&order=from_point_order` | `GET /api/v1/dashboard/trips/{tripId}/pricing` |
| T12 | Upsert one stop pair | `POST|PATCH trip_pricing` → `DELETE trip_package_prices` → `POST trip_package_prices[]` → `GET` + log | `PUT /api/v1/dashboard/trips/{tripId}/pricing/{pairId}` |
| T12b | Toggle a pair | `PATCH trip_pricing {is_active}` + log | `PATCH /api/v1/dashboard/trip-pricing/{pricingId}` |
| T13 | Event log (read / write) | `GET trip_events?trip_id=eq.&order=event_time.desc` / `POST trip_events` | `GET /api/v1/dashboard/trips/{tripId}/events` (writes become server-side) |
| T14 | Catalogue packages pricable on a trip | `GET transport_packages?office_id=eq.&active=eq.true&trip_id=is.null&order=display_order` | `GET /api/v1/dashboard/packages/pricable` |
| T14b | Trip-scoped packages | same `&trip_id=eq.<tripId>` | `GET /api/v1/dashboard/trips/{tripId}/packages` |
| T14c | Create a trip-scoped package | `GET max(display_order)` → `POST transport_packages` | `POST /api/v1/dashboard/trips/{tripId}/packages` |
| T15 | Schedulable drivers (+ their vehicle) | `GET drivers?select=…,assignments(status,vehicles(...))&office_id=eq.&status=eq.active&license_expiry_date=gte.<today>&order=full_name` | `GET /api/v1/dashboard/trips/schedulable-drivers` |
| T15b | One driver's assignment (re-read at submit) | same `&id=eq.` (`.maybeSingle()`) | `GET /api/v1/dashboard/drivers/{driverId}/assignment` |
| T16 | Active routes with stations | `GET operation_routes?select=*,route_stations(*)&office_id=eq.&status=eq.active` | `GET /api/v1/dashboard/routes?status=active&include=stations` |
| T17 | Resource conflicts for a slot | `GET operation_trips?select=driver_id,vehicle_id,trip_code,trip_date,departure_time,arrival_time&office_id=eq.&status=neq.cancelled&service_window=ov.[start,end)` | `GET /api/v1/dashboard/trips/conflicts?date=&departure=&arrival=` |
| T18 | Route status | `GET operation_routes?select=status&id=eq.` | `GET /api/v1/dashboard/routes/{routeId}/status` |
| T19 | Realtime (list) | channel `dashboard_trip_management_<officeId>`: `operation_trips`, `trip_seats`, `trip_passengers`, `trip_events` (all events, unfiltered) | per-office `trips.changed` |
| T19b | Realtime (one trip) | channel `dashboard_trip_details_<tripId>`: same tables filtered `id/trip_id = tripId` | per-trip `trip.changed` |

All errors: `LicensingGuard.check()` → then `_translateServerError` (`supabase_trips_datasource.dart:916`)
maps these machine codes to Arabic: `trip_not_publishable:<code>`, `cancellation_reason_required`,
`trip_status_direct_update_forbidden`, `trip_direct_write_forbidden`, `invalid_transition`, `trip_locked`,
`trip_delete_forbidden` (`has bookings` variant), `trip_never_published`, `trip_already_closed`,
`not_authorized`, `trip_not_found`, `package_trip_office_mismatch`. **Keep these codes.**

---

## T1 / T2 — List and detail (`fetchTrips()` line 26, `fetchTripById()` line 56)

```
GET /rest/v1/operation_trips
  ?select=*,route:operation_routes(id,name),driver:drivers(id,full_name),
          vehicle:vehicles(id,plate_number,vehicle_code,vehicle_type),
          route_points:trip_route_points(*),seats:trip_seats(*),passengers:trip_passengers(*),events:trip_events(*)
  &office_id=eq.<session office>&order=trip_date.desc,departure_time.desc&limit=1500
```

`OperationTripModel.fromJson` reads: `id, route_id, driver_id, vehicle_id, trip_date, departure_time,
arrival_time, status, capacity, ticket_price, currency (default 'ج.م'), notes[]`; `route.name`
('مسار غير معروف'), `driver.full_name` ('سائق غير معروف'), vehicle label = `'<vehicle_type> (<vehicle_code>) <plate_number>'`
(or plate only). Children:

| Child | Columns read | Notes |
|---|---|---|
| `trip_route_points` | `id, point_name, point_order, arrival_offset, departure_offset` (+ lat/lng) | sorted by order in Dart |
| `trip_seats` | `id, seat_label, seat_row, seat_column, state, passenger_id` | sorted by label; `state ∈ available|reserved|paid|subscription|blocked` |
| `trip_passengers` | `id, passenger_name, phone, status, seat_id/seat_label, pickup_point_name, dropoff_point_name, payment_method` | |
| `trip_events` | `id, title, description, event_time, done` | |

`operation_trips.status` wire values: `scheduled` (= the draft), `open_for_booking`, `boarding`,
`in_progress`, `completed`, `cancelled`. `RLS` `trips_office_manage` (`office_id = current_office_id()`)
plus `*_office_manage` on every child (through `operation_trips.office_id`).

**Proposed .NET:** `GET /api/v1/dashboard/trips?status=&date=&routeId=&page=` returning the trip **without**
children (they are per-trip: `GET /trips/{id}` with `seats`, `passengers`, `routePoints`, `events`).
Today one list call pulls every seat/passenger/event of 1 500 trips — the heaviest read in the console.

---

## T3 — Create: `createTrip(input)` (line 80) — orchestrated by `CreateTripUseCase`

Client-side pre-flight (`trips_repository_impl.dart:118`): required fields, `ticketPrice > 0`, T18 route
not `archived`, T15b driver belongs to the office / has a vehicle / vehicle `isSchedulable`.

```
GET /rest/v1/route_stations?select=*&route_id=eq.<routeId>&order=sort_order.asc
   → builds p_route_points[] = { route_point_id, point_name, point_order (=sort_order),
       arrival_offset, departure_offset (overridable per station from the wizard), latitude, longitude }
   → Exception('لا يمكن إنشاء رحلة لمسار ليس له محطات.') when empty

POST /rest/v1/rpc/office_create_trip
{ "p_route_id":"<uuid>", "p_driver_id":"<uuid>", "p_trip_date":"yyyy-MM-dd",
  "p_departure_time":"HH:mm[:ss]", "p_arrival_time":"HH:mm[:ss]",
  "p_ticket_price": 120, "p_currency":"EGP",
  "p_notes": ["تم إنشاء الرحلة ونمذجة المحطات والمقاعد تلقائياً"],
  "p_route_points": [ … ] }                          (p_trip_code omitted → generated)
→ 200 { "success":true, "trip_id":"<uuid>", "trip_code":"TR-00042", "vehicle_id":"<uuid>",
        "seats_created": 14, "stations_created": 6 }
```

`BUSINESS RULE` — `office_create_trip` (`20260731090000_driver_vehicle_authority.sql`), `authenticated`:
`not_an_office_user`; `route_not_in_office`; `driver_required`; `driver_not_in_office`;
`driver_unavailable` (status ≠ active); **vehicle = `driver_active_vehicle(driver)`** — never a parameter
(`driver_has_no_vehicle`); `vehicle_not_in_office`, `vehicle_unavailable`; `trip_code = 'TR-' + lpad(max+1, 5)`
per office (`next_office_trip_code`). Then `create_trip(...)` (same file):
`no_route_points`; seats = `vehicle_trip_seats(vehicle)` (`vehicle_has_no_seats`, `duplicate_seat_labels`);
`capacity = count(seats)`; overlap pre-check → `driver_conflict` / `vehicle_conflict` naming the other trip;
inserts `operation_trips` (`status:'scheduled'`, `capacity`, `service_window` is a **generated column**
`[date+departure, date+arrival(+1 day if ≤ departure; +1h if null) + 30 min)`), `trip_route_points`,
`trip_seats` (all `available`), one `trip_events` row 'إنشاء الرحلة'. The exclusion constraints
`operation_trips_driver_no_overlap` / `_vehicle_no_overlap` (`gist`, `status <> 'cancelled'`) are the real
authority. Licensing: `max_trips_per_month` is a **flow** meter consumed by a trigger on insert
(`quota_exceeded`); feature `trips` asserted.

After the RPC, `CreateTripUseCase` (`trip_creation_usecases.dart:18`):
1. creates each **new** package offer via T14c (one insert per offer),
2. **expands the single fare across every boarding→dropoff pair** `(i<j)` of the trip's route points
   with the same `one_time_price`, the same `packagePrices` and the same `packageNotes` → one T12 call
   per pair (n·(n−1)/2 upserts, each = 3–4 requests),
3. re-reads T2.

`BUSINESS RULE` — a trip with **no active `trip_pricing` row cannot be published** (`no_pricing` blocker),
so if step 2 fails half-way the trip stays a draft.

**Proposed .NET:** `POST /api/v1/dashboard/trips { routeId, driverId, tripDate, departureTime, arrivalTime,
ticketPrice, currency, stationTimeOverrides[], packageOffers[] }` → `201 Trip` doing **all of the above in one
transaction**: route points from `route_stations`, seats from the driver's vehicle, the fare expansion to all
pairs, and the offers. Keep every code above.

---

## T4 — Edit planning fields: `updateTripInfo(trip)` (line 147)

```
PATCH /rest/v1/operation_trips?id=eq.<id>
{ "driver_id", "vehicle_id", "trip_date", "departure_time", "arrival_time"|null, "ticket_price", "currency" }
POST  /rest/v1/trip_events { trip_id, title:'تعديل تفاصيل الرحلة', description:'…', event_time:<utc>, done:true }
```

Repo (`trips_repository_impl.dart:193`): if the driver changed, T15b re-reads the new driver's assignment
and **sets `vehicle_id` to that driver's vehicle** (the operator never picks a vehicle). `BUSINESS RULE`
trigger `enforce_trip_write_authority` (`20260727160000_trip_lifecycle_authority.sql:378`): `status` may not
be written here (`trip_status_direct_update_forbidden`); a `completed/cancelled` trip is frozen
(`trip_locked`); a `boarding/in_progress` trip allows only driver/vehicle changes; captains may not write
the table at all. Changing `driver_id` fires the captain notification 'تم إسنادك لرحلة جديدة'
(`on_operation_trip_change`). The overlap constraints apply to updates too.
**Note:** `ticket_price` edits here do **not** touch `trip_pricing` — the fare table is separate (T11/T12).

**Proposed .NET:** `PATCH /api/v1/dashboard/trips/{tripId} { driverId?, tripDate?, departureTime?, arrivalTime?, ticketPrice?, currency? }`.

---

## T5 — Delete: `deleteTrip(tripId)` (line 175)

`DELETE /rest/v1/operation_trips?id=eq.<id>`. Repo pre-check `TripLifecycle.canDelete` (scheduled + no
passengers); server trigger `enforce_trip_delete_guard`: `trip_delete_forbidden` unless `status = 'scheduled'`
**and** no `operation_bookings` reference it. Children cascade per FK.

---

## T6 — Transition: `updateTripStatus(tripId, status, reason)` (line 184)

```
POST /rest/v1/rpc/office_update_trip_status
{ "p_trip_id":"<uuid>", "p_new_status":"open_for_booking|boarding|in_progress|completed|cancelled", "p_reason": null|"…" }
→ 200 { success, unchanged, trip_id, previous_status, new_status,
        bookings_affected, passengers_affected, seats_released, refund_owed_count, actual_start_time, actual_end_time }
```

Repo pre-checks mirror the server (`TripLifecycle.canTransition`, `TripPublishBlocker.evaluate`) and route
`cancelled` to T7. `BUSINESS RULE` — `update_trip_status` (`20260727160000…:125`, reachable only via the
`office_`/`captain_` wrappers):
* Wrapper: owner office, **or** the assigned captain limited to `boarding|in_progress|completed`
  (`status_not_allowed_for_captain`), else `not_authorized`.
* Idempotent: same status ⇒ `unchanged:true`, no side effects.
* Edges: `scheduled→{open_for_booking,cancelled}`, `open_for_booking→{boarding,cancelled}`,
  `boarding→{in_progress,cancelled}`, `in_progress→{completed,cancelled}`; else `invalid_transition`.
* Publish gate `trip_publish_blocker`: `no_driver | no_vehicle | no_seats | no_pricing | past_date` ⇒
  `trip_not_publishable:<code>`.
* `cancellation_reason_required` when cancelling from `boarding|in_progress` without a reason.
* Stamps `actual_start_time` on entry to **boarding**, `actual_end_time` on `completed` (always) or
  `cancelled` (only if started).
* `completed`: bookings `confirmed→completed`; passengers `confirmed→completed`, everyone else not
  cancelled/no_show → `no_show`.
* `cancelled`: notifies riders whose payment was still under review (not yet in `trip_passengers`);
  bookings not cancelled/rejected → `cancelled` (**`payment_status` untouched** — refunds are a separate
  action, see `wallet/`); passengers → `cancelled`; seats → `available` (holds cleared);
  `refund_owed_count` = approved payments on the trip.
* Writes `trip_events` with `event_code ∈ trip_published|boarding_started|trip_departed|trip_completed|trip_cancelled`.
* Trigger `on_operation_trip_change` then pushes rider + captain notifications per status and a
  `trip_cancelled` operational alert (see `notifications/`).

**Proposed .NET:** `POST /api/v1/dashboard/trips/{tripId}/status { status, reason? }` → the same payload.

---

## T7 — Cancel: `cancelTrip(tripId, reason)` (line 206)

`POST rpc/office_cancel_trip { p_trip_id, p_reason }` → `cancellation_reason_required` if blank, else T6 with
`cancelled`. **Proposed .NET:** `POST /api/v1/dashboard/trips/{tripId}/cancel { reason }`.

## T8 — Close a stale trip: `closeStaleTrip(tripId, outcome, reason)` (line 220)

```
POST rpc/office_close_stale_trip { "p_trip_id", "p_outcome": "operated"|"cancelled", "p_reason": null|"…" }
```
`trip_already_closed` if completed/cancelled; `cancelled` ⇒ T7 with reason default 'إغلاق رحلة فات موعدها';
`operated`: `trip_never_published` if still `scheduled`, else walks the machine
`open_for_booking→boarding→in_progress→completed` with rider notifications **suppressed** (`bmt.trip_notify_suppress`).
Stale = `open_for_booking` with `trip_date < today` (flagged in the UI, never auto-closed — by owner's choice).

---

## T9 — Seat state: `updateSeatState(tripId, seatId, state)` (line 242)

```
GET   /rest/v1/trip_seats?select=seat_label&id=eq.<seatId>
PATCH /rest/v1/trip_seats?id=eq.<seatId>   { "state": "available|reserved|paid|subscription|blocked", "passenger_id": null (only for available/blocked) }
POST  /rest/v1/trip_events { … 'تعديل حالة المقعد' … }
```
Direct write under `trip_seats_office_manage`. `booked_seats` on the trip is recomputed by trigger
`sync_trip_booked_seats`. No business validation server-side (an operator can mark a seat `paid` with no
booking). `NEEDS BACKEND DECISION`: restrict to `available ⇄ blocked` for operators.

## T10 — Passengers (lines 279 / 306 / 345)

* **Edit**: `PATCH trip_passengers?id=eq. { passenger_name, phone, status }` + log.
* **Cancel**: read `passenger_name, seat_id` → `PATCH trip_passengers {status:'cancelled'}` →
  `PATCH trip_seats?id=eq.<seat_id> {state:'available', passenger_id:null}` + log.
  **Does not touch `operation_bookings`** — the booking stays `confirmed`. `NEEDS BACKEND DECISION`.
* **Move**: read passenger (`seat_id`, `status`) → read target seat by `trip_id + seat_label` (must be
  `available`, else 'المقعد المطلوب غير متاح حالياً.') → old seat `available` → new seat
  `state = passenger.status == 'subscription' ? 'subscription' : 'reserved'`, `passenger_id = <passenger row id>`
  → `PATCH trip_passengers { seat_id, seat_label }` + log. Not transactional; note the new seat gets
  `reserved` even if the booking is paid, and `passenger_id` receives the manifest id (elsewhere it holds
  the client id). `operation_bookings.seat_id/seat` are **not** updated.

**Proposed .NET:** `PATCH /trip-passengers/{id}`, `POST /trip-passengers/{id}/cancel`,
`POST /trip-passengers/{id}/move { seatLabel }` — each one transaction, keeping booking + manifest + seat in step.

---

## T11 / T12 — Fare table (`fetchTripPricing` line 411, `upsertTripPricing` line 430, `toggleTripPricingStatus` line 486)

```
GET /rest/v1/trip_pricing?select=*,trip_package_prices(package_id,price,note)&trip_id=eq.<id>&order=from_point_order.asc
```
Row: `id, trip_id, from_point_id, to_point_id, from_point_name, to_point_name, from_point_order, to_point_order,
one_time_price, currency, is_active, created_at, updated_at` + `trip_package_prices[] { package_id, price, note }`
→ `TripPricing.packagePrices{packageId→price}` / `packageNotes{packageId→note}`.

Upsert of one pair (4 requests, not atomic):
```
POST  /rest/v1/trip_pricing  { trip_id, from_point_id, to_point_id, from_point_name, to_point_name, from_point_order, to_point_order, one_time_price, currency, is_active }   (.select().single())   — or PATCH …?id=eq. when id known
DELETE /rest/v1/trip_package_prices?trip_pricing_id=eq.<pricingId>
POST  /rest/v1/trip_package_prices  [ { trip_pricing_id, package_id, price, note:'' } … ]
GET   /rest/v1/trip_pricing?select=…&id=eq.<pricingId>
POST  /rest/v1/trip_events { 'تحديث التسعير' … }
```
Toggle: `PATCH trip_pricing?id=eq. { is_active }` + log.

`BUSINESS RULE` (pricing model, from memory + `20260815091000_per_package_trip_pricing.sql`): ONE fare per
trip expanded to all stop pairs; a package price is a flat amount per package per pair (not rides×fare);
the **single-ride shape** (`duration_days ≤ 1 && ride_count ≤ 1`) is *not* a package row — it is
`one_time_price`. `trip_package_prices.note` = exact-pair note. The client booking RPC
(`confirm_seat_booking_v2`) reads `trip_pricing` for the chosen pair and falls back to the catalogue
price when no active row exists.

**Proposed .NET:** `GET /trips/{id}/pricing`, `PUT /trips/{id}/pricing/{pairId} { oneTimePrice, currency, isActive, packagePrices:[{packageId, price, note}] }`
(replace-children semantics, one transaction), `PATCH /trip-pricing/{id} { isActive }`.
Also worth adding: `PUT /trips/{id}/pricing/bulk` so the planner's "same fare on every pair" is one call.

---

## T13 — Events (`fetchTripEvents` line 630, `logEvent` line 646)

`GET trip_events?select=*&trip_id=eq.&order=event_time.desc`; writes are `POST trip_events { trip_id, title,
description, event_time:<utc iso>, done:true }` fired by the datasource after every direct write (T4, T9,
T10, T12) and **swallowed on failure**. The lifecycle RPCs write their own rows with `event_code`.
**Proposed .NET:** read-only endpoint; every mutation endpoint writes its own event server-side.

---

## T14 — Packages for the fare editor (lines 516 / 537 / 556)

```
GET /rest/v1/transport_packages?select=id,name_ar,name_en,ride_count,duration_days,price
   &office_id=eq.<office>&active=eq.true&trip_id=is.null&order=display_order.asc          (catalogue)
GET … &trip_id=eq.<tripId> …                                                              (trip-scoped)
```
Dart drops the single-ride shape (`duration_days ≤ 1 && ride_count ≤ 1`). Name = `name_ar` or `name_en`.

Create trip-scoped package:
```
GET  /rest/v1/transport_packages?select=display_order&office_id=eq.&order=display_order.desc&limit=1   (.maybeSingle())
POST /rest/v1/transport_packages
{ office_id, trip_id, name_ar, name_en (=same), package_type:'trip_<microseconds>', price, duration_days, ride_count,
  description_ar:'', description_en:'', active:true, display_order:<max+1> }   (.select('id').single())
```
`BUSINESS RULE` trigger `enforce_trip_package_office` (`20260820100000_trip_scoped_packages.sql:65`):
`package_trip_office_mismatch` if `trip_id`'s office ≠ `office_id`. `package_type` is a free-text
discriminator (unique per office) — hence the timestamp.

**Proposed .NET:** `GET /packages/pricable`, `GET /trips/{id}/packages`, `POST /trips/{id}/packages { name, price, durationDays, rideCount }`.

---

## T15 — Drivers for the planner (lines 669 / 701)

```
GET /rest/v1/drivers?select=id,full_name,phone,assignments(status,vehicles(id,plate_number,vehicle_code,vehicle_type,brand,model,capacity,status))
   &office_id=eq.<office>&status=eq.active&license_expiry_date=gte.<today>&order=full_name.asc
```
`assignments` are filtered **in Dart** to `status='active' && vehicles != null` (filtering the embed
server-side would drop drivers without a bus, whom the planner must still list and explain). →
`TripDriverOption { id, name, phone, assignedVehicle? { id, plateNumber, vehicleCode, vehicleType, brand, model, capacity, status } }`.
T15b re-reads one driver (`&id=eq.&office_id=eq.`, `.maybeSingle()` → `null` = not ours) at submit time.

**Proposed .NET:** `GET /api/v1/dashboard/trips/schedulable-drivers` → drivers with `assignedVehicle|null`
and a `schedulable` flag + reason.

## T16 / T17 / T18 — Routes, conflicts, route status

* T16 `GET operation_routes?select=*,route_stations(*)&office_id=eq.&status=eq.active` (the wizard's route picker).
* T17 `GET operation_trips?select=driver_id,vehicle_id,trip_code,trip_date,departure_time,arrival_time&office_id=eq.&status=neq.cancelled&service_window=ov.[<start>,<end>)`
  where the window is computed **exactly like the generated column** (arrival ≤ departure ⇒ +1 day; empty ⇒
  +1 h; then +30 min). Used to grey out busy drivers before submit.
* T18 `GET operation_routes?select=status&id=eq.` → `'draft'` default; `archived` blocks creation.

---

## T19 — Realtime

`SUPABASE-SPECIFIC`. Two channels (`watchTripsChanges` line 823, `watchTripChanges` line 857); any event
re-runs T1 or T2. **Proposed .NET:** push `trips.changed` / `trip.changed {tripId}` per office.

## Notes for the .NET team

1. **Driver-first**: there is no vehicle input anywhere. Vehicle, capacity and seat map derive from the
   driver's active assignment at creation time and are then snapshotted on the trip.
2. `status` is written **only** by `update_trip_status`. Any other write path is refused by trigger. Port the
   state machine + side effects verbatim (`../README.md` §5 lists the vocabulary).
3. Creation is currently RPC + N client-side pricing upserts. Make it one transaction; a trip with no
   pricing is unpublishable, so partial failure today leaves a silent draft.
4. Seat/passenger edits (T9/T10) are raw table writes with no invariants and do not touch bookings. Decide
   the rules before porting them one-for-one.
5. `trip_events` is both an audit log (server) and a free-text log (client). Make it server-only.
6. Overlap protection is a DB exclusion constraint — replicate with a transactional check or a DB constraint.
