# Feature Specification: Prompt 4 – BMT Routes & Booking Journey Premium UX

**Feature Branch**: `[002-bmt-routes-booking-ux]`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "Prompt 4 – BMT Routes & Booking Journey Premium UX. Redesign the Client App's Routes Hub screen, Search Results screen, Filters bottom sheet, Route Details screen, and Trips screen (upcoming/active/completed/cancelled) into a premium transportation booking experience comparable to Swvl, Careem, and Uber, building on top of the BMT brand identity and design system already established by spec 001-bmt-brand-identity-premium-ux. Must preserve all existing business logic, Cubit/Bloc state management, repositories, use cases, APIs, and navigation — this is a presentation-layer redesign only."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Route Discovery & Comparison (Priority: P1)

A passenger opens the app to find a way to travel between two places. They search or browse, see a set of route options, narrow them down with filters, and compare options quickly enough to pick one with confidence.

**Why this priority**: Discovery is the entry point of the entire booking journey. If a passenger cannot quickly understand and compare their options here, they never reach booking at all — every other improvement downstream is wasted.

**Independent Test**: Starting from the app's home/routes entry point, search or browse routes, apply at least one filter, and confirm the passenger can identify and compare origin, destination, timing, seats, and price across results without opening any single result first.

**Acceptance Scenarios**:

1. **Given** a passenger opens the routes/discovery entry point, **When** the screen finishes loading, **Then** available routes are presented as scannable cards each showing origin, destination, duration, distance, available seats, price, departure time, and status without further taps.
2. **Given** a passenger has an active search or browse list, **When** they open the filter experience, **Then** they can narrow by price range, departure time, arrival time, available seats, vehicle type, and route type, and choose a sort order, with results updating to reflect the applied criteria.
3. **Given** a passenger has one or more filters applied, **When** they view the results screen, **Then** every active filter is visibly indicated and can be removed individually or reset all at once in a single action.
4. **Given** a passenger's search or filter combination matches no routes, **When** the results screen renders, **Then** it explains that nothing matched and offers a clear next action (e.g., adjust filters, clear filters, browse popular routes) instead of an empty blank area.

---

### User Story 2 - Confident Booking Decision (Priority: P2)

A passenger who has narrowed down to a specific route wants to understand everything relevant to that route — the stops, the schedule, the price, seat availability, and who is driving — in one coherent place, and move toward booking without hunting for missing information.

**Why this priority**: This is the moment of commitment. A cluttered or incomplete details view causes hesitation, back-and-forth, or abandonment; a clear one builds the trust needed to complete a booking.

**Independent Test**: Open a specific route's details from the discovery results and confirm a passenger can review the route overview, ordered stops, map context, pricing, seat availability, and driver/vehicle identity, then reach the booking action without needing to leave the screen to find missing information.

**Acceptance Scenarios**:

1. **Given** a passenger opens a route's details, **When** the screen loads, **Then** the route overview, stop-by-stop timeline, map view, pricing, seat availability, and driver/vehicle identity are each presented as a distinct, legible section in a logical order.
2. **Given** a passenger is viewing route details, **When** they decide to proceed, **Then** a single, unambiguous primary action leads them into booking.
3. **Given** map or live data for the route is temporarily unavailable, **When** the details screen loads, **Then** the rest of the route information remains usable and the map section degrades gracefully instead of breaking the screen.
4. **Given** a route has many stops or a long name in either Arabic or English, **When** the details screen renders, **Then** all text remains readable without overflow, clipping, or broken layout.

---

### User Story 3 - Trip Lifecycle Visibility (Priority: P3)

A passenger wants to check on trips they've booked — what's coming up, what's happening right now, and what already happened — and understand the state of each one at a glance.

**Why this priority**: Trip visibility builds trust after booking and reduces support burden, but it depends on discovery and booking already working, making it the natural third priority.

**Independent Test**: Open the trips area with a mix of trip states present and confirm upcoming, active, completed, and cancelled trips are clearly separated, each trip's state is visible without opening it, and an active trip shows progress toward its destination.

**Acceptance Scenarios**:

1. **Given** a passenger has trips in multiple lifecycle states, **When** they open the trips screen, **Then** upcoming, active, completed, and cancelled trips are separately browsable and each trip displays a clear status indicator.
2. **Given** a passenger has a trip currently in progress, **When** they view it, **Then** its progress toward completion is visibly communicated.
3. **Given** a passenger has no trips in a given state (e.g., no upcoming trips), **When** they view that section, **Then** a tailored empty state explains the absence and suggests a relevant next action (e.g., browse routes).
4. **Given** a trip fails to load or a realtime update fails to arrive, **When** the passenger views the trips screen, **Then** they see an actionable, non-technical error state with a way to retry rather than a stale or blank screen.

---

### Edge Cases

- What happens when a route or stop name is unusually long in either Arabic or English and risks overflowing its card or timeline row?
- How does the filter experience behave when a chosen combination of filters excludes every available route?
- What happens when seat availability or pricing changes between viewing the results list and opening a route's details?
- How does the experience communicate a slow or degraded network while a search or filter change is in flight, without appearing frozen or broken?
- How does the map section of route details behave when geographic or live-position data is missing, stale, or partially loaded?
- How do loading, empty, and error states render correctly for both Arabic (right-to-left) and English (left-to-right) layouts, including numerals, dates, and prices?
- How does the experience remain usable and unambiguous for a user with reduced-motion or screen-reader accessibility settings enabled?
- How does a trip that changes state while the passenger is viewing the trips screen (e.g., upcoming becomes active) update without disorienting the passenger?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The routes discovery entry point MUST present available routes as scannable cards that each communicate origin, destination, duration, distance, available seats, price, departure time, and route status without requiring an additional tap.
- **FR-002**: The search/results experience MUST let passengers filter available routes by price range, departure time window, arrival time window, minimum available seats, vehicle type, and route type, and MUST let them choose a sort order for results.
- **FR-003**: Filter and sort selections MUST combine together (not replace one another) and MUST be reflected in the results shown.
- **FR-004**: Active filters MUST be visibly listed on the results screen, each individually removable, with a single action available to reset all filters at once.
- **FR-005**: The filter experience MUST use interaction patterns (chips, ranges/sliders, segmented choices) that make the current selection state obvious at a glance, and MUST visibly animate/acknowledge changes as they are made.
- **FR-006**: The route details experience MUST consolidate route overview, ordered stop timeline, map context, pricing, seat availability, and driver/vehicle identity into one screen, organized so the passenger is guided naturally toward a single, clear booking action.
- **FR-007**: The route details experience MUST remain usable when map or live-position data is unavailable, degrading that section gracefully rather than blocking the rest of the screen.
- **FR-008**: The trips experience MUST separate a passenger's trips into upcoming, active, completed, and cancelled groups that can each be browsed independently.
- **FR-009**: A trip that is currently active MUST visibly communicate its progress toward completion.
- **FR-010**: Every screen in the discovery-to-booking-to-trips journey (routes hub, search results, filters, route details, trips) MUST define distinct loading, empty, error, success, and refreshing presentations; no screen may show a blank area during normal operation.
- **FR-011**: Loading presentations MUST use placeholders that mirror the shape of the eventual content rather than a generic, content-agnostic spinner.
- **FR-012**: Empty presentations MUST explain why content is absent and MUST offer at least one relevant next action.
- **FR-013**: Error presentations MUST use plain, non-technical language and MUST offer a way to retry the failed action.
- **FR-014**: All visual treatments across these screens (cards, buttons, chips, badges, sheets, dialogs, status indicators) MUST reuse the shared BMT design system established for the platform rather than introducing screen-specific one-off styles.
- **FR-015**: Transitions between discovery, filtering, route details, and booking MUST use purposeful, consistent motion that communicates hierarchy and state changes, and MUST respect a passenger's reduced-motion preference.
- **FR-016**: The redesigned experience MUST preserve all existing booking business rules, underlying data sources, and state-management behavior; no functional booking capability may be removed, degraded, or duplicated as a side effect of the presentation redesign.
- **FR-017**: Every screen in this journey MUST remain fully usable and correctly mirrored in both Arabic (right-to-left) and English (left-to-right) presentations, including numerals, dates, and prices.
- **FR-018**: Trip and route status MUST be communicated through more than color alone (e.g., icon, label, or shape) so status remains distinguishable for passengers who cannot rely on color.
- **FR-019**: Interactive elements across these screens MUST provide immediate, restrained feedback when pressed or selected (e.g., cards, buttons, filter chips, tabs).
- **FR-020**: These screens MUST remain legible and usable across phone, tablet, and desktop presentation sizes without changing their underlying visual language.
- **FR-021**: All touch targets, text contrast, and accessible naming across these screens MUST meet the accessibility bar already established for the platform's shared design system.

### Key Entities *(include if feature involves data)*

- **Route**: A travel option between an origin and destination, characterized by distance, duration, price/price range, available seats, and one or more scheduled trips.
- **Trip**: A specific scheduled or in-progress instance of a route with its own departure/arrival time, vehicle, driver, seat availability, and lifecycle status (upcoming, active, completed, cancelled).
- **Stop**: A named, sequenced point along a route where passengers may be picked up or dropped off.
- **Filter/Sort Criteria**: The set of passenger-selected constraints (price range, time windows, seat minimum, vehicle type, route type) and ordering preference applied to a set of routes or trips.
- **Booking Decision Context**: The consolidated set of information (route, pricing, seats, driver/vehicle) a passenger reviews immediately before starting a booking.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Passengers can identify a route's origin, destination, price, and available seats within 3 seconds of a results card appearing on screen, in usability review.
- **SC-002**: Passengers can apply and understand the effect of at least one filter combination in under 10 seconds, including seeing which filters are active, in usability review.
- **SC-003**: At least 9 out of 10 reviewed screens in this journey (routes hub, search results, filters, route details, trips) are judged by stakeholders to belong to the same premium BMT design system as the rest of the app, without additional explanation.
- **SC-004**: No screen in this journey displays a blank or generic loading spinner during normal operation, verified across simulated slow-network and empty-result conditions.
- **SC-005**: Passengers can move from opening a route's details to reaching the booking action without leaving the screen to find missing information, in usability review.
- **SC-006**: In review with a representative mix of trip states, all trips are correctly grouped into upcoming, active, completed, and cancelled with zero misclassification.
- **SC-007**: All screens in this journey remain fully readable with no clipped or overlapping text in both Arabic and English renditions during design review.

## Assumptions

- The BMT shared design system delivered by spec `001-bmt-brand-identity-premium-ux` (semantic tokens, buttons, cards, chips, badges, route/station/captain components, branded map styling, loading/empty/error/success primitives) is the foundation this feature builds on, not replaces.
- The routes, search, filters, route details, and trips screens continue to be powered by their existing state management, use cases, repositories, and data sources; this specification concerns the experience layer only, not the underlying data or business rules.
- Filter dimensions described here (price range, departure/arrival time, available seats, vehicle type, route type, sort order) are backed by data already available to the application; if any dimension turns out to require new data not currently exposed, that will be flagged during planning rather than expanding this specification's scope.
- Existing navigation destinations between these screens are preserved; only their internal layout, hierarchy, and transition treatment are in scope for change.
- No competitor's signature visual language is copied directly; comparisons to other platforms describe a quality bar, not a design source.
- Both Arabic and English/RTL and LTR support continue to be required, consistent with the rest of the platform.
