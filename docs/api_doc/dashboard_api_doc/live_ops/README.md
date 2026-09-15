# Dashboard · Live Ops Center (العمليات المباشرة)

The live board: every `boarding` / `in_progress` trip of the office with its driver, vehicle,
booked-seat count, last GPS fix and a tracking-health verdict (LIVE / STALE / OFFLINE / UNKNOWN),
plus the captain incident queue (`driver_trip_reports`) with acknowledge / resolve / dismiss.
Positions arrive over **one realtime channel**; a catch-up poll runs only while the socket is
unhealthy. Built 2026-07-27, tracking rebuilt 2026-08-17.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/live_ops/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.liveOps` = `/live-ops`) |
| Cubit | `presentation/cubit/live_ops_cubit.dart` |
| Use cases | `domain/usecases/` (`GetLiveOpsSnapshotUseCase` — also used by Business Overview, `WatchFleetFixesUseCase`, `UpdateIncidentStatusUseCase`, …) |
| Repo | `data/repositories/live_ops_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_live_ops_datasource.dart` (`SupabaseLiveOpsDatasource implements LiveOpsDatasource`) |
| Models / entities | `data/models/live_trip_model.dart`, `live_fix_model.dart`, `trip_incident_model.dart`; `domain/entities/live_ops_snapshot.dart` (`TrackingHealth`, windows), `trip_incident.dart` (`IncidentType`, `IncidentStatus`), `fleet_feed.dart` |
| Shared | `lib/core/tracking/live_tracking_config.dart` (`staleAfter = 45 s`), `lib/core/tracking/link_health.dart` |
| Permission | `DashboardPermission.liveOps` (both roles); `liveOpsIncidentAction` (admin) — UI-only; feature key `live_ops_center` |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| L1 | Active trips | `GET operation_trips?select=…,seats:trip_seats(state)&office_id=eq.&status=in.(boarding,in_progress)&order=departure_time.asc` + L2 | `GET /api/v1/dashboard/live-ops/trips` |
| L2 | Latest fix per active trip | `POST rpc/dashboard_active_trip_fixes {p_office_id}` | `GET /api/v1/dashboard/live-ops/fixes` |
| L3 | Position stream | Realtime `INSERT` on `trip_live_locations` (unfiltered, RLS-scoped) | WebSocket `live-ops.fix` |
| L4 | Open incidents | `GET driver_trip_reports?select=…,trip:operation_trips!inner(…)&status=in.(pending,acknowledged)&order=created_at.desc` | `GET /api/v1/dashboard/live-ops/incidents` |
| L5 | Incident status | `PATCH driver_trip_reports {status, acknowledged_at/by | resolved_at/by, resolution_note}` | `PATCH /api/v1/dashboard/live-ops/incidents/{id}` |
| L6 | Board refresh signal | Realtime on `operation_trips` (`office_id=eq.`) + `driver_trip_reports` (all) | WebSocket `live-ops.changed` |

---

## L1 — Active trips: `fetchActiveTrips()` (`supabase_live_ops_datasource.dart:43`)

```
GET /rest/v1/operation_trips
  ?select=id,trip_date,departure_time,status,capacity,actual_start_time,route:operation_routes(name),
          driver:drivers(full_name,phone),vehicle:vehicles(plate_number,vehicle_code),seats:trip_seats(state)
  &office_id=eq.<office>&status=in.(boarding,in_progress)&order=departure_time.asc
```
→ `LiveTripModel { id, statusLabel, isInProgress, routeName, driverName ('غير معيّن'), driverPhone, vehicleLabel (plate ?? code),
tripDate, departureTime, capacity, bookedSeats (= count of seats with state ≠ available/blocked), lastFix, scheduledDeparture, actualStart }`
merged with L2 by trip id.

`BUSINESS RULE` (Dart, `live_ops_snapshot.dart`): `TrackingHealth` from fix age — `live` ≤ 45 s
(`kLiveTrackingConfig.staleAfter`, the captain publishes every 10 s + 30 s heartbeat), `stale` ≤ 4 min,
`offline` beyond that while running, `unknown` when no fix ever. `boardingGrace = 10 min` before a
boarding trip without fixes is flagged. Delay detection reads `actual_start_time` (stamped on `boarding`).

## L2 — Latest fixes: `_latestFixRows()` (line 100)

```
POST /rest/v1/rpc/dashboard_active_trip_fixes { "p_office_id": "<session office>" }
→ 200 [ { trip_id, latitude, longitude, heading, speed, accuracy, recorded_at } ]    (DISTINCT ON trip_id, newest)
```
`SECURITY DEFINER` (`20260727090000_live_ops_incident_lifecycle.sql:76`): returns rows only when
`p_office_id = current_office_id()` or the caller is a platform admin — otherwise an **empty set, never an
error**. The only dashboard RPC that takes an office id, and it is verified server-side. A failure is
swallowed (positions are an enrichment). Not on a timer: first paint + catch-up while the socket is unhealthy.

## L3 — Position stream: `watchFleetFixes()` (line 130)

`SUPABASE-SPECIFIC` — channel `dashboard_fleet_fixes_<officeId>`, `INSERT` on `public.trip_live_locations`
with **no filter**: the table has no `office_id`; `RLS` `trip_live_locations_read` → `can_read_trip_fixes(trip_id)`
admits the operating office, and Realtime evaluates it per WAL row. Each row → `FleetFixReported { tripId, fix }`;
subscribe status → `FleetLinkChanged(connected | degraded (closed/timedOut) | lost (channelError))`.
**Proposed .NET:** a per-office WebSocket topic fed by the captain's position endpoint
(`../../captain_api_doc/` — the captain is the sole writer, 10 s throttle).

## L4 — Incidents: `fetchOpenIncidents()` (line 176)

```
GET /rest/v1/driver_trip_reports
  ?select=id,trip_id,report_type,description,status,resolved_at,created_at,acknowledged_at,resolution_note,
          trip:operation_trips!inner(trip_date,departure_time,route:operation_routes(name),driver:drivers(full_name),vehicle:vehicles(plate_number,vehicle_code))
  &status=in.(pending,acknowledged)&order=created_at.desc
```
`RLS` `driver_trip_reports_office_manage` (through the trip's office). `report_type` (captain vocabulary):
`emergency | vehicle_issue | route_blockage | passenger_issue | delay | other`; `status`:
`pending | acknowledged | resolved | dismissed`. `acknowledged` stays on the board on purpose.

## L5 — Incident status: `updateIncidentStatus({incidentId, next, note})` (line 202)

```
PATCH /rest/v1/driver_trip_reports?id=eq.<id>
{ "status": "acknowledged", "acknowledged_at": <utc>, "acknowledged_by": <auth uid> }
{ "status": "resolved"|"dismissed", "resolved_at": <utc>, "resolved_by": <auth uid>, "resolution_note"?: "…" }
```
Direct write; both roles can today (UI hides the buttons from support agents via
`liveOpsIncidentAction`). No captain notification on resolve. `NEEDS BACKEND DECISION`: gate by role and
notify the captain.

## L6 — Board refresh: `watchChanges()` (line 239)

Channel `dashboard_live_ops_<officeId>`: `operation_trips` (filter `office_id=eq.`) + `driver_trip_reports`
(all events; RLS-scoped) → the cubit reloads L1/L4.

## Notes for the .NET team

1. The freshness thresholds must match the captain's publish cadence (10 s throttle, 30 s heartbeat) or
   the board flaps STALE.
2. `trip_live_locations` is append-only and grows ~360 rows/trip-hour; the "latest per trip" query needs the
   `(trip_id, recorded_at desc)` index or a materialised "latest" table.
3. No relative-age label ("منذ دقيقتين") is allowed on the live board by design rule; send absolute timestamps.
4. Incidents are filed by the captain app (`driver_trip_reports_captain_file`); the trigger
   `on_driver_trip_report_change` raises an operational alert for the office (see `notifications/`).
