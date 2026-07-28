# Client App — Booking Lifecycle

## 1. Three axes, not one status

A booking is described by three independent statuses. The Client App used to
collapse them into a single four-value `TripStatus`, keeping only "cancelled"
from the booking axis. That was the single largest source of misleading
information in the app.

| Axis | Column | Values | Answers |
|---|---|---|---|
| **Journey** | `operation_trips.status` | `scheduled`, `open_for_booking`, `boarding`, `in_progress`, `completed`, `cancelled` | Is the vehicle coming, moving, done, or called off? |
| **Booking** | `operation_bookings.status` | `reserved`, `confirmed`, `completed`, `cancelled` | Is this rider's seat theirs yet? |
| **Payment** | `operation_bookings.payment_status` | `pending`, `submitted`, `approved`, `rejected`, `refunded`, `cancelled` | Has the money been accepted? |

Measured on the production database during the audit:

```
status     payment_status  payment_review_status  count
reserved   pending         pending                 17
confirmed  approved        reviewed                 5
completed  approved        reviewed                 5
cancelled  submitted       pending                  2
cancelled  cancelled       pending                  2
cancelled  rejected        reviewed                 1
```

**17 of 32 bookings sat at `reserved`/`pending`** — a held seat awaiting review.
Every one of them rendered in My Trips as a plain "Upcoming" trip, with no
indication that the payment was unreviewed, that the hold expires, or that the
seat was not yet the rider's.

## 2. The happy path

```
 discovery ──▶ route ──▶ date ──▶ trip ──▶ stops ──▶ seat ──▶ package ──▶ payment
                                                                            │
                       lock_trip_seat(trip, seat, client)  ◀────────────────┘
                                     │  seat.state = reserved, lock_expires_at = now()+N
                                     ▼
                       confirm_seat_booking_v2(…22 args…)
                                     │  booking row: status=reserved
                                     │  payment_status = pending (card) | submitted (transfer)
                                     │  seat hold extended to 30 minutes
                                     ▼
              ┌──────────────────────┴───────────────────────┐
        card leg                                       manual transfer
              │                                               │
   Paymob checkout (WebView)                        receipt uploaded to
              │                                     storage `payment-receipts`
   HMAC-verified callback                                     │
   settle_paymob_payment()                          operator reviews in Dashboard
              │                                               │
              └──────────────────▶ approve_payment() ◀────────┘
                                     │
                            booking.status = confirmed
                            payment_status = approved
                            seat.state     = paid
                                     ▼
                          trip runs ──▶ booking.status = completed
```

`PlaceSeatBookingUseCase` performs lock-then-confirm as one unit of work: the
lock lives in its own transaction, so a confirm that throws would strand the seat
until the hold expired. It hands the lock back on any failure. Once a booking row
exists the release RPC no-ops, so a seat that really was booked keeps its hold.

## 3. Server-authoritative rules

These are enforced in `confirm_seat_booking_v2` (SECURITY DEFINER) and are **not**
duplicated in Dart:

| Rule | Failure |
|---|---|
| Caller must be the booking's client | `not_authorized` |
| Trip must be `open_for_booking` | `trip_not_available` |
| Seat must be `reserved` **by this client** with an unexpired lock | `seat_unavailable` / `lock_expired` |
| No second active booking on the same trip | `duplicate_active_booking` |
| Payment method ∈ `credit_card`, `instapay`, `vodafone_cash`, `bank_transfer` | `payment_method_not_allowed` |
| Non-card, non-subscription bookings need a receipt | `payment_receipt_required` |
| **The fare is resolved server-side** from `trip_pricing` / `transport_packages`; `p_payment_amount` is never read past validation | `fare_unavailable` |

> Until `20260730090000_client_trust_hardening`, three legacy RPCs
> (`book_trip_seat`, `confirm_seat_booking`, and a 19-arg `confirm_seat_booking_v2`
> overload) were still executable by `authenticated` and inserted
> `payment_amount` straight from the client. They have been dropped. See
> `CLIENT_SECURITY.md`.

The Client mirrors only what it needs to *stop a rider early*, never to decide:
`BookableTrip.isOffered` refuses a trip that has left `open_for_booking` before
the rider picks a seat, so the rejection is a screen rather than an RPC error.

## 4. Contradictions, and what the app does about them

Because the axes are independent, invalid combinations are reachable. The app
names them instead of smoothing them over (`TripAttention`):

| Journey | Booking | Payment | Attention | What the rider is told |
|---|---|---|---|---|
| upcoming | reserved | submitted | `awaitingPaymentReview` | Seat held while the office checks the receipt |
| upcoming | reserved | pending | `paymentIncomplete` | Payment not completed — finish or cancel |
| upcoming | reserved | rejected | `paymentRejected` | Not accepted — contact support or rebook |
| any | cancelled | approved | `refundDue` | Cancelled after you paid; a refund is owed |
| cancelled | confirmed | approved | `refundDue` | Trip called off; a refund is owed |
| completed | **reserved** | any | `needsSupport` | Booking and payment records disagree |
| upcoming | reserved | **approved** | `needsSupport` | Approval did not carry the booking forward |
| upcoming | confirmed | approved | `none` | Nothing outstanding |

`needsRiderAction` splits "waiting on someone else" (review, refund) from "your
move" (incomplete, rejected, contradiction), which is what decides whether the
banner reads as an action or as information.

Every attention state that the rider cannot resolve alone ends at the support
centre — no explanation is a dead end.

## 5. Cancellation

`cancel_booking_by_client(booking_id, reason)` is the only path. It refuses once
the payment is approved (`booking_already_confirmed`); after that, cancelling is
a support conversation, not a button.

`TripPolicies.canBeCancelled` mirrors that rule on the booking axis:

```dart
status == TripStatus.upcoming
  && bookingState == BookingState.reserved
  && (paymentStatus == pending || paymentStatus == underReview)
```

Gating on the journey axis alone — which is what it did before — offered the
button on bookings the RPC would refuse.

## 6. Re-paying a rejected booking

`update_existing_booking_payment(booking_id, method, receipt, reference, phone)`
exists and the wizard calls it when `session.bookingId` is already set. **There
is currently no entry point that carries an existing booking id into the wizard**,
so a rider whose receipt was rejected cannot re-pay from My Trips. In practice
`reject_payment` also cancels the booking, so the rider rebooks — but that is a
side effect, not a designed flow. Tracked in `CLIENT_STATUS.md`.

## 7. Race conditions and their answers

| Race | Answer |
|---|---|
| Two riders tap the same seat | `lock_trip_seat` takes a row lock; the loser gets `seat_unavailable` |
| Rider double-taps "confirm" | The wizard raises a full-screen blocker while `BookingWizardConfirming` / `CardCheckout` / `VerifyingPayment` |
| Lock expires during checkout | `confirm_seat_booking_v2` raises `lock_expired`; the wizard surfaces it and the rider re-picks |
| Confirm fails after the lock | `PlaceSeatBookingUseCase` releases the lock in its `catch` |
| Rider already booked this trip | `duplicate_active_booking` before any seat is touched |
| Trip closes while the rider is on the seat map | `BookableTrip.isOffered` refuses at load |
| App killed mid-card-checkout | Nothing is believed from the WebView; the booking row already exists and `card_payment_state` is read from our own DB on return |
| Gateway callback is late | `BookingWizardConfirmCubit.cardPaymentFinished` confirms as *pending verification* rather than claiming failure — a rider whose card was charged never loses their seat to a slow webhook |
