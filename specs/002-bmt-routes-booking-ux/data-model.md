# Data Model: Prompt 4 – BMT Routes & Booking Journey Premium UX

This feature introduces no new business entities, database tables, or Cubit state shapes. It presents the existing domain entities below more clearly; any "attributes" listed are the real fields already exposed by the current entities (see file references), not new data.

## Entities

### Route (discovery/results)

Represents a travel option between an origin and destination, shown on the routes hub, search results, and as the subject of route details.

**Key attributes** (`RouteOptionData`, `PopularRouteListData` — `lib/apps/client/features/booking/domain/entities/booking_option.dart`):
- Route name, pickup, destination
- Distance, duration
- Available seats, starting price, price range
- Ordered stops (`points`, see Stop below)
- `isFastest`, `matchQuality` (exact/partial/suggested)
- Daily trip count, average duration (list-context variant)

**Relationships**: Has one or more Trips; has an ordered list of Stops.

**Validation rules**: Card presentations must always surface origin, destination, duration, distance, available seats, price, and status together (spec FR-001) — no partial-data card states in the redesigned UI, consistent with existing entity completeness.

### Trip (a scheduled instance of a Route)

Represents a specific departure of a route, shown in results, route details, and the trips screen.

**Key attributes**:
- Discovery-context (`RouteTripOptionData`): trip date, departure/arrival time, available seats, vehicle type, price
- Post-booking context (`TripData` — `lib/apps/client/features/trips/domain/entities/trip.dart`): reference, status, pickup/destination, date/time labels, driver identity + rating, vehicle name/type/id, seats, payment status, fare, optional cancellation reason, optional completion timestamp

**State transitions** (`TripStatus` enum, existing — not modified): `upcoming → inProgress → completed`, or `upcoming → cancelled`. The redesigned Trips screen groups by the existing `TripFilter` enum (`upcoming`, `active`, `completed`, `cancelled`), which already maps 1:1 onto `TripStatus` via `statusMatch`.

**Relationships**: Belongs to a Route; has a Driver/vehicle identity; has one or more Seats; has a Payment status.

**Validation rules**: An `inProgress` trip must always render a progress indicator (spec FR-009); a `cancelled` trip must surface its cancellation reason when present.

### Stop

Represents a named, sequenced pickup/dropoff point along a route.

**Key attributes** (`RoutePointData`): id, name, order, `pickupAllowed`, `dropoffAllowed`, optional latitude/longitude.

**Relationships**: Belongs to a Route; consumed by the route-details stop timeline and the branded map layer.

**Validation rules**: Stops missing coordinates must still render correctly in the timeline (text-only), and the map section must degrade gracefully rather than fail (spec FR-007, Edge Cases).

### Filter/Sort Criteria (presentation-only, not persisted)

Represents the passenger's current narrowing/ordering choice, scoped to whichever screen it applies on (see `research.md` §2 for why the two screens use different subsets):

- On the results/discovery grid (route-level `PopularRouteListData`): price range, duration range, pickup, destination, sort order.
- On Route Details' available-trips list (per-trip `RouteTripOptionData`): price range, departure time window, arrival time window, minimum available seats, vehicle type, sort order.
- On Route Details' alternative-routes list (`RouteOptionData`): derived route type (direct vs. multi-stop, from stop count), with "fastest" shown as a separate badge from `isFastest`.

**Relationships**: Applied against data already loaded by `BookingCubit`; purely a client-side view transform — does not change what `BookingCubit` fetches, and touches no domain/data file.

**Validation rules**: Multiple criteria combine with AND semantics (spec FR-003); every active criterion must be individually removable and collectively resettable (spec FR-004); no criterion may be offered on a screen whose underlying entity cannot satisfy it.

### Booking Decision Context

Represents the consolidated view a passenger reviews on Route Details immediately before booking.

**Key attributes**: the selected Route, its Stops, available Trips, pricing, seat availability, and driver/vehicle identity — all already available on `RouteOptionData` plus its nested `RouteTripOptionData` list; no new aggregation entity is introduced, only a clearer on-screen composition of what already exists.

**Relationships**: Leads to the existing booking wizard (`BookingWizardCubit`), which remains entirely unchanged by this feature.

**Validation rules**: The screen must expose exactly one unambiguous path into the existing booking flow (spec FR-006) regardless of how the information above is visually organized.
