# Client · Seat Selection — the booking write path

The seat map for one trip, and the three RPCs that create a booking:
**lock a seat → confirm the booking (with payment details) → (retry) update payment on an existing
booking**, plus the release RPC that hands back an unconfirmed lock. This is the most important
feature for the backend: every rule below is currently a SQL function body.

## Overview

| Layer | Files (relative to `lib/apps/client/features/seat_selection/`) |
|---|---|
| Screen | `presentation/screens/seat_selection_screen.dart` (also embedded as the wizard's seat step) |
| Cubit | `SeatSelectionCubit` (`presentation/cubit/seat_selection_cubit.dart`) |
| Use cases | `GetSeatSelectionDataUseCase`, `SelectSeatUseCase` (pure), `LockTripSeatUseCase`, `ReleaseTripSeatLockUseCase`, `ConfirmSeatBookingUseCase`, `UpdateExistingBookingPaymentUseCase`, **`PlaceSeatBookingUseCase`** (lock → confirm → release-on-failure), `BookTripSeatUseCase` (`RETIRED`) |
| Repo | `data/repositories/seat_selection_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_seat_selection_datasource.dart` |
| Model | `data/models/seat_selection_model.dart` (`SeatSelectionModel`, `SeatOptionModel`) |
| Caller of the write path | `features/booking/presentation/cubit/booking_wizard_confirm_cubit.dart` (params built by `features/booking/presentation/utils/wizard_booking_params.dart`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| S1 | Seat map + trip header | `GET trip_seats` + `GET public_trips` | anon | `GET /api/v1/trips/{tripId}/seats` |
| S2 | Lock a seat (5 min) | `POST rpc/lock_trip_seat` | session | `POST /api/v1/trips/{tripId}/seats/{seatId}/lock` |
| S3 | Release an unconfirmed lock | `POST rpc/release_trip_seat_lock` | session | `DELETE /api/v1/trips/{tripId}/seats/{seatId}/lock` |
| S4 | Confirm booking | `POST rpc/confirm_seat_booking_v2` | session | `POST /api/v1/bookings` |
| S5 | Update payment on an existing reserved booking | `POST rpc/update_existing_booking_payment` | session | `PATCH /api/v1/bookings/{bookingId}/payment` |
| S6 | Legacy one-shot booking | `POST rpc/book_trip_seat` | — | `RETIRED` — server function dropped |

---

## S1 — Seat map: `getSeatSelectionData(tripId)` (`supabase_seat_selection_datasource.dart:13-113`)

```
GET /rest/v1/trip_seats?select=id,seat_label,seat_row,seat_column,state&trip_id=eq.<tripId>&order=seat_row.asc,seat_column.asc
GET /rest/v1/public_trips?select=*,operation_routes(*),trip_pricing(*)&id=eq.<tripId>        (maybeSingle)
```

Rules applied in Dart: trip must exist (`'Trip details could not be found.'`); must satisfy
`BookableTrip.isOffered` (`'This trip is no longer open for booking.'`); must have ≥1 seat row
(`'No seats are registered for this trip. Please contact support.'`). A `PostgrestException`
becomes `'Could not load trip seats from the database.'`.

Response (`SeatSelectionModel`):

| Field | From |
|---|---|
| `seats[]` → `SeatOptionModel { id, seatNumber (digits of label, else index+1), availability: available if state=='available' else reserved, seatLabel, row=seat_row, column=seat_column }` | `trip_seats` |
| `pricePerSeat` | `ticket_price` (num) else `trip_pricing[0].one_time_price` else 0 |
| `pickupPoint`, `destination` | `operation_routes.start_city`, `end_city` |
| `vehicleNumber` (`plate_number` ?? `vehicle_code`), `vehicleName=brand`, `vehicleType`, `vehicleModel`, `vehicleImageUrl` | `vehicles` jsonb |
| `tripDate`, `departureTime`, `arrivalTime` | trip |
| `driverName=full_name`, `driverRating`, `driverImageUrl=profile_image_url` | `drivers` jsonb |

`RLS`: `trip_seats` marketplace read is keyed on the trip's office being listed (see
`20260727160000_trip_lifecycle_authority.sql` — scheduled trips' seats were closed to anon).

**Proposed .NET:** `GET /api/v1/trips/{tripId}/seats` → `{ trip:{…header…}, seats:[{id,label,row,column,state}] }`.
`state` should stay the raw `available|reserved|paid` so the client can keep its own mapping.

---

## S2 — Lock a seat: `lockTripSeat()` (line 116)

```
POST /rest/v1/rpc/lock_trip_seat
{ "p_trip_id": "<uuid>", "p_seat_id": "<uuid>", "p_client_id": "<uid>" }
→ 200 { "success": true, "seat_id": "<uuid>", "lock_expires_at": "<timestamptz>" }
```

**`BUSINESS RULE`** (`20260727160000_trip_lifecycle_authority.sql:812-878`):

1. `trip_is_bookable(p_trip_id)` = `status = 'open_for_booking' AND trip_date >= current_date`, else `trip_not_bookable`.
2. Caller must not already hold a booking on this trip with `status IN ('reserved','confirmed')`, else `duplicate_active_booking`.
3. Lock TTL = **5 minutes** (`now() + interval '5 minutes'`).
4. Single atomic `UPDATE trip_seats SET state='reserved', passenger_id=p_client_id, lock_expires_at=… WHERE id=p_seat_id AND trip_id=p_trip_id AND (state='available' OR (state='reserved' AND lock_expires_at < now() AND no non-cancelled booking references the seat))` — the self-healing branch reclaims expired orphan locks.
5. 0 rows updated ⇒ `seat_unavailable`.

Note: the SQL does **not** check `auth.uid() = p_client_id` (the confirm step does). `NEEDS BACKEND DECISION`: derive the client id from the token, never from the body.

**Errors the app maps:** `seat_unavailable`, `duplicate_active_booking` (others rethrown; message also contains `trip_not_bookable`).

**Proposed .NET:** `POST /api/v1/trips/{tripId}/seats/{seatId}/lock` → `200 { seatId, lockExpiresAt }`;
`409 { code: seat_unavailable | duplicate_active_booking | trip_not_bookable }`.

---

## S3 — Release a lock: `releaseTripSeatLock()` (line 145)

Called by `PlaceSeatBookingUseCase` when confirm throws, so a failed checkout never strands a seat.

```
POST /rest/v1/rpc/release_trip_seat_lock
{ "p_trip_id", "p_seat_id", "p_client_id" }
→ 200 { "success": true, "released": true|false }
```

**`BUSINESS RULE`** (`20260714090000_fix_orphan_seat_locks.sql:96-128`): sets the seat back to
`available` (clears `passenger_id`, `lock_expires_at`, `held_at`, `hold_expires_at`) **only if**
`state='reserved' AND passenger_id=p_client_id AND hold_expires_at IS NULL AND no non-cancelled
booking references the seat`. A seat that already has a booking is untouched. Errors are swallowed by the app.

**Proposed .NET:** `DELETE /api/v1/trips/{tripId}/seats/{seatId}/lock` → `200 { released }` (idempotent, never fails the caller).

---

## S4 — Confirm the booking: `confirmSeatBooking(params)` (line 167)

The datasource stamps `p_client_id = uid`, `p_passenger_name = params.p_passenger_name || metadata.full_name`,
`p_phone = params.p_phone || metadata.phone`.

```
POST /rest/v1/rpc/confirm_seat_booking_v2
{
  "p_client_id":"<uid>", "p_trip_id":"<uuid>", "p_seat_id":"<uuid>", "p_seat_label":"A3",
  "p_pricing_id": null,
  "p_pickup_point_id":"<route_stations id|null>", "p_dropoff_point_id":"<route_stations id|null>",
  "p_pickup_point_name":"New Cairo", "p_dropoff_point_name":"Obour",
  "p_passenger_name":"…", "p_phone":"…",
  "p_route":"New Cairo → Obour", "p_trip_time":"07:00:00", "p_trip_date":"2026-09-20",
  "p_payment_method":"instapay|vodafone_cash|bank_transfer|credit_card",
  "p_payment_amount": 120,                       // ignored server-side
  "p_package_id":"<uuid>", "p_plan_start_date":"2026-09-20",
  "p_receipt_url":"<signed url|null>", "p_payment_reference":"<text|null>", "p_payer_phone":"<text|null>",
  "p_subscription_id": null                      // not sent by the wizard today
}
→ 200 { "success":true, "booking_id":"<uuid>", "booking_number":"BK-1A2B3C4D", "trip_id":"<uuid>",
        "seat_label":"A3", "payment_amount":120, "status":"reserved|confirmed" }
```

The app reads only `booking_id` and `booking_number` (`WizardBookingRecord.fromRpc`).

**`BUSINESS RULE`** — `confirm_seat_booking_v2` (`20260820100000_trip_scoped_packages.sql:105-397`), in order:

1. `auth.uid()` must equal `p_client_id` → `not_authorized`.
2. `p_payment_method IN ('credit_card','instapay','vodafone_cash','bank_transfer')` → `payment_method_not_allowed`.
3. Non-card, non-subscription bookings require a non-empty `p_receipt_url` → `payment_receipt_required`.
4. Trip row locked `FOR SHARE`; `status` must be `open_for_booking` → `trip_not_available`.
5. **Fare is resolved server-side; `p_payment_amount` is never used.**
   * If `p_subscription_id` given: `transport_subscriptions` row must be the caller's, `active`, `remaining_rides > 0`, not expired → else `subscription_not_usable`; amount = 0.
   * Else: `transport_packages` row `p_package_id` must be `active` and either a catalogue package (`trip_id IS NULL`) or a package created for this trip (`trip_id = p_trip_id`) → else `package_not_available`.
     Translate `p_pickup_point_id`/`p_dropoff_point_id` (station ids) to this trip's `trip_route_points.id`; find the active `trip_pricing` row for that pair (accepts either id space via `coalesce`).
     If found: single-ride package (`duration_days <= 1 AND ride_count = 1`) ⇒ `one_time_price`; otherwise `trip_package_prices.price` for `(trip_pricing_id, package_id)`.
     If no positive amount ⇒ fall back to `transport_packages.price`.
   * `amount IS NULL OR < 0` → `fare_unavailable`.
6. No existing booking by this client on this trip with status `reserved|confirmed` → `duplicate_active_booking`.
7. Seat row locked `FOR UPDATE`; must exist (`seat_not_found`), be `reserved` **by this client** (`seat_unavailable`), and `lock_expires_at > now()` (`lock_expired`).
8. `booking_number = 'BK-' || upper(first 8 hex of a uuid)`.
9. `INSERT operation_bookings` with: `status = 'confirmed'` (subscription) or `'reserved'`; `payment_status = 'approved'` (subscription) / `'pending'` (card) / `'submitted'` (receipt); `payment_review_status = 'reviewed'` / `'pending'`; `payment_amount = resolved amount`; `created_by_source='client'`; `plan_start_date = coalesce(p_plan_start_date, trip_date)`, `plan_end_date = plan_start_date + (duration_days - 1)`; `trip_date = coalesce(p_trip_date, trip.trip_date)`.
10. Subscription branch: decrement `remaining_rides` (status → `exhausted` at 0), seat → `paid`, insert `trip_passengers` (status `reserved`), notify client `booking_received`.
11. Money branch: insert `booking_payments(method, amount, status pending|submitted, receipt_url, payment_reference, payer_phone)`; seat gets `held_at=now()`, **`hold_expires_at = now() + 30 minutes`**, `lock_expires_at = NULL`; notify operators (`user_roles` in `operations_manager|dashboard_admin`) `payment_review` for non-card; notify client `booking_received`.
12. `unique_violation` ⇒ `seat_or_booking_already_exists`.

**Errors the app maps:** `lock_expired` → `'lock_expired'`; `seat_not_locked` | `seat_locked_by_other` → `'seat_unavailable'`; `trip_full` → `'trip_full'`; anything else rethrown with the raw message (the wizard shows it). All the codes above must be preserved.

**Proposed .NET:** `POST /api/v1/bookings` with the same fields (camelCase; drop `clientId`, `passengerName`, `phone` — derive from the identity; drop `paymentAmount`) → `201 { bookingId, bookingNumber, tripId, seatLabel, paymentAmount, status }`.
`409/422 { code }` with the exact codes listed.

---

## S5 — Retry payment on an existing booking: `updateExistingBookingPayment()` (line 218)

Used when a first attempt failed (e.g. card declined) and the wizard still holds `bookingId`.

```
POST /rest/v1/rpc/update_existing_booking_payment
{ "p_booking_id":"<uuid>", "p_payment_method":"instapay", "p_receipt_url":"…", "p_payment_reference":"…", "p_payer_phone":"…" }
→ 200 { "booking_id":"<uuid>", "booking_number":"BK-…" }
```

**`BUSINESS RULE`** (`20260706153000_update_existing_booking_payment.sql`): caller signed in
(`not_authorized`); method in the allowed set (`payment_method_not_allowed`); receipt required for
non-card (`payment_receipt_required`); booking exists (`booking_not_found`), belongs to caller
(`not_authorized`), and `status = 'reserved'` (`booking_not_reserved`). Updates
`payment_method`, `payment_receipt_url`, `payment_status` (`pending` card / `submitted` else),
`payment_review_status='pending'`; inserts a new `booking_payments` row with the booking's stored amount.

**Proposed .NET:** `PATCH /api/v1/bookings/{bookingId}/payment`.

---

## S6 — `book_trip_seat` — `RETIRED`

`SupabaseSeatSelectionDatasource.bookTripSeat` (line 206) and `BookTripSeatUseCase` still exist and are
registered in DI, but the 16-arg `public.book_trip_seat` was **dropped** in
`20260730090000_client_trust_hardening.sql:171`. Nothing calls the use case. Do not port.

---

## Seat state machine (what the backend must own)

```
available ──lock_trip_seat──▶ reserved (lock_expires_at = +5m, passenger_id)
reserved ──lock expires / release_trip_seat_lock──▶ available
reserved ──confirm (money)──▶ reserved (held_at, hold_expires_at = +30m, lock_expires_at = null) + booking(status reserved)
reserved ──confirm (subscription)──▶ paid + booking(status confirmed)
reserved (held) ──operator approves payment / Paymob callback──▶ paid + booking(confirmed)      [dashboard / payments]
reserved (held) ──cancel_booking_by_client / operator rejects──▶ available                        [trips]
```

**Hold expiry (`BUSINESS RULE`, server-scheduled):** a pg_cron job `release-expired-booking-seat-holds` runs `release_expired_seat_holds()` **every minute** (`20260704000000_production_booking_flow_hardening.sql:570`, body in `20260706110000_fix_booking_status_vocabulary.sql:411`). It cancels every `reserved` booking whose seat has `hold_expires_at <= now()` **and** whose payment is still `pending` (i.e. a card checkout never completed): booking → `status='cancelled'`, `payment_status='rejected'`, `payment_rejection_reason='انتهت مهلة حجز المقعد'`; seat → `available`. A receipt-based booking (`payment_status='submitted'`) is **not** auto-expired — it waits for the operator. The .NET port needs an equivalent background job.

## Notes for the .NET team

1. The `p_client_id`/`p_passenger_name`/`p_phone` body fields exist because SQL had no other way to
   read the caller's profile; in .NET take them from the identity.
2. The lock RPC trusts `p_client_id` from the body. Fix in the port.
3. Keep the two-step lock/confirm shape: the wizard shows a 5-minute countdown from `lock_expires_at`.
4. `p_pricing_id` is always null; the server picks the `trip_pricing` row itself. It can be dropped.
5. `p_subscription_id` is supported by the RPC but never sent by the app today.
