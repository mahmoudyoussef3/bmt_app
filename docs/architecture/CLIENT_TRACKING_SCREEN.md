# Client Tracking Screen

The passenger-facing live tracking screen (`lib/apps/client/features/tracking/`).

Rebuilt 2026-07-15. This document records what it shows, where every value comes
from, and the rules that keep it honest.

---

## 1. Why it exists

A passenger with a confirmed booking has exactly four questions:

1. **When does the bus reach *me*?**
2. **Where do I get on, and am I checked in?**
3. **Where is the bus now, and can I trust that dot?**
4. **Who is driving, and how do I reach them?**

The screen answers those four, in that order, and nothing else. Anything that
does not answer one of them does not belong on it.

---

## 2. Layout

One layout, two widths — not two hierarchies.

```
┌────────────────────────────┐
│ ←  Track your trip      ⟳ │   transparent app bar over the map
│  ● Live · just now         │   TrackingSignalPill — the ONLY map overlay
│                            │
│        [ live map ]        │   route on road geometry, ordered stops, vehicle
│                    ⌖ + −   │   TrackingMapChrome, lifted above the sheet
├────────────────────────────┤
│ ═══                        │   draggable sheet (side panel > 900dp)
│ The captain is on the way  │   ← state headline
│ Arrives at your stop       │
│ 8 min                      │   ← THE hero ETA (appears exactly once)
│ From live GPS              │   ← where the number came from
│ ▓▓▓▓▓░░░░░  3 stops left   │
│                            │
│ Your booking      [Seat 12]│   ← TrackingBookingCard (rider's own row)
│ Board at   Nasr City       │
│ Get off at Smart Village   │
│ [Not boarded yet]          │
│                            │
│ Trip stops                 │   ← TrackingStopsList (ordered by point_order)
│ ● Banha         Departed   │
│ ● Nasr City  [Your stop]   │   ← badged by ID match, not name
│ ○ Smart Village [Your drop-off]
│                            │
│ 👤 Mahmoud  ★ 4.8 (32)  📞 │   ← TrackingCrewCard (REAL drivers.rating)
│ 🚌 Toyota Hiace · ح ب ج ٧٨٩│
└────────────────────────────┘
```

Past 900dp the sheet becomes a fixed 420dp side panel. Same widgets — the old
screen kept separate mobile and tablet trees, and they had drifted apart.

---

## 3. Where every value comes from

| Shown | Source |
|---|---|
| Trip state | `operation_trips.status`, then the captain's latest `trip_events.title`, then (last) whether a fix exists |
| Stops + order | `trip_route_points`, sorted by `point_order` |
| Stop visit state | `RouteProgressEngine`, seeded with the captain's confirmed station arrivals |
| Hero ETA | `RouteProgressEngine` → the rider's own stop (see §4) |
| ETA confidence | `EtaConfidence` — live / estimated / scheduled |
| Seat, boarding, drop-off, check-in | the rider's own `trip_passengers` row |
| Captain rating | `drivers.rating` / `drivers.rating_count` (maintained by the `trip_reviews` triggers) |
| Vehicle rating | `vehicles.rating` / `vehicles.rating_count` |
| Vehicle position | `trip_live_locations`, latest row + realtime inserts |
| Review state | `trip_reviews` row for this booking |

**There are no placeholder defaults.** A value we do not have is `null`, and the
UI omits the line. It never renders an invented "Driver assigned", "Plate
pending", "Assigned vehicle" or "N/A".

---

## 4. The rider-centric rule

A trip's stop list is the same for everyone aboard. The *journey* is not.

`TrackingFocus` picks the one stop the rider is actually waiting on:

* **Not yet boarded** → their **boarding stop** ("when does it reach me?")
* **Boarded, or the bus has already passed their boarding stop** → their
  **drop-off** ("when do I get there?")
* **Manifest unmatched** → the end of the line (the old behaviour, now the
  fallback rather than the rule)

The rider's two stops are resolved to indices in the ordered stop list by
`trip_passengers.pickup_point_id` → `trip_route_points.route_point_id`. Names are
only a fallback: two stations can share a name, and an operator can rename one
after the booking was made — matching on a stale name puts the badge on the wrong
stop, which is worse than not badging it at all.

Stops outside the rider's leg are **dimmed, not hidden**. The bus still calls
there, and that is *why* the arrival takes as long as it does.

---

## 5. Rules

* **The UI cannot set the trip state.** It is derived in the data layer from
  operational truth. The previous screen shipped a debug sheet
  (`showTrackingStatePreviewSheet`) and a `TrackingCubit.changeState` that let
  the UI put the screen into any state it liked. Both are deleted. Do not
  reintroduce a way for the presentation layer to declare where a bus is.
* **Ratings go to the server or they do not happen.** The completed state opens
  the real review flow (`showTripReviewFlow` → `submit_trip_review` RPC, keyed on
  the booking). The previous screen drew its own star rows whose values lived in
  cubit state and were never sent anywhere: the rider rated their captain, and
  nothing happened.
* **Only trackable bookings.** `TrackingTripQuery.trackableStatuses` is
  `confirmed` / `boarded` / `completed`. A booking whose payment is still pending
  or rejected can never surface a live vehicle position, from any entry point.
* **Empty is a real state.** No confirmed booking → `TrackingEmpty` explains why
  and offers a way forward. It does not render a map full of placeholders.
* **Stop order is load-bearing.** The map polyline, the engine's along-route
  projection and the rider's timeline all treat index order as route order. The
  data layer sorts by `point_order` rather than trusting the response order.

---

## 6. Performance

* `TrackingScreen` rebuilds only when the *state type* changes
  (`buildWhen: previous.runtimeType != current.runtimeType`), so a GPS fix cannot
  tear down the map.
* Inside `TrackingView`, each section is a `BlocSelector` — the map, the signal
  pill and the sheet rebuild independently.
* The map surface sits in a `RepaintBoundary`.
* The vehicle halo animates **only while a live fix exists**
  (`TrackingMapVehicle.feed`). It previously repeated forever, on a screen a
  rider leaves open for a whole bus journey.
* Zoom feeds back into the marker layer only on a ≥0.25 step, so a pinch does not
  rebuild every marker per frame.
* The realtime change stream is debounced 250 ms: one operator action touching
  five tables costs one refetch.
* A failed background refetch keeps the trip on screen. The rider is mid-journey.

---

## 7. Localization

Every string resolves through `TrackingLabels` (`tracking_*` keys in
`lib/l10n/app_ar.arb` / `app_en.arb`). Times and countdowns are formatted with
the rider's locale via `intl`.

The feature previously hardcoded English across 38 widgets inside an app that
ships in Arabic and runs right-to-left.

---

## 8. See also

* `docs/architecture/LIVE_TRACKING_ENGINE.md` — fix validation, interpolation
* `docs/architecture/ROUTE_PROGRESS_ETA.md` — the progress/ETA engine
* `supabase/migrations/20260714120000_trip_reviews.sql` — ratings + review RPC
