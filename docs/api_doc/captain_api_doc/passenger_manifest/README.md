# Captain · Passenger Manifest

Who paid to be on the vehicle, and the one verb the captain has on it: **set a rider's boarding status**.
Boarding a rider (or putting them back to pending) is the captain's own observation and is a **direct
row update**; marking a rider absent removes them from a station's boarding requirement and therefore
goes through `captain_resolve_no_show` with a reason. Live via a Supabase row stream.

## Overview

| Layer | Files (relative to `lib/apps/captain/features/passenger_manifest/`) |
|---|---|
| Screen | `presentation/pages/passenger_list_page.dart` (route `CaptainRoutes.passengerManifest = /captain/trip/passengers`, argument `tripId`; opened from Home cards, quick actions and the trip screen's tools) |
| Cubit | `PassengerManifestCubit` (`presentation/cubit/passenger_manifest_cubit.dart` — `load(tripId)` :36-49, `search()`, `toggleStatusFilter()`, `updateStatus(...)` :65-99 optimistic with rollback) |
| Use cases | `GetTripPassengersUseCase`, `WatchTripPassengersUseCase`, `UpdatePassengerStatusUseCase` (also injected into `CaptainTripMapCubit`) |
| Repo | `data/repositories/passenger_manifest_repository_impl.dart` |
| **Datasource** | `data/datasources/passenger_manifest_datasource.dart` |
| Model / entity | `data/models/passenger_model.dart` → `domain/entities/passenger.dart` (`Passenger`, `PassengerBoardingStatus {pending, boarded, absent, cancelled}`) |
| Shared | `NoShowReason` + `stationFailureFrom` from `../station_progress/domain/entities/` |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| M1 | Manifest (+ stop times) | `GET trip_passengers?trip_id=eq.` then `GET trip_route_points?trip_id=eq.` | session (captain) | `GET /api/v1/captain/trips/{tripId}/passengers` |
| M2 | Live manifest | Realtime `.stream(primaryKey:['id'])` on `trip_passengers` filtered `trip_id` | session | SignalR `manifest.changed` on the trip group |
| M3a | Board / un-board a rider | `PATCH trip_passengers?id=eq. {status}` | session | `PATCH /api/v1/captain/trip-passengers/{id} { status }` |
| M3b | Mark absent (no-show) | `POST rpc/captain_resolve_no_show` | session | `POST /api/v1/captain/trip-passengers/{id}/no-show` (see `../station_progress/` S4) |

---

## M1 — `getTripPassengers(tripId)` (`passenger_manifest_datasource.dart:22-73`)

Two sequential reads:

```
GET /rest/v1/trip_passengers?select=*&trip_id=eq.<tripId>&order=created_at.asc
→ 200 [ { "id":"…","trip_id":"…","booking_id":"…","customer_id":"<auth uid|null>",
          "passenger_name":"…","phone":"…","seat_id":"…","seat_label":"A3",
          "pickup_point_id":"<route_stations.id|null>","pickup_point_name":"رمسيس",
          "dropoff_point_id":"…","dropoff_point_name":"…","payment_method":"…",
          "status":"reserved","boarded_at":null,"boarding_source":null,
          "no_show_reason":null,"resolution_note":null,"resolved_by":null,"resolved_at":null,
          "created_at":"…","updated_at":"…" }, … ]

GET /rest/v1/trip_route_points?select=route_point_id,point_name,arrival_offset,departure_offset&trip_id=eq.<tripId>
→ 200 [ { "route_point_id":"…","point_name":"رمسيس","arrival_offset":"00:00","departure_offset":"00:05" }, … ]
```

**App reads** (per rider): `id`, `passenger_name` (fallback `'Unknown'`), `seat_label`,
`pickup_point_name`, `dropoff_point_name`, `phone`, `status`; plus `pickupTime` = the stop's
`departure_offset` if non-empty else `arrival_offset`, looked up **by `pickup_point_name`** (:33-39) —
a name join, `SUPABASE-SPECIFIC` workaround; the .NET response should just carry `pickupTime`.

Status mapping (:42-59): `confirmed|boarded` ⇒ `boarded`; `no_show|absent` ⇒ `absent`; `cancelled` ⇒
`cancelled`; `reserved` and anything else ⇒ `pending`. (`completed` therefore renders as **pending**
after the trip finishes — a known display quirk; the counts in `../assigned_trips/` treat `completed`
as boarded. `NEEDS BACKEND DECISION`: return `completed` as `boarded`.)

`RLS`: `trip_passengers_captain_read` (own trips, `20260728120000_captain_authority.sql:133-137`),
`trip_route_points_captain_read`.

**Proposed .NET:** `GET /api/v1/captain/trips/{tripId}/passengers` →
`[ { id, name, seatLabel, pickupPoint, destination, pickupTime: "HH:MM", phone, status: pending|boarded|absent|cancelled } ]`.

---

## M2 — `watchPassengerUpdates(tripId)` (`passenger_manifest_datasource.dart:14-20`)

```
Realtime row stream: table=trip_passengers, primaryKey=[id], filter trip_id=eq.<tripId>
```
`SUPABASE-SPECIFIC`: `.stream()` performs an initial select **and** subscribes to CDC, emitting the
whole row set on every change. The cubit ignores the rows and re-runs M1 (`_reload` :107-116) —
so the .NET equivalent is a plain change signal.

---

## M3a — Board / un-board: `updatePassengerStatus(...)` (`passenger_manifest_datasource.dart:113-116`)

Call chain: tile action → `PassengerManifestCubit.updateStatus(tripPassengerId, status)` (optimistic
update, rollback + `PassengerManifestUpdateError` on failure) → `UpdatePassengerStatusUseCase` → repo →
datasource. For `status ∈ {boarded, pending}`:

```
PATCH /rest/v1/trip_passengers?id=eq.<tripPassengerId>
{ "status": "confirmed" }        ← boarded
{ "status": "reserved" }         ← back to pending
→ 204 (no representation requested)
→ 4xx PostgrestException          ← RLS refusal or trigger (raw message surfaced)
```

(`_statusToString` :119-124 also maps `cancelled` → `'cancelled'`, but no UI path sends it and RLS would
refuse it.)

`RLS` `trip_passengers_captain_board` (`20260811090000_station_boarding_authority.sql:785-808` — the latest
definition): row must belong to the caller's trip and currently be **not** `cancelled|completed`; the
new `status` must be **`reserved` or `confirmed`**. `no_show` was removed from this policy on purpose.
No captain INSERT or DELETE policy exists.

`BUSINESS RULE` — column guard trigger `enforce_captain_manifest_scope` (`20260728120000:164-196`): a
captain-context update that changes anything other than `status` (name, phone, seat, booking,
customer, trip, pickup/dropoff point, payment method) raises `captain_may_only_set_passenger_status`.

Side effects: `trg_trip_passengers_station_counts` recounts the station board
(`boarded_count`/`pending_count`), which is what unlocks `captain_depart_station`. Note the direct
write does **not** stamp `boarded_at`/`boarding_source` — only `passenger_confirm_boarding` (rider
side) does. `NEEDS BACKEND DECISION`: stamp `boarded_at = now(), boarding_source = 'captain'` in the
.NET endpoint.

**Proposed .NET:** `PATCH /api/v1/captain/trip-passengers/{id} { status: "boarded" | "pending" }` →
`200 { id, status, boardedAt }`; `403` not the caller's trip; `409 { code: passenger_terminal }` when
the row is `cancelled|completed`.

---

## M3b — Absent: same method, `status == absent` (`passenger_manifest_datasource.dart:91-111`)

Requires `noShowReason` (else a local `StationActionException(noShowNoteRequired)` before any call),
then `POST rpc/captain_resolve_no_show { p_trip_passenger_id, p_reason, p_note }` — contract, rules and
codes in `../station_progress/README.md` S4. Errors are typed via `stationFailureFrom` and rendered
with `StationLabels.failure` (`passenger_manifest_cubit.dart:103-105`).

---

## Notifications fired on manifest changes (server-side, for completeness)

`trg_trip_passenger_insert` / `trg_trip_passenger_delete` (`20260706140000_notification_event_engine.sql:230-282`)
push `راكب جديد على رحلتك` / `ألغى أحد الركاب حجزه` to the captain's `notifications` (target `captain`)
whenever a manifest row is inserted (payment approved) or deleted. Status updates by the captain fire
nothing.

## Notes for the .NET team

1. Two write paths, on purpose: **boarding is an observation (direct), absence is a decision (RPC with
   reason + audit event)**. Keep them distinct; do not add a "skip" that bypasses the reason.
2. The captain may never create or delete manifest rows, nor edit anything but `status`; `cancelled`
   and `completed` are terminal for them (`completed` is written by trip completion).
3. `pickup_point_id` can be null on older trips — every station↔rider join in the system falls back to
   the trimmed point name. Backfill it in the port and drop the name fallback.
4. The manifest screen is also the fallback for a rider whose own "I'm on board" tap failed
   (`vehicle_not_at_station`, etc. — client side); the captain's direct write has no station check.
