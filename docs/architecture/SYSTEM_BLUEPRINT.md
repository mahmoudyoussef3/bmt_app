# System Blueprint

## 1. System Architecture Overview
The Transportation Management System (TMS) is built on a **Flutter Clean Architecture** for the front-end (Presentation -> Domain -> Data) and **Supabase (PostgreSQL + PostgREST + Realtime + Edge Functions)** for the backend. 

The ecosystem consists of three primary applications that interact with the unified backend:
1. **Operation Dashboard (Admin App):** Web/Desktop app for dispatchers and fleet managers to manage resources, schedule trips, monitor operations, and handle financials.
2. **Driver App:** Mobile app for drivers to view schedules, manage live trips, scan tickets, track boarding, and handle cash collection.
3. **Client App:** Mobile/Web app for passengers to search routes, book seats, buy subscriptions, track vehicles live, and handle payments.

## 2. Core Modules & Responsibilities
- **Fleet Management:** Manages vehicles, drivers, documents, maintenance, and asset assignment.
- **Route Management:** Defines geographical paths, station sequences, arrival offsets, and pickup/dropoff rules.
- **Trip Operations (Dispatch):** Instantiates routes into executable "Trips" with specific schedules, vehicles, drivers, and capacities.
- **Booking & Ticketing:** Handles passenger seat reservations, conflict resolution, payment status, and QR-code ticketing.
- **Pricing & Subscriptions:** Manages dynamic trip segment pricing, multi-day/monthly packages, and loyalty systems.
- **Live Execution:** Event-driven module for real-time location tracking, trip state transitions (Boarding -> InProgress -> Completed), and passenger updates.

## 3. Complete Entity List
* **User (Auth):** Core identity for clients, drivers, and admins.
* **Driver:** Personnel records, licenses, statuses.
* **Vehicle:** Fleet assets, capacities, plate numbers, maintenance status.
* **Assignment:** Mapping of drivers to vehicles.
* **Route:** Blueprint of a geographical path.
* **RouteStation:** Specific points on a route with sequential ordering.
* **OperationTrip:** A scheduled instance of a route.
* **TripSeat:** Physical seat availability and state for a specific trip.
* **TripPricing:** Matrix of pricing for from-to station segments and package types.
* **Booking / Passenger:** A client's reservation on a specific trip, mapping to a seat.
* **Subscription:** A pre-paid package allowing a user to book multiple trips.
* **Payment:** Financial transactions linked to bookings/subscriptions.
* **Notification:** System alerts pushed to users.

## 4. Full System Relationships
- **Vehicle** (1) -> (M) **OperationTrip**
- **Driver** (1) -> (M) **OperationTrip**
- **Route** (1) -> (M) **RouteStation**
- **Route** (1) -> (M) **OperationTrip**
- **OperationTrip** (1) -> (M) **TripSeat**
- **OperationTrip** (1) -> (M) **Booking (TripPassenger)**
- **OperationTrip** (1) -> (M) **TripPricing**
- **Booking** (1) -> (1) **TripSeat**
- **User (Client)** (1) -> (M) **Booking**
- **User (Client)** (1) -> (M) **Subscription**

## 5. High-Level Workflows
1. **Provisioning:** Admin adds Vehicles and Drivers to the fleet.
2. **Planning:** Admin designs Routes and Route Stations.
3. **Scheduling:** Admin schedules Operation Trips by attaching a Route, Driver, Vehicle, and Time.
4. **Publishing:** The system automatically generates Seat Maps and Pricing Matrices for the Trip.
5. **Booking:** Client discovers the Trip, selects an available Seat, pays, and secures a Booking.
6. **Execution:** Driver starts the Trip, live location broadcasts, passengers board via QR scan, Trip completes.

## 6. Cross-App Interaction
* **Dashboard -> Supabase -> Driver App:** Dispatcher schedules a trip -> Driver receives push notification and sees it in "Upcoming Trips".
* **Dashboard -> Supabase -> Client App:** Dispatcher updates a route's pricing -> Client app instantly reflects new prices on search.
* **Client App -> Supabase -> Dashboard:** Client books a seat -> Dashboard Trips module updates seat occupancy in real-time.
* **Driver App -> Supabase -> Client App:** Driver starts moving -> Supabase Realtime broadcasts GPS coordinates -> Client App map markers move smoothly.
