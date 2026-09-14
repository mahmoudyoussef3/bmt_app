# Client · My Trips (own bookings) & Trip Reviews

The "My Trips" tab: every booking the rider ever made, the Trip Details screen (booking + trip +
driver + vehicle + live seat map + the trip's stops), cancelling a booking before payment approval,
and rating a completed trip.

## Overview

| Layer | Files (relative to `lib/apps/client/features/trips/`) |
|---|---|
| Screens | `presentation/screens/my_trips_screen.dart` (`TripsRoutes.myTrips` = `/trips`), `trip_details_screen.dart` (`TripsRoutes.tripDetails` = `/trips/details`, argument `{tripId: <bookingId>}`), `full_screen_seat_map_screen.dart` |
| Cubits | `TripsCubit` (`presentation/cubit/trips_cubit.dart` — `loadTrips()`, `loadTripDetails(id)`, `refreshSelectedTrip(id)`, `cancelTrip(trip, reason)`, realtime refresh via `trips_realtime_refresher.dart`), `TripReviewCubit` (`load(trip)`, `submit()`, `retry()`) |
| Use cases | `GetTripsUseCase`, `GetTripDetailsUseCase`, `WatchTripsUseCase`, `CancelBookingUseCase`, `GetTripReviewUseCase`, `SubmitTripReviewUseCase` |
| Repos | `data/repositories/trips_repository_impl.dart`, `trip_reviews_repository_impl.dart` |
| **Datasources** | `data/datasources/supabase_trips_datasource.dart`, `supabase_trip_reviews_datasource.dart` |
| Mappers | `data/mappers/trip_mapper.dart`, `trip_status_mapper.dart`, `trip_seat_mapper.dart`, `trip_stop_mapper.dart`, `trip_review_mapper.dart`, `trip_review_failure_mapper.dart` |
| Models / entities | `data/models/trip_model.dart`, `trip_review_model.dart`; `domain/entities/trip.dart` (`TripData`), `trip_status.dart`, `trip_seat.dart`, `trip_stop.dart`, `trip_review.dart`, `trip_review_failure.dart` |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| T1 | List my bookings | `GET operation_bookings` (+ `public_trips`, `trip_reviews` embeds) | session | `GET /api/v1/me/bookings` |
| T2 | Booking detail | T1 filtered by id + `GET trip_seats` + `GET trip_route_points` | session | `GET /api/v1/me/bookings/{bookingId}` |
| T3 | Cancel my booking | `POST rpc/cancel_booking_by_client` | session | `POST /api/v1/bookings/{bookingId}/cancel` |
| T4 | Watch my bookings | Realtime `client_trips:<uid>` | session | `NEEDS BACKEND DECISION` |
| T5 | Read my review of a booking | `GET trip_reviews?booking_id=eq.` | session | `GET /api/v1/me/bookings/{bookingId}/review` |
| T6 | Submit a review | `POST rpc/submit_trip_review` | session | `POST /api/v1/bookings/{bookingId}/review` |

---

## T1 — My bookings: `getTrips()` (`supabase_trips_datasource.dart:30-42`)

```
GET /rest/v1/operation_bookings
  ?select=*,operation_trips:public_trips(*,office:public_offices(name)),trip_reviews(booking_id)
  &client_id=eq.<uid>
  &order=created_at.desc
```

No status filter and **no pagination** — the whole history. `RLS`: `bookings_client_read`.
The `trip_reviews(booking_id)` embed is RLS-narrowed to the caller's own reviews, so "embed non-empty" ⇒ already rated.

### Row → `TripModel` (`TripMapper.fromBookingRow`, `trip_mapper.dart`)

| Model field | Source |
|---|---|
| `id` | `id` (booking uuid) |
| `tripId` | `operation_trips.id` |
| `reference` | `booking_number`, else `BMT-<first 8 hex of id>` |
| `status` (`TripStatus`) | `TripStatusMapper.tripStatus(trip.status, booking.status)`: booking `cancelled` ⇒ `cancelled`; trip `scheduled|open_for_booking` ⇒ `upcoming`; `boarding|in_progress` ⇒ `inProgress`; `completed` ⇒ `completed`; `cancelled` ⇒ `cancelled`; default `upcoming` |
| `bookingState` (`BookingState`) | booking `status`: `confirmed|boarded|approved|paid` ⇒ `confirmed`; `completed` ⇒ `completed`; `cancelled|canceled|rejected` ⇒ `cancelled`; anything else (incl. `draft`, `reserved`) ⇒ `reserved` |
| `pickup`, `destination` | split of the free-text `route` on `→` (else ` - `) |
| `dateLabel`, `timeLabel` | `trip_date`, `trip_time` |
| `driverName`, `driverPhone` (`'Not available'` — the view never exposes it), `driverInitials`, `driverRating`, `driverRatingCount`, `driverPhotoUrl` | `operation_trips.drivers` jsonb: `full_name, rating, rating_count, profile_image_url` |
| `vehicleName=brand`, `vehicleType`, `vehicleId` (never present in the view ⇒ `''`), `vehiclePlate=plate_number`, `vehicleCode`, `vehicleModel`, `vehicleColor`, `vehicleYear=manufacture_year`, `vehicleSeatCapacity=capacity`, `vehicleSeatLayout=seat_layout_type`, `vehicleRating`, `vehicleRatingCount`, `vehicleImageUrls` (comma-joined `image_url` split) | `operation_trips.vehicles` jsonb |
| `seats` | `[seat]` when non-empty |
| `paymentStatus` (`PaymentStatus`) | `payment_status` (fallback `payment_details.status`, default `pending`): `paid|approved` ⇒ `paid`; `refunded`; `cancelled`; `rejected|failed` ⇒ `failed`; `underreview|under_review|submitted` ⇒ `underReview`; else `pending` |
| `fare` | `'EGP ' + payment_amount` (fallback `payment_details.amount`, `'0'`) |
| `officeName` | `operation_trips.office.name` |
| `isReviewed` | `trip_reviews` embed non-empty |
| `cancellationReason` | `cancellation_reason` ?? `payment_rejection_reason` ?? `rejection_reason` |

Columns of `operation_bookings` this feature relies on: `id, trip_id, client_id, booking_number, status,
payment_status, payment_amount, payment_details (jsonb, legacy), route, trip_date, trip_time, seat, seat_id,
pickup_point_id, dropoff_point_id, pickup_point_name, dropoff_point_name, cancellation_reason,
payment_rejection_reason, rejection_reason, created_at`.

**Proposed .NET:** `GET /api/v1/me/bookings?page=&pageSize=` → `[ BookingSummary ]` with the joined
trip/driver/vehicle/office facts and `isReviewed`. Recommend paging (today unbounded).

---

## T2 — Booking detail: `getTripById(bookingId)` (line 44-72)

```
GET /rest/v1/operation_bookings?select=<same as T1>&client_id=eq.<uid>&id=eq.<bookingId>&limit=1   (maybeSingle)
GET /rest/v1/trip_seats?select=seat_label,seat_row,seat_column,state&trip_id=eq.<tripId>&order=seat_row.asc,seat_column.asc
GET /rest/v1/trip_route_points?select=id,route_point_id,point_name,point_order,arrival_offset,departure_offset,latitude,longitude&trip_id=eq.<tripId>&order=point_order.asc
```

* Seat map (`TripSeatMapper`): `state: mine` when `seat_label == booking.seat` (case-insensitive), else `available` / `occupied`. Failure ⇒ empty list (never blocks the screen).
* Stops (`TripStopMapper.fromRows`): sorted by `point_order`; the rider's boarding/drop-off stop is matched **by id first** (`trip_route_points.route_point_id == booking.pickup_point_id`, a `route_stations` id) then by name; failure ⇒ no stops section.

**Proposed .NET:** `GET /api/v1/me/bookings/{bookingId}` → `BookingDetail { …summary…, seatMap:[{label,row,column,state}], stops:[{id,stationId,name,order,arrivalOffset,departureOffset,latitude,longitude,isBoarding,isDropoff}] }`.

---

## T3 — Cancel my booking: `cancelBooking(bookingId, reason)` (line 75-101)

```
POST /rest/v1/rpc/cancel_booking_by_client
{ "p_booking_id": "<uuid>", "p_reason": "<text>" }
→ 200 { "success":true, "booking_id":"…", "status":"cancelled", "seat_released":true }
      { "success":true, "booking_id":"…", "status":"cancelled", "already_cancelled":true }
```

**`BUSINESS RULE`** (`20260714100000_client_cancel_before_approval.sql:56-158`):

1. Booking exists (`booking_not_found`), row locked `FOR UPDATE`.
2. Caller is the booking's `client_id` (`not_authorized`).
3. Already `cancelled` ⇒ idempotent success.
4. **Refused once paid:** `payment_status = 'approved'` OR `status IN ('confirmed','boarded','completed')` ⇒ `booking_already_confirmed`.
5. Updates booking: `status='cancelled'`, `payment_status='cancelled'`, `payment_review_status='reviewed'`, `cancellation_reason`, `cancelled_at=now()`.
6. Marks non-approved `booking_payments` rows `cancelled` (removes it from the dashboard's review queue).
7. Releases the seat (`trip_seats` → `available`, clears passenger/lock/hold) **only if** `passenger_id = booking.client_id`.
8. Deletes the `trip_passengers` manifest row.
9. Notifies the client (`booking` category, title `تم إلغاء الحجز`) and raises an operational alert `booking_cancelled_by_client` for the dashboard.

**Errors the app maps** (`_cancelErrorMessage`): `booking_already_confirmed`, `not_authorized`, `booking_not_found`; anything else ⇒ generic.

**Proposed .NET:** `POST /api/v1/bookings/{bookingId}/cancel { reason }` → `200 { status, seatReleased, alreadyCancelled }`; `409 { code: booking_already_confirmed }`.

---

## T4 — Realtime: `watchTripChanges()` (line 165-196)

```
channel: client_trips:<uid>
postgres_changes: table=operation_bookings, event=*, filter=client_id=eq.<uid>
postgres_changes: table=trip_events,        event=*  (no filter)
```

Any event ⇒ `TripsCubit._refreshFromRealtime()` (refetch T1, or T2 for the open detail).

**Proposed .NET:** SignalR user group `bookings:<uid>` with a `booking-changed` event, or client polling of T1/T2 while the screen is visible.

---

## T5 — My review for a booking: `getReviewForBooking(bookingId)` (`supabase_trip_reviews_datasource.dart:22`)

Requires a signed-in user (else `TripReviewFailure.notAuthenticated` — the table grants `select` to `anon` for the dashboard queue, so an anonymous read would leak everyone's reviews).

```
GET /rest/v1/trip_reviews?select=booking_id,office_rating,driver_rating,vehicle_rating,route_rating,comment,created_at&booking_id=eq.<bookingId>   (maybeSingle)
```

→ `TripReviewModel { bookingId, officeRating, driverRating, vehicleRating, routeRating, comment, submittedAt=created_at }` or `null`.
`RLS`: `trip_reviews_client_read` (`client_id = auth.uid()`).

---

## T6 — Submit a review: `submitReview(review)` (line 50)

```
POST /rest/v1/rpc/submit_trip_review
{ "p_booking_id":"<uuid>", "p_office_rating":5, "p_driver_rating":4, "p_vehicle_rating":5, "p_route_rating":4, "p_comment":"…" }
→ 200 "<review uuid>"
```

**`BUSINESS RULE`** (`20260721090300_multi_office_rpcs.sql:428-515`): `not_authenticated`; every rating
`BETWEEN 1 AND 5` (`invalid_rating`); booking exists (`booking_not_found`) and is the caller's
(`not_authorized`); the **trip** status must be `completed` (`trip_not_completed`); inserts
`trip_reviews` with derived `client_id, trip_id, driver_id, vehicle_id, route_id, office_id` plus
denormalised `booking_number, client_name, driver_name, vehicle_name, route_label`;
`ON CONFLICT (booking_id) DO NOTHING` ⇒ `already_reviewed`. Triggers then recompute
`drivers.rating/rating_count`, `vehicles.rating/rating_count`, `offices.rating/ratings_count`
(these averages are public; individual reviews are dashboard-owner-only).

**Errors the app maps** (`TripReviewFailureMapper`): `trip_not_completed`, `booking_cancelled`, `not_authorized`,
`booking_not_found`, `invalid_rating`, `not_authenticated`; else `unknown`. (`already_reviewed` is raised by
SQL but currently falls into `unknown` — worth mapping in the port.)

**Proposed .NET:** `POST /api/v1/bookings/{bookingId}/review { officeRating, driverRating, vehicleRating, routeRating, comment }` → `201 { reviewId }`.

---

## Notes for the .NET team

1. `route` on a booking is a stored label (`"A → B"`); the detail screen prefers the point-name
   columns and the `trip_route_points` snapshot. Keep returning both.
2. Driver phone is intentionally **not** exposed to riders; the model's `'Not available'` is a placeholder.
3. `TripStatus` is derived from the **trip**, `BookingState` from the **booking**, `PaymentStatus` from
   `payment_status` — three independent axes. Return the raw statuses and let the app keep its mappers, or return all three.
4. The list is unbounded; add paging.
