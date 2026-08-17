# Dashboard — Refactor Report

**Date** 2026-08-16 · **Branch** `dashboard-performance` · **Scope** `lib/apps/dashboard/`
(562 files, ~107.6k lines), its tests, and the showcase harness.

**Method** Code read as the source of truth. The existing audit docs
(`DASHBOARD_AUDIT.md`, `DASHBOARD_KNOWN_ISSUES.md`, dated 2026-08-15) were treated as
claims to verify, not as evidence — and two of their claims turned out to be wrong.

**Result** 89 files changed, +1,216 / −2,987 lines. `flutter analyze` clean for the
dashboard. Dashboard suite **1,206 passing / 0 failing**, up from 1,193 / **7**.

---

## 1. What the audit found that the previous pass had missed

### The dashboard test suite was not green

`DASHBOARD_ARCHITECTURE.md` claimed "1,090 assertions passing" and
`DASHBOARD_KNOWN_ISSUES.md` claimed "the dashboard suite on its own is 1,107 passing,
0 failing". Measured on a clean tree: **1,193 passing, 7 failing.** All seven were fixed
in this pass, and two of them were real product defects rather than stale tests:

| Failing test | What it was |
|---|---|
| `dashboard_rtl_test` | **A real RTL violation.** `fleet_documents_screen.dart` forced `TextDirection.ltr` around a close button — a wrapper that did nothing except break the console's own rule. Fixed with `PositionedDirectional`. |
| `business_overview_screen_test` ×3 | Stale: the page is a lazy `ListView` and had grown past the test's declared viewport, so the last section was never built. Tests now scroll to it. |
| `fleet_overview_focus_test` ×3 | Stale: the drivers tab swaps card list ↔ table at 1200px and the test named the card layout's button. Now targets whichever affordance the width renders. |

### A fixed-size dialog that overflowed on a normal laptop

The fleet document preview was `SizedBox(width: 800, height: 800)` inside 24px inset
padding — taller than the viewport on a 1366×768 screen. Now a `ConstrainedBox` bounded
by the window. Shipped one commit before this pass; the RTL test caught the file, reading
it caught this.

### Four layer violations the docs did not mention

Listed in §3.

---

## 2. Performance

The branch's purpose, and the console's weakest dimension. Full detail in
`DASHBOARD_PERFORMANCE.md`.

| # | Defect | Fix |
|---|---|---|
| 1 | **الحجوزات re-read the whole joined booking table on every realtime event.** One bulk approval of 20 → 20 full-table reads; `asyncMap` queued rather than dropped, so a busy day never caught up. | Stream is now a signal. 400ms coalesce + in-flight guard, so re-reads are proportional to activity rather than to row count. |
| 2 | **The notifications bell held an unbounded subscription for the whole session** — `.stream()` with no filter and no limit, pulling the office's entire alert history into memory to count unread. | Server-side `count(exact)` over `is_read = false`, re-run when the already-bounded 100-row feed ticks. Badge stays exact; client holds nothing. |
| 3 | **112 selects, 12 limits, 0 ranges.** Five list modules pulled the office's entire history on every visit and paginated in Dart — and the shell rebuilds a module on every navigation. | Row caps on bookings / trips / subscriptions / reviews / tickets, each with an order, a `capReached` flag and a visible notice. |
| 4 | **Home fired 9 feeds and نظرة تنفيذية 12** — one of them a second query over `operation_bookings` used only for a count already inside the bookings feed. | 8 and 11. The count derives from `bookings`. |

### The cap contract

`DashboardQueryCaps` puts every ceiling in one file. A cap is always three things:
`.limit()` **with** `.order()` (so which rows survive is a decision), a `capReached`
getter, and a `DashboardCapNotice` on screen. Silently truncating a list and then
totalling it is the failure this console refuses everywhere else — every tally on a
capped state is computed over the loaded rows.

**This changes what an operator sees** and was confirmed before implementing: a booking
older than the newest 2,000 no longer appears in الحجوزات until the filters narrow to it.

---

## 3. Architecture

All four layer-violation greps now return **0**. They did not before.

| Violation | Fix |
|---|---|
| `OfficeBillingCubit` held a `SupabaseClient`, called `.rpc()` and parsed JSON through a `fromJson` on the **domain entity** | Built the data layer the feature never had: datasource → repository → `GetOfficeInvoicesUseCase`. `OfficeInvoice` is plain Dart; parsing lives in `OfficeInvoiceModel`. |
| `DashboardAuthCubit` depended on the concrete `DashboardAuthDatasource` — the console's most security-sensitive cubit could not be tested without a live Supabase client | Added `DashboardAuthRepository` + `DashboardAuthFailure` in `domain/`. The datasource implements the interface; DI binds the interface. |
| `WalletScreen` called `data/services/WalletStatementExportService` directly, while Finance routed the identical job through its repository | `WalletRepository.exportStatement` + `ExportWalletStatementUseCase`. The screen calls the cubit. |
| Two fleet presentation files imported `data/models/fleet_models.dart` for one wire-name mapping | `FleetDocumentType.wireName` on the domain enum. Deleted a duplicated 9-branch switch as well as the imports. |

**One deviation was examined and deliberately kept.** `platform_licensing` holds 29
`fromJson` factories on domain entities. Its RPCs return one document per surface, already
shaped as the screen reads it; a parallel model layer would copy fifteen classes
field-for-field to gain a folder, inside the most security-sensitive subsystem in the
console. The codebase already argues this position in `WalletRepositoryImpl`. Recorded in
`DASHBOARD_ARCHITECTURE.md` §2 rather than "fixed".

---

## 4. The module merge

**مراجعة المدفوعات folded into الحجوزات.** 14 files, 2,036 lines, deleted.

The two modules read `operation_bookings` through two datasources, two repositories, two
cubits, two sets of use cases and two DI graphs — and drove the same three RPCs.

- `/payment-verification` now builds `BookingsScreen` with
  `load(presetTab: BookingQueueTab.needsReview)`. Route, permission and top-bar title
  survive, so the Home tile and the نظرة تنفيذية KPI that point at it still work.
- The preset **overrides remembered filters** — an operator asking for the payment queue
  wants that queue, not whatever الحجوزات was last narrowed to.
- **`addNote` came with it.** It was the one thing the old queue could do that الحجوزات
  could not: record "I called the passenger, the receipt is coming" without approving or
  rejecting. Now `AddBookingNoteUseCase` plus a notes box in the booking inspector.
  Dropping it would have left operators making a decision they had not taken just to
  leave a trace.
- **Counting semantics preserved exactly.** `pendingPaymentReviews` derives from
  `bookings` where `paymentStatus == submitted` — matching what the old queue meant by
  "pending". `underReview` is still excluded, because that booking is waiting on the
  passenger, not on the office.

---

## 5. Files

**Created (11)**

```
core/query/dashboard_query_caps.dart
core/widgets/dashboard_cap_notice.dart
features/auth/domain/entities/dashboard_auth_failure.dart
features/auth/domain/repositories/dashboard_auth_repository.dart
features/bookings/domain/usecases/add_booking_note_usecase.dart
features/office_billing/data/datasources/supabase_office_billing_datasource.dart
features/office_billing/data/models/office_invoice_model.dart
features/office_billing/data/repositories/office_billing_repository_impl.dart
features/office_billing/domain/repositories/office_billing_repository.dart
features/office_billing/domain/usecases/get_office_invoices_usecase.dart
test/apps/dashboard/core/dashboard_query_caps_test.dart
```

**Deleted (18)** — the 14 `payment_verification` files, its 3 test files, and
`core/widgets/dashboard_table_frame.dart` (62 lines, referenced by nothing in `lib/`,
`test/` or `tool/`).

**Duplication removed**

- `_CapNotice` (private, finance) → shared `DashboardCapNotice`, now used by six modules.
- `documentTypeToDbString` (data) → `FleetDocumentType.wireName` (domain); one switch
  instead of one switch plus two cross-layer imports.
- `_ListSection` in the booking inspector, superseded by the notes section that replaced
  it.
- An entire duplicate data layer over `operation_bookings`.

---

## 6. Verification

```
flutter analyze     5 issues — all pre-existing unused imports in the captain app.
                    Zero in lib/apps/dashboard, test/apps/dashboard or tool/.

flutter test        2,335 passing · 11 failing
                    Dashboard: 1,206 passing · 0 failing  (was 1,193 · 7)
                    The 11 failures are the documented pre-existing set, all in the
                    captain and client apps:
                      captain_profile_layout_test              ×3
                      trip_history_layout_test                 ×4
                      trip_history_detail_layout_test          ×3
                      client/support_ticket_details_test       ×1
```

Tests added: 7 for the cap contract (flag boundaries, notice copy, 1.6×-scale narrow
window, finance alias) and 4 for the merged queue (preset opens the review tab, preset
ignores remembered filters, remembered filters still restore without a preset, note
trimming and empty-note refusal).

Checked explicitly: no permission bypass (route gate test green, `_items` still complete),
no cross-office leak (no query scoping changed, no office id introduced client-side), no
licensing bypass (`feature` keys preserved on every nav item), no finance calculation
touched, no RLS or migration changed.

---

## 7. What needs a business or product decision

1. **Cap values.** 2,000 bookings / 1,500 trips / 1,500 subscriptions / 1,500 reviews /
   1,000 tickets. Chosen from row weight and expected daily volume, not from measurement
   against a real office's data. If any office is already past one, the notice will
   appear — that is the signal to either raise the number or build §2 below.

2. **Server-side paging.** The real fix, and a migration. Needs
   `office_<x>_page(filters, limit, offset)` **and** `office_<x>_tallies(filters)` per
   module, because the counters and KPIs are computed over the full loaded set today and
   paging without moving them would replace a truthful window with a lying one.

3. **The fleet workspace feed runs 23 selects** and الرئيسية calls it on every load. It
   wants one `office_fleet_workspace` RPC returning one document.

4. **`addNote` writes the `notes` column directly** — a read-modify-write with a
   lost-update race if two operators note the same booking in the same second. Carried
   over verbatim from مراجعة المدفوعات; folding a queue was not the moment to change what
   it does. Fix is an `office_add_booking_note` RPC that appends in one statement.

5. **Retire الإعدادات.** Offered and declined this pass. It holds a theme toggle already
   in the top bar, a paragraph saying permissions live elsewhere, and a sign-out already
   in the sidebar footer.

6. **Still open from the 2026-08-15 audit**, untouched here: fleet RLS still lets a
   support agent read driver PII *columns* (writes are closed); `referral_analytics` is
   granted to every authenticated user; the driver/vehicle/complaint report views have no
   date dimension; there is no customer entity.
