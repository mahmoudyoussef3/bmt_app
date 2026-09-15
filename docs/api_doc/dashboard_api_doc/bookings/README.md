# Dashboard · Bookings (الحجوزات + مراجعة المدفوعات)

The office's booking queue board: every booking of the office (newest 2 000), a payment-review
queue (receipts to approve/reject/ask to re-upload), bulk review, moving a passenger to another
trip, free-text notes, realtime refresh, and a CSV export. The old «مراجعة المدفوعات» route
(`/payment-verification`) opens this same module preset to the *needs review* tab.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/bookings/`) |
|---|---|
| Screen | `presentation/screens/bookings_screen.dart` (`DashboardRoutes.bookings` = `/bookings`, `DashboardRoutes.paymentVerification` = `/payment-verification` → same screen, `presetTab: needsReview`) |
| Cubit | `presentation/cubit/bookings_cubit.dart` — `load()`, `switchTab()`, `sortBy()`, `goToPage()`, `updateFilters()`, `approveBooking()`, `rejectBooking()`, `requestReupload()`, `addNote()`, `reassignBooking()`, `bulkApprove()`, `bulkReject()`, `exportBookings()` |
| Use cases | `domain/usecases/` (`GetOperationBookingsUseCase`, `ApproveBookingUseCase`, `RejectBookingUseCase`, `RequestReuploadUseCase`, `AddBookingNoteUseCase`, `ReassignBookingUseCase`, `GetReassignmentTargetsUseCase`, `WatchBookingsUseCase`, `BulkApprove/RejectUseCase`, `ExportBookingsUseCase`) |
| Repo | `data/repositories/bookings_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_bookings_datasource.dart` (`SupabaseBookingsDatasource implements BookingsDatasource`) |
| Export | `data/services/bookings_csv_export_service.dart` (calls `LicensedExport.consume('csv')` first) |
| Model / entity | `data/models/operation_booking_model.dart` (`OperationBookingModel.columns`), `domain/entities/operation_booking.dart` (`BookingStatus`, `PaymentStatus`, `BookingPaymentMethod`, `BookingTripDetails`, `BookingTimelineEvent`), `domain/entities/reassignment_target.dart` |
| Permission | `DashboardPermission.bookings` (both roles), `paymentVerification` (both roles); feature key `bookings` |

## Operations

| # | Operation | Today (Supabase) | Role | Proposed .NET |
|---|---|---|---|---|
| B1 | List bookings (newest 2 000) | `GET operation_bookings?select=<embed>&order=created_at.desc&limit=2000` | both | `GET /api/v1/dashboard/bookings` |
| B2 | Re-read one booking | `GET operation_bookings?id=eq.&select=<embed>` (`.single()`) | both | `GET /api/v1/dashboard/bookings/{id}` |
| B3 | Approve payment | `POST rpc/office_approve_payment` | both* | `POST /api/v1/dashboard/bookings/{id}/approve-payment` |
| B4 | Reject payment | `POST rpc/office_reject_payment` | both* | `POST /api/v1/dashboard/bookings/{id}/reject-payment` |
| B5 | Ask for re-upload / review | `POST rpc/office_request_payment_review` | both* | `POST /api/v1/dashboard/bookings/{id}/request-review` |
| B6 | Bulk approve / reject | B3/B4 in a **sequential loop** | both* | same endpoints (or a batch endpoint) |
| B7 | Reassignment targets | `GET operation_trips?select=id,trip_date,departure_time,operation_routes(name)&status=in.(scheduled,open_for_booking)&trip_date=gte.<today>&limit=100` | both | `GET /api/v1/dashboard/bookings/reassignment-targets` |
| B8 | Reassign booking to another trip | `POST rpc/office_reassign_booking` | both* | `POST /api/v1/dashboard/bookings/{id}/reassign` |
| B9 | Add note | `GET notes` → `PATCH operation_bookings` (read-modify-write) | both | `POST /api/v1/dashboard/bookings/{id}/notes` |
| B10 | Live refresh | Realtime `.stream()` on `operation_bookings` → re-run B1 | both | WebSocket/SSE `bookings.changed` for the office |
| B11 | Export CSV | `POST rpc/office_consume_export {p_kind:'csv'}` then file built in Dart | both | `POST /api/v1/dashboard/exports` |

\* Server-side today the review RPCs only require "is an active office user of the owning office"
(`is_admin()` = any active `office_users` row); the UI additionally hides review actions behind
`DashboardPermission.paymentVerification`, which both roles hold.

Every error passes `LicensingGuard.check()` first (licensing codes → `LicensingFailure`), then a
`PostgrestException` becomes `'خطأ بقاعدة البيانات: <message> (<code>)'`.

---

## B1 — List: `fetchBookings()` (`supabase_bookings_datasource.dart:27`)

```
GET /rest/v1/operation_bookings
  ?select=id,booking_number,client_id,passenger_name,phone,route,trip_time,trip_date,seat,
          payment_method,status,payment_status,payment_amount,payment_receipt_url,
          payment_rejection_reason,reviewed_at,created_at,notes,
          package:transport_packages(name_ar,name_en),
          trip:operation_trips(id,trip_date,departure_time,
               route:operation_routes(name),driver:drivers(full_name),vehicle:vehicles(plate_number))
  &order=created_at.desc
  &limit=2000
```

No office filter in the query — `RLS` `bookings_office_manage` (`20260721090200_multi_office_rls.sql:266`,
`office_id = current_office_id()`) scopes it. `SUPABASE-SPECIFIC`: the three-level embed.

Row → `OperationBookingModel.fromJson` (`operation_booking_model.dart:45`):

| Entity field | Source | Notes |
|---|---|---|
| `id, bookingNumber, clientId, passengerName ('غير معروف'), phone, route, tripTime, date=trip_date, seat` | top-level columns | strings, defaults `''` |
| `paymentMethod` | `payment_method` | `bank_transfer|bankTransfer → bankTransfer`, `vodafone_cash|vodafoneCash`, `instapay|instaPay`, `credit_card|card → card`, anything else → `cash` |
| `status` | `status` | `draft|reserved|confirmed|boarded|completed|cancelled` (default `draft`) |
| `paymentStatus` | `payment_status` | `pending|submitted|underReview|approved|rejected|refunded|failed|cancelled` (default `pending`) — **note the camelCase `underReview` literal in the DB** |
| `paymentAmount` | `payment_amount` | num → double |
| `packageName` | `package.name_ar` ?? `package.name_en` ?? `''` | |
| `receiptUrl, rejectionReason (blank→null), reviewedAt, createdAt` | columns | |
| `tripDetails { tripId, route, date, time, vehicle, driver }` | `trip.*` embed; falls back to the denormalised `route/trip_date/trip_time` columns | |
| `notes` | `notes` jsonb array of strings, newest first | |
| `timeline` | **derived in Dart** from `created_at`, `reviewed_at`, status, payment status, rejection reason | not a stored audit trail |

Everything else is Dart-side: queue tabs (`needsReview` = `payment_status in (submitted, underReview)`;
`all`; one per `BookingStatus`), filters (search, route, date, payment method, payment status), sort,
paging, KPI counts, `capReached` when exactly 2 000 rows came back.

**Proposed .NET:** `GET /api/v1/dashboard/bookings?tab=&status=&paymentStatus=&paymentMethod=&route=&date=&search=&sort=&page=&pageSize=`
returning the flattened row above + `tripDetails` + `packageName`. Server-side paging replaces the cap.

---

## B2 — Refetch: `_refetch(bookingId)` (line 261)

Same select with `&id=eq.<bookingId>`, `Accept: application/vnd.pgrst.object+json`. Called after every
mutation so the row on screen is the server's truth (the RPC payloads are not used for state).

---

## B3 — Approve payment: `approveBooking(bookingId, note)` (line 44)

```
POST /rest/v1/rpc/office_approve_payment
{ "p_booking_id": "<uuid>", "p_note": "<trimmed note or ''>" }
→ 200 { "success": true, "booking_id": "<uuid>", "status": "confirmed" }
```

`BUSINESS RULE` — wrapper `office_approve_payment` (`20260721090300_multi_office_rpcs.sql:111`) →
`assert_office_owns_booking` (`not_an_office_user` / `booking_not_found` / `cross_office_denied`) →
`approve_payment(p_booking_id, p_note)` (latest: `20260802090000_subscription_office_attribution.sql`):

1. `not_authorized` unless caller is an active office user (`is_admin()`).
2. Locks the booking `FOR UPDATE`; `booking_not_found`; `booking_not_pending` unless `status = 'reserved'`.
3. `payment_not_submitted` unless a `booking_payments` row is `submitted` or `under_review`.
4. If the booking's package has `ride_count > 1`: inserts `transport_subscriptions` (ride ledger,
   `remaining_rides = ride_count − 1`) **and** mirrors into `subscriptions` (`status:'active'`,
   `total_price = paid_amount = booking.payment_amount`, `trips_count = ride_count`, `trips_used = 1`,
   `payment_review_status:'accepted'`, links `route_id/origin_trip_id/origin_booking_id`).
5. Booking → `status:'confirmed'`, `payment_status:'approved'`, `payment_review_status:'reviewed'`,
   `reviewed_by = auth.uid()`, `reviewed_at = now()`, `subscription_id`, note **prepended** to `notes`.
6. `booking_payments` → `approved`.
7. `trip_seats` → `state:'paid'` for the booking's seat (`seat_hold_not_found` if the hold is gone).
8. Inserts the `trip_passengers` manifest row (`status:'reserved'`, pickup/dropoff copied from the booking).
9. Inserts a client `notifications` row (`type:'payment_approved'`, `category:'payment'`, data `{booking_id, trip_id}`).

The raw `approve_payment` is revoked from `authenticated`; only the `office_` wrapper is callable.

**Proposed .NET:** `POST /api/v1/dashboard/bookings/{id}/approve-payment { note? }` → `200 Booking`. Keep
steps 2–9 in **one transaction**, keep the machine codes.

---

## B4 — Reject payment: `rejectBooking(bookingId, reason)` (line 60)

```
POST /rest/v1/rpc/office_reject_payment
{ "p_booking_id": "<uuid>", "p_reason": "<trimmed, required>" }
→ 200 { "success": true, "booking_id": "<uuid>", "status": "cancelled" }
```

`BUSINESS RULE` — `reject_payment` (`20260706120000_dashboard_approve_auth.sql`): `rejection_reason_required`;
`booking_not_pending` unless `reserved`; booking → `status:'cancelled'`, `payment_status:'rejected'`,
`payment_rejection_reason`, `reviewed_by/at`; `booking_payments` → `rejected`; seat → `available`
(`passenger_id null`, hold/lock cleared); `trip_passengers` row deleted; client notification
`payment_rejected` with the reason in the body.

**Proposed .NET:** `POST /api/v1/dashboard/bookings/{id}/reject-payment { reason }` (reason required, 422 otherwise).

---

## B5 — Request review / re-upload: `requestReupload(bookingId, reason)` (line 76)

```
POST /rest/v1/rpc/office_request_payment_review
{ "p_booking_id": "<uuid>", "p_note": "<trimmed>" }
→ 200 { "success": true, "booking_id": "<uuid>", "status": "under_review" }
```

`BUSINESS RULE` — `request_payment_review`: booking must be `reserved` (`booking_not_pending`);
sets `payment_status = 'underReview'` (camelCase literal), `payment_review_status = 'under_review'`,
prepends the note; `booking_payments.status = 'under_review'`; client notification
`payment_review_requested` (body = note or a default sentence). The booking stays `reserved`.

**Proposed .NET:** `POST /api/v1/dashboard/bookings/{id}/request-review { note }`.

---

## B6 — Bulk: `bulkApprove(ids, note)` / `bulkReject(ids, reason)` (lines 92/104)

A **sequential** loop over B3/B4 — one RPC per booking, no transaction across them; a failure mid-way
leaves the earlier ones done. `NEEDS BACKEND DECISION`: offer `POST /api/v1/dashboard/bookings/bulk-review
{ ids[], action, note }` with per-item results, or keep it client-driven.

---

## B7 — Reassignment targets: `fetchReassignmentTargets()` (line 116)

```
GET /rest/v1/operation_trips?select=id,trip_date,departure_time,operation_routes(name)
  &status=in.(scheduled,open_for_booking)&trip_date=gte.<yyyy-MM-dd today, device local>
  &order=trip_date.asc,departure_time.asc&limit=100
```
→ `ReassignmentTarget { tripId, routeName ('مسار غير معروف'), tripDate, departureTime }`.
Office-scoped by `operation_trips` RLS. **Proposed .NET:** `GET /api/v1/dashboard/bookings/reassignment-targets?fromDate=`.

---

## B8 — Reassign: `reassignBooking(bookingId, newTripId)` (line 143)

```
POST /rest/v1/rpc/office_reassign_booking
{ "p_booking_id": "<uuid>", "p_new_trip_id": "<uuid>" }          (p_new_seat_label not sent → first free seat)
→ 200 { "success": true, "new_trip_id": "<uuid>", "new_seat_id": "<uuid>" }
```

`BUSINESS RULE` — wrapper asserts the office owns **both** the booking and the target trip
(`cross_office_reassignment_denied`), then `reassign_booking` (`20260728090000_fleet_authority.sql`):
`booking_not_found`, `same_trip`, `trip_full` (no `available` seat on target); old seat → `available`
(cleared); new seat = requested label (`seat_unavailable` if not free) or first `available` by
`seat_row, seat_column`, set to `state:'paid'` **regardless of whether the booking was paid**; booking
`trip_id/seat_id/seat` updated + `timeline` jsonb appended `{action:'reassigned', actor:'operations'}`;
`trip_passengers` moved. Note: it does **not** re-price, does not check the target route matches, and
does not notify the rider — the UI (`OperationBooking.canReassign`) restricts it to bookings that are
not cancelled/completed.

**Proposed .NET:** `POST /api/v1/dashboard/bookings/{id}/reassign { newTripId, seatLabel? }` → `200 Booking`.
Decide whether the moved seat should keep the *original* seat state instead of always `paid`.

---

## B9 — Add note: `addNote(bookingId, note)` (line 234)

```
GET   /rest/v1/operation_bookings?select=notes&id=eq.<id>            (.single())
PATCH /rest/v1/operation_bookings?id=eq.<id>
{ "notes": ["<new note>", ...existing], "updated_at": "<utc iso>" }
```

The only direct table write in the module and a read-modify-write race (two operators within the same
second can lose a note). Allowed by `bookings_office_manage` (`FOR ALL`). `NEEDS BACKEND DECISION`:
`POST /api/v1/dashboard/bookings/{id}/notes { text }` that **appends server-side** (prepend order is what
the UI shows: newest first).

---

## B10 — Realtime: `watchBookings()` (line 164)

`SUPABASE-SPECIFIC` — `.from('operation_bookings').stream(primaryKey:['id'])` (an unfiltered CDC stream,
RLS-scoped to the office). Any event → debounce 400 ms → re-run B1 (never more than one in flight; a
change during a read schedules exactly one more). Rows carried by the stream are ignored — only the
enriched select is trusted.

**Proposed .NET:** a per-office channel that emits `bookings.changed { bookingId }`; the client re-fetches.

---

## B11 — Export: `BookingsCsvExportService` → `LicensedExport.consume('csv')`

```
POST /rest/v1/rpc/office_consume_export   { "p_kind": "csv" }
→ 200 { allowed, used, limit, remaining, ... }        (verdict of max_exports_per_month)
```
then the CSV of the **currently filtered tab** is built in Dart. Errors: the six licensing codes
(`feature_not_licensed`, `quota_exceeded`, …) — see `../README.md` §1.3. `csv` maps to feature
`export_excel`. **Proposed .NET:** `POST /api/v1/dashboard/exports { kind:'bookings', format:'csv', filters }`
that meters and returns the file (or keep the meter-only call + client-side file).

---

## Notes for the .NET team

1. **The office is never in the request.** B1/B7 rely on RLS; B3–B8 rely on `assert_office_owns_*`. The
   token's office must do both jobs.
2. The review RPCs are `is_admin()`-gated (= any active office user), not admin-role-gated. If you want
   support agents to review payments (today they can), keep it that way; it is a product decision.
3. `payment_status` uses the literal `underReview` (camelCase) while `booking_payments.status` uses
   `under_review`. Keep both spellings or migrate both readers (client app reads the same column).
4. Approval creates the subscription mirror; **there is no "un-approve"**. Refunds live in `wallet/`.
5. `notes` is a JSON array of strings, newest first; the model also derives a timeline from timestamps —
   a real `booking_events` table would replace both.
6. Every list load is a 2 000-row window. The screen shows a notice when the cap is hit; the fix is
   server paging with server tallies.
