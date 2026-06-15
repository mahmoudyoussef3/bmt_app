# System Flow

This document details the complete end-to-end flow of the Transportation Management System.

---

## FLOW 1: Fleet Setup Flow (Vehicle → Driver → Assignment)
**Actor:** Admin (Dashboard)
1. **Create Vehicle:** Admin inputs plate number, capacity, and model into Dashboard. Backend saves to `vehicles` (Status: `available`).
2. **Create Driver:** Admin inputs driver details and license. Backend saves to `drivers` and creates Auth User (Status: `available`).
3. **Assignment:** Admin assigns Driver X to Vehicle Y.
   - **Data Changes:** `assignments` record created. `drivers.status` -> `assigned`. `vehicles.status` -> `assigned`.
   - **Events Triggered:** `VehicleAssigned`
   - **Cross-App Updates:** Driver App updates home screen to show current assigned vehicle.

---

## FLOW 2: Route Creation Flow (Route → Stops → Validation → Activation)
**Actor:** Admin (Dashboard)
1. **Define Path:** Admin sets Start City, End City, and basic distance.
2. **Add Stations:** Admin drops stations on the map, setting `arrival_offset_mins` for each to define the timeline relative to trip start.
3. **Validation:** Backend ensures at least 2 stations exist (Start & End), and `sort_order` is sequential.
4. **Activation:** Route saved to `routes` and `route_stations`. Status -> `active`.

---

## FLOW 3: Trip Creation Flow (Route + Vehicle + Driver → Trip → Publish)
**Actor:** Dispatcher (Dashboard)
1. **Instantiate:** Dispatcher selects Route, Date, Departure Time, and assigns an `assigned` Driver/Vehicle pair.
2. **Validation:** Backend RPC ensures Driver/Vehicle are not double-booked at this time.
3. **Trip Creation:** Record inserted into `operation_trips` (Status: `scheduled`).
4. **Auto-Generation (Side Effects):** 
   - Backend reads vehicle capacity (e.g., 14) and auto-generates 14 rows in `trip_seats` (State: `available`).
   - Backend auto-generates `trip_pricing` matrix for all valid station-to-station combinations based on route defaults.
5. **Publishing:** 
   - **Events Triggered:** `TripCreated`.
   - **Cross-App Updates:** Trip instantly becomes searchable on the Client App. Appears in Driver App schedule.

---

## FLOW 4: Booking Flow (Client App)
**Actor:** Passenger (Client App)
1. **Search:** Client searches "City A to City B on Friday". App queries `operation_trips` joined with `trip_pricing`.
2. **Seat Selection:** Client views seat map. Taps Seat A1.
3. **Locking:** App calls RPC `lock_seat`. `trip_seats.state` -> `reserved`. (5-minute timeout starts).
4. **Payment:** Client pays via Wallet/Card.
5. **Confirmation:**
   - **Data Changes:** `operation_bookings` created. `trip_seats.state` -> `paid`. `passenger_id` linked.
   - **Events Triggered:** `SeatBooked`.
   - **Cross-App Updates:** Driver App passenger manifest updates in real-time. Dashboard Live view decrements available seats. Client receives QR Code.

---

## FLOW 5: Trip Execution Flow (Driver App)
**Actor:** Driver (Driver App)
1. **Start Boarding:** 30 mins before departure, Driver taps "Start Boarding". 
   - `operation_trips.status` -> `boarding`. Passengers get push notifications.
2. **Ticket Scanning:** Passengers board. Driver scans QR Codes. RPC `scan_passenger_ticket` validates booking.
3. **Start Moving:** Driver taps "Start Trip". 
   - `operation_trips.status` -> `in_progress`. Bookings lock.
4. **Live Tracking:** Driver App broadcasts GPS via Supabase Realtime (`DriverLocationUpdated`). Client App map markers move smoothly.
5. **Completion:** Driver arrives at final station and taps "End Trip".
   - `operation_trips.status` -> `completed`.
   - **Events Triggered:** `TripCompleted`.

---

## FLOW 6: Seat Management Flow
**System Automated Flow**
1. **Capacity Setup:** Vehicle capacity determines seat matrix layout.
2. **Booking Attempt:** Concurrent users attempt to book Seat A1.
3. **Conflict Handling:** RPC `book_seat` uses Postgres Row-Level Locks (`SELECT ... FOR UPDATE`). First user wins. Second user gets `400 Bad Request: Seat Unavailable`.
4. **Cancellation:** If User 1's payment fails or timeouts, pg_cron or Edge Function triggers `BookingCancelled`, freeing the seat instantly.

---

## MASTER SYSTEM FLOW DIAGRAM (TEXT)

```text
[FLEET SETUP]
  Admin creates Vehicle + Driver
         |
         v
  Admin assigns Driver -> Vehicle (Assignment Active)

[PLANNING]
  Admin creates Route + RouteStations
         |
         v
  Dispatcher schedules OperationTrip (Route + Assignment + Time)
         |
         +-- (Auto-Generates) --> TripSeats (Available) based on Vehicle Capacity
         +-- (Auto-Generates) --> TripPricing Matrix

[DISCOVERY & BOOKING]
  Client App queries upcoming Scheduled Trips
         |
         v
  Client selects Trip -> Selects Seat -> Pays -> Booking Confirmed
         |
         +-- (Updates) --> TripSeat becomes 'Paid'
         +-- (Realtime) -> Dashboard Capacity Updates
         +-- (Realtime) -> Driver App Manifest Updates

[EXECUTION]
  Driver opens Driver App -> Taps "Start Boarding"
         |
         +-- (Push Notification) -> Client: "Bus is boarding!"
         v
  Passengers board -> Driver Scans QR Codes -> Validates Bookings
         |
         v
  Driver taps "Start Trip" -> Status: 'In Progress'
         |
         +-- (Realtime Broadcast) -> Live GPS Coordinates
         v
  Client App tracks Bus live on Map
         |
         v
  Driver reaches final destination -> Taps "End Trip" -> Status: 'Completed'
```
