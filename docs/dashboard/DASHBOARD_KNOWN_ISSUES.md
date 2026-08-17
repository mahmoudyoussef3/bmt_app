# Dashboard — Known Issues

Open as of **2026-08-16**, after the architecture/performance pass. Issues fixed in that
pass are recorded in `DASHBOARD_REFACTOR_REPORT.md` and are not repeated here; issues
fixed in the 2026-08-15 pass are in `DASHBOARD_AUDIT.md`.

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

### 2. List queries are capped, not paged *(PARTIALLY RESOLVED 2026-08-16)*

The five heaviest lists — bookings, trips, subscriptions, reviews, tickets — now carry a
row ceiling from `DashboardQueryCaps`, an explicit `.order()`, a `capReached` flag and a
visible `DashboardCapNotice`. الرئيسية is down to 8 feeds and نظرة تنفيذية to 11.

**What is still open** is paging, and it is a migration rather than a Dart change. The
counters and KPIs on these screens (`countByStatus`, `countForTab`, `approvedRevenue`,
`availableRoutes`) are computed over the full loaded set, so paging the query without
moving those tallies server-side would replace a truthful window with a lying one. Needs
per module:

```
office_<x>_page(p_filters jsonb, p_limit int, p_offset int)
office_<x>_tallies(p_filters jsonb)
```

Also still open: **`GetFleetWorkspaceUseCase` runs 23 selects** and الرئيسية calls it on
every load. One `office_fleet_workspace` RPC returning one document would replace it.

### 3. `addNote` writes a column directly, with a lost-update race

**Where** `SupabaseBookingsDatasource.addNote`.

A read-modify-write on the `notes` array: two operators noting the same booking within the
same second lose one of the notes. Carried over verbatim from مراجعة المدفوعات when that
queue was folded into الحجوزات on 2026-08-16 — folding it was not the moment to change what
it does.

**Fix** An `office_add_booking_note` RPC that appends in one statement. That also brings
the write back under the module's own stated rule, which is that state changes go through
audited definer RPCs.

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

RLS-gated and low-risk today, but inconsistent with every other write path in the console.
One of two such writes — see §3 for the other.

### 12. No test coverage for several shipped modules

No tests exist for: referrals, office billing, notifications dispatch, settings, or the
reports **screen** (the cubit is covered). Tickets gained coverage in the UX pass.

`office_billing` gained a real data layer on 2026-08-16 and is now testable without a
Supabase client — as is `auth`, whose cubit had no tests at all because it depended on a
concrete datasource. Both are the cheapest coverage left to add.

---

## P3 — polish

### 13. Filters do not survive navigation, except where a module opts in

Every module is rebuilt from scratch when the shell switches route.
`DashboardFilterMemory` papers over it for الحجوزات and الشكاوى; every other module still
starts over.

The underlying cause is that the shell disposes each module on navigation. With the row
caps in place the refetch is now bounded, and refetching *is* arguably right for an ops
console — so the remaining work is to extend the memory to the other filtered modules
rather than to keep modules alive.

### 14. `revenue_daily_view` has no subscription revenue

The revenue report's "إيرادات الاشتراكات" line is structurally zero because the view only
aggregates `operation_bookings`. Honest today (it reads 0), but the column invites the
reader to think subscriptions earned nothing.

### 15. Five unused imports in the captain app

Pre-existing analyzer warnings, out of scope for a dashboard pass, listed so nobody
mistakes them for new.

---

## Pre-existing test failures

Measured 2026-08-16 (`flutter test`, whole repo). **All are in the captain and client
apps; the dashboard suite is green.**

> The earlier claim that the dashboard suite was "1,107 passing, 0 failing" was wrong. It
> was 1,193 passing / **7 failing** on a clean tree. All seven were fixed on 2026-08-16 —
> one was a real RTL violation, six were tests that had drifted from the UI. See
> `DASHBOARD_REFACTOR_REPORT.md` §1.

| Test | Failure |
|---|---|
| `captain/captain_profile_layout_test.dart` | Overflow at small/medium/large (×3) |
| `captain/features/trip_history/trip_history_layout_test.dart` | Overflow and copy assertions (×4) |
| `captain/features/trip_history/trip_history_detail_layout_test.dart` | Overflow and copy assertions (×3) |
| `client/support_ticket_details_test.dart` | Overflow on a loaded ticket (×1) |

Full suite is **2,335 passing / 11 failing**. The 11 are all pre-existing and all outside
the dashboard.

The dashboard suite on its own is **1,206 passing, 0 failing**.
