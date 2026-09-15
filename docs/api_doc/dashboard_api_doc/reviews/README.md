# Dashboard · Reviews (التقييمات)

Read-only feed of the office's trip reviews (driver / vehicle / route ratings + comment) with
averages computed in Dart. Individual reviews and comments are **owner-only** on the dashboard
(`DashboardPermission.reviews` is admin-only); the aggregate driver/vehicle averages are public
(read by the client app). Nothing is written from here — reviews are submitted by riders through
`submit_trip_review` (see `../../client_api_doc/trips/`).

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/reviews/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.reviews` = `/reviews`) |
| Cubit | `presentation/cubit/reviews_cubit.dart` (`reviews_state.dart` — averages, distribution) |
| Use cases | `domain/usecases/` (`GetReviewsUseCase` — also used by Home/Business Overview, `WatchReviewsUseCase`) |
| Repo | `data/repositories/reviews_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_reviews_datasource.dart` (`SupabaseReviewsDatasource implements ReviewsDatasource`) |
| Model / entity | `data/models/trip_review_entry_model.dart`, `domain/entities/trip_review_entry.dart`, `reviews_summary.dart` |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| V1 | Reviews (newest 1 500) | `GET trip_reviews?select=<13 cols>&order=created_at.desc&limit=1500` | `GET /api/v1/dashboard/reviews` |
| V2 | Live feed | `.stream(primaryKey:['id']).order('created_at')` on `trip_reviews` | WebSocket `reviews.changed` |

## V1 — `getReviews()` (`supabase_reviews_datasource.dart:21`)

```
GET /rest/v1/trip_reviews
  ?select=id,booking_id,booking_number,client_name,driver_id,driver_name,vehicle_name,route_label,
          driver_rating,vehicle_rating,route_rating,comment,created_at
  &order=created_at.desc&limit=1500
```
`RLS` `trip_reviews_office_read` (`office_id = current_office_id()`, `20260721090200_multi_office_rls.sql:526`).
The denormalised name/label columns are written by `submit_trip_review` at submission time (a later
driver rename does not change history). Ratings are integers 1–5; `route_rating` and `comment` are nullable.
Averages, per-driver/per-vehicle grouping and the rating distribution are Dart-side (`reviews_state.dart`).
No error mapping.

**Proposed .NET:** `GET /api/v1/dashboard/reviews?driverId=&vehicleId=&from=&to=&page=` plus
`GET /api/v1/dashboard/reviews/summary` (averages by driver/vehicle/route) computed in SQL.

## V2 — `watchReviews()` (line 35)

`SUPABASE-SPECIFIC` CDC stream of the whole (RLS-scoped) table, re-mapped on every change. The code
comment about "anon role" predates the auth gate — the dashboard is authenticated today.

## Notes for the .NET team

1. `submit_trip_review` (client RPC) also refreshes `offices.rating` / `drivers.rating` / `vehicles.rating`
   via `refresh_office_rating_trigger` — keep the aggregate columns if the marketplace keeps showing them.
2. There is no reply/moderation action on the dashboard; a review is immutable once submitted.
