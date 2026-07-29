# Operations Dashboard — Feature Reference

The operations dashboard (`lib/apps/dashboard/`) is the office-facing control centre of
the BMT platform. It is an **Arabic-only, RTL, web/desktop workspace** used by transport
office staff to run daily operations: routes, trips, bookings, fleet, money and support.

This document describes what each module *does*, what it talks to, and what it cannot do.
For the operator's step-by-step journeys, see [DASHBOARD_USER_FLOWS.md](DASHBOARD_USER_FLOWS.md).

> **Accuracy note.** This reference was written against the code as of 2026-07-23 and
> reflects what the modules actually do. It replaces `dashboard_analysis_report.md`,
> which had drifted badly out of date.

---

## 1. Foundations

### 1.1 Entry point and session

```
lib/apps/dashboard/main.dart
  → AppFlavorConfig.activate(AppFlavor.dashboard)
  → Supabase.initialize(...)            // Dio-backed HTTP adapter
  → registerDashboardDependencies()     // get_it: dashboardDi
  → runApp(DashboardWebApp)
      → DashboardThemeCubit (light/dark, persisted)
      → MaterialApp(locale: 'ar', builder: Directionality.rtl)
          → _DashboardAuthGate
              ├─ checking   → spinner
              ├─ signed in  → DashboardShell(office: …)
              ├─ registering→ DashboardSignUpScreen
              └─ signed out → DashboardLoginScreen
```

**RTL is applied once**, in `MaterialApp.builder`, so it also covers dialogs, menus,
tooltips and snack bars. Individual screens must not re-declare `Directionality`.

### 1.2 Office context — the tenancy boundary

Every signed-in operator resolves exactly one `OfficeContext` from the
`current_office_context` RPC, held for the session:

| Field | Meaning |
|---|---|
| `officeId` | The tenant. Every office-scoped query reads it from here — never from a route, a form, or a fetched row. |
| `officeName`, `officeSlug`, `logoUrl` | Identity shown in the sidebar header. |
| `role` | `admin` (المالك) or `supportAgent` (خدمة العملاء). |
| `username`, `fullName` | Who is signed in. |
| `listingStatus` | Marketplace visibility: `draft` / `listed` / `unlisted`. Independent of operational status. |
| `isPlatformAdmin` | Whether this operator also administers the EWT platform itself. |

Because `officeId` is never client-supplied, there is no value an operator can tamper
with to reach another office. The database enforces the same boundary independently via
RLS, and every platform-level RPC re-checks `is_platform_admin()` server-side — so a
forged `isPlatformAdmin: true` reaches a screen whose every action is refused.

### 1.3 Roles and permissions

Two roles only (`DashboardRole`), defined in `core/permissions/`:

| Role | DB value | Label |
|---|---|---|
| `admin` | `dashboard_admin` | المالك |
| `supportAgent` | `support_agent` | خدمة العملاء |

`DashboardPermissions.permissionsFor(role)`:

- **admin** — every permission.
- **supportAgent** — `bookings`, `tickets`, `reports`, `paymentVerification`, `notifications`.

Everything else (trips, routes, fleet, captain requests, finance, subscriptions,
referrals, owner overview, **reviews**, office profile, platform offices, users &
permissions, settings) is owner-only. Reviews are deliberately owner-only: aggregate
driver/vehicle ratings are public, but individual passenger comments are not.

`platformOffices` carries an extra gate: being in the owner's permission set is
necessary but **not sufficient** — the module is additionally hidden unless
`OfficeContext.isPlatformAdmin`, because it is the one module that reaches outside the
signed-in office.

> In debug builds the sidebar shows a role switcher. It changes `_role` for UI
> exploration only; the server still scopes every request to the authenticated identity.

### 1.4 Shell and navigation

`DashboardShell` owns all page chrome: the sidebar, the top bar (title, notifications
bell with unread badge, light/dark toggle, role chip), and the RTL context. Below 920px
it collapses the sidebar into a drawer with a hamburger button.

Module screens render **content only** — no `Scaffold`, no `AppBar`, no `Directionality`.

Sidebar groups:

| Group | Modules |
|---|---|
| *(top level)* | الرئيسية |
| **التشغيل** | الحجوزات · الرحلات · المسارات |
| **الأسطول** | إدارة الأسطول · طلبات الكباتن |
| **المالية** | المالية · الاشتراكات · برنامج الإحالات · التقارير · نظرة المالك |
| **الدعم** | الشكاوى · التقييمات |
| **النظام** | الإشعارات · ملف المكتب · مكاتب المنصة · المستخدمون والصلاحيات · الإعدادات |

The shell creates each module's cubit with `..load()` already applied. **Screens must not
call `load()` again in `initState`** — doing so fires a second full fetch on every visit.

### 1.5 Shared design system

One visual language across every module (`core/widgets/`):

| Widget | Use |
|---|---|
| `DashboardModuleHeader` | Page banner: icon, title, subtitle, actions, optional `child` for a KPI/filter strip. |
| `DashboardKpiCard` + `DashboardKpiGrid` | Stat tiles, responsive 4 / 2 / 1 columns. |
| `DashboardPanel` | Titled content section (charts, detail blocks). |
| `DashboardTableFrame`, `OpsDataTable` | Tabular data with a consistent shell and pagination. |
| `MasterDetailLayout` | List → detail split above the tablet breakpoint. |
| `DashboardLoading` / `DashboardErrorState` / `EmptyState` | The three non-happy states. Error states always offer retry. |
| `DebouncedSearchField` | All search inputs (300 ms debounce + clear button). |
| `DashboardChartPalette` | The only source of chart colours. |

Tokens: radii from `AppTokens` (`radiusSmall` 10 / `radius` 14 / `radiusLarge` 18 /
`radiusSheet` 28; `circular(999)` only for intentional pills), spacing from `AppSpacing`,
status colours from `AppStatusColors`, Cairo typography from `DashboardAppTheme`.

### 1.6 Error convention

- A failed **load** → error state with a retry button (there is nothing to show).
- A failed **action** → keep the loaded state, surface a transient message
  (`actionError` / `actionMessage`) as a snack bar.

Dropping an operator to a blank error screen because one approval was rejected would
discard their filters, their selection and the row they were working on. Repositories
also preserve the underlying cause (`seat_taken`, `cross_office_reassignment_denied`, …)
rather than replacing it with a generic message.

---

## 2. Module reference

### 2.1 الرئيسية — Command centre
`features/dashboard_home/` · permission: none (always visible)

The operator's landing page and triage queue. Aggregates six live feeds into one screen:

| Section | Contents |
|---|---|
| Action items | Prioritised work queue (`urgent` / `high` / `normal`), each linking to the module that resolves it. |
| Today's trips | Route, driver, vehicle, departure, capacity vs booked seats, status. |
| Payment reviews | Receipts awaiting a decision, with customer, trip, method and amount. |
| Open complaints | Ticket, customer, type, owner, last update. |
| Subscriptions | Subscription items needing review. |
| Alerts | Operational warnings. |

Every card is a deep link — `onOpenModule` switches the shell route. This is the **only**
route into Payment Verification (see §3 Known gaps).

### 2.1b العمليات المباشرة — Live Operations Center
`features/live_ops/` · permissions: `liveOps` (view) + `liveOpsIncidentAction` (act)

The "what is happening on the road right now" board. Full design in
`DASHBOARD_LIVE_OPS_CENTER.md`.

| Section | Contents |
|---|---|
| Summary bar | On-road count · overdue departures · tracking at risk · open incidents (with an unclaimed count) |
| Fleet map | Every active trip that has reported a position, coloured by tracking health; tap to focus |
| Trips on the road | Route, crew, occupancy, tracking health, last-report age, departure delay. Overdue trips lead |
| Incident queue | Captain reports, worst-first, claimable and closable in place |

**Actors.** Owner: full. Support agent: **read-only** — they see the board (they need it while
a passenger is on the phone) but cannot close a captain's report, because that writes a
permanent audit trail. Platform admin: per-office, via the office context they are in.

**Business rules.**
- Tracking health is derived from fix age against the captain app's real 30s publish cadence:
  ≤75s live · ≤4min stale · older offline · never-reported unknown.
- A trip is *overdue* only while boarding, and only past a 10-minute grace. A trip already
  running is *late* (reported), never overdue (alarmed).
- Incidents move `pending → acknowledged → resolved/dismissed`. Nothing reopens. Closing
  requires a note.
- A trip with no position is never drawn at a guessed location; it stays in the list and is
  counted in the map legend.

**Edge cases.** No active trips → calm empty state, not an error. Dropped socket → last good
snapshot retained. Two operators on one incident → the second is refused with an explanation.

### 2.2 الحجوزات — Bookings
`features/bookings/` · permission: `bookings` · **owner + support agent**

The payment-review queue and booking inspector. Backed by `operation_bookings`, enriched
with the trip, route, driver, vehicle and package each booking references, and kept live
by a realtime subscription.

**Lifecycle** — `BookingStatus`: `draft` → `reserved` → `confirmed` → `boarded` → `completed`, or `cancelled`.
**Payment** — `PaymentStatus`: `pending` → `submitted` → `underReview` → `approved` / `rejected` / `refunded` / `failed`.

Actions (all via audited SECURITY DEFINER RPCs — the dashboard never writes status
columns directly):

| Action | RPC |
|---|---|
| Approve payment | `office_approve_payment` |
| Reject payment | `office_reject_payment` |
| Request receipt re-upload | `office_request_payment_review` |
| Move booking to another trip | `office_reassign_booking` |
| Bulk approve / bulk reject | the same single-booking RPCs, applied per row |

Also provides: status tabs, filters (search, route, date, payment method), multi-select
with a bulk action bar, an analytics strip, and a details panel showing customer, trip,
payment, receipt, notes and a full timeline. Reassignment is offered only while the
booking is `draft`/`reserved`/`confirmed` — once boarded or completed there is no seat
left to release.

### 2.3 الرحلات — Trips
`features/trips/` · permission: `trips` · **owner only**

Scheduling and live operation of trips. Split into focused sub-cubits: list, details,
creation, seats, pricing, passengers.

**Lifecycle** — `OperationTripStatus`: `scheduled` → `openForBooking` → `boarding` →
`inProgress` → `completed`, or `cancelled` from any non-terminal state.

The state machine lives in the **database** (`public.update_trip_status`) and is the only
way a status can change: since migration `20260727160000` a direct table write raises
`trip_status_direct_update_forbidden`, for operators and captains alike.
`TripLifecycle` (`shared/domain/entities/trip_lifecycle.dart`) mirrors it so the dashboard
offers the right actions — it never decides whether one is allowed. Full design and
state-transition matrix: [`TRIP_LIFECYCLE_DESIGN.md`](../architecture/TRIP_LIFECYCLE_DESIGN.md).

**Seats** — `TripSeatState`: `available` / `reserved` / `paid` / `subscription` / `blocked`.

- **Three view modes**: `list` (driven by a quick-filter chip), `grouped` (upcoming /
  active / completed sections), `timeline`.
- **Filters**: search plus advanced filters on status, route, driver, vehicle, occupancy
  and date.
- **Creation wizard**: picks route, driver, vehicle, date/time, capacity and fare, then
  calls `office_create_trip` with the **driver only** — the vehicle, the capacity and the
  seat map are derived server-side from that driver's active assignment. The trip code is
  generated **server-side**
  (`next_office_trip_code`) — client-side codes collided across offices.
- **Publishing** (`scheduled → openForBooking`) passes a five-point readiness gate:
  driver, vehicle, seat inventory, at least one active `trip_pricing` row, and a
  departure date that has not passed. The button carries the blocking reason, so an
  unready trip reads as an instruction rather than a failure. Enforced server-side by
  `trip_publish_blocker`.
- **Cancelling** is available on any non-terminal trip and always captures a reason; the
  server *requires* one once boarding has started. The dialog states what will happen —
  how many riders are cancelled, how many seats released, and that paid bookings will
  need a manual refund. Calls `office_cancel_trip`.
- **Details workspace tabs**: overview, passengers, seats, pricing, payments, history.
- **Live sync**: realtime subscription plus a periodic refresh; a failed background
  refresh preserves the last good trip rather than showing an error.
- **Analytics**: status mix, occupancy distribution, busiest routes.

Passenger operations: edit, cancel a booking, relocate to another seat.

**Deleting** a trip is only possible while it is `scheduled` and carries no bookings.
Anything else must be cancelled — deleting it would leave paid bookings pointing at no
trip at all (`operation_bookings.trip_id` is `ON DELETE SET NULL`) with no refund trail
and no word to the rider. The menu item is disabled with that reason in place.

**Stale trips** are flagged (فات موعدها) for the operator rather than auto-closed — a
deliberate business choice, not an oversight. A flagged trip is closed one of two honest
ways via `office_close_stale_trip`: **نُفّذت بالفعل**, which walks the real machine to
`completed` server-side with rider notifications suppressed (replaying "انطلقت رحلتك" for
a week-old departure tells the rider nothing true), or **لم تُنفَّذ**, which cancels it
normally so riders *are* told.

### 2.4 المسارات — Routes
`features/routes/` · permission: `routes` · **owner only**

Defines the transit network: routes and their ordered stations.

**Lifecycle** — `OperationRouteStatus`: `draft` / `active` / `paused` / `archived`.

Route operations: create, update, duplicate, pause, archive, delete.
Station operations: add, update, delete, **reorder** (drag to re-sequence).

Includes a geo route form for plotting the path, a route timeline view, an analytics
strip, and filters on status, city and stop count. Tables: `operation_routes`,
`route_stations`.

### 2.5 إدارة الأسطول — Fleet
`features/fleet/` · permission: `fleet` · **owner only**

One workspace with four tabs over a shared `FleetWorkspace` (drivers, vehicles,
assignments, documents loaded together), plus KPI tiles and readiness charts.

| Tab | Contents |
|---|---|
| **السائقون** | Driver records, operational readiness, per-driver documents. |
| **المركبات** | Vehicle records, licences, per-vehicle documents. |
| **التعيينات** | Driver ↔ vehicle assignments. |
| **الوثائق** | Fleet-wide document expiry tracking. |

**Statuses** — driver: `active` / `suspended` / `archived`. Vehicle: `active` /
`maintenance` / `suspended` / `archived`. Assignment: `active` / `ended`.
Document: `valid` / `expiringSoon` / `expired`.

Actions: create/edit driver and vehicle, change status, bulk archive drivers, bulk
suspend vehicles, delete, upload and delete document files, assign, reassign, end and
delete assignments. A driver's `canAssign` readiness is computed from status, documents
and existing active assignments.

Tables: `drivers`, `vehicles`, `assignments`, `driver_documents`, `vehicle_documents`.

### 2.6 طلبات الكباتن — Captain requests
`features/captain_requests/` · permission: `captainRequests` · **owner only**

Inbox for drivers who self-registered through the Captain app.

**Lifecycle** — `CaptainRequestStatus`: `pending` → `approved` / `rejected`.

Approving runs a flow that creates the driver record and attaches any documents supplied
with the request. Rejecting requires a written reason. Filter toggles between
"قيد المراجعة" and "الكل"; the list is kept live by a subscription.

### 2.7 المالية — Finance
`features/finance/` · permission: `payments` · **owner only**

The money workspace, in five sections:

| Section | Purpose |
|---|---|
| **المدفوعات** | All payments; filter by method and status. |
| **طلبات المراجعة** | Receipt review queue with an image viewer (zoom + rotate). |
| **المرتجعات** | Refund requests. |
| **الاشتراكات** | Subscription records and cancellation. |
| **الإيرادات** | Revenue breakdowns derived from the loaded payments. |

**Statuses** — payment: `success` / `pending` / `cancelled` / `refunded`.
Receipt: `pending` / `accepted` / `rejected` / `reuploadRequested`.
Refund: `pending` / `approved` / `rejected`.

Actions: review a receipt (accept / reject / request re-upload), process a refund,
cancel a subscription. Tables/views include `refund_requests` and `revenue_daily_view`.

### 2.8 التحقق من الدفع — Payment verification
`features/payment_verification/` · permission: `paymentVerification` · **owner + support agent**

A focused, single-purpose queue for verifying booking payment receipts — narrower and
faster to work than the Finance receipts section.

**Lifecycle** — `BookingVerificationStatus`: `pending` → `approved` / `rejected` / `reviewRequested`.

Actions: approve, reject, request review, add an internal note. Filters: all / pending /
review requested / approved / rejected, plus search across customer, phone, booking
number, route and payment reference. Includes a receipt viewer with zoom.

> Reachable **only** from Home action items — it has no sidebar entry. See §3.

### 2.9 الاشتراكات — Subscriptions
`features/subscriptions/` · permission: `subscriptions` · **owner only**

Passenger subscription management, plus a plans catalogue.

**Types** — `oneTime`, `fiveDays`, `tenDaysMonthly`, `monthly`, `threeMonths`.
**Status** — `pendingPayment` → `active` → `expired` / `cancelled`.
**Plan status** — `active` / `paused` / `archived`.

Subscription actions: create manually, confirm payment
(`office_confirm_subscription_payment`), renew (`office_request_subscription_renewal`),
consume a ride (`office_consume_subscription_ride`), cancel. Expiry is swept by
`office_expire_overdue_subscriptions`.

Plans sub-module: create, update, set status, delete.

> **Two subscription worlds exist in the schema.** `transport_packages` /
> `transport_subscriptions` drive the booking flow, while `packages` / `subscriptions`
> back this tab. Payment approval mirrors into `subscriptions`.

### 2.10 برنامج الإحالات — Referrals
`features/referrals/` · permission: `referrals` · **owner only**

Referral programme administration, in five tabs: نظرة عامة, إعدادات المكافآت,
المتصدّرون, سجل الإحالات, حركات المكافآت.

**Lifecycle** — `ReferralStatus`: `pendingRegistration` → `registered` →
`firstOrderCompleted` → `rewardGranted`.

The only write is `saveConfig` (reward rules). Everything else is read-only reporting.
Tables: `referrals`, `referral_codes`, `referral_rewards`, `referral_reward_transactions`,
`referral_analytics`, `referral_leaderboard`.

### 2.11 التقارير — Reports
`features/reports/` · permission: `reports` · **owner + support agent**

Seven report types: الرحلات, الحجوزات, الإيرادات, السائقين, المركبات, الاشتراكات, الشكاوى.

Each offers KPIs, charts and a data table, with date-range and dimension filters.

**Exports are real**, not stubs: `ReportExportService` generates CSV (UTF-8 BOM so Arabic
opens correctly in Excel), XLSX via `excel`, and PDF via `pdf` + `printing`.

### 2.12 نظرة المالك — Owner overview
`features/owner_overview/` · permission: `ownerOverview` · **owner only**

Executive summary: subscription revenue, booking revenue (total / today / month), client
counts by state (active / expired / cancelled), active subscriptions, renewals, a revenue
trend series and a per-plan breakdown. Read-only.

### 2.13 الشكاوى — Support tickets
`features/tickets/` · permission: `tickets` · **owner + support agent**

The customer support desk over `support_tickets` and `support_attachments`.

**Lifecycle** — `TicketStatus`: `submitted` → `underReview` → `contacted` → `resolved` → `closed`, or `rejected`.
**Priority** — `low` / `medium` / `high` / `urgent`.

Actions: assign an agent, change status, save an internal note, mark the customer
contacted, close the ticket. KPI tiles cover new, under review, resolved, and **delayed**
(unresolved for more than 24 hours). Filters: status, priority, debounced search.

### 2.14 التقييمات — Reviews
`features/reviews/` · permission: `reviews` · **owner only**

Passenger trip reviews from `trip_reviews`, kept live by a subscription. Filters: all /
needs attention / with comments, plus search. Read-only.

Owner-only by design: aggregate driver and vehicle ratings are public across the
platform, but individual reviews, their written comments and the route rating are not.

### 2.15 الإشعارات — Notifications centre
`features/notifications/` · permission: `notifications` · **owner + support agent**

Two tabs:

- **الوارد** — operational alerts raised by database triggers whenever something needs
  attention. `OperationalAlertType`: `paymentReview`, `captainRequest`, `supportTicket`,
  `refundRequest`, `tripCancelled`, `general`; priority `low` → `urgent`. Alerts can be
  filtered by type, marked read individually or all at once, and deep-link into the
  module that resolves them. The unread count drives the top-bar bell badge.
- **إرسال إشعار** — compose and broadcast a notification to the Client app, the Captain
  app, or both, under a category (booking, payment, trip, announcement, promotion,
  emergency, subscription, system, general).

### 2.16 ملف المكتب — Office profile
`features/office_profile/` · permission: `officeProfile` · **owner only**

The office's own marketplace record: identity, logo, contact and description. Editing is
gated on the *signed-in* role being `admin` — not the debug-switchable `_role` — because
only that is what the `offices_operator_update` RLS policy will honour.

### 2.17 مكاتب المنصة — Platform offices
`features/platform_admin/` · permission: `platformOffices` **+ `isPlatformAdmin`**

EWT platform administration, spanning **all** offices. The only module that reaches
outside the signed-in office.

Capabilities: list and filter offices (query, status, listing status, activity level,
sort), open a details panel, view cross-office analytics over a configurable window,
onboard a new office (`register_office`), set listing status
(`platform_set_office_listing`), set operational status (`platform_set_office_status`),
and broadcast platform-wide notifications (`platform_broadcast_notification`).

Every RPC re-checks `is_platform_admin()` server-side.

### 2.18 المستخدمون والصلاحيات — Users & permissions
`features/users/` · permission: `permissions` · **owner only**

Dashboard account administration for the office: list users (via `get_dashboard_users`),
change a user's role, remove access. Search by email, user id or role; filter by role.

This screen *is* the access-control surface — there is no separate permissions matrix
page. (One previously existed as a hardcoded placeholder and was removed.)

### 2.19 الإعدادات — Settings
`features/settings/` · permission: `settings` · **owner only**

Deliberately small: light/dark theme selection (persisted), a note that operational
permissions are managed elsewhere, and sign-out with confirmation.

---

## 3. Known gaps and deliberate choices

**Gaps**

| Gap | Detail |
|---|---|
| Payment Verification has no sidebar entry | Reachable only from Home action items. A support agent who clears Home cannot navigate back to the queue. |
| Trips and Subscriptions lists are not virtualised | Rows are built eagerly inside a page-level `ListView`. Fine at current volumes; needs `CustomScrollView` + `SliverList.builder` as those lists grow. |
| `buildWhen` is not used on the module `BlocBuilder`s | They switch on sealed states where it buys little, but the playbook asks for it. |
| Two subscription schemas coexist | `transport_*` vs `packages`/`subscriptions` — see §2.9. |
| Two vocabularies for one payment concept | `operation_bookings.payment_status` uses `underReview`; `booking_payments.status` uses `under_review`. Cross-app rename, not done. |
| Bulk payment approval is not atomic | One RPC per booking, no surrounding transaction — a partial failure leaves half a batch approved. |
| Incident history is written but not readable | Closed reports carry notes and actors; no screen reads them back. |
| Denormalised trip columns are unmaintained | `operation_trips.revenue` and `booked_seats` are never updated — compute from approved bookings and `trip_seats` instead. |

**Deliberate choices — do not "fix" these**

- Stale (past-dated, still-open) trips are **flagged, not auto-closed**. There is no
  expiry cron, by the owner's decision.
- The dashboard is **Arabic-only**; the locale is pinned rather than read from storage.
- Reviews and Owner Overview are **owner-only** even though support agents handle
  complaints.
- The debug role switcher changes UI visibility only; server-side scoping is unaffected.
- **Incident closure is owner-only** even though support agents have the Live Ops module.
  Seeing the situation and deciding it is handled are different authorities.
- **`payment_review_status` is derived, not authored.** A trigger recomputes it from
  `payment_status` on every write. Do not set it by hand; do not "fix" a writer that ignores it.
- Booking contradictions are **detected, not prohibited**. `cancelled` + `approved` must stay
  representable so a refund can be processed through it.

---

## 4. Where things live

```
lib/apps/dashboard/
├── main.dart                    # bootstrap + auth gate + MaterialApp
├── core/
│   ├── di/dashboard_di.dart     # get_it registrations (dashboardDi)
│   ├── permissions/             # DashboardRole, DashboardPermission(s)
│   ├── routes/                  # DashboardRoutes, DashboardShell
│   ├── session/                 # OfficeContext, DashboardSession
│   ├── theme/                   # DashboardAppTheme (Cairo), theme cubit
│   └── widgets/                 # the shared design system (§1.5) + charts/
└── features/<feature>/
    ├── data/        # datasources (Supabase), models, repositories
    ├── domain/      # entities, repository interfaces, use cases
    └── presentation/# cubit + state, screens, widgets
```

Tests live in `test/apps/dashboard/`, including
`core/dashboard_design_system_overflow_test.dart`, which renders the shared widgets at
360 / 720 / 1024 / 1440 px and fails on any layout overflow.
