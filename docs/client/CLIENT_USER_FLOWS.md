# Client App — User Flows

## 1. Launch and landing

```
main_client.dart → bootstrapFlavorApp(client) → ClientApp
   ClientSplashGate (waits for OnboardingCubit)
        │
        ├─ never onboarded            → OnboardingScreen → Welcome
        ├─ onboarded, no session      → Welcome → Sign in / Sign up / Forgot
        └─ onboarded, session cached  → Client shell (Home · Routes · Trips · Notifications · Profile)
```

A cached Supabase session restores straight into the shell — no re-login on
relaunch. `_LandingScreen` reads `currentSession` as well as the auth stream, so
it does not flash Welcome while the stream is still cold.

## 2. Discovery → booking (the only live funnel)

```
Home ─┬─ search (pickup, destination, date)
      ├─ popular routes
      ├─ map pin selection
      └─ office directory → office profile ─┬─ a departure
                                            └─ a route
                    │
                    ▼
          RouteSelectionScreen  (route details, pick a departure)
                    │
                    ▼
          BookingWizardScreen  ── one question per step ──
             1. stops      pickup + drop-off along the route
             2. trip       which departure
             3. seat       live seat map from trip_seats
             4. package    single ride or a commute plan
             5. payment    method + receipt/card
             6. summary    what you are buying, then confirm
                    │
                    ▼
          lock_trip_seat → confirm_seat_booking_v2   (one unit of work)
                    │
       ┌────────────┴─────────────┐
   card leg                  manual transfer
   Paymob WebView            receipt already uploaded
       │                          │
   settlement read from       payment_status = submitted
   our own DB                 operator reviews
       └────────────┬─────────────┘
                    ▼
          BookingConfirmationScreen → My Trips
```

**Back navigation.** `PopScope` on the wizard walks the steps backwards before
leaving, so Android back and iOS swipe-back both correct an answer instead of
discarding the session. `canPop` is true only on step 0.

**Double-tap.** While confirming, checking out, or verifying a card, the wizard
raises a full-screen blocker and disables the app-bar back button — a second
confirm cannot race the first for the same seat.

## 3. What happens when things go wrong

| Situation | What the rider sees |
|---|---|
| Seat taken while they were deciding | `seat_unavailable` → the seat map refuses and re-loads |
| Lock expired during checkout | `lock_expired` → error dialog, re-pick |
| Trip closed for booking | `BookableTrip.isOffered` refuses at seat-map load, before any money |
| They already booked this trip | `duplicate_active_booking` before any seat is touched |
| Confirm throws after the lock | The lock is handed back automatically |
| Card cancelled at the gateway | `card_payment_not_completed` — the seat keeps its hold so they can pay another way |
| Card charged but the callback is late | Confirmed **as pending verification** — never told it failed |
| Network dies mid-flow | Cubit emits `XError`; `ClientErrorCard` with a retry that re-runs the same call |
| App killed mid-checkout | The booking row already exists; reopening My Trips shows it with its real state |
| Office has nothing published | Two ways onward: search all routes, or browse other offices |
| No trips on the chosen date | `RouteResultsEmptyState` — explanation + an action, never a blank list |

## 4. After booking

```
My Trips ─┬─ Upcoming · Active · Completed · Cancelled  (counts live)
          └─ card: journey badge · fare · route · date · OFFICE · driver
                    └─ attention strip when unsettled
                              │
                              ▼
                     Trip Details
                        attention banner (what's my move)
                        hero · boarding · live tracking · sections
                        actions: Track | Cancel | Rate | Book again
                              │
                              ▼
                     TrackingScreen (only when in progress AND paid)
```

## 5. Notifications

A notification's destination is derived from its own `type` and `data`, not from
`action_url` (which is null on every production row):

| Notification | Opens |
|---|---|
| Payment approved / rejected / booking received | **that** booking's Trip Details |
| Trip departed / boarding started | live tracking for that booking |
| Trip-wide announcement | My Trips |
| Support ticket update | that ticket |
| Refund update | Support centre |
| Package expiring / exhausted | My Subscription |
| Anything with nothing to open | nothing — the tile just marks read |

A tapped push and a tapped inbox entry resolve through the same function, so they
cannot disagree. A server-supplied `action_url` still wins if one ever appears,
and now carries the row's ids so it lands on the right record.

> Push is not delivered today: no FCM sender exists. The in-app inbox is
> realtime and works.

## 6. Support

```
Profile / Trip attention banner → Support centre
     ├─ Create ticket   (category, office picker, attachments)
     ├─ Create refund request
     └─ Ticket details  (status, agent, conversation, attachments)
```

The office picker matters: before `20260726120000`, client tickets landed with
`office_id = NULL` and were invisible to every office.

## 7. Flows deliberately removed

- **Standalone seat-selection screen → payment checkout → payment processing.**
  Unreachable, incompatible with the live booking RPC, skipped the seat lock, and
  reported success after a cancelled card payment.
- **Packages "Continue to payment".** It reached a checkout with no trip and no
  seat, whose pay bar could never unblock. A subscription is bound to a route, so
  the CTA now sends the rider to pick one; the plan is bought in the wizard.
