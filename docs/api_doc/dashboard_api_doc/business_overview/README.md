# Dashboard · Business Overview (نظرة تنفيذية)

The owner's executive tab: how the business is performing (day-over-day trends for revenue,
bookings, trips, occupancy, wallet movement), what needs the owner (health flags, pending refunds,
wallet liability, open incidents), and the fleet summary — over one selectable period. Like Home it
is a **composition root with no datasource**: `BusinessOverviewCubit` runs eleven use cases from
other features, each loaded tolerantly, and derives everything in `BusinessOverview`. It replaced
the never-linked `/owner-overview` screen (2026-08-31 rebuild onto Home's page plan).

## Overview

| Layer | Files |
|---|---|
| Screen | `lib/apps/dashboard/features/business_overview/presentation/screens/` (`DashboardRoutes.businessOverview` = `/business-overview`) |
| Cubit | `presentation/cubit/business_overview_cubit.dart` (`load()` → `_fetch(showSpinner)`; per-feed `onError` keeps the page alive) |
| Entities | `domain/entities/business_overview.dart`, `business_metric.dart` (`MetricTrend`, `TrendDirection`), `business_health.dart` |
| Permission | `DashboardPermission.businessOverview` (admin only) |

## The eleven feeds

| Feed | Use case | Documented in |
|---|---|---|
| Trips | `GetOperationTripsUseCase` | `trips/` T1 |
| Bookings | `GetOperationBookingsUseCase` | `bookings/` B1 |
| Revenue metrics | `GetRevenueMetricsUseCase` | `finance/` N2 |
| Fleet workspace | `GetFleetWorkspaceUseCase` | `fleet/` F1 |
| Captain requests | `GetCaptainRequestsUseCase` | `captain_requests/` Q1 |
| Reviews | `GetReviewsUseCase` | `reviews/` V1 |
| Tickets | `GetTicketsUseCase` | `tickets/` K1 |
| Subscriptions | `GetSubscriptionsUseCase` | `subscriptions/` S1 |
| Refund requests | `GetRefundRequestsUseCase` | `finance/` N3 |
| Wallet position | `GetWalletPositionUseCase` | `finance/` N5 (`office_wallet_overview` + 2 reads) |
| Live ops snapshot | `GetLiveOpsSnapshotUseCase` | `live_ops/` L1 + L2 + L4 |

## Derivations and the honesty rules

* Series are 7 daily buckets (`revenueWeek`, `bookingsWeek`, `tripsWeek`, `occupancyWeek`, `walletWeek`);
  "today" = last bucket; `MetricTrend` = day-over-day delta and ratio; **a trend is never invented** —
  when the loaded window does not cover both days (`earliestLoadedBookingDay`, `loadedBookings` vs the
  2 000 cap) the trend is `null` and the tile says so.
* `tripsRunningNow / tripsUpcomingToday / tripsCompletedToday / tripsCancelledToday` from today's trips by status.
* `fleetUtilisation` = vehicles on a duty / active vehicles; `vehiclesInMaintenance`; `activeDrivers`.
* `openIncidents` from Live Ops; `pendingRefundAmount` from refund requests (`pending`); `walletLiability`
  = `office_wallet_overview.outstanding_balance`.
* `BusinessHealth.needsAttention` aggregates the flags (stale open trips, payments waiting, refunds pending,
  license attention).
* Every feed loads tolerantly; one failing panel must not blank the page; KPIs on an overview are never foldable.

## Proposed .NET

`GET /api/v1/dashboard/overview?period=7d` → one document with the series and the attention block,
computed server-side with the same counting rules as the modules (revenue = approved bookings + collected
subscriptions; occupancy from seats; wallet from the ledger). `BACKEND RECOMMENDATION`.
