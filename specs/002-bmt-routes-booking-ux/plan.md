# Implementation Plan: Prompt 4 – BMT Routes & Booking Journey Premium UX

**Branch**: `[002-bmt-routes-booking-ux]` | **Date**: 2026-07-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-bmt-routes-booking-ux/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Redesign the client passenger's discovery-to-trips journey — routes hub, search results/discovery, filters, route details, and trips — into a cohesive, premium presentation layer built entirely on the BMT design system delivered by spec `001-bmt-brand-identity-premium-ux`. The underlying Cubits, use cases, repositories, entities, and navigation are unchanged; the plan replaces ad hoc popup-menu filters with a real filter bottom sheet, decomposes several screens that already exceed the project's 120-line file limit into small composable widgets, replaces remaining `CircularProgressIndicator` usage in the five in-scope screens with layout-matching skeletons, and reconciles the two parallel token scales (`AppTokens` vs `ClientSpacing/ClientRadius`) uncovered during research.

## Technical Context

**Language/Version**: Dart 3 / Flutter stable

**Primary Dependencies**: `flutter_bloc` (Cubit/Bloc), `get_it`, `flutter_map` + `latlong2` (route map — not `google_maps_flutter`), the existing BMT design system (`lib/core/theme/`, `lib/core/widgets/`) and client theme layer (`lib/apps/client/core/theme/`, `lib/apps/client/core/widgets/`) delivered by spec 001, existing Supabase-backed repositories for routes/trips/bookings

**Storage**: N/A for this feature directly — runtime data continues to flow through the existing Supabase-backed repositories (`routes`, `route_stations`, `operation_trips`, `trip_pricing`, `trip_seats`, `operation_bookings`); no schema or data-source changes

**Testing**: Existing Cubit/domain patterns per `CLAUDE.md` §19; add a unit test only where new pure presentation logic is extracted (e.g., a filter-combination/sort helper); manual UX, responsive, RTL, and accessibility review consistent with spec 001's quickstart approach

**Target Platform**: Flutter mobile (Client App primary target), tablet/desktop via the shared responsive breakpoints already defined in `AppLayout`

**Project Type**: Presentation-layer redesign within an existing Flutter monorepo feature (`lib/apps/client/features/{routes,booking,trips}`)

**Performance Goals**: Smooth 60fps scrolling on route/trip result lists and the route-details map; no added rebuild cost from decomposing large screens into smaller widgets (use `BlocSelector`/`const` widgets per `CLAUDE.md` §17)

**Constraints**: Must not alter Cubit contracts (`BookingCubit`, `BookingState`, `RoutesHubCubit`, `TripsCubit`, `TripsState`), use cases, repositories, entities, Supabase queries, or named navigation routes (`BookingRoutes`, `TripsRoutes`); must keep every file at or under 120 lines per `CLAUDE.md` §6, which requires splitting several existing files (see Complexity Tracking); must preserve full RTL/Arabic support and reduced-motion behavior already established by spec 001

**Scale/Scope**: 5 screens named in the spec, mapped to real existing files: Routes Hub (`routes/presentation/screens/routes_hub_screen.dart`), Search Results/Discovery (`booking/presentation/screens/popular_routes_screen.dart`), Filters (currently `PopupMenuButton`s inside `popular_routes_screen.dart` — to become a real bottom sheet), Route Details (`booking/presentation/screens/route_selection_screen.dart`, with `route_overview_screen.dart` as a secondary simpler variant), and Trips (`trips/presentation/screens/my_trips_screen.dart` + `trip_details_screen.dart`), plus their direct supporting widgets and cubits

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

This repository's `CLAUDE.md` functions as the project constitution (`.specify/memory/constitution.md` is still the unfilled template). Evaluated against it:

- **Pass** — Clean Architecture stays intact: only `presentation/` (screens + widgets) changes; `domain/` and `data/` layers are untouched (§5).
- **Pass** — Cubits continue to depend only on use cases; no repository or datasource access is added to widgets/screens (§14).
- **Pass** — No mock, demo, or hardcoded operational data is introduced; all content continues to come from the existing Supabase-backed repositories (§7).
- **Pass** — Shared UI is centralized: new reusable pieces (e.g., a filter bottom sheet, route/trip result cards, skeletons) are added to `lib/core/widgets/` or `lib/apps/client/core/widgets/` when used in 2+ places rather than duplicated per screen (§6).
- **Conditional pass, remediation in scope** — The 120-line-per-file rule (§6) is already violated by several files this feature touches (`route_selection_screen.dart` at 1254 lines, `trip_details_screen.dart` at 1488 lines, `popular_routes_screen.dart` at 923 lines, `my_trips_screen.dart` at 400 lines, `routes_hub_screen.dart` at 358 lines). This plan treats decomposing them into ≤120-line widgets as required, in-scope remediation rather than a violation to justify away.

## Project Structure

## Project Structure

### Documentation (this feature)

```text
specs/002-bmt-routes-booking-ux/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

No `contracts/` directory is generated: this feature exposes no new external interface (no new API, CLI, or schema) — it restyles and recomposes presentation on top of the existing repository/use-case contracts, same as spec 001.

### Source Code (repository root)

```text
lib/
├── core/
│   ├── theme/                     # AppTokens/AppColors/AppTextThemes/AppLayout/AppSurfaceStyle (spec 001) — reused, extended only where a real gap is found (e.g. reduced-motion helper)
│   ├── widgets/                   # AppButton, AppCard, StatusChip, Badge, RouteInfoCard, StationStopCard, CaptainCard, EmptyState, SkeletonBox, AsyncStateView, AppDialogs — reused; new cross-screen primitives (e.g. FilterBottomSheet) added here
│   └── tracking/                  # Live vehicle/route progress engine — reused as-is for Route Details map + active trip progress
└── apps/client/
    ├── core/
    │   ├── theme/                 # ClientColors, ClientSpacing/Radius/Motion/Elevation — reconciled against core AppTokens (see research.md)
    │   └── widgets/                # ClientSkeleton, ClientErrorCard — extended with per-screen skeleton layouts
    └── features/
        ├── routes/                # Routes Hub: presentation/screens/routes_hub_screen.dart + cubit/domain/data (thin CTA screen)
        ├── booking/                # Real search/filter/details flow
        │   └── presentation/
        │       ├── screens/        # popular_routes_screen.dart (results/discovery), route_selection_screen.dart (route details), route_overview_screen.dart (secondary details variant)
        │       ├── widgets/        # route/trip result cards, new filter bottom sheet + filter chips
        │       ├── widgets/map/     # existing branded map layers (route_map_markers.dart, live_vehicle_layer.dart, etc.) — untouched, only re-embedded in the redesigned layout
        │       └── cubit/          # booking_cubit.dart / booking_state.dart — untouched contracts
        └── trips/
            └── presentation/
                ├── screens/        # my_trips_screen.dart, trip_details_screen.dart
                ├── widgets/        # trip_card.dart, trip_filter_bar.dart, new status/progress components
                └── cubit/          # trips_cubit.dart / trips_state.dart — untouched contracts
```

**Structure Decision**: All redesign work stays inside each feature's existing `presentation/` layer. Oversized screens are decomposed into small, composable widget files colocated under each feature's `presentation/widgets/`, keeping every file ≤120 lines per `CLAUDE.md` §6. Any visual pattern that repeats across 2+ of the 5 in-scope screens (filter bottom sheet, result-card shells, skeleton layouts, status badges) is promoted to `lib/core/widgets/` (if platform-wide) or `lib/apps/client/core/widgets/` (if client-specific), never duplicated per screen. `domain/` and `data/` layers, Cubit/state contracts, and named routes in `booking_routes.dart` / `trips_routes.dart` are not modified.

## Complexity Tracking

> Documenting pre-existing constitution deviations this plan must remediate, not new ones it introduces.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `route_selection_screen.dart` (1254 lines), `trip_details_screen.dart` (1488 lines), `popular_routes_screen.dart` (923 lines) already exceed the 120-line limit before this feature starts | These are exactly the screens the spec asks to redesign; touching them without splitting them would perpetuate the violation | Leaving them oversized was rejected because `CLAUDE.md` §6 is non-negotiable and this feature is the natural opportunity to fix it — deferring the split to a separate cleanup effort would mean redesigning UI twice |
| `CircularProgressIndicator` usage found in adjacent booking-wizard/vehicle/payment screens (e.g. `vehicle_listing_screen.dart`, `wizard_payment_step.dart`) is out of the 5 named screens | Spec 002 only names Routes Hub, Search Results, Filters, Route Details, and Trips | Expanding scope to every `CircularProgressIndicator` in the app was rejected because it is not in the user's requested screen list; tracked here so a future "Prompt 5" can pick it up deliberately instead of silently expanding this feature's blast radius |
