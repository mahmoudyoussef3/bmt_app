# Dashboard — UI Architecture

How ~23 modules read as one product. The rules live in `DASHBOARD_UX_GUIDELINES.md`;
this file is the inventory and the composition model behind them.

---

## 1. The shell owns the chrome

```
DashboardShell
├── Sidebar            nav items, groups, role + licensing gates, sign-out
├── TopBar             module title, section subtitle, notifications bell, theme toggle
└── _buildContent()    ONE module, swapped by route
```

A module renders content and nothing else. A module that draws its own app bar, back
button or sign-out has duplicated the shell and will drift from it.

Breakpoints the shell owns:

| Width | Sidebar |
|---|---|
| < 920 | drawer |
| 920–1180 | icon rail |
| ≥ 1180 | labelled, unless the operator collapsed it |

`_navCollapsed` is `null` until the operator chooses: the shell follows the window, then
obeys the person.

---

## 2. The shared vocabulary

Everything in `core/widgets/`. **Check here before writing a new one.**

| Widget | Job |
|---|---|
| `DashboardModuleHeader` | every module's opening block: icon, title, subtitle, actions, pinned controls, optional KPI summary |
| `OpsDataTable` | the one table: sticky header, `flex` columns with `minWidth`, optional sort, integrated pagination, hover rows, RTL-correct, horizontal scroll inside its own container |
| `DashboardCollapsibleSection` / `DashboardPanel` | folding blocks, fold state persisted per `sectionId` |
| `DashboardKpiCard` / `DashboardKpiGrid` | the number tiles |
| `DashboardLoading` | skeleton, `rows:` and `showHeader:` shaped to the page it replaces |
| `DashboardErrorState` | failed first load, with retry |
| `DashboardEmptyState` / `EmptyState` | loaded, nothing there — says what would put data here |
| `DashboardPartialDataNotice` | some feeds failed, names them |
| `DashboardCapNotice` | the list is the newest N rows, not all of them |
| `MasterDetailLayout` | directory → inspector, sheet below the breakpoint |
| `charts/` | donut, line, bar, sparkline, ranked bars, `DashboardChartPalette` |

`DashboardCapNotice` is new in this pass and replaced a private `_CapNotice` inside
المركز المالي. Five modules now carry a cap; one notice serves all of them.

---

## 3. Screen composition

A module screen is an orchestrator, not a widget tree. The shape:

```
XScreen                       BlocConsumer at the root, one per module
└── _LoadedView
    ├── DashboardModuleHeader     title · actions · cap notice · KPI summary
    ├── XToolbar                  filters, search, view mode
    ├── XBulkActions              only when a selection exists
    ├── XQueueBoard / OpsDataTable
    └── XAnalyticsSection         folded by default
```

The detail pane is a sibling, not a child: on a wide window it is a `Row` beside the
content, below the breakpoint it is a full-height sheet whose scrim dismisses it.

Sizes worth knowing, all measured:

- 662 `StatelessWidget` vs 85 `StatefulWidget` — state is held in cubits, not widgets.
- 41 files over 500 lines; 19 over 800. The largest is
  `trip_creation_wizard.dart` at 1,884.

---

## 4. One builder per screen, on purpose

There are 45 `BlocBuilder`/`BlocConsumer` sites in the console and **exactly one per
module**, at the root. There is no `buildWhen` and no `BlocSelector` anywhere.

This looks like an omission and is not. The state a module builder reads *is* the
module's data; a `buildWhen` at the root would be asking "did anything change", and
`BlocSelector` for sub-widgets would trade a readable tree for a rebuild saving that only
matters if emissions are frequent.

So the console controls **emission rate** instead of builder scope, which is the variable
that actually costs frames:

| Emitter | Rate | Control |
|---|---|---|
| `BookingsCubit` | realtime | 400ms coalesce + in-flight guard |
| `TripsListCubit`, `TripDetailsCubit` | realtime + 30s poll | 250ms debounce + in-flight guard |
| `LiveOpsCubit` | 15s poll | by design — it is the live view |
| `OperationalAlertsBadgeCubit` | realtime | builder scoped to the bell `IconButton` alone |

The one place scope *is* controlled is the badge, because it sits in the shell's top bar
and would otherwise rebuild the console on every alert.

**If you add a high-frequency emitter, debounce it before you reach for `BlocSelector`.**

---

## 5. State views

| Situation | What to show |
|---|---|
| First load | `DashboardLoading` |
| Initial load failed | `DashboardErrorState` with retry |
| Loaded, no data | `EmptyState` — say what would put data here |
| **Refetching over a loaded page** | Keep the page. Dim the results, thin progress bar. |
| **An action failed** | Snackbar over the page. **Never** replace it. |
| **Some feeds failed** | `DashboardPartialDataNotice` naming them, plus what arrived |
| **List hit its ceiling** | `DashboardCapNotice` in the header, beside the count |

The two bolded rules are the ones most often broken, and the damage is the same each
time: the operator loses the filters and the selection they had built.

---

## 6. RTL

The console is Arabic-only and renders RTL.

- Directional insets, alignments and positioning — never the physical forms for anything
  asymmetric. `PositionedDirectional`, not `Positioned(left:)`.
- **Name directional icons with LTR semantics.** `Icons.chevron_right` for "next";
  Material declares these with `matchTextDirection: true` and the framework mirrors them.
- **Do not mirror physical objects.** Seat maps stay LTR; a bus is not a text run. Three
  files are allowlisted in `dashboard_rtl_test.dart` for exactly this.
- `dashboard_rtl_test.dart` fails the build on any other `TextDirection.ltr` in
  `lib/apps/dashboard`. It caught one in the fleet document preview during this pass — a
  `Directionality(ltr)` wrapper around a close button, which did nothing except break the
  rule.

---

## 7. Responsive

| Breakpoint | Behaviour |
|---|---|
| < 920 | sidebar → drawer |
| 920–1180 | sidebar → icon rail |
| ~1180 | booking inspector splits vs. sheet |
| ~1200 | fleet tabs swap card list ↔ `OpsDataTable` |
| ~900 | two-column bands stack (each column needs ~380px) |
| ~760 | booking board goes compact |
| ~720 | toolbars wrap |

**No fixed pixel dialog sizes.** The fleet document preview was a hard `SizedBox(800, 800)`
inside 24px inset padding — taller than the viewport on a 1366×768 laptop, so it
overflowed rather than shrinking. It is now a `ConstrainedBox` with a max side and a
viewport-relative minimum.

Layout tests pump at several widths **and** at 1.3× / 1.6× text scale. Arabic at 1.6×
overflows layouts that look fine at 1.0×.

---

## 8. Colour and theme

Colours from `DashboardColors` and `DashboardChartPalette`, text styles from the theme,
spacing from `AppSpacing`, radii and motion from `AppTokens`. No hardcoded `Color(0x…)`
and no hardcoded radius in a widget. Both light and dark are covered by
`dashboard_design_system_overflow_test` and the theme/RTL tests.
