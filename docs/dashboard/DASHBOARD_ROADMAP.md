# Dashboard — Roadmap

Ordered by what it costs an office to be without it, not by what is interesting to build.
Every item states the business reason; anything that could not be argued for is not here.

---

## Phase 1 — Critical (close the holes)

### 1.1 Role-gate fleet writes server-side
Owner-only writes on `drivers`, `vehicles`, `assignments`, fleet documents, mirroring
`wallet_policies`. Migration drafted in `DASHBOARD_SECURITY.md` §3. Needs a verification
pass across the trip planner, live ops, the report views and the captain app before it is
applied.
**Why:** the only thing keeping a support agent out of driver national IDs and licence
numbers is currently a client-side check.

### 1.2 Cap the composition screens
A `dashboard_home_summary` RPC returning the counts Home needs, instead of nine full-table
pulls; the same for نظرة تنفيذية.
**Why:** the console's landing page currently gets slower every day the office operates,
and it is the screen everyone opens first.

### 1.3 Page and cap the module lists
Bookings, trips, tickets, subscriptions, reviews. Finance's `ledgerCapReached` is the
pattern — cap, and *say* the window may be incomplete.

### 1.4 Scope the report views explicitly
Replace the implicit `or is_platform_admin()` with a scope the caller chooses, so an EWT
staff member operating an office sees their office's numbers in their office's screens.

---

## Phase 2 — Core UX (make the day cheaper)

### 2.1 Fold مراجعة المدفوعات into الحجوزات
As a saved queue preset, keeping `/payment-verification` as a deep link.
**Why:** two modules, two data layers and two test surfaces for one job; and an operator
currently answers "is this receipt approved?" in whichever of the two they happened to
open.

### 2.2 Sharpen الرئيسية vs نظرة تنفيذية
Home keeps the KPI row, the attention panel, today's departures and the newest bookings —
*what must I do*. The revenue trend, top routes, standing capacity and activity feed move
to نظرة تنفيذية, which is where an owner already goes for *how are we doing*.

### 2.3 Persist filter state across navigation
Extend `DashboardSectionStateStore` to hold module filters for the session.
**Why:** every trip an operator inspects from the bookings queue costs them their filters.

### 2.4 Retire الإعدادات
Move anything real into ملف المكتب and drop the sidebar row.

### 2.5 A "today" default everywhere
Trips, bookings and live ops should open on today, not on everything. Most sessions are
about today.

---

## Phase 3 — Business features (what an office cannot do at all)

### 3.1 Customer directory and profile — *highest business value*
A searchable list of customers, and a profile that puts bookings, payments, refunds,
wallet ledger, tickets and reviews on **one timeline**.
**Why:** answering a single "I paid twice" phone call currently means four searches across
five modules with no shared identity. The data is all present and already office-scoped;
only the assembly is missing. See `DASHBOARD_CUSTOMERS.md`.

### 3.2 Trip schedule templates
Define a recurring departure once; generate the week.
**Why:** an office running six fixed departures a day currently creates them one at a
time, every day, forever. This is the single largest repetitive cost in the console.

### 3.3 No-show and cancellation handling
Surface no-shows from seat state, report cancellations in aggregate, and let an operator
act on both.
**Why:** these are the two events that cost an office money on a trip that otherwise ran
fine, and neither is visible today.

### 3.4 Driver availability
Shifts, leave and rest periods, so the planner stops offering drivers who are not working.

### 3.5 Contact log
Record that a customer was called, by whom, about what. Tickets already carry
`customer_contacted_at`; generalise it.

---

## Phase 4 — Analytics and intelligence

### 4.1 Date-bound the driver, vehicle and complaint views
Add a date dimension so "last month" becomes answerable, and restore the report filters
that are currently declared unsupported.

### 4.2 Route performance over time
Occupancy, revenue and cancellation rate per corridor, month over month.
**Why:** the decision this supports — which routes to keep, retime or drop — is the most
consequential one an owner makes, and nothing in the console informs it.

### 4.3 Real driver and vehicle performance
Teach the views to compute working hours, rating and utilisation, then put the four
removed KPIs back — with real numbers behind them this time.

### 4.4 Period comparison on the financial statement
This period vs last, on the statement itself. Only once there is a comparison period —
never a fabricated arrow.

### 4.5 Scheduled reports
Weekly summary generated and delivered without anyone opening the console.

---

## Phase 5 — Polish

- Consolidate the two partial-data notices onto `DashboardPartialDataNotice`.
- Move الشكاوى writes onto RPCs, matching every other module.
- Add `where public.is_platform_admin()` to `referral_analytics`.
- Tests for referrals, tickets, office billing, notifications dispatch and the reports
  screen.
- Fix the pre-existing text-scale overflows in the trip creation card and the captain
  profile/history screens.
- Subscription revenue in `revenue_daily_view`, or drop the structurally-zero column from
  the revenue report.
- Keyboard shortcuts for the queue actions an operator performs dozens of times a day.

---

## Explicitly not planned

Recorded so they do not get re-proposed:

- **A third role.** The two-role model is deliberate and matches `office_role()`. New
  capabilities belong as per-action permissions inside a role (the pattern
  `liveOpsIncidentAction` and `walletAdjustments` already set), not as new roles.
- **Self-service plan changes.** A checkout without a payment gateway would be a lie.
  Contact-to-upgrade stays until there is a real billing engine.
- **Auto-expiring stale trips.** Past-dated open trips are *flagged* for the operator, by
  the owner's explicit decision. No expiry cron.
- **Re-introducing captain chat.** Removed by the owner's call in August 2026. Ops reaches
  captains through the notifications bell.
- **A second price input on a trip.** One fare, expanded. Packages are flat multiples.
- **Any second permission system.** Three predicates, ANDed, already exist.
