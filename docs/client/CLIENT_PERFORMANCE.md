# Client App — Performance

> Measured 2026-07-30. Numbers below are from this repository and the live
> database, not estimates.

---

## 1. App size — the largest single win

```
assets/            6.4 MB total
  images/          6.2 MB
    third_onboarding.png    2.1 MB
    first_onboarding.png    2.0 MB
    second_onboarding.png   1.8 MB
    app_icon.png            317 KB
  branding/        220 KB
```

**5.9 MB — 92 % of the asset bundle — is three onboarding PNGs shown once, on
first launch, and never again.** Every install pays for them permanently.

Recommended: re-encode to WebP at the real display resolution. Three full-bleed
phone illustrations should land around 150–250 KB each — roughly a **5.5 MB
reduction in install size** for no visual change. Nothing else in the bundle is
above 100 KB.

## 2. Network

### 2.1 The Home realtime subscription is unfiltered — the main scaling risk

`SupabaseHomeDatasource.watchHomeChanges` subscribes to **every** `trip_seats`
change on the platform:

```dart
.onPostgresChanges(
  event: PostgresChangeEvent.all,
  schema: 'public',
  table: 'trip_seats',      // ← no filter
  callback: notify,
)
```

Every seat state change, in every office, on every trip, wakes every open Home
screen and triggers a full `getHomeData()` — which is three parallel queries plus
their joins. The payload is discarded; only the "something changed" signal is
used.

`HomeCubit` debounces at 250 ms, so a burst collapses. But the ceiling is still
~4 refetches/second per open app, driven by traffic that has nothing to do with
that rider. With N riders on the home screen this is O(N × platform seat churn).

Recommended fix, in order of preference:

1. Drop the `trip_seats` subscription. `trip_events` already carries every trip
   lifecycle flip and is **RLS-scoped to trips the rider booked**; new departures
   can be picked up by the existing pull-to-refresh and the app-resume path.
2. If a live departures board is wanted, filter the subscription to the routes
   currently on screen.

`TripsCubit`'s equivalent is already correct: its `operation_bookings` channel is
filtered on `client_id`, and `TripsRealtimeRefresher` debounces at 250 ms with a
non-overlapping guard.

### 2.2 Two websocket subscriptions where one would do

`SupabaseNotificationsDatasource` opens `.stream()` on `notifications` twice —
once for the list, once for the unread count — filtered identically. The count
stream re-maps every row on every change purely to compute
`rows.where((r) => !r['is_read']).length`.

Recommended: derive the count from the existing list stream in the cubit.

### 2.3 Tracking's poll is deliberate, not waste

`TrackingSubscriptions` runs an 8-second `latestLocation` poll alongside the
realtime subscription. That is a documented fallback: realtime delivery on
`trip_live_locations` has been observed to drop under RLS, and a frozen bus
mid-journey is the failure that matters. It is cancelled with the subscription
and does not run outside a live trip.

## 3. CPU and rebuilds

- The ETA ticker (`TrackingCubit._startEtaTicker`, 30 s) emits a new state on
  every tick so relative times stay honest. It stops once
  `tripState.isFinished`. This is the correct trade: one rebuild per 30 s buys a
  timestamp that never lies.
- `TripsLoaded.counts` walks the full trip list once per filter value — four
  passes per rebuild. Negligible at today's volumes; worth memoising if history
  grows past a few hundred rows.
- Trip and route lists build through `SliverList.builder`, so they are lazy.
- `ClientSkeleton` shimmer and the confetti painters are the only continuous
  animations, and both are bounded by their screen's lifetime.

## 4. Memory and cleanup

Every timer and subscription in the Client App has a matching cancel:

| Owner | Resource | Released in |
|---|---|---|
| `TrackingCubit` | ETA ticker, location sub, trip-change sub | `close()` |
| `TripsCubit` | `TripsRealtimeRefresher` (sub + debounce) | `close()` |
| `HomeCubit` | home-changes sub + debounce timer | `close()` |
| `ForgotPasswordCubit` | resend cooldown ticker | `close()` |
| `ClientApp` | `onAuthStateChange` subscription | `dispose()` |
| Every datasource channel | `controller.onCancel = channel.unsubscribe` | stream cancel |

No leak was found. `booking_confirmation_screen.dart` runs a status poll timer;
it is cancelled in `dispose()`.

## 5. Rendering

Trip Details, My Trips and the office profile cap content width
(`AppLayout.maxContentWidth`, 560/720 px) so tablet layouts do not stretch line
lengths. Lists are lazy. Images use `CachedNetworkImage` with shimmer
placeholders.

## 6. Dead weight now removed from the build graph

Retiring the second booking funnel took ~1,900 lines out of the reachable app
(see `CLIENT_STATUS.md` for the files still on disk awaiting deletion). Those
files are no longer referenced from `ClientRouter`, so they are tree-shaken from
release builds today and will stop being compiled at all once deleted.

## 7. Not measured

No profiling run (`--profile` + DevTools timeline) was performed as part of this
audit, so there are no frame-time numbers here. Everything above is a static or
database measurement. A profiling pass on the seat map and the tracking map —
the two heaviest screens — is the recommended next performance step.
