# Easy Way Transportation (EWT) - Portfolio Showcase Strategy

## 1. Ecosystem Architecture
The Easy Way Transportation (EWT) platform is a multi-office transportation ecosystem consisting of three distinct applications that interface with a unified operational backend.
- **Client App**: Passenger-facing marketplace and booking engine.
- **Captain App**: Driver-facing execution and manifest management tool.
- **Dashboard**: Operations control center for transportation offices.

For the portfolio showcase, we will implement a simulated ecosystem inside the `my_portfolio` Flutter Web project. This simulation relies on a single **EwtShowcaseState** that perfectly replicates the business rules and constraints of the production system, allowing all three apps to react simultaneously to state changes without connecting to the production Supabase database.

## 2. Personas
- **The Passenger**: Books seats, manages payments, and tracks their assigned vehicle's ETA live.
- **The Captain**: Executes trips, manages the passenger manifest, scans tickets, and broadcasts live GPS data.
- **The Operator**: Monitors fleet health, creates schedules, resolves delays, and manages live incidents from the control center.

## 3. End-to-End User Stories
The central story guiding the showcase is:
`CLIENT BOOKS A TRIP` → `CAPTAIN EXECUTES THE TRIP` → `OPERATIONS MONITORS THE TRIP`

Specifically:
1. The Passenger browses Easy Way Transportation — Banha and selects the 08:30 trip to Cairo.
2. They select Seat 3 on a 14-seat Toyota Hiace and confirm the booking.
3. The Captain sees Seat 3 turn "Booked" on their manifest.
4. The Captain starts the trip and begins broadcasting their location.
5. The Operator sees the active trip on the map, with 1/14 occupancy and a "LIVE" tracking health status.

## 4. Shared State Model
The portfolio will use a single centralized state (`EwtShowcaseState`) to ensure absolute consistency across the three views. It will include:
- `Office`: ID, Name (e.g., Easy Way Transportation — بنها).
- `Driver`: ID, Name (e.g., كابتن أحمد).
- `Vehicle`: ID, Type (Toyota Hiace), Capacity (14).
- `Route`: ID, Path (بنها → القاهرة).
- `Trip`: ID, DepartureTime, Status (SCHEDULED, OPEN_FOR_BOOKING, BOARDING, IN_PROGRESS, COMPLETED).
- `Seats`: Array of 14 seat objects with deterministic statuses (AVAILABLE, RESERVED, PAID, BLOCKED).
- `Passengers`: Manifest of booked users.
- `TrackingState`: Status (LIVE, STALE, OFFLINE, UNKNOWN), Location, Progress (e.g., 42 km remaining).

## 5. Data Consistency Rules
- **Capacity Constraint**: The number of seats cannot exceed the vehicle's capacity (14 for Hiace).
- **Occupancy Match**: `Available Seats + Booked Seats = Total Capacity`.
- **Manifest Sync**: The Captain's manifest passenger count must equal the Client's booked seats count and the Dashboard's occupancy count.
- **Trip State Sync**: If the Captain changes the trip state to `IN_PROGRESS`, the Client tracking must switch to Active Map view, and the Dashboard must show the trip under "Active Trips".

## 6. Showcase Scenarios
The primary scenario is a highly specific, realistic EWT journey:
- **Vehicle**: Toyota Hiace (14 seats)
- **Route**: بنها → القاهرة
- **Captain**: كابتن أحمد
- **Initial State**: Booked seats: 1, 3, 5, 7, 9, 11, 13 (7 occupied). Available: 2, 4, 6, 8, 10, 12, 14.

## 7. Client Flow
1. **Office Marketplace**: Select Easy Way Transportation.
2. **Available Routes**: Choose بنها → القاهرة.
3. **Trip Selection**: Select 08:30 Trip (Toyota Hiace).
4. **Seat Selection**: Interactive 14-seat layout. Tapping Seat 4 marks it as "Selected".
5. **Booking Summary**: Price updates.
6. **Payment**: Confirmed.
7. **Live Tracking**: Map reveals the vehicle moving towards the pickup point.

## 8. Captain Flow
1. **Assigned Trip**: Sees the 08:30 Trip.
2. **Manifest**: Sees 8 passengers (7 initial + 1 booked by Client).
3. **Action**: Tap "Start Boarding".
4. **Action**: Mark Passenger in Seat 4 as "Boarded".
5. **Action**: Tap "Start Trip".
6. **Live Execution**: Simulation of GPS location sharing.

## 9. Dashboard Flow
1. **Live Operations Center**: Desktop view of active trips.
2. **Trip Status**: Sees 08:30 Trip status change from `SCHEDULED` to `BOARDING` to `IN_PROGRESS` as the Captain interacts.
3. **Tracking Health**: Displays "LIVE" when the Captain starts the trip.
4. **Occupancy**: Shows 8/14 seats occupied.

## 10. Responsive Strategy
- **Dashboard Showcase**: Desktop-first design. Represents a wide-screen operational control center with data density.
- **Client Showcase**: Mobile-first design. Simulates an iOS/Android app experience.
- **Captain Showcase**: Mobile-first design. High-contrast, easy-to-tap targets for driving conditions.
*We will not simply scale UIs up or down; each view uses the proper breakpoints for its intended platform.*

## 11. Reusable Components
We will reuse (or carefully extract) specific design system components from `bmt_app` to ensure authentic visual language:
- `SeatGrid` and layout logic.
- EWT Material 3 Theme tokens (Primary Blue, Success Green, specific rounded corners).
- Arabic typography configurations and RTL layout wrappers.
- Domain models (stripped of Supabase dependencies).

## 12. Components Intentionally Not Reused
- **Datasources / Repositories**: No actual API calls or Supabase SDK integration.
- **Full App Shells**: We will not copy `main_client.dart` or entire feature modules. The showcase is a bespoke, lightweight shell rendering extracted widgets.
- **Auth Layer**: Completely removed to allow instant, unauthenticated access to the portfolio demos.

## 13. Security Considerations
- **No Supabase Keys**: The portfolio will contain absolutely zero production API keys or URL endpoints.
- **No Real PII**: The deterministic state uses realistic but completely fake Arabic names (e.g., كابتن أحمد, أحمد محمود) and generic phone numbers if required. Real customer data is strictly isolated from this repository.

## 14. Portfolio Storytelling
The portfolio will introduce EWT with a clear narrative structure:
> **Easy Way Transportation**
> A multi-office transportation platform connecting passengers, captains, and transportation operations.

1. **01 BOOK**: "Passenger books a seat." (Opens Client interactive flow).
2. **02 EXECUTE**: "Captain receives and executes the trip." (Opens Captain interactive flow).
3. **03 MONITOR**: "Operations monitors the journey in real time." (Opens Dashboard interactive flow).

Each step builds on the previous one, proving that these are not three disconnected apps, but a singular, unified platform.
