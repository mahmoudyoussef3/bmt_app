# EWT Dashboard — Audit

> **Superseded in part.** A follow-up architecture and performance pass ran on
> 2026-08-16 — see `DASHBOARD_REFACTOR_REPORT.md`. It closed P1-3 (unbounded queries),
> folded مراجعة المدفوعات into الحجوزات, removed the four layer violations this pass did
> not look for, and fixed seven dashboard test failures this pass reported as zero.
> The scores below are from 2026-08-15 and have not been re-run.

**Date:** 2026-08-15 · **Scope:** `lib/apps/dashboard/` (575 files, ~108k lines), the
Supabase migrations behind it, and the dashboard test suite.
**Method:** code, schema and migrations read as the source of truth. Existing docs and the
existing UI were treated as claims to verify, not as evidence.

---

## Executive summary

### What is good

The dashboard is **substantially better engineered than most products at this stage**. The
recently-rebuilt modules — licensing, wallet, live ops, bookings, business overview, home,
routes — are genuinely well designed: consistent Clean Architecture, a real shared design
system, and doc comments that explain *why* a decision was taken rather than restating the
code.

Three things stand out:

1. **The security model is layered and mostly right.** RLS on ~40 tables, state changes
   through audited `SECURITY DEFINER` RPCs, office identity resolved server-side and
   never trusted from the client, `DashboardSession.officeId` throwing rather than
   defaulting when read while signed out.
2. **The licensing system is unusually mature.** Three ANDed predicates that stay separate
   so the console can always say *which one* refused you; a five-rung resolution ladder
   whose winning rung is reported as `source`; trigger-based enforcement rather than UI
   convention; and a deliberate fail-open on the client because the object is a hint and
   the server is the boundary.
3. **There is a real honesty discipline.** Multiple modules refuse to fabricate a trend or
   a metric they cannot compute, and say so on screen. That is rare and worth protecting.

### What is weak

**Maturity is very unevenly distributed.** The console has two generations of code in it.
The recent modules are excellent; the older ones (reports, referrals, settings, the
now-removed owner overview) were shipped and then left behind — and nobody noticed, because
several of them had become unreachable.

The specific weaknesses:

- **The navigation table was also the permission gate, and it was incomplete.** Five routes
  the shell could render were missing from it, and the lookup resolved a miss to the home
  item — which permits everyone.
- **Reports was largely non-functional** and had no sidebar entry, so the failure was
  invisible.
- **Scale has not been designed for.** Almost every list query is unbounded, and the two
  landing screens fire nine and twelve of them respectively on every visit.
- **There is no customer.** A passenger exists as five disconnected event lists.

### What is dangerous

One thing, and it is a genuine P0: **fleet RLS does not distinguish owner from support
agent**, while `office_role()` is used correctly on wallet, offices and logo storage. That
made the client-side gate the only thing keeping a support agent out of driver national
IDs and licence data — and that gate had a hole in it, reachable from a tile on the home
screen every role sees.

The client hole is now closed and tested. The server gap was closed in a follow-up pass —
`20260815110000_fleet_role_authority`, with its own verification against every reader and a
37-probe regression suite. **Writes** to the fleet are now owner-only. **Reads** are still
open to both office roles, deliberately: four support-agent surfaces embed driver and
vehicle rows, and hiding the rows would have silently zeroed two Home KPIs instead of
hiding anything. Withholding the PII *columns* is the remaining work — see
`DASHBOARD_SECURITY.md` §3.1.

### What should change first

1. ~~Apply the fleet RLS role gate~~ *(done)* — then the sanitised driver view that closes
   the read half.
2. Cap the composition screens — the landing page gets slower every day the office trades.
3. Fold مراجعة المدفوعات into الحجوزات.
4. Build a customer directory.

---

## Current dashboard score

Scored 1–10. The bar is *"a professional production transportation management console"*,
not *"better than nothing"*.

| Dimension | Score | Why |
|---|---:|---|
| **Business completeness** | 7 | Every core operational loop is present and works: routes → fleet → trips → bookings → money → reports. Missing: customers as an entity, schedule templates, no-show/cancellation handling. |
| **UX** | 7 | Strong, consistent design system; folding sections with session memory; sensible responsive behaviour. Held back by Home/نظرة تنفيذية overlap, filters that reset on navigation, and a Settings screen with nothing in it. |
| **UI** | 8 | Genuinely good. One table, one header, one panel, one master/detail. Careful RTL — including the discipline of naming LTR-semantic icons and letting the framework mirror them. Light and dark both covered by tests. |
| **Operations** | 7 | Live ops is excellent: honest tracking health, a real incident workflow with an `acknowledged` state that makes a shared desk work. Trips and bookings are strong. Missing: station-level progress, no-shows, delay propagation. |
| **Finance** | 8 | Clearly reasoned. Read-only by design; refunds not double-counted; excluded amounts shown as memo lines; wallet liability kept distinct from revenue. Missing a cost side and any cash reconciliation — and "net revenue" must never be called profit. |
| **Security** | 6 | Would be 8 without the fleet gap. Everything else is layered properly: RLS, triggers, definer RPCs, no client-supplied office id. The gap was that one table family was left out of the role split that the rest of the schema applies. *Since scored: the write half is closed (`20260815110000`); the read half — support agents can still see driver PII columns — is not, so the score stands until the sanitised view lands.* |
| **Performance** | 4 | The weakest dimension. ~14 `.limit()` calls across ~110 selects; Home fires 9 uncapped queries, نظرة تنفيذية 12; the shell rebuilds every module on every navigation. Fine at today's volume, degrades linearly. |
| **Maintainability** | 8 | Clean layering, one DI graph, consistent state shape, 77 test files. Cost: some very large files, and a DI file at 1,600 lines. |
| **Reporting** | 5 | Was 3 before this pass — three of seven reports were literal stubs and the filter bar was decorative. Now all seven return real data and the filters are honest. Still limited by views with no date dimension. |
| **Customer management** | 3 | There is no customer module. Five surfaces hold customer *events*; none holds a customer. This is the largest business gap in the console. |
| **Overall** | **6.6** | A strong operational console with one security gap, one scale liability, and one missing entity. |

---

## Critical findings

### P0-1 · The route gate failed open *(FIXED)*

`_canOpenRoute` resolved an unregistered route to `_items.first` — the home item, which
carries no permission and no feature and therefore permits every role. Five routes the
shell renders were unregistered: `/drivers`, `/vehicles`, `/assignments`,
`/payment-verification`, `/users`.

Exploitable without any tampering: the Home fleet panel renders three tiles for every
role. «إدارة الأسطول» was correctly refused for a support agent; «السائقون» and «المركبات»
right beside it were not, and led to the full fleet module — driver phone numbers, national
IDs and licence data.

The same fallback also mistitled every unregistered route: Reports, Payment Verification,
Drivers and Vehicles all rendered under the top-bar title "الرئيسية".

### P0-2 · Fleet RLS is role-agnostic *(WRITES FIXED — reads still open)*

Applied 2026-08-15 as `20260815110000_fleet_role_authority`. The five `for all` policies on
`drivers`, `vehicles`, `assignments`, `driver_documents` and `vehicle_documents` became one
read policy carrying the original predicate verbatim plus three write policies gated on
`office_role() = 'dashboard_admin'`. Reads were deliberately left open to both office roles
— four support-agent surfaces embed driver and vehicle rows, and restricting rows would
have silently zeroed two Home KPIs rather than hiding anything.

Covered by `supabase/tests/fleet_role_authority_regression.sql`: 37 probes across seven
identities, all green, and 7 of them fail against the pre-migration schema.

**Still open:** a support agent can read driver PII columns. That needs a sanitised definer
view and four datasource rewrites — see `DASHBOARD_SECURITY.md` §3.1.

### P1-1 · Reports produced fabricated and stub data *(FIXED)*

Four separate defects in one module, all invisible because the module had no sidebar entry:

- **Three of seven report types were stubs.** `trips`, `bookings` and `subscriptions`
  returned a single KPI reading `"قيد التطوير الفعلي"` — and `trips` was the **default**,
  so the first thing anyone saw of the reports module was a placeholder.
- **Four KPIs read columns that have never existed.** `total_working_hours` and `rating`
  from `drivers_performance_view`, `fuel_consumption` from `vehicles_efficiency_view`,
  `avg_resolution_time` from `complaints_summary_view`. All arrived null, parsed to 0, and
  printed as `0 ساعة`, `0.0 ★`, `0.0 لتر/100كم`, `0.0 ساعة` beside real figures.
- **The entire filter bar was decorative.** Route, driver, vehicle and package dropdowns
  were bound to state and read by nothing. The date range reached only the revenue report;
  drivers, vehicles and complaints ignored it entirely because their views have no date
  column.
- **CSV export corrupted Arabic.** `Uint8List.fromList([...bom, ...csv.codeUnits])` — a
  UTF-8 BOM followed by truncated UTF-16 code units. Every Arabic name in an exported
  report was mojibake. Finance and Wallet always did this correctly; Reports did not.

### P1-2 · One failed feed blanked the console's landing page *(FIXED)*

`DashboardHomeCubit` ran nine feeds through a single `Future.wait`. Any one rejection —
one licensing refusal, one dropped connection — produced a full-screen error on the page
every role opens first, for a business that was otherwise running normally.
`BusinessOverviewCubit` had already solved this; Home had not been brought along.

### P1-3 · Every list query is unbounded *(OPEN)*

See `DASHBOARD_KNOWN_ISSUES.md` §2.

---

## Redundant features

| What | Verdict |
|---|---|
| **نظرة المالك على الإيرادات** (`/owner-overview`, 525 lines) | **Removed.** No nav item, no inbound link from any screen — unreachable since the نظرة تنفيذية rebuild. Its figures were a strict subset of نظرة تنفيذية + المركز المالي, its datasource applied no office filter of its own, and its own footer admitted it could not compute the metrics it was named for. |
| **مراجعة المدفوعات** vs **الحجوزات** | **Merged 2026-08-16.** 14 files deleted; `/payment-verification` opens الحجوزات on the review preset, and `addNote` came across as `AddBookingNoteUseCase`. |
| **الإعدادات** | **Retire.** A theme toggle already in the top bar, a paragraph saying permissions live elsewhere, and a sign-out already in the sidebar footer. |
| **`/users` and `/permissions`** | Two routes, one screen. Kept as an alias; both now registered and gated. |
| **Home KPIs vs نظرة تنفيذية KPIs** | Home's four are a strict subset of the other's eleven. Sharpen the split rather than delete either. |
| **Two partial-data notices** | Consolidate onto the shared one. |
| **برنامج الإحالة** | **Not redundant — it was orphaned.** 2,187 lines, fully built, zero inbound references. Now reachable, under المنصة. |

---

## Missing features

Ranked by business cost. Argued in `DASHBOARD_ROADMAP.md`.

1. **A customer.** Five modules hold customer events; nothing holds a customer. One "I paid
   twice" call costs four searches across five modules.
2. **Trip schedule templates.** Six fixed daily departures are created one at a time,
   forever.
3. **No-show and cancellation handling.** The two events that cost money on a trip that
   otherwise ran fine, and neither is visible.
4. **Route performance over time.** The decision it supports — keep, retime or drop a
   corridor — is the most consequential an owner makes, and nothing informs it.
5. **Driver availability.** The planner will offer a driver who is not working.
6. **Cash reconciliation.** Finance knows what was collected digitally; it cannot say what
   is in the drawer.
7. **A cost side.** No fuel, salaries, maintenance or platform fees, so there is no profit
   figure anywhere — and "net revenue" must never be presented as one.

---

## UX problems

1. **Reports was not in the sidebar.** A whole analytical module reachable only by clicking
   one card inside نظرة تنفيذية. *(Fixed — it is now a top-level destination.)*
2. **The top bar lied about where you were.** Four modules rendered under the title
   "الرئيسية". *(Fixed.)*
3. **Changing a report filter tore the page down.** `switchReportType` and `updateFilter`
   emitted a full-screen loading state, destroying the selector, the filter bar and the
   toolbar; a failure then emitted a full-screen error that discarded the operator's
   filters. *(Fixed — refetch happens over the page, failures are notices.)*
4. **Failed exports were silent.** `catch { emit(actionLoading: false) }`. An operator
   could click PDF four times and never learn the office is not licensed to export.
   *(Fixed.)*
5. **Filters reset on every navigation.** Inspecting a trip from the bookings queue costs
   the operator their filters. *(Open.)*
6. **Two landing pages that overlap.** *(Open — sharpen the split.)*

---

## Technical problems

1. **`_items` is three things at once** — sidebar source, permission gate and title table —
   and nothing enforced that it stayed complete. Now it fails closed and a test holds it.
2. **Two composition cubits fetch nearly the same nine to twelve feeds** and neither is
   capped or cached.
3. **`dashboard_di.dart` is ~1,600 lines** of hand-written registrations. Feature-local DI
   files exist (`trips_di`, `live_ops_di`, `wallet_di`); the rest should follow.
4. **`DashboardHomeCubit` fetched an office profile nothing read.** One entire query per
   Home load, feeding a field with zero usages. *(Fixed — removed.)*
5. **The showcase harness did not compile.** `DashboardRoutes.platformPlans` was removed in
   the platform console consolidation and the harness still named it — three analyzer
   errors, and the only no-auth visual QA path in the project was dead. *(Fixed.)*
6. **الشكاوى writes columns directly** while every other module uses RPCs.
7. **Six shipped modules have no tests.**

---

## Recommended information architecture

Close to what shipped, with the corrections this pass made and the two merges it
recommends:

```
الرئيسية                     ← what must I do right now
نظرة تنفيذية                 ← how is the business doing            (owner)
التقارير                     ← show me the numbers, filtered and exportable

التشغيل
  العمليات المباشرة
  الرحلات                                                          (owner)
  المسارات                                                          (owner)
المبيعات
  الحجوزات        ← absorbs مراجعة المدفوعات as a queue preset
  الاشتراكات                                                        (owner)
  العملاء          ← NEW: the directory + profile that does not exist
الأسطول
  إدارة الأسطول    ← tabs: السائقون · المركبات · التعيينات · الوثائق   (owner)
  طلبات الكباتن                                                      (owner)
المالية
  المركز المالي                                                     (owner)
  محفظة العملاء
الدعم
  الشكاوى
  التقييمات                                                         (owner)
النظام
  الإشعارات
  ملف المكتب      ← absorbs what little الإعدادات holds              (owner)
  الباقة والفوترة                                                    (owner)
  المستخدمون والصلاحيات                                              (owner)
المنصة                                              (platform admins only)
  مكاتب المنصة · الباقات والميزات · التراخيص · الفوترة والسجل · برنامج الإحالة
```

Net change from what was there before this audit: **−2 modules** (owner overview removed,
settings folded), **+1 reachable** (referrals, correctly placed), **+1 promoted** (reports
into the sidebar), **+1 to build** (customers), **−1 to merge** (payment verification).

---

## What was fixed in this pass

| # | Fix | Files |
|---|---|---|
| 1 | Route gate fails closed; all renderable routes registered with correct permissions; top bar names every route | `dashboard_shell.dart`, `dashboard_routes.dart` |
| 2 | Reports: three stub report types implemented against real tables | `supabase_reports_datasource.dart` |
| 3 | Reports: four phantom-column KPIs removed; vehicle report reports real occupancy instead of non-existent fuel data | `report_entities.dart`, `report_data_table.dart`, `report_export_service.dart` |
| 4 | Reports: filters now reach the query, and each report only offers filters it can honour | `report_entities.dart`, `report_filters_bar.dart`, datasource |
| 5 | Reports: CSV export emits real UTF-8 — Arabic no longer corrupted | `report_export_service.dart` |
| 6 | Reports: refetch happens over the page; failures are notices, not screen replacements | `reports_cubit.dart`, `reports_state.dart`, `reports_screen.dart`, `report_workspace.dart` |
| 7 | Reports: opens on a working report instead of a stub | `reports_cubit.dart` |
| 8 | Home tolerates per-feed failure and names what is missing | `dashboard_home_cubit.dart`, `dashboard_home_summary.dart`, `dashboard_home_screen.dart` |
| 9 | Shared `DashboardPartialDataNotice` | `dashboard_state_views.dart` |
| 10 | Dead office-profile fetch removed from Home | `dashboard_home_cubit.dart`, `dashboard_di.dart` |
| 11 | Owner Overview module deleted (9 files) with its route, permission, icons and DI | across `core/` |
| 12 | Referrals made reachable, under المنصة, platform-only | `dashboard_shell.dart` |
| 13 | Showcase harness compiles again | `dashboard_showcase.dart` |
| 14 | Regression tests: route gate (5) and reports behaviour (3) | 2 test files |

**Deliberately not changed**, with reasons:

- ~~**The fleet RLS migration.**~~ Applied in a follow-up pass as
  `20260815110000_fleet_role_authority`, with its own verification and regression suite.
  The read-side PII split remains deferred (`DASHBOARD_SECURITY.md` §3.1).
- ~~**The payment-verification merge.**~~ Done 2026-08-16.
- **`referral_analytics`'s grant.** A one-line view change, but it is client-facing and
  belongs in its own migration with its own test.
- ~~**The uncapped queries.**~~ Capped 2026-08-16 (`DashboardQueryCaps` + a visible
  notice). Paging still needs new RPCs and a paging contract per module.
- **`BusinessOverview`'s own partial-data notice.** Migrating it means touching a module
  this pass had no other reason to change.
- **The five captain-app unused imports and the pre-existing layout test failures.** Out of
  scope for a dashboard audit.

---

## Verification

```
flutter analyze     5 issues — all pre-existing unused imports in the captain app.
                    The 3 pre-existing ERRORS in tool/showcase are fixed.

flutter test        2,221 passing · 13 failing
                    All 13 pre-existing and unrelated (10 captain layout,
                    2 dashboard trip-creation text-scale, 1 client ticket).
                    This pass added 8 tests and broke none.
```

Checked explicitly: no new analyzer issues, no broken navigation (every route registered
and titled), no permission bypass (route gate test), no cross-office leak (no query
scoping changed), no licensing bypass (`feature` keys preserved on every nav item, plus
`reports` added to the newly-surfaced entry), no finance calculation touched, no RTL or
responsive regression (existing layout and RTL tests pass).

---

## Implementation roadmap

Full detail in `DASHBOARD_ROADMAP.md`.

```
Phase 1 — Critical      fleet RLS role gate · cap the composition screens ·
                        page the module lists · scope the report views

Phase 2 — Core UX       merge payment verification into bookings ·
                        sharpen Home vs Business Overview · persist filters ·
                        retire Settings · default to "today"

Phase 3 — Business      CUSTOMER DIRECTORY + PROFILE · schedule templates ·
                        no-shows and cancellations · driver availability ·
                        contact log

Phase 4 — Analytics     date-bound the driver/vehicle/complaint views ·
                        route performance over time · real driver metrics ·
                        period comparison · scheduled reports

Phase 5 — Polish        consolidate notices · tickets onto RPCs ·
                        referral_analytics grant · tests for 6 untested modules ·
                        fix pre-existing overflows
```
