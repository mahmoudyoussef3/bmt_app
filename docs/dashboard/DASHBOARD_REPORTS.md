# Dashboard — Reports

`/reports` — «التقارير». Owner **and** support agent. Licensed on `reports`, metered on
`export_pdf` / `export_excel`.

---

## 1. Reports vs Finance vs Operations

These three must not blur into each other:

| Surface | Question | Shape |
|---|---|---|
| **العمليات المباشرة** | What is happening *right now*? | Live board, self-refreshing |
| **المركز المالي** | What happened to the *money*? | Statements, one period, formal |
| **التقارير** | What happened to the *business*? | Pick a subject, filter it, export it |

Overlap that is intentional: both Finance and Reports can produce a revenue figure for a
period, and they agree because both read `revenue_daily_view`. Overlap that would be a
bug: Reports growing an approve button, or Finance growing a driver-performance tab.

---

## 2. The seven reports

| Report | Source | Period-bounded? | Filters it honours |
|---|---|---|---|
| الإيرادات | `revenue_daily_view` | **yes** | date range |
| الرحلات | `operation_trips` + earned bookings | **yes** | date range, route, driver, vehicle |
| الحجوزات | `operation_bookings` | **yes** | date range, route |
| السائقين | `drivers_performance_view` | no — lifetime | driver |
| المركبات | `vehicles_efficiency_view` | no — lifetime | vehicle |
| الاشتراكات | `subscriptions` | no — lifetime | package |
| الشكاوى | `complaints_summary_view` | no — lifetime | — |

**Two kinds of source, and the difference decides everything.**

*The licensed views* (`drivers_performance_view`, `vehicles_efficiency_view`,
`complaints_summary_view`) are office-scoped in their own bodies and carry
`office_licensed('reports')` as a genuine server-side read gate. They are lifetime
roll-ups with **no date column**, so the reports built on them declare
`usesDateRange == false` and print a scope note saying the period does not apply to them —
rather than showing a date picker they silently ignore.

*The base tables* (`operation_trips`, `operation_bookings`, `subscriptions`) carry dates
and dimensions, so those three reports are genuinely period-bounded and genuinely
filterable. Their gate is the module-level `reports` entitlement, recorded honestly as
`ui` in the licensing migration.

---

## 3. Filters

`ReportType.supportedFilters` declares what each report can apply, and the filter bar
draws only that set. Where nothing applies (الشكاوى) the bar collapses to a one-line note.

This is a rule, not a preference: **a control that cannot reach the query is not a
control.** Until this pass all four dropdowns were drawn for every report and the
datasource read none of them — an operator could pick a driver on the revenue report,
watch the page reload, and get back identical rows.

---

## 4. Trip revenue

Always summed from the trip's own earned bookings (`approved` / `confirmed` / `completed`),
matching the finance module's rule so a route's revenue reads the same in both places.

**Never from `operation_trips.revenue`.** That column exists and nothing writes it; code
reading it reports zero.

---

## 5. Export

PDF (Cairo font, RTL), Excel, CSV (UTF-8 + BOM). The file carries the same columns as the
on-screen table. Export consumes the licensed format quota before generating, and a
refusal now surfaces as a notice instead of being swallowed.

---

## 6. Behaviour

- Opens on **الإيرادات**. It used to open on الرحلات while that report was a stub whose
  only KPI read "قيد التطوير الفعلي", so the first thing anyone saw of the module was a
  placeholder.
- Switching report type or changing a filter **refetches over the page**: the selector,
  the filter bar and the export toolbar stay put, the results dim, a thin progress bar
  runs. It used to emit a full-screen loading state and tear all three down.
- A failed refetch or a refused export lands as a snackbar on the still-valid page. It
  used to emit a whole-screen error that discarded the filters the operator had built.

---

## 7. Known gaps

- **`drivers_performance_view` and `vehicles_efficiency_view` cannot be date-bounded.**
  "This driver's trips *last month*" is a reasonable question the schema cannot answer.
  Fixing it means adding a date dimension to those views (a migration), not more Dart.
- **Driver rating and working hours are not reported.** The view never had those columns;
  they were being read by name, arriving null, and printing as `0 ساعة` and `0.0 ★`. Two
  fabricated columns are worse than two missing ones, so they were removed rather than
  faked. Restoring them needs the view to actually compute them.
- **Complaint resolution time is not reported**, for the same reason.
- **Vehicle fuel consumption is not reported**, for the same reason. What the view *does*
  have is `avg_occupancy_rate`, which is a real operational number, and that is what the
  vehicles report shows now.
- **No scheduled or emailed reports.** Every export is manual.
- **No saved report configurations.** Filters reset on every mount.
