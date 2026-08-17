# Dashboard — Modules

23 feature modules, 562 files, ~107.6k lines. Measured 2026-08-16.

---

## The map

| Module | Files | Lines | Layers | Route | Owner-only |
|---|---:|---:|---|---|---|
| `fleet` | 68 | 15,298 | full ×4 sub-features | `/fleet` (+3 drill-ins) | yes (writes) |
| `platform_licensing` | 24 | 12,559 | full | `/platform-*` | platform admin |
| `trips` | 39 | 9,976 | full ×5 sub-features | `/trips` | yes |
| `routes` | 34 | 6,876 | full | `/routes` | yes |
| `wallet` | 26 | 6,786 | full | `/wallet` | mixed |
| `bookings` | 34 | 6,019 | full | `/bookings`, `/payment-verification` | no |
| `subscriptions` | 43 | 5,955 | full + `plans/` | `/subscriptions` | yes |
| `platform_admin` | 20 | 5,747 | full | `/platform-offices` | platform admin |
| `finance` | 25 | 4,557 | full | `/payments` | yes |
| `business_overview` | 19 | 4,007 | domain + presentation | `/business-overview` | yes |
| `live_ops` | 22 | 3,315 | full | `/live-ops` | no |
| `reports` | 22 | 2,947 | full | `/reports` | yes |
| `tickets` | 19 | 2,524 | full | `/tickets` | no |
| `dashboard_home` | 13 | 2,198 | domain + presentation | `/` | no |
| `referrals` | 21 | 2,187 | full | `/referrals` | platform admin |
| `users` | 17 | 1,913 | full | `/users`, `/permissions` | yes |
| `office_profile` | 12 | 1,653 | full | `/office-profile` | yes |
| `notifications` | 24 | 1,273 | full | `/notifications` | no |
| `reviews` | 15 | 1,020 | full | `/reviews` | yes |
| `auth` | 6 | 909 | data + domain + presentation | (gate) | — |
| `captain_requests` | 12 | 873 | full | `/captain-requests` | yes |
| `office_billing` | 8 | 555 | full | `/office-billing` | yes |
| `settings` | 1 | 144 | presentation only | `/settings` | no |

"full" = `data/` + `domain/` + `presentation/`.

---

## The two shapes that are not "full", and why

**`dashboard_home` and `business_overview` have no `data/`.** They are composition roots:
they own no datasource and call the use cases the feature modules already register. A
number on الرئيسية matches the module it came from because it *came from* that module's
query, not from a second hand-rolled one. See `DASHBOARD_ARCHITECTURE.md` §6.

**`settings` is presentation only.** It holds a theme toggle (also in the top bar) and a
paragraph explaining that permissions are configured elsewhere. It has nothing to fetch
because it has nothing of its own — which is why `DASHBOARD_KNOWN_ISSUES.md` recommends
retiring it.

---

## Modules with sub-features

### `fleet/` — four workspaces over one dataset

```
fleet/
├── data/         one datasource (23 selects) + models, shared by all four
├── domain/       fleet_usecases.dart
├── shared/       entities, widgets, upload helpers used by every tab
├── overview/     the tab host (presentation only)
├── fleet_drivers/       full three layers
├── fleet_vehicles/      full three layers
├── fleet_assignments/   full three layers
└── fleet_documents/     full three layers
```

The largest module in the console, and the one with the heaviest single feed:
`GetFleetWorkspaceUseCase` runs 23 selects, and الرئيسية calls it on every load.

### `trips/` — five concerns, one planner

`trip_creation` (the wizard), `trip_management` (the list and details), `trip_passengers`,
`trip_pricing`, `trip_seats`, `trip_events`, plus `shared/` and `trips_di.dart`.

`trip_creation_wizard.dart` is the largest single file in the console at 1,884 lines.

### `subscriptions/plans/`

The plan catalog an office sells, separate from the subscriptions it has sold.

---

## What changed on 2026-08-16

### مراجعة المدفوعات was folded into الحجوزات

`payment_verification` (14 files, 2,036 lines) is **gone**. It read `operation_bookings`
through its own datasource, repository, cubit and use cases, and drove the same three
RPCs الحجوزات already drove — `office_approve_payment`, `office_reject_payment`,
`office_request_payment_review`.

What the fold did:

- `/payment-verification` now builds `BookingsScreen` with
  `load(presetTab: BookingQueueTab.needsReview)`. The route survives, the permission and
  top-bar title survive, and the Home tile and نظرة تنفيذية KPI that point at it still
  work.
- The preset **overrides remembered filters**: an operator who asked for the payment queue
  is asking for that queue, not for whatever الحجوزات was last narrowed to.
- **`addNote` came with it.** It was the one thing the old queue could do that الحجوزات
  could not — record "I called the passenger, the receipt is coming" without approving or
  rejecting. It is now `AddBookingNoteUseCase` and a notes box in the booking inspector.
  Dropping it would have left operators making a decision they had not taken just to leave
  a trace.
- **الرئيسية and نظرة تنفيذية each lost a feed.** Both fetched the verification queue and
  used it only to count bookings awaiting a decision — a number already inside the
  bookings feed they also fetched. `pendingPaymentReviews` is now derived from `bookings`.
  Semantics are unchanged: only `submitted` counts, because a booking sent back for
  re-upload is waiting on the *passenger*, which is the line the separate queue also drew.

### `office_billing` gained the data layer it never had

Its cubit held a `SupabaseClient` and its domain entity parsed JSON. It now has
`SupabaseOfficeBillingDatasource` → `OfficeBillingRepositoryImpl` →
`GetOfficeInvoicesUseCase`, and `OfficeInvoice` is plain Dart with the parsing in
`OfficeInvoiceModel`.

### `auth` gained a domain layer

`DashboardAuthRepository` (interface) + `DashboardAuthFailure` (entity). The datasource
implements the interface; the cubit depends on it. The console's most security-sensitive
cubit is now testable without a Supabase client.

### One dead file removed

`core/widgets/dashboard_table_frame.dart` — 62 lines, referenced by nothing in `lib/`,
`test/` or `tool/`.

---

## Module count over time

| Pass | Change |
|---|---|
| 2026-08-15 audit | −1 (`owner_overview` deleted, unreachable), +1 reachable (`referrals`) |
| 2026-08-16 | −1 (`payment_verification` folded into `bookings`) |

Recommended next, not done: retire `settings` (nothing of its own), and build the
customer directory that does not exist — see `DASHBOARD_KNOWN_ISSUES.md`.
