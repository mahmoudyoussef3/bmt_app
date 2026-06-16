# Trips Feature Documentation

The `trips` feature is the central operational hub of the Dashboard App. It follows a modular Clean Architecture approach, breaking down the complex lifecycle of a Trip into manageable sub-domains while unifying the UI into a powerful workspace.

## 1. Directory Structure & Sub-domains

The feature is heavily modularized to prevent bloated state management. Instead of one massive "TripsCubit", it is broken down into specific operational concerns:

```text
lib/apps/dashboard/features/trips/
├── presentation/           # Shared UI screens and global widgets
├── shared/                 # Domain entities (OperationTrip) and shared Data models
├── trip_creation/          # Sub-feature: The Wizard and logic to instantiate new trips
├── trip_events/            # Sub-feature: Trip historical logs and timeline events
├── trip_management/        # Sub-feature: Listing, filtering, and status updates
├── trip_passengers/        # Sub-feature: Passenger manifests and boarding logic
├── trip_pricing/           # Sub-feature: Dynamic segment pricing and ticket logic
├── trip_seats/             # Sub-feature: Seat map generation and availability
└── trips_di.dart           # Dependency Injection orchestrator for the entire module
```

## 2. UI Flow & Deep Routing

The Trips module is designed as a **Master-Detail Workspace** without relying on deep navigator pushes. It keeps the dispatcher immersed in a single screen.

### The Entry Point: `TripsScreen`
Path: `presentation/screens/trips_screen.dart`

When the user navigates to the Trips page, the `TripsScreen` is loaded. It divides the screen into two main areas:
1. **The List Pane (Master):** Displays KPI summary cards at the top (Trips Today, Upcoming, In Progress, Completed). Below them is a searchable, filterable list of trips powered by `TripsListCubit`.
2. **The Workspace Pane (Detail):** When a trip is clicked, the `_TripWorkspace` widget slides into view.

### The Sub-widgets of `_TripWorkspace`
The `_TripWorkspace` is a massive container acting as a control room for a single trip. It consists of:
* **The Header:** Displays the `_TripInfoChip`s (Route, Time, Vehicle, Driver), Seat availability KPI (`_WorkspaceFact`), and a `PopupMenuButton` to change the `OperationTripStatus`.
* **The Tab Bar:** A scrollable row of `ChoiceChip`s that switch the active view below it.

The Tabs (Subwidgets inside `trips_screen.dart` and `presentation/widgets/`):
1. **`_OverviewTab`**: Shows Driver details, Vehicle details, and a visual vertical timeline of `RouteStation`s and arrival times.
2. **`_PassengersTab`**: Displays a data table of passengers (Name, Phone, Seat, Pickup, Dropoff, Status).
3. **`_SeatsTab`**: A visual map representing the bus seating arrangement. Seats are colored based on `TripSeatState` (Available, Reserved, Paid, Blocked).
4. **`TripPricingTab`**: (Extracted to `presentation/widgets/trip_pricing_tab.dart`). Manages the complex pricing matrix for route segments. Uses `trip_pricing_editor_dialog.dart` to add specific segment prices.
5. **`_PackagesTab`**: Displays subscription/multi-day packages available for the trip.
6. **`_PaymentsTab`**: Shows financial transactions, cash collection, and refund logs.
7. **`_HistoryTab`**: Uses a `Stepper` or Timeline widget to show chronological `TripEvent` logs (e.g., "Trip Created", "Driver Assigned", "Status changed to Boarding").

## 3. The Trip Creation Flow

Trip Creation is the most complex workflow in this module, handled by the **`TripCreationWizardDialog`** (`presentation/widgets/trip_creation_wizard.dart`). 

It is a multi-step modal dialog that walks the dispatcher through instantiating a Route into a live Trip. It is powered by `TripCreationCubit`.

### The 8-Step Wizard Flow:
1. **Route Selection:** Dispatcher selects an active Route.
2. **Vehicle Selection:** Filters and displays vehicles that have status `available` or `assigned`.
3. **Driver Selection:** Filters and displays available drivers. Validates against vehicle assignments.
4. **Scheduling:** Sets the Trip Date (`_dateController`), Departure Time (`_timeController`), and calculates Estimated Arrival based on Route duration.
5. **Pricing Matrix:** A dynamic horizontal table. Automatically maps every `RouteStation` combination (e.g., Station 1 to Station 2, Station 1 to Station 3). If the route has < 2 stations, it shows an error state.
6. **Package Pricing:** Allows the dispatcher to enable/disable specific Subscription Packages (Weekly, Monthly) and set discounts.
7. **Review:** A summary screen displaying all selections using `_buildReviewRow` helpers.
8. **Confirmation:** The final step. Triggers `TripCreationCubit.createTrip()`.

### Post-Creation Side Effects
When a trip is successfully created:
* The Backend/RPC generates `trip_seats` records based on the Vehicle's capacity.
* The Backend/RPC generates `trip_pricing` records based on the Matrix inputs.
* The `TripCreationWizardDialog` listens for `TripCreationSuccess`, closes itself (`Navigator.pop`), and triggers a refresh on the `TripsListCubit` so the new trip immediately appears in the dashboard.

## 4. State Management (Cubits)

Each sub-domain has its own isolated state management to prevent UI freezing and ensure single responsibility.

* **`TripsListCubit`**: Handles pagination, filtering, and realtime DB updates for the Master List.
* **`TripDetailsCubit`**: Manages the currently opened trip in the Workspace and its active Tab index. Also handles root-level status changes (e.g., Marking a trip "Completed").
* **`TripPricingCubit`**: Handles the heavy lifting of saving, updating, and validating the pricing segments for the active trip.

## 5. Extensibility
The `trips` feature is designed so that if a new operational requirement emerges (e.g., "Cargo Management"), a developer simply needs to:
1. Create a `trip_cargo/` subdirectory.
2. Build a `TripCargoCubit`.
3. Add a `TripWorkspaceTab.cargo` enum to `trips_screen.dart`.
4. Create a `_CargoTab(trip: trip)` widget in the switch statement. 
No core architecture changes would be required.
