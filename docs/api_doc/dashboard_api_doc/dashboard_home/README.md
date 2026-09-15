# Dashboard · Home (الرئيسية)

The operator's landing console: today's trips and occupancy, today's bookings, revenue KPIs,
fleet counts, the attention queues (payments to review, captain requests, open tickets, low
ratings), and this week's sparklines. **It has no datasource of its own** — `DashboardHomeCubit`
is a composition root over eight use cases from other features, so every number on Home equals
the number on the corresponding module for the same office. Each feed is guarded individually; a
failed feed is *named* on the page and only "nothing answered" is an error.

## Overview

| Layer | Files |
|---|---|
| Screen | `lib/apps/dashboard/features/dashboard_home/presentation/screens/` (`DashboardRoutes.home` = `/`) |
| Cubit | `presentation/cubit/dashboard_home_cubit.dart` (`load()` — 8 guarded futures started in parallel) |
| Entity | `domain/entities/dashboard_home_summary.dart` (`DashboardHomeSummary` — every derivation) |
| Frame | `core/widgets/dashboard_page_body.dart` etc. (shared with Live Ops) |
| Permission | none (every role lands here) |

## The eight feeds it issues on every visit

| Feed | Use case | Actual backend call (documented in) | Volume |
|---|---|---|---|
| Trips | `GetOperationTripsUseCase` | `trips/` T1 — 1 500 trips **with seats, passengers, route points, events embedded** | heaviest |
| Bookings | `GetOperationBookingsUseCase` | `bookings/` B1 — 2 000 bookings with trip/route/driver/vehicle/package | heavy |
| Revenue | `GetRevenueMetricsUseCase` | `finance/` N2 — two uncapped column scans | medium |
| Fleet | `GetFleetWorkspaceUseCase` | `fleet/` F1 — 7 reads incl. 12 months of trip history | heavy |
| Captain requests | `GetCaptainRequestsUseCase` | `captain_requests/` Q1 — all rows | light |
| Reviews | `GetReviewsUseCase` | `reviews/` V1 — 1 500 rows | light |
| Tickets | `GetTicketsUseCase` | `tickets/` K1 — 1 000 rows (+ `user_roles`) | light |
| Subscriptions | `GetSubscriptionsUseCase` | `subscriptions/` S1 — expire RPC + 1 500 rows | medium |

Plus the shell's own subscriptions (alerts bell, entitlement realtime) — see `notifications/`, `../README.md` §2.

## What `DashboardHomeSummary` derives (the counting rules the backend aggregate must reproduce)

* **Today's trips** = trips with `trip_date == today` (local); `todayOccupancyRate` = Σ booked seats
  (state ≠ available/blocked) / Σ capacity over today's trips.
* **Today's bookings** = bookings `created_at` on today (local).
* **Pending payment reviews** = bookings with `payment_status ∈ {submitted, underReview}` and status not cancelled.
* **Pending captain requests** = `status = 'pending'`.
* **Open tickets** = tickets not `resolved|closed|rejected`.
* **Fleet** counts from the workspace (active drivers/vehicles, active duties).
* **Sparklines** (`tripCountsThisWeek`, `bookingCountsThisWeek`, `occupancyThisWeek`) — 7 daily buckets ending
  today, **each computed with exactly the same rule as its tile** (a series counted differently from its
  number above it is a defect this project already fixed once).
* `unavailable` = names of feeds that failed; `isEmptyShell` = every feed failed.

## Proposed .NET

`GET /api/v1/dashboard/home` → one pre-computed document:
```
{ today: { trips, occupancyRate, bookings, revenue }, week: { trips[7], bookings[7], occupancy[7] },
  revenue: { today, week, month, activeSubscriptions },
  fleet: { activeDrivers, activeVehicles, activeDuties },
  attention: { paymentsToReview, captainRequestsPending, ticketsOpen, lowRatings },
  unavailable: [] }
```
computed by SQL aggregates with the rules above. This is the single highest-value backend change
available: one Home visit today issues ~15 requests pulling tens of thousands of rows to render a page of
counters. `BACKEND RECOMMENDATION` (consistent with `docs/API_DOCUMENTATION.md` §10.1).
