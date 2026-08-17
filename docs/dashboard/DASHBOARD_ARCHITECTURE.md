# Dashboard — Architecture

Verified against the tree on 2026-08-16. **562 Dart files, ~107.6k lines** under
`lib/apps/dashboard/`.

---

## 1. Where things live

```
lib/apps/dashboard/
├── main.dart                     app entry (via lib/main_dashboard.dart)
├── core/
│   ├── di/dashboard_di.dart      ONE get_it graph for the whole console
│   ├── entitlements/             licensing: context, service, guard, dialogs, export
│   ├── permissions/              DashboardRole + DashboardPermission
│   ├── query/                    DashboardQueryCaps — every list ceiling, one file
│   ├── routes/                   DashboardRoutes constants + DashboardShell
│   ├── session/                  DashboardSession (mutable holder) + OfficeContext
│   ├── theme/                    colours, icons, theme cubit + repository
│   ├── ui_state/                 section fold memory + filter memory
│   └── widgets/                  the design system: tables, panels, KPI cards, charts
└── features/<feature>/
    ├── data/         models · datasources (Supabase) · repositories (impl)
    ├── domain/       entities · repositories (interfaces) · usecases
    └── presentation/ cubit · screens · widgets
```

Feature-first Clean Architecture, one direction: **presentation → domain ← data**.

Two features are large enough to be split into sub-features with the same three layers
each:

- `trips/` → `trip_creation`, `trip_management`, `trip_passengers`, `trip_pricing`,
  `trip_seats`, `trip_events`, plus `shared/` and its own `trips_di.dart`
- `fleet/` → `fleet_drivers`, `fleet_vehicles`, `fleet_assignments`, `fleet_documents`,
  plus `overview/` (the tab host) and `shared/`

`subscriptions/` similarly carries a `plans/` sub-feature.

---

## 2. The dependency rule, and how it is checked

The rule is not "these folders exist". It is four statements that must all be false,
and they are greppable:

| Violation | How to check | Status |
|---|---|---|
| presentation imports `data/` | `grep -rl "import.*/data/" features/*/presentation` | **0** |
| presentation touches Supabase | `grep -rl "SupabaseClient" features/*/presentation` | **0** |
| domain imports Flutter | `grep -rl "package:flutter/" features/*/domain` | **0** |
| data imports presentation | `grep -rl "import.*presentation" features/*/data` | **0** |

All four were non-zero before the 2026-08-16 pass. What they caught:

- **`office_billing` had no data layer at all.** Its cubit held a `SupabaseClient`,
  called `.rpc('office_invoices')` and parsed the response through a `fromJson` factory
  on the *domain entity*. It now has datasource → repository → use case like every other
  feature, and the entity is plain Dart.
- **`DashboardAuthCubit` depended on the concrete `DashboardAuthDatasource`.** The most
  security-sensitive cubit in the console could not be tested without a live Supabase
  client. It now depends on `DashboardAuthRepository`, which the datasource implements.
- **`WalletScreen` called a `data/services/` export service directly.** Finance already
  routed the same job through its repository; wallet now does too
  (`ExportWalletStatementUseCase`).
- **Two fleet presentation files imported `data/models/fleet_models.dart`** for one
  function that maps a document type to its wire name. The wire name moved onto the
  domain enum (`FleetDocumentType.wireName`), which deleted a duplicated switch as well
  as the import.

### The accepted deviation

`platform_licensing` keeps 29 `fromJson` factories on its domain entities rather than in
`data/models/`. This is **deliberate and documented**, not an oversight:

Those RPCs return one document per surface, already shaped the way the screen reads it.
A parallel model layer would copy fifteen classes field-for-field to gain nothing but a
folder, and it would do so inside the most security-sensitive subsystem in the console.
The codebase already states this position in `WalletRepositoryImpl`:

> There is no mapping left to do here — the datasource already returns domain entities,
> because the RPCs return one document per surface rather than raw table rows, and
> inventing a second DTO layer over a shape that is already the screen's shape would be
> ceremony.

The distinction that matters: `office_billing` was fixed because presentation held a
database client — a *functional* problem. `platform_licensing` parses JSON in an entity —
a *purity* problem, with no test, coupling or correctness cost attached to it.

---

## 3. The data path

```
Screen
  └─ context.read<XCubit>().action()
       └─ UseCase(...)                        one class, one verb
            └─ XRepository (domain interface)
                 └─ XRepositoryImpl (data)    maps model → entity
                      └─ SupabaseXDatasource  .from(...) / .rpc(...)
                           └─ Supabase (RLS + triggers + RPCs)
```

**Divergence from the root playbook, and it is intentional:** this app talks to Supabase,
not a REST API, so there is no Dio, no Retrofit, no `ApiResult<T>`. Datasources throw;
repositories translate the failure into an Arabic sentence and rethrow; cubits catch,
strip the `Exception: ` prefix and emit an error state. The `ApiResult` union in the
playbook does not apply here — do not introduce it.

State is `sealed class` hierarchies with `switch` exhaustiveness rather than freezed
unions. Also intentional, also consistent across all 25 state files.

---

## 4. Dependency injection

One `GetIt` instance, `dashboardDi`, registered by `registerDashboardDependencies()`.
Every registration is guarded by `if (!dashboardDi.isRegistered<T>())` so tests can
pre-register fakes and the production graph steps around them.

| Kind | Lifetime | Why |
|---|---|---|
| `SupabaseClient`, `DashboardSession`, `EntitlementService` | lazy singleton | session-wide |
| Datasources, repositories, use cases | lazy singleton | stateless |
| Cubits | **factory** | fresh per screen mount |
| `DashboardAuthCubit` | **lazy singleton** | the auth gate and the sign-out button must act on one instance |

`PlatformLicensingCubit` is the other exception: the shell holds a single instance across
all licensing destinations, because those sections read each other constantly and a
per-route `create:` would refetch the whole catalog on every tab change.

`DashboardSession` is a mutable `ChangeNotifier` holder rather than an injected value,
because every datasource singleton is constructed before anyone has signed in. A
constructor-injected office id would be captured as null and stay null.

**Bind to the interface, never the implementation.** `DashboardAuthRepository` is
registered, `DashboardAuthDatasource` is what satisfies it. A registration keyed on the
concrete class is a test that cannot substitute a fake.

---

## 5. Navigation

There is no `Navigator` route table and no `onGenerateRoute`. `DashboardShell` holds a
`_route` string and a `switch` in `_buildContent()`.

Adding a module means: a `DashboardRoutes` constant, a `_DashboardNavItem` entry (with
`permission`, optional `feature`, optional `group`, and `inSidebar: false` if it is a
drill-in destination), and a `case` in `_buildContent()`.

**The `_items` table is load-bearing.** It is what the role gate, the licensing gate and
the top-bar title all read. A route rendered by `_buildContent()` but missing from
`_items` used to resolve to the home item on lookup — which permits everyone and is
titled "الرئيسية". That was a live permission bypass; `_canOpenRoute` now returns `false`
for unknown routes and `dashboard_shell_route_gate_test.dart` holds the line.

A route may render another module's screen. `/payment-verification` does exactly that
since مراجعة المدفوعات was folded into الحجوزات — it stays in `_items` (so it keeps its
permission and its title) and builds `BookingsScreen` with a queue preset.

Cross-module navigation is prop-drilled: `onOpenModule(String route)` is passed down from
the shell to Home and نظرة تنفيذية, whose cards call it. Modules never navigate
themselves.

---

## 6. Composition-root cubits

`DashboardHomeCubit` and `BusinessOverviewCubit` own **no datasource**. They call the
same use cases the feature modules register, in parallel, and let an entity derive the
counts. That is what guarantees a number on Home matches the module it came from — there
is no second, capped, hand-rolled query path to drift.

Both tolerate partial failure: each feed is guarded individually, failures are collected
by name, and the page renders what arrived with a notice naming what did not. Only a
total failure emits an error state.

Home now fires **8** feeds and نظرة تنفيذية **11**, down one each: both used to fetch the
payment-verification queue as a separate feed and use it only for a count of bookings
awaiting a decision — a number the bookings feed they *also* fetched already contained.

---

## 7. Entitlements at runtime

`EntitlementService` resolves the office's licence once at sign-in and holds it as a
`ChangeNotifier`. The shell listens: when entitlements change, the sidebar recomputes and
a route the office just lost is closed underneath the operator.

`LicensingGuard.run(...)` wraps writes that can be refused. When the server refuses, the
guard publishes a `LicensingFailure` on the global `licensingRefusals` notifier; the shell
consumes it, refreshes the entitlement document (the server just disagreed with what we
hold, so our copy is stale by definition) and shows the upgrade card. One wiring point,
so a new module cannot ship without an upgrade path.

---

## 8. Testing

82 dashboard test files, **1,206 assertions passing, 0 failing**. The shapes used:

- **Cubit tests** with hand-written fake repositories (no mocking framework).
- **Widget tests** that mount a screen with fakes registered in `dashboardDi`, then
  `dashboardDi.reset()` in `tearDown`.
- **Layout tests** that pump at several widths and text scales and assert no overflow.
- **RTL tests** asserting no dashboard file forces `TextDirection.ltr` outside a short
  allowlist, and that directional icons are named with LTR semantics so the framework
  mirrors them (`dashboard_rtl_test.dart`).
- **Fixture files** (e.g. `dashboard_home_test_fixtures.dart`) building entities by hand.

See `DASHBOARD_CONVENTIONS.md` §7 for the two traps that make dashboard widget tests
fail for reasons unrelated to the code under test.
