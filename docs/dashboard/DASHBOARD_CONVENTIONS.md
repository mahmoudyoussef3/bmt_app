# Dashboard — Conventions

What a reviewer checks. Each rule below is one the console already follows everywhere;
a change that breaks one should not merge without saying why in the diff.

`CLAUDE.md` is the repository-wide playbook. Where this file differs, this file wins for
`lib/apps/dashboard/` — the divergences are listed in §1 and are deliberate.

---

## 1. Where the dashboard deliberately differs from the root playbook

| Playbook says | Dashboard does | Why |
|---|---|---|
| Dio + Retrofit + `ApiResult<T>` | Supabase client, thrown failures | There is no REST API. Introducing `ApiResult` here would wrap a `PostgrestException` in a union nothing else reads. |
| `@freezed` state unions | `sealed class` + `switch` | Predates freezed adoption, is exhaustive at compile time, and 25 state files are consistent with it. Converting them buys nothing and regenerates 25 files. |
| `Routes` + `AppRouter.generateRoute` | `DashboardShell` switch | The console is one page with a swappable body, not a navigation stack. |
| ScreenUtil `.w/.h/.sp/.r` | plain logical pixels + `AppSpacing`/`AppTokens` | This is a desktop web console with a resizable window, not a fixed 375×812 phone canvas. Scaling a sidebar by a phone design ratio is meaningless. |

Everything else in `CLAUDE.md` applies: naming, layer direction, one widget per file,
`const` where possible, no hardcoded colours.

---

## 2. Naming

| Thing | Pattern | Example |
|---|---|---|
| Datasource interface | `<Feature>Datasource` | `BookingsDatasource` |
| Datasource impl | `Supabase<Feature>Datasource` | `SupabaseBookingsDatasource` |
| Repository interface | `<Feature>Repository` | `WalletRepository` |
| Repository impl | `<Feature>RepositoryImpl` | `WalletRepositoryImpl` |
| Use case | `<Verb><Noun>UseCase` | `AddBookingNoteUseCase` |
| Entity | `<Noun>`, no suffix | `OperationBooking` |
| Model | `<Noun>Model extends <Noun>` | `OperationBookingModel` |
| Cubit / state | `<Feature>Cubit` / `<Feature>State` | `BookingsCubit` |
| State variants | `<Feature>Loading` / `Loaded` / `Error` | `BookingsLoaded` |

A model **extends** its entity rather than holding one. The repository then returns the
model as the entity with no mapping step, which is why most repository implementations
are one line per method.

---

## 3. Errors

One shape, end to end:

```dart
// datasource — throws whatever Supabase threw, after the licensing check
catch (e) { throw _handleError(e); }        // LicensingGuard.check(e) first

// repository — names the failure in Arabic, keeps the reason
throw Exception('تعذر نقل الحجز إلى الرحلة المحددة: ${_reason(error)}');

// cubit — strips the prefix, emits
emit(XError(error.toString().replaceFirst('Exception: ', '')));
```

The reason is **kept, not discarded**: the RPCs raise specific, actionable errors
(`seat_taken`, `cross_office_reassignment_denied`) and an operator who only sees
"تعذر نقل الحجز" has no way to act on them.

`LicensingGuard.check(error)` runs **first** in every datasource catch. A plan-limit
refusal is not a database error and must leave as a `LicensingFailure` so the shell can
raise the upgrade card.

---

## 4. State

- One `sealed` base, three or more variants, `Loaded` carrying everything the screen
  needs.
- Derived values are `late final` fields on `Loaded`, not getters that recompute:
  `BookingsLoaded.filteredBookings` is read several times per build.
- **A failed action never emits an error state.** Error states are for a failed *load*,
  when there is nothing to show. An action failure sets `actionError` on the still-intact
  `Loaded` state and the screen shows a snackbar. Losing a filtered queue and an open
  inspector because one approval was refused is not a trade an operator would make.
- `copyWith` takes an explicit `clearX` bool for every nullable field. `null` means
  "unchanged".

---

## 5. Queries

- **Every list query has a ceiling and an order.** The ceiling comes from
  `DashboardQueryCaps`; the order makes it a decision rather than an accident. See
  `DASHBOARD_PERFORMANCE.md` §2.
- A capped query is paired with a `capReached` getter on the state and a
  `DashboardCapNotice` on the screen. Silently truncating a list and then totalling it is
  the failure this console refuses everywhere else.
- **Never pass an office id from the client.** RLS and the definer RPCs resolve the
  caller's office server-side. A query written as if it were unscoped comes back scoped;
  a query that accepts an office id is a cross-tenant read waiting to be found.
- State changes go through the audited `SECURITY DEFINER` RPCs, never through column
  writes. Two exceptions exist and are both recorded in `DASHBOARD_KNOWN_ISSUES.md`.

---

## 6. Widgets

- Shell owns the chrome. A module renders content and nothing else — see
  `DASHBOARD_UI_ARCHITECTURE.md`.
- `StatelessWidget` unless there is local UI state to hold (a text controller, a hover
  flag, an expansion). 662 of the console's 747 widgets are stateless.
- Reuse before creating: check `core/widgets/` for a table, panel, KPI card, empty state,
  loading skeleton, cap notice, master/detail or chart before writing one.
- No `Color(0x…)` in a widget. `DashboardColors`, `DashboardChartPalette`, or the theme.
- `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional` — never the
  non-directional forms for anything asymmetric. The console is RTL.

---

## 7. Tests

Two traps account for most confusing dashboard test failures:

**Lazy lists.** Screens are `ListView`s. A widget below the fold has not been *built*, so
`find.byType(X)` returns nothing and `ensureVisible` throws `Bad state: No element` —
neither is evidence the widget is missing. Scroll to it:

```dart
await tester.scrollUntilVisible(finder, 360,
    scrollable: find.byType(Scrollable).first);
```

**Responsive swaps.** Several modules render a card list below a breakpoint and
`OpsDataTable` above it. A test that names one layout's button breaks the next time the
breakpoint moves, while the behaviour under test is still correct. Target whichever
affordance is present, or assert on something layout-independent:

```dart
final card = find.widgetWithText(FilledButton, 'فتح الملف');
final table = find.byTooltip('عرض جاهزية السائق');
final target = tester.any(card) ? card.first : table.first;
```

Beyond that: fake repositories by hand (no mocking framework), register them in
`dashboardDi` and `dashboardDi.reset()` in `tearDown`, and pump layout tests at several
widths **and** at 1.3× / 1.6× text scale — Arabic at 1.6× overflows layouts that look
fine at 1.0×.

Session-scoped singletons (`DashboardFilterMemory`, `DashboardSectionStateStore`) leak
between tests in the same file. Clear them in `setUp` **and** `tearDown` when a test
depends on their contents.

---

## 8. Comments

The console's comments explain *why*, and that is worth protecting. The standard:

- Keep a comment that records a decision, a constraint, a business rule, a security
  boundary, or a bug that a future edit would reintroduce.
- Delete a comment that restates the code, or that was a note-to-self left mid-thought
  (`// since it's RTL, left is visually correct for the 'end' or 'start', let's use
  directionality` was a real one, above a wrapper that did nothing).
- An empty line where a comment was deleted is not a comment. Several `catch (_) { }`
  blocks held a blank line where an explanation used to be; a swallowed error needs the
  sentence saying why it is safe to swallow, or it needs to stop being swallowed.
