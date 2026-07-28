# Client App — Live Tracking

## 1. What the rider sees

`TrackingScreen` (`TrackingRoutes.tracking`, arguments `{bookingId}` or
`{tripId}`) shows a map with the vehicle, the route polyline, every stop, the
rider's pickup, the destination, and a bottom sheet carrying trip state, next
stop and ETA.

## 2. Who may open it

```dart
bool get canBeTracked =>
    status == TripStatus.inProgress &&
    paymentStatus == PaymentStatus.paid &&
    bookingState != BookingState.cancelled;
```

A trip can be in progress for other passengers while this rider's payment is
still under review — tracking is gated on **this booking's** money, not the
trip's status. The booking-axis clause was added in the 2026-07-30 audit so a
cancelled booking on a running trip stops offering a map.

## 3. Data path

```
GetTrackingTripUseCase(bookingId | tripId)
  ├─ operation_bookings  → the rider's own row, hence trip_id
  ├─ public_trips        → trip + sanitised driver/vehicle jsonb
  ├─ trip_route_points   → polyline + ordered stop names/coords
  └─ trip_live_locations → latest fix (lat, lng, heading, speed, recorded_at)

TrackingSubscriptions
  ├─ syncLocation(tripId, tripState)   realtime on trip_live_locations
  │                                    + 8s latestLocation poll as delivery fallback
  └─ syncTripChanges(tripId)           realtime on trip_events → silent refetch
```

The 8-second poll is not redundancy for its own sake: realtime delivery on
`trip_live_locations` has been observed to drop under RLS, and a rider mid-journey
staring at a frozen bus is the failure that matters. The poll is cancelled with
the subscription.

## 4. Freshness — never claim "live" when it is not

`TrackingSignalPill` renders four honest states derived from the newest fix's
`recorded_at` and the progress engine's staleness flag:

| Condition | State |
|---|---|
| no fix at all | `tracking_signalNone` — tracking has not started |
| fix, not stale, on route | live |
| fix older than the staleness window | `tracking_signalStale` — delayed |
| fix present but far off the route line | off-route |

The age itself is printed beside it (`TrackingLabels.signalAge`) and re-rendered
by the cubit's 30-second ETA ticker, so "2 minutes ago" becomes "3 minutes ago"
without a network call.

`_onFix` also corrects a stale *status*: a position arriving while the trip still
reads `notStarted` promotes the state to `driverOnWay`, because a moving vehicle
outranks a status the captain forgot to flip.

## 5. Resilience

- A failed **background** refetch never replaces a good screen: `_fetch(silent:
  true)` keeps the last `TrackingLoaded` and only clears `isRefreshing`. The
  rider is mid-journey and needs the map more than they need an error.
- `TrackingEmpty` is a real state, not an error — "no confirmed booking to
  track" is rendered as an explanation, never as a fabricated vehicle marker.
- The ETA ticker stops itself once `tripState.isFinished`.
- Every subscription and timer is cancelled in `close()`.

## 6. Map behaviour

- Stop markers declutter by zoom (`buildTrackingStopMarkers`): intermediate stops
  drop out when zoomed out; only the next stop and the destination carry labels.
- Stops the Dashboard saved without coordinates are skipped rather than drawn at
  (0, 0).
- The vehicle marker interpolates between fixes through the shared
  `lib/core/tracking` engine — the same engine the Captain app and the Dashboard
  Live Ops Center use, so all three agree about where a bus is.

## 7. Security

`trip_live_locations` was open to `anon` until `20260729090000_tracking_authority`
— anyone holding the shipped anon key could stream every vehicle's GPS. It is now
RLS-scoped through a SECURITY DEFINER helper (policy subqueries are themselves
subject to RLS, and clients hold no read policy on `operation_trips`, which is why
the obvious policy silently returned false and the table had been left open).

## 8. Gaps

- **No ETA confidence surfaced.** The progress engine produces an ETA; the sheet
  prints it without a confidence band. On a long stale gap this is the one number
  that can still read as false precision.
- **No "tracking will start at HH:MM" pre-state.** Before departure the rider is
  told tracking has not started, but not when it will.
