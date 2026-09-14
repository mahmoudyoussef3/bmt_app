# Client · Home

The Home tab: greeting, the rider's live bookings, the active package card, the departures feed
(every bookable trip, soonest first) and the search-card suggestions. Read-only, plus one realtime
channel that triggers a refetch.

## Overview

| Layer | Files (relative to `lib/apps/client/features/home/`) |
|---|---|
| Screens | `presentation/screens/home_screen.dart` (+ `widgets/`), `client_shell_screen.dart` (bottom-nav shell), `client_splash_gate.dart` |
| Cubit | `HomeCubit` (`presentation/cubit/home_cubit.dart`) — `load()` at line 25; subscribes to changes at line 47 and refetches (`_refreshFromRealtime`, line 58) |
| Use cases | `GetHomeDataUseCase`, `WatchHomeChangesUseCase` |
| Repo | `data/repositories/home_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_home_datasource.dart` |
| Models / mappers | `data/models/home_data_model.dart`, `home_booking_model.dart` (`HomeBookingMapper`), `upcoming_trip_model.dart` (`UpcomingTripMapper`), `home_active_package_model.dart` |
| Entities | `domain/entities/home_data.dart` (`HomeData`, `UpcomingTripData`), `home_booking.dart`, `home_booking_status.dart`, `home_active_package.dart` |
| Shared rule | `lib/apps/client/core/utils/bookable_trip.dart` (`BookableTrip`) and `client_money.dart` (`tripFareLabel`, `moneyLabel`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| H1 | Load Home payload (4 parallel reads) | `GET operation_routes`, `GET public_trips`, `GET operation_bookings`, `GET subscriptions` | anon for H1a/H1b; session for H1c/H1d | `GET /api/v1/me/home` (one aggregate) |
| H2 | Watch for changes | Realtime channel `client_home_trips` | session (channel auth) | `NEEDS BACKEND DECISION` (SignalR / polling) |

---

## H1 — `SupabaseHomeDatasource.getHomeData()` (`supabase_home_datasource.dart:52-96`)

Runs four requests with `Future.wait`. `today = BookableTrip.today()` = local date as `yyyy-MM-dd`.

### H1a — active routes (for search suggestions)

```
GET /rest/v1/operation_routes?select=id,name,start_city,end_city,duration,status&status=eq.active
```

Used for: `pickupSuggestions = distinct(start_city)`, `destinationSuggestions = distinct(end_city)` (in Dart).

### H1b — bookable departures (the feed)

```
GET /rest/v1/public_trips
  ?select=*,
          route:operation_routes(id,name,start_city,end_city,duration),
          office:public_offices(id,name),
          trip_pricing(one_time_price,currency,is_active),
          trip_seats(state)
  &trip_date=gte.<today>
  &status=eq.open_for_booking
  &order=trip_date.asc,departure_time.asc
  &limit=50
```

`SUPABASE-SPECIFIC`: PostgREST resource embedding (`route:`, `office:` aliases, nested `trip_pricing`,
`trip_seats`). `public_trips` is a **view**; see `README.md` §5 for the columns it exposes.

Fields read per row (`UpcomingTripMapper.fromRow`, `upcoming_trip_model.dart`):

| Field | Source | Mapped to |
|---|---|---|
| `id` | trip | `tripId` |
| `route_id` (fallback `route.id`) | trip | `routeId` |
| `route.name` (fallback `"<start_city> - <end_city>"`) | embed | `routeName` |
| `route.start_city`, `route.end_city`, `route.duration` | embed | `pickup`, `destination`, `duration` |
| `trip_date` (`yyyy-MM-dd`), `departure_time` (`HH:mm:ss`) | trip | `tripDate`, `departureTime` |
| `trip_pricing[]` (`one_time_price`, `currency`, `is_active`) and `ticket_price`, `currency` | trip | `price` = **cheapest positive** of active `one_time_price` rows and `ticket_price`, formatted `"EGP 100"` (`tripFareLabel`) |
| `trip_seats[].state` | embed | `seatsLeft` = count of `state == 'available'` (`BookableTrip.seatsLeft`) — falls back to `capacity - booked_seats` only if the embed is missing |
| `status` | trip | `isLive` = `boarding` or `in_progress` |
| `office.id`, `office.name` | embed | `officeId`, `officeName` |
| `timeSuggestions` | all rows | `distinct(departure_time)` |

Each trip is tagged with the rider's own booking on it (`bookedStatus`, `bookedSeats`) by joining
H1c in Dart on `trip_id`.

### H1c — the rider's live bookings (only when signed in)

```
GET /rest/v1/operation_bookings
  ?select=id,trip_id,booking_number,status,seat,trip_date,trip_time,route,payment_amount,
          pickup_point_name,dropoff_point_name,operation_trips:public_trips(status)
  &client_id=eq.<uid>
  &status=in.(reserved,confirmed,boarded)
  &trip_date=gte.<today>
  &order=trip_date.asc,trip_time.asc
  &limit=10
```

Mapping (`HomeBookingMapper.fromRow`, `home_booking_model.dart`):

* Row dropped when embedded `operation_trips.status` is `completed` or `cancelled`, or when
  `status` is not one of `reserved → underReview`, `confirmed → confirmed`, `boarded → onBoard`.
* `pickup`/`destination` = `pickup_point_name`/`dropoff_point_name`, falling back to splitting the
  free-text `route` on `' → '`, `' - '`, `' to '`.
* `fare` = `moneyLabel(payment_amount)`; `seatLabel = seat`; `bookingNumber`; `tripDate`; `departureTime = trip_time`.

`RLS`: `bookings_client_read` — `client_id = auth.uid()`.

### H1d — active package (only when signed in)

```
GET /rest/v1/subscriptions
  ?select=package_name,route_name,start_date,end_date
  &client_id=eq.<uid>&status=eq.active
  &order=created_at.desc&limit=1               (maybeSingle)
```

→ `HomeActivePackageData(title=package_name, routeLabel=route_name, startDate, endDate)` or `null`.

### Response the screen needs (`HomeData`)

```json
{
  "userName": "<from token metadata full_name|name, else 'User'>",
  "upcomingTrips": [ { "tripId","routeId","routeName","pickup","destination","tripDate","departureTime",
                       "duration","price":"EGP 100","seatsLeft":7,"isLive":false,
                       "officeId","officeName","bookedStatus":"underReview|confirmed|onBoard|null","bookedSeats":0 } ],
  "bookings":      [ { "id","tripId","bookingNumber","status","pickup","destination","tripDate","departureTime","seatLabel","fare" } ],
  "pickupSuggestions": ["New Cairo", ...],
  "destinationSuggestions": ["Obour", ...],
  "timeSuggestions": ["07:00:00", ...],
  "activePackage": { "title","routeLabel","startDate","endDate" } | null
}
```

**Proposed .NET:** `GET /api/v1/me/home` returning exactly the above (server does the four reads
and the joins). `userName` can come from the token. For anonymous users the same endpoint with
empty `bookings`/`activePackage`, or `GET /api/v1/trips?bookable=true&limit=50` + `GET /api/v1/search/options`.

---

## H2 — Realtime: `watchHomeChanges()` (`supabase_home_datasource.dart:24-50`)

```
channel: client_home_trips
postgres_changes: schema=public, event=*, table=trip_seats
postgres_changes: schema=public, event=*, table=trip_events
postgres_changes: schema=public, event=*, table=operation_bookings
```

No filter — **every** change on those three tables (that RLS lets this user see) triggers
`HomeCubit._refreshFromRealtime()` → full H1 refetch. The payload is ignored; it is a "something changed" signal.

`NEEDS BACKEND DECISION`: replace with a SignalR group "marketplace-changed" (coalesced, e.g. ≤1
event / 2 s) or let the client poll `GET /me/home` on an interval while the tab is visible.

---

## Business rules that live in the client (must be reproduced server-side or kept in the app)

* **Sellable = `status == 'open_for_booking' AND trip_date >= today`** (`BookableTrip.isOffered`).
  A sold-out trip is still shown (CTA disabled); `isBookable` additionally requires `seatsLeft > 0`.
* **Seats left are counted from `trip_seats.state == 'available'`**, never from `booked_seats`.
* **Fare shown = cheapest active `trip_pricing.one_time_price` or `ticket_price`**, whichever is lower and > 0.
* Past-dated open trips are the operator's problem (flagged on the dashboard), never auto-closed.

## Notes for the .NET team

1. The feed is not paginated — capped at 50 soonest departures. Keep the cap or add paging.
2. `route` on a booking is a free-text label written at booking time (`"<pickup> → <dropoff>"`); the
   point-name columns are authoritative when present.
3. The `office:public_offices(id,name)` embed only resolves for **listed** offices; a delisted office
   yields `office = null` and the card shows no operator.
