# Captain · Assigned Trips (Home)

The captain's work board: every trip assigned to them that is still live, plus today's completed
ones — each with its stops, headcount, boarded count and how many stations have been reported arrived.
One realtime channel keeps it fresh; a local "seen" set drives the **new trip** badge.

## Overview

| Layer | Files (relative to `lib/apps/captain/features/assigned_trips/`) |
|---|---|
| Screen | `presentation/pages/assigned_trips_page.dart` (Home tab of `CaptainAppShell`; focus card = the running trip, else the first upcoming one — `domain/entities/captain_day_summary.dart:25`; "open" → `context.openTripExecution(trip)`, "manifest" → `openPassengerManifest(trip.id)`, quick actions → incident) |
| Cubit | `AssignedTripsCubit` (`presentation/cubit/assigned_trips_cubit.dart` — `load()` :34-47, `refresh()` :49, `acknowledgeNewTrips()` :76-85, realtime → `_backgroundRefresh` debounced 250 ms :91-100) |
| Use cases | `GetAssignedTripsUseCase`, `WatchAssignedTripsUseCase`, `GetSeenTripIdsUseCase`, `MarkTripsSeenUseCase` |
| Repos | `data/repositories/captain_trip_repository_impl.dart`, `seen_trips_repository_impl.dart` |
| **Datasources** | `data/datasources/captain_trip_remote_datasource.dart` (network), `seen_trips_local_datasource.dart` (SharedPreferences `captain_seen_trip_ids`, JSON list) |
| Model / entity | `data/models/assigned_trip_model.dart` → `domain/entities/assigned_trip.dart` (`AssignedTrip`, `AssignedTripStop`, `AssignedTripStatus`) |
| Shared | `lib/core/tracking/progress/arrival_events.dart` (`kStationArrivalEventTitle = 'وصول محطة'`, `countStationArrivalEvents`, `stationArrivalFloor`), `lib/apps/captain/core/trips/captain_trip_stage.dart` (stage + 30-min boarding window) |
| DI | `captain_di.dart:_registerAssignedTripsDependencies` — datasource takes `SupabaseClient` + `CaptainIdentityProvider` |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| T1 | Assigned trips list | `GET operation_trips?select=*,<5 embeds>&driver_id=eq.&or=(…)` | session (captain) | `GET /api/v1/captain/trips` |
| T2 | Live refresh signal | Realtime channel `captain_assigned_trips:<driverId>` (6 tables) | session | `NEEDS BACKEND DECISION` (SignalR per-driver group) |
| T3 | Seen-trip ids | SharedPreferences | — | **local only** |

---

## T1 — `getAssignedTrips()` (`captain_trip_remote_datasource.dart:60-85`)

Call chain: `CaptainAppShell` mounts `AssignedTripsCubit()..load()` (`captain_app_shell.dart:50-51`)
→ `GetAssignedTripsUseCase` → `CaptainTripRepositoryImpl.getAssignedTrips` → datasource. The driver
id is awaited from `CaptainIdentityProvider.driverId()` (see `../auth/` A4); null ⇒ `[]` without a request.

```
GET /rest/v1/operation_trips
  ?select=*,
          operation_routes(name,start_city,end_city),
          vehicles(vehicle_code,plate_number),
          trip_route_points(id,point_name,point_order,latitude,longitude),
          trip_passengers(id,status),
          trip_events(title)
  &driver_id=eq.<driverId>
  &or=(status.in.(scheduled,open_for_booking,boarding,in_progress),and(status.eq.completed,trip_date.eq.<today yyyy-MM-dd>))
  &order=trip_date.asc,departure_time.asc
```

`<today>` is the **device's** local date (`_isoDate(DateTime.now())` :87-92). `NEEDS BACKEND DECISION`:
compute "today" in the office timezone server-side (`office_wallet_policies.timezone`, default
`Africa/Cairo`) rather than trusting the phone's clock.

**Response fields the app reads** (`_mapTrip` :94-151):

| Wire | Read as | Rule |
|---|---|---|
| `id` | `id` | |
| `operation_routes.name` | `route` | fallback `"<start_city> - <end_city>"` joined with a **plain hyphen** (never an arrow — bidi trap, `project_rtl_direction_label_bidi`) |
| `vehicles.vehicle_code`, `.plate_number` | `vehicleNumber`, `plateNumber` | `''` when unassigned |
| `trip_date` + `departure_time` / `arrival_time` | `departureTime`, `expectedArrivalTime` (local `DateTime`) | `_dateTime` :153-171 — hour/minute outside range ⇒ 00:00; unparsable date ⇒ now |
| `trip_route_points[]` (sorted by `point_order` client-side) | `stops[] {id, name, latitude?, longitude?}` | `id` here is the **trip-scoped** `trip_route_points.id` |
| `trip_passengers[]` | `passengerCount` = length; `boardedCount` = count of `status IN (confirmed, completed)` | |
| `trip_events[].title` | `arrivedStationsCount` = `countStationArrivalEvents(titles)` clamped to `stops.length` | seeds the progress engine so GPS inference cannot regress below what the captain reported |
| `status` | `AssignedTripStatus` | `open_for_booking|boarding|in_progress|completed`; anything else ⇒ `scheduled` |

Everything else in `*` (pricing, capacity, notes, office_id, …) is fetched and ignored —
`SUPABASE-SPECIFIC` over-fetch; the .NET response should carry only the columns above.

`RLS`: `trips_captain_read` (`20260721090200_multi_office_rls.sql:145-148`) —
`office_id = captain_office_id() AND driver_id = current_driver_id()`; embeds pass through
`routes_captain_read` (own office), `vehicles_captain_read` (own office), `trip_route_points_captain_read`,
`trip_passengers_captain_read`, `trip_events_captain_read` (own trips). The `driver_id=eq.` filter is
therefore redundant server-side — keep the semantics: **the driver comes from the token**.

Derived on the app side (`AssignedTrip.stageAt(now)`, `captain_trip_stage.dart`): `scheduled` ⇒
`awaitingRelease`; `open_for_booking` ⇒ `awaitingWindow` until `departure_time − 30 min`, then
`readyToBoard`; `boarding` ⇒ `boarding`; `in_progress` ⇒ `underway`; `completed` ⇒ `finished`.
The 30-minute window is **app-only** — the server accepts `boarding` whenever the trip is
`open_for_booking` (`../trip_execution/`).

**Proposed .NET:** `GET /api/v1/captain/trips` →
```json
{ "items": [ { "id", "route", "vehicleCode", "plateNumber",
               "departureAt", "expectedArrivalAt",          // full timestamps, office tz
               "status": "scheduled|open_for_booking|boarding|in_progress|completed",
               "passengerCount", "boardedCount", "arrivedStationsCount",
               "stops": [ { "id", "name", "latitude", "longitude" } ] } ] }
```
`arrivedStationsCount` should come from `trip_station_progress` (rows with `actual_arrival_at`) once the
board exists, falling back to the event count for trips that never started.

---

## T2 — Realtime: `watchTripUpdates()` (`captain_trip_remote_datasource.dart:17-58`)

Subscribed once after the first successful load (`_subscribeToChanges` :91-100); every event
schedules a silent re-fetch of T1 after a 250 ms debounce (`isRefreshing` is not shown).

```
channel: captain_assigned_trips:<driverId>
postgres_changes:
  operation_trips      event=*  filter=driver_id=eq.<driverId>
  operation_bookings   event=*  (unfiltered)
  trip_passengers      event=*  (unfiltered)
  trip_events          event=*  (unfiltered)
  trip_route_points    event=*  (unfiltered)
  trip_seats           event=*  (unfiltered)
```

`SUPABASE-SPECIFIC`: the five unfiltered tables deliver only rows the captain may read (RLS is evaluated
per delivered row), so in practice the captain receives events for their own trips only. The payload
is discarded — only "something changed" is used. Also note `driverIdOrNull` is read synchronously here;
if the identity has not been resolved yet the stream is empty (no channel), which is why `load()` runs
T1 first.

**Proposed .NET:** SignalR group `captain:<driverId>` with one `trips.changed` event (fired on any change
to the driver's trips, their manifest, events, stops or seats). Payload optional.

---

## T3 — Seen trips (local)

`SeenTripsLocalDataSource` (`seen_trips_local_datasource.dart`): key `captain_seen_trip_ids`.
`newTripIds = ids(trips) − seen`; `acknowledgeNewTrips()` stores all current ids. The
"تم إسنادك لرحلة جديدة" push (see `../notifications/`) is the server-side counterpart; the badge itself
never touches the backend.

## Notes for the .NET team

1. `today` and the 30-min boarding window are both **device-clock** decisions today. Move "today" to
   the server; keep the window app-side (it is UX, and the server has its own gate).
2. `boardedCount` (`confirmed OR completed`) is the counting rule every captain screen uses — keep one
   definition.
3. The list is unbounded (a driver's future assignments could grow); add paging or a horizon
   (`trip_date <= today + N`) — `NEEDS BACKEND DECISION`.
4. `AssignedTrip` is passed **by value** to the trip screen (`Navigator` argument), so the execution
   screen starts from this snapshot and then subscribes on its own (`../trip_execution/`).
