# Dashboard — UX Guidelines

The rules that make ~25 modules read as one product. These are not preferences; a change
that breaks one of them should not merge.

---

## 1. The shell owns the chrome

A module renders content and nothing else. The sidebar, the top bar, the module title,
the section subtitle, the notifications bell, the theme toggle and sign-out all belong to
`DashboardShell`.

A module that draws its own back button, its own app bar, or its own sign-out has
duplicated the shell and will drift from it.

---

## 2. Every module opens the same way

```dart
DashboardModuleHeader(
  icon: DashboardIcons.xActive,
  title: '…',
  subtitle: '…',                 // what this screen is for, in one line
  actions: [ /* refresh, create */ ],
  pinned: /* controls that scope the WHOLE page */,
)
```

`pinned` is for controls every figure below depends on — the finance period bar is the
canonical case. If an operator cannot see it, they cannot read the page.

---

## 3. One table

`OpsDataTable`. Sticky header, proportional `flex` columns with `minWidth`, optional sort,
integrated pagination, hover rows, RTL-correct, horizontal scroll inside its own container
so the page body never scrolls sideways.

It replaced three paradigms (raw `DataTable`, a bespoke fleet shell, and card lists). Do
not add a fourth.

---

## 4. Everything folds

`DashboardCollapsibleSection` / `DashboardPanel`, each with a `sectionId` registered in
`DashboardSectionIds`. Fold state persists for the session via
`DashboardSectionStateStore`, so an owner who reads money first can collapse the rest once
and find that layout waiting for them.

A screen with more than three major blocks and no folding is not finished.

---

## 5. Filters

```
open filter → choose → apply → collapse → read the data
```

The filter bar must not own the screen. Collapse it into a section, or keep it to one row.
And the rule that outranks all of that:

> **A control that cannot reach the query is not a control.**

Do not render a dropdown the datasource ignores. If a report cannot be date-bounded, say
so in a scope note instead of drawing a date picker that changes nothing.

---

## 6. State views

| Situation | What to show |
|---|---|
| First load | `DashboardLoading` (skeleton, `rows:` and `showHeader:` to match the page) |
| Initial load failed | `DashboardErrorState` with a retry |
| Loaded, no data | `EmptyState` — say what would put data here |
| **Refetching over a loaded page** | Keep the page. Dim the results, run a thin progress bar. |
| **An action failed** | Snackbar over the page. **Never** replace it. |
| **Some feeds failed** | `DashboardPartialDataNotice` naming them, plus everything that did arrive |

The two bolded rules are the ones most often broken, and the damage is the same each time:
the operator loses the filters and the selection they had built.

---

## 7. Master/detail

`MasterDetailLayout` for directory→inspector modules (wallet, fleet tabs, licensing
features). Below the breakpoint the detail becomes a full-height sheet whose **scrim
dismisses it** — a scrim that looks like a modal barrier but swallows taps is worse than
no scrim.

For a workspace with several unrelated concerns, prefer **full-width tabs** over a narrow
detail pane holding six stacked panels. That was the lesson of the التراخيص rebuild:
reaching the invoices meant scrolling past everything above them, in a column too narrow
for any of it.

---

## 8. RTL

The console is Arabic-only and renders RTL.

- `EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderDirectional` — never the
  non-directional forms for anything asymmetric.
- **Name directional icons with LTR semantics.** `Icons.chevron_right` for "next" — Material
  declares these with `matchTextDirection: true` and the framework mirrors them. Naming the
  already-flipped icon renders it backwards. `dashboard_rtl_test.dart` enforces this.
- **Do not mirror physical objects.** Seat maps stay LTR; a bus is not a text run.
- Normalise Arabic-Indic digits on input where a value is matched (plate numbers).

---

## 9. Numbers

- Money is one format, module-wide, via each module's `*Format` helper.
- Percentages carry their basis; occupancy is booked ÷ capacity, computed from real seat
  counts.
- **Never invent a trend.** No comparison period means no arrow.
- **Never present a computed zero as a measurement.** If the source cannot answer, remove
  the tile and say why — two fabricated columns are worse than two missing ones.
- Show excluded amounts as memo lines rather than dropping them from a total.

---

## 10. Actions

Every important action needs: a clear CTA in a predictable place, confirmation when
destructive, a loading state, a success notice, and a failure notice. All four states,
every time.

Sign-out sits in the sidebar footer next to the identity it ends — it used to be three
clicks and a scroll away inside Settings, on a screen an operator had no other reason to
open.

---

## 11. Responsive

| Breakpoint | Behaviour |
|---|---|
| < 920 | Sidebar → drawer |
| 920–1180 | Sidebar → icon rail |
| ~900 | Two-column bands stack (each column needs ~380px to stay readable) |
| ~800 | Report split → stacked |
| ~720 | Toolbars wrap |

Layout tests pump at several widths **and** at 1.3× / 1.6× text scale. Arabic at 1.6×
overflows layouts that look fine at 1.0×.

---

## 12. Colour and theme

Colours come from `DashboardColors` and `DashboardChartPalette`, text styles from the
theme, spacing from `AppSpacing`, radii and motion from `AppTokens`. No hardcoded `Color(0x…)`
in a widget. Both light and dark must be checked — `dashboard_design_system_overflow_test`
and the theme/RTL tests cover the combinations.
