# Captain · Station Progress (the station board)

The station is the unit of trip progress. One `trip_station_progress` row per stop per trip carries
the planned and actual arrival/departure, the configured dwell, and a boarding tally denormalised from
the manifest. The captain **arrives** at the next stop, resolves anyone still pending (boards them on the
manifest, or records a **no-show with a reason**), and **departs** — a transition the **database** decides.
The app renders the same gate so the button is honestly disabled, but the refusal is what settles it.

## Overview

| Layer | Files (relative to `lib/apps/captain/features/station_progress/`) |
|---|---|
| UI | `presentation/widgets/station_progress_section.dart` (embedded in the trip screen while live — `trip_execution_page.dart:130-133`), `current_station_panel.dart`, `station_timeline.dart`, `station_boarding_tally.dart`, `station_primary_action.dart` (arrive / depart), `station_no_show_sheet.dart` + `no_show_reason_sheet.dart`; labels in `presentation/formatters/station_labels.dart` |
| Cubit | `StationProgressCubit` (`presentation/cubit/station_progress_cubit.dart` — `watch(tripId)` :47-64, `arriveAtCurrentStation()` :66, `departCurrentStation()` :69, `resolveNoShow(...)` :75-81, `passengersAt(station)` :83-95; one in-flight action at a time `_run` :106-126) |
| Use cases | `WatchStationBoardUseCase`, `ArriveAtStationUseCase`, `DepartStationUseCase`, `ResolveNoShowUseCase`, `GetStationPassengersUseCase` |
| Repo | `data/repositories/station_progress_repository_impl.dart` |
| **Datasource** | `data/datasources/station_progress_datasource.dart` |
| Entities | `domain/entities/station_action_failure.dart` (`StationActionFailure`, `StationActionException{failure, detail}`, `stationFailureFrom`), `station_passenger.dart` (`StationPassenger`, `StationPassengerStatus`, `NoShowReason`) |
| Shared (both apps) | `lib/core/tracking/progress/station_board.dart` (`StationBoard`, `TripStation`, `StationGate`, `gateAt(now)`), `station_board_mapper.dart` (`columns`, `fromRows`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| S1 | Board (initial + live) | `GET trip_station_progress?…&trip_id=eq.&order=sequence.asc` + Realtime `captain_station_progress:<tripId>` | session (captain) | `GET /api/v1/captain/trips/{tripId}/station-board` + SignalR `station-board.changed` |
| S2 | Arrive at next station | `POST rpc/captain_arrive_station` | session | `POST /api/v1/captain/trips/{tripId}/stations/arrive` |
| S3 | Depart current station | `POST rpc/captain_depart_station` | session | `POST /api/v1/captain/trips/{tripId}/stations/depart` |
| S4 | Record a no-show | `POST rpc/captain_resolve_no_show` | session | `POST /api/v1/captain/trip-passengers/{id}/no-show` |
| S5 | Riders due at one station | `GET trip_passengers?…&pickup_point_id=eq.` (or `pickup_point_name=eq.`) | session | `GET /api/v1/captain/trips/{tripId}/stations/{routePointId}/passengers` |

---

## S1 — The board: `fetchBoard()` (`station_progress_datasource.dart:71-81`) + `watchBoard()` (:28-69)

```
GET /rest/v1/trip_station_progress
  ?select=id,trip_id,route_point_id,point_name,sequence,expected_arrival_at,expected_departure_at,min_dwell_seconds,actual_arrival_at,actual_departure_at,status,expected_boardings,boarded_count,pending_count,no_show_count
  &trip_id=eq.<tripId>&order=sequence.asc
→ 200 [ { "id":"…","trip_id":"…","route_point_id":"<route_stations.id|null>","point_name":"رمسيس","sequence":1,
          "expected_arrival_at":"2026-09-15T05:30:00+00:00","expected_departure_at":"…","min_dwell_seconds":180,
          "actual_arrival_at":null,"actual_departure_at":null,"status":"arriving",
          "expected_boardings":4,"boarded_count":0,"pending_count":4,"no_show_count":0 }, … ]
→ 200 []      ← board not built yet (trip not boarding) — the section shows nothing
```

The select list **is** the contract (`StationBoardMapper.columns`, `station_board_mapper.dart:41-45`);
timestamps are localised once in the mapper; numeric fields tolerate strings.

Realtime:
```
channel: captain_station_progress:<tripId>
postgres_changes: table=trip_station_progress event=* filter=trip_id=eq.<tripId>
```
Any event ⇒ re-fetch after 200 ms (`schedule` :42-45). A stream error keeps the last board on screen.
`SUPABASE-SPECIFIC`: the table has `replica identity full` so UPDATE events carry the counts; the app
ignores the payload anyway and re-reads.

`RLS` (`20260811090000_station_boarding_authority.sql:942-995`): select only, via
`can_read_trip_stations(trip_id)` = platform admin **or** operating office **or** assigned captain
**or** a rider with a booking in `confirmed|boarded|completed`. **There is no INSERT/UPDATE/DELETE
policy and no grant** — the RPCs below are the only writers.

Derived on the app side, mirrored from SQL (`StationBoard.gateAt(now)`, `station_board.dart:339-360`):
`current` = row with `actual_arrival_at NOT NULL AND actual_departure_at IS NULL`; `canProceed =
pending_count == 0`; `earliestDeparture = max(actual_arrival_at + min_dwell, expected_departure_at)`
is **informational** (`aheadOfSchedule` ⇒ confirm dialog, never a block — since `20260819120000`).

**Board lifecycle** (`BUSINESS RULE`, `ensure_trip_station_progress` :277-420): seeded from
`trip_route_points` when the trip enters `boarding` (trigger) — and lazily by every RPC below —
with `sequence` = `row_number() over (order by point_order, created_at, id)`, first row `arriving`,
the rest `upcoming`; `expected_*_at = (trip_date + departure_time) at office tz + parse_route_offset(offset)`;
`min_dwell_seconds = departure_offset − arrival_offset` (≥ 0). Only for trips in `boarding|in_progress`.
Trips that were already running when the feature shipped are backfilled from `'وصول محطة'` events.

**Proposed .NET:** `GET /api/v1/captain/trips/{tripId}/station-board` → `{ stations: [ …same 15 fields, camelCase… ] }`;
SignalR `station-board.changed` on the trip group.

---

## S2 — Arrive: `arriveAtStation(tripId)` (`station_progress_datasource.dart:83-84`)

```
POST /rest/v1/rpc/captain_arrive_station
{ "p_trip_id": "<uuid>" }
→ 200 { "success": true, "unchanged": false, "station_id": "…", "sequence": 2, "point_name": "…" }
→ 200 { "success": true, "unchanged": true,  "station_id": "…", "sequence": 2, "point_name": "…" }  ← already standing at a station
→ 400 { "message": "…no_pending_station…" | "…trip_not_running:<status>…" | "…not_your_trip…" | "…not_a_captain…" }
```

**App reads:** nothing from the body (the board refresh arrives via realtime).

`BUSINESS RULE` (`20260811090000:526-593`):
1. `assert_captain_running_trip` (:489-523): `not_a_captain`; trip row locked `FOR UPDATE`;
   `trip_not_found`; `not_your_trip` unless `driver_id = current_driver_id()`;
   `trip_not_running:<status>` unless `boarding|in_progress`.
2. `ensure_trip_station_progress` (build/heal the board).
3. **Idempotent**: if a station is currently arrived-and-not-departed ⇒ `{unchanged:true}` — a double
   tap or retry can never skip a station.
4. Else the first row with `actual_departure_at IS NULL` ordered by `sequence` (locked) —
   `no_pending_station` when none.
5. `actual_arrival_at = now()`, `status = 'waiting_for_passengers'`, `arrived_by = auth.uid()`.
6. Insert `trip_events (title 'وصول محطة', description 'وصلت الرحلة إلى محطة: <name>', done=true)` —
   the same marker all three apps count. **The app never writes this event itself any more.**

**No station argument on purpose** — which stop was reached is not the app's to assert.

**Proposed .NET:** `POST /api/v1/captain/trips/{tripId}/stations/arrive` → `200 { unchanged, stationId, sequence, pointName }`;
`409 { code: no_pending_station | trip_not_running }`, `403 not_your_trip`.

---

## S3 — Depart: `departStation(tripId)` (`station_progress_datasource.dart:86-87`)

```
POST /rest/v1/rpc/captain_depart_station
{ "p_trip_id": "<uuid>" }
→ 200 { "success": true, "station_id": "…", "sequence": 1, "point_name": "…",
        "departed_at": "…", "next_sequence": 2 | null }
→ 400 { "message": "…no_current_station…" | "…passengers_not_boarded:3…" | "…trip_not_running:…" | "…not_your_trip…" }
```

`BUSINESS RULE` (`20260819120000_station_departure_gated_on_boarding_only.sql:41-115` — supersedes the
two-condition version in `20260811090000:597-680`):
1. `assert_captain_running_trip` + `ensure_trip_station_progress`.
2. Current station = arrived-and-not-departed (locked); none ⇒ `no_current_station` (a retry of a
   departure that already succeeded is **refused**, never silently applied to the next stop).
3. `recount_trip_stations(trip)` under the lock (closes the race with a rider confirming boarding at
   the same instant), then **the gate: `pending_count > 0 ⇒ passengers_not_boarded:<n>`**.
   The published departure time and dwell are **not** a gate any more — nobody can join a station's
   manifest after the trip leaves `open_for_booking`, so a fully-resolved stop has nobody left to wait for.
4. `actual_departure_at = now()`, `status='departed'`, `departed_by = auth.uid()`; the next `upcoming`
   row becomes `arriving`.
5. **Leaving the first station while the trip is `boarding` calls `captain_update_trip_status(trip,'in_progress')`**
   — the trip departs through the same allowlisted wrapper (`../trip_execution/` E2).

`pending_count` counts manifest rows with `status='reserved'` whose `pickup_point_id = route_point_id`
(fallback: trimmed `pickup_point_name = point_name`) — `recount_trip_stations` :217-252. Boarded =
`confirmed|completed`; expected = `<> cancelled`.

**Proposed .NET:** `POST /api/v1/captain/trips/{tripId}/stations/depart` → `200 { stationId, sequence, pointName, departedAt, nextSequence }`;
`409 { code: passengers_not_boarded, pendingCount }`, `409 no_current_station`, `403 not_your_trip`.

---

## S4 — No-show: `resolveNoShow(...)` (`station_progress_datasource.dart:89-97`)

Also called from the manifest screen (`../passenger_manifest/` M3b) with the same parameters.

```
POST /rest/v1/rpc/captain_resolve_no_show
{ "p_trip_passenger_id": "<uuid>",
  "p_reason": "did_not_arrive" | "cancelled_by_passenger" | "passenger_requested" | "other",
  "p_note": "…" | null }
→ 200 { "success": true, "unchanged": false, "passenger_id": "…", "reason": "did_not_arrive" }
→ 200 { "success": true, "unchanged": true,  "passenger_id": "…" }     ← already no_show
→ 400 { "message": "…invalid_no_show_reason:x…" | "…no_show_note_required…" | "…passenger_not_found…" | "…passenger_not_pending:<status>…" | trip codes }
```

`BUSINESS RULE` (`20260811090000:698-780`): reason must be one of the four; **`other` requires a
non-empty note**; manifest row locked; the trip must be the caller's and running
(`assert_captain_running_trip`); already `no_show` ⇒ idempotent; only a `reserved` rider can become a
no-show (`passenger_not_pending:<status>`); writes `status='no_show', no_show_reason, resolution_note,
resolved_by=auth.uid(), resolved_at`; inserts a `trip_events` row titled `راكب لم يصعد` with the
reason in Arabic; recounts the board. **The captain has no direct write to `no_show`** — the RLS
policy `trip_passengers_captain_board` admits only `reserved|confirmed` (`:785-808`), so this RPC is the
only path.

**Proposed .NET:** `POST /api/v1/captain/trip-passengers/{id}/no-show { reason, note? }` →
`200 { unchanged }`; `422 { code: invalid_no_show_reason | no_show_note_required }`,
`409 { code: passenger_not_pending, status }`, `404 passenger_not_found`.

---

## S5 — Riders at a station: `passengersAt(...)` (`station_progress_datasource.dart:104-130`)

Called when the captain opens the pending list for the current station (`StationProgressCubit.passengersAt(station)`).

```
GET /rest/v1/trip_passengers?select=id,passenger_name,seat_label,phone,status
  &trip_id=eq.<tripId>&pickup_point_id=eq.<station.route_point_id>&order=seat_label.asc
— or, when the station has no route_point_id —
GET /rest/v1/trip_passengers?select=…&trip_id=eq.<tripId>&pickup_point_name=eq.<station.point_name>&order=seat_label.asc
→ 200 [ { "id":"…","passenger_name":"…","seat_label":"A3","phone":"…","status":"reserved" }, … ]
```

**App reads:** `id`, `passenger_name`, `seat_label`, `phone` (tap-to-call), `status` →
`StationPassengerStatus` (`confirmed|completed` ⇒ boarded, `no_show`, `cancelled`, else pending).
Same two-step match as `recount_trip_stations`. Errors ⇒ `[]`. `RLS`: `trip_passengers_captain_read`.

**Proposed .NET:** `GET /api/v1/captain/trips/{tripId}/stations/{routePointId}/passengers` (or
`?pointName=` for legacy rows) → `[ { id, name, seatLabel, phone, status } ]`.

---

## Error codes → app copy (`station_action_failure.dart:81-91`, `station_labels.dart`)

| Code (prefix match, `:detail` kept) | `StationActionFailure` |
|---|---|
| `passengers_not_boarded:<n>` | `passengersNotBoarded` (`pendingCount = n`) |
| `departure_time_not_reached:<HH:mm>` | `departureTimeNotReached` (legacy — no longer raised since `20260819120000`; mapping kept) |
| `no_current_station` | `noCurrentStation` |
| `no_pending_station` | `noPendingStation` |
| `no_show_note_required` | `noShowNoteRequired` |
| `passenger_not_pending:<status>` | `passengerNotPending` |
| `trip_not_running:<status>` | `tripNotRunning` |
| `not_your_trip`, `not_a_captain` | `notYourTrip` |
| anything else | `unknown` |

Codes must arrive **as a prefix of the error message / `code` field with the detail after a colon**.

## Notes for the .NET team

1. The board is a **server-owned read model** with denormalised tallies maintained by trigger
   (`trg_trip_passengers_station_counts`). Keep the tallies on the row: the rider can only read their
   own manifest row, so counts cannot be computed client-side, and the captain screen needs one
   subscription, not two.
2. Every write is row-locked on the trip; two concurrent departs must never advance two stations.
3. `route_point_id` on the board is `route_stations.id` (the namespace `trip_passengers.pickup_point_id`
   uses), while `trip_route_point_id` is the trip-scoped stop id — two ids, two namespaces, both needed.
4. The app's `StationGate` must keep answering exactly as the server: boarding requirement only;
   schedule is advisory.
