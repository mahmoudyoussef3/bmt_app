# Captain · Trip Execution (start boarding → depart → complete, live snapshot)

The trip screen. Three lifecycle buttons that all go through **one server-side state machine**, a
live snapshot (status / headcount / arrived stations / last GPS fix) re-read on every realtime event,
the station board (`../station_progress/`) embedded while the trip is live, and the GPS publisher
(`../live_location/`) started/stopped from the trip's stage. There is deliberately no map here.

## Overview

| Layer | Files (relative to `lib/apps/captain/features/trip_execution/`) |
|---|---|
| Screen | `presentation/pages/trip_execution_page.dart` (route `CaptainRoutes.tripExecution = /captain/trip`, argument `AssignedTrip`); widgets `trip_execution_primary_action.dart` (board :52 / start :59 / complete :88), `trip_execution_action_bar.dart` (complete :96), `trip_execution_tools.dart` (manifest / status-update / incident links), `trip_execution_sos_button.dart` (incident with `emergency` preselected) |
| Cubits | `TripExecutionCubit` (`presentation/cubit/trip_execution_cubit.dart` — `watch(...)` :42-59, `board()` :61, `start()` :74, `complete()` :87, `markStationArrived()` :100); plus `StationProgressCubit` (`../station_progress/`) mounted in the same `MultiBlocProvider` (`trip_execution_page.dart:40-56`) |
| Use cases | `StartBoardingUseCase`, `StartTripUseCase`, `CompleteTripUseCase`, `WatchTripExecutionSnapshotUseCase`, `MarkStationArrivedUseCase` |
| Repo | `data/repositories/trip_execution_repository_impl.dart` |
| **Datasource** | `data/datasources/trip_execution_datasource.dart` |
| Entities | `domain/entities/trip_execution_state.dart` (`TripExecutionStatus`, `TripExecutionSnapshot {status, passengerCount, boardedCount, arrivedStationsCount, lastLocation?}`, `TripLastLocationFix`) |
| GPS coupling | `TripLocationAutoShare(enabled: stage.isLive)` (`trip_execution_page.dart:100-104, 125-128`) — publishing follows the **trip stage**, not any button |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| E1 | Start boarding | `POST rpc/captain_update_trip_status {p_new_status:'boarding'}` | session (captain) | `POST /api/v1/captain/trips/{tripId}/status { status:"boarding" }` |
| E2 | Start trip (depart) | same RPC, `in_progress` | session | same endpoint |
| E3 | Complete trip | same RPC, `completed` | session | same endpoint |
| E4 | Snapshot (initial + on every change) | `GET operation_trips?select=status,trip_passengers(status),trip_events(title)&id=eq.` + `GET trip_live_locations … limit=1` | session | `GET /api/v1/captain/trips/{tripId}/snapshot` |
| E5 | Change signal | Realtime `captain_trip_execution:<tripId>` (4 sources) | session | SignalR per-trip group |
| E6 | Station arrived (shortcut) | `POST rpc/captain_arrive_station` | session | `POST /api/v1/captain/trips/{tripId}/stations/arrive` (documented in `../station_progress/` S2) |

---

## E1–E3 — Lifecycle transitions: `_transitionStatus()` (`trip_execution_datasource.dart:196-216`)

Call chain: button → `TripExecutionCubit.board/start/complete(tripId)` → use case → repo →
`startBoarding` (:15) / `startTrip` (:23) / `completeTrip` (:31) → `_transitionStatus(tripId, status)`.
The cubit emits `TripExecutionLoading`, then on success overwrites `snapshot.status` locally (the
realtime refetch confirms it), on failure `TripExecutionError(message)` shown inline.

```
POST /rest/v1/rpc/captain_update_trip_status
{ "p_trip_id": "<uuid>", "p_new_status": "boarding" | "in_progress" | "completed" }
      (p_reason is never sent — PostgREST binds the 3-arg function by parameter names)

→ 200 { "success": true, "unchanged": false, "trip_id": "…",
        "previous_status": "open_for_booking", "new_status": "boarding",
        "bookings_affected": 0, "passengers_affected": 0, "seats_released": 0, "refund_owed_count": 0,
        "actual_start_time": "…", "actual_end_time": null }
→ 200 { "success": true, "unchanged": true, … }     ← already in that status (retry / double-tap)
→ 400 { "message": "…<code>…" }
```

**App reads:** nothing from the body — success is the absence of an error.

**Error codes the app maps** (:203-214): `invalid_transition` ⇒ *"حالة الرحلة لا تسمح بهذا الانتقال"*;
`trip_not_found` ⇒ *"الرحلة غير موجودة"*; `not_your_trip` | `not_a_captain` |
`status_not_allowed_for_captain` ⇒ *"غير مصرح لك بتعديل هذه الرحلة"*; anything else rethrown raw.

`BUSINESS RULE` — the wrapper (`captain_update_trip_status`, `20260727160000_trip_lifecycle_authority.sql:572-604`):
1. `not_a_captain` when `current_driver_id()` is null.
2. **Allowlist**: `p_new_status ∈ {boarding, in_progress, completed}` else `status_not_allowed_for_captain`
   (cancellation and publishing belong to the office — `20260723090000_captain_status_transition_allowlist.sql`).
3. `trip_not_found`; `not_your_trip` when `operation_trips.driver_id <> current_driver_id()`.
4. Delegates to `update_trip_status(p_trip_id, p_new_status, p_reason)`.

`BUSINESS RULE` — the state machine (`update_trip_status`, same file :125-380), which the dashboard
shares. Port it once, not per app:
1. Row lock (`FOR UPDATE`); `trip_not_found`.
2. **Idempotent**: `current = new` ⇒ `{unchanged:true}`, no side effects, no notification.
3. Legal edges: `scheduled→open_for_booking|cancelled`, `open_for_booking→boarding|cancelled`,
   `boarding→in_progress|cancelled`, `in_progress→completed|cancelled`; else
   `invalid_transition: Cannot transition trip from X to Y`. Note **`open_for_booking → in_progress` is
   not an edge** — the captain must board first. There is no `scheduled → boarding`: an unpublished
   trip cannot be started (the app shows it as `awaitingRelease`).
4. The one permitted `status` write, guarded by the transaction-local flag `bmt.trip_transition`
   which `trg_enforce_trip_write_authority` (:378-486) checks — **any direct `PATCH operation_trips`
   from the app raises `trip_status_direct_update_forbidden`**, and a captain writing any other
   authored column raises `trip_direct_write_forbidden`.
5. Stamps: `actual_start_time = now()` on entering **`boarding`** (not `in_progress`);
   `actual_end_time = now()` on `completed`.
6. Side effects on `completed`: `operation_bookings.status confirmed→completed`,
   `trip_passengers.status confirmed→completed`, and **every other non-terminal passenger → `no_show`**
   ("anyone the captain never boarded did not travel").
7. Audit: one `trip_events` row (`event_code` `boarding_started | trip_departed | trip_completed`,
   Arabic titles `بدء التجميع | انطلاق الرحلة | اكتمال الرحلة`).
8. Trigger `trg_seed_trip_station_progress` builds the station board on entry to `boarding`
   (`20260811090000:425-442`); trigger `on_operation_trip_change` (`20260727160000:731-800`) pushes
   notifications: riders (`بدأ صعود الركاب` / `انطلقت رحلتك` / `اكتملت رحلتك`) and the captain
   (`بدأ صعود الركاب` / `بدأت الرحلة`) — see `../notifications/`.

Also reachable **without the button**: leaving the first station via `captain_depart_station`
performs `boarding → in_progress` itself (`../station_progress/` S3). The "start" button and the
station gate are two doors to the same transition.

**Proposed .NET:** `POST /api/v1/captain/trips/{tripId}/status { status }` → `200 { unchanged, previousStatus, newStatus, actualStartTime, actualEndTime }`;
`403 { code: not_your_trip | not_a_captain | status_not_allowed_for_captain }`, `404 trip_not_found`,
`409 { code: invalid_transition, from, to }`.

---

## E4 — Snapshot: `_fetchSnapshot()` (`trip_execution_datasource.dart:106-141`) + `_fetchLastLocation()` (:143-163)

Run once on subscribe and after every E5 event (debounced 250 ms); errors are swallowed so the
screen never breaks mid-trip. The initial snapshot before the first fetch is built from the
`AssignedTrip` argument (`trip_execution_page.dart:58-72`).

```
GET /rest/v1/operation_trips?select=status,trip_passengers(status),trip_events(title)&id=eq.<tripId>
    Accept: application/vnd.pgrst.object+json          (.single())
→ 200 { "status": "in_progress", "trip_passengers": [ {"status":"confirmed"}, … ], "trip_events": [ {"title":"وصول محطة"}, … ] }

GET /rest/v1/trip_live_locations?select=latitude,longitude,recorded_at&trip_id=eq.<tripId>&order=recorded_at.desc&limit=1
    (.maybeSingle())
→ 200 { "latitude": 30.05, "longitude": 31.26, "recorded_at": "2026-09-15T07:42:11+00:00" } | null
```

**App reads:** `status` (unknown ⇒ `scheduled`); `passengerCount` = manifest length;
`boardedCount` = `confirmed|completed`; `arrivedStationsCount` = count of titles `== 'وصول محطة'`
clamped to `routePointCount` (passed in from `trip.stops.length`); `lastLocation` = the fix or null
(`recorded_at` → local). `RLS`: `trips_captain_read`, `trip_passengers_captain_read`,
`trip_events_captain_read`; `trip_live_locations_read` = `can_read_trip_fixes(trip_id) AND trip_tracking_licensed(trip_id)`
(the captain is always admitted by the driver arm; the licence arm can hide the captain's **own** last
fix when live tracking is unlicensed — harmless, the card just shows no fix).

**Proposed .NET:** `GET /api/v1/captain/trips/{tripId}/snapshot` →
`{ status, passengerCount, boardedCount, arrivedStationsCount, lastLocation: { latitude, longitude, recordedAt } | null }`.

---

## E5 — Realtime: `watchSnapshot()` (`trip_execution_datasource.dart:39-104`)

```
channel: captain_trip_execution:<tripId>
postgres_changes:
  operation_trips      event=UPDATE  filter=id=eq.<tripId>
  trip_passengers      event=*       (unfiltered — RLS scopes to own trips)
  trip_events          event=*       (unfiltered)
  trip_live_locations  event=INSERT  filter=trip_id=eq.<tripId>
```
Any event ⇒ `scheduleEmit()` ⇒ E4 after 250 ms. Unsubscribed when the cubit closes.

**Proposed .NET:** SignalR group `trip:<tripId>` with `trip.changed` (status/manifest/events) and
`trip.position` (the captain's own fix echo — optional; the app only uses it to refresh the "last sent"
card, which `../live_location/` already knows locally).

---

## E6 — "Arrived at station" shortcut: `markStationArrived()` (`trip_execution_datasource.dart:175-194`)

Same RPC as `../station_progress/` S2 (`captain_arrive_station {p_trip_id}` — **no station argument;
the server picks the next un-departed stop**). Exposed through `TripExecutionCubit.markStationArrived`
for the trip-map cubit (`../trip_map/`); the trip screen itself uses `StationProgressCubit`.
Error copy here (:182-192): `no_pending_station` ⇒ *"لا توجد محطات متبقية في هذه الرحلة"*;
`trip_not_running` ⇒ *"حالة الرحلة لا تسمح بتسجيل الوصول"*; `not_your_trip|not_a_captain` ⇒
*"غير مصرح لك بتعديل هذه الرحلة"*.

---

## Screen-level rules the backend should know

* **GPS publishing = `stage.isLive`** (`boarding` or `underway`), started by `TripLocationAutoShare`
  when the page builds and stopped when the stage leaves live or the page is disposed — but the
  publisher is an app-lifetime singleton, so backing out of the screen does **not** stop it
  (`../live_location/`).
* The complete button is offered when `underway`; completion also cascades `no_show` on the manifest
  (rule 6) — the manifest screen will show those riders as absent afterwards.
* The station board section renders only while `stage.isLive`; before boarding the captain sees the
  static stops from `AssignedTrip.stops`.

## Notes for the .NET team

1. **One state machine, one endpoint family.** `update_trip_status` is shared with the dashboard; the
   captain wrapper only adds the ownership check and the three-status allowlist. Implement the machine
   once and expose `POST /captain/trips/{id}/status` and `POST /dashboard/trips/{id}/status` as two
   authorisation shells.
2. Idempotency (`unchanged:true`) is load-bearing: the app retries on flaky mobile links and must not
   see `invalid_transition` for a transition it already made.
3. The snapshot is a **read-model**; the app polls it only on change signals, never on a timer.
4. `arrivedStationsCount` via event-title counting is a legacy path; once the station board is the
   source of truth, derive it from `trip_station_progress` (rows with `actual_arrival_at IS NOT NULL`).
