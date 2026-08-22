# Dashboard — Trips Lifecycle UX & Colour Audit (Phase 3)

**Date** 2026-08-22 · **Scope** UI/UX only — no schema, RLS, RPC, auth, entitlement, or
accounting change. **Branch** `enhance-theme`.

This is the trip-lifecycle-focused follow-up to `DASHBOARD_UX_AUDIT.md` (2026-08-15,
whole-console), the Phase 1 Light Mode pass (Customers, Home, Fleet, Finance), and
`DASHBOARD_FORMS_UX_AUDIT.md` (Phase 2, forms/dialogs). This phase asks the question the
brief posed directly: **"If an owner opens a trip, can they understand everything
important about it within a few seconds?"** — and, separately, whether the trips module's
light-mode colours read as professional or washed out.

---

## 1. Method

1. Read the full trip lifecycle end to end myself: the list screen and its filters
   (`trips_screen.dart`), the row card (`trip_row_card.dart`), the details workspace
   (header, Overview/Passengers/Seats/Pricing/History tabs — all in `trips_screen.dart`),
   the domain model (`operation_trip.dart`, `trip_lifecycle.dart`), the details cubit, the
   pricing tab, and the seat map.
2. One parallel read-only research pass (general-purpose agent, no edits) covering the
   remaining trip widgets — analytics, grouped/timeline views, the filter sheet, the
   cancellation dialog, and the creation wizard's route/driver/vehicle/package sections —
   specifically for information hierarchy and light-mode colour quality.
3. Cross-checked every colour finding against the actual token source
   (`DashboardColors`, `DashboardChartPalette`, `AppStatusTone`) before changing anything,
   so a fix always reuses an existing accessor rather than inventing a new one.
4. Implemented the highest-confidence fixes; built a new visual-QA harness
   (`trip_details_visual_capture.dart`) since none existed for the details workspace, and
   used it to *see* the restructured Overview tab before calling it done — which is how
   the section reordering below (§3, finding 7) was caught.
5. Ran `flutter analyze` and the full trips + dashboard test suites.

## 2. What "a few seconds" was actually failing on

Opening a trip landed on an Overview tab with one section, "بيانات التشغيل" ("operational
data"), that silently mixed three of the brief's categories in one undifferentiated
row of identical grey cards: **who's driving** (driver, vehicle), **how full the trip
is** (occupancy), and **what it costs** (ticket price). Nothing distinguished them by
colour, weight, or grouping — an owner had to read every label to sort facts into
categories themselves. Two more gaps compounded it:

- The one thing that blocks a trip from moving forward (`TripPublishBlocker`) was only
  ever readable inside a `Tooltip` on a disabled button — invisible until the operator
  happened to hover over a button they'd already learned does nothing.
- A passenger's payment status (`TripPassenger.status`, `.paymentMethod`) was fetched by
  the datasource but never rendered anywhere in the Passengers tab — the one place an
  owner would look to see who still owes money.

## 3. Findings and what was done about each

### Information hierarchy (Overview tab restructure)

**1. ✅ Split "بيانات التشغيل" into three labelled, colour-differentiated sections.**
`trips_screen.dart` — `_OverviewTab`. Driver/vehicle/ticket-price now live under
"السائق والمركبة والتكلفة" with each `_InfoCard` carrying a category accent (neutral
for driver/vehicle, the `special` status tone for price — the one hue nothing else in
the workspace uses, so "this card is money" reads before the label does); occupancy
moved to its own "الركاب والسعة" section tinted by *how full the trip is* (see finding
5); route stops stayed with the schedule hero. `_InfoCard` gained an `accent` parameter
reusing the existing icon-square pattern from the header rather than inventing new UI.

**2. ✅ The publish blocker is now a visible banner, not a hover-only tooltip.**
`_DetailsHeader` → new `_PublishBlockerNotice` widget, shown under the header whenever
`TripPublishBlocker.evaluate(trip)` returns non-null and the trip isn't stale (the stale
banner already covers that case). Uses `context.status(AppStatusTone.warning)` — the
existing six-tone status accessor — rather than a one-off colour.

**3. ✅ The header now shows the vehicle, not just the driver.**
`_DetailsHeader` — the identity block only ever named the driver; a second line was
added reusing `TripFact` (already public, from `trip_row_card.dart`) for both driver and
vehicle, so the always-visible header alone now answers "who and what" without opening
Overview.

**4. ✅ Passenger rows show a payment-status chip and payment method.**
`_PassengersTab` — `TripPassenger.status` is written from the same values as a seat's
`TripSeatState` (confirmed in the datasource's booking→seat mapping), so
`TripSeatState.fromString(passenger.status)` plus the existing `tripSeatColor`/
`tripSeatOnColor` gives each row a status chip using the *same* colour vocabulary as the
Seats tab's legend — "paid" is never a different colour on two tabs of the same trip.
`paymentMethod` is appended to the subtitle when present.

**5. ✅ The occupancy card and the row-card progress bar are now colour-coded by fill
level**, not a flat, meaning-free `primary`/`onSurfaceVariant`. New `tripOccupancyColor()`
in `trip_ui_helpers.dart` buckets empty/low/mid/high/full exactly the way
`trips_analytics.dart`'s occupancy donut already did — reusing that logic instead of
inventing a second one — and both `_InfoCard`'s accent and `TripRowCard`'s
`LinearProgressIndicator.color` now read it. An owner scanning the list can spot an
under-booked trip without reading the fraction.

**6. ✅ Every seat state gets a glance-able count, not just a legend.** `_SeatLegend`
gained an optional `count` parameter ("مدفوع (4)"); the Overview's capacity section shows
one for every non-zero state, so "how many paid vs. reserved vs. subscription" is visible
without opening the Seats tab.

**7. ✅ Section order was corrected after the new visual-QA harness showed the problem.**
The first pass put the (small) financial section *last*, after the driver/vehicle
section and the full route-stops list — pushing it below the fold on a typical trip. The
harness screenshot (see §5) made this obvious in a way the code never would have: the
combined "السائق والمركبة والتكلفة" section and the capacity section now come
immediately after the schedule hero; the route-stops list (already summarised by the
hero's origin/destination) moved to the bottom, since it's reference detail an owner
checks occasionally rather than a first-look fact.

**8. ✅ Removed a dead tab.** `TripWorkspaceTab.payments` existed in the enum with a
switch case rendering `_OverviewTab` again — unreachable, since `_TripWorkspaceNav` never
built a nav item for it. Deleted the enum value and the dead case rather than leaving
confusing, unreachable branching in a file this audit was already restructuring.

### Colour quality (light mode)

**9. ✅ Trip status colours contradicted themselves across the module.**
`trip_ui_helpers.dart`'s `tripStatusColor` (list/grouped/timeline rows, details header)
and `trips_analytics.dart`'s own `_statusColor` (the status donut) mapped the *same* six
statuses to different colours — `completed` was grey in row cards but teal in the donut;
`boarding` was tertiary in rows but amber in the donut. Fixed by making the donut
delegate to `tripStatusColor` instead of re-deriving its own mapping, so "amber means
boarding" (or whatever it lands on) is true everywhere at once.

**10. ✅ `TripRowCard`'s status icon and chip used the same too-low alpha the KPI tint
fix (Phase 1) already corrected elsewhere.** `.withAlpha(22)`/`.withAlpha(28)` on a
near-white page is nearly invisible — the exact problem `DashboardColors.kpiTint`/
`kpiBorder` were bumped from 20/60 to 40/115 to fix. `TripRowCard` — rendered for every
trip in every list/grouped/timeline view, the highest-traffic surface in the module —
had never been updated to match. Now uses `DashboardColors.kpiTint(context, ...)`.

**11. ✅ The "paid" seat tile was muddier than its siblings.** `tripSeatColor`'s `paid`
case was `DashboardChartPalette.positive.withAlpha(60)` — but `positive` is an
`onXContainer` ink (a deliberately dark, low-chroma tone meant to sit *as text on* a
container, not to seed one). Alpha-blending it toward white produced a washed grey-teal
instead of an opaque fill, visible in the very first Passengers-tab capture (§5) as a
noticeably duller chip than "reserved" or "subscription" beside it. Every sibling state
uses a real `*Container` colour; `paid` now uses `context.status(AppStatusTone.success)`
— `.tint` for the fill, `.ink` for on-fill text, `.accent` for the border — the exact
container/ink pair that ink was designed to sit on.

**12. ✅ The subscription seat's accent colour didn't adapt to dark mode.**
`trip_seat_map.dart` hardcoded `AppLightColors.special` regardless of brightness, the one
colour in the file that bypassed the brightness-aware resolution every other trip surface
uses. Now resolves `AppDarkColors.special` in dark mode.

**13. ✅ The vehicle-assignment status card (ready/no-vehicle/unschedulable/none) in the
trip creation wizard read as four near-identical faint panels.** `_AssignedVehicleCard`
tinted an already-pale `*Container` colour at a further 30–100 alpha — the same
double-fading problem as finding 10, on the wizard's single most important "can this
trip even be created" signal. Now uses `DashboardColors.kpiTint`/`kpiBorder` against the
state's saturated accent (`scheme.error`/`tertiary`/`primary`/`outline`) instead of its
container.

**14. ✅ Financial information had no representation at the row-card glance level.**
`TripRowCard` showed route, schedule, driver, vehicle, and occupancy — never a fare. The
seat-count line now reads "٧ من ١٠ مقعد • ٧٥ ج.م" via a new shared `formatTripPrice()`
helper (also used by the details header's financial card), so revenue exposure per trip
is visible without opening it.

## 4. Findings verified and *not* acted on — already correct

- **The trip cancellation dialog, the route builder, and the trip pricing dialog's own
  colour usage** were already reviewed and fixed in Phase 2; re-checked here for the
  lifecycle categories this phase cares about and found consistent with the rest of the
  module.
- **`_PlannerReadinessPill`/`_PlannerStatusChip` alphas** in the creation wizard (70/90/60)
  are pale but distinguishable by hue (tinted vs. neutral), unlike finding 13's four
  same-hue-different-alpha states — left alone to keep this pass's wizard changes scoped
  to the one genuinely confusing case.

## 5. Visual verification

Light Mode, via a new harness (`test/apps/dashboard/features/trips/trip_details_visual_capture.dart`)
built specifically for this pass — no capture of the details workspace existed before,
because `TripDetailsWorkspace` (the dialog's content widget) was private. It was made
public (`TripDetailsWorkspace`, formerly `_TripDetailsDialog`) solely so a test could pump
it directly against a fake `TripDetailsCubit` without standing up the full `TripsScreen`
and its five-cubit DI graph; every other helper widget inside it stays private.

| Capture | What it confirms |
|---|---|
| `trip_details_1_overview_light` | The corrected section order (driver/vehicle/price, then capacity, then route stops) is visible without scrolling on a normally-booked trip; the financial card's distinct `special`-tone icon square reads apart from the neutral driver/vehicle cards |
| `trip_details_2_passengers_light` | Three passengers in three different payment states render three visibly distinct chip colours, matching the Seats tab's legend |
| `trip_details_3_publish_blocker_light` | A trip missing a driver shows "لا يوجد سائق معيّن لهذه الرحلة" as a standing amber banner, not a tooltip — confirmed by taking the screenshot with no simulated hover/tap at all |
| `trip_details_4_row_card_light` | The row card's status badge, occupancy bar colour, and the new price text all render correctly against a light page |

Regenerate with `flutter test test/apps/dashboard/features/trips/trip_details_visual_capture.dart --update-goldens`.

## 6. Final verification

- **`flutter analyze`**: 21 issues before this pass, 21 after — identical set, none in any
  file this pass touched.
- **Trips test suite**: 133 passing / 134 total before and after (the pre-existing
  `trip_creation_driver_vehicle_test.dart` failure — a stale `/assignments` route
  assertion from the 2026-08-20 fleet-simplification rename, documented in Phase 2 — is
  unchanged and unrelated). Plus 4 new visual-QA test cases (not behaviour assertions).
- **Full dashboard suite** (`flutter test test/apps/dashboard/`): 1428 passing / 1429
  total, same single pre-existing failure, no regressions.

## 7. Recommended next steps

1. **Live tracking is invisible from a trip's details.** An owner opening an in-progress
   trip has no way to see whether it's actually being tracked or where the bus is without
   leaving to the separate Live Ops Center (`/live-ops`), which reads `trip_live_locations`
   independently. A cross-link (reusing the existing `onOpenModule` callback pattern
   already used by the creation wizard) is the cheap version; a live status chip is the
   fuller one. Deferred — it needs `onOpenModule` threaded through `_openTripDetails` and
   three call sites (`_TripsList`, `TripsGroupedView`, `TripsTimelineView`), which is more
   plumbing than this pass's Overview-focused scope warranted.
2. **No authoritative revenue-collected figure exists on `OperationTrip`.** Only
   `ticketPrice` (the catalogue rate) is available; actual money collected lives in the
   booking/payment ledger the Finance module owns (see `project_finance_read_only`
   precedent: naive `ticketPrice × bookedSeats` would ignore package-priced passengers and
   reproduce exactly the "wrong live number" class of bug Finance has already been burned
   by). If trip-level revenue is wanted here, it needs a real join, not a client-side
   multiplication — a data-layer change outside this UI-only pass's scope.
3. **`_PlannerReadinessPill`/`_PlannerStatusChip`** (creation wizard) could still take the
   `kpiTint`/`kpiBorder` treatment for consistency with finding 13, though they were not
   confusing enough on their own to justify touching wizard code beyond this pass's one
   fix.
