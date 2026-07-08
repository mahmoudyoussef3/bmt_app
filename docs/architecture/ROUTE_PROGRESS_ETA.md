# Smart Route Progress & ETA System

## Purpose

Turn raw captain GPS fixes plus the trip's stop list into a trustworthy,
passenger-grade progress story: how far along the route the bus is, the visit
state of every stop, when the bus reaches each stop (including *the rider's
own pickup*), and honest degradation when the data gets bad. One pure-Dart
engine, shared by the Client tracking screen and the Dashboard live
monitoring panel, layered on top of the Live Vehicle Tracking Engine
(`docs/architecture/LIVE_TRACKING_ENGINE.md`).

## Ownership & data flow

The Dashboard remains the source of truth for trips. The engine only *infers
presentation state* from data the Dashboard already owns — it never mutates
operational state. Operator- **and captain**-logged station arrivals (trip
events, title `'وصول محطة'`) always act as a floor under GPS inference. The
counting/clamping logic for that floor lives in one place —
`lib/core/tracking/progress/arrival_events.dart`
(`countStationArrivalEvents` / `stationArrivalFloor`) — reused by the
Dashboard live-trips datasource, the Client tracking datasource/cubit, and
the Captain assigned-trips datasource + trip-execution flow, so all three
apps agree on how many stations have actually been visited.

```
trip_route_points (name, order, lat/lng, arrival_offset "HH:mm")
operation_trips   (status, trip_date, departure/arrival_time)
trip_passengers   (pickup_point_name, status)          — passenger flow
trip_live_locations (lat, lng, speed, recorded_at)     — via Realtime
        │
        ▼
RouteProgressEngine (lib/core/tracking/progress/)
  validate → project onto polyline → advance stop states → estimate ETAs
        │
        ├── Client  TrackingCubit → TrackingLoaded.progress (snapshot)
        │     ├── TrackingEtaPanel        (hero ETA + route progress bar)
        │     ├── TrackingStopsTimeline   (per-stop states/ETAs, animations)
        │     └── TrackingLiveMap         (split polyline, state markers)
        └── Dashboard SupabaseLiveTripsDatasource._withSmartProgress
              └── LiveTrip (progressPercent, point statuses, per-stop ETA,
                            waiting/boarded counts, expectedArrivalTime)
```

## Modules — `lib/core/tracking/progress/` (pure Dart, no Flutter)

| File | Responsibility |
| --- | --- |
| `arrival_events.dart` | Shared `trip_events` arrival-floor logic: `kStationArrivalEventTitle`, `countStationArrivalEvents`, `stationArrivalFloor`. The one place Dashboard, Client, and Captain count "how many stations arrived". |
| `route_stop.dart` | Stop value object (coords, order, planned arrival/departure). |
| `route_geometry.dart` | Polyline math: cumulative distances, projection of a GPS point onto the route (along-track + cross-track), forward-biased matching so loop routes can't snap the bus backwards. |
| `eta_estimator.dart` | Distance → arrival time. Speed priority: live GPS (blended 70/30 with reference pace) → trip's observed average → schedule pace → 35 km/h fallback; clamped to [12, 90] km/h; +45 s dwell per intermediate stop. |
| `stop_progress.dart` | Vocabulary: `TripProgressPhase` (headingToPickup/boarding/enRoute/completed), `StopVisitStatus` (upcoming/next/arrived/departed), `EtaConfidence` (live/estimated/scheduled/none), per-stop `StopProgress`. |
| `route_progress_engine.dart` | Stateful orchestrator: `addFix` / `updatePhase` / `seedVisited` → `snapshot(now)`. Injected clock ⇒ deterministic tests. |
| `route_progress_snapshot.dart` | Render-ready output: route fraction, traveled/remaining meters, per-stop states + ETAs, next stop, off-route/stale flags, `stopByName` for pickup lookup. |
| `route_progress_config.dart` | Tunables (radii, thresholds, speeds, dwell, stale window). |

## Stop state machine

`upcoming → arrived → departed`, monotonic, with radius hysteresis:

* **arrived** — within 150 m of the stop.
* **departed** — an arrived stop must be left by > 250 m (jitter at a station
  cannot flap states), or the along-route position clears the stop by 300 m
  (`passedStopSlackMeters`) when the bus rolled through without a dwell fix.
* **next** — derived: the first unvisited stop.
* Before the trip starts (`headingToPickup`/`boarding`) only arrival at the
  origin is watched; route progress stays 0.

## ETA semantics

Every ETA carries its provenance so the UI never lies:

* `live` — fresh GPS, vehicle moving.
* `estimated` — fresh GPS but dwelling; pace inferred from trip history /
  schedule.
* `scheduled` — no usable GPS (none yet, stale > 2 min, or off-route): the
  published per-stop plan (`arrival_offset` against `trip_date`) is shown and
  labeled as such.
* `none` — nothing to estimate from.

Before departure, the ETA to the origin uses straight-line distance × 1.3
(road indirectness) since the driver's approach path is unknown.

## Edge cases handled

| Case | Behavior |
| --- | --- |
| No GPS yet | Schedule-based ETAs, progress 0, "based on schedule" caption. |
| Stale GPS (> 2 min) | Progress freezes, ETAs degrade to schedule, stale flag. |
| Off-route (> 500 m cross-track) | Progress/states freeze, detour caption; resumes on return. |
| Backwards GPS jitter | Along-track is monotonic; stop states never regress. |
| Loop / out-and-back routes | Forward-biased projection (200 m backtrack tolerance). |
| Rolled past a stop between sparse fixes | `passedStopSlackMeters` marks it departed. |
| Stop coordinates missing/(0,0) | Filtered from geometry; dashboard keeps event-based status for them. |
| < 2 valid stops | Engine degrades gracefully (no fraction, no crash). |
| Dwell at a station (speed ≈ 0) | ETA falls back to trip average/schedule pace — never divides by zero. |
| Midnight-crossing schedules | Stop times ≥ 6 h before departure roll forward a day (client datasource). |
| Trip completed | All stops departed, fraction 1, ETAs cleared. |
| ETA drift between fixes | Client cubit re-emits a snapshot every 30 s. |

## Client app (passenger experience)

* `TrackingTripData` now carries `routeStops` (with planned times) and the
  rider's manifest row (`passengerPickupName`, `passengerStatus`;
  `confirmed` = boarded).
* `TrackingCubit` owns one engine per trip (kept across silent refreshes so
  states stay monotonic), feeds Realtime fixes, maps trip states to phases,
  and runs the 30 s ETA ticker. On every load/refresh it also seeds the
  engine with `stationArrivalFloor(data.arrivalEventCount, routeStops.length)`
  — the same captain-reported arrival count the Dashboard uses — so a
  captain marking a station arrived shows up in the rider's stop timeline
  immediately over the existing `trip_events` Realtime subscription, with no
  GPS fix required.
* **TrackingEtaPanel** — counts down to the *rider's pickup stop* until they
  board, then to the destination; shows the route progress bar (% / km left /
  stops ahead) and a confidence caption.
* **TrackingStopsTimeline** — per-stop dots that animate on arrival
  (check scale-in), per-stop ETAs, "You board here / Boarded / Stop passed"
  chip.
* **TrackingLiveMap** — polyline split into covered (green) and ahead
  (primary); per-stop markers follow visit state, with a pulsing halo on the
  stop the bus is at.

## Dashboard (operations)

`SupabaseLiveTripsDatasource._withSmartProgress` runs after vehicle positions
attach: operator arrival events seed the engine (`seedVisited`), the latest
fix advances it, and the snapshot updates `progressPercent` (continuous, not
just event count), per-point statuses, per-stop `estimatedArrival`, and
`expectedArrivalTime`. Fix timestamps are used as receipt time so hours-old
rows read as stale and fall back to the schedule. `_mapToLiveTrip` now also
fills per-stop **passenger flow** (`waitingPassengersCount` /
`boardedPassengersCount` from `trip_passengers.pickup_point_name`), which the
route timeline in `live_monitoring_panel.dart` already displays, plus an
Arabic ETA line per pending/current stop.

## Captain app (trip execution)

The "تم الوصول للمحطة" (arrived at station) button in `TripExecutionPage`
inserts the same `trip_events` arrival marker via
`TripExecutionCubit.markStationArrived` → `MarkStationArrivedUseCase` →
`TripExecutionRepository` → `TripExecutionDataSource`, matching the
Dashboard's `markPointArrived` convention exactly (title `'وصول محطة'`,
`done: true`). `CaptainTripRemoteDataSource` also computes each assigned
trip's `arrivedStationsCount` via `stationArrivalFloor` so reopening the trip
execution screen resumes at the correct next station instead of resetting to
the first one. This action is deliberately independent of the
board/start/complete trip-status state machine — it never touches
`TripExecutionCubitState`.

## Tests

* `test/core/tracking/progress/arrival_events_test.dart` — arrival-event
  counting and floor clamping.
* `test/core/tracking/progress/route_geometry_test.dart` — distances,
  projection, clamping, loop-route forward bias, untrackable routes.
* `test/core/tracking/progress/eta_estimator_test.dart` — speed blending and
  fallback chain, clamping, dwell, confidences.
* `test/core/tracking/progress/route_progress_engine_test.dart` — schedule
  fallback, pickup approach, boarding arrival, passed-stop departure,
  hysteresis, monotonicity, off-route freeze/resume, staleness, completion,
  event seeding, degraded routes, pickup lookup.

All deterministic: the engine takes `now` per call; tests inject fixed clocks.
