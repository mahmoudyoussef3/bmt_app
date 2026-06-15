# Event System Architecture

The TMS uses an Event-Driven Architecture powered by **PostgreSQL Triggers**, **Supabase Realtime (WebSockets)**, and **Supabase Edge Functions** for background processing.

## Real-Time Sync Rules
All cross-app synchronization happens via Supabase Realtime channels. Apps subscribe to specific rows or tables.

---

## Core System Events

### 1. `TripCreated`
* **Trigger Source:** Dashboard (Insert into `operation_trips`)
* **Payload:** `{ trip_id, route_id, driver_id, vehicle_id, date, status }`
* **Side Effects (Postgres Trigger):** Generates default `trip_seats` based on vehicle capacity. Generates `trip_pricing` matrix from Route templates.
* **Consumers:** Driver App (adds to upcoming schedule).

### 2. `TripStatusChanged` (Started / Completed)
* **Trigger Source:** Driver App (Update `operation_trips.status`)
* **Payload:** `{ trip_id, old_status, new_status, timestamp }`
* **Side Effects (Edge Function):**
  - If `boarding`, sends Push Notification to all booked passengers: "Your bus is boarding".
  - If `completed`, updates Driver status to `available` and Vehicle status to `available`.
* **Real-time Updates:** Client App UI updates to show live tracking map. Dashboard updates KPI counters.

### 3. `SeatBooked`
* **Trigger Source:** Client App / RPC `book_seat`
* **Payload:** `{ booking_id, trip_id, seat_id, client_id, status: 'confirmed' }`
* **Side Effects:** 
  - Updates `trip_seats.state` to `reserved` or `paid`.
  - Creates a `booking` record with a secure `qr_code_token`.
* **Real-time Updates:** Dashboard "Live Trips" instantly decrements "Available Seats". Driver App passenger manifest updates instantly.

### 4. `BookingCancelled`
* **Trigger Source:** Client App or Dashboard (Update `operation_bookings.status = 'cancelled'`)
* **Payload:** `{ booking_id, trip_id, seat_id, client_id }`
* **Side Effects:**
  - Frees the seat: `UPDATE trip_seats SET state = 'available', passenger_id = null WHERE id = seat_id`.
  - Triggers refund logic (Edge Function to Payment Gateway or Wallet).
* **Real-time Updates:** Seat becomes immediately available on the Client App booking screen.

### 5. `DriverLocationUpdated`
* **Trigger Source:** Driver App (Background Geolocation SDK via Supabase Realtime Broadcast, *Not persisted to DB to save costs*)
* **Payload:** `{ trip_id, lat, lng, speed, bearing }`
* **Consumers:** Client App (Live Map), Dashboard (Fleet Tracking).
* **Real-time Updates:** High-frequency (every 3-5 seconds) websocket broadcast.

### 6. `VehicleAssigned`
* **Trigger Source:** Dashboard (Insert `assignments`)
* **Payload:** `{ driver_id, vehicle_id, start_date }`
* **Side Effects:** Updates Driver status to `assigned`. Updates Vehicle status to `assigned`.
* **Consumers:** Driver App (Shows newly assigned vehicle details).
