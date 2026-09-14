# Client · Seat Release

A subscriber's "release my seat for a day" hub: the active package summary, upcoming bookings to
release from, and this month's release stats. **Read-only today** — the "Release seat" button is
disabled (`onPressed: null`, tooltip `seatRelease_actionUnavailable`) because no backend operation
exists for it. Nothing in the app navigates to this route except the router entry itself.

## Overview

| Layer | Files (relative to `lib/apps/client/features/seat_release/`) |
|---|---|
| Screen | `presentation/screens/seat_release_screen.dart` (route `SeatReleaseRoutes.seatRelease`) |
| Cubit | `SeatReleaseCubit` (`presentation/cubit/seat_release_cubit.dart`) |
| Use case | `GetSeatReleaseDataUseCase` |
| Repo | `data/repositories/seat_release_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_seat_release_datasource.dart` (`getSeatReleaseData()`, line 14) |
| Entity | `domain/entities/seat_release_data.dart` (`SeatReleaseData`, `UpcomingTrip`, `PastRelease`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| R1 | Load the hub (3 parallel reads) | `GET subscriptions`, `GET operation_bookings` ×2 | session | `GET /api/v1/me/seat-release` |
| — | Release a seat | **does not exist** | — | `NOT IMPLEMENTED` — `NEEDS BACKEND DECISION` |

---

## R1 — `getSeatReleaseData()` (`supabase_seat_release_datasource.dart:14-90`)

Signed-out ⇒ the empty payload (`packageStatus = 'No subscription'`). `today` = local `yyyy-MM-dd`; `monthStart` = first of the month.

```
GET /rest/v1/subscriptions?select=package_name,route_name,start_date,end_date,status
    &client_id=eq.<uid>&status=eq.active&order=created_at.desc&limit=1                         (maybeSingle)

GET /rest/v1/operation_bookings?select=id,trip_date,trip_time,route,seat,status,assigned_trip
    &client_id=eq.<uid>&status=in.(reserved,confirmed,boarded)&trip_date=gte.<today>
    &order=trip_date.asc&limit=10

GET /rest/v1/operation_bookings?select=id
    &client_id=eq.<uid>&status=eq.cancelled&trip_date=gte.<monthStart>
```

Result (`SeatReleaseData`):

| Field | Source |
|---|---|
| `packageName`, `packageRoute`, `startDate`/`endDate` (`d/M/yyyy`), `packageStatus` (`'Active'` / `'No subscription'`), `remainingDays` (days to `end_date`, ≥0) | subscription row |
| `packageType` | constant `'Subscription package'` |
| `upcomingTrips[]` → `UpcomingTrip { id, date ('Today'/'Tomorrow'/'Mon 3/9'), pickup, destination (split `route` on '→'), departureTime=trip_time, vehicle=assigned_trip, seatNumber=seat }` | bookings |
| `releasedSeatsThisMonth` | count of cancelled bookings dated this month |
| `successfullyRebookedSeats`, `totalCompensationEarned` | constants `0` (no backend concept) |
| `reasons[]` | constant list: Personal plans, Working from home, Vacation, Alternative transport, Medical reason, Other |
| `pastReleases[]` | constant `[]` |

`RLS`: `subscriptions_client_read`, `bookings_client_read`.

**Proposed .NET:** `GET /api/v1/me/seat-release` returning the shape above — or fold the two live
pieces (active subscription = `packages/K3`; upcoming bookings = `home/H1c`) and retire this screen.

## Notes for the .NET team

1. There is **no release/rebook/compensation model in the database**. The screen renders placeholders for them. `NEEDS BACKEND DECISION`: whether the feature ships; if so it needs a `seat_releases` model and a "release day" operation that returns a package ride and frees the seat.
2. `assigned_trip` is read as the vehicle label; it is a legacy column and is usually null.
