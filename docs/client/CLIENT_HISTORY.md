# Client App — Booking History

## 1. Where history lives

My Trips (`TripsRoutes.myTrips`, and the shell's Trips tab) is the whole history
surface. It reads every `operation_bookings` row for the signed-in rider, newest
first — there is no pagination and no cut-off date, so a rider never loses access
to an old booking.

```dart
_supabase.from('operation_bookings')
  .select('*, operation_trips:public_trips(*, office:public_offices(name)), trip_reviews(booking_id)')
  .eq('client_id', user.id)
  .order('created_at', ascending: false);
```

The embedded `trip_reviews(booking_id)` is RLS-scoped to the rider's own review,
so its mere presence means "already rated" — no second query.

## 2. Organisation

Four filter tabs backed by `TripFilter`, each with a live count:

| Tab | Matches |
|---|---|
| Upcoming | `TripStatus.upcoming` |
| Active | `TripStatus.inProgress` |
| Completed | `TripStatus.completed` |
| Cancelled | `TripStatus.cancelled` |

Tabs partition on the **journey** axis. The booking and payment axes are shown
*within* each card rather than splitting the tabs further — a rider looking for
"my trip to Smart Village next Tuesday" thinks in journeys, not in payment
states.

## 3. What a card shows

- Journey status badge (pulsing dot only while in progress — never colour alone)
- Fare
- Pickup → destination
- Date · time
- **Operating office** — on a marketplace the rider booked with someone specific
- Driver row
- **Attention strip** — one line naming why this booking is unsettled

Before the 2026-07-30 audit the card carried no payment or booking information at
all, so 17 of the 32 production bookings (all `reserved`/`pending`) were visually
identical to confirmed ones. The strip is the difference; the full explanation is
on Trip Details.

## 4. Trip Details

Ordered by what the rider needs first:

```
TripAttentionBanner    ← only when something is outstanding; above everything
TripHeroCard           route, date, time, reference
TripBoardingCard       ← when the trip can still be boarded or cancelled
TripLiveTrackingCard   ← when this booking may be tracked
TripDetailSections     driver · vehicle · seat map · payment · policies
TripActionsBar         exactly one primary action set for the trip's state
```

The actions bar offers Track (filled) and Cancel (destructive) for a live
booking, and Rate + Book again once completed. Rating is offered only on a trip
the rider actually travelled — `bookingState` must be `completed` or
`confirmed`, so a seat that was only ever held is never asked how the journey
went.

## 5. Realtime

`TripsRealtimeRefresher` re-reads the list on any change to the rider's own
`operation_bookings` rows or to `trip_events` for trips they booked. A failed
refresh keeps the last usable state rather than blanking the screen.

## 6. Honest gaps

### No event timeline
Phase 9 of the audit brief asks for a per-booking read-only timeline
(created → seat held → payment uploaded → payment approved → trip started →
completed). **This is not implemented, and the data to build it honestly is only
partly there.**

What exists today:

| Event | Available? | Source |
|---|---|---|
| Booking created | ✅ | `operation_bookings.created_at` |
| Seat held | ⚠️ approximated | `trip_seats.held_at` — overwritten on later transitions |
| Payment submitted | ✅ | `booking_payments.created_at` |
| Payment reviewed | ✅ | `operation_bookings.reviewed_at`, `reviewed_by` |
| Trip started / completed | ✅ | `trip_events` (RLS-scoped to the rider's trips) |
| Cancelled | ✅ | `operation_bookings.cancelled_at`, `cancellation_reason` |

The one genuinely missing link is a durable "seat held" moment. Building the
timeline on the six real sources and simply omitting that row is the correct
implementation — fabricating a plausible timestamp for it is not. Tracked as a
recommended enhancement in `CLIENT_STATUS.md`.

### No search or date filtering
A rider with a year of commuting has hundreds of rows and four tabs. Once the
list is long enough to scroll past a screen, filter-by-route and filter-by-month
become necessary.

### Route parsed from a string
`TripMapper` splits `operation_bookings.route` on `→` to recover pickup and
destination. The row also carries `pickup_point_name` / `dropoff_point_name`,
which are structured and should be preferred, with the split kept only as a
fallback for rows that predate those columns.
