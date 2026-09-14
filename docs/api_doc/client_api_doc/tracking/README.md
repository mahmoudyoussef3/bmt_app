# Client · Live Tracking

Follow the bus on a paid booking: the trip's stops, the captain's latest GPS fix (realtime + a
fallback poll), the live station board, the rider's own manifest row, trip events, and the
"I'm on board" confirmation. The screen is the heaviest realtime consumer in the client.

## Overview

| Layer | Files (relative to `lib/apps/client/features/tracking/`) |
|---|---|
| Screen | `presentation/screens/tracking_screen.dart` (route `TrackingRoutes.tracking` = `/tracking`, arguments `{bookingId}` or `{tripId}` or none = "my current trackable booking") |
| State | `TrackingCubit` (`presentation/cubit/tracking_cubit.dart` — `load({bookingId, tripId})`, `refresh()`, `confirmBoarding()`), `TrackingSubscriptions` (`syncTripChanges(tripId)`), **`LiveTrackingBloc`** (`presentation/bloc/live_tracking_bloc.dart` — the only Bloc in the client; owns the GPS feed and the progress engine in `lib/core/tracking/`) |
| Use cases | `GetTrackingTripUseCase`, `WatchVehicleFeedUseCase`, `WatchTrackingTripUseCase`, `ConfirmBoardingUseCase` |
| Repo | `data/repositories/tracking_repository_impl.dart` |
| **Datasources** | `data/datasources/supabase_tracking_datasource.dart` (orchestration), `tracking_trip_query.dart` (the reads), `tracking_realtime.dart` (channels) |
| Models | `data/models/tracking_trip_assembler.dart` (rows → entity), `tracking_point_model.dart`, `tracking_state_model.dart` (status/event → `TrackingTripState`), `tracking_crew_model.dart`, `tracking_rider_model.dart`, `tracking_stops_model.dart` |
| Entities | `domain/entities/tracking_trip.dart` (`TrackingTripData`), `tracking_trip_state.dart`, `tracking_point.dart`, `vehicle_feed.dart` (`VehicleFixReported`, `VehicleLinkChanged`, `TrackingLink {connected, degraded, lost}`) |
| Shared | `lib/core/tracking/live_tracking_config.dart` (cadences), `lib/core/tracking/progress/station_board_mapper.dart` (station board columns) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| L1 | Resolve the trackable booking | `GET operation_bookings` | session | part of L2 |
| L2 | Load the tracking view (7 parallel reads) | `trip_route_points`, `public_trips`, `trip_live_locations`, `trip_events`, `trip_passengers`, `trip_reviews`, `trip_station_progress` | session | `GET /api/v1/me/tracking?bookingId=|tripId=` |
| L3 | Live vehicle feed | Realtime `location_updates:<tripId>` + poll `GET trip_live_locations` while unhealthy | session | `NEEDS BACKEND DECISION` (SignalR stream + `GET /api/v1/trips/{tripId}/live-position`) |
| L4 | Watch trip changes | Realtime `client_tracking:<tripId>` (6 tables) | session | `NEEDS BACKEND DECISION` |
| L5 | Confirm boarding | `POST rpc/passenger_confirm_boarding` | session | `POST /api/v1/bookings/{bookingId}/boarding-confirmation` |

---

## L1 — Which booking? `TrackingTripQuery.findBooking()` (`tracking_trip_query.dart:28-48`)

```
GET /rest/v1/operation_bookings?select=id,trip_id,status,created_at&client_id=eq.<uid>&id=eq.<bookingId>            (maybeSingle)
GET /rest/v1/operation_bookings?select=id,trip_id,status,created_at&client_id=eq.<uid>&trip_id=eq.<tripId>          (maybeSingle)
GET /rest/v1/operation_bookings?select=id,trip_id,status,created_at&client_id=eq.<uid>
    &status=in.(confirmed,boarded,completed)&order=created_at.desc&limit=1                                            (maybeSingle)
```

**Rule:** a booking is trackable only with `status IN ('confirmed','boarded','completed')`
(`trackableStatuses`). A `reserved` (payment pending) or `cancelled` booking ⇒ `TrackingTripData.none`.
The same set is the database boundary (`can_read_trip_fixes`, below) — the app check just fails early.

---

## L2 — The tracking view: `getTrackingTrip()` (`supabase_tracking_datasource.dart:31-70`)

After L1, seven reads run in parallel (`Future.wait`):

| # | Request | Read as |
|---|---|---|
| a | `GET /rest/v1/trip_route_points?select=id,route_point_id,point_name,point_order,latitude,longitude,arrival_offset,departure_offset&trip_id=eq.<tripId>&order=point_order.asc` | `stops[]` (`RouteStop`) |
| b | `GET /rest/v1/public_trips?select=id,trip_code,status,trip_date,departure_time,arrival_time,route:operation_routes(name),driver:drivers,vehicle:vehicles&id=eq.<tripId>` (maybeSingle) | `tripCode`, `routeName`, `departureAt`/`arrivalAt` (date+time), captain (`full_name, profile_image_url, rating, rating_count`), vehicle (`brand, model, plate_number, vehicle_type, color, image_url, rating, rating_count`), raw `status` |
| c | `GET /rest/v1/trip_live_locations?select=latitude,longitude,heading,speed,accuracy,recorded_at&trip_id=eq.<tripId>&order=recorded_at.desc&limit=1` (maybeSingle) | `vehicleFix` (`TrackingPoint`) or null |
| d | `GET /rest/v1/trip_events?select=title,created_at&trip_id=eq.<tripId>&order=created_at.desc` | newest title drives state inference; count of per-station arrival events seeds the progress engine (`arrivalEventCount`) — errors ⇒ `[]` |
| e | `GET /rest/v1/trip_passengers?select=seat_label,pickup_point_id,pickup_point_name,dropoff_point_id,dropoff_point_name,status&trip_id=eq.<tripId>&customer_id=eq.<uid>&limit=1` (maybeSingle) | `rider` (own manifest row) — errors ⇒ null |
| f | `GET /rest/v1/trip_reviews?select=booking_id&booking_id=eq.<bookingId>` (maybeSingle) | `hasReview` — errors ⇒ false |
| g | `GET /rest/v1/trip_station_progress?select=id,trip_id,route_point_id,point_name,sequence,expected_arrival_at,expected_departure_at,min_dwell_seconds,actual_arrival_at,actual_departure_at,status,expected_boardings,boarded_count,pending_count,no_show_count&trip_id=eq.<tripId>&order=sequence.asc` | `stations` (`StationBoard`) — empty until the trip starts boarding; errors ⇒ `[]` |

State inference (`TrackingStateModel.resolve`): trip `status` `in_progress` ⇒ `inProgress`,
`boarding` ⇒ `boarding`, `completed` ⇒ `completed`; otherwise the newest `trip_events.title`
(Arabic, exact strings): `اكتملت الرحلة` / `وصلت الرحلة للوجهة` ⇒ completed; `غادرت الرحلة` ⇒ inProgress;
`وصل السائق لنقطة الانطلاق` ⇒ boarding; `السائق في الطريق` ⇒ driverOnWay; else `driverOnWay` if a fix exists, `notStarted` otherwise.

Result (`TrackingTripData`): `tripState, tripId, bookingId, tripCode, routeName, departureAt, arrivalAt,
arrivalEventCount, captain, vehicle, rider {seatLabel, pickup/dropoff point id+name, status}, stops[],
stations[], vehicleFix?, hasReview`. Derived: `myStation` (board row matched by `route_point_id` then name),
`canConfirmBoarding` (vehicle standing at my station).

`RLS`: `trip_live_locations` select gated by `can_read_trip_fixes(trip_id)` (`20260729090000_tracking_authority.sql:68`):
platform admin, the operating office, the driving captain, **or a passenger with a booking on the trip in
`confirmed|boarded|completed`**. `trip_passengers` narrowed to own `customer_id`. `trip_events`,
`trip_route_points`, `trip_station_progress` readable for trips the rider can see.

**Proposed .NET:** `GET /api/v1/me/tracking?bookingId=` (or `tripId=`, or none) → the full
`TrackingTripData` shape in one response; `204` when nothing is trackable; `403` when the booking is not paid.

---

## L3 — Live vehicle feed: `watchVehicleFeed(tripId)` (`supabase_tracking_datasource.dart:110-176`, `tracking_realtime.dart:44-75`)

```
channel: location_updates:<tripId>
postgres_changes: table=trip_live_locations, event=INSERT, filter=trip_id=eq.<tripId>
subscribe(status callback) → VehicleLinkChanged(connected | degraded | lost)
```

* Each INSERT payload (`new_record`) is parsed by `TrackingPointModel.fromRow`: `latitude`, `longitude` (required), `heading`, `speed`, `accuracy`, `recorded_at` (ISO → local).
* Subscribe status mapping: `subscribed` ⇒ `connected`; `closed`/`timedOut` ⇒ `degraded`; `channelError` ⇒ `lost`.
* **Fallback poll**: armed on listen; while the link is not `connected` (or on stream error) it runs
  `GET trip_live_locations … limit=1` (read c) immediately and then every **8 s** (`reconnectPollInterval`);
  it stops the moment the socket reports `connected`. The progress engine ignores fixes that are not strictly newer.
* Freshness: a feed with no fix for **45 s** (`staleAfter`) is shown stale. The captain publishes every ≤10 s while moving, 30 s heartbeat when parked.

**Proposed .NET:** SignalR hub method `SubscribeTrip(tripId)` streaming `{ latitude, longitude, heading, speed, accuracy, recordedAt }` with the same authorization as `can_read_trip_fixes`, plus `GET /api/v1/trips/{tripId}/live-position` for the fallback poll.

---

## L4 — Trip change signal: `watchTripChanges(tripId)` (`tracking_realtime.dart:90-109`)

```
channel: client_tracking:<tripId>
postgres_changes (event=*, filter=trip_id=eq.<tripId>) on:
  operation_bookings, trip_events, trip_passengers, trip_route_points, trip_seats, trip_station_progress
```

Any event ⇒ `TrackingCubit.refresh()` ⇒ L2 refetch (silent). This is what moves "✓ passed" / next-stop ETA when the captain leaves a station.

**Proposed .NET:** a single `trip-changed` event on the same SignalR trip group.

---

## L5 — "I'm on board": `confirmBoarding(bookingId)` (`supabase_tracking_datasource.dart:76-107`)

```
POST /rest/v1/rpc/passenger_confirm_boarding
{ "p_booking_id": "<uuid>" }
→ 200 { "success":true, "unchanged":false, "booking_id":"…", "station_id":"…", "point_name":"…", … }
      { "success":true, "unchanged":true, "booking_id":"…" }        // already boarded (idempotent)
```

**`BUSINESS RULE`** (`20260811090000_station_boarding_authority.sql:811-925`):

1. `not_authenticated`; booking exists (`booking_not_found`), locked `FOR UPDATE`.
2. Caller owns it (`not_your_booking`).
3. Already `boarded` ⇒ idempotent success.
4. Booking `status` must be `confirmed` (`booking_not_boardable:<status>`).
5. Trip must be `boarding` or `in_progress` (`trip_not_running:<status>`); `ensure_trip_station_progress(trip)` builds the board if missing.
6. **The vehicle must be standing at a station** — a `trip_station_progress` row with `actual_arrival_at NOT NULL AND actual_departure_at IS NULL` (`vehicle_not_at_station`).
7. **…and it must be this rider's station** — manifest `pickup_point_id == station.route_point_id`, falling back to name equality (`not_your_station:<point_name>`); manifest status must be `reserved|confirmed` (`passenger_not_boardable`).
8. Manifest row → `status='confirmed'`, `boarded_at=coalesce(boarded_at, now())`, `boarding_source='passenger'`; booking → `status='boarded'`; `recount_trip_stations(trip)`.

**Errors the app maps** (`_boardingFailure`, Arabic copy): `vehicle_not_at_station`, `not_your_station`, `not_your_booking`, `booking_not_boardable`, `trip_not_running`; else generic.

**Proposed .NET:** `POST /api/v1/bookings/{bookingId}/boarding-confirmation` → `200 { unchanged, stationId, pointName }`; `409 { code }` with the codes above.

---

## Data shapes the backend must provide

`trip_live_locations` row: `trip_id, latitude, longitude, heading?, speed?, accuracy?, recorded_at` (written only by the captain app).
`trip_station_progress` row: see read g (columns are the contract in `StationBoardMapper.columns`); `status` vocabulary (check constraint, `20260811090000_station_boarding_authority.sql:145`): `upcoming | arriving | waiting_for_passengers | departed`.
`trip_events` row: `trip_id, title (Arabic, load-bearing strings above), created_at`.

## Notes for the .NET team

1. The tracking authorization is **booking-status based**, not just ownership: a rider who has not been approved must not see the bus.
2. Once the rider boards, `can_read_trip_fixes` still admits them (`boarded` is in the set); the app cancels its own subscription as a courtesy.
3. The event **titles** are Arabic strings used as an enum — replace with a typed `event_code` in the port (a known gap; see memory note on `event_code`).
4. Cadences (10 s publish / 30 s heartbeat / 45 s stale / 8 s fallback poll) live in one place — `lib/core/tracking/live_tracking_config.dart` — and the captain app shares it.
