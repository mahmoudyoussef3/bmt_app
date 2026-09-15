# Captain · Trip Status Updates ("report to operations")

**Not** the trip lifecycle (that is `../trip_execution/`). This is a narrative log: the captain taps one
of three situational updates and the app appends a `trip_events` row with a fixed Arabic title. The
dashboard's trip timeline and the rider's tracking screen read those titles as strings.

## Overview

| Layer | Files (relative to `lib/apps/captain/features/trip_status_updates/`) |
|---|---|
| Screen | `presentation/pages/status_update_page.dart` (route `CaptainRoutes.statusUpdate = /captain/trip/status`, argument `tripId`; opened from the trip screen tools `trip_execution_tools.dart:37`). Offers **only** `headingToPickup`, `arrivedPickup`, `arrivedDestination` (`_reportableStatuses` :17-21) |
| Cubit | `TripStatusUpdateCubit` (`presentation/cubit/trip_status_update_cubit.dart` — `update(tripId, status)` :14-25) |
| Use case | `UpdateTripStatusUseCase` (`domain/usecases/update_trip_status_usecase.dart` — imported as `status_updates.` in DI to avoid the name clash with trip_execution) |
| Repo | `data/repositories/trip_status_repository_impl.dart` |
| **Datasource** | `data/datasources/trip_status_datasource.dart` |
| Model / entity | `data/models/trip_status_model.dart` → `domain/entities/captain_trip_status.dart` (`CaptainTripStatus`, `CaptainTripStatusUpdate`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| U1 | Append a narrative event | `POST trip_events` | session (captain) | `POST /api/v1/captain/trips/{tripId}/events` |

---

## U1 — `updateStatus(tripId, status)` (`trip_status_datasource.dart:11-24`)

```
POST /rest/v1/trip_events
{ "trip_id":     "<uuid>",
  "title":       "<see table>",
  "description": "<see table>",
  "done":        false,                     ← true only for `completed`, which the UI never offers
  "event_time":  "2026-09-15T07:42:11.000Z" }   ← device clock, UTC
→ 201
→ 4xx PostgrestException (raw)
```
`event_code` is not sent ⇒ column default `'other'`.

| `CaptainTripStatus` | `title` (exact) | `description` | Offered by the UI |
|---|---|---|---|
| `headingToPickup` | `السائق في الطريق` | `أبلغ السائق أنه في الطريق إلى نقطة الانطلاق.` | ✅ |
| `arrivedPickup` | `وصل السائق لنقطة الانطلاق` | `أبلغ السائق بالوصول إلى نقطة الانطلاق.` | ✅ |
| `boarding` | `صعود الركاب` | `بدأ السائق استقبال وصعود الركاب.` | ❌ (enum only) |
| `departed` | `غادرت الرحلة` | `أبلغ السائق بانطلاق الرحلة.` | ❌ |
| `arrivedDestination` | `وصلت الرحلة للوجهة` | `أبلغ السائق بالوصول إلى الوجهة.` | ✅ |
| `completed` | `اكتملت الرحلة` | `أبلغ السائق باكتمال الرحلة.` | ❌ |

**These titles are load-bearing** on the rider side: the client's tracking state inference
(`../../client_api_doc/tracking/README.md`, `TrackingStateModel.resolve`) reads the newest event title
and maps `السائق في الطريق` ⇒ *driver on way*, `وصل السائق لنقطة الانطلاق` ⇒ *boarding*,
`غادرت الرحلة` ⇒ *in progress*, `وصلت الرحلة للوجهة` / `اكتملت الرحلة` ⇒ *completed* — but only when
the trip's real `status` is not already decisive. Change a string here and the rider's screen changes.

`RLS` `trip_events_captain_append` (`20260728120000_captain_authority.sql:100-115`): INSERT allowed
on the caller's own trips **provided `event_code NOT IN (trip_published, boarding_started,
trip_departed, trip_completed, trip_cancelled)`** — the five lifecycle codes are reserved for
`update_trip_status`, so a captain cannot forge a departure. Read: `trip_events_captain_read`. No
captain UPDATE/DELETE — append-only.

Not gated on trip status; no notification fires.

**Proposed .NET:** `POST /api/v1/captain/trips/{tripId}/events { kind: "heading_to_pickup" | "arrived_pickup" | "arrived_destination" }`
→ `201 { id, eventCode, title, eventTime }`. Let the **server** own the title strings and stamp a typed
`event_code` (e.g. `captain_heading_to_pickup`), and have the rider app switch to codes — the Arabic
titles-as-enum are a known gap (`event_code` memory note).

## Notes for the .NET team

1. This is distinct from the station-arrival marker `وصول محطة`, which the app **no longer writes**
   (it is written by `captain_arrive_station`) — do not let the port re-open a client-written path
   for it.
2. `event_time` is the device clock; the table also has server `created_at`. Readers on the dashboard
   sort by `event_time desc`. Prefer server time in the port.
3. Three of the six enum values are dead UI-side; only the three ✅ rows need an endpoint variant.
