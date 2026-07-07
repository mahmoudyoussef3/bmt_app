# Tasks: Prompt 4 – BMT Routes & Booking Journey Premium UX

**Input**: Design documents from `/specs/002-bmt-routes-booking-ux/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Not requested in the feature specification beyond one pure presentation helper (see T003); the rest of validation is the manual `quickstart.md` walkthrough, consistent with spec 001.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Resolve the token/animation gaps `research.md` found before any screen work starts

- [x] T001 [P] Reconcile `ClientSpacing`/`ClientRadius`/`ClientMotion`/`ClientElevation` to delegate to `AppTokens` values in `lib/apps/client/core/theme/client_design_tokens.dart` (research.md §1)
- [x] T002 [P] Extract the repeated accessibility reduced-motion check into a shared helper (e.g. `AppMotion.reduceMotion(BuildContext)`) in `lib/core/theme/motion_preference.dart` (research.md §6)
- [x] T003 [P] Add a derived route-type classifier (direct vs. multi-stop, from `RouteOptionData.points.length`) with a unit test in `lib/apps/client/features/booking/presentation/utils/route_type_classifier.dart` and `test/apps/client/features/booking/presentation/utils/route_type_classifier_test.dart`, for use in Route Details' alternative-routes list (research.md §2 — not applicable to the discovery grid, which has no stop data)

**Checkpoint**: Token source of truth and motion helper exist — foundational widgets can now consume them.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared primitives that User Stories 1–3 all depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Create the `FilterBottomSheet` shell (tiered header, scrollable body slot, active-filter summary, apply/reset footer) in `lib/apps/client/core/widgets/filter_bottom_sheet.dart`
- [x] T005 [P] Create a reusable range-slider filter control in `lib/apps/client/core/widgets/filter_range_slider.dart`
- [x] T006 [P] Create reusable filter chip-group and segmented-control primitives in `lib/apps/client/core/widgets/filter_chip_group.dart`
- [x] T007 [P] Create a `RouteFilterCriteria` presentation model with combine/remove-one/reset-all logic and a unit test in `lib/apps/client/features/booking/presentation/models/route_filter_criteria.dart` and its `_test.dart`
- [x] T008 Confirmed: `AsyncStateView` (`lib/core/widgets/async_state_view.dart`) hardcodes Arabic-only default copy and its own `CircularProgressIndicator`, making it a poor fit for the client app's bidirectional requirement — the 5 screens keep their existing per-screen contract (`ClientErrorCard` + `ClientSkeleton`-family custom skeletons + a local empty-state widget per screen), not a migration to `AsyncStateView`. No code change for this task; documented so later tasks don't second-guess it.

**Checkpoint**: Filter primitives and the shared loading/empty/error contract are ready — user story implementation can now begin.

---

## Phase 3: User Story 1 - Route Discovery & Comparison (Priority: P1) 🎯 MVP

**Goal**: Make the Routes Hub, search/discovery results, and filters feel instant, scannable, and comparable.

**Independent Test**: From the routes entry point, search/browse to results, apply a filter combination, and confirm origin/destination/duration/distance/seats/price/departure/status are all visible on each card without opening it, with active filters shown and resettable.

### Implementation for User Story 1

- [x] T009 [P] [US1] Redesign the Routes Hub header, search CTA, and how-it-works section using `AppCard`/`AppButton`/`AppTokens` hierarchy in `lib/apps/client/features/routes/presentation/screens/routes_hub_screen.dart`, extracting any section over 120 lines into `lib/apps/client/features/routes/presentation/widgets/`
- [x] T010 [P] [US1] Build a Routes-Hub-specific skeleton mirroring its final layout in `lib/apps/client/features/routes/presentation/widgets/routes_hub_skeleton.dart`
- [x] T011 [US1] Decompose `lib/apps/client/features/booking/presentation/screens/popular_routes_screen.dart` (923 lines) into a discovery header (title/subtitle/count, search field, and a single "Filters" trigger with an active-count badge) and a results list, extracting `lib/apps/client/features/booking/presentation/widgets/routes_discovery_header.dart`. Decision: sort lives inside the same `FilterBottomSheet` as its own group (already wired in T013's `route_filter_sheet_content.dart`) rather than a separate standalone sort menu — one combined filter+sort entry point, consistent with spec FR-002 treating sort as part of "the filter experience."
- [x] T012 [US1] Build the redesigned result card (built on `RouteInfoCard`) surfacing origin, destination, duration, distance, available seats, price, departure time, and status in `lib/apps/client/features/booking/presentation/widgets/route_result_card.dart`
- [x] T013 [US1] Replace `_LocationFilterMenu`/`_DurationFilterMenu` popup menus with the `FilterBottomSheet` (T004–T007) wired to the dimensions `PopularRouteListData` actually has — price range, duration range, pickup, destination, and sort (research.md §2) — in `lib/apps/client/features/booking/presentation/screens/popular_routes_screen.dart` and new `lib/apps/client/features/booking/presentation/widgets/route_filter_sheet_content.dart`
- [x] T014 [US1] Add an active-filters row with per-filter removal and a single reset-all action in `lib/apps/client/features/booking/presentation/widgets/active_filters_row.dart`
- [x] T015 [US1] Build a results-list skeleton matching `route_result_card`'s shape, replacing `_RoutesLoadingSkeleton`, in `lib/apps/client/features/booking/presentation/widgets/route_results_skeleton.dart`
- [x] T016 [US1] Redesign the no-results empty state (explanation + adjust/reset-filters + browse-popular actions) in `lib/apps/client/features/booking/presentation/widgets/route_results_empty_state.dart`, replacing `_RoutesEmptyState`
- [x] T017 [US1] Redesign the results error state (illustration, plain-language message, retry) reusing `ClientErrorCard`, replacing `_BookingErrorState` in `popular_routes_screen.dart`
- [x] T018 [US1] Add press/selection micro-interactions to result cards and filter chips (scale/fade feedback) using the `AppMotion` helper from T002, applied across T012–T014

**Checkpoint**: User Story 1 is fully functional and independently testable.

---

## Phase 4: User Story 2 - Confident Booking Decision (Priority: P2)

**Goal**: Make Route Details the clear, trustworthy centerpiece that leads naturally to booking.

**Independent Test**: Open a route's details from the results screen and confirm the overview, stop timeline, map, pricing, seat availability, and driver/vehicle identity are each a distinct legible section, with one unambiguous path into booking, including when map data is missing.

### Implementation for User Story 2

- [x] T019 [US2] Decompose `lib/apps/client/features/booking/presentation/screens/route_selection_screen.dart` (1254 lines) into section widgets under `lib/apps/client/features/booking/presentation/widgets/route_details/`: `route_overview_header.dart`, `route_pricing_card.dart`, `route_available_trips_section.dart` (add a `FilterBottomSheet` for price/departure-time/arrival-time/seats/vehicle-type/sort against `RouteTripOptionData`, the one place all of FR-002's dimensions have real data — research.md §2), `route_alternatives_section.dart` (apply the T003 route-type classifier as a chip per `RouteOptionData` alternative)
- [x] T020 [P] [US2] Rebuild the stop timeline using `StationStopCard` (spec 001) so long stop names remain readable, in `lib/apps/client/features/booking/presentation/widgets/route_details/route_stop_timeline.dart`
- [x] T021 [P] [US2] Corrected scope (no driver data exists at this screen — `RouteTripOptionData` has no driver field; that only appears one step later on `AvailableTripData`/`available_trip_card.dart`, out of scope): rebuild the available-trips list as `route_available_trips_section.dart` + `trip_option_tile.dart`, showing vehicle type/seats/times/price per trip, and add the seats/vehicle-type/departure-arrival-time/sort `FilterBottomSheet` here (research.md §2) — the one place all of FR-002's remaining dimensions have real data
- [x] T022 [US2] Re-embed the existing branded map (`google_style_map_view.dart`) in the redesigned layout with graceful fallback to the existing `_NoMapPlaceholder`/`AsyncStateView` pattern, in `route_selection_screen.dart`
- [x] T023 [US2] Add a single, unambiguous sticky booking CTA leading into the existing `BookingWizardCubit` flow, in `lib/apps/client/features/booking/presentation/widgets/route_details/route_booking_cta.dart`
- [x] T024 [US2] Build a route-details skeleton mirroring the new section layout, replacing `_RouteDetailsLoading`, in `lib/apps/client/features/booking/presentation/widgets/route_details/route_details_skeleton.dart`
- [x] T025 [US2] Redesign the route-details empty/error states (`_RouteEmptyState`/`_BookingErrorState`) with branded illustration and retry, in the same `route_details/` widgets folder
- [x] T026 [US2] Corrected scope: `route_overview_screen.dart` is registered at `BookingRoutes.routeOverview` but nothing in the app ever calls `pushNamed` to it — confirmed via a repo-wide grep, it is unreachable dead code today. Do a light split-only pass to satisfy the 120-line rule (no premium redesign investment on a screen no user can currently reach); flag it for the user to decide whether to wire it up or remove it in a future prompt.
- [x] T027 [US2] Add section-entrance and map-aligned transition motion (fade/slide) using the `AppMotion` helper, applied across T019–T026

**Checkpoint**: User Stories 1 and 2 are both independently functional.

---

## Phase 5: User Story 3 - Trip Lifecycle Visibility (Priority: P3)

**Goal**: Make upcoming, active, completed, and cancelled trips clearly separated, statused, and browsable.

**Independent Test**: Open the trips screen with trips in all four states and confirm each group is independently browsable, every trip shows a non-color-only status indicator, an active trip shows progress, and empty/error states are tailored per section.

### Implementation for User Story 3

- [x] T028 [US3] Decompose `lib/apps/client/features/trips/presentation/screens/trip_details_screen.dart` (1488 lines) into `lib/apps/client/features/trips/presentation/widgets/trip_details/`: `trip_hero_header.dart`, `trip_ticket_card.dart`, `trip_live_tracking_card.dart`, `trip_driver_vehicle_card.dart`, `trip_seats_payment_card.dart`, `trip_actions_bar.dart`
- [x] T029 [P] [US3] Redesign `lib/apps/client/features/trips/presentation/widgets/trip_card.dart` with a non-color-only status badge and a progress affordance for active trips
- [x] T030 [US3] Redesign `lib/apps/client/features/trips/presentation/screens/my_trips_screen.dart` layout (header, stat chips, section list) so upcoming/active/completed/cancelled stay clearly separated, extracting `_TripsHeader`/`_StatChip`/`_SectionTitle` into `lib/apps/client/features/trips/presentation/widgets/`
- [x] T031 [P] [US3] Wire the in-progress trip's live progress indicator to the existing tracking/progress engine (`lib/core/tracking/progress/`) in `lib/apps/client/features/trips/presentation/widgets/trip_details/trip_live_tracking_card.dart`
- [x] T032 [US3] Build per-section skeleton layouts matching `trip_card`'s shape, replacing `_TripsLoadingSkeleton`, in `lib/apps/client/features/trips/presentation/widgets/trips_list_skeleton.dart`
- [x] T033 [US3] Redesign tailored empty states per trip-filter section (no upcoming/active/completed/cancelled), each with a relevant next action, in `lib/apps/client/features/trips/presentation/widgets/trips_empty_state.dart`
- [x] T034 [US3] Redesign the trips list error state and the trip-details loading/empty/error views (`_TripLoadingView`/`_TripErrorView`/`_TripEmptyView`) with plain-language retry, in `trip_details_screen.dart` and a new `trips_error_state.dart`
- [x] T035 [US3] Add tab-switch and status-change micro-interactions/haptics for trip transitions using the `AppMotion` helper, applied across T028–T034

**Checkpoint**: All three user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency, accessibility, and regression checks across the whole journey

- [x] T036 [P] Confirm no `CircularProgressIndicator` remains inside the 5 named screens or any widget created in T009–T035 (routes/, `popular_routes_screen.dart`, `route_selection_screen.dart`, `route_overview_screen.dart`, trips/)
- [x] T037 [P] RTL/Arabic pass: replace directional icons (`arrow_forward`/`arrow_back`) with logical equivalents and audit `EdgeInsetsDirectional` usage across every file touched in T009–T035
- [x] T038 [P] Accessibility audit (contrast, touch targets, screen-reader labels, reduced-motion behavior) across every file touched in T009–T035
- [x] T039 [P] Responsive check across phone/tablet/desktop breakpoints (`AppLayout`) for all 5 redesigned screens
- [x] T040 File-length audit confirming every file touched or created by this feature is ≤120 lines per `CLAUDE.md` §6; split any stragglers
- [x] T041 Run `specs/002-bmt-routes-booking-ux/quickstart.md` end-to-end (all 4 scenarios, light/dark, RTL/LTR, reduced motion) and record results
- [x] T042 [P] Update `plan.md`/`research.md`/`data-model.md` in `specs/002-bmt-routes-booking-ux/` if implementation diverges from what was planned

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel if staffing allows
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Reuses `RouteFilterCriteria`/`FilterBottomSheet` only indirectly (route details has no filters); independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Independently testable; T031 reuses the existing tracking/progress engine also used by US2's map, but does not depend on US2's tasks completing

### Within Each User Story

- Screen decomposition before section/sub-widget redesign
- Shared component adoption before micro-interaction polish
- Loading/empty/error states before the checkpoint is considered met
- Story complete before moving to the next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel within Phase 2
- Once Foundational phase completes, all user stories can start in parallel if needed
- All story tasks marked [P] can run in parallel when they touch different files
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
Task: "Redesign the Routes Hub header, search CTA, and how-it-works section in lib/apps/client/features/routes/presentation/screens/routes_hub_screen.dart"
Task: "Build a Routes-Hub-specific skeleton in lib/apps/client/features/routes/presentation/widgets/routes_hub_skeleton.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run `quickstart.md` scenario 1 independently
5. Demo or review Route Discovery & Comparison before continuing

### Incremental Delivery

1. Complete Setup + Foundational → shared filter/loading primitives ready
2. Add User Story 1 → verify discovery/results/filters feel premium and comparable
3. Add User Story 2 → verify Route Details guides naturally to booking
4. Add User Story 3 → verify trip lifecycle grouping, progress, and status clarity
5. Finish with polish tasks (T036–T042) to close RTL, accessibility, responsive, and file-size gaps

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- No Cubit/UseCase/Repository/entity/named-route file is modified by any task above — all changes stay in `presentation/`
- Keep the BMT identity premium, calm, and operational rather than decorative, consistent with spec 001

## Implementation Notes (T042 — plan vs. delivered)

All 42 tasks are complete. Where the delivered file layout diverged from this task list's original guesses (made before reading the real code), the change and reason are logged in `research.md`; summary pointers:

- **T009/T012** delivered as `RoutesHubHero`/`RoutesHubSearchCard`/`RoutesHubFlowSteps` and `PopularRouteListCard` decomposed into `route_card_header.dart`/`route_card_endpoint_line.dart`/`route_card_chips.dart`/`route_fact_chip.dart`/`route_card_cta_row.dart`/`route_line_dots.dart` — the existing card was already premium; it was decomposed and switched to `ClientCard` rather than rebuilt from `AppCard`/`RouteInfoCard` as first guessed.
- **T019–T021** delivered under `presentation/widgets/route_details/` with the file names in research.md §2 — the stop timeline kept its richer pickup/dropoff detail instead of downgrading to the generic `StationStopCard`, and the available-trips filter sheet (`trip_filter_sheet_content.dart`, `TripFilterCriteria`) is the real FR-002 fulfillment point, not the discovery grid.
- **T023** delivered as `route_booking_action.dart` (`RouteBookingAction`), not `route_booking_cta.dart`.
- **T026** delivered as a light split of `route_overview_screen.dart` (confirmed unreachable dead code) plus new shared `no_map_placeholder.dart`.
- **T028–T034** delivered under `presentation/widgets/trip_details/` (20+ small files; see research.md §10 for the two real bugs fixed while decomposing: the forced-LTR `Directionality` wrap and the "Track Vehicle" copy-paste in the cancel-trip action row) rather than the six originally-guessed filenames.
- **T031** delivered as a genuine live integration (`TripLiveTrackingCard` + `TripProgressSummary`, a locally-scoped `TrackingCubit`) reading `RouteProgressSnapshot.routeFraction` from the real engine, with a fail-open fallback when no vehicle fix is available yet — not a fabricated progress bar.
- **T036–T040**: see research.md §8 (`CircularProgressIndicator` scope boundary), §9–10 (RTL findings), §11 (file-length audit) for what was found, fixed, and explicitly left out of scope.
- **T041**: see `quickstart.md`'s "Verification Log" — automated checks (analyze/tests/app-boot) passed; interactive tap-through was not possible in this environment (no GUI automation permission) and is flagged for a human pass before merge.
