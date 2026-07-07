# Quickstart: Prompt 4 – BMT Routes & Booking Journey Premium UX

## Purpose

Use this guide to validate the redesigned routes-to-trips journey end-to-end before considering the feature complete.

## Prerequisites

- A runnable Client App build (simulator/device) connected to a Supabase environment with realistic routes, trips, stops, seats, and trip history across all four `TripStatus` values
- Ability to switch the device/app locale between Arabic and English
- Ability to toggle system dark mode and "reduce motion" / "disable animations" accessibility settings
- At least one route/trip combination with missing map coordinates, to exercise the map-unavailable fallback

## Validation Scenarios

### 1. Route Discovery & Comparison (User Story 1)

1. Open the Routes Hub, then search or browse to the results screen.
2. Confirm each result card shows origin, destination, duration, distance, available seats, price, departure time, and status without opening it.
3. Open the filter experience; apply a price range, a time window, and a vehicle type together.
4. Confirm active filters are listed, each individually removable, with a working "reset all."
5. Apply a filter combination expected to match nothing; confirm a helpful empty state with a next action appears instead of a blank list.

**Expected outcome**: A passenger can compare and narrow routes without opening any single result, per spec SC-001/SC-002.

### 2. Confident Booking Decision (User Story 2)

1. From results, open a route's details.
2. Confirm route overview, stop timeline, map, pricing, seat availability, and driver/vehicle identity each appear as distinct, legible sections in a logical order.
3. Confirm exactly one clear primary action leads toward booking.
4. Repeat with a route/trip that has no map coordinates; confirm the rest of the screen still works and the map section degrades gracefully instead of erroring.
5. Repeat with an unusually long Arabic and English route/stop name; confirm no clipping or overflow.

**Expected outcome**: A passenger reaches the booking action without leaving the screen to find missing information, per spec SC-005.

### 3. Trip Lifecycle Visibility (User Story 3)

1. Open the Trips screen with trips present in all four states.
2. Confirm upcoming, active, completed, and cancelled trips are separately browsable and each shows a clear status indicator (not color-only).
3. Open an active trip; confirm its progress toward completion is visible.
4. View a state with no trips (e.g., no cancelled trips); confirm a tailored empty state with a relevant next action.
5. Force a load failure (e.g., disable network briefly); confirm an actionable, non-technical error state with retry, not a stale or blank screen.

**Expected outcome**: Trips are correctly grouped with zero misclassification and every state has a designed presentation, per spec SC-006/SC-004.

### 4. Cross-Cutting Review

1. Repeat scenarios 1–3 in Arabic (RTL) and confirm layout mirrors correctly, including numerals, dates, and prices.
2. Repeat in dark mode.
3. Enable "reduce motion" and confirm transitions/animations respect it without breaking comprehension.
4. Confirm every new/updated file introduced by this feature is ≤120 lines (`CLAUDE.md` §6) and that no `CircularProgressIndicator` remains in the 5 named screens.
5. Confirm no Cubit method signature, use case, repository, or named route was changed — only presentation.

**Expected outcome**: The journey feels like one premium BMT product in both languages, both themes, and with accessibility preferences honored, with zero regression to existing booking/trip functionality.

## Notes

- This feature has no external interface contract (no new API/schema); validation is UI/UX-driven, consistent with spec 001's quickstart.
- Run this guide again after `/speckit-implement` completes, not just before — it is the acceptance check for the whole feature.

## Verification Log (T041)

What was actually run during implementation, and what still needs a human pass:

- **Automated, done**: `flutter analyze` across the whole repo — zero issues introduced (13 pre-existing `info`-level lints remain, all in untouched files). `flutter test` across the whole repo — 245/245 pass, including 20 new tests for `RouteFilterCriteria` and `TripFilterCriteria`. Every file created or substantively rewritten is ≤120 lines (research.md §11).
- **Runtime, done**: the client app was launched on an iOS simulator against the real Supabase backend (flavor `client`) and screenshotted at the start and end of implementation — it boots cleanly, renders Home with live data, and is still running with no crash after every change in this feature.
- **Not done — no GUI automation permission in this environment**: tapping through Routes Hub → Search Results → Filters → Route Details → Trips interactively. AppleScript/System Events access to the Simulator was denied (`Not authorized to send Apple events`), and no `idb`/device-automation tool was available. **Recommendation**: before merging, a human (or a session with automation permission granted) should actually run the four scenarios above on-device — static analysis and unit tests confirm correctness of logic, not that the layouts read as premium and cohesive on a real screen.
