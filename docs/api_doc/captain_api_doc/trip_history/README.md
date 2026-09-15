# Captain · Trip History

The driver's completed trips (grouped by period, searchable, date-filtered client-side) and, on
detail, the ordered stops of one trip with their scheduled offsets. Two reads, both unbounded.

## Overview

| Layer | Files (relative to `lib/apps/captain/features/trip_history/`) |
|---|---|
| Screens | `presentation/pages/trip_history_page.dart` (History tab of `CaptainAppShell`), `trip_history_detail_page.dart` (route `CaptainRoutes.tripHistoryDetail = /captain/history/detail`, argument `TripHistoryItem` — passed by value) |
| Cubits | `TripHistoryCubit` (`presentation/cubit/trip_history_cubit.dart` — `load()` :18-29, `refresh()`, `search()`, `filterByDate()`; all filtering/grouping is local: `presentation/utils/trip_history_filters.dart`), `TripHistoryDetailCubit` (`trip_history_detail_cubit.dart` — `load(tripId)` :12-23) |
| Use cases | `GetTripHistoryUseCase`, `GetTripStopsUseCase` |
| Repo | `data/repositories/trip_history_repository_impl.dart` |
| **Datasource** | `data/datasources/trip_history_datasource.dart` |
| Entities | `domain/entities/trip_history_item.dart` (`TripHistoryItem`; derived `duration`, `boardingRate`), `trip_history_stop.dart` (`TripHistoryStop {name, order, scheduledTime?}`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| H1 | Completed trips | `GET operation_trips?select=…&driver_id=eq.&status=eq.completed&order=trip_date.desc,departure_time.desc` | session (captain) | `GET /api/v1/captain/trips/history` |
| H2 | Stops of one trip | `GET trip_route_points?select=…&trip_id=eq.&order=point_order.asc` | session | `GET /api/v1/captain/trips/{tripId}/stops` |

---

## H1 — `getTripHistory()` (`trip_history_datasource.dart:34-52`)

Driver id from `CaptainIdentityProvider.driverId()`; null ⇒ `[]`.

```
GET /rest/v1/operation_trips
  ?select=id,trip_date,departure_time,arrival_time,
          operation_routes(name,start_city,end_city),
          vehicles(vehicle_code,plate_number),
          trip_passengers(id,status)
  &driver_id=eq.<driverId>&status=eq.completed
  &order=trip_date.desc,departure_time.desc
→ 200 [ { "id":"…","trip_date":"2026-09-14","departure_time":"07:30:00","arrival_time":"08:50:00",
          "operation_routes":{"name":"…","start_city":"…","end_city":"…"},
          "vehicles":{"vehicle_code":"V-12","plate_number":"…"},
          "trip_passengers":[{"id":"…","status":"completed"},…] }, … ]
```

**App reads** (`_mapRow` :54-86): `id`; `route` = `operation_routes.name` else `"<start> - <end>"`
(plain hyphen — bidi rule); `tripDate` (unparsable ⇒ now); `departureTime`/`arrivalTime` = date +
`HH:mm` (`_parseTime` :88-93, bad parts ⇒ 0); `passengerCount` = manifest length; `boardedCount` =
`status IN (confirmed, completed)`; `vehicleNumber`, `plateNumber`. The history header sums
`boardedCount` across all trips as "passengers carried".

`RLS`: `trips_captain_read` (own office **and** own driver id), embeds via `routes_captain_read`,
`vehicles_captain_read`, `trip_passengers_captain_read`. **Unbounded** — `NEEDS BACKEND DECISION`:
paginate (the UI's period grouping and date filters would map naturally to `?from=&to=&page=`).

**Proposed .NET:** `GET /api/v1/captain/trips/history?from=&to=&page=&pageSize=` →
`{ items: [ { id, route, tripDate, departureAt, arrivalAt, passengerCount, boardedCount, vehicleCode, plateNumber } ], total }`.

---

## H2 — `getTripStops(tripId)` (`trip_history_datasource.dart:14-32`)

```
GET /rest/v1/trip_route_points?select=point_name,point_order,arrival_offset,departure_offset&trip_id=eq.<tripId>&order=point_order.asc
→ 200 [ { "point_name":"رمسيس","point_order":1,"arrival_offset":"00:00","departure_offset":"00:05" }, … ]
```
**App reads:** `point_name`, `point_order`, and `scheduledTime` = `arrival_offset` if non-empty else
`departure_offset` (**note the opposite preference from the manifest's pickup time**, which prefers
`departure_offset`). Offsets are `"HH:MM"` durations from route start, rendered as-is.
`RLS`: `trip_route_points_captain_read`.

**Proposed .NET:** `GET /api/v1/captain/trips/{tripId}/stops` →
`[ { name, order, arrivalOffset, departureOffset } ]` — return both offsets and let the app choose,
or better, resolve them to clock times against `trip_date + departure_time` in the office timezone
(the station board already does this server-side, `../station_progress/`).

## Notes for the .NET team

1. History is derived purely from `operation_trips.status = 'completed'`; there is no separate archive.
2. Both reads reuse the assigned-trips shape; a shared `CaptainTripSummary` DTO with a `status` filter
   would serve `assigned_trips` H1 and this endpoint.
3. Actual times (`actual_start_time`, `actual_end_time`) exist on the trip row but the app shows the
   *planned* departure/arrival — consider returning both.
