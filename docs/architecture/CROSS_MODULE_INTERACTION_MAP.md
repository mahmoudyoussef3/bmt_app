# Cross-Module Interaction Map

This document outlines the dependencies, data flow directions, and synchronization rules between the various modules of the TMS ecosystem.

## 1. Module Dependency Graph

```text
[Auth & Users] <------------------------------------+
       ^                                            |
       |                                            |
[Fleet Management] <---(Assigns)--- [Trip Operations] ---> [Booking & Ticketing]
  (Vehicles, Drivers)                      |                        |
                                           |                        v
                                           |               [Finance & Pricing]
                                           v                        ^
[Route Management] <---(Templates)- (Schedules Trips)               |
  (Paths, Stations)                        |                        |
                                           v                        |
                                    [Live Execution] ---------------+
                                 (Tracking, Boarding)
```

## 2. Cross-Module Side Effects

### A. Fleet Updates Affecting Trips
* **Vehicle Maintenance:** If a vehicle is marked `in_maintenance`, the Fleet module emits an event. The Trip Operations module listens to this and automatically flags or cancels any upcoming trips scheduled for that vehicle, prompting the Dispatcher to assign a replacement.
* **Driver Suspension:** If a driver is suspended, all their future assigned trips are flagged as "Missing Driver".

### B. Route Changes Affecting Trips
* **Station Modifications:** Changes to a `RouteStation` (e.g., adding a new stop) do NOT affect past or currently running `OperationTrips`. However, when a *new* trip is instantiated from that route, it will snapshot the updated stations.

### C. Bookings Affecting Seat Availability (The Critical Path)
* **High-Concurrency Booking:** The Booking module directly depends on the Trip Operations module (specifically `trip_seats`). The interaction is strictly bounded by transactional RPCs in PostgreSQL to ensure no double-booking occurs.
* **Sync Rule:** The Dashboard and Driver App do not poll for seat availability. They listen to the `trip_seats` table via Supabase Realtime. When a seat state changes from `available` to `paid`, the UI updates instantly.

### D. Trip Status Affecting the Client App
* **Status Sync:** When the Live Execution module (Driver App) changes a trip status from `scheduled` to `boarding`, the `operation_trips` table is updated.
* **Realtime Broadcast:** Supabase Realtime pushes this table mutation to the Client App. The Client App UI immediately transitions the passenger's ticket screen from "Waiting" to "Show QR Code to Driver".

## 3. Synchronization Rules

1. **Write Operations:**
   * All write operations (Create, Update, Delete) MUST go through REST APIs or RPCs to the Supabase PostgreSQL database. 
   * Local state is immediately updated optimistically, but reverted if the backend throws an error.

2. **Read & Sync Operations:**
   * **Dashboard:** Fetches initial state via REST. Subscribes to `operation_trips`, `trip_seats`, and `operation_bookings` via WebSockets for live updates.
   * **Driver App:** Fetches daily schedule on launch. Subscribes specifically to the `trip_seats` and `operation_bookings` for their *current active trip* only (to save bandwidth).
   * **Client App:** Fetches search results via REST. Once a booking is made, subscribes to the specific `operation_trips` row to listen for status changes (`boarding`, `in_progress`).

3. **High-Frequency Ephemeral Data:**
   * **Live GPS Tracking:** Driver coordinates are NOT saved to the database on every tick. They are sent to a Supabase Realtime **Broadcast Channel** (e.g., `room:trip_{trip_id}`). The Client App joins this room to receive the live coordinates and update the map marker.

## 4. Single Source of Truth Enforcement
* The Backend (Supabase PostgreSQL) is the absolute Single Source of Truth.
* **No Business Logic in UI:** The frontend applications do NOT calculate whether a seat can be booked, nor do they calculate dynamic pricing discounts locally. They simply display what the backend RPCs and queries return. Validation happens exclusively in the Data layer (Postgres Constraints) and Domain layer (Edge Functions/RPCs).
