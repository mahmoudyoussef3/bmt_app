# Entity Operational Lifecycle Document

> **Scope:** Dashboard App · Client App · Driver (Captain) App · Supabase Backend  
> **Authority:** Dashboard is the source of truth for all lifecycle transitions unless noted.  
> **Notation:** `actor → action → side effects` · `●` = realtime event · `✦` = DB write · `✸` = push notification

---

## Reading This Document

Each entity section follows the same structure:

1. **Status Registry** — every possible status value, its DB enum string, Arabic label, and what it means operationally
2. **Transition Graph** — legal state machine: from → to, who triggers it, the mechanism, and side effects
3. **Illegal Transitions** — explicit list of forbidden moves with reasons
4. **Permission Matrix** — which role can read / write / delete each status
5. **Realtime Requirements** — which events must broadcast and to which subscribers
6. **Dashboard Actions** — what the operations UI must expose per status
7. **Client App Visibility** — what the passenger sees and can do per entity status
8. **Driver App Visibility** — what the captain sees and can do per entity status
9. **Invariants** — business rules that must never be violated regardless of who triggers the transition

---

---

# ENTITY 1 — ROUTE

**Table:** `routes`  
**Owner:** Dashboard (Admin / Operations Manager)  
**Purpose:** A templated geographical path from a start city to an end city with ordered stations. Routes are reusable templates; they do not expire. Trips are scheduled instances of a route.

---

## 1.1 Status Registry

| Status | DB Value | Arabic | Meaning |
|--------|----------|--------|---------|
| `draft` | `draft` | مسودة | Route is being configured. No trips can be created from it. Not visible to clients. |
| `active` | `active` | نشط | Route is live. Trips can be scheduled from it. Visible to clients. |
| `paused` | `paused` | متوقف | Temporarily suspended. No new trips allowed. Existing trips run to completion. Client cannot discover route. |
| `archived` | `archived` | مؤرشف | Permanently retired. No trips ever again. Read-only. Soft-deleted. |

---

## 1.2 Transition Graph

```
[draft] ──(publish)──→ [active]
[active] ──(pause)───→ [paused]
[paused] ──(resume)──→ [active]
[active] ──(archive)─→ [archived]
[paused] ──(archive)─→ [archived]
[draft]  ──(archive)─→ [archived]
```

### draft → active
- **Actor:** Admin / Operations Manager (Dashboard)
- **Trigger:** "نشر المسار" button in route detail
- **Preconditions:** Route must have ≥ 2 stations. At least 1 station with `pickup_allowed = true`. At least 1 station with `dropoff_allowed = true`. Start and end city must be set.
- **Mechanism:** `UPDATE routes SET status = 'active' WHERE id = ?`
- **Side Effects:**
  - ● Realtime broadcast `route.published` to Dashboard subscribers
  - Client App route search index refreshes (next query picks up new route)

### active → paused
- **Actor:** Admin (Dashboard)
- **Trigger:** "إيقاف مؤقت" in route actions menu
- **Preconditions:** No in-progress trips using this route right now (trips in `boarding` or `in_progress` must complete first).
- **Mechanism:** `UPDATE routes SET status = 'paused'`
- **Side Effects:**
  - All `scheduled` trips on this route remain scheduled (they continue to completion)
  - ● Realtime `route.paused` to Dashboard
  - Client App hides route from search results immediately
  - Passengers with existing bookings are NOT affected

### paused → active
- **Actor:** Admin (Dashboard)
- **Trigger:** "استئناف المسار"
- **Preconditions:** None
- **Side Effects:**
  - Client App route search exposes route again
  - ● Realtime `route.resumed`

### active / paused / draft → archived
- **Actor:** Admin only
- **Trigger:** "أرشفة المسار" with confirmation dialog
- **Preconditions:** No active or scheduled trips on this route exist. All trips must be `completed` or `cancelled`.
- **Mechanism:** Soft delete: `UPDATE routes SET status = 'archived', deleted_at = now()`
- **Side Effects:**
  - All `route_stations` become read-only
  - Route removed from all Client App searches permanently
  - Existing historical bookings and trip records still reference route for audit trail

---

## 1.3 Illegal Transitions

| From | To | Why Forbidden |
|------|-----|----------------|
| `archived` | any | Archived is terminal. A new route must be created. |
| `draft` | `paused` | Cannot pause a route that was never active. |
| `active` | `draft` | Data regression. Would invalidate existing trip references. |

---

## 1.4 Permission Matrix

| Role | Read | Create | Edit Stations | Publish | Pause/Resume | Archive |
|------|------|--------|---------------|---------|--------------|---------|
| Admin | ✓ all | ✓ | ✓ | ✓ | ✓ | ✓ |
| Operations Manager | ✓ all | ✓ | ✓ | ✓ | ✓ | ✗ |
| Finance Agent | ✓ active only | ✗ | ✗ | ✗ | ✗ | ✗ |
| Support Agent | ✓ active only | ✗ | ✗ | ✗ | ✗ | ✗ |
| Driver | ✓ assigned route only | ✗ | ✗ | ✗ | ✗ | ✗ |
| Client | ✓ active only | ✗ | ✗ | ✗ | ✗ | ✗ |

---

## 1.5 Realtime Requirements

| Event | Channel | Subscribers |
|-------|---------|-------------|
| `route.published` | `dashboard:routes` | Dashboard all roles |
| `route.paused` | `dashboard:routes` | Dashboard all roles |
| `route.resumed` | `dashboard:routes` | Dashboard all roles |
| `route.archived` | `dashboard:routes` | Dashboard all roles |

Client App uses standard polling (re-query on screen resume); realtime not required for route discovery.

---

## 1.6 Dashboard Actions Per Status

| Status | Available Actions |
|--------|------------------|
| `draft` | Edit Info · Add/Remove Stations · Reorder Stations · Publish · Archive |
| `active` | View Trips · Edit Info · Edit Stations · Pause · Archive · Clone Route |
| `paused` | View Trips · Resume · Archive |
| `archived` | View Only · Export |

---

## 1.7 Client App Visibility

| Status | Visible in Search | Bookable |
|--------|------------------|---------|
| `draft` | ✗ | ✗ |
| `active` | ✓ | ✓ (if trips exist) |
| `paused` | ✗ | ✗ |
| `archived` | ✗ | ✗ |

Clients with existing bookings on a now-paused or archived route see their booking details with trip info fully intact. The route status change does not affect confirmed bookings.

---

## 1.8 Driver App Visibility

Driver sees their assigned trip's route regardless of route status. The route is displayed as a read-only stop timeline. Driver never interacts with route status.

---

## 1.9 Invariants

- A route must always have `start_city ≠ end_city`.
- `sort_order` in `route_stations` must be unique per route (enforced by DB constraint).
- At least one station must have `pickup_allowed = true` and at least one must have `dropoff_allowed = true`.
- `archived` routes are write-locked at the DB level via RLS policy.

---

---

# ENTITY 2 — TRIP

**Table:** `operation_trips`  
**Owner:** Dashboard creates and controls. Driver transitions `boarding → in_progress → completed`.  
**Purpose:** A scheduled, executable travel instance. A trip is a specific date + time + route + driver + vehicle combination. It has seats, pricing, passengers, and events.

---

## 2.1 Status Registry

| Status | DB Value | Dart Enum | Arabic | Meaning |
|--------|----------|-----------|--------|---------|
| `scheduled` | `scheduled` | `OperationTripStatus.scheduled` | مجدولة | Created, configured. Booking not yet open. Visible to Dashboard and Driver only. |
| `open_for_booking` | `scheduled`* | `OperationTripStatus.openForBooking` | مفتوحة للحجز | Published for client booking. Clients can discover and book seats. |
| `boarding` | `boarding` | `OperationTripStatus.boarding` | صعود الركاب | Driver has started boarding process. No new bookings accepted. QR scanning active. |
| `in_progress` | `in_progress` | `OperationTripStatus.inProgress` | جارية | Trip is physically moving. GPS broadcasting active. Client tracking active. |
| `completed` | `completed` | `OperationTripStatus.completed` | مكتملة | Trip finished. All data frozen. Read-only. |
| `cancelled` | `cancelled` | `OperationTripStatus.cancelled` | ملغاة | Trip will not operate. All seats released. All bookings moved to cancellation flow. |

> *Note: The current implementation maps `openForBooking` to the `scheduled` DB value. A DB migration should add `open_for_booking` as a distinct enum value to remove this ambiguity.

---

## 2.2 Transition Graph

```
[scheduled] ─────(open)──────→ [open_for_booking]
[open_for_booking] ──(board)─→ [boarding]
[scheduled] ──────(board)────→ [boarding]     ← dispatcher can force-start boarding
[boarding] ────(start_trip)──→ [in_progress]
[in_progress] ──(end_trip)───→ [completed]
[scheduled] ─────(cancel)────→ [cancelled]
[open_for_booking] ─(cancel)─→ [cancelled]
[boarding] ────(cancel)──────→ [cancelled]    ← emergency only, requires admin
```

### scheduled → open_for_booking
- **Actor:** Operations Manager / Admin (Dashboard)
- **Trigger:** "فتح الحجز" button
- **Preconditions:** Trip must have pricing configured (`trip_pricing` rows exist). Vehicle and driver must be `active`/`assigned`. Trip date must be in the future.
- **Mechanism:** `UPDATE operation_trips SET status = 'open_for_booking'`
- **Side Effects:**
  - ✦ Trip becomes queryable via Client App search
  - ✸ Push notification to passengers subscribed to this route: "رحلة جديدة متاحة"
  - ● Realtime `trip.published` to Dashboard live view

### open_for_booking → boarding
- **Actor:** Driver (Captain App) — primary path. Admin/Ops (Dashboard) — override path.
- **Trigger:** Captain taps "بدء صعود الركاب" (available 60 min before departure)
- **Preconditions:** Current time must be within 90 minutes of `departure_time`. Driver must be the assigned driver for this trip.
- **Mechanism:** `POST /rpc/update_trip_status { p_trip_id, p_new_status: 'boarding' }`
- **Side Effects:**
  - ✦ `operation_trips.status = 'boarding'`
  - ✦ `operation_trips.actual_start_time = now()` (boarding start timestamp)
  - ✦ All `reserved` seats (5-min lock timeout not yet expired) are released to `available`
  - ✸ Push to all confirmed passengers: "الحافلة تستقبل الركاب الآن"
  - ● Realtime `trip.boarding_started` to Dashboard live view and Client App

### boarding → in_progress
- **Actor:** Driver (Captain App)
- **Trigger:** "بدء الرحلة"
- **Preconditions:** Trip must be in `boarding` status.
- **Mechanism:** `POST /rpc/update_trip_status { p_new_status: 'in_progress' }`
- **Side Effects:**
  - ✦ `drivers.status = 'on_trip'`
  - ✦ `vehicles.status = 'on_trip'`
  - ✦ Remaining `reserved` seats that were not scanned → booking marked `no_show`, seat → `available`
  - ✸ Push to all passengers not yet boarded: "الرحلة انطلقت"
  - ● GPS broadcast channel opens: `live_location:{trip_id}`
  - ● Realtime `trip.started` to Dashboard and Client App (tracking screen activates)

### in_progress → completed
- **Actor:** Driver (Captain App)
- **Trigger:** "إنهاء الرحلة"
- **Preconditions:** Trip must be in `in_progress`.
- **Mechanism:** `POST /rpc/update_trip_status { p_new_status: 'completed' }`
- **Side Effects:**
  - ✦ `operation_trips.actual_end_time = now()`
  - ✦ `drivers.status = 'assigned'` (returns to ready state)
  - ✦ `vehicles.status = 'assigned'`
  - ✦ All still-`boarded` passenger records remain as-is (audit trail)
  - ✦ All `subscription` seats: decrement `subscriptions.trips_used += 1`
  - ● GPS broadcast channel closes
  - ✸ Push to all boarded passengers: "شكراً لرحلتك! قيّم تجربتك"
  - ● Realtime `trip.completed` to Dashboard

### any → cancelled
- **Actor:** Admin or Operations Manager (Dashboard) only. Driver cannot cancel.
- **Trigger:** "إلغاء الرحلة" with mandatory reason
- **Preconditions:** Trip must NOT be `in_progress` or `completed`. (A moving trip cannot be cancelled; it must be completed then reviewed.)
- **Mechanism:** `POST /rpc/cancel_trip { p_trip_id, p_reason }`
- **Side Effects:**
  - ✦ `operation_trips.status = 'cancelled'`
  - ✦ All `trip_seats` → `available` (releases all locks)
  - ✦ All linked `operation_bookings` → `cancelled`, `payment_status = 'refunded'` (if paid)
  - ✦ Refund workflow triggered per payment method
  - ✸ Push to all booked passengers: "تم إلغاء رحلتك. سيتم استرداد المبلغ."
  - ● Realtime `trip.cancelled` to Dashboard and Client App

---

## 2.3 Illegal Transitions

| From | To | Why Forbidden |
|------|-----|----------------|
| `completed` | any | Terminal. Historical record. Create a new trip. |
| `cancelled` | any | Terminal. Cannot un-cancel. Create a new trip. |
| `in_progress` | `boarding` | Cannot reverse execution. |
| `in_progress` | `cancelled` | Trip is moving. Use force-complete then manual refund. |
| `boarding` | `scheduled` | Cannot regress. |
| `boarding` | `open_for_booking` | Cannot regress. |

---

## 2.4 Permission Matrix

| Role | Create | Open Booking | Force-Cancel | View All | View Own Only |
|------|--------|--------------|--------------|----------|----------------|
| Admin | ✓ | ✓ | ✓ | ✓ | — |
| Operations Manager | ✓ | ✓ | ✓ | ✓ | — |
| Finance Agent | ✗ | ✗ | ✗ | ✓ (read) | — |
| Support Agent | ✗ | ✗ | ✗ | ✓ (read) | — |
| Driver | ✗ | ✗ | ✗ | ✗ | ✓ (assigned trips) |
| Client | ✗ | ✗ | ✗ | ✗ | ✓ (booked trips) |

---

## 2.5 Realtime Requirements

| Event | Channel Pattern | Subscribers | Payload |
|-------|----------------|-------------|---------|
| `trip.published` | `dashboard:trips` | Dashboard all roles | `{trip_id, route, date, departure}` |
| `trip.boarding_started` | `dashboard:trips`, `client:trip:{id}` | Dashboard + booked clients | `{trip_id}` |
| `trip.started` | `dashboard:trips`, `client:trip:{id}` | Dashboard + booked clients | `{trip_id}` |
| `trip.completed` | `dashboard:trips`, `client:trip:{id}` | Dashboard + booked clients | `{trip_id}` |
| `trip.cancelled` | `dashboard:trips`, `client:trip:{id}` | Dashboard + booked clients | `{trip_id, reason}` |
| `location.update` | `live_location:{trip_id}` | Dashboard live trips + Client tracking | `{lat, lng, speed, timestamp}` |
| `seat.booked` | `dashboard:trips:{id}:seats` | Dashboard live trips panel | `{seat_id, seat_label}` |

---

## 2.6 Dashboard Actions Per Status

| Status | Available Actions |
|--------|------------------|
| `scheduled` | Edit Details · Configure Pricing · Open for Booking · Duplicate · Cancel |
| `open_for_booking` | View Bookings · View Seat Map · Start Boarding (override) · Cancel |
| `boarding` | View Live Manifest · View Seat Map · Cancel (admin only) |
| `in_progress` | View Live Map · View Manifest · Resolve Alerts · Notify Passengers |
| `completed` | View Report · Export Manifest · View Timeline |
| `cancelled` | View Details · View Refund Status |

---

## 2.7 Client App Visibility

| Trip Status | Discoverable | Bookable | Shows Tracking | Shows in "My Trips" |
|-------------|-------------|---------|----------------|---------------------|
| `scheduled` | ✗ | ✗ | ✗ | ✗ |
| `open_for_booking` | ✓ | ✓ | ✗ | ✓ (after booking) |
| `boarding` | ✓ (detail only) | ✗ | Live countdown | ✓ |
| `in_progress` | ✗ (new search) | ✗ | ✓ Full map | ✓ |
| `completed` | ✗ | ✗ | ✗ | ✓ (history) |
| `cancelled` | ✗ | ✗ | ✗ | ✓ (cancelled tag) |

---

## 2.8 Driver App Visibility

| Trip Status | Appears in Schedule | Primary Action | Boarding Actions Available |
|-------------|--------------------|-----------------|-----------------------------|
| `scheduled` | ✓ | — (future trip) | ✗ |
| `open_for_booking` | ✓ | "بدء صعود الركاب" (60min window) | ✗ |
| `boarding` | ✓ (active card) | "بدء الرحلة" | QR Scanner · Manifest · Chat |
| `in_progress` | ✓ (active card) | "إنهاء الرحلة" | Manifest · Location · Chat · SOS |
| `completed` | ✓ (dimmed, history) | — | ✗ |
| `cancelled` | ✓ (cancelled tag) | — | ✗ |

---

## 2.9 Invariants

- A trip must always reference a driver with `status IN ('active', 'assigned', 'on_trip')`.
- A trip must always reference a vehicle with `status IN ('active', 'assigned', 'on_trip')`.
- A trip cannot be `open_for_booking` unless `trip_pricing` rows exist for it.
- `capacity` on `operation_trips` must equal the number of passenger `trip_seats` rows generated.
- Only one trip per driver per date and overlapping time window (enforced by `create_trip` RPC conflict check).
- `actual_start_time` is set on first transition to `boarding`, never updated thereafter.
- `actual_end_time` is set once on transition to `completed`, never updated thereafter.

---

---

# ENTITY 3 — BOOKING

**Table:** `operation_bookings`  
**Owner:** Created by Client App. Reviewed and managed by Dashboard.  
**Purpose:** A passenger's reservation on a specific trip seat, with payment record and audit trail.

---

## 3.1 Status Registry

### Booking Status (`status` field)

| Status | DB Value | Arabic | Meaning |
|--------|----------|--------|---------|
| `new_request` | `new_request` | طلب جديد | Booking submitted. Seat locked. Payment not yet uploaded. |
| `payment_uploaded` | `payment_uploaded` | تم رفع الإيصال | Passenger uploaded receipt. Awaiting ops review. |
| `under_review` | `under_review` | قيد المراجعة | Agent has opened the booking for review. |
| `request_reupload` | `request_reupload` | طلب إعادة رفع | Receipt was rejected. Passenger must re-upload. |
| `approved` | `approved` | مقبول | Payment receipt accepted. Seat confirmed. QR code active. |
| `rejected` | `rejected` | مرفوض | Booking rejected. Seat released. |
| `confirmed` | `confirmed` | مؤكد المقعد | Seat physically assigned (post-boarding QR scan). |
| `cancelled` | `cancelled` | ملغى | Cancelled by passenger or ops. Seat released. Refund initiated if paid. |

### Payment Status (`payment_status` field)

| Status | DB Value | Arabic | Meaning |
|--------|----------|--------|---------|
| `unpaid` | `unpaid` | غير مدفوع | No payment received or receipt uploaded yet. |
| `paid` | `paid` | مدفوع | Payment verified by ops agent. |
| `refunded` | `refunded` | مسترد | Refund processed (booking cancelled after payment). |

---

## 3.2 Transition Graph

### Booking Status Transitions

```
[new_request] ──(upload_receipt)────→ [payment_uploaded]
[payment_uploaded] ──(review)────────→ [under_review]
[under_review] ──(approve)───────────→ [approved]
[under_review] ──(reject)────────────→ [rejected]
[under_review] ──(request_reupload)──→ [request_reupload]
[request_reupload] ──(re_upload)─────→ [payment_uploaded]
[approved] ──(qr_scanned_on_board)──→ [confirmed]
[any except confirmed/cancelled] ──(cancel)──→ [cancelled]
```

### new_request (created)
- **Actor:** Client App (passenger)
- **Trigger:** Completing checkout (`book_seat` RPC call)
- **Preconditions:** Seat is `available`. Trip is `open_for_booking`. Client is authenticated.
- **Mechanism:** `POST /rpc/book_seat { p_trip_id, p_seat_id, p_pickup_station_id, p_dropoff_station_id, p_payment_method }`
- **Side Effects:**
  - ✦ `trip_seats.state = 'reserved'`, `passenger_id = client.id`
  - ✦ `operation_bookings` row created with `status = 'new_request'`, `payment_status = 'unpaid'`
  - ✦ `qr_code_token` generated (UUID)
  - ✸ Push to client: "تم استلام طلب حجزك"
  - ● Realtime `seat.reserved` → Dashboard updates available seat count
  - ✦ 5-minute seat lock timer starts (Edge Function or pg_cron releases seat if payment not initiated)

### new_request → payment_uploaded
- **Actor:** Client App
- **Trigger:** Receipt upload screen — passenger uploads image
- **Mechanism:** `UPDATE operation_bookings SET status = 'payment_uploaded', payment_receipt_url = ?`
- **Side Effects:**
  - ✸ Push to Dashboard support/finance agents: "إيصال جديد في انتظار المراجعة"
  - ● Realtime `booking.receipt_uploaded` → Dashboard bookings queue

### payment_uploaded → under_review
- **Actor:** Finance Agent / Operations Manager (Dashboard)
- **Trigger:** Opening booking detail (auto-transitions, or explicit "بدء المراجعة" button)
- **Mechanism:** `UPDATE operation_bookings SET status = 'under_review', reviewer_id = current_user_id`
- **Side Effects:**
  - ✦ `reviewer_name` field set
  - Booking no longer appears in "جديد" filter; moves to "قيد المراجعة"

### under_review → approved
- **Actor:** Finance Agent / Admin (Dashboard)
- **Trigger:** "قبول الحجز" button after verifying receipt
- **Mechanism:** `UPDATE operation_bookings SET status = 'approved', payment_status = 'paid'`
- **Side Effects:**
  - ✦ `trip_seats.state = 'paid'`
  - ✸ Push to client: "تم تأكيد حجزك! رمز QR جاهز."
  - ● Realtime `booking.approved` → Dashboard seat map updates
  - QR code is now active and scannable

### under_review → request_reupload
- **Actor:** Finance Agent (Dashboard)
- **Trigger:** "طلب إعادة رفع" with mandatory reason
- **Mechanism:** `UPDATE operation_bookings SET status = 'request_reupload', rejection_reason = ?`
- **Side Effects:**
  - ✸ Push to client: "يرجى إعادة رفع إيصال الدفع: [reason]"
  - Seat remains `reserved` (5-min lock is refreshed)

### under_review → rejected
- **Actor:** Finance Agent / Admin (Dashboard)
- **Trigger:** "رفض الحجز" with mandatory reason
- **Mechanism:** `UPDATE operation_bookings SET status = 'rejected', rejection_reason = ?`
- **Side Effects:**
  - ✦ `trip_seats.state = 'available'`, `passenger_id = null`
  - ✸ Push to client: "تم رفض حجزك: [reason]"

### approved → confirmed (QR Scan)
- **Actor:** Driver (Captain App)
- **Trigger:** QR code scanner reads passenger's token
- **Mechanism:** `POST /rpc/scan_passenger_ticket { p_trip_id, p_qr_code_token }`
- **Side Effects:**
  - ✦ `operation_bookings.status = 'confirmed'`
  - ✦ `trip_passengers` record updated to `status = 'boarded'`
  - ● Realtime `passenger.boarded` → Dashboard manifest and Client App

### any → cancelled
- **Actor:** Client (own booking, before `boarding` status of trip) OR Admin/Ops (any time before `confirmed`)
- **Trigger:** "إلغاء الحجز"
- **Preconditions:** Cannot cancel a booking that is already `confirmed` (passenger is physically on the bus).
- **Mechanism:** `POST /rpc/cancel_booking { p_booking_id, p_reason }`
- **Side Effects:**
  - ✦ `trip_seats.state = 'available'`
  - ✦ If `payment_status = 'paid'` → `payment_status = 'refunded'`; refund workflow triggered
  - ✸ Push to client confirming cancellation and refund status

---

## 3.3 Illegal Transitions

| From | To | Why Forbidden |
|------|-----|----------------|
| `confirmed` | `cancelled` | Passenger is physically on board. Use operational report instead. |
| `confirmed` | any (backward) | Terminal. Booking is recorded as completed. |
| `rejected` | `approved` | Cannot reinstate rejected booking. Client must rebook. |
| `cancelled` | any | Terminal. |
| `approved` | `payment_uploaded` | Cannot undo approval. |

---

## 3.4 Permission Matrix

| Role | Create | Upload Receipt | Review | Approve | Reject | Cancel | Reassign Trip/Seat |
|------|--------|---------------|--------|---------|--------|--------|-------------------|
| Admin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ any | ✓ |
| Operations Manager | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ any | ✓ |
| Finance Agent | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ (own review) | ✗ |
| Support Agent | ✗ | ✗ | ✓ (view) | ✗ | ✗ | ✓ (own request) | ✗ |
| Driver | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Client | ✓ (own trip) | ✓ (own) | ✗ | ✗ | ✗ | ✓ (own, before boarding) | ✗ |

---

## 3.5 Realtime Requirements

| Event | Channel | Subscribers | Priority |
|-------|---------|-------------|----------|
| `booking.created` | `dashboard:bookings` | Finance + Ops | Medium |
| `booking.receipt_uploaded` | `dashboard:bookings` | Finance Agent | High |
| `booking.approved` | `client:booking:{id}` | Client | Critical |
| `booking.rejected` | `client:booking:{id}` | Client | Critical |
| `booking.cancelled` | `dashboard:bookings`, `client:booking:{id}` | Both | High |
| `passenger.boarded` | `dashboard:trips:{trip_id}:manifest` | Dashboard live trips | Medium |

---

## 3.6 Dashboard Actions Per Status

| Status | Available Actions |
|--------|------------------|
| `new_request` | View Details · Start Review · Cancel |
| `payment_uploaded` | View Receipt · Approve · Request Re-upload · Reject · Cancel |
| `under_review` | Approve · Request Re-upload · Reject · Cancel |
| `request_reupload` | View Details · Cancel |
| `approved` | View QR · Reassign Trip/Seat · Cancel |
| `rejected` | View Details (read-only) |
| `confirmed` | View Boarding Record (read-only) |
| `cancelled` | View Refund Status (read-only) |

---

## 3.7 Client App Visibility

| Status | Client Sees | Client Can Do |
|--------|-------------|---------------|
| `new_request` | "في انتظار رفع الإيصال" | Upload receipt · Cancel |
| `payment_uploaded` | "جاري المراجعة" | Cancel |
| `under_review` | "قيد المراجعة" | Cancel |
| `request_reupload` | "يرجى إعادة رفع الإيصال" + reason | Re-upload receipt · Cancel |
| `approved` | "مؤكد ✓" + QR code | Download QR · Cancel |
| `rejected` | "مرفوض" + reason | View reason (no further action) |
| `confirmed` | "تم الصعود ✓" | Rate trip (post-completion) |
| `cancelled` | "ملغى" + refund status | View refund status |

---

## 3.8 Driver App Visibility

Driver sees bookings only through the Passenger Manifest. The manifest shows:
- Passenger name, seat number, pickup station, dropoff station
- Boarding status: `pending` / `boarded` / `absent` / `cancelled`
- Phone number (for calling no-shows)

Driver never sees payment details, booking ID, or receipt.

---

## 3.9 Invariants

- One booking per seat per trip (enforced by `UNIQUE(trip_id, seat_id)` on `operation_bookings` where status not in `cancelled`, `rejected`).
- `qr_code_token` must be globally unique (`UNIQUE` constraint on column).
- A booking cannot exist for a `cancelled` trip.
- `payment_status = 'paid'` can only be set when `status = 'approved'` or later.
- Seat state and booking status must be consistent: `approved` booking → seat must be `paid`; `cancelled` booking → seat must be `available`.

---

---

# ENTITY 4 — DRIVER

**Table:** `drivers` (linked to `auth.users` via `user_id`)  
**Owner:** Dashboard (Admin / Operations Manager)  
**Purpose:** A human operator of a vehicle. Drivers are onboarded by ops, assigned to vehicles, and execute trips.

---

## 4.1 Status Registry

| Status | DB Value | Dart Enum | Arabic | Meaning |
|--------|----------|-----------|--------|---------|
| `active` | `active` | `FleetDriverStatus.active` | نشط | Driver is available for assignments. No current trip. |
| `suspended` | `suspended` | `FleetDriverStatus.suspended` | موقوف | Temporarily barred. Cannot execute trips. Assignment still held. |
| `archived` | `archived` | `FleetDriverStatus.archived` | مؤرشف | Permanently inactive. Cannot ever execute trips. |

> The DB schema also defines operational statuses (`available`, `assigned`, `on_trip`, `license_expired`) that represent real-time operational state. These are separate from the administrative status above.

### Operational Sub-Status (computed, not stored separately)

| Sub-Status | Computed From | Meaning |
|------------|--------------|---------|
| `available` | `status = active` AND no active assignment | Ready to be assigned |
| `assigned` | `status = active` AND active `assignment` exists | Has vehicle, available for trips |
| `on_trip` | Current trip is `in_progress` | Physically executing a trip |
| `license_expired` | `license_expiry_date < today` | Cannot legally drive; blocked from new trips |

---

## 4.2 Transition Graph

```
[active:available] ──(create_assignment)──→ [active:assigned]
[active:assigned] ──(start_trip)──────────→ [active:on_trip]
[active:on_trip] ──(complete_trip)────────→ [active:assigned]
[active:assigned] ──(end_assignment)───────→ [active:available]
[active] ──(suspend)───────────────────────→ [suspended]
[suspended] ──(reinstate)──────────────────→ [active]
[active] ──(archive)───────────────────────→ [archived]
[suspended] ──(archive)────────────────────→ [archived]
```

### active → suspended
- **Actor:** Admin (Dashboard)
- **Trigger:** "تعليق السائق" with reason
- **Preconditions:** Driver must not be `on_trip` at time of suspension.
- **Mechanism:** `UPDATE drivers SET status = 'suspended'`
- **Side Effects:**
  - Future trips assigned to this driver remain scheduled but a warning flag appears in Dashboard
  - ✸ Notification to Operations Manager: "تم تعليق السائق [name]. يوجد [N] رحلة مجدولة بحاجة للتعيين."
  - Driver App login still allowed but "لا يمكنك تنفيذ الرحلات حالياً" banner shown

### suspended → active
- **Actor:** Admin (Dashboard)
- **Trigger:** "رفع التعليق"
- **Side Effects:**
  - Driver operational capability restored
  - ✸ Notification to driver (if mobile registered)

### active/suspended → archived
- **Actor:** Admin (Dashboard)
- **Trigger:** "أرشفة السائق" with confirmation
- **Preconditions:** No future scheduled trips assigned to this driver. Driver must be in `suspended` status (cannot archive an active driver directly to prevent accidental removal).
- **Mechanism:** Soft delete: `UPDATE drivers SET status = 'archived', deleted_at = now()`
- **Side Effects:**
  - If driver has an active assignment: `assignments.status = 'ended'`
  - `vehicles.status` recomputed (may return to `available`)
  - Driver App login blocked

---

## 4.3 Permission Matrix

| Role | Create Driver | Edit Info | View License Docs | Suspend | Archive | View Trip History |
|------|--------------|-----------|-------------------|---------|---------|-------------------|
| Admin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Operations Manager | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| Finance Agent | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ (limited) |
| Support Agent | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ (trip reference only) |
| Driver (self) | ✗ | ✗ | ✓ (own docs) | ✗ | ✗ | ✓ (own) |
| Client | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

---

## 4.4 Realtime Requirements

| Event | Channel | Subscribers |
|-------|---------|-------------|
| `driver.suspended` | `dashboard:fleet:drivers` | Operations Manager + Admin |
| `driver.reinstated` | `dashboard:fleet:drivers` | Operations Manager + Admin |
| `driver.license_expiry_warning` | `dashboard:alerts` | Operations Manager + Admin (7 days and 30 days before expiry) |

---

## 4.5 Dashboard Actions Per Status

| Status | Available Actions |
|--------|------------------|
| `active:available` | View Profile · Edit Info · Assign to Vehicle · Upload Documents · Suspend · Archive (via suspend first) |
| `active:assigned` | View Profile · View Assignment · View Trips · Edit Info · End Assignment · Upload Documents · Suspend |
| `active:on_trip` | View Live Trip · View Profile · (Edit blocked while on trip) |
| `suspended` | View Profile · Reinstate · Archive |
| `archived` | View Profile (read-only) · Export Record |

---

## 4.6 Client App Visibility

Client never sees driver entity directly. Client sees:
- Driver's **full name** on the trip detail and booking confirmation screens
- Driver is **not contactable** through the Client App (no phone number shown)

When a trip is cancelled because a driver was suspended, client sees only the trip cancellation notice, not the driver's status.

---

## 4.7 Driver App Visibility

Driver sees their own profile (name, employee code, license expiry). They cannot edit their own profile through the app. They see a warning banner if `isLicenseExpiringSoon = true`. If `isLicenseExpired = true`, a full-screen blocking overlay prevents trip execution with message: "رخصتك منتهية الصلاحية. تواصل مع الإدارة."

---

## 4.8 Invariants

- A driver cannot be assigned to two active assignments simultaneously (`UNIQUE active assignment per driver`).
- A driver with `status = 'license_expired'` must not be allowed to start a trip (`start_boarding` RPC rejects if `license_expiry_date < today`).
- Archiving requires suspension first — prevents accidental permanent removal of active drivers.
- `on_trip` sub-status is computed from trip state, never stored directly on `drivers` table to prevent drift.
- Driver's Supabase Auth account must be deactivated when `status = 'archived'`.

---

---

# ENTITY 5 — VEHICLE

**Table:** `vehicles`  
**Owner:** Dashboard (Admin / Operations Manager)  
**Purpose:** A physical transport unit with a defined seat layout and capacity. Vehicles are assigned to drivers and used to execute trips.

---

## 5.1 Status Registry

| Status | DB Value | Dart Enum | Arabic | Meaning |
|--------|----------|-----------|--------|---------|
| `active` | `active` | `FleetVehicleStatus.active` | نشطة | Available for assignment. No current assignment. |
| `maintenance` | `in_maintenance` | `FleetVehicleStatus.maintenance` | صيانة | In service/repair. Cannot be assigned to trips. |
| `suspended` | `suspended` | `FleetVehicleStatus.suspended` | موقوفة | Administratively barred. Investigation or compliance hold. |
| `archived` | `archived` | `FleetVehicleStatus.archived` | مؤرشفة | Permanently retired. Soft-deleted. |

### Operational Sub-Status (computed)

| Sub-Status | Computed From | Meaning |
|------------|--------------|---------|
| `available` | `status = active` AND no active assignment | Ready to be assigned |
| `assigned` | `status = active` AND active `assignment` exists | Paired with driver |
| `on_trip` | Linked trip is `in_progress` | Currently executing |
| `documents_expiring` | Any expiry date within 30 days | Warning state, still operational |
| `documents_expired` | Any expiry date in past | Blocked from new trips |

---

## 5.2 Transition Graph

```
[active] ──(send_to_maintenance)──→ [maintenance]
[maintenance] ──(return_to_service)─→ [active]
[active] ──(suspend)──────────────→ [suspended]
[suspended] ──(reinstate)─────────→ [active]
[active] ──(archive)──────────────→ [archived]
[suspended] ──(archive)───────────→ [archived]
[maintenance] ──(archive)─────────→ [archived]
```

### active → maintenance
- **Actor:** Operations Manager / Admin
- **Trigger:** "إرسال للصيانة"
- **Preconditions:** Vehicle must not be `on_trip`. If vehicle has an active assignment, assignment must be ended first or driver reassigned.
- **Side Effects:**
  - If active assignment exists: `assignments.status = 'ended'`, driver returns to `available`
  - ✸ Notification to Ops: "المركبة [code] في الصيانة. السائق المرتبط يحتاج تعيينًا جديدًا."

### maintenance → active
- **Actor:** Operations Manager / Admin
- **Trigger:** "إعادة للخدمة"
- **Side Effects:**
  - Vehicle returns to `available` sub-status

### active/suspended → archived
- **Actor:** Admin
- **Preconditions:** No future scheduled trips using this vehicle. Must not have active assignment.
- **Side Effects:** Soft delete. All past trip records retain reference for audit.

---

## 5.3 Permission Matrix

| Role | Create | Edit Info | Send to Maintenance | Suspend | Archive | View Documents |
|------|--------|-----------|---------------------|---------|---------|----------------|
| Admin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Operations Manager | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| Finance Agent | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ (read) |
| Support Agent | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Driver | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ (own vehicle docs) |
| Client | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

---

## 5.4 Realtime Requirements

| Event | Channel | Subscribers |
|-------|---------|-------------|
| `vehicle.maintenance` | `dashboard:fleet:vehicles` | Operations Manager + Admin |
| `vehicle.returned` | `dashboard:fleet:vehicles` | Operations Manager + Admin |
| `vehicle.document_expiring` | `dashboard:alerts` | Operations Manager + Admin |

---

## 5.5 Dashboard Actions Per Status

| Status | Available Actions |
|--------|------------------|
| `active:available` | Edit Info · Upload Documents · Assign to Driver · Send to Maintenance · Suspend · Archive |
| `active:assigned` | View Assignment · View Trips · Edit Info · End Assignment · Send to Maintenance · Suspend |
| `active:on_trip` | View Live Trip · View Profile (edit blocked) |
| `maintenance` | Edit Maintenance Notes · Return to Service · Archive |
| `suspended` | Reinstate · Archive |
| `archived` | View Only · Export |

---

## 5.6 Client App Visibility

Client never sees vehicle entity directly. Client sees the **vehicle type** (e.g., "حافلة ٤٥ مقعد") on trip detail and booking confirmation. Seat map is derived from `vehicles.seat_configuration` via `trip_seats`.

---

## 5.7 Driver App Visibility

Driver sees their assigned vehicle details:
- Vehicle code, plate number, type, capacity
- A "my vehicle" card on the Captain App home screen if they have an active assignment
- If vehicle documents are expiring: warning banner

Driver cannot modify vehicle information through the app.

---

## 5.8 Invariants

- One active assignment per vehicle at a time (enforced by DB constraint).
- A vehicle with expired `license_expiry`, `insurance_expiry`, or `inspection_expiry` must be blocked from new trip assignments at the RPC layer.
- `capacity` determines the number of `trip_seats` rows generated. Changing capacity after trips are created is forbidden.
- `seat_configuration` JSONB must be consistent with `capacity` (passenger seat count = capacity).

---

---

# ENTITY 6 — ASSIGNMENT

**Table:** `assignments`  
**Owner:** Dashboard (Operations Manager / Admin)  
**Purpose:** A persistent pairing of one driver to one vehicle for an indefinite operational period. Assignments are the prerequisite for scheduling trips. A driver executes all trips using their assigned vehicle.

---

## 6.1 Status Registry

| Status | DB Value | Dart Enum | Arabic | Meaning |
|--------|----------|-----------|--------|---------|
| `active` | `active` | `FleetAssignmentStatus.active` | نشط | Driver and vehicle are paired. Both carry "assigned" sub-status. |
| `ended` | `ended` | `FleetAssignmentStatus.ended` | منتهي | Pairing dissolved. Both driver and vehicle revert to `available`. |

---

## 6.2 Transition Graph

```
[created] ──────────────────────── (insert)  → [active]
[active] ──(end_assignment)────────────────  → [ended]
[active] ──(driver_suspended)──────────────  → [ended] (automatic)
[active] ──(vehicle_sent_to_maintenance)───  → [ended] (automatic)
```

### Create Assignment (→ active)
- **Actor:** Operations Manager / Admin (Dashboard)
- **Trigger:** "تعيين سائق لمركبة" from Fleet Assignments screen or Driver detail
- **Preconditions:**
  - Driver must be `active` with no current active assignment
  - Vehicle must be `active` with no current active assignment
  - No date overlap with any future assignment for either entity
- **Mechanism:** `INSERT INTO assignments (driver_id, vehicle_id, start_date, status) VALUES (..., 'active')`
- **Side Effects:**
  - ✦ `drivers.status = 'assigned'`
  - ✦ `vehicles.status = 'assigned'`
  - ✦ `vehicles.current_driver_id = driver.id`
  - ✦ `drivers.current_vehicle_id = vehicle.id`
  - ● Realtime `assignment.created` → Dashboard fleet view
  - ✸ (Optional) Notification to driver: "تم تعيينك للمركبة [code]"
  - Driver App home screen shows assigned vehicle card

### active → ended
- **Actor:** Operations Manager / Admin (Dashboard) — manual end. Or system (automatic on driver suspend / vehicle maintenance).
- **Trigger:** "إنهاء التعيين" button
- **Preconditions:** Driver must not be `on_trip` at time of ending.
- **Mechanism:** `UPDATE assignments SET status = 'ended', end_date = now()`
- **Side Effects:**
  - ✦ `drivers.status = 'active'` (sub: `available`)
  - ✦ `vehicles.status = 'active'` (sub: `available`)
  - ✦ `vehicles.current_driver_id = null`
  - ✦ `drivers.current_vehicle_id = null`
  - ● Realtime `assignment.ended` → Dashboard fleet view
  - All future *scheduled* trips using this driver/vehicle pair remain scheduled — Dashboard alerts ops to reassign or cancel them

---

## 6.3 Illegal Transitions

| From | To | Why Forbidden |
|------|-----|----------------|
| `ended` | `active` | Cannot reactivate an ended assignment. Create a new one. |
| `ended` | `ended` | Already terminal. |

---

## 6.4 Permission Matrix

| Role | Create | End | View All | View Own Assignment |
|------|--------|-----|---------|---------------------|
| Admin | ✓ | ✓ | ✓ | — |
| Operations Manager | ✓ | ✓ | ✓ | — |
| Finance Agent | ✗ | ✗ | ✓ (limited) | — |
| Support Agent | ✗ | ✗ | ✓ (limited) | — |
| Driver | ✗ | ✗ | ✗ | ✓ |
| Client | ✗ | ✗ | ✗ | ✗ |

---

## 6.5 Realtime Requirements

| Event | Channel | Subscribers |
|-------|---------|-------------|
| `assignment.created` | `dashboard:fleet:assignments` | Operations Manager + Admin |
| `assignment.ended` | `dashboard:fleet:assignments` | Operations Manager + Admin |

Driver App refreshes home screen on `assignment.created` to show the new vehicle card.

---

## 6.6 Dashboard Actions Per Status

| Status | Available Actions |
|--------|------------------|
| `active` | View Details · View Trip History · End Assignment |
| `ended` | View Details (read-only) · View History |

---

## 6.7 Client App Visibility

Clients have no visibility into assignments. The assignment is an operational construct invisible to passengers.

---

## 6.8 Driver App Visibility

Driver sees their current active assignment as a "مركبتك الحالية" card showing:
- Vehicle code, plate number, type, capacity
- Assignment start date
- Total trips executed under this assignment

When `assignment.status = 'ended'`, the card disappears from the Captain App home screen and the driver sees "لا يوجد تعيين نشط حالياً. تواصل مع مشرفك."

---

## 6.9 Invariants

- Exactly one active assignment per driver at any time (DB constraint: UNIQUE active assignment per `driver_id`).
- Exactly one active assignment per vehicle at any time (DB constraint: UNIQUE active assignment per `vehicle_id`).
- `end_date >= start_date` always.
- Ending an assignment while a trip is `in_progress` is blocked at the RPC layer.

---

---

# ENTITY 7 — PACKAGE / SUBSCRIPTION

**Table:** `subscriptions`  
**Owner:** Created by Dashboard (on behalf of passenger) or by Client App (self-service). Managed by Dashboard.  
**Purpose:** A pre-paid multi-ride pass for a specific route and origin-destination pair. Covers a defined number of trips within a validity window.

---

## 7.1 Status Registry

| Status | DB Value | Dart Enum | Arabic | Meaning |
|--------|----------|-----------|--------|---------|
| `active` | `active` | `SubscriptionStatus.active` | نشط | In-date and has remaining rides. Passenger can book with subscription. |
| `expired` | `expired` | `SubscriptionStatus.expired` | منتهي | Past `valid_to` date OR all rides consumed. No further bookings. |
| `cancelled` | `cancelled` | `SubscriptionStatus.cancelled` | ملغي | Manually cancelled by ops or client. Remaining rides forfeited. |
| `pending_payment` | `pending_payment` | `SubscriptionStatus.pendingPayment` | بانتظار الدفع | Payment not yet verified. Cannot be used for bookings. |

### Subscription Types

| Type | DB Value | Arabic | Rides |
|------|----------|--------|-------|
| One-time | `one_time` | رحلة واحدة | 1 |
| 5 Days | `five_days` | ٥ أيام | 5 |
| 10 Days Monthly | `ten_days_monthly` | ١٠ أيام شهريًا | 10 |
| Monthly | `monthly` | شهري | ~22 |
| 3 Months | `three_months` | ٣ شهور | ~66 |

---

## 7.2 Transition Graph

```
[pending_payment] ──(verify_payment)──→ [active]
[pending_payment] ──(cancel)──────────→ [cancelled]
[active] ──(all_rides_consumed)────────→ [expired]  (automatic)
[active] ──(valid_to_date_passed)──────→ [expired]  (automatic, pg_cron)
[active] ──(cancel)────────────────────→ [cancelled]
[expired] ─ terminal ─
[cancelled] ─ terminal ─
```

### pending_payment → active
- **Actor:** Finance Agent / Admin (Dashboard) — after verifying payment
- **Trigger:** "تأكيد الدفع" in subscription detail
- **Mechanism:** `UPDATE subscriptions SET status = 'active'`
- **Side Effects:**
  - ✸ Push to client: "تم تفعيل اشتراكك. يمكنك الحجز الآن."
  - ✦ `valid_from` and `valid_to` dates confirmed

### active → expired (rides consumed)
- **Actor:** System (automatic)
- **Trigger:** After QR scan in Captain App: `trips_used = total_trips_allowed`
- **Mechanism:** `UPDATE subscriptions SET trips_used = trips_used + 1, status = (CASE WHEN trips_used + 1 >= total_trips_allowed THEN 'expired' ELSE 'active' END)`
- **Side Effects:**
  - ✸ Push to client when last ride is used: "انتهت رحلات اشتراكك. قم بتجديد الاشتراك."
  - When 2 rides remain: proactive warning push

### active → expired (date passed)
- **Actor:** System (pg_cron Edge Function — runs daily at 00:01)
- **Trigger:** `valid_to < today`
- **Side Effects:**
  - Batch update: `UPDATE subscriptions SET status = 'expired' WHERE status = 'active' AND valid_to < today`
  - ✸ Push to all affected clients: "انتهى اشتراكك. يمكنك التجديد الآن."

### active → cancelled
- **Actor:** Admin / Operations Manager (Dashboard) OR Client (self-service before first ride)
- **Trigger:** "إلغاء الاشتراك" with reason
- **Preconditions:** Cannot cancel a subscription with `trips_used > 0` by client. Admin can cancel at any time.
- **Side Effects:**
  - ✦ Refund amount computed: `(remaining_rides / total_rides) × price`
  - ✦ Refund workflow triggered
  - ✸ Push to client: "تم إلغاء اشتراكك. رصيد الاسترداد: [amount] ج.م"

---

## 7.3 Illegal Transitions

| From | To | Why Forbidden |
|------|-----|----------------|
| `expired` | `active` | Cannot reactivate. Client must purchase new subscription. |
| `cancelled` | `active` | Terminal. New subscription required. |
| `expired` | `cancelled` | Already terminal. |
| `active` | `pending_payment` | Cannot regress to unverified state. |

---

## 7.4 Permission Matrix

| Role | Create (for client) | Verify Payment | View All | Cancel Any | Cancel Own |
|------|---------------------|---------------|---------|------------|------------|
| Admin | ✓ | ✓ | ✓ | ✓ | — |
| Operations Manager | ✓ | ✓ | ✓ | ✓ | — |
| Finance Agent | ✓ | ✓ | ✓ | ✗ | — |
| Support Agent | ✗ | ✗ | ✓ (read) | ✗ | — |
| Driver | ✗ | ✗ | ✗ | ✗ | — |
| Client | ✓ (own only) | ✗ | ✗ | ✗ | ✓ (before first ride) |

---

## 7.5 Realtime Requirements

| Event | Channel | Subscribers |
|-------|---------|-------------|
| `subscription.activated` | `client:subscription:{id}` | Client |
| `subscription.expired` | `client:subscription:{id}` | Client |
| `subscription.low_rides` | `client:subscription:{id}` | Client (at 2 rides remaining) |
| `subscription.cancelled` | `client:subscription:{id}`, `dashboard:subscriptions` | Client + Ops |

---

## 7.6 Dashboard Actions Per Status

| Status | Available Actions |
|--------|------------------|
| `pending_payment` | View Details · Verify Payment · Cancel |
| `active` | View Details · View Ride History · Edit Validity Dates (admin) · Cancel |
| `expired` | View History · Renew (creates new subscription pre-filled) |
| `cancelled` | View Details · View Refund Status (read-only) |

---

## 7.7 Client App Visibility

| Status | Client Sees | Can Use for Booking |
|--------|-------------|---------------------|
| `pending_payment` | "بانتظار تأكيد الدفع" | ✗ |
| `active` | Rides used / total, valid_to date, route | ✓ (shown in payment method selector) |
| `expired` | "منتهي" + expiry reason + renew CTA | ✗ |
| `cancelled` | "ملغي" + refund status | ✗ |

When booking with a subscription:
- Seat payment method selector shows "اشتراكك النشط: [N] رحلات متبقية"
- After trip is completed: remaining rides count updates in real time
- Trip `seat_state` = `subscription` distinguishes these seats from cash/card bookings

---

## 7.8 Driver App Visibility

Driver sees the subscription indicator during QR scanning only:
- On scan: result card shows `payment_method = 'اشتراك'` alongside passenger name and seat
- Driver does not see subscription balance or validity

After QR scan succeeds, the `scan_passenger_ticket` RPC automatically decrements `trips_used`.

---

## 7.9 Invariants

- A subscription is bound to exactly one route, one origin station, and one destination station.
- `trips_used` can never exceed `total_trips_allowed` (DB constraint: `CHECK (trips_used <= total_trips_allowed)`).
- `valid_from <= valid_to` always.
- Only one `active` subscription per client per route-from-to combination at any time.
- `trips_used` is incremented atomically inside the `scan_passenger_ticket` RPC to prevent race conditions when a passenger takes two buses simultaneously (edge case in multi-segment routes).
- Subscription bookings use `seat_state = 'subscription'` to distinguish them in the seat map. They behave identically to `paid` seats for the purposes of capacity calculation.

---

---

# CROSS-ENTITY CONSISTENCY RULES

## Cascade Effects

| Trigger | Entity Affected | Effect |
|---------|----------------|--------|
| Route archived | operation_trips (future) | Must not exist. Pre-condition enforced. |
| Trip cancelled | operation_bookings (all) | All → `cancelled`. Seats → `available`. |
| Trip completed | subscriptions | `trips_used += 1` for each subscription seat. |
| Assignment ended mid-day | operation_trips (future) | Dashboard alert: "N رحلة تحتاج إعادة تعيين" |
| Driver suspended | operation_trips (future) | Dashboard alert to reassign driver. Trips not auto-cancelled. |
| Vehicle → maintenance | operation_trips (future) | Dashboard alert to reassign vehicle. Trips not auto-cancelled. |
| Booking approved | trip_seats | state → `paid` |
| Booking cancelled | trip_seats | state → `available`, `passenger_id = null` |
| Seat locked (`reserved`) | booking SLA | 5-minute release timer starts. If no `approved` within 5 min → seat auto-released |
| Subscription expired | future bookings | Payment method `subscription` returns error; client must re-book with alternative payment |

---

## Status Consistency Matrix

At any point in time, the following must be true:

| If... | Then... |
|-------|---------|
| `operation_trips.status = 'in_progress'` | `drivers.operational_status = 'on_trip'` AND `vehicles.operational_status = 'on_trip'` |
| `operation_trips.status = 'completed'` | `drivers.operational_status = 'assigned'` AND `vehicles.operational_status = 'assigned'` |
| `operation_bookings.status = 'approved'` | `trip_seats.state = 'paid'` |
| `operation_bookings.status = 'cancelled'` | `trip_seats.state = 'available'` |
| `operation_bookings.status = 'new_request'` | `trip_seats.state = 'reserved'` |
| `assignments.status = 'active'` | `drivers.current_vehicle_id ≠ null` AND `vehicles.current_driver_id ≠ null` |
| `subscriptions.status = 'expired'` | `trips_used >= total_trips_allowed` OR `valid_to < today` |

Any violation of the above is a **data integrity bug** that must be resolved by the Data layer, not by client-side validation.

---

## Realtime Subscription Map

| App | Listens To | Why |
|-----|-----------|-----|
| Dashboard Live Trips | `live_location:{trip_id}` | Show vehicle on map |
| Dashboard Live Trips | `postgres_changes` on `operation_trips` where `status = 'in_progress'` | Trip health indicators |
| Dashboard Bookings | `postgres_changes` on `operation_bookings` | Real-time queue updates |
| Dashboard Manifest | `postgres_changes` on `trip_passengers` for trip_id | Boarding count updates |
| Client App (tracking) | `live_location:{trip_id}` | Passenger map tracking |
| Client App (booking) | `client:booking:{booking_id}` | Status updates push |
| Captain App (manifest) | `postgres_changes` on `trip_passengers` for trip_id | Manifest boarding sync |
| Captain App (home) | `postgres_changes` on `operation_trips` for driver_id | New assignment detection |

---

## Role Summary

| Role | Primary Entities | Cannot Touch |
|------|-----------------|--------------|
| Admin | All | Nothing |
| Operations Manager | Route, Trip, Driver, Vehicle, Assignment | User management, Archiving |
| Finance Agent | Booking (payment), Subscription (payment) | Fleet, Routes, Trip creation |
| Support Agent | Ticket, Booking (view), Subscription (view) | All write operations |
| Driver | Trip (status transition only), Booking (scan QR only) | All fleet and route entities |
| Client | Booking (own), Subscription (own) | All operational entities |
