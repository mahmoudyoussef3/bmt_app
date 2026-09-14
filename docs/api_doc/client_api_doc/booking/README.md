# Client · Booking (discovery + wizard)

Search for a corridor, rank routes, show popular routes, map pins, search options, the vehicle
listing/detail screens, and the **booking wizard** (route → stops → trip → seat → package → payment).
This feature owns the *reads* of the funnel and the mapping from the wizard session to the booking
RPC parameters. The *writes* (lock / confirm / update payment) live in [`../seat_selection`](../seat_selection/README.md);
receipts and card checkout in [`../payments`](../payments/README.md); the package menu in
[`../packages`](../packages/README.md).

## Overview

| Layer | Files (relative to `lib/apps/client/features/booking/`) |
|---|---|
| Screens | `presentation/screens/search_trip_screen.dart`, `route_selection_screen.dart` (results), `popular_routes_screen.dart`, `map_route_selection_screen.dart`, `route_map_screen.dart`, `route_overview_screen.dart`, `vehicle_listing_screen.dart`, `vehicle_details_screen.dart`, `daily_booking_flow_screen.dart`, **`booking_wizard_screen.dart`** |
| Cubits | `BookingSearchCubit` (search options), `RouteResultsCubit` (`load(query)`), `PopularRoutesCubit`, `MapPinsCubit`, `VehicleListingCubit`, `VehicleDetailsCubit`, `DailyBookingCubit`, `BookingWizardCubit` / `BookingWizardStepCubit` (session state), `RoutePackagesCubit` (`loadFor(officeId)` → packages feature), **`BookingWizardConfirmCubit`** (`confirm(session)` → seat_selection + payments) |
| Use cases | `GetBookingRoutesUseCase`, `GetPopularRoutesUseCase`, `GetMapPinsUseCase`, `GetSearchOptionsUseCase`, `GetVehiclesUseCase`, `GetVehicleDetailsUseCase`, `GetDailyBookingDataUseCase`, `SortVehiclesUseCase` (pure Dart) |
| Repo | `data/repositories/booking_repository_impl.dart` |
| **Datasources** | `data/datasources/supabase_booking_search_datasource.dart`, `supabase_vehicle_booking_datasource.dart`, `supabase_daily_booking_datasource.dart` |
| Models | `data/models/booking_option_model.dart` (`RouteOptionModel`, `RouteTripOptionModel`, `TripVehicleProfileModel`, `RoutePointModel`, `PopularRouteListModel`, `MapPinOptionModel`), `vehicle_detail_model.dart` |
| Entities | `domain/entities/booking_option.dart`, `booking_search_query.dart`, `booking_wizard_session.dart`, `search_options.dart`, `transport_office.dart`, `vehicle_detail.dart`, `daily_booking_data.dart` |
| Wizard → RPC mapping | `presentation/utils/wizard_booking_params.dart`, `presentation/widgets/payment/wizard_payment_mapping.dart` |
| Shared pricing | `lib/core/pricing/trip_stop_pair_price_mapper.dart`, `trip_pricing_resolver.dart`, `trip_stop_pair_price.dart` |

Routes (`presentation/routes/booking_routes.dart`): `search`, `routeSelection`, `popularRoutes`,
`mapSelection`, `routeMap`, `vehicleListing`, `vehicleDetails`, `dailyBooking`, `wizard`, `routeOverview`.

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| B1 | Search routes for a query | `GET operation_routes` + `GET route_stations` + `GET public_trips` (3 reads, scored in Dart) | anon | `GET /api/v1/search/routes` |
| B2 | Popular routes | `GET operation_routes` (+stations embed) + `GET public_trips` | anon | `GET /api/v1/routes?popular=true` |
| B3 | Search options (pickup/destination names, departure times) | 2× `GET route_stations` + `GET public_trips` | anon | `GET /api/v1/search/options` |
| B4 | Map pins (pickup / destination) | `GET route_stations` ×2 | anon | `GET /api/v1/search/map-pins?kind=pickup|destination` |
| B5 | Vehicle listing (bookable trips, optional route) | `GET public_trips` | anon | `GET /api/v1/trips?bookable=true&routeId=` |
| B6 | Vehicle detail (one trip) | `GET public_trips?id=eq.` | anon | `GET /api/v1/trips/{tripId}` |
| B7 | Daily booking hub data | `GET public_trips` + `GET operation_routes` | anon | (legacy — fold into B5/B3) |

---

## B1 — Route search: `getRoutes(query)` (`supabase_booking_search_datasource.dart:34-191`)

Input `BookingSearchQuery { routeId?, pickup, destination, date, time, initialPackageId? }`
(`domain/entities/booking_search_query.dart`). Only `routeId`, `pickup`, `destination` affect the
query; `date`/`time` are display-only today.

### Request 1 — active routes with their office

```
GET /rest/v1/operation_routes?select=*,office:public_offices(*)&status=eq.active[&id=eq.<routeId>]
```

Fields read: `id`, `name`, `start_city`, `end_city`, `distance`, `duration`, embedded `office`
(`TransportOffice.fromJson`: `id`, `name`, `logo_url`, `description`, `rating`, `ratings_count`,
`service_areas[]`; missing embed ⇒ `TransportOffice.unknown`).

### Request 2 — stations of those routes

```
GET /rest/v1/route_stations
  ?select=id,route_id,name,sort_order,latitude,longitude,pickup_allowed,dropoff_allowed,arrival_offset,departure_offset
  &route_id=in.(<id1>,<id2>,…)
  &order=sort_order.asc
```

→ `RoutePointModel { id, name, order=sort_order, pickupAllowed, dropoffAllowed, latitude, longitude, arrivalOffset, departureOffset }`.
If a route has no stations, two synthetic points are made from `start_city` (pickup only) and `end_city` (dropoff only).

### Request 3 — bookable trips of those routes, one round-trip (`_tripsByRouteId`, line 193)

```
GET /rest/v1/public_trips
  ?select=id,trip_date,departure_time,arrival_time,capacity,booked_seats,ticket_price,currency,status,route_id,
          drivers,vehicles,
          trip_pricing(from_point_id,to_point_id,one_time_price,currency,is_active,trip_package_prices(package_id,price,note)),
          trip_route_points(id,route_point_id),
          trip_seats(state)
  &route_id=in.(…)
  &status=eq.open_for_booking
  &trip_date=gte.<today>
```

Capped in Dart at **100 trips per route**. Per trip (`RouteTripOptionModel`):

| Field | From |
|---|---|
| `id`, `tripDate`, `departureTime` (default `'Not set'`), `arrivalTime` (default `'Not set'`) | trip |
| `availableSeats` | `count(trip_seats.state == 'available')` |
| `vehicleType` | `vehicles.vehicle_type` (jsonb from the view; default `'Standard'`) |
| `price` | cheapest positive of active `trip_pricing.one_time_price` and `ticket_price` → `"EGP 120"`, else `'Price pending'` |
| `stopPricing` | `tripStopPairPricesFromJson(trip_pricing, stationIds: routeStationIdsFromJson(trip_route_points))` — **translates `trip_pricing.from/to_point_id` (trip_route_points ids) into `route_stations` ids** so the wizard can match the rider's stop pair; each row carries `oneTimePrice`, `packagePrices{package_id→price}`, `packageNotes{package_id→note}`, `currency`, `isActive` |
| `vehicle` | `TripVehicleProfileModel.fromJson(vehicles, drivers)` — `brand, model, plate_number, vehicle_type, color, manufacture_year, capacity, seat_layout_type, features[], image_url` (**comma-joined string split into a list**), `rating, rating_count`; driver `full_name, profile_image_url, rating, rating_count` |

A trip is kept only if `BookableTrip.isBookable(trip) && hasPrice` (open, not past, ≥1 seat, a positive fare).
Routes with zero such trips are **dropped from results**.

### Scoring (Dart, lines 92-170) — reproduce server-side if search moves to the backend

For each route: best pickup match among `pickupAllowed` points, best destination match among
`dropoffAllowed` points, using `_textSimilarity` (exact = 1.0; substring either way = 0.8; token
overlap = 0.6 × shared/queryTokens; stop-words `of, the, and, egypt`; split on whitespace/comma/dot/dash).

* `matchQuality`: `exact` if `routeId` was given **or** both scores ≥ 0.75 and pickup order ≤ dropoff order; `partial` if both > 0 and ordered; else `suggested`.
* `relevance = (routeId given ? 100 : 0) + dest×1.2 + pickup + (bothMatched&&ordered ? 0.5 : 0)`.
* Sort: relevance desc, hasTrips first, availableSeats desc. **Return top 8.**
* Route aggregates: `availableSeats` = Σ seats left; `startingPrice` = cheapest fare label; `priceRange` = `"EGP min - max"` (or single value; `'Price pending'` when none).
* Displayed `pickup`/`destination` = the matched station name, else the query text, else `start_city`/`end_city`.

### Response shape (`RouteOptionData`)

```json
[{
  "id":"<route uuid>","routeName":"New Cairo - Obour","pickup":"New Cairo","destination":"Obour",
  "distance":"45 km","duration":"1h 10m","availableSeats":23,"startingPrice":"EGP 100","priceRange":"EGP 100 - 140",
  "matchQuality":"exact|partial|suggested",
  "office":{"id","name","logoUrl","description","rating","ratingsCount","serviceAreas":[]},
  "points":[{"id","name","order","pickupAllowed","dropoffAllowed","latitude","longitude","arrivalOffset","departureOffset"}],
  "availableTrips":[{
    "id","tripDate","departureTime","arrivalTime","availableSeats","vehicleType","price",
    "stopPricing":[{"fromPointId","toPointId","oneTimePrice","packagePrices":{},"packageNotes":{},"currency","isActive"}],
    "vehicle":{"brand","model","plateNumber","vehicleType","color","manufactureYear","capacity","seatLayoutType","features":[],"imageUrls":[],
               "vehicleRating","vehicleRatingCount","driverName","driverImageUrl","driverRating","driverRatingCount"}
  }]
}]
```

**Proposed .NET:** `GET /api/v1/search/routes?pickup=&destination=&routeId=&date=` returning the
shape above (server does the scoring, keeps `stopPricing` keyed by **station ids**). Limit 8.

---

## B2 — Popular routes: `getPopularRoutes()` (line 290)

```
GET /rest/v1/operation_routes?select=*,route_stations(name,sort_order),office:public_offices(*)&status=eq.active&limit=10
GET /rest/v1/public_trips?select=route_id,ticket_price,currency,status,trip_date,capacity,booked_seats,trip_pricing(one_time_price,currency,is_active),trip_seats(state)
    &route_id=in.(…)&status=eq.open_for_booking&trip_date=gte.<today>
```

→ `PopularRouteListModel { id, routeName (name or "<start> — <end>"), dailyTrips = count(bookable trips), averageDuration = duration, startingPrice, pickup = start_city, destination = end_city, distance, office }`.
Routes with `dailyTrips == 0` are dropped. Note the `limit=10` is on **routes**, not trips.

**Proposed .NET:** `GET /api/v1/routes?popular=true&limit=10`.

---

## B3 — Search options: `getSearchOptions()` (line 451)

```
GET /rest/v1/route_stations?select=name,operation_routes!inner(status)&operation_routes.status=eq.active&pickup_allowed=eq.true
GET /rest/v1/route_stations?select=name,operation_routes!inner(status)&operation_routes.status=eq.active&dropoff_allowed=eq.true
GET /rest/v1/public_trips?select=departure_time,status,trip_date,capacity,booked_seats,ticket_price,currency,trip_pricing(one_time_price,currency,is_active),trip_seats(state)
    &status=eq.open_for_booking&trip_date=gte.<today>
```

→ `TripSearchOptions { pickupPoints: distinct sorted names, destinations: distinct sorted names, departureTimes: distinct sorted "h:mm AM/PM" of bookable trips }`.

**Proposed .NET:** `GET /api/v1/search/options` → `{ pickupPoints:[], destinations:[], departureTimes:[] }`.

---

## B4 — Map pins: `getPickupMapPins()` / `getDestinationMapPins()` (lines 543 / 573)

```
GET /rest/v1/route_stations?select=name,latitude,longitude,operation_routes!inner(status)&operation_routes.status=eq.active&pickup_allowed=eq.true
GET /rest/v1/route_stations?select=name,latitude,longitude,operation_routes!inner(status)&operation_routes.status=eq.active&dropoff_allowed=eq.true
```

Rows without a valid non-zero coordinate are dropped; de-duplicated by name; sorted by label.
→ `MapPinOptionModel { label=name, subtitle='Pickup station'|'Destination station', x=latitude, y=longitude }`.

**Proposed .NET:** `GET /api/v1/search/map-pins?kind=pickup|destination`.

---

## B5 / B6 — Vehicle listing & detail (`supabase_vehicle_booking_datasource.dart`)

```
GET /rest/v1/public_trips?select=*,operation_routes(*),trip_pricing(*),trip_seats(state)&status=eq.open_for_booking&trip_date=gte.<today>[&route_id=eq.<routeId>]
GET /rest/v1/public_trips?select=*,operation_routes(*),trip_pricing(*),trip_seats(state)&id=eq.<tripId>      (maybeSingle)
```

Both keep only `BookableTrip.isBookable && hasPositivePrice`. Mapping (`_mapToModel`, line 71):
`name=vehicles.brand`, `model`, `vehicleType`, `hasAirConditioning = features contains 'AC'|'Air Conditioning'`,
`seatType=seat_layout_type`, `driverName`, `price = "<currency> <ticket_price ?? trip_pricing[0].one_time_price>"`,
`capacity=vehicles.capacity (default 14)`, `availableSeats`, `estimatedArrival=arrival_time`,
`routeDuration=operation_routes.duration`, `departureTime`, driver/vehicle `rating`/`rating_count`.

**Proposed .NET:** `GET /api/v1/trips?bookable=true&routeId=` and `GET /api/v1/trips/{tripId}`.

---

## B7 — Daily booking hub (`supabase_daily_booking_datasource.dart:12`)

```
GET /rest/v1/public_trips?select=*,trip_seats(state)&status=eq.open_for_booking&trip_date=gte.<today>
GET /rest/v1/operation_routes?select=start_city,end_city&status=eq.active
```

→ `DailyBookingData { pickupPoints, destinations, arrivalTimes (distinct sorted), vehicles:[{id, driver, time=departure_time, seatsLeft, occupancy}] }`.
Reachable via `BookingRoutes.dailyBooking`. Low value; consider retiring rather than porting.

---

## The wizard: session → RPC parameters (`presentation/utils/wizard_booking_params.dart`)

`BookingWizardConfirmCubit.confirm(session)` (`presentation/cubit/booking_wizard_confirm_cubit.dart:34`)
calls `PlaceSeatBookingUseCase` (new booking) or `UpdateExistingBookingPaymentUseCase` (retry on an
existing `bookingId`), then — for card — `StartCardCheckoutUseCase` and `AwaitCardSettlementUseCase`.

`wizardConfirmBookingParams(session)` produces the body of `confirm_seat_booking_v2`:

| RPC param | From the session |
|---|---|
| `p_trip_id` | `selectedTrip.id` |
| `p_seat_id`, `p_seat_label` | `selectedSeatId`, `selectedSeatLabel` |
| `p_pricing_id` | always `null` |
| `p_pickup_point_id`, `p_dropoff_point_id` | `pickupStop.id`, `dropoffStop.id` (**`route_stations` ids**; `null` for a map-picked stop with no id) |
| `p_route` | `"<pickup.name> → <dropoff.name>"` (stored label) |
| `p_trip_time`, `p_trip_date` | `selectedTrip.departureTime`, `selectedTrip.tripDate` |
| `p_payment_amount` | `session.totalPrice.round()` — **ignored by the server**, which re-resolves the fare |
| `p_pickup_point_name`, `p_dropoff_point_name` | stop names |
| `p_package_id` | `selectedPackage.id` |
| `p_plan_start_date` | `selectedTrip.tripDate` (`yyyy-MM-dd`) |
| `p_payment_method` | `session.paymentMethod ?? 'instapay'` — one of `credit_card`, `instapay`, `vodafone_cash`, `bank_transfer` (`wizardPaymentMethodId`) |
| `p_receipt_url`, `p_payment_reference`, `p_payer_phone` | receipt step outputs |
| `p_client_id`, `p_passenger_name`, `p_phone` | stamped by the datasource from the session user (`uid`, `metadata.full_name`, `metadata.phone`) |

`wizardUpdatePaymentParams(session)` = `{ p_booking_id, p_payment_method, p_receipt_url, p_payment_reference, p_payer_phone }`.

Client-side price shown to the rider (`BookingWizardSession.tripPrice` / `resolvedPackagePrice`)
mirrors the server's branch exactly: the `trip_pricing` row for the exact stop pair → `one_time_price`
for a single ride (`duration_days <= 1 && ride_count == 1`), else `trip_package_prices.price` for
that package; fallback to the package's catalogue `price`. See `seat_selection/` for the SQL.

`wizardMethodRequiresReceipt(method)` = every method except `credit_card`.

---

## Notes for the .NET team

1. **Three id spaces for a stop:** `route_stations.id` (what the rider picks), `trip_route_points.id`
   (the trip's snapshot; what `trip_pricing.from/to_point_id` use) and free-text names. The app
   translates snapshot→station ids for display and sends **station ids** to the booking RPC, which
   translates back. Keep one convention in the new API (recommend: station ids in, server resolves).
2. `vehicles.image_url` is a **comma-joined** string of URLs written by the dashboard's fleet form.
3. Search scoring is entirely client-side and unbounded on the number of active routes (3 reads,
   up to 100 trips/route). Moving it server-side is the main win.
4. `RETIRED` funnel: `features/payments/presentation/screens/payment_checkout_screen.dart` →
   `receipt_upload_screen.dart` → `payment_processing_screen.dart` is **not routed** anywhere; the
   wizard is the only live booking path. Do not port its parameter shape (it sends `mobile_wallet`
   and `wallet_balance`, which the RPC rejects).
