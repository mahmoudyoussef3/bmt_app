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
* **Features:** Fleet management (drivers, vehicles), route planning, trip creation wizard, dynamic pricing, driver-sent location updates, financial reports, and passenger manifests.
* **Data Ownership:** Core operational entities (Routes, Trips, Fleet, Pricing, Global Settings).
* **Relationships:** Controls the lifecycle of all entities consumed by the Client and Driver apps.

### Driver / Captain App (`driver` / `captain`)
* **Responsibilities:** For drivers/captains executing the scheduled trips.
* **Features:** Viewing assigned trips, starting/completing trips, marking route stations, scanning/checking in passengers, and reporting operational alerts (delays, breakdowns).
* **Data Ownership:** Trip events, one-time location updates with timestamps, passenger check-in status.
* **Relationships:** Modifies the live state of `operation_trips` and `trip_passengers` created by the dashboard/client apps.

#### Captain Onboarding (Self-Service Access Requests)
* **Flow:** Captain app → sign up (name + phone) → `submit_captain_request` RPC inserts a `captain_requests` row (pending). The app polls `get_captain_request_status` (no SMS/OTP). Dashboard → **طلبات الكباتن** queue (`captain_requests` feature, under Fleet) → operator **accepts** (reuses the fleet driver form to complete the full driver record, creating an *active* `drivers` row linked back via `captain_requests.driver_id`) or **rejects** with a reason. On approval the captain's poll flips to an approved welcome home (local session, `CaptainSessionStore`); a rejection shows the operator's reason with re-apply.
* **Ownership:** The Dashboard remains the source of truth — the driver record only exists once an operator completes it. `captain_requests` review is admin-gated (`DashboardPermission.captainRequests`).
* **Activation (local session → operational session):** The welcome home is a waiting room, not a dead end. `CaptainActivationCubit` re-attempts the phone sign-in below on open, on pull-to-refresh and on a 20s poll; the moment the driver record is active it establishes a real Supabase session and the auth gate swaps the captain into the operational shell — no sign-out/sign-in round trip. A sign-out also drops the local session (in the gate), so it can never re-authenticate the captain straight back in.
* **Migration:** `supabase/migrations/20260705120000_captain_access_requests.sql`.

#### Captain Sign In (Returning Captains — Phone Only)
* **Flow:** No password, no OTP. The captain enters only their phone number. `resolve_captain_login` (anon-callable RPC) normalizes the phone and checks it against `drivers` for an *active* match; if found it derives a stable email + secret from the phone (`hmac(phone, ...)`, same output every time for that phone). The app signs in with that pair — or signs up the first time, since this Supabase project auto-confirms email signups — then calls `link_current_captain_driver` to bind the resulting `auth.uid()` to `drivers.user_id`. Every subsequent app open with a live session reads the driver profile straight off `drivers.user_id`.
* **Why derived credentials instead of anonymous auth:** anonymous sign-ins are disabled on this project, and this avoids needing a service-role edge function. The same phone always re-derives the same auth account, so the link is stable across reinstalls without an anon-auth UID churning each install.
* **Trade-off:** no proof-of-possession of the phone number (no SMS/OTP) — same no-SMS trust model as the onboarding request above. Knowing a driver's phone is enough to sign in as them.
* **Migration:** `supabase/migrations/20260708120000_captain_phone_login.sql`. Supersedes the earlier `link_current_driver_account()` (SMS-OTP design that was never actually wired up — `drivers.user_id` was NULL for every driver in production before this fix).

#### Persistent Login & Remember Me (Client + Captain)
* **Persistent session (already provided by Supabase):** `supabase_flutter`'s local session cache is the source of truth for "stay logged in" — `Supabase.initialize()` restores a saved session before either app's `home:` widget builds. `ClientApp._buildLandingScreen` and `_CaptainAuthGate` both check `Supabase.instance.client.auth.currentSession` / `onAuthStateChange` and route straight to the shell when a session exists, skipping Login entirely. No custom "session token" storage was added for this — duplicating Supabase's own persisted session would be a second source of truth for the same fact. `ClientSplashGate` holds the branded splash on screen until onboarding/auth state resolves, so there is no login-screen flash on a warm start.
* **Remember Me is a separate, local-only cache — not the session.** It only prefills the login form; it never authenticates by itself. Signing out clears the Supabase session but deliberately leaves Remember Me alone, so a returning rider/captain still sees their field(s) prefilled and the checkbox pre-checked next time, per the feature's own point.
  * **Client (email + password):** `RememberMeStore` (`apps/client/core/storage/`) writes through the shared `SecureStorage` (Keychain/Keystore-backed) — a password must never sit in `SharedPreferences`. Domain surface: `RememberMeRepository` + `Save/Get/ClearRememberedCredentialsUseCase`, orchestrated by `ClientAuthCubit.signIn(..., rememberMe:)` and read back via `loadRememberedCredentials()` in `SignInScreen.initState`.
  * **Captain (phone only):** captain sign-in has no password (see phone-only flow above), so `CaptainRememberMeStore` uses `SharedPreferences`, the same tier already used by `CaptainSessionStore`. Domain surface mirrors the client: `CaptainRememberMeRepository` + `Save/Get/ClearRememberedPhoneUseCase`, orchestrated by `CaptainAuthCubit.signIn(..., rememberMe:)`.
  * **Why decoupled from the sign-in usecase itself:** `SignInCaptainUseCase` is also called by `CaptainActivationCubit`'s silent background poll (re-establishing the operational session once a pending driver record goes active). If Remember Me lived inside `signInWithPhone`/`signInWithEmail`, that unrelated poll would repeatedly overwrite or clear whatever the captain actually chose on the login screen. Keeping Remember Me as sibling usecases that only `CaptainAuthCubit`/`ClientAuthCubit` (the actual login-screen cubits) call avoids that collision.
  * A storage read/write failure degrades to "nothing remembered" and never blocks sign-in or turns a successful login into a reported failure.

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
* **Trip Pricing (single source of truth):** A fare is configured in exactly ONE place — the planner's pricing panel. The operator types the **ticket price**, and the four package tiers (5-ride, 10-ride, monthly, 3-month) auto-fill from it; each tier stays overridable. On submit, that fare is expanded across **every** boarding→dropoff pair into `trip_pricing`, so the table is fully populated the moment a trip exists and the Client app never falls back to a guessed price. The same editor (`TripFareFields` + `TripFareControllers`, under `trips/shared/presentation/widgets/`) backs the post-creation **Trip Pricing** tab, so create and edit always write the same shape.
  * **Pricing model** lives in `lib/core/pricing/package_tier_pricing.dart`: a package is a **flat multiple of the ticket** (×3.5 / ×3.75 / ×4.0 / ×4.5), *not* `rides × fare` — a subscription is deliberately far cheaper than buying each ride. The tier columns store package **totals**, which `TripPricingResolver` and the `confirm_seat_booking_v2` RPC charge as-is.
  * **Historical bug (fixed 2026-07-12):** `CreateTripUseCase` used to copy the single ticket price into all five tier columns, so a monthly subscription cost the same as one ride — the Client rendered nonsense like "2,200 → 100 EGP, save 95%". 25 of 27 live `trip_pricing` rows were affected; repaired by `20260712100000_backfill_flat_package_tiers.sql` (which only touches provably-flat rows and leaves hand-priced trips alone).
* **Trip Monitoring:** Operations sees the latest location explicitly sent by the driver with its timestamp, resolves alerts, and views passenger manifests. Continuous/background location sharing is not used.
* **Live Vehicle Tracking Engine:** Driver-sent fixes are rendered through a shared engine (`lib/core/tracking/` + `lib/core/widgets/tracking/`) that validates fixes, interpolates marker movement, rotates heading, estimates speed (km/h), draws the GPS accuracy circle, and flags stale signals. Used by both the Dashboard live monitoring map and the Client tracking map. See `docs/architecture/LIVE_TRACKING_ENGINE.md`.
* **Smart Route Progress & ETA System:** A shared pure-Dart engine (`lib/core/tracking/progress/`) projects GPS fixes onto the route polyline to produce continuous route progress, per-stop visit states (upcoming → arrived → departed, with hysteresis and operator-event seeding), per-stop ETAs with explicit confidence (live / estimated / scheduled), and per-stop passenger flow (waiting/boarded). Powers the Client tracking screen (pickup countdown, smart stops timeline, split route polyline) and the Dashboard live monitoring panel (continuous progress %, per-station ETAs). See `docs/architecture/ROUTE_PROGRESS_ETA.md`.
* **Client Tracking Screen (rebuilt 2026-07-15):** The passenger's live tracking screen (`lib/apps/client/features/tracking/`). Rider-centric: the single hero ETA counts down to *that passenger's* boarding stop before they board and to *their* drop-off afterwards — not to the end of the line. Seat, boarding/drop-off point and check-in status come from the rider's own `trip_passengers` row; captain and vehicle ratings are the real `drivers.rating` / `vehicles.rating` averages; the completed state opens the real `submit_trip_review` flow. Trip state is derived from operational truth only — the presentation layer has no way to set it. Fully localized (ar/en). See `docs/architecture/CLIENT_TRACKING_SCREEN.md`.
  * **Historical bug (fixed 2026-07-15):** the screen shipped a debug state-switcher (`showTrackingStatePreviewSheet` + `TrackingCubit.changeState`) that let the UI fake any trip state, and a star-rating UI whose values lived only in cubit state and were never persisted — passengers rated their captain and nothing happened. `driverRating` was never fetched at all, so the captain always rendered as "N/A". All removed; ratings now go through the server-enforced review RPC.

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

---

## 11. Notification System (Event-Driven)

The platform notifies the right audience on **every meaningful action**, generated
centrally in the database so notifications fire regardless of which app performed
the action, delivered live over Supabase Realtime.

### Delivery channels
* **Client** & **Captain** → `public.notifications` (per-user, `user_id → auth.users`),
  filtered by `target_app` (`client` / `captain` / `all`). Both apps have full receive
  stacks under `lib/apps/{client,captain}/features/notifications/` (inbox + realtime
  stream + unread badge + mark-as-read).
* **Dashboard** → `public.operational_alerts` (**NEW**, RLS disabled, Realtime on). The
  Dashboard runs as the anon role and cannot own a per-user notification row, so it reads
  a dedicated ops feed — like `captain_requests`. Feature:
  `lib/apps/dashboard/features/notifications/` (inbox + composer tabs, top-bar bell badge,
  route `DashboardRoutes.notifications`, `DashboardPermission.notifications`).

### Backbone
* **Foundation migration:** `20260629300000_notification_system.sql` (notifications table
  upgrade, `notification_tokens`, `notification_preferences`, `broadcast_notification`).
* **Event engine migration:** `20260706140000_notification_event_engine.sql` —
  `operational_alerts` table + central helpers (`push_notification`,
  `push_operational_alert`, `captain_user_for_trip`, `notify_trip_passengers`) + AFTER
  triggers on `operation_trips` (status + driver assignment), `trip_passengers`
  (insert/delete), `booking_payments`, `captain_requests`, `support_tickets`,
  `support_messages`, `refund_requests`, `transport_subscriptions`.
* Booking/payment **client** notifications remain inline in the booking RPCs
  (`confirm_seat_booking_v2` / `approve_payment` / `reject_payment` /
  `request_payment_review`).

### Adding a new event
Prefer a DB trigger calling `push_notification` (per-user) or `push_operational_alert`
(dashboard). Categories must match the app enums (client: `booking/payment/trip/
subscription/chat/system`; captain: `trip/passenger/assignment`). FCM/APNs push is not yet
wired (tables are FCM-ready); in-app Realtime is the delivery mechanism today.

---

## Trip Reviews (التقييمات)

After a **completed** trip the passenger rates three things separately — the captain, the
vehicle, and the route — plus optional written feedback. One review per booking.

### Visibility model (the whole point of the feature)
| Data | Who sees it |
| --- | --- |
| Individual review + written feedback | **Dashboard owner only** (`DashboardPermission.reviews` — deliberately *not* granted to `supportAgent`) |
| Driver average + review count | **Everyone** (`drivers.rating` / `drivers.rating_count`) |
| Vehicle average + review count | **Everyone** (`vehicles.rating` / `vehicles.rating_count`) |
| Route rating | Dashboard only — passengers do not shop for a route on quality |
| Own review | The passenger who wrote it (re-opening the sheet shows it read-only) |

### Backbone
* **Migrations:** `20260714120000_trip_reviews.sql` (table, RLS, aggregate columns +
  trigger, `submit_trip_review` RPC, low-rating `push_operational_alert`, realtime
  publication) and `20260714121000_trip_reviews_revoke_anon.sql` (revokes the RPC + writes
  from `anon`; Supabase default privileges grant EXECUTE to anon, so `revoke from public`
  alone is not enough).
* **Writes:** only through `submit_trip_review(p_booking_id, …)` — SECURITY DEFINER,
  enforces ownership (`client_id = auth.uid()`), trip `completed`, booking not cancelled,
  ratings 1–5, and upserts on `booking_id` so a re-submit amends rather than duplicates.
* **Aggregates:** an AFTER trigger recomputes `drivers.rating` / `vehicles.rating`. Every
  screen already selecting `drivers (*)` picks the average up with no new query.
* **RLS:** `anon` (the Dashboard, which has no login) reads all; `authenticated` reads only
  its own rows. No insert/update/delete policy exists — the RPC is the only door.

### Where it lives
* Client: `lib/apps/client/features/trips/` — `trip_review_flow.dart` +
  `widgets/trip_review/`, `TripReviewCubit`, `submit_trip_review_usecase.dart`.
* Dashboard: `lib/apps/dashboard/features/reviews/` — route `DashboardRoutes.reviews`,
  `ReviewsCubit` (filters: all / تحتاج متابعة / بها تعليقات), captain standings panel.
* A rating ≤ 2 on **any** dimension flags the review as `needsAttention` and fires a
  high-priority operational alert — a 5-star captain in a 1-star vehicle averages "fine"
  and must not be silently averaged away.

### Rules
A captain or vehicle with **zero** reviews renders as "New captain" / no chip — never as
0.0 stars. `VehicleSortOption.rating` ranks on the combined captain+vehicle average and
sorts unrated trips **last**; an absent rating is not a perfect one.
