# PROJECT_INDEX.md — BMT App Core Documentation

## Read First
This file is the single source of truth for the BMT App project architecture, business logic, entities, and workflows. Any AI agent working on this repository **MUST** read and understand this file before making any modifications.

---

## 1. Project Overview
* **Project Purpose:** A production-ready transportation platform (BMT App) handling operations, fleet, bookings, and trips.
* **Business Domain:** Intercity and intra-city commuter transportation, bus fleet management, and dynamic route operations.
* **System Goals:** Deliver real-time tracking, seamless booking experiences, comprehensive operations management, and strict architectural discipline using real production data.

---

## 2. Applications

The workspace is divided into several applications under `lib/apps/`:

### Client App (`client`)
* **Responsibilities:** Passenger-facing application.
* **Features:** Route discovery, booking seats, purchasing packages/subscriptions, tracking active trips, managing loyalty points, and handling payments.
* **Data Ownership:** Passenger profile, bookings, personal wallet, support tickets.
* **Relationships:** Consumes `operation_trips` and `operation_routes` to create `operation_bookings`.

### Admin Dashboard (`dashboard`)
* **Responsibilities:** Centralized operations management for the entire platform.
* **Features:** Fleet management (drivers, vehicles), route planning, trip creation wizard, dynamic pricing, live tracking, financial reports, and passenger manifests.
* **Data Ownership:** Core operational entities (Routes, Trips, Fleet, Pricing, Global Settings).
* **Relationships:** Controls the lifecycle of all entities consumed by the Client and Driver apps.

### Driver / Captain App (`driver` / `captain`)
* **Responsibilities:** For drivers/captains executing the scheduled trips.
* **Features:** Viewing assigned trips, starting/completing trips, marking route stations, scanning/checking in passengers, and reporting operational alerts (delays, breakdowns).
* **Data Ownership:** Trip events, live location updates, passenger check-in status.
* **Relationships:** Modifies the live state of `operation_trips` and `trip_passengers` created by the dashboard/client apps.

---

## 3. Core Business Flow

The primary operational flow of the system is as follows:

**Fleet & Route Initialization**
`Vehicle` & `Driver` (Created in Fleet Management) 
→ `Route` (Created with interconnected `Route Stations`)

**Trip Lifecycle**
→ `Operation Trip` (Created via Wizard, linking a Route, Vehicle, and Driver)
→ `Trip Pricing` & `Trip Seats` (Configured based on distance and vehicle capacity)
→ **Status**: `scheduled` → `openForBooking`

**Booking & Execution**
→ `Booking` (Client reserves a seat) 
→ `Trip Passenger` (Added to passenger manifest)
→ **Status**: `inProgress` (Driver starts trip)
→ `Trip Events` (Driver marks stations, check-ins, or reports delays)
→ **Status**: `completed` (Trip finishes)

---

## 4. Core Entities

### `OperationTrip` / `Trip`
* **Purpose:** The central executable unit of work.
* **Fields:** ID, Route ID, Driver ID, Vehicle ID, Status, Departure/Arrival Times, Capacity.
* **Relationships:** Has many `TripRoutePoints`, `TripSeats`, `TripPassengers`, `TripPricing`, and `TripEvents`.
* **Validation:** Must have an active driver, active vehicle, and mapped route stations before creation.

### `Vehicle`
* **Purpose:** The physical transport unit.
* **Fields:** Plate Number, Type, Capacity, Seat Configuration.
* **Relationships:** Assigned to Drivers and Trips.

### `Driver`
* **Purpose:** The personnel operating the vehicle.
* **Fields:** Full Name, Phone, Status, Rating.
* **Relationships:** Assigned to Vehicles and Trips.

### `OperationRoute`
* **Purpose:** A templated path from start to end cities.
* **Fields:** Name, Start City, End City, Duration, Status.
* **Relationships:** Has many `RouteStations` defining pickup/dropoff points.

### `Booking`
* **Purpose:** A passenger's reservation on a specific trip.
* **Fields:** Client ID, Trip ID, Seat ID, Payment Status, Amount.
* **Relationships:** Links a Client User to an `OperationTrip` and a specific `TripSeat`.

---

## 5. Architecture

This project strictly adheres to **Flutter Clean Architecture**. Bypassing layers is strictly prohibited.

### Folder Structure
```text
lib/
  apps/
    [app_name]/
      core/
        di/               <-- Dependency Injection setup (GetIt)
      features/
        [feature_name]/
          data/
            datasources/  <-- Supabase API calls (e.g., supabase_trips_datasource.dart)
            models/       <-- Data Transfer Objects mapping JSON to Entities
            repositories/ <-- Repository Implementations
          domain/
            entities/     <-- Core business objects
            repositories/ <-- Interfaces for repositories
            usecases/     <-- Single-responsibility business logic classes
          presentation/
            cubit/        <-- State Management
            screens/      <-- UI Screens
            widgets/      <-- Reusable UI components
```

### Layer Boundaries
* **Presentation** listens to **Domain (UseCases)**.
* **Domain** defines interfaces and entities.
* **Data** implements repositories and calls backend **Datasources**.
* **Rule:** A `Cubit` MUST NEVER call a `Datasource` directly. A `Widget` MUST NEVER call a `Repository` directly.

---

## 6. State Management

The application uses **Cubit / Bloc** (from `flutter_bloc`) for state management.
* Each feature has a `Cubit` (e.g., `TripsListCubit`).
* States are strictly typed (e.g., `Initial`, `Loading`, `Loaded`, `Error`).
* Cubits invoke `UseCases` to fetch or mutate data and emit new states.

---

## 7. Backend Integration

The project relies entirely on **Supabase (PostgreSQL)** as its backend.
* **Database:** Relational schema containing `operation_trips`, `operation_routes`, `drivers`, `vehicles`, `operation_bookings`, `trip_seats`, `packages`, etc.
* **Auth:** Supabase Auth for Client and Dashboard authentication.
* **Data Flow:** `SupabaseClient` is injected via GetIt into `Supabase*Datasource` classes. Datasources execute `.from('table').select().eq(...)` queries and return strongly-typed Models.

---

## 8. Dashboard Workflow

* **Fleet Management:** Admins create Vehicles and Drivers, mark them as active/suspended, and upload documents.
* **Route Management:** Admins define interconnected Route Stations and group them into an Operation Route.
* **Trip Creation Wizard:** Admins select a route, vehicle, and driver. The system automatically snapshots route stations into `trip_route_points` and generates seat layouts into `trip_seats`.
* **Trip Pricing:** Admins set base prices, multi-day package prices, and subscriptions for specific trips.
* **Live Monitoring:** Operations team tracks active trips, resolves alerts reported by drivers, and views passenger manifests.

---

## 9. Development Rules

* **Strict Clean Architecture:** All features must be split into `data`, `domain`, and `presentation`.
* **Dependency Injection:** Use GetIt. All services, repositories, and datasources MUST be registered in `core/di/[app]_di.dart`. Manual instantiation in UI/Cubits is forbidden.
* **Production-Ready UX:** All UIs must feel premium, use proper spacing/typography, support RTL (Arabic), and be fully responsive.
* **No Placeholders:** All buttons must work. No "Coming Soon" or empty screens.
* **Error Handling:** Catch exceptions in the Data layer, map them to Failures/Result objects, and expose user-friendly messages in the Presentation layer.

---

## 10. Mock Data Policy & Audit

### Findings
During the initial prototyping phase, several features were built using Mock Datasources, including but not limited to:
* `MockSeatReleaseDatasource`
* `MockTrackingDatasource`
* `MockSettingsDatasource`
* `MockNotificationsDatasource`
* `MockReferralRewardsDatasource`
* `MockFinanceDatasource`
* `MockSubscriptionsDatasource`
* `MockDashboardHomeDatasource`
* `MockDashboardOperationsDatasource`
* `MockBookingPaymentVerificationDatasource`
* `MockPaymentsDatasource`
* `MockLiveTripsDatasource`

### The Policy
**Mock data is strictly prohibited in the final production release.**
* Future AI agents working on any feature MUST audit the respective DI file (e.g., `client_di.dart`, `dashboard_di.dart`) and check if a `Mock*Datasource` is being used.
* If a mock datasource is found, the agent **MUST** write a real `Supabase*Datasource` equivalent, connect it to the actual Supabase database tables, update the DI registration, and remove the mock class entirely.
* Never generate temporary fake data, hardcoded lists, or `List.generate()` dummy responses. Always design database tables and pull real data.
