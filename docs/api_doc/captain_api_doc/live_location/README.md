# Captain · Live Location (the GPS publisher)

The producer half of live tracking. The captain's device streams positions; a domain pipeline
validates and throttles them; the cubit publishes one row per accepted fix and adds a heartbeat while
parked. This is the **only writer** of `trip_live_locations` on the platform. Reproduce the numbers
exactly — they are derived, not arbitrary.

## Overview

| Layer | Files (relative to `lib/apps/captain/features/live_location/`) |
|---|---|
| UI | `presentation/widgets/trip_location_auto_share.dart` (`TripLocationAutoShare(tripId, enabled)` — starts/stops the publisher from the trip screen; status card with "retry now") |
| Cubit | **`LiveLocationCubit`** (`presentation/cubit/live_location_cubit.dart`) — registered as an **app-lifetime lazy singleton** (`captain_di.dart:_registerLiveLocationDependencies`) so publishing follows the *trip*, not the screen. `startAutoSharing(tripId)` :89-120, `stopAutoSharing({tripId})` :124-129, `send(tripId)` :86-87 (manual retry), `resumeIfStale()` :133-145 (on app resume) |
| Use cases | `WatchPublishableLocationUseCase` (`domain/usecases/watch_publishable_location_usecase.dart` — GPS stream → `ValidFixFilter` → `LatestValueThrottle(10 s)`), `PublishTripLocationUseCase`, `SendLocationUpdateUseCase` |
| Repo | `data/repositories/location_repository_impl.dart` |
| **Datasources** | `data/datasources/supabase_location_datasource.dart` (the write), `device_gps_datasource.dart` (Geolocator stream / single fix / permissions), interface `location_datasource.dart` |
| Model / entity | `data/models/location_sharing_model.dart` (`LocationUpdateModel`) → `domain/entities/location_sharing_state.dart` (`LocationUpdateData`), `location_sharing_health.dart` (`LocationSharingStatus.evaluate` — live / acquiring / stale / off) |
| Shared config | `lib/core/tracking/live_tracking_config.dart` (`kLiveTrackingConfig`), `lib/core/tracking/vehicle_fix.dart`, `fix_validator.dart`, `tracking_config.dart` (`defaultMaxAccuracyMeters = 100`) |
| Kill-switch | `CaptainOfficeSession.identity.licensing.liveTracking` (`live_location_cubit.dart:63-64`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| G1 | Resolve the trip's vehicle (once per trip) | `GET operation_trips?select=vehicle_id&id=eq.&driver_id=eq.` | session (captain) | dropped — server derives it |
| G2 | Publish a fix | `POST trip_live_locations` | session | `POST /api/v1/captain/trips/{tripId}/locations` |

---

## When it runs (`trip_execution_page.dart:100-104`, `trip_location_auto_share.dart:79-89`)

* `enabled = stage.isLive` (`boarding` or `underway`). On enable: `startAutoSharing(tripId)`; on
  disable or trip change: `stopAutoSharing(tripId: previous)`. Backing out of the trip screen does
  **not** stop it (singleton; `wantKeepAlive`); sign-out does (`main.dart:129`).
* `startAutoSharing` is refused outright when `licensing.live_tracking == false` (:90) and `send()` is a
  no-op (:86-87) — the office's SaaS licence, resolved by `captain_session_context` (`../auth/` A4).
* Pipeline (`live_location_cubit.dart:24-39`):
  ```
  GPS stream (distanceFilter 10 m, high accuracy)
    ─▶ ValidFixFilter        drops: invalid coords / (0,0), accuracy > 100 m, out-of-order timestamp,
    │                                implausible jump (speed > TrackingConfig.maxPlausibleSpeedMps)
    ─▶ LatestValueThrottle   trailing, latest wins, floor 10 s between publishes
    ─▶ publishFix(tripId, fix)                                      (movement-driven)
  heartbeat Timer 30 s ─▶ if nothing published in the window: currentPosition() (20 s time limit) ─▶ publishFix
  ```
  First fix is sent immediately on start. One send in flight at a time (`_sending`); a run of failures
  is counted (`consecutiveFailures`, shown at ≥ 2) but never interrupts the captain. `resumeIfStale()`
  sends immediately when the app comes back from background and the last send is older than 30 s
  (Dart timers do not survive iOS suspension).

| Constant (`LiveTrackingConfig`) | Value | Why |
|---|---|---|
| `publishInterval` | **10 s** | marker engine renders ≤ 6 s gaps as motion; a bus at 80 km/h crosses a 300 m stop radius in 13.5 s, so 10 s lands a fix inside it |
| `heartbeatInterval` | **30 s** | distance filter means a parked bus emits nothing; heartbeat distinguishes "parked" from "GPS died" |
| `distanceFilterMeters` | **10 m** | suppress standing-still jitter |
| `minimumAccuracyMeters` | **100 m** | shared with the consumer; a fix the client would reject is never written |
| `staleAfter` (consumer) | 45 s | client-side; not a multiple of 10 s on purpose |

---

## G1 — Vehicle lookup: `_vehicleFor(tripId, driverId)` (`supabase_location_datasource.dart:72-94`)

Cached per trip after the first publish (`_cachedTripId/_cachedVehicleId`).

```
GET /rest/v1/operation_trips?select=vehicle_id&id=eq.<tripId>&driver_id=eq.<driverId>   (.maybeSingle())
→ 200 { "vehicle_id": "<uuid>" } | null
```
Null (trip not the caller's, or no vehicle assigned) ⇒ `Exception('لا يمكن إرسال الموقع: لم يتم تعيين
سائق ومركبة لهذه الرحلة.')`. The driver id comes from `CaptainIdentityProvider.driverId()` (null ⇒
*"لا يمكن إرسال الموقع: لم يتم التعرف على السائق."*).

**Proposed .NET:** none — the server resolves the vehicle from the trip's assignment.

---

## G2 — Publish: `publishFix(tripId, fix)` (`supabase_location_datasource.dart:41-70`)

```
POST /rest/v1/trip_live_locations
{ "trip_id":     "<uuid>",
  "driver_id":   "<uuid>",            ← sent because the column is NOT NULL; the server OVERWRITES it
  "vehicle_id":  "<uuid>",            ← from G1
  "latitude":    30.0512,             ← degrees
  "longitude":   31.2611,
  "accuracy":    8.0,                 ← metres (horizontal, 68 %), may be null
  "heading":     118.4,               ← degrees clockwise from north; null when the sensor reported < 0
  "speed":       12.5,                ← metres/second; null when < 0
  "recorded_at": "2026-09-15T07:42:11.000Z" }   ← DEVICE timestamp, converted to UTC
→ 201 (no representation requested)
→ 4xx PostgrestException  (raw message surfaced on the card; counted as a failure)
```

**App reads:** nothing; on success the card shows `recorded_at` (local) as "آخر إرسال".

`RLS` + `BUSINESS RULE`:
* Policy `trip_live_locations_captain_publish` (`20260729090000_tracking_authority.sql:178-186`):
  INSERT only, `can_publish_trip_fix(trip_id)` = the trip's `driver_id = current_driver_id()`.
  No UPDATE/DELETE policy or grant — a reported position is a fact and cannot be rewritten.
* Trigger `enforce_live_location_authorship` (`20260728120000_captain_authority.sql:259-292`), BEFORE INSERT:
  a signed-in caller must resolve to an active driver (`live_location_requires_captain`);
  **`new.driver_id := current_driver_id()`** regardless of payload; the trip must be that driver's
  (`live_location_not_your_trip`).
* **Not** gated on trip status — the captain may publish for an assigned trip in any state (the app
  only does so while live). `NEEDS BACKEND DECISION`: reject fixes for `completed|cancelled` trips.
* **Not** gated on licensing (deliberate — `20260807140000:253-255`): refusing a moving bus's write
  would become an error dialog; the *read* side is licence-gated instead (`trip_live_locations_read` =
  `can_read_trip_fixes AND trip_tracking_licensed`).
* Realtime fan-out: riders (`location_updates:<tripId>`, `../../client_api_doc/tracking/`), the
  dashboard live board, and the captain's own `captain_trip_execution` channel all consume the INSERT.

`REQUIRES CONFIRMATION` — retention: at 10 s cadence a trip-hour is ~360 rows. A
`prune_trip_live_locations` function exists in the migrations; no schedule is visible in this repo.

**Proposed .NET:** `POST /api/v1/captain/trips/{tripId}/locations`
```json
{ "latitude", "longitude", "accuracy", "heading", "speed", "recordedAt" }
```
→ `201 { recordedAt }`; `403 { code: live_location_not_your_trip }`; `422` when the trip has no
vehicle. Derive `driverId`/`vehicleId` from the token and the trip. Then fan out to the trip's
SignalR group / rider subscribers.

---

## Data shape of `trip_live_locations` (as written by the app)

`id, trip_id, driver_id (server-stamped), vehicle_id, latitude, longitude, accuracy?, heading?, speed?,
recorded_at (device UTC), created_at (server)`. Readers order by `recorded_at desc`.

## Notes for the .NET team

1. Batch uploads do not exist and must not be introduced silently: consumers assume each row is a
   fresh fix ≤ 10 s apart while moving. If you add offline buffering, keep `recorded_at` as the device
   time and let the validator's out-of-order rule drop stale replays.
2. The throttle is **trailing / latest-wins** — a burst of fixes yields the newest one once per window,
   never a queue.
3. The publisher's own health (`live` < 10 s + slack, `stale` beyond) is computed from `lastSentAt`
   locally (`location_sharing_health.dart`); the server needs no "is the captain online" endpoint.
4. `heading`/`speed` nulls come from Geolocator's negative sentinel; keep them nullable, do not coerce to 0.
