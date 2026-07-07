# Tasks: Prompt 3 – BMT Brand Identity & Premium UX

**Input**: Design documents from `/specs/001-bmt-brand-identity-premium-ux/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Not requested in the feature specification, so implementation tasks focus on the production UX system and validation checkpoints.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare the shared BMT design foundation used across all apps

- [x] T001 [P] Define the BMT semantic palette and status roles in `lib/core/theme/colors.dart`
- [x] T002 [P] Expand the shared spacing, radius, and motion tokens in `lib/core/theme/tokens.dart` and `lib/core/theme/spacing.dart`
- [x] T003 [P] Rebuild the multilingual typography hierarchy in `lib/core/theme/text_themes.dart` and `lib/core/theme/app_typography.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core theming and shared primitives that all user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Refactor the base theme assembly and surface extension model in `lib/core/theme/app_theme.dart` and `lib/core/theme/app_surface_style.dart`
- [x] T005 [P] Align app theme entry points to the shared BMT system in `lib/apps/dashboard/core/theme/dashboard_app_theme.dart`, `lib/apps/client/core/theme/client_theme.dart`, `lib/apps/client/core/theme/client_app_theme.dart`, and `lib/apps/captain/core/theme/captain_theme.dart`
- [x] T006 [P] Update application bootstrap surfaces to consume the shared BMT theme in `lib/apps/dashboard/main.dart`, `lib/apps/client/client_app.dart`, and `lib/apps/captain/main.dart`
- [x] T007 [P] Normalize common card, surface, and feedback primitives in `lib/core/widgets/app_surface.dart`, `lib/core/widgets/app_card.dart`, `lib/core/widgets/app_button.dart`, `lib/core/widgets/status_chip.dart`, `lib/core/widgets/badge.dart`, `lib/core/widgets/empty_state.dart`, `lib/core/widgets/skeleton.dart`, and `lib/core/widgets/app_dialogs.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Premium Brand Foundation (Priority: P1) 🎯 MVP

**Goal**: Make every core BMT surface feel like one premium, trusted, operational brand.

**Independent Test**: Compare representative dashboard, client, and captain surfaces and confirm the same premium brand language, hierarchy, and spacing are visible without explanation.

### Implementation for User Story 1

- [ ] T008 [P] [US1] Apply the BMT visual language to operational headers, metrics, labels, and separators in `lib/core/widgets/section_header.dart`, `lib/core/widgets/metric_tile.dart`, `lib/core/widgets/label.dart`, and `lib/core/widgets/separator.dart`
- [ ] T009 [P] [US1] Refine the premium layout rhythm and surface depth in `lib/core/theme/app_layout.dart`, `lib/core/theme/spacing.dart`, and `lib/core/widgets/app_surface.dart`
- [ ] T010 [US1] Harmonize dashboard, client, and captain shell screens for the shared BMT identity in `lib/apps/dashboard/main.dart`, `lib/apps/client/client_app.dart`, and `lib/apps/captain/main.dart`
- [ ] T011 [P] [US1] Tighten brand consistency in representative app chrome surfaces in `lib/apps/dashboard/core/theme/dashboard_app_theme.dart`, `lib/apps/client/core/theme/client_app_theme.dart`, and `lib/apps/captain/core/theme/captain_theme.dart`

**Checkpoint**: User Story 1 should now be fully functional and visually testable on its own

---

## Phase 4: User Story 2 - Map-First Transportation Experience (Priority: P2)

**Goal**: Make routes, stops, and vehicles feel native to a branded BMT transportation map experience.

**Independent Test**: Open a route map and a live monitoring map, then confirm the route, stops, and vehicle are immediately distinguishable in both light and dark themes.

### Implementation for User Story 2

- [x] T012 [P] [US2] Rebrand route stop pins, callouts, and selected-state motion in `lib/apps/client/features/booking/presentation/widgets/map/route_map_markers.dart`
- [x] T013 [P] [US2] Rework live vehicle rendering and motion treatment in `lib/apps/client/features/booking/presentation/widgets/map/live_vehicle_layer.dart` and `lib/core/widgets/tracking/animated_vehicle_marker.dart`
- [x] T014 [P] [US2] Align route path, overlays, and legend styling in `lib/apps/client/features/booking/presentation/widgets/map/route_map_overlays.dart`, `lib/apps/client/features/booking/presentation/widgets/map/animated_route_line.dart`, and `lib/apps/client/features/booking/presentation/widgets/map/route_map_info_panel.dart`
- [x] T015 [P] [US2] Update the shared tracking map presentation for dashboard monitoring in `lib/core/widgets/tracking_map_card.dart` and `lib/core/widgets/tracking/live_vehicle_layer.dart`
- [x] T016 [US2] Refine the map loading and fallback experience in `lib/core/widgets/map_placeholder.dart` and `lib/core/widgets/async_state_view.dart`

**Checkpoint**: User Stories 1 and 2 should now both be usable independently

---

## Phase 5: User Story 3 - Operational Components That Scale (Priority: P3)

**Goal**: Standardize captain cards, stop cards, route summaries, sheets, dialogs, and reusable UI states across the platform.

**Independent Test**: Review captain cards, stop cards, route summary components, buttons, chips, badges, sheets, and feedback states and confirm they share one premium component language.

### Implementation for User Story 3

- [x] T017 [P] [US3] Create a reusable captain identity card in `lib/core/widgets/captain_card.dart`
- [x] T018 [P] [US3] Create a reusable route information component in `lib/core/widgets/route_info_card.dart`
- [x] T019 [P] [US3] Create a reusable station and stop card in `lib/core/widgets/station_stop_card.dart`
- [x] T020 [P] [US3] Update buttons, chips, and badges for premium SaaS interaction states in `lib/core/widgets/app_button.dart`, `lib/core/widgets/status_chip.dart`, and `lib/core/widgets/badge.dart`
- [x] T021 [P] [US3] Refine bottom-sheet and dialog surfaces for quick actions and confirmations in `lib/core/widgets/app_dialogs.dart`
- [x] T022 [US3] Standardize loading, empty, error, and success feedback across reusable components in `lib/core/widgets/empty_state.dart`, `lib/core/widgets/skeleton.dart`, `lib/core/widgets/progress_bar.dart`, and `lib/core/widgets/app_snackbar.dart`
- [x] T023 [US3] Apply the reusable card and component language to representative journey screens in `lib/apps/client/features/booking/presentation/widgets/available_trip_card.dart`, `lib/apps/captain/features/passenger_manifest/presentation/widgets/passenger_card.dart`, and `lib/apps/dashboard/features/reports/presentation/widgets/report_kpi_grid.dart`

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency, accessibility, and responsiveness review across the shared BMT experience

- [x] T024 [P] Audit contrast, RTL behavior, and reduced-motion behavior across `lib/core/theme/app_theme.dart` and `lib/core/widgets/`
- [x] T025 [P] Verify premium responsive behavior on phone, tablet, and desktop breakpoints in `lib/core/theme/app_layout.dart` and `lib/apps/*/presentation/**`
- [x] T026 [P] Review `specs/001-bmt-brand-identity-premium-ux/quickstart.md` against the implemented surfaces and capture any remaining polish gaps
- [x] T027 [P] Update the feature documentation in `specs/001-bmt-brand-identity-premium-ux/plan.md`, `specs/001-bmt-brand-identity-premium-ux/research.md`, and `specs/001-bmt-brand-identity-premium-ux/data-model.md` if any implementation decisions diverge from the spec

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
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Core primitives before app-specific refinements
- App shell and map surfaces before representative screen polish
- Shared components before screen-level adoption
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
Task: "Apply the BMT visual language to operational headers, metrics, labels, and separators in lib/core/widgets/section_header.dart, lib/core/widgets/metric_tile.dart, lib/core/widgets/label.dart, and lib/core/widgets/separator.dart"
Task: "Refine the premium layout rhythm and surface depth in lib/core/theme/app_layout.dart, lib/core/theme/spacing.dart, and lib/core/widgets/app_surface.dart"
Task: "Tighten brand consistency in representative app chrome surfaces in lib/apps/dashboard/core/theme/dashboard_app_theme.dart, lib/apps/client/core/theme/client_app_theme.dart, and lib/apps/captain/core/theme/captain_theme.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Demo or review the premium brand system before continuing

### Incremental Delivery

1. Complete Setup + Foundational → shared design base is ready
2. Add User Story 1 → verify brand identity and shell consistency
3. Add User Story 2 → verify map-first transportation experience
4. Add User Story 3 → verify reusable premium components and feedback states
5. Finish with polish tasks to tighten accessibility and responsive behavior

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
- Verify each story's visual outcome before moving to the next priority
- Keep the BMT identity premium, calm, and operational rather than decorative
