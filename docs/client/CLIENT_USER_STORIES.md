# Client App — User Stories

Each story states the rider's goal, what the app must guarantee, and where that
guarantee is enforced. ✅ = holds today. ⚠️ = holds partially. ❌ = not met.

---

## Discovery

**As a new rider, I want to find an office that runs my route.**
✅ Office directory + search over `public_offices`; office profile shows
departures, routes and packages. Office identity travels with every route card,
trip card and booking, so the rider always knows who they are buying from.

**As a rider looking at an office with nothing published, I want a way onward.**
✅ *(fixed 2026-07-30)* Previously two plain "none" sentences and no action —
the end of the app. Now: "Search all routes" and "Browse other offices".

**As a rider whose date has no departures, I want to know why and what to try.**
✅ `RouteResultsEmptyState` gives a title, an explanation and an action.

---

## Booking

**As a rider, I want to know exactly what I am buying before I pay.**
✅ The wizard's summary step lists office, route, stops, date, departure,
vehicle, seat, package and total.

**As a rider, I must never pay a price I chose myself.**
✅ *(hardened 2026-07-30)* `confirm_seat_booking_v2` resolves the fare from
`trip_pricing` / `transport_packages` and never reads `p_payment_amount`. Three
legacy RPCs that *did* trust the client have been dropped —
`CLIENT_SECURITY.md` §2.3.

**As a rider, I must never be charged without a valid booking.**
✅ The booking row is written **before** the gateway session. A cancelled or
failed card payment leaves a booking the rider can settle another way, not a
charge with nothing behind it.

**As a rider, I must never see a seat as free when it is taken.**
✅ Seats come from `trip_seats`, never generated. `lock_trip_seat` takes a row
lock; the loser gets `seat_unavailable`.

**As a rider, I must not be able to double-book by tapping twice.**
✅ A full-screen blocker while confirming, plus `duplicate_active_booking`
server-side as the real guarantee.

**As a rider correcting an answer, I want back to take me one step, not out.**
✅ `PopScope` walks the wizard backwards; `canPop` only on step 0.

---

## Payment

**As a rider, I want to know whether my payment is accepted.**
✅ *(fixed 2026-07-30)* Payment state is its own axis, shown on the My Trips card
and on Trip Details. Before, a card showed only the journey status — 17 of 32
production bookings were unreviewed and all of them read "Upcoming".

**As a rider whose payment is still being checked, I want to know my seat is not
final yet.**
✅ `TripAttention.awaitingPaymentReview` — "Seat held while {office} reviews the
receipt."

**As a rider whose payment was rejected, I want to know and to have a next step.**
⚠️ The rejection is surfaced with a link to support. There is **no in-app
re-payment entry**: `update_existing_booking_payment` exists and the wizard can
call it, but nothing carries an existing booking id into the wizard.

**As a rider whose card was charged while the callback was slow, I must not lose
my seat.**
✅ `cardPaymentFinished` confirms as *pending verification* rather than claiming
failure whenever the gateway reported success.

---

## The trip

**As a rider, I want to know which office, vehicle and seat are mine.**
✅ Office on the card and in details; vehicle brand/model/plate; seat label and a
live seat map with the rider's own seat flagged.

**As a rider, I want to follow my vehicle.**
✅ Live map, gated on `inProgress` **and this booking's** payment being approved.

**As a rider, I must never be told "live" about stale data.**
✅ Four honest states — not started / live / delayed / off-route — plus the age
of the last fix, re-rendered every 30 s.

**As a rider, I want to cancel while that is still allowed.**
✅ Offered only while the booking is `reserved` with payment pending or under
review, mirroring `cancel_booking_by_client` exactly.

---

## History

**As a rider, I want every booking I ever made.**
✅ All `operation_bookings` rows, newest first, no cut-off, four filter tabs with
live counts.

**As a rider, I want a timeline of what happened to a booking.**
❌ Not implemented. Six of the seven events have real sources; only a durable
"seat held" moment is missing — `CLIENT_HISTORY.md` §6.

**As a rider, I must never be told I travelled on a seat I never got.**
✅ *(fixed 2026-07-30)* A trip marked complete over a `reserved` booking resolves
to `TripAttention.needsSupport` and is not offered for rating.

---

## Notifications

**As a rider, tapping a notification must open what it is about.**
✅ *(fixed 2026-07-30)* Destination derived from `type` + `data`, with the
record's id passed as an argument. Every one of the 74 production rows has
`action_url = null`, so before this every tap did nothing — and a tap that did
navigate opened the rider's *newest* booking rather than the one named.

**As a rider, I must not receive notifications strangers wrote.**
✅ *(fixed 2026-07-30)* Insert is now gated on office staff / platform admin. Any
signed-in rider could previously address a notification — with an `action_url` —
to any other user.

**As a rider, I want push when the app is closed.**
❌ No sender exists. `notification_tokens` is written and never read.

---

## Privacy

**As a rider, my payment proof and support attachments are mine.**
⚠️ Table access is fixed (RLS enabled, `anon` revoked). The
`support-attachments` **bucket** is still public-read; remediation needs a
matching Dashboard change — `CLIENT_SECURITY.md` §3.2.

**As a rider, nobody should learn which trip I am on.**
⚠️ `trip_seats.passenger_id` is still readable by anyone. The column is
redundant with `trip_passengers.seat_id`; dropping it is the fix —
`CLIENT_SECURITY.md` §3.1.

**As a rider, nobody should see my bookings, payments or tickets.**
✅ Every one is RLS-scoped to `client_id = auth.uid()`, verified by
`supabase/tests/client_trust_regression.sql`.
