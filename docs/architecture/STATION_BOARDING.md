# Station-Based Trip Progress & Passenger Boarding Control

## Purpose

Make a trip advance the way a real transport operation does — one station at a
time, and only when the passengers due there are accounted for and the vehicle is
due out:

```
STATION → ARRIVAL → WAIT → BOARDING → VALIDATION → DEPARTURE → NEXT STATION
```

Before this, station progress was a *count*: the captain tapped "تم الوصول
للمحطة", a narrative row landed in `trip_events`, and all three apps inferred
"we are at station N" by counting those rows (`stationArrivalFloor`). A count is
not a state machine. It cannot say when the vehicle arrived, who is supposed to
board here, whether they did, or whether the captain may leave — so nothing
stopped a captain tapping through five stations in five seconds and stranding
every rider waiting at them.

## The rule

```
canProceed = boardingRequirementResolved AND earliestDepartureReached
```

Both halves are enforced in `captain_depart_station`. The Captain App renders the
same rule so the button is honestly disabled and *says why*, but the app is a
representation of the rule, never the rule itself.

| Condition | Satisfied when |
| --- | --- |
| **A — boarding** | No passenger whose pickup is this station is still `reserved`. They are aboard (`confirmed`), a recorded no-show, or cancelled. |
| **B — departure clock** | `now >= greatest(actual_arrival + configured_dwell, published_departure)`. A late bus still owes its riders the dwell; an early bus still waits for the time riders were told. |

## What is reused

Nothing about routes, trips, bookings or GPS was rebuilt.

* **`trip_route_points`** stays the only station list. Its `arrival_offset` /
  `departure_offset` are `"HH:MM"` durations from route start (written by
  `RouteScheduleCalculator`), and the gap between them is the dwell the operator
  configured for that stop. That gap *is* the minimum wait.
* **`trip_passengers.status`** stays the boarding vocabulary: `reserved`
  (expected) → `confirmed` (aboard) → `no_show` / `cancelled` / `completed`.
* **`operation_bookings.status`** already carried an unused `boarded` value.
  That is the rider-side boarding flag — and the switch that ends their tracking.
* **`trip_events`** keeps receiving the arrival marker with the exact title the
  three apps already count, so every existing progress surface keeps working.
* **`trip_live_locations`** and the captain's publisher are untouched.

## Data model — `trip_station_progress`

One row per stop of one trip, seeded when the trip enters `boarding`
(migration `20260811090000_station_boarding_authority.sql`).

```
upcoming ──▶ arriving ──▶ waiting_for_passengers ──▶ departed
```

`ready_to_depart` is deliberately **not** a stored value: it is a function of
stored facts and the clock, and a stored column cannot become true because a
minute passed. It is derived identically on both sides — by
`captain_depart_station` in SQL and by `StationGate` in Dart.

| Column group | Purpose |
| --- | --- |
| `sequence`, `point_name`, `route_point_id` | Position and identity. `route_point_id` is the `route_stations.id` namespace a manifest row's pickup point uses. |
| `expected_arrival_at` / `expected_departure_at` | The plan, resolved to instants against the office timezone (`office_wallet_policies.timezone`, default `Africa/Cairo`) — the one place this feature converts wall clock to an instant. |
| `min_dwell_seconds` | `departure_offset − arrival_offset`. |
| `actual_arrival_at` / `actual_departure_at` | What happened. |
| `expected_boardings`, `boarded_count`, `pending_count`, `no_show_count` | Denormalised from the manifest by trigger. |
| `arrived_by`, `departed_by` | Who caused the transition. |

**Why the counts are denormalised:** a rider may only read *their own* manifest
row. Without these the Client App could never show "3 expected, 2 boarded", and
the Captain App would need a second realtime subscription to the manifest to keep
a number on screen fresh. One table, one subscription, one truth — the captain
and the rider are literally reading the same numbers.

## RPCs

| Function | Who | Refuses when |
| --- | --- | --- |
| `captain_arrive_station(trip)` | assigned captain | not their trip, trip not running, no stations left. Takes **no station argument** — the server picks the next un-departed stop, so a captain cannot mark an arbitrary station reached. Idempotent while standing at one. |
| `captain_depart_station(trip)` | assigned captain | `passengers_not_boarded:N`, `departure_time_not_reached:HH:MM`, `no_current_station`. Row-locked; leaving station 1 transitions the trip to `in_progress` through `captain_update_trip_status`. |
| `captain_resolve_no_show(passenger, reason, note)` | assigned captain | invalid reason, `other` without a note, passenger not `reserved`. Records reason + author + time and files a `trip_events` row. |
| `passenger_confirm_boarding(booking)` | the rider | not their booking, booking not paid, trip not running, vehicle not at *their* station. Idempotent. |

`trip_station_progress` has a SELECT policy and **no write policy or grant at
all** — these four functions are the only way it changes.

### Concurrency

`assert_captain_running_trip` takes `FOR UPDATE` on the trip row, and each RPC
takes `FOR UPDATE` on the station row. Two simultaneous "continue" taps cannot
advance two stations: the second finds no current station and raises
`no_current_station` — a refusal, never a silent advance to the next stop.

## Per-rider tracking visibility

The single most important behaviour, and the one most easily got wrong.

```
Passenger A — confirmed, waiting … reads live positions
Passenger B — confirmed, waiting … reads live positions
Passenger C — boarded            … reads nothing
Captain                          … publishes throughout
```

`can_read_trip_fixes`'s passenger arm narrowed from
`status in ('confirmed','boarded','completed')` to `status = 'confirmed'`.
Realtime evaluates that policy per delivered row per subscriber, so the boundary
is genuinely **per booking**, never a switch on the trip. Nothing anywhere stops
the captain publishing.

The app mirrors it as a courtesy — `TrackingSubscriptions.syncLocation` drops the
channel and `TrackingView` stops passing the fix to the map — but
`TrackingRider.canTrackVehicle` deliberately **fails open** (off only when we
positively know the rider is aboard): the database is the boundary, and a missing
field must never take the map away from a rider still standing at their stop.

A boarded rider keeps the station board (`can_read_trip_stations` is wider than
`can_read_trip_fixes`) — they lose the vehicle's position, not their journey.

## ETAs

Two sources, merged by `overlayStationBoard`:

* **`RouteProgressEngine`** (existing) infers from where the vehicle *is*. Sharp
  while GPS flows; the only source of a `live` ETA. Unavailable to a boarded rider.
* **`StationBoard.etas`** (new) projects the published plan by the observed
  delay: the last station with both a planned and a real arrival sets the delay,
  extended if the vehicle is still standing somewhere it was already due to leave.
  No GPS, no position disclosure, and genuinely responsive to reality.

Rule: **fact beats inference for state, live beats projected for ETA** — the
latter only for a rider still allowed a live one. Every ETA carries its
`EtaConfidence`, and the client says "قد يتغير الوقت حسب حالة الطريق" once at the
foot of the list rather than dressing a projection up as a measurement.

## Modules

### Shared, pure Dart — `lib/core/tracking/progress/`

| File | Responsibility |
| --- | --- |
| `station_board.dart` | `TripStation`, `TripStationStatus`, `StationGate`/`StationGateState`, `StationEta`, `StationBoard` (current/next/focus, `delayAt`, `etas`, `gateAt`). Clock injected per call. |
| `station_board_mapper.dart` | Rows → board, plus the `columns` select list. Shared by both apps so they cannot disagree about what a row means. |
| `station_overlay.dart` | Lays the board over the GPS-inferred stop timeline. |

### Captain — `lib/apps/captain/features/station_progress/`

Full Clean Architecture slice (datasource → repository → use cases → cubit →
widgets). `resolveStationAction` is a pure function returning the one action:
arrive / depart (with its gate) / finish / board-unavailable.

The docked bar renders **one fixed-height button** in every state; when the gate
is shut the label *becomes the reason* ("متبقي راكبان", "يمكنك المغادرة بعد 08:45")
rather than adding a second line, because a bar that changes height reflows the
page under the captain's thumb at the moment they reach for it.

### Client — `lib/apps/client/features/tracking/`

`TrackingTripData` gained `stations`; `TrackingRider` gained `bookingStatus` and
`boardingPointId`. `TrackingBoardingCard` renders three states — waiting for the
vehicle / confirm / boarded-and-here-is-why-tracking-stopped.

## No captain map

The Captain App's trip screen has no map. A captain running a fixed route does
not navigate — they work a sequence of stations — and a map is a second thing
competing for the attention of someone holding a wheel. The live-map CTA is gone
from `TripExecutionPage`.

GPS itself is untouched: `TripLocationAutoShare` publishes for the whole live
trip, because the riders still waiting down the route are watching it.

> The `features/trip_map` module still exists on disk with its route registered,
> but has no entry point from the trip screen. It was left in place rather than
> deleted; deleting it is a separate call.

## Edge cases

| Case | Behaviour |
| --- | --- |
| Trip already running when this shipped | `ensure_trip_station_progress` replays the captain's arrival events onto a fresh board — the trip resumes where it is, not at station one. |
| Trip with no route points | `StationBoardUnavailable`; the captain gets the trip-level controls instead of an ungateable gate. |
| Stop with no configured time | Gated by the boarding requirement alone; no ETA is invented. |
| Passenger never boards | `captain_resolve_no_show` with a reason, an author and a timestamp. There is no direct captain write to `no_show` — the RLS policy no longer admits the value. |
| Duplicate arrive / depart / board request | Idempotent (arrive, board) or a refusal (depart). Never a double advance. |
| Rider confirms from home | `vehicle_not_at_station`. |
| Rider confirms at the wrong station | `not_your_station`. |
| Rider confirms someone else's booking | `not_your_booking`. |
| Captain reconnects / realtime drops | The board is re-read on every action and on reconnect; a stream error leaves the last board on screen rather than blanking it. |
| Two riders confirm simultaneously | Independent rows; `captain_depart_station` re-counts under the trip lock so neither can lose the race and be left behind. |
| Trip cancelled | `update_trip_status` already cancels the manifest; the board stops being read. |
| Points re-sequenced after the board was built | The overlay matches by id/name and declines to pair a stop with somebody else's station. |

## Tests

| Level | File |
| --- | --- |
| Unit | `test/core/tracking/progress/station_board_test.dart` — lifecycle, both departure clocks, gate states, delay projection, ETA provenance. |
| Unit | `test/core/tracking/progress/station_board_mapper_test.dart` — mapping, units, sorting, sparse rows, select-list parity. |
| Unit | `test/core/tracking/progress/station_overlay_test.dart` — fact over inference, ETA preference, re-sequenced boards. |
| Unit | `test/apps/captain/.../station_action_test.dart` — the four situations. |
| Unit | `test/apps/captain/.../station_action_failure_test.dart` — refusal parsing, Arabic plural forms. |
| Cubit | `test/apps/captain/.../station_progress_cubit_test.dart` — wiring, duplicate-tap protection, typed refusals, degradation. |
| Cubit | `test/apps/client/.../tracking_boarding_test.dart` — eligibility, station matching, confirm/refuse, per-booking visibility. |
| Widget | `test/apps/captain/.../station_primary_action_test.dart` — disabled gate says why, is not tappable, one height across every state. |
| Widget | `test/apps/client/.../tracking_boarding_card_test.dart` — three card states, the "why tracking stopped" explanation, stop list. |
| Integration | `test/apps/captain/.../station_boarding_integration_test.dart` — the full 14-step scenario with one server behind both apps. |
| Database | `supabase/tests/station_boarding_regression.sql` — 37 assertions against the **real** database, impersonating a real captain and two real riders, inside `BEGIN … ROLLBACK`. |

The Dart integration test would pass against a server that had forgotten the
rules — which is exactly why the SQL suite exists too.

## Related

* `LIVE_TRACKING_ENGINE.md` — the GPS pipeline this sits beside.
* `ROUTE_PROGRESS_ETA.md` — the inference engine the board now overlays.
* `TRIP_LIFECYCLE_DESIGN.md` — the trip-level state machine departure hooks into.
