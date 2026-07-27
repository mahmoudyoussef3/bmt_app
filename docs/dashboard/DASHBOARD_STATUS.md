# Dashboard Status Register

The honest state of the EWT operations dashboard: what is finished, what is finished *but
wrong*, what is half-built, and what is risky. Written to be read before planning work, not
after.

**Last full pass:** 2026-07-27 (Re-Ownership Program, Phases 1–2).
**Verification standard used here:** a feature is "verified" only if it was exercised —
tests run, or SQL executed against the live database. Reading the code is an *audit*, not a
verification, and is labelled as such below.

---

## 1. Program status

| Phase | Scope | State |
|---|---|---|
| **1 — Live Operations** | Map, tracking health, delay detection, incident lifecycle | ✅ **Complete** (2026-07-27) |
| **2 — Booking & Payment control** | Separate booking / payment / trip state; enforce transitions | ✅ **Complete** (2026-07-27) |
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

### Booking & Payment control — ✅ verified

- **Three state machines, explicitly separated**: booking state, payment state, and the
  trip's operational state, in `booking_lifecycle.dart`. Each has a `canTransitionTo`
  rule set with a stated reason for every edge (a rejected receipt may be replaced;
  approved money is refunded, never un-approved; a boarded passenger is not cancelled).
- **Cross-machine contradiction detection** (`detectBookingIssues`) covering
  paid-but-cancelled, confirmed-without-payment, travelled-without-payment and
  completed-but-refunded — mirrored exactly by the `booking_state_contradictions` SQL view.
- **A next-action resolver** driving the booking inspector, so the panel states *what to do
  and why* instead of showing two status chips the operator must interpret. A contradiction
  outranks routine work, because acting on a booking whose money and seat disagree makes it
  worse.
- **`payment_review_status` drift eliminated** — it is now derived by trigger from
  `payment_status`, so the two columns can no longer disagree regardless of who writes.
- **`cancelled_at` stamped automatically** on the transition into `cancelled`.

**Verification:** 56 tests (40 state-machine + 16 widget, incl. a 4-width × 3-text-scale
overflow sweep); migration applied to the live database, with the trigger, the backfill and
the detection view each proven transactionally (seed → assert → `ROLLBACK`, rollback
confirmed).

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
| B6 | Bookings | `PaymentStatus` enum was missing `cancelled`, which the database CHECK allows. The model resolves the enum by name with a `pending` fallback, so **every cancelled payment rendered as "قيد الانتظار"** — telling operators money was still expected on a booking whose payment had been called off. 2 live rows affected. | High | ✅ **Fixed** 2026-07-27 |
| B7 | Bookings | `payment_review_status` disagreed with `payment_status` on 2 live rows (`approved` vs `pending`, `reviewed_at` null — written outside `approve_payment`) | Medium | ✅ **Fixed** 2026-07-27 (derived by trigger + reconciled) |
| B8 | Bookings | 3 cancelled bookings had `cancelled_at` null — no record of when the seat was released | Low | ✅ **Fixed** 2026-07-27 (trigger + backfill from `updated_at`) |
| B9 | Bookings | `booking_state_contradictions` view inherited a database default grant giving `authenticated` ALL privileges. A single-table view is updatable, so operators could have written `operation_bookings` through it, bypassing the RPC discipline. | Medium | ✅ **Fixed** 2026-07-27 (explicit revoke, `authenticated=r` verified) |

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
| Privileged booking RPCs are unreachable from the client | `approve_payment`, `reject_payment`, `approve_booking`, `reject_booking`, `reassign_booking`, `bulk_update_booking_status`, `request_payment_review` are granted to `postgres`/`service_role` **only** — never `authenticated`. The only reachable path is the `office_*` wrapper, which calls `assert_office_owns_booking` first. | `proacl` inspection of all 11 functions | 2026-07-27 |
| `booking_state_contradictions` is office-scoped | `security_invoker = on`, so the view runs as the caller and `operation_bookings` RLS applies | `reloptions` inspection | 2026-07-27 |
| `booking_state_contradictions` is read-only | Explicit `revoke all … from authenticated` then `grant select` | `relacl` = `authenticated=r` | 2026-07-27 |

### Open risks

| # | Risk | Impact | Status |
|---|---|---|---|
| **S1** | **`trip_live_locations` has RLS disabled platform-wide.** Any authenticated user can read every office's live vehicle positions. Empirically confirmed: a direct read returned all 15 rows across both offices. | Cross-office operational intelligence leak; a competitor office's account can watch your fleet. | **Open.** Deliberate historically — the table is kept open so realtime delivery to client maps works. Phase 1 removed the *dashboard's* dependence on it, which is a precondition for closing it. Closing it requires validating the client's realtime tracking path, which belongs to the client workstream. **Do not close it blind.** |
| **S2** | `driver_trip_reports.report_type` has no CHECK constraint | A malformed type falls through to `other`; handled defensively in `IncidentType.fromDb`, so impact is cosmetic | **Accepted.** A constraint risks rejecting a captain-app write if a new type ships first. Revisit if the captain app's type list stabilises. |
| **S3** | Realtime subscription on `driver_trip_reports` carries no filter | Every office's dashboard wakes on every office's incident insert | **Low.** The wake only triggers a re-fetch, which is RLS-scoped, so no data leaks — it is noise, not exposure. The table has no `office_id` column to filter on. |
| **S4** | `watchChanges` unsubscribes its channel but does not remove it from the Supabase client | Minor channel accumulation over a long session | **Open**, cosmetic. |
| **S5** | `is_admin()` returns true for **any** active `office_users` row, including support agents. Every booking RPC gates on it, so at the database level a support agent can approve payments. | The dashboard's own permission set does grant `paymentVerification` to support agents, so this is currently intentional — but the database has no role distinction to fall back on if that product decision changes. | **Documented, not a defect today.** If payment approval is ever restricted to owners, `is_admin()` is not the function to gate it with; a `current_office_role()` check is needed. |
| **S6** | `bulkApprove` / `bulkReject` loop one RPC per booking with no surrounding transaction | A partial failure leaves half a batch approved with no rollback | **Open.** Low frequency, but a `bulk_office_approve_payment(uuid[])` RPC would make it atomic. Phase 7 candidate. |

---

## 6. Technical debt

| # | Item | Cost of leaving it |
|---|---|---|
| D1 | The dashboard deliberately avoids freezed/codegen and hand-writes `fromJson` + sealed states. This is house style, applied consistently. | None today — but it is a convention future contributors must be told about, since `CLAUDE.md` prescribes freezed. Documented here so the divergence is intentional rather than accidental. |
| D2 | `operation_trips.revenue` is dead — never maintained. Correct revenue is the sum of approved bookings. | Any report that reads it silently reports zero. Phase 7 must not use it. |
| D3 | `operation_trips.booked_seats` is likewise unmaintained; seat states in `trip_seats` are the truth. | Same class of bug. Live Ops already counts seats from `trip_seats`. |
| D4 | Two subscription "worlds" (`transport_packages`/`transport_subscriptions` vs `packages`/`subscriptions`) | Phase 2 must map which is authoritative before touching payment state. |
| D5 | Client `features/<x>/di/<x>_di.dart` files are dead code; real DI is inline in `core/di/client_di.dart` | Confusing, but client-side — out of this program's scope. |
| D6 | **Two vocabularies for one payment concept.** `operation_bookings.payment_status` uses camelCase `underReview`; `booking_payments.status` uses snake_case `under_review`. Every RPC that touches both must remember to switch. | A future writer using the wrong casing silently violates a CHECK or, worse, matches nothing in a `where status in (…)` filter. Not changed here: the columns are read by the client and captain apps too, so renaming is a cross-workstream migration. |
| D7 | `operation_bookings` carries 3 status columns, one of which (`payment_review_status`) is now fully derived. It could be dropped entirely once no reader depends on it. | Dead weight; the trigger keeps it honest in the meantime. |

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

## 8. Remaining program work — exact specification

Phases 3–7 are **not started**. This section records what each one must cover, including the
findings already gathered during the Phases 1–2 audit, so the next session starts from evidence
rather than from scratch.

### Phase 3 — Trip Operations
*Already known:*
- `operation_trips_status_check` allows `scheduled · open_for_booking · boarding · in_progress ·
  completed · cancelled`. There is **no `draft`** state in the database, so the requested
  `Draft → Scheduled → …` lifecycle needs either a migration or a decision that `scheduled` *is*
  draft until opened for booking. Recommend the latter — a seventh state earns its keep only if
  something behaves differently in it.
- A transition guard already exists in `trips_repository_impl.dart:323-328` covering
  `openForBooking → boarding → inProgress → completed`. It has never been audited for the
  cancellation paths.
- The captain app drives `boarding` and `in_progress` (`trip_execution_datasource.dart`), so any
  dashboard-side rule must not contradict `trips_captain_update` RLS.
- **The live database currently holds no `boarding` or `in_progress` trips at all** — statuses
  present are `completed`, `cancelled`, `open_for_booking` across 9 trips. Phase 3 verification
  will therefore need transactionally-seeded fixtures, as Phases 1–2 used.

*Must cover:* cancellation and failure paths as first-class; capacity / occupancy / captain /
vehicle consistency across every state; what happens to bookings when a trip is cancelled.

### Phase 4 — Fleet
*Already known:*
- **B1 and B2 are open failing tests** in `fleet_vehicle_form_vehicle_type_test.dart` covering
  Coaster-30 and Hiace-14 seat persistence. Start here: seat layout is the substrate booking
  correctness sits on.
- `trip_seats_state_check` allows `available · reserved · paid · subscription · blocked`.
- `release_expired_seat_holds` exists as an RPC and **nothing schedules it** (recommendation
  R14), so abandoned checkouts hold seats indefinitely.

*Must cover:* double-booking prevention for both vehicles and captains across overlapping
trips — this is the single most important fleet invariant and has not been verified to exist.

### Phase 5 — Captains
*Already known:*
- Captain onboarding (`captain_requests`), approval, and office assignment exist and were
  built in an earlier program.
- `20260723090000_captain_status_transition_allowlist.sql` exists; per the project memory its
  application status was previously uncertain — **verify it is applied before designing on top
  of it**.
- Incident data now accruing per captain (Phase 1) is the raw material for reliability metrics.

### Phase 6 — Multi-office
*Already verified (see §5):* Live Ops positions, incident reads/writes, the contradictions view,
and the booking RPC grant surface.
*Not yet verified:* every other module's datasource. The audit pattern that worked is: read the
`office_id` filter in the datasource, confirm the matching RLS policy in `pg_policies`, then
prove it with a transactional `set local request.jwt.claims` test as a real office user.
*Known outstanding risk:* **S1**, `trip_live_locations` RLS.

### Phase 7 — Analytics & Reports
*Already known:*
- **Do not read `operation_trips.revenue` or `booked_seats`** (debt D2/D3) — both are
  denormalised and unmaintained. Revenue is the sum of approved bookings; occupancy comes from
  `trip_seats`.
- `booking_state_contradictions` gives a money-integrity KPI for free (recommendation R6).
- Incident data (Phase 1) supports time-to-acknowledge, the best proxy for desk responsiveness.
- Platform office analytics already exist (`20260722140000`) and should be extended, not
  duplicated.

---

## 9. How to verify this document

```bash
# Tests
flutter test test/apps/dashboard/                      # expect 456 pass, 2 fail (B1, B2)
flutter test test/apps/dashboard/features/live_ops/    # expect 99 pass
flutter test test/apps/dashboard/features/bookings/    # expect 56 pass

# Analyzer
flutter analyze lib/apps/dashboard/ test/apps/dashboard/   # expect clean

# Database (read-only checks)
supabase db query --linked "select conname, convalidated from pg_constraint
  where conname='driver_trip_reports_status_check';"
supabase db query --linked "select proname, prosecdef, array_to_string(proacl,',')
  from pg_proc where proname='dashboard_active_trip_fixes';"
supabase db query --linked "select relname, relrowsecurity from pg_class
  where relname in ('driver_trip_reports','trip_live_locations');"

# Phase 2 invariants — all three must return 0
supabase db query --linked "
select 'review_status drift' as check, count(*) from operation_bookings
 where payment_review_status is distinct from case
   when payment_status in ('approved','rejected') then 'reviewed'
   when payment_status='underReview' then 'under_review' else 'pending' end
union all select 'cancelled without timestamp', count(*) from operation_bookings
 where status='cancelled' and cancelled_at is null
union all select 'critical contradictions', count(*)
 from booking_state_contradictions where severity='critical';"
```
