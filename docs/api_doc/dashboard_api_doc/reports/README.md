# Dashboard · Reports (التقارير)

Seven reports (revenue, trips, bookings, drivers, vehicles, subscriptions, complaints) with KPIs,
rows, and trend series, plus PDF/Excel/CSV export. Four reports read **SQL views** (lifetime
roll-ups, no date range); three read base tables and are genuinely period-bounded. All the
aggregation is done in Dart from raw rows.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/reports/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.reports` = `/reports`) |
| Cubit | `presentation/cubit/reports_cubit.dart` |
| Use cases | `domain/usecases/` (`GetReportDataUseCase`, `GetReportFilterOptionsUseCase`, `ExportReportUseCase`) |
| Repo | `data/repositories/reports_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_reports_datasource.dart` (`SupabaseReportsDatasource implements ReportsDatasource`) |
| Export | `data/services/report_export_service.dart` (`LicensedExport.consume(format)` then PDF/Excel/CSV built in Dart) |
| Entities | `domain/entities/report_entities.dart` (`ReportType`, `ReportFilter { startDate, endDate, routeCode?, driverName?, vehiclePlate?, packageName? }`, `ReportData { kpis, rows, trends, occupancyTrends }`, row types) |
| Permission | `DashboardPermission.reports` (both roles); feature key `reports` (also enforced **inside three views** via `office_licensed('reports')`); `export_pdf` / `export_excel` + `max_exports_per_month` on export |

## Operations

| # | Report / operation | Today (Supabase) | Period-bounded? | Proposed .NET |
|---|---|---|---|---|
| P1 | Revenue | `GET revenue_daily_view?report_date=gte.&lte.&order=report_date` + P2's trips (for occupancy) | yes (`created_at` day, UTC) | `GET /api/v1/dashboard/reports/revenue?from=&to=` |
| P2 | Trips | `GET operation_trips?select=…,seats:trip_seats(state)&trip_date=gte.&lte.` + `GET operation_bookings?select=trip_id,payment_amount,status&trip_id=in.(…)` | yes (`trip_date`) | `GET /api/v1/dashboard/reports/trips?…` |
| P3 | Bookings | `GET operation_bookings?select=…,trip:operation_trips(trip_code,route:operation_routes(name))&created_at=gte.&lte.&order=created_at.desc` | yes | `GET /api/v1/dashboard/reports/bookings?…` |
| P4 | Drivers | `GET drivers_performance_view` | **no** (lifetime) | `GET /api/v1/dashboard/reports/drivers` |
| P5 | Vehicles | `GET vehicles_efficiency_view` | **no** | `GET /api/v1/dashboard/reports/vehicles` |
| P6 | Subscriptions | `GET subscriptions?select=package_name,status,total_price,renewals_count` | **no** (all rows) | `GET /api/v1/dashboard/reports/subscriptions` |
| P7 | Complaints | `GET complaints_summary_view` | **no** | `GET /api/v1/dashboard/reports/complaints` |
| P8 | Filter option lists | `GET operation_routes?select=name`, `GET drivers?select=full_name`, `GET vehicles?select=plate_number`, `GET subscriptions?select=package_name` (distinct in Dart) | — | `GET /api/v1/dashboard/reports/filters` |
| P9 | Export | `POST rpc/office_consume_export {p_kind}` → file built client-side | — | `POST /api/v1/dashboard/exports` |

All reads are unbounded and office-scoped by RLS / the views' own `current_office_id()` predicate.
No error mapping in this datasource. Dimension filters (route / driver / vehicle / package) are applied
**in Dart by exact string match on names**, not by id.

---

## P1 — Revenue (`_revenueReport` line 67)

`revenue_daily_view` (`20260721100100_report_views_office_scoping.sql`):
`report_date = (created_at at time zone 'UTC')::date`, `total_bookings = count(*)`,
`total_bookings_revenue = Σ payment_amount where status not in (rejected, cancelled)`, grouped per office/day.
**Diverges from Finance** (which counts only `payment_status = 'approved'`) — a documented, still-open
divergence; the .NET report should adopt Finance's rule. KPIs: total, count, average per booking, average per
day. Subscriptions and refunds are hard-coded to 0 in the rows.

## P2 — Trips (`_tripsReport` line 118, `_fetchTrips` line 473, `_revenueByTrip` line 498)

Trips in `[start, end]` by `trip_date` (plain calendar days, never UTC-shifted) with route/driver/vehicle
names and `seats(state)`; booked = seats with `state != 'available'` (so `blocked` counts as booked);
revenue per trip = Σ `payment_amount` of that trip's bookings whose **booking `status` ∈ {approved,
confirmed, completed}** (`operation_trips.revenue` is dead — never read it). KPIs: count, completed,
occupancy = passengers/capacity, revenue. `trends` = top-7 routes by revenue; `occupancyTrends` = mean
occupancy % per route.

## P3 — Bookings (`_bookingsReport` line 190)

Bookings created in the period; `earned` when booking `status ∈ {approved, confirmed, completed}`
(note: `approved` is not a booking status — harmless), `rejected` counts `rejected|cancelled`;
`trends` = earned amount by raw `payment_method` string (unnormalised, unlike Finance).

## P4 / P5 / P7 — the licensed views (`20260808090000_licensing_enforcement_completion.sql`)

* `drivers_performance_view`: `driver_id, office_id, name, status, completed_trips, total_revenue` —
  **`total_revenue` sums `operation_trips.revenue`, which is never maintained → always 0.** `RETIRED`-ish figure.
* `vehicles_efficiency_view`: `vehicle_id, office_id, plate_number, model, status, completed_trips,
  avg_occupancy_rate (from operation_trips.occupancy_rate — also unmaintained), maintenance_status
  ('جاهزة'|'تحتاج صيانة'|'غير متاحة')`. Dart normalises occupancy > 1 as a percentage.
* `complaints_summary_view`: per `category` of **`operation_complaints`** (the legacy complaints table,
  not `support_tickets`): `total_complaints, resolved_complaints (resolved|closed), pending_complaints`.

All three: `where office_id = current_office_id() and office_licensed('reports') or is_platform_admin()` —
an unlicensed office gets **empty rows, not an error** (`SUPABASE-SPECIFIC` view-level gate).

## P6 — Subscriptions (`_subscriptionsReport` line 406)

All `subscriptions` rows (RLS-scoped) grouped by `package_name`: active/expired counts, `Σ total_price`
(**invoiced, not collected** — Finance uses `paid_amount`), renewals.

## P9 — Export

`ReportExportService` → `LicensedExport.consume('pdf'|'excel'|'csv')` → `office_consume_export` (asserts
`export_pdf` / `export_excel`, consumes `max_exports_per_month`) → file rendered in Dart from `ReportData`.

## Notes for the .NET team

1. Rebuild each report as a SQL aggregate endpoint with `from/to` and **id-based** dimension filters;
   the current Dart aggregation over unbounded raw rows is the second-heaviest read pattern after Home.
2. Fix the three dead figures (`operation_trips.revenue`, `occupancy_rate`, drivers' `total_revenue`) by
   deriving from bookings/seats — as P2 already does for trips.
3. Align revenue rules with Finance (`payment_status = 'approved'`, `paid_amount` for subscriptions) —
   one definition, both screens.
4. `complaints_summary_view` reads `operation_complaints`, while the Tickets module works `support_tickets`;
   decide which is the support system of record.
