# Live Vehicle Tracking Engine

## Purpose

Turn the sparse, noisy GPS fixes that captains send into a smooth, trustworthy
vehicle presentation on every map in the platform: interpolated movement,
heading rotation, estimated speed, GPS accuracy circle, and staleness
signaling. One engine, consumed by the Client tracking screen.

## Ownership & data flow

The Captain App is the producer; the Client App is the consumer. The Dashboard
remains the source of truth for trips — the engine only affects presentation of
location data, never operational state.

```
Captain App (Geolocator one-shot send)
  → trip_live_locations (lat, lng, heading, speed m/s, accuracy m, recorded_at)
    → Supabase Realtime INSERT events
      └── Client tracking feature (TrackingPoint fix → cubit state)
            → VehicleTrackController.addFix(VehicleFix)
              → VehicleTrackingEngine (validate → estimate → interpolate)
                → VehicleSample (per frame) → LiveVehicleLayer (FlutterMap)
```

## Modules

### Pure Dart core — `lib/core/tracking/` (no Flutter imports)

| File | Responsibility |
| --- | --- |
| `vehicle_fix.dart` | Raw GPS fix value object (Geolocator conventions: negative heading/speed = missing). |
| `vehicle_sample.dart` | Render-ready interpolated snapshot (position, heading, km/h, accuracy, stale/moving flags). |
| `tracking_config.dart` | Tunables: accuracy gate, plausibility cap, snap distance, animation window, stale window, smoothing. |
| `geo_math.dart` | Haversine distance, initial bearing, shortest-arc angle lerp, antimeridian-safe longitude lerp, ease-out cubic. |
| `fix_validator.dart` | Drops junk: (0,0) placeholders, out-of-range coords, accuracy > 100 m, out-of-order/replayed events, jumps implying > 55 m/s (~200 km/h). |
| `speed_estimator.dart` | km/h from device speed (m/s) or displacement/Δt fallback; exponential smoothing (α = 0.35). |
| `heading_resolver.dart` | Device heading when moving; path bearing when displacement ≥ 3 m; otherwise holds last heading (parked bus keeps facing where it stopped). |
| `vehicle_tracking_engine.dart` | Orchestrator: `addFix(fix, now:)` → `sample(now)`. Clock is injected per call, so all behavior is deterministic in tests. |

### Flutter bindings — `lib/core/widgets/tracking/`

| File | Responsibility |
| --- | --- |
| `vehicle_track_controller.dart` | `ChangeNotifier` + `Ticker`. The ticker runs **only while an interpolation is in flight**; an idle marker costs zero frames. A 15 s timer re-notifies so staleness badges refresh without animation. |
| `animated_vehicle_marker.dart` | Circular bus badge, orbiting heading wedge, pulse halo, grey stale styling, paused icon when stationary. |
| `live_vehicle_layer.dart` | Drop-in `FlutterMap` layer: accuracy `CircleLayer` (`useRadiusInMeter`) + `MarkerLayer` + optional plate label. Only this subtree rebuilds per frame. |

### Consumers

* **Client** — `apps/client/features/tracking/presentation/widgets/tracking_live_map.dart`
  (route polyline, stop markers, live vehicle layer, camera auto-follow that
  disengages on user pan and re-engages via button, live status strip).
  The realtime datasource now parses heading/speed/accuracy
  (`TrackingPointModel.fromLiveLocationRow`) instead of dropping them.

The Dashboard has no live-monitoring consumer: the `live_trips` module was
removed — trip state is followed in the Trips module (`الرحلات`) instead.

## Engine behaviors

* **Interpolation**: a new fix animates the marker from *wherever it currently
  is* (including mid-animation) to the fix, over the observed inter-fix
  interval clamped to [300 ms, 6 s], eased with ease-out cubic. A fix arriving
  mid-flight never causes a backwards jump.
* **Snap rules**: first fix and jumps longer than 1 km render immediately —
  a vehicle that went dark must not crawl across the map.
* **Heading**: smoothed along the shortest arc (350° → 10° passes through 0°).
* **Speed**: displayed values are km/h (the DB stores m/s; the previous UI
  mislabeled m/s as km/h — fixed via `TrackingTripData.vehicleSpeedKmh`).
* **Staleness**: no fix for 2 minutes (receipt time, immune to device clock
  skew) → grey marker, warning strip, dimmed halo.

## Tuning

All thresholds live in `TrackingConfig`; consumers may pass a custom config to
`VehicleTrackController`. Defaults are calibrated for intercity buses.

## Related

The **Smart Route Progress & ETA System** (`lib/core/tracking/progress/`,
documented in `ROUTE_PROGRESS_ETA.md`) builds on the same fixes to compute
route-relative progress, per-stop visit states, and ETAs.

## Tests

* `test/core/tracking/geo_math_test.dart` — distances, bearings, arc lerp, wrap.
* `test/core/tracking/fix_validator_test.dart` — junk/replay/teleport gating.
* `test/core/tracking/speed_estimator_test.dart` — conversion, derivation, smoothing.
* `test/core/tracking/heading_resolver_test.dart` — source priority + jitter hold.
* `test/core/tracking/vehicle_tracking_engine_test.dart` — snap, interpolation,
  mid-flight continuation, clamped windows, staleness, rejection.
* `test/core/widgets/tracking/vehicle_track_controller_test.dart` — ticker
  lifecycle, notifications, rejection silence.

All deterministic: the engine takes `now` per call; tests inject a fake clock.
