# Captain · Trip Map (in-app map — no backend of its own)

`lib/apps/captain/features/trip_map/` renders the captain's own device position on a map with the
route's stops and a "next pickup" panel. **It owns no backend call.** Everything it needs it borrows:

| Concern | Datasource used | Documented in |
|---|---|---|
| Device position stream (display only, distance filter 8 m) | `data/datasources/captain_location_stream_datasource.dart` (Geolocator; `ensureReady()` permission gate) | — local |
| Manifest + live manifest | `GetTripPassengersUseCase`, `WatchTripPassengersUseCase` | `../passenger_manifest/` M1, M2 |
| Board / un-board / absent a rider (`confirmBoarded`, `markPending`, `markAbsent` — `captain_trip_map_cubit.dart:207-241`) | `UpdatePassengerStatusUseCase` | `../passenger_manifest/` M3a / M3b |
| Trip snapshot + change signal | `WatchTripExecutionSnapshotUseCase` | `../trip_execution/` E4 / E5 |
| "Arrived at active pickup" (`markArrivedAtActivePickup` :243-255) | `MarkStationArrivedUseCase` → `captain_arrive_station` | `../station_progress/` S2 |

The **10 s publisher in `../live_location/` remains the sole writer** of positions; this feature's
GPS stream never reaches the database.

`RETIRED` (unreachable): the route `CaptainRoutes.tripMap = /captain/trip/map` is registered in
`captain_app_router.dart:43-46` and `CaptainNav.openTripMap` exists (`captain_nav.dart:19-20`), but
**nothing in the app calls it** — the trip screen deliberately has no map
(`trip_execution_page.dart:26-31`). Do not plan any endpoint for it. ⚠ One trap if it is ever
revived: `markAbsent` (:210) calls `updatePassengerStatus(status: absent)` **without a `noShowReason`**,
which the manifest datasource rejects locally (`noShowNoteRequired`) — it would need the reason sheet.
