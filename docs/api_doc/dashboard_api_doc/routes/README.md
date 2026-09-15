# Dashboard · Routes (المسارات)

The office's route catalogue: a route is a **name-first** ordered list of stations (a station is a
name; GPS is optional), with per-station offsets and pickup/dropoff flags. Rebuilt 2026-08-02.
Trips snapshot a route's stations at creation (`trip_route_points`), so editing a route never moves
an existing trip. All access is **direct table access under RLS** — no RPCs, no triggers specific to
routes beyond licensing.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/routes/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.routes` = `/routes`; the route builder is a dialog/pane with a map dialog for optional coordinates) |
| Cubit | `presentation/cubit/routes_cubit.dart` |
| Use cases | `domain/usecases/` (`GetRoutesUseCase`, `CreateRouteUseCase`, `UpdateRouteUseCase`, `DeleteRouteUseCase`, `AddStationUseCase`, `UpdateStationUseCase`, `DeleteStationUseCase`, `ReorderStationsUseCase`) |
| Repo | `data/repositories/routes_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_routes_datasource.dart` (`SupabaseRoutesDatasource implements RoutesDatasource`) |
| Model / entity | `data/models/operation_route_model.dart` (`OperationRouteModel`, `RouteStationModel`), `domain/entities/operation_route.dart` (`OperationRouteStatus`, `RouteStation`) |
| Permission | `DashboardPermission.routes` (admin only); feature key `routes`; limit `max_routes` (stock meter, trigger on insert) |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| R1 | List routes + stations | `GET operation_routes?office_id=eq.&order=created_at.desc` → `GET route_stations?route_id=in.(…)&order=sort_order` | `GET /api/v1/dashboard/routes` |
| R2 | Create route | `POST operation_routes` → `POST route_stations[]` → R5 | `POST /api/v1/dashboard/routes` |
| R3 | Update route (+ station sync) | `PATCH operation_routes` → diff `route_stations` (delete/insert/update) → R5 | `PUT /api/v1/dashboard/routes/{id}` |
| R4 | Delete route | `DELETE route_stations?route_id=eq.` → `DELETE operation_routes?id=eq.` | `DELETE /api/v1/dashboard/routes/{id}` |
| R5 | Re-read one route | `GET operation_routes?id=eq.` + `GET route_stations?route_id=eq.` | `GET /api/v1/dashboard/routes/{id}` |
| R6 | Add station | `GET route_stations` (for next order) → `POST route_stations` → R5 | `POST /api/v1/dashboard/routes/{id}/stations` |
| R7 | Update station | `PATCH route_stations?id=eq.` → R5 | `PATCH /api/v1/dashboard/routes/{id}/stations/{stationId}` |
| R8 | Delete station | `DELETE route_stations?id=eq.` → renumber → R5 | `DELETE /api/v1/dashboard/routes/{id}/stations/{stationId}` |
| R9 | Reorder stations | `GET route_stations` → `PATCH route_stations {sort_order}` **per station** → R5 | `PUT /api/v1/dashboard/routes/{id}/stations/order` |

`RLS`: `routes_office_manage` / `route_stations_office_manage` (`FOR ALL`, `office_id = current_office_id()`;
stations through the parent route) — **both roles can write today**; the UI hides the module from support
agents (`DashboardPermission.routes`). Marketplace read (anon) covers active routes of listed offices.
Errors: `LicensingGuard.check` then the raw Postgres message with code/details/hint appended.

---

## R1 — List: `fetchRoutes()` (`supabase_routes_datasource.dart:23`)

```
GET /rest/v1/operation_routes?select=*&office_id=eq.<office>&order=created_at.desc
GET /rest/v1/route_stations?select=*&route_id=in.(<ids>)&order=sort_order.asc
```
Unbounded. Route row → `OperationRouteModel`: `id, name, route_code, start_city, end_city, duration,
distance, status (active|paused|draft|archived), notes, created_at, updated_at`. Station row →
`RouteStationModel`: `id, route_id, name, area, arrival_offset, departure_offset, location_description, notes,
latitude?, longitude?, pickup_allowed, dropoff_allowed, estimated_arrival_time, sort_order`.

**Proposed .NET:** `GET /api/v1/dashboard/routes?status=&search=&page=` with stations embedded (routes are few per office).

---

## R2 — Create: `createRoute(route)` (line 72)

```
POST /rest/v1/operation_routes      Prefer: return=representation
{ office_id, name, route_code, start_city, end_city, duration, distance, status, notes, updated_at }
POST /rest/v1/route_stations
[ { route_id, name, area, arrival_offset, departure_offset, location_description, notes, latitude, longitude,
    pickup_allowed, dropoff_allowed, estimated_arrival_time, sort_order: 1..n, updated_at } … ]
```
Two requests, not atomic (a failed station insert leaves a station-less route, which trip creation refuses:
'لا يمكن إنشاء رحلة لمسار ليس له محطات.'). `max_routes` stock meter → `quota_exceeded`. `sort_order` is
renumbered 1..n client-side.

`BUSINESS RULE` (client-side, `route builder`): the first and last stations are the terminals; a station is
a **name** — `latitude/longitude` are optional and only set through the map dialog.

**Proposed .NET:** `POST /api/v1/dashboard/routes { name, routeCode, startCity, endCity, duration, distance, status, notes, stations[] }` → `201 Route` in one transaction.

---

## R3 — Update + station sync: `updateRoute(route)` (line 102, `_syncStations` line 255)

```
PATCH /rest/v1/operation_routes?id=eq.<id>  { name, route_code, start_city, end_city, duration, distance, status, notes, updated_at }
GET   /rest/v1/route_stations?route_id=eq.<id>&order=sort_order
DELETE /rest/v1/route_stations?id=in.(<removed ids>)          (stations missing from the payload)
POST  /rest/v1/route_stations { … }                            (per station with empty id)
PATCH /rest/v1/route_stations?id=eq.<sid> { … sort_order: index+1 }   (per changed station; unchanged rows skipped)
```
Status-only writes (pause / archive) pass the full station list and skip unchanged rows. Not atomic.
**Proposed .NET:** `PUT /api/v1/dashboard/routes/{id}` with full replace-children semantics in one transaction.

## R4 — Delete: `deleteRoute(routeId)` (line 119)

Deletes stations then the route. **No guard**: `operation_trips.route_id` is `ON DELETE SET NULL`
(`20260721090000_multi_office_foundation.sql:179`), so deleting a route detaches its trips (they keep their
`trip_route_points` snapshot but lose `route.name`). The UI offers "archive" as the normal path.
`NEEDS BACKEND DECISION`: refuse deletion when trips reference the route (mirror the fleet delete guard).

## R6–R9 — Stations

* **Add** (line 131): next `sort_order = last + 1`, insert, re-read.
* **Update** (line 157): full-row `PATCH` by station id.
* **Delete** (line 177): delete, then `_normalizeStationOrder` re-numbers survivors with one `PATCH` per
  out-of-place row.
* **Reorder** (line 195): applies the drag-and-drop move in Dart then issues **one `PATCH` per station**
  (`{sort_order: i+1, updated_at}`) — n requests, not atomic.

**Proposed .NET:** `PUT /api/v1/dashboard/routes/{id}/stations/order { stationIds: [...] }` in one transaction.

---

## Notes for the .NET team

1. Stations are ordered by `sort_order` starting at 1 with no gaps; the client keeps this invariant with
   extra round trips — make the server own it.
2. Keep `arrival_offset` / `departure_offset` as free-text offsets (they are copied verbatim onto
   `trip_route_points` at trip creation and may be overridden per trip).
3. The client marketplace reads `operation_routes` + `route_stations` directly for search (see
   `../../client_api_doc/routes/`); the same rows serve both consoles, so field names must not diverge.
4. Route status `archived` blocks trip creation (`trips/` T18); `paused` does not.
