# Client · Routes catalogue

The "Routes" tab: every active route on the marketplace (with its operator, its stations for
in-app station search, and a per-route booking outlook), and the Route Details screen (full route +
ordered stops; packages and trips on that screen come from the booking/packages features).

## Overview

| Layer | Files (relative to `lib/apps/client/features/routes/`) |
|---|---|
| Screens | `presentation/screens/routes_directory_screen.dart` (shell tab), `route_details_screen.dart` (`RoutesFeatureRoutes.details`, argument route id) |
| Cubits | `RoutesDirectoryCubit` (`load()`, `refresh()`), `RouteDetailsCubit` (`load(routeId)`) |
| Use cases | `domain/usecases/` (`GetRoutesUseCase`, `GetRouteDetailsUseCase`, station search is pure Dart via `lib/core/search/`) |
| Repo | `data/repositories/routes_directory_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_routes_directory_datasource.dart` |
| Models | `data/models/route_summary_model.dart`, `route_availability_model.dart`, `route_details_model.dart`, `route_stop_model.dart` |
| Entities | `domain/entities/route_summary.dart`, `route_availability.dart` (`RouteAvailabilityStatus {unknown, bookable, soldOut, none}`), `route_details.dart`, `route_stop.dart` |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| O1 | Routes catalogue + availability | `GET operation_routes` (+stations, office embeds) + `GET public_trips` | anon | `GET /api/v1/routes` |
| O2 | Route details + stops | `GET operation_routes?id=eq.` + `GET route_stations` | anon | `GET /api/v1/routes/{routeId}` |

`RLS` (`20260721140000_platform_office_onboarding.sql:111-121`): `routes_marketplace_read` — `status = 'active' AND office_is_listed(office_id)`; `route_stations_marketplace_read` — stations of such routes.

---

## O1 — `fetchRoutes()` (`supabase_routes_directory_datasource.dart:33-59`)

```
GET /rest/v1/operation_routes
  ?select=id,name,start_city,end_city,distance,duration,
          stops:route_stations(id,name,sort_order),
          office:public_offices(id,name,logo_url)
  &status=eq.active
  &order=name.asc

GET /rest/v1/public_trips
  ?select=route_id,trip_date,departure_time,status,capacity,booked_seats,trip_seats(state)
  &route_id=in.(<all route ids>)
  &status=eq.open_for_booking
  &trip_date=gte.<today>
  &order=trip_date.asc,departure_time.asc
  &limit=400
```

Row → `RouteSummaryModel { id, name, startCity, endCity, distance, duration, officeId, officeName, officeLogoUrl,
stops[] (sorted by sort_order, unnamed dropped), availability }`.

**Availability rule** (`RouteAvailabilityModel`, must be reproduced if computed server-side):
group the trip rows by `route_id`, keeping only `BookableTrip.isOffered` rows (open + not past);
`bookable` = any row with seats left — name the **first row with a free seat** (`nextDepartureDate`,
`nextDepartureTime`, `seatsLeft`, `tripCount` = number of bookable rows); `soldOut` = rows exist but
none has a seat — name the soonest one; `none` = no rows for that route; **`unknown`** for every route
when the trips read itself failed (the catalogue still renders, cards make no availability claim).
The 400-row cap only ever trims the most distant departures.

**Proposed .NET:** `GET /api/v1/routes` → `[{ id, name, startCity, endCity, distance, duration, office:{id,name,logoUrl}, stops:[{id,name,order}], availability:{ status, nextDepartureDate, nextDepartureTime, seatsLeft, tripCount } }]`.

---

## O2 — `fetchRouteDetails(routeId)` (line 100-119)

```
GET /rest/v1/operation_routes?select=*,office:public_offices(*)&id=eq.<routeId>&status=eq.active     (.single())
GET /rest/v1/route_stations?select=*&route_id=eq.<routeId>&order=sort_order.asc
```

→ `RouteDetailsModel { id, name, startCity, endCity, routeCode=route_code, distance, duration, status,
officeId, officeName, officeLogoUrl, officeRating, stops[] }` with `RouteStopModel { id, name, order=sort_order, area,
arrivalOffset, departureOffset, estimatedArrivalTime, pickupAllowed (default true), dropoffAllowed (default true), latitude, longitude }`.

The Route Details screen additionally loads the office's packages (`packages/K1` via `RoutePackagesCubit.loadFor(officeId)`) and the route's trips (`booking/B1` with `routeId`).

**Proposed .NET:** `GET /api/v1/routes/{routeId}` → the shape above (`404` when inactive/unlisted).

## Notes for the .NET team

1. Station search across the whole catalogue is done in the app (`lib/core/search/` normaliser) over the embedded station names — so O1 must keep returning `stops` for every route, or provide `GET /api/v1/search/stations?q=`.
2. The catalogue is unbounded on routes; today there are a few dozen. Add paging only if the marketplace grows.
3. `distance`/`duration` are free-text strings as entered by the office.
