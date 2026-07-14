# System Flow

Complete end-to-end operational flows for the Transportation Management Platform.  
**Apps:** Dashboard · Client · Captain (Driver)  
**Backend:** Supabase (PostgreSQL + Auth + Realtime + Storage)

---

## FLOW 1 — Fleet Setup (Vehicle → Driver → Assignment)

**Actor:** Admin / Operations Manager (Dashboard)

```
1. Create Vehicle
   └─ Dashboard: input plate, capacity, model, seat layout
   └─ DB: INSERT vehicles (status = 'active')
   └─ ✦ Auto-generates SeatConfiguration JSON from capacity

2. Create Driver
   └─ Dashboard: input name, phone, license number, expiry
   └─ DB: INSERT drivers (status = 'active')
   └─ Auth: Supabase auth invite email sent to driver

3. Create Assignment
   └─ Dashboard: select active driver + active vehicle
   └─ Precondition: neither has an existing active assignment
   └─ DB: INSERT assignments (status = 'active')
   └─ DB: UPDATE drivers SET current_vehicle_id = vehicle.id
   └─ DB: UPDATE vehicles SET current_driver_id = driver.id
   └─ Captain App: home screen shows assigned vehicle card
```

**Cross-app effect:** Assignment created → Captain App `watchTripUpdates()` stream fires → home screen refresh.

---

## FLOW 2 — Route Creation (Path → Stations → Publish)

**Actor:** Admin / Operations Manager (Dashboard)

```
1. Define Route
   └─ Input: name, start_city, end_city, distance_km, duration_mins
   └─ DB: INSERT routes (status = 'draft')

2. Add Stations
   └─ For each station: name, area, lat/lng, arrival_offset_mins, pickup_allowed, dropoff_allowed
   └─ DB: INSERT route_stations with sequential sort_order
   └─ Constraint: sort_order is UNIQUE per route

3. Validate
   └─ Precondition: ≥ 2 stations
   └─ Precondition: ≥ 1 station with pickup_allowed = true
   └─ Precondition: ≥ 1 station with dropoff_allowed = true

4. Publish
   └─ Dashboard: click "نشر المسار"
   └─ DB: UPDATE routes SET status = 'active'
   └─ Client App: route now appears in search results
```

---

## FLOW 3 — Trip Scheduling (Route + Fleet → Trip → Publish)

**Actor:** Dispatcher / Operations Manager (Dashboard)

```
1. Create Trip (Wizard Step 1–3)
   └─ Select route, date, departure_time
   └─ Select driver (must have active assignment)
   └─ Select vehicle (must be same vehicle in driver's assignment)
   └─ Conflict check: RPC rejects if driver has overlapping trip on same date
   └─ DB: INSERT operation_trips (status = 'scheduled')

2. Auto-generation (immediate side effects)
   └─ RPC generate_trip_seats: inserts N rows in trip_seats (state = 'available')
      where N = vehicle.capacity
   └─ RPC (or trigger): inserts trip_pricing matrix for all valid
      station-pair combinations at default prices

3. Configure Pricing
   └─ Dashboard: review and adjust trip_pricing rows
   └─ Each pair (from_station, to_station) has: one_time_price, five_days_price, monthly_price

4. Publish (Open for Booking)
   └─ Dashboard: click "فتح الحجز"
   └─ RPC update_trip_status(trip_id, 'open_for_booking')
   └─ DB: operation_trips.status = 'open_for_booking'
   └─ Client App: trip becomes searchable and bookable
   └─ Captain App: trip visible in assigned schedule
   └─ Push: passengers subscribed to this route are notified
```

**Status machine at this stage:** `scheduled` → `open_for_booking`

---

## FLOW 4 — Booking (Client App — Seat Reservation & Payment)

**Actor:** Passenger (Client App)

```
1. Search
   └─ Client App queries operation_trips WHERE status = 'open_for_booking'
      filtered by route, date

2. Select Trip
   └─ View route stops, departure time, vehicle type, available seats count

3. Select Seat
   └─ Seat map loaded from trip_seats WHERE state = 'available'
   └─ Client taps seat → seat turns to pending state (UI only)

4. Lock Seat (transactional)
   └─ RPC book_trip_seat called (SELECT ... FOR UPDATE on trip_seats)
   └─ DB: trip_seats.state = 'reserved', passenger_id = client.id
   └─ DB: trip_passengers INSERT (status = 'reserved')
   └─ DB: operation_bookings INSERT (status = 'newRequest', payment_status = 'unpaid')
   └─ DB: booking_number generated, qr_code_token generated
   └─ Error if seat state != 'available': second concurrent user gets "Seat unavailable"
   └─ 5-minute lock timer starts: Edge Function releases seat if not approved

5. Upload Payment Receipt
   └─ Client uploads image to Supabase Storage
   └─ DB: operation_bookings.status = 'paymentUploaded', receipt_url stored
   └─ Push to Dashboard finance agents: "إيصال جديد في انتظار المراجعة"

6. Dashboard Review
   └─ Finance Agent opens booking: DB status → 'underReview'
   └─ Agent views receipt image

   ┌── APPROVE PATH ────────────────────────────────────────────────────┐
   │  RPC approve_booking(booking_id)                                   │
   │  DB: bookings.status = 'approved', payment_status = 'paid'        │
   │  DB: trip_seats.state = 'paid'                                     │
   │  Push to client: "تم تأكيد حجزك — QR جاهز"                       │
   │  Client App: QR code is now active and scannable                   │
   └────────────────────────────────────────────────────────────────────┘

   ┌── REQUEST REUPLOAD PATH ───────────────────────────────────────────┐
   │  DB: bookings.status = 'requestReupload', rejection_reason stored  │
   │  Push to client with reason — client re-uploads                    │
   │  DB: bookings.status → 'paymentUploaded' again                    │
   └────────────────────────────────────────────────────────────────────┘

   ┌── REJECT PATH ─────────────────────────────────────────────────────┐
   │  RPC reject_booking(booking_id, reason)                            │
   │  DB: bookings.status = 'rejected'                                  │
   │  DB: trip_seats.state = 'available', passenger_id = null          │
   │  DB: trip_passengers.status = 'cancelled'                          │
   │  Push to client with rejection reason                              │
   └────────────────────────────────────────────────────────────────────┘
```

---

## FLOW 5 — Subscription Booking (Client App — Package Purchase)

**Actor:** Passenger (Client App) or Finance Agent (Dashboard)

```
1. Purchase Subscription
   └─ Client selects route, from/to stations, package type (5-day/monthly/etc.)
   └─ DB: INSERT subscriptions (status = 'pendingPayment')
   └─ Client uploads payment receipt

2. Dashboard Verifies Payment
   └─ Finance Agent: UPDATE subscriptions SET status = 'active'
   └─ Push to client: "تم تفعيل اشتراكك"

3. Using Subscription for Booking
   └─ Client selects payment_method = 'subscription' during seat booking
   └─ RPC validate_subscription_for_booking checks:
      - status = 'active'
      - trips_used < total_trips_allowed
      - valid_from <= today <= valid_to
   └─ DB: trip_seats.state = 'subscription' (distinguishes from paid cash)
   └─ No receipt upload needed — subscription is pre-verified

4. Auto-Consume on Boarding
   └─ When captain scans QR and booking becomes 'confirmed':
      UPDATE subscriptions SET trips_used = trips_used + 1
   └─ If trips_used reaches total_trips_allowed:
      UPDATE subscriptions SET status = 'expired'
   └─ Push at 2 remaining: "تبقى رحلتان في اشتراكك"
   └─ Push at 0 remaining: "انتهت رحلات اشتراكك"

5. Expiry (pg_cron — daily)
   └─ UPDATE subscriptions SET status = 'expired'
      WHERE status = 'active' AND valid_to < today
```

---

## FLOW 6 — Trip Execution (Captain App)

**Actor:** Driver (Captain App)

```
1. Trip Appears in Schedule
   └─ Captain App displays trips with status in
      ['scheduled', 'open_for_booking', 'boarding', 'in_progress']
   └─ Trip card shows route, departure time, passenger count

2. Start Boarding (≤90 min before departure)
   └─ Captain taps "بدء صعود الركاب"
   └─ Precondition: current time within 90 min of departure_time
   └─ RPC update_trip_status(trip_id, 'boarding')
   └─ DB: status = 'boarding', actual_start_time = now()
   └─ DB: all 'reserved' seats with expired lock times → released to 'available'
   └─ Push to all approved passengers: "الحافلة تستقبل الركاب الآن"
   └─ Client App: tracking screen shows "جاري التجميع"

3. Scan Passenger QR Codes
   └─ Captain opens QR scanner
   └─ Camera reads booking qr_code_token
   └─ RPC scan_passenger_ticket(trip_id, qr_code_token)

   ┌── VALID SCAN ──────────────────────────────────────────────────────┐
   │  Checks: booking.status IN ('approved', 'confirmed')              │
   │  Checks: trip_passengers.status != 'confirmed' (not already       │
   │          boarded)                                                  │
   │  DB: operation_bookings.status = 'confirmed'                      │
   │  DB: trip_passengers.status = 'confirmed'                         │
   │  Response: passenger_name, seat_label, pickup_point               │
   │  Captain App: green flash + haptic + passenger card displayed     │
   └────────────────────────────────────────────────────────────────────┘

   ┌── ALREADY BOARDED ────────────────────────────────────────────────┐
   │  Response: error 'already_checked_in'                             │
   │  Captain App: amber warning — "هذا الراكب صعد بالفعل"           │
   └────────────────────────────────────────────────────────────────────┘

   ┌── INVALID QR ─────────────────────────────────────────────────────┐
   │  Response: error 'ticket_not_approved'                            │
   │  Captain App: red flash — "تذكرة غير صالحة"                     │
   └────────────────────────────────────────────────────────────────────┘

   └─ Offline: QR scan stored locally, flushed when connectivity returns

4. Start Trip
   └─ Captain taps "بدء الرحلة"
   └─ RPC update_trip_status(trip_id, 'in_progress')
   └─ DB: status = 'in_progress'
   └─ DB: drivers.status = 'on_trip' (or derived)
   └─ GPS broadcast channel opens: live_location:{trip_id}
   └─ Push to all not-yet-boarded passengers: "الرحلة انطلقت"
   └─ Client App: tracking screen becomes active with live map

5. Live Location Broadcasting
   └─ Background service (Android foreground service) runs every 5 seconds:
      Geolocator.getPositionStream → broadcast on live_location:{trip_id}
   └─ Every 30 seconds: INSERT trip_live_locations (lat, lng, speed, timestamp)
   └─ Client App tracking screen: map shows vehicle position

6. End Trip
   └─ Captain taps "إنهاء الرحلة"
   └─ RPC update_trip_status(trip_id, 'completed')
   └─ DB: status = 'completed', actual_end_time = now()
   └─ DB: all passengers with status NOT IN ('confirmed', 'cancelled',
          'no_show') → status = 'no_show' (automatic no-show recording)
   └─ DB: subscriptions used for this trip: trips_used incremented
   └─ GPS broadcast channel closes
   └─ Push to all boarded passengers: "شكراً لاستخدامك EasyWay"
```

---

## FLOW 7 — Cancellation (Any Actor)

### Booking Cancellation (by Client)
```
Precondition: booking.status NOT IN ('confirmed', 'cancelled', 'rejected')
Precondition: trip.status NOT IN ('boarding', 'in_progress', 'completed')
RPC cancel_booking(booking_id)
└─ DB: booking.status = 'cancelled'
└─ DB: trip_seats.state = 'available', passenger_id = null
└─ DB: trip_passengers.status = 'cancelled'
└─ If payment_status = 'paid': refund workflow triggered
└─ Push: booking cancellation confirmation + refund status
```

### Trip Cancellation (by Ops)
```
Precondition: trip.status NOT IN ('in_progress', 'completed')
RPC update_trip_status(trip_id, 'cancelled')
└─ DB: status = 'cancelled', actual_end_time = now()
└─ DB: ALL trip_seats → state = 'available'
└─ DB: ALL operation_bookings → status = 'cancelled'
└─ DB: ALL paid bookings → payment_status = 'refunded'
└─ Push to all booked passengers: "تم إلغاء الرحلة — سيتم الاسترداد"
```

---

## FLOW 8 — No-Show Handling (Automatic)

```
Trigger: update_trip_status(trip_id, 'completed')

For every trip_passenger WHERE status NOT IN ('confirmed', 'cancelled', 'no_show', 'completed'):
   UPDATE trip_passengers SET status = 'no_show'

Dashboard reporting:
   └─ Trip completion report shows: X boarded, Y no-shows, Z cancelled
   └─ No-show rate tracked per route for pricing strategy
```

---

## FLOW 9 — Seat Lock Timeout (Automated — Edge Function / pg_cron)

```
Every 5 minutes (pg_cron):
  SELECT trip_seats WHERE state = 'reserved' AND lock_expires_at < now()
  
  For each expired lock:
    UPDATE trip_seats SET state = 'available', passenger_id = null
    UPDATE operation_bookings SET status = 'cancelled'
       WHERE seat_id = expired_seat AND status = 'newRequest'
    UPDATE trip_passengers SET status = 'cancelled'
       WHERE seat_id = expired_seat AND status = 'reserved'
    
    Push to client: "انتهت مهلة حجز مقعدك. يرجى إعادة المحاولة."
```

---

## MASTER STATUS TRANSITIONS REFERENCE

### Trip Status Machine
```
scheduled ──(publish)──────→ open_for_booking
scheduled ──(cancel)───────→ cancelled
open_for_booking ─(board)──→ boarding
open_for_booking ─(cancel)─→ cancelled
boarding ──(start)─────────→ in_progress
boarding ──(cancel*)───────→ cancelled        * admin only
in_progress ──(complete)───→ completed
in_progress ──(cancel*)────→ cancelled        * admin only
```

### Booking Status Machine
```
[seat locked] → newRequest ──(upload)──→ paymentUploaded
paymentUploaded ──(review)──→ underReview
underReview ──(approve)─────→ approved
underReview ──(reject)──────→ rejected          [seat released]
underReview ──(reupload)────→ requestReupload
requestReupload ──(upload)──→ paymentUploaded
approved ──(qr_scan)────────→ confirmed         [physically boarded]
[any except confirmed] ──(cancel)──→ cancelled  [seat released]
```

### Seat State Machine
```
available ──(lock)──────→ reserved       (on booking attempt)
reserved ──(approve)────→ paid           (booking approved)
reserved ──(subscription_book)──→ subscription
reserved ──(timeout/reject/cancel)──→ available
paid ──(cancel)─────────→ available
subscription ──(cancel)─→ available
available ──(ops_block)─→ blocked        (manual ops action)
blocked ──(ops_unblock)─→ available
```

### Realtime Channel Map

| Channel | Type | Producer | Consumer | Payload |
|---------|------|----------|----------|---------|
| `live_location:{trip_id}` | Broadcast | Captain background service | Client tracking | `{lat, lng, speed, timestamp}` |
| `operation_trips` stream | postgres_changes | DB trigger | Captain App (assigned trips) | Full row |
| `trip_passengers` stream | postgres_changes | DB (scan RPC) | Captain manifest | Full row |
| `captain_messages` stream | postgres_changes | DB insert | Captain chat | Full row |
| `operation_bookings` stream | postgres_changes | DB (book/approve RPC) | Dashboard bookings queue | Full row |

> **Push Notifications** (FCM/APNs via Supabase Edge Function) handle: boarding_started, booking_approved, booking_rejected, trip_cancelled, subscription_activated, subscription_expiring, no-show events. These are NOT Supabase Realtime channels.
