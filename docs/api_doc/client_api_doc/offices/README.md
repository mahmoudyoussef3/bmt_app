# Client · Offices (operators directory)

The marketplace's operator directory and an office's public profile (its active routes and the
seats it is selling right now). Everything reads the sanitised `public_offices` view — no private
office column ever reaches the client.

## Overview

| Layer | Files (relative to `lib/apps/client/features/offices/`) |
|---|---|
| Screens | `presentation/screens/offices_directory_screen.dart` (`OfficesRoutes.directory`), `office_profile_screen.dart` (`OfficesRoutes.profile`, argument office id / summary) |
| Cubits | `OfficesDirectoryCubit` (`load()`, `refresh()`), `OfficeProfileCubit` (`load(officeId)`) |
| Use cases | `domain/usecases/` (`GetOfficesUseCase`, `GetOfficeRoutesUseCase`, `GetOfficeTripsUseCase`) |
| Repo | `data/repositories/offices_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_offices_datasource.dart` |
| Models / entities | `data/models/office_summary_model.dart`, `office_route_model.dart`, `office_trip_model.dart`; `domain/entities/office_summary.dart`, `office_route.dart`, `office_trip.dart` |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| G1 | Offices directory (+ active route counts) | `GET public_offices` + `GET operation_routes?select=office_id` | anon | `GET /api/v1/offices` |
| G2 | An office's active routes | `GET operation_routes?office_id=eq.` | anon | `GET /api/v1/offices/{officeId}/routes` |
| G3 | An office's bookable trips | `GET public_trips?office_id=eq.` | anon | `GET /api/v1/offices/{officeId}/trips` |
| — | Office profile header | reuses the G1 row (or the office embedded on a package/route) | — | `GET /api/v1/offices/{officeId}` |

---

## The `public_offices` view (the only office surface the client may read)

Definition (`20260721140000_platform_office_onboarding.sql:278`, `security_invoker = false`):

```sql
select id, name, slug, logo_url, description, service_areas, rating, ratings_count
  from offices
 where status = 'active' and listing_status = 'listed';
```

The stronger predicate used by the trip/route/package policies is `office_is_listed(office_id)`
(`20260807140000_licensing_marketplace.sql:160`): `status = 'active' AND listing_status = 'listed' AND
coalesce(licensing_hold,'none') <> 'delisted'`. `rating`/`ratings_count` are maintained by the
`trip_reviews` triggers (office rating is rated explicitly by riders, never averaged from driver/vehicle).

---

## G1 — `fetchOffices()` (`supabase_offices_datasource.dart:18-42`)

```
GET /rest/v1/public_offices?select=*&order=rating.desc,name.asc
GET /rest/v1/operation_routes?select=office_id&status=eq.active            → counted per office in Dart
```

→ `OfficeSummaryModel { id, name, logoUrl, description, rating, ratingsCount, serviceAreas[], routesCount }`.

**Proposed .NET:** `GET /api/v1/offices` → `[{ id, name, logoUrl, description, rating, ratingsCount, serviceAreas, routesCount }]` sorted rating desc, name asc.

## G2 — `fetchOfficeRoutes(officeId)` (line 64)

```
GET /rest/v1/operation_routes?select=id,name,start_city,end_city&office_id=eq.<officeId>&status=eq.active&order=name.asc
```

→ `OfficeRouteModel { id, name, startCity, endCity }`.

## G3 — `fetchOfficeTrips(officeId)` (line 84)

```
GET /rest/v1/public_trips
  ?select=id,route_id,trip_date,departure_time,capacity,booked_seats,ticket_price,currency,status,
          route:operation_routes(id,name,start_city,end_city,duration),
          trip_pricing(one_time_price,currency,is_active),
          trip_seats(state)
  &office_id=eq.<officeId>&status=eq.open_for_booking&trip_date=gte.<today>
  &order=trip_date.asc,departure_time.asc&limit=30
```

Rows re-checked with `BookableTrip.isOffered` → `OfficeTripModel { id, routeId, routeName (name or "<start> - <end>"), pickup, destination, tripDate, departureTime, duration, price = tripFareLabel (cheapest active fare), seatsLeft }`.

**Proposed .NET:** `GET /api/v1/offices/{officeId}/trips?limit=30` (same shape as the Home feed item).

## Notes for the .NET team

1. Only the eight public columns of an office may be exposed; the join code, contact details, staff and fleet documents must never appear on a client endpoint.
2. The office profile screen also shows packages — see `packages/K1` with `officeId`.
