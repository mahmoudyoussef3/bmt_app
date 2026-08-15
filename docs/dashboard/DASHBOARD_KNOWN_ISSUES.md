# Dashboard — Known Issues

Open as of **2026-08-15**, after the audit pass. Issues fixed in that pass are recorded in
`DASHBOARD_AUDIT.md` §"What was fixed" and are not repeated here.

> A second, **UX-only** pass ran the same day — see `DASHBOARD_UX_AUDIT.md` (findings and
> fixes) and `DASHBOARD_UX_ROADMAP.md` (what to do next). It fixed the trip-wizard
> text-scale overflow listed at the bottom of this file, and rebuilt مركز الشكاوى والدعم
> (Arabic labels, reachable filters, paginated/sortable queue, real empty states). Issues
> #8, #9, #10 and #13 below were re-confirmed by that pass and remain open.

---

## P0 — can cause loss, breach or corruption

### 1. Fleet RLS does not distinguish owner from support agent

**Where** `drivers`, `vehicles`, `assignments`, fleet document tables.

`for all to authenticated using (office_id = public.current_office_id())` — office-scoped
but role-agnostic, unlike wallet, office and logo-storage policies which do use
`office_role()`.

**Impact** `drivers` holds phone numbers, national IDs and licence data that the permission
model says a support agent must never see. The client-side gate is currently the only
thing enforcing that.

**Status** The client hole is closed and tested (`dashboard_shell_route_gate_test.dart`).
The server-side gap is open. A recommended migration is written out in
`DASHBOARD_SECURITY.md` §3; it was **not applied**, because it changes production RLS on
four tables read by the trip planner, live ops, the report views and the captain app, and
that needs a deliberate verification pass rather than being folded into an audit.

---

## P1 — major workflow, correctness or scale problem

### 2. Almost every list query is unbounded

**Where** Most `supabase_*_datasource.dart` files: 14 `.limit()` calls across ~110 selects.
`fetchBookings()`, `fetchTrips()`, the fleet workspace (23 selects), tickets, subscriptions
and reviews all pull the office's entire history.

**Impact** compounds badly:

- الرئيسية fires **9** uncapped queries on every visit.
- نظرة تنفيذية fires **12** on every visit.
- The shell disposes and rebuilds each module on every navigation, so returning to Home
  re-runs all nine.

An office with 50k bookings pulls 50k rows several times per session. Finance already has
a row cap and surfaces `ledgerCapReached`; that is the pattern the rest should follow.

**Fix** Server-side aggregates for the two composition screens (a `dashboard_home_summary`
RPC), and paging + caps on the module lists.

### 3. Payment Verification duplicates Bookings

**Where** `features/payment_verification/` (2.0k lines) vs `features/bookings/` (5.8k).

Both read `operation_bookings`, both call `office_approve_payment` /
`office_reject_payment` / reupload. Two datasources, two repositories, two cubits, two
sets of use cases, two DI graphs, one job.

الحجوزات is the richer surface (filters, bulk actions, reassignment); مراجعة المدفوعات is a
narrower queue over `payment_status in (submitted, underReview, approved, rejected)`.

**Fix** Fold it into الحجوزات as a saved queue preset, and keep `/payment-verification` as
a deep link that opens that preset. Not done in this pass because it is a genuine refactor
with its own test surface, not a cleanup.

### 4. Reports cannot date-bound driver, vehicle or complaint data

`drivers_performance_view`, `vehicles_efficiency_view` and `complaints_summary_view` are
lifetime roll-ups with no date column. "This driver's trips last month" is a reasonable
question the schema cannot answer.

The UI now states this rather than showing an inert date picker, but the underlying gap is
a migration, not a Dart change.

### 5. Driver rating, working hours, fuel consumption and complaint resolution time do not exist

Four KPIs were being read out of those views by column name. The columns have never
existed; the values arrived null, parsed to 0, and printed as `0 ساعة`, `0.0 ★`,
`0.0 لتر/100كم` and `0.0 ساعة` next to real figures.

They have been removed rather than faked. Restoring any of them means teaching the view to
compute it.

---

## P2 — important improvement

### 6. Platform admins see cross-office totals inside an office's screens

`is_platform_admin()` is an OR branch in all four report views. An EWT staff member who
also operates an office sees platform-wide numbers in that office's Finance and Reports.
Fix: an explicit scope selector rather than an implicit OR.

### 7. `referral_analytics` is readable by every authenticated user

A definer view over `referrals`, granted to `authenticated`, whose own migration comment
says "platform admins only". Any signed-in user — including a Client-app passenger — can
read platform-wide referral totals. Aggregate metrics, no PII. Fix: add
`where public.is_platform_admin()` to the view body.

### 8. الرئيسية and نظرة تنفيذية overlap substantially

Home's four KPIs are a strict subset of نظرة تنفيذية's eleven. Home's lower half (revenue
trend, top routes, standing capacity, activity feed) is executive material sitting on the
operator's console. The split should be sharpened: Home = *what must I do*, نظرة تنفيذية =
*how are we doing*.

### 9. الإعدادات has nothing of its own

A theme toggle (also in the top bar), a paragraph explaining that permissions are
configured elsewhere, and sign-out (also in the sidebar footer). Fold what is real into
ملف المكتب and drop the row.

### 10. Two partial-data notices

`BusinessOverview`'s `UnavailableSourcesNotice` and the new shared
`DashboardPartialDataNotice` do the same job. The former should migrate to the latter; it
was left alone because it maps a feature-local enum to labels and changing it means
touching a module this pass did not otherwise need to.

### 11. الشكاوى writes columns directly

The only module that updates its table without an RPC. RLS-gated and low-risk today, but
inconsistent with every other write path in the console.

### 12. No test coverage for several shipped modules

No tests exist for: referrals, tickets, office billing, notifications dispatch, settings,
or the reports **screen** (the cubit is covered).

---

## P3 — polish

### 13. Filters do not survive navigation

Every module rebuilds from scratch when the shell switches route, so an operator who
filters الحجوزات, checks a trip and comes back starts over. Fold state persists via
`DashboardSectionStateStore`; filter state does not.

### 14. `revenue_daily_view` has no subscription revenue

The revenue report's "إيرادات الاشتراكات" line is structurally zero because the view only
aggregates `operation_bookings`. Honest today (it reads 0), but the column invites the
reader to think subscriptions earned nothing.

### 15. Five unused imports in the captain app

Pre-existing analyzer warnings, out of scope for a dashboard pass, listed so nobody
mistakes them for new.

---

## Pre-existing test failures (not caused by, and not fixed by, this pass)

Measured after the UX pass (`flutter test`, whole repo):

| Test | Failure |
|---|---|
| ~~`dashboard/features/trips/trip_creation_driver_vehicle_test.dart`~~ | ~~Overflow at 1.3× and 1.6× text scale (×2)~~ — **fixed** in the UX pass |
| `captain/captain_profile_layout_test.dart` | Overflow at small/medium/large (×3) |
| `captain/features/trip_history/trip_history_layout_test.dart` | Overflow and copy assertions (×4) |
| `captain/features/trip_history/trip_history_detail_layout_test.dart` | Overflow and copy assertions (×3) |
| `client/support_ticket_details_test.dart` | Overflow on a loaded ticket (×1) |

Full suite was **2,221 passing / 13 failing** at the end of the correctness audit and is
**2,236 passing / 11 failing** after the UX pass: the two dashboard overflows are fixed and
13 tickets tests were added. The remaining **11 failures are all in the captain and client
apps**, all pre-existing, and untouched by dashboard work. (The earlier note split the seven
captain trip-history failures as "×5"; the per-file counts above are measured.)

The dashboard suite on its own is **1,107 passing, 0 failing**.
