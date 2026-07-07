# Research: Prompt 4 – BMT Routes & Booking Journey Premium UX

## 1. Token scale reconciliation

**Decision, revised after checking actual values and call-site count**: `ClientSpacing.{xxs,xs,sm,md,lg,xl}` (4/8/12/16/24/32) and `ClientMotion.{fast,base,slow}` (120ms/180ms/280ms) are numerically **identical** to `AppTokens.{spaceXs..spaceXxl}` and `AppTokens.{motionFast,motionBase,motionSlow}` respectively — just offset by one step in naming. These are redefined to delegate to `AppTokens` (pure DRY, zero visual change, since the numbers already match).

`ClientRadius`/`ClientElevation`, however, do **not** numerically overlap with `AppTokens.radius*` at any step (e.g. `ClientRadius.lg == 24` vs `AppTokens.radiusLarge == 18`, and there are 5 client radius steps vs 4 core steps). A repo-wide grep found 50 call sites for `ClientRadius` alone across the client app, almost all outside this feature's 5 named screens (home, profile, auth, settings, etc.). Forcing radius/elevation to numerically match `AppTokens` would silently reskin all 50 of those unrelated call sites — a real visual regression risk with no upside for the screens actually in scope. Spec 001 §7 also explicitly sanctions this: "Dense operational screens MUST use tighter spacing than discovery surfaces" — the client app is the discovery/booking surface, so a deliberately more generous radius/elevation scale than the operational (dashboard) scale is by design, not drift. **Decision: leave `ClientRadius`/`ClientElevation` as the client app's own intentionally-distinct scale**, documented as such in code, and reserve full `AppTokens` reconciliation for spacing and motion only.

**Rationale**: Fix only the genuine duplication (spacing, motion) where the numbers already agree and delegating is risk-free; do not "fix" a difference that is actually an intentional, spec-sanctioned density distinction and whose blast radius (50 call sites) far exceeds this feature's scope.

**Alternatives considered**: Unifying all four token groups to `AppTokens` values (rejected after data check — real visual regression risk across ~50 out-of-scope call sites, and contradicts spec 001 §7's density-differentiation rule); leaving all four groups fully independent including spacing/motion (rejected — those two are pure duplication with identical numbers, worth deduplicating at zero risk).

## 2. Filter dimensions vs. available data

**Decision, revised after reading the actual screens and datasource**: The two in-scope screens sit at different data granularities, and each filter dimension is only wired where real data already backs it — no dimension is faked and no domain/data file is touched.

- `popular_routes_screen.dart` (the results/discovery grid) renders `PopularRouteListData` — a **route-level aggregate** with only `startingPrice`, `averageDuration`, `dailyTrips`, `pickup`, `destination`. Confirmed in `supabase_booking_search_datasource.dart#getPopularRoutes()`: the raw Supabase query already fetches `capacity`, `booked_seats`, `trip_seats(state)` per trip, but `PopularRouteListModel.toEntity()` discards all of it except the computed price/trip-count — there is no `vehicleType` join at all in this query. **Its filter sheet is scoped to what the entity actually has: price range, duration range (upgrading the existing coarse `_DurationFilter` enum to a slider), pickup, destination, and sort.**
- `route_selection_screen.dart` (Route Details) has two data-richer sub-sections that already carry the remaining FR-002 dimensions: its "available trips" list uses `RouteTripOptionData` (`price`, `departureTime`, `arrivalTime`, `availableSeats`, `vehicleType` — all present today), and its "alternative routes" list uses `RouteOptionData` (`points`, `isFastest`). **Departure/arrival time window, minimum seats, and vehicle type are filtered here, against real per-trip data; "route type" (direct vs. multi-stop) is derived from `RouteOptionData.points.length` for the alternative-routes list, with `isFastest` shown as a separate badge rather than folded into "type."**

**Rationale**: Building a "vehicle type" or "available seats" chip on the discovery grid would either no-op or require adding a field to `PopularRouteListModel`/`PopularRouteListData` and extending the datasource mapping — a domain/data change this plan explicitly commits not to make. Splitting filter dimensions by where the data genuinely lives satisfies FR-002 in full across the journey without silently expanding scope past "presentation-layer redesign only."

**Alternatives considered**: Adding a new `vehicleType`/aggregate-seats field to `PopularRouteListData` by mapping columns already fetched by the existing query (rejected — still a domain/data-layer edit, and the spec's Assumptions section says any such gap should be flagged during planning, not implemented ad hoc); dropping seats/vehicle-type/time-window filters entirely (rejected — spec FR-002 requires them, and they are fully satisfiable on Route Details' available-trips data without any data-layer change); adding a fake/inert filter chip on the discovery grid (rejected outright — a filter that visibly does nothing is a correctness bug, not a design choice).

## 3. Filters interaction pattern

**Decision**: Replace the existing `PopupMenuButton`-based `_LocationFilterMenu` / `_DurationFilterMenu` (in `popular_routes_screen.dart`) with a single shared, tiered bottom sheet component (new `FilterBottomSheet` in `lib/apps/client/core/widgets/`, composed from chips/segmented controls/range sliders), opened from one "Filters" entry point on the results screen.

**Rationale**: Popup menus cannot comfortably host a price range slider or multiple simultaneous filter groups, and spec 001 already establishes bottom sheets as the platform's primary surface for contextual inspection (spec 001 §14) — reusing that pattern keeps the filter experience consistent with the rest of BMT rather than introducing a new overlay paradigm.

**Alternatives considered**: A dedicated full-screen filters route (rejected — heavier than needed for a filter-and-return interaction, and breaks the "bottom sheet = contextual detail" convention); keeping per-filter popup menus but restyling them (rejected — doesn't solve the range-selection UX problem FR-002/FR-005 require).

## 4. Map integration in Route Details

**Decision**: Reuse the existing `flutter_map`-based branded map stack (`google_style_map_view.dart` + `widgets/map/*`) unchanged. It was already restyled under spec 001 tasks T012–T016 (branded markers, animated route line, theme-aware tiles). This feature only changes where/how that widget is composed within the redesigned Route Details layout, and ensures a graceful fallback (existing `_NoMapPlaceholder` / `AsyncStateView` pattern) is used consistently.

**Rationale**: Spec 001 already solved "make the map feel native to BMT" (its US2); re-deriving it here would duplicate completed work and risk regressing the branded marker/animation behavior.

**Alternatives considered**: Swapping to `google_maps_flutter` (rejected — no reason given in the spec, real behavior change, licensing/config overhead, and would contradict "preserve existing... APIs").

## 5. Navigation pattern

**Decision**: Keep the existing `Navigator`-based named-route system (`BookingRoutes`, `TripsRoutes` constants, `Navigator.of(context).pushNamed`). No migration to `go_router`.

**Rationale**: Spec explicitly requires preserving existing navigation; the app has no `go_router` dependency, and introducing one would be a routing-architecture change far outside a presentation redesign.

**Alternatives considered**: None seriously considered — out of scope per spec Assumptions.

## 6. Reduced-motion / accessibility-aware animation helper

**Decision**: Extract the repeated inline check (`WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations`) — currently duplicated across `skeleton.dart`, `animated_vehicle_marker.dart`, `animated_route_line.dart`, `route_map_markers.dart`, `live_vehicle_layer.dart` — into one shared helper (e.g. `AppMotion.reduceMotion(BuildContext)` in `lib/core/theme/` or a small `lib/core/utils/motion_preference.dart`), and use it in every new animation this feature adds instead of re-inlining the check.

**Rationale**: `CLAUDE.md` §6: "If logic is used in 2+ places... move to core/... never duplicate logic." This feature adds several new animated interactions (card press, filter chip selection, sheet transitions, tab switching) that would otherwise add a sixth+ inline copy of the same check.

**Alternatives considered**: Leaving the check inline in each new widget (rejected — directly violates §6, and this feature is precisely the kind of "2+ places" trigger the rule anticipates).

## 7. Testing approach

**Decision**: No new domain/repository tests are needed since `domain/` and `data/` are untouched. Add a focused unit test only for any pure logic this feature extracts into a testable class (most likely a filter-combination/derived-route-type helper from research item 2). All remaining verification is manual: run the app, exercise each of the three user stories end-to-end in both LTR and RTL, light and dark, and with reduced-motion enabled, per `quickstart.md`.

**Rationale**: `CLAUDE.md` §19 requires domain/repository/Cubit tests and reproducing tests for bug fixes — this is a presentation redesign, not a bug fix, and it introduces no new domain logic beyond the small derived-filter helper.

**Alternatives considered**: Adding widget/golden tests for every redesigned screen (considered, not required by the spec's own Success Criteria which are usability/visual-review based like spec 001's; left as an optional follow-up rather than a blocking requirement, to avoid inflating scope beyond what was asked).

## 9. RTL correction: directional arrow icons already auto-mirror

**Decision**: No blanket icon replacement is needed. Verified against the Flutter SDK (`packages/flutter/lib/src/material/icons.dart`): `Icons.arrow_forward`, `arrow_forward_rounded`, `arrow_back`, `arrow_back_rounded` (and their `_sharp`/`_outlined` siblings) all set `matchTextDirection: true` on the underlying `IconData`, so `Icon(Icons.arrow_forward_rounded)` already mirrors correctly under RTL `Directionality` with zero extra code. The earlier research pass (feeding into `plan.md`'s Technical Context) flagged these as needing manual "logical" replacements — that was incorrect. T037's RTL audit should instead focus on `EdgeInsets`/`Alignment` (non-directional variants) and any icon that does *not* set `matchTextDirection` (e.g. plain glyphs with no inherent direction don't need it, but a genuinely asymmetric custom icon would).

**Rationale**: Acting on the original, unverified claim would have meant swapping working icons for no reason across every touched file — wasted effort with no user-visible benefit, and a needless diff.

## 10. RTL audit findings (T037)

Two real, fixed issues found while auditing the 5 named screens:

- `trip_details_screen.dart`'s four views (`_TripDetailsView`, `_TripLoadingView`, `_TripErrorView`, `_TripEmptyView`) each hardcoded `Directionality(textDirection: TextDirection.ltr, ...)` around their whole `Scaffold` — Trip Details never respected Arabic/RTL regardless of the user's locale, a direct violation of spec FR-004. Removed in all four replacement views (`trip_details_view.dart`, `trip_loading_view.dart`, `trip_error_view.dart`, `trip_empty_view.dart`); they now inherit the ambient, locale-driven `Directionality` like every other screen.
- `route_pricing_card.dart` used `EdgeInsets.only(left: 16)` to separate the "Price range" block from the divider — asymmetric and LTR-only, so the gap would land on the wrong side in RTL. Changed to `EdgeInsetsDirectional.only(start: 16)`.

Everything else flagged by a repo-wide grep for `EdgeInsets.fromLTRB`/`.only(left/right:)` in the touched files turned out to have equal left/right values (e.g. `fromLTRB(16, 14, 16, 0)`), which is direction-agnostic in practice — not a bug, left as-is. Directional icons (`chevron_right_rounded`, `arrow_forward_rounded`) were re-verified against the Flutter SDK and confirmed to carry `matchTextDirection: true`, so no icon swaps were needed (research.md §9).

**Found but explicitly out of scope**: `vehicle_listing_screen.dart`, `vehicle_details_screen.dart`, and `route_option_card.dart` (the booking-wizard screens one step past Route Details) also force `TextDirection.ltr`. Same scope boundary as §8 — these aren't part of the 5 named screens, so left untouched here and flagged for a future prompt rather than silently expanding this feature's blast radius.

## 11. File-length audit (T040)

A repo-wide sweep of every file touched or created this session found exactly three still over 120 lines: `route_map_markers.dart` (326), `live_vehicle_layer.dart` (183), and `animated_vehicle_marker.dart` (125). All three predate this feature — they are map-rendering internals from spec 001 (marker geometry, live-position interpolation), not part of the 5 named screens' presentation composition this feature was scoped to. `git diff --stat` confirms my only edits to them were the T002 `AppMotion` de-duplication, which is net **subtractive** (−22 lines across the three, zero new lines beyond one import each) — I made them smaller, not larger, and introduced no new violation. Splitting them properly would mean refactoring flutter_map layer/marker internals I wasn't tasked to redesign, which is a materially different (and riskier) job than this feature's "presentation-layer redesign of 5 named screens." Left as a flagged, pre-existing item rather than pulled into scope here — same treatment as §8's `CircularProgressIndicator` boundary and §10's out-of-scope forced-LTR screens. Every file actually created or substantively rewritten by this feature is ≤120 lines.

## 8. Scope boundary: `CircularProgressIndicator` removal

**Decision**: Remove `CircularProgressIndicator` only where it appears in the 5 named screens and their direct supporting widgets (none currently found inside `popular_routes_screen.dart`, `route_selection_screen.dart`, `my_trips_screen.dart`, or `trip_details_screen.dart` themselves — they already use custom skeletons). Leave instances in `vehicle_listing_screen.dart`, `vehicle_details_screen.dart`, `booking_wizard_screen.dart`, `wizard_payment_step.dart`, `wizard_package_step.dart`, `daily_booking_flow_screen.dart`, `bookings_screen.dart`, and `map/route_map_info_panel.dart` untouched.

**Rationale**: These files belong to the booking wizard / vehicle-selection steps that come *after* Route Details in the journey but were not named in the spec. Touching them would silently expand scope beyond the five requested screens.

**Alternatives considered**: Removing all app-wide `CircularProgressIndicator` usage now (rejected — not requested, and better tracked as its own follow-up feature so it gets its own review rather than riding along here).
