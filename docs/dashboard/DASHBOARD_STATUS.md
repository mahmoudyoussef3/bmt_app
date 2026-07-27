# Dashboard Status Register

The honest state of the EWT operations dashboard: what is finished, what is finished *but
wrong*, what is half-built, and what is risky. Written to be read before planning work, not
after.

**Last full pass:** 2026-07-27 (Re-Ownership Program, Phase 1).
**Verification standard used here:** a feature is "verified" only if it was exercised —
tests run, or SQL executed against the live database. Reading the code is an *audit*, not a
verification, and is labelled as such below.

---

## 1. Program status

| Phase | Scope | State |
|---|---|---|
| **1 — Live Operations** | Map, tracking health, delay detection, incident lifecycle | ✅ **Complete** (2026-07-27) |
| 2 — Booking & Payment control | Separate booking / payment / trip state; enforce transitions | ⏳ Not started |
| 3 — Trip Operations | Full lifecycle draft → completed, cancellation paths | ⏳ Not started (transition guard exists, see §4) |
| 4 — Fleet | Vehicles, types, seat layouts, availability, double-booking | ⏳ Not started — **2 known test failures**, see §3 |
| 5 — Captains | Onboarding → approval → assignment → suspension | ⏳ Not started |
| 6 — Multi-office | Isolation audit across every module | ⏳ Partial — Live Ops proven (§5); rest audited only |
| 7 — Analytics & Reports | Actionable KPIs over decorative charts | ⏳ Not started |

---

## 2. Completed features

### Live Operations Center — ✅ verified
Full design in `DASHBOARD_LIVE_OPS_CENTER.md`.

- Fleet map over the shared `core/widgets/maps` stack; vehicles coloured by tracking health,
  tap-to-focus, camera stable under polling.
- Tracking health (`live` / `stale` / `offline` / `unknown`) tied to the captain app's real
  30s publish cadence.
- Departure-delay detection with a 10-minute boarding grace; overdue trips lead the list and
  drive a KPI.
- 4-state incident lifecycle with guarded transitions, required resolution notes, and actor +
  timestamp per transition.
- Office-scoped position reads via `dashboard_active_trip_fixes`.

**Verification:** 99 tests (44 unit + 55 widget, incl. a 5-width × 3-text-scale overflow
sweep); `flutter analyze` clean; migration applied to the live database and its office gate
proven by transactional test (own office 1 row, foreign office 0 rows, rollback confirmed).

### Earlier work (carried forward, not re-verified in this pass)
Multi-office migration, platform office management + analytics, trip map (captain), packages
marketplace, support-ticket office routing, dashboard home as a composition root. See the
migration audit at `docs/architecture/MULTI_OFFICE_MIGRATION_AUDIT.md`.

---

## 3. Known bugs

| # | Area | Bug | Severity | State |
|---|---|---|---|---|
| B1 | Fleet | `fleet_vehicle_form_vehicle_type_test.dart` — *"saving a Coaster persists 30 Coaster seats"* fails | Medium | **Open**, pre-existing. Confirmed unrelated to Phase 1 (zero fleet files touched). Phase 4. |
| B2 | Fleet | Same file — *"saving an unchanged Hiace keeps 14 Hiace seats"* fails | Medium | **Open**, pre-existing. Phase 4. |
| B3 | Live Ops | `_HealthDot` built its `AnimationController` lazily, so a non-live badge first touched it in `dispose()` → *"Looking up a deactivated widget's ancestor is unsafe"* on every navigation away | High | ✅ **Fixed** 2026-07-27 |
| B4 | Live Ops | `_MetaRow` overflowed up to 33px at narrow widths / large text scales | Low | ✅ **Fixed** 2026-07-27 |
| B5 | Live Ops | Unbounded `trip_live_locations` query: ~7,200 rows per 15s poll at 20 active trips | High (perf) | ✅ **Fixed** 2026-07-27 (RPC) |

B1/B2 are the reason Phase 4 should not be deferred indefinitely: seat-layout persistence is
the substrate booking correctness sits on.

---

## 4. Partially implemented

| Area | What exists | What is missing |
|---|---|---|
| **Trip lifecycle** | `OperationTripStatus` enum with all 6 states; a transition guard in `trips_repository_impl.dart`; captain app drives `boarding` / `in_progress` | No `draft` concept; cancellation/failure paths not modelled as first-class; capacity/occupancy/assignment consistency across states unaudited. **Phase 3.** |
| **Incident history** | Closed reports now carry `resolution_note`, `resolved_by`, `acknowledged_at`/`_by` | Nothing reads them back. This is audit data with no reporting surface yet. |
| **Fleet map route geometry** | Vehicles plotted | Planned route path not drawn; `trip_route_points` + `RouteGeometryService` make it cheap when wanted. |
| **Captain contact from Live Ops** | Phone number displayed on the trip card | No tel: link or in-app message action. |

---

## 5. Security register

### Verified boundaries

| Boundary | Mechanism | Verified how | Date |
|---|---|---|---|
| Live Ops positions are office-scoped | `dashboard_active_trip_fixes` office check inside a `SECURITY DEFINER` function | Transactional SQL test as a real office user: own 1 / foreign 0, rollback confirmed | 2026-07-27 |
| Incident reads/writes are office-scoped | `driver_trip_reports_office_manage` RLS + mandatory inner join to `operation_trips` | `pg_policies` inspection + `relrowsecurity = true` | 2026-07-27 |
| Incident status values are constrained | `driver_trip_reports_status_check`, `convalidated = true` | SQL inspection after apply | 2026-07-27 |
| Position RPC is not public | `revoke … from public, anon` / `grant … to authenticated` | `proacl` inspection | 2026-07-27 |
| Support agents cannot close incidents | `liveOpsIncidentAction` absent from their permission set | Unit test + widget test (no buttons rendered) | 2026-07-27 |

### Open risks

| # | Risk | Impact | Status |
|---|---|---|---|
| **S1** | **`trip_live_locations` has RLS disabled platform-wide.** Any authenticated user can read every office's live vehicle positions. Empirically confirmed: a direct read returned all 15 rows across both offices. | Cross-office operational intelligence leak; a competitor office's account can watch your fleet. | **Open.** Deliberate historically — the table is kept open so realtime delivery to client maps works. Phase 1 removed the *dashboard's* dependence on it, which is a precondition for closing it. Closing it requires validating the client's realtime tracking path, which belongs to the client workstream. **Do not close it blind.** |
| **S2** | `driver_trip_reports.report_type` has no CHECK constraint | A malformed type falls through to `other`; handled defensively in `IncidentType.fromDb`, so impact is cosmetic | **Accepted.** A constraint risks rejecting a captain-app write if a new type ships first. Revisit if the captain app's type list stabilises. |
| **S3** | Realtime subscription on `driver_trip_reports` carries no filter | Every office's dashboard wakes on every office's incident insert | **Low.** The wake only triggers a re-fetch, which is RLS-scoped, so no data leaks — it is noise, not exposure. The table has no `office_id` column to filter on. |
| **S4** | `watchChanges` unsubscribes its channel but does not remove it from the Supabase client | Minor channel accumulation over a long session | **Open**, cosmetic. |

---

## 6. Technical debt

| # | Item | Cost of leaving it |
|---|---|---|
| D1 | The dashboard deliberately avoids freezed/codegen and hand-writes `fromJson` + sealed states. This is house style, applied consistently. | None today — but it is a convention future contributors must be told about, since `CLAUDE.md` prescribes freezed. Documented here so the divergence is intentional rather than accidental. |
| D2 | `operation_trips.revenue` is dead — never maintained. Correct revenue is the sum of approved bookings. | Any report that reads it silently reports zero. Phase 7 must not use it. |
| D3 | `operation_trips.booked_seats` is likewise unmaintained; seat states in `trip_seats` are the truth. | Same class of bug. Live Ops already counts seats from `trip_seats`. |
| D4 | Two subscription "worlds" (`transport_packages`/`transport_subscriptions` vs `packages`/`subscriptions`) | Phase 2 must map which is authoritative before touching payment state. |
| D5 | Client `features/<x>/di/<x>_di.dart` files are dead code; real DI is inline in `core/di/client_di.dart` | Confusing, but client-side — out of this program's scope. |

---

## 7. UX issues

| # | Area | Issue | State |
|---|---|---|---|
| U1 | Live Ops | Non-live badge crashed on teardown (B3) | ✅ Fixed |
| U2 | Live Ops | Trip card overflowed at 320px / 1.6× (B4) | ✅ Fixed |
| U3 | Live Ops | "Resolve" was a single irreversible click with no ownership signal, so two operators could work the same incident | ✅ Fixed via the acknowledge state |
| U4 | Live Ops | Late trips were invisible — the data existed and nothing read it | ✅ Fixed via delay detection |
| U5 | Dashboard-wide | No systematic width × text-scale overflow sweep exists outside `dashboard_design_system_overflow_test.dart` and now Live Ops | **Open.** The Live Ops sweep is the pattern to copy per module as each phase lands. |

---

## 8. How to verify this document

```bash
# Tests
flutter test test/apps/dashboard/            # expect 414 pass, 2 fail (B1, B2)
flutter test test/apps/dashboard/features/live_ops/   # expect 99 pass

# Analyzer
flutter analyze lib/apps/dashboard/ test/apps/dashboard/   # expect clean

# Database (read-only checks)
supabase db query --linked "select conname, convalidated from pg_constraint
  where conname='driver_trip_reports_status_check';"
supabase db query --linked "select proname, prosecdef, array_to_string(proacl,',')
  from pg_proc where proname='dashboard_active_trip_fixes';"
supabase db query --linked "select relname, relrowsecurity from pg_class
  where relname in ('driver_trip_reports','trip_live_locations');"
```
