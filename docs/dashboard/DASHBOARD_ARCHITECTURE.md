# Dashboard — Architecture

Verified against the tree on 2026-08-15. ~575 Dart files, ~108k lines under
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
│   ├── routes/                   DashboardRoutes constants + DashboardShell
│   ├── session/                  DashboardSession (mutable holder) + OfficeContext
│   ├── theme/                    colours, icons, theme cubit + repository
│   ├── ui_state/                 DashboardSectionStateStore (fold memory)
│   └── widgets/                  the design system: tables, panels, KPI cards, charts
└── features/<feature>/
    ├── data/         models · datasources (Supabase) · repositories (impl)
    ├── domain/       entities · repositories (interfaces) · usecases
    └── presentation/ cubit · screens · widgets
```

Feature-first Clean Architecture, one direction: **presentation → domain ← data**.
Presentation never imports `data/`; domain is plain Dart.

Two features are large enough to be split into sub-features with the same three layers
each:

- `trips/` → `trip_creation`, `trip_management`, `trip_passengers`, `trip_pricing`,
  `trip_seats`, `trip_events`, plus `shared/` and its own `trips_di.dart`
- `fleet/` → `fleet_drivers`, `fleet_vehicles`, `fleet_assignments`, `fleet_documents`,
  plus `overview/` (the tab host) and `shared/`

`subscriptions/` similarly carries a `plans/` sub-feature.

---

## 2. The data path

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
not a REST API, so there is no Dio, no Retrofit, no `ApiResult<T>`. Datasources throw
typed failures; repositories let them propagate; cubits catch and emit an error state.
The `ApiResult` union in the playbook does not apply here — do not introduce it.

State is `sealed class` hierarchies with `switch` exhaustiveness rather than freezed
unions. Also intentional, also consistent across the whole dashboard.

---

## 3. Dependency injection

One `GetIt` instance, `dashboardDi`, registered by `registerDashboardDependencies()`.
Every registration is guarded by `if (!dashboardDi.isRegistered<T>())` so tests can
pre-register fakes and the production graph steps around them.

Lifetimes:

| Kind | Lifetime | Why |
|---|---|---|
| `SupabaseClient`, `DashboardSession`, `EntitlementService` | lazy singleton | session-wide |
| Datasources, repositories, use cases | lazy singleton | stateless |
| Cubits | **factory** | fresh per screen mount |

`PlatformLicensingCubit` is the one exception: the shell holds a single instance across
all three licensing destinations, because those sections read each other constantly and a
per-route `create:` would refetch the whole catalog on every tab change.

`DashboardSession` is a mutable `ChangeNotifier` holder rather than an injected value,
because every datasource singleton is constructed before anyone has signed in. A
constructor-injected office id would be captured as null and stay null.

---

## 4. Navigation

There is no `Navigator` route table and no `onGenerateRoute`. `DashboardShell` holds a
`_route` string and a `switch` in `_buildContent()`.

```dart
DashboardRoutes.bookings => BlocProvider(
  create: (_) => dashboardDi<BookingsCubit>()..load(),
  child: const BookingsScreen(),
),
```

Adding a module means: a `DashboardRoutes` constant, a `_DashboardNavItem` entry (with
`permission`, optional `feature`, optional `group`, and `inSidebar: false` if it is a
drill-in destination), and a `case` in `_buildContent()`.

**The `_items` table is load-bearing.** It is what the role gate, the licensing gate and
the top-bar title all read. A route rendered by `_buildContent()` but missing from
`_items` used to resolve to the home item on lookup — which permits everyone and is
titled "الرئيسية". That was a live permission bypass; `_canOpenRoute` now returns `false`
for unknown routes and `dashboard_shell_route_gate_test.dart` holds the line.

Cross-module navigation is prop-drilled: `onOpenModule(String route)` is passed down from
the shell to Home and نظرة تنفيذية, whose cards call it. Modules never navigate
themselves.

---

## 5. Composition-root cubits

`DashboardHomeCubit` and `BusinessOverviewCubit` own **no datasource**. They call the
same use cases the feature modules register, in parallel, and let an entity derive the
counts. That is what guarantees a number on Home matches the module it came from — there
is no second, capped, hand-rolled query path to drift.

Both tolerate partial failure: each feed is guarded individually, failures are collected
by name, and the page renders what arrived with a `DashboardPartialDataNotice` naming
what did not. Only a total failure emits an error state.

The cost is real and is the main performance liability in the console: Home fires nine
uncapped queries and نظرة تنفيذية fires twelve, and the shell rebuilds both from scratch
on every visit. See `DASHBOARD_KNOWN_ISSUES.md` §2.

---

## 6. Entitlements at runtime

`EntitlementService` resolves the office's licence once at sign-in and holds it as a
`ChangeNotifier`. The shell listens: when entitlements change, the sidebar recomputes and
a route the office just lost is closed underneath the operator.

`LicensingGuard.run(...)` wraps writes that can be refused. When the server refuses, the
guard publishes a `LicensingFailure` on the global `licensingRefusals` notifier; the shell
consumes it, refreshes the entitlement document (the server just disagreed with what we
hold, so our copy is stale by definition) and shows the upgrade card. One wiring point,
so a new module cannot ship without an upgrade path.

---

## 7. Testing

77 dashboard test files, ~1,090 assertions passing. The shapes used:

- **Cubit tests** with hand-written fake repositories (no mocking framework).
- **Widget tests** that mount a screen with fakes registered in `dashboardDi`, then
  `dashboardDi.reset()` in `tearDown`.
- **Layout tests** that pump at several widths and text scales and assert no overflow.
- **RTL tests** asserting directional icons are named with LTR semantics so the framework
  mirrors them (`dashboard_rtl_test.dart`).
- **Fixture files** (e.g. `dashboard_home_test_fixtures.dart`) building entities by hand.

Two dashboard tests fail on `main` and are unrelated to any recent change:
`trip_creation_driver_vehicle_test.dart` overflows at 1.3× and 1.6× text scale.

The showcase harness (`tool/showcase/`) renders modules with canned data and no auth —
the only practical way to eyeball a screen without a live office. It had been broken since
the platform console consolidation renamed `DashboardRoutes.platformPlans`; it builds
again.
