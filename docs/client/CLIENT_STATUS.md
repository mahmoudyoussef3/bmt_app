# Client App — Status

> Audit date: **2026-07-30**. Baseline before the audit: `flutter analyze lib` →
> 0 issues; `flutter test` → 1423 passing, 1 pre-existing failure.
> After: `flutter analyze lib` → 0 issues; `flutter test` → **1450 passing, the
> same 1 pre-existing failure**, +27 new tests. Plus 11 database probes green in
> `supabase/tests/client_trust_regression.sql`.

Legend: ✅ Production Ready · ⚠️ Works but Needs Improvement · 🐛 Has Known Bugs ·
🔒 Security Risk · 🚧 Partially Implemented · 💡 Recommended Enhancement ·
❌ Not Implemented

---

## 1. Feature matrix

| Feature | Status | Bugs | UX Quality | Performance | Security | Recommended Action |
|---|---|---|---|---|---|---|
| Onboarding | ⚠️ | none | Good | **Poor** — 5.9 MB of PNGs | OK | Re-encode the three images to WebP (~5.5 MB install saving) |
| Auth (sign in/up/reset, Remember Me) | ✅ | none | Good | Good | Good | — |
| Home & discovery | ⚠️ | none | Good | **Weak** — unfiltered `trip_seats` realtime | OK | Drop or filter the platform-wide subscription |
| Offices (directory + profile) | ✅ | fixed | Good | Good | Good | — |
| Route discovery / search | ✅ | none | Good | Good | Good | — |
| Booking wizard | ✅ | none | Strong | Good | **Hardened** | — |
| Seat lock & confirm | ✅ | none | Good | Good | **Hardened** | — |
| Payments — card (Paymob) | ✅ | none | Good | Good | Good | — |
| Payments — manual transfer | ✅ | none | Good | Good | Good | — |
| Payments — re-pay a rejected booking | 🚧 | — | Missing | — | — | Route an existing `bookingId` into the wizard |
| Payments — promo codes | ❌ | — | — | — | — | `promo_codes` table does not exist; remove the dead repository method or build the table |
| Payments — wallet balance | ❌ | — | — | — | — | Enum member with no backing table; remove or build |
| My Trips / Trip Details | ✅ | fixed | **Much improved** | Good | Good | — |
| Booking / payment state model | ✅ | fixed | Strong | Good | Good | — |
| Booking event timeline | ❌ | — | Missing | — | — | Build on the six real sources; omit "seat held" rather than invent it |
| Cancellation | ✅ | none | Good | Good | Good | — |
| Trip review | ✅ | fixed | Good | Good | Good | — |
| Live tracking | ✅ | none | Strong | Good | Good | Consider an ETA confidence band |
| Notifications — inbox | ✅ | fixed | Good | ⚠️ two sockets | **Hardened** | Derive unread count from the list stream |
| Notifications — routing / deep links | ✅ | fixed | Good | Good | Good | — |
| Notifications — push delivery | ❌ | — | — | — | — | **No FCM sender exists.** Build the Edge Function that reads `notification_tokens` |
| Packages marketplace | ✅ | fixed | Good | Good | Good | — |
| My Subscription | ⚠️ | none | Good | Good | Good | Provider office is a documented backend gap |
| Seat release | ⚠️ | none | Adequate | Good | Good | Screen is ~2.8k lines across 9 files; decompose |
| Support (tickets, refunds, attachments) | ⚠️ | none | Good | Good | 🔒 **bucket still public** | Private bucket + signed URLs (Client **and** Dashboard) |
| Communication (threads) | 🚧 | none | Adequate | Good | Good | Agent replies do not arrive live; the "call" screen is a preview |
| Loyalty | ✅ | none | Good | Good | Good | — |
| Referrals | ✅ | none | Good | Good | Good | — |
| Profile / settings | ⚠️ | none | Good | Good | Good | FAQ + legal are static constants; no backing table |
| Localization & RTL | ✅ | fixed | Good | Good | Good | — |

---

## 2. Fixed in this pass

### Security (`supabase/migrations/20260730090000_client_trust_hardening.sql`, applied and verified)

1. 🔒→✅ **`support_attachments` had RLS disabled.** Correct policies existed but
   were never enforced; `anon` held SELECT/INSERT/UPDATE. Anyone with the shipped
   anon key could list every attachment on the platform, and any rider could read
   another rider's ticket files through the app's own datasource.
2. 🔒→✅ **Any rider could send any user a notification.** The INSERT policy was
   `{public}` with `with_check (true)` — a phishing primitive, since both the
   inbox and FCM navigate on notification content.
3. 🔒→✅ **Price tampering via three legacy booking RPCs.** `book_trip_seat`,
   `confirm_seat_booking` and a 19-arg `confirm_seat_booking_v2` overload were
   executable by `authenticated` and wrote `payment_amount` straight from a
   client parameter. All dropped; exactly one booking function remains.
4. 🔒→✅ **`documents` and `vehicle-images` buckets were publicly writable** —
   including DELETE. No app uploads to either.

### Correctness

5. 🐛→✅ **Booking state was invisible.** `TripStatus` collapsed three axes into
   one, keeping only "cancelled" from the booking axis. 17 of 32 production
   bookings sat at `reserved`/`pending` and every one displayed as a confirmed
   "Upcoming" trip. Added `BookingState` + `TripAttention` + banner and card
   strip.
6. 🐛→✅ **Every notification tap did nothing.** All 74 production rows have
   `action_url = null`, and the app read only that field. Destinations are now
   derived from `type` + `data`, and carry the record's id — a tap that *did*
   navigate previously opened the rider's newest booking, not the one named.
7. 🐛→✅ **A dead, DB-incompatible second booking funnel was routable.** Its
   confirm call omits two required RPC arguments, it skipped the seat lock, and
   it showed "Payment submitted" after a cancelled card checkout. Both entry
   routes removed; a regression test asserts they stay removed.
8. 🐛→✅ **Home's "Packages" tile led to a dead end.** `hasBookingContext` read
   `true` for any non-empty argument map, so `{'hasActiveSubscription': …}` sent
   riders to a checkout with no trip and a permanently blocked pay button.
9. 🐛→✅ **An office with nothing published was the end of the app** — two "none"
   sentences, nothing tappable.
10. 🐛→✅ **`SupportRoutes.ticketDetails` crashed on a null argument**
    (`_args(context)! as String`), reachable from a notification tap.
11. 🐛→✅ **A trip completed over an unconfirmed booking offered "Rate trip"** —
    asking a rider to review a journey they never took.
12. 🐛→✅ **Cancel was offered on bookings the RPC would refuse** (gated on the
    journey axis instead of the booking axis).
13. 🐛→✅ **Hardcoded Arabic in shared core** (`FcmService` snackbar action).

---

## 3. Open — security

| # | Finding | Severity | Why not fixed here |
|---|---|---|---|
| S1 | `trip_seats.passenger_id` readable by `anon` and every rider | Medium | Column privileges break the Dashboard's `trip_seats(*)`; a view kills Home's realtime signal. **Correct fix: drop the column** — it is redundant with `trip_passengers.seat_id` (0 orphans measured). Dashboard-side change. |
| S2 | `support-attachments` storage bucket is public-read | Medium | Needs signed URLs in **both** Client and Dashboard. §2.1 removed URL enumeration, which was the practical dump vector. |

---

## 4. Open — bugs and gaps

| # | Item | Severity | Notes |
|---|---|---|---|
| B1 | No FCM sender exists | High | `notification_tokens` written, never read. Push is silently non-functional. |
| B2 | No re-payment path from My Trips | High | The RPC and the wizard support it; nothing routes a booking id in. |
| B3 | Unfiltered `trip_seats` realtime on Home | Medium | Every seat change platform-wide refetches every open Home. Debounced but O(N × churn). |
| B4 | `promo_codes` table does not exist | Low | Dead repository method always returns 0. |
| B5 | Onboarding assets are 5.9 MB | Medium | Largest single install-size win available. |
| B6 | Two websocket subscriptions on `notifications` | Low | Derive the count from the list stream. |
| B7 | Route parsed by splitting a string | Low | `pickup_point_name` / `dropoff_point_name` are structured and already selected. |
| B8 | `TripsRoutes.tripDetails` takes `{'tripId': <booking id>}` | Low | Key is wrong, value is right. Rename with the notification resolver in one change. |
| B9 | Presentation files over the 120-line guideline | Low | `seat_release_screen`, `subscription_screen`, `communication_screen`. |
| B10 | Pre-existing test failure | Low | `support_ticket_details_test.dart` — "renders a loaded ticket without overflow" times out in `pumpAndSettle`. Present before this audit; untouched. |

### Orphaned files awaiting deletion

The retired funnel's files are unreachable but still on disk (file deletion was
blocked by this session's permission layer). They compile, are tree-shaken from
release builds, and are safe to remove wholesale:

```bash
git rm lib/apps/client/features/payments/presentation/screens/payment_checkout_screen.dart \
       lib/apps/client/features/payments/presentation/screens/payment_processing_screen.dart \
       lib/apps/client/features/payments/presentation/screens/receipt_upload_screen.dart \
       lib/apps/client/features/payments/presentation/cubit/payment_cubit.dart \
       lib/apps/client/features/payments/presentation/cubit/payment_state.dart \
       lib/apps/client/features/payments/presentation/widgets/checkout/checkout_promo_field.dart \
       lib/apps/client/features/payments/presentation/widgets/checkout/checkout_progress.dart \
       lib/apps/client/features/payments/presentation/widgets/checkout/checkout_header.dart \
       lib/apps/client/features/seat_selection/presentation/screens/seat_selection_screen.dart \
       lib/apps/client/features/seat_selection/presentation/widgets/interactive_seat.dart \
       lib/apps/client/features/seat_selection/presentation/widgets/booking_footer_summary.dart \
       lib/apps/client/features/seat_selection/presentation/widgets/seat_booking_summary_panel.dart \
       lib/apps/client/features/seat_selection/presentation/widgets/seat_passenger_preview_card.dart \
       lib/apps/client/features/seat_selection/presentation/widgets/passenger_info_bottom_sheet.dart \
       test/apps/client/features/payments/payment_checkout_screen_test.dart
```

Then remove `ClientCubitScopes.payment` / `.seatSelection`, the `PaymentCubit`
registration in `client_di.dart`, and `PaymentRepository.validatePromoCode` with
its datasource and interface methods. `flutter analyze lib` must stay at 0.

**Keep** `BookingConfirmationScreen`, `PaymobCheckoutWebViewScreen`,
`SeatSelectionCubit`, `SeatLegend` and every `checkout/` widget not listed above
— the live wizard uses all of them.

---

## 5. Recommended next phase, by impact

| Priority | Work | Why |
|---|---|---|
| **P0** | Build the FCM sender (Edge Function over `notification_tokens`) | Every backgrounded rider currently misses payment approvals and departure alerts |
| **P0** | Re-payment entry from My Trips | A rejected payment is a dead end for a paying customer |
| **P1** | Drop `trip_seats.passenger_id` (S1) | Closes a passenger-privacy leak with a one-line migration |
| **P1** | Private `support-attachments` bucket + signed URLs (S2) | Payment proof and complaint photos are world-readable by URL |
| **P1** | Re-encode onboarding assets | ~5.5 MB off every install |
| **P2** | Filter or drop the Home `trip_seats` subscription | Scales badly with marketplace traffic |
| **P2** | Booking event timeline from the six real sources | Trust: riders can see what happened and when |
| **P2** | Profiling pass on the seat map and tracking map | The only two screens with no frame-time data |
| **P3** | History search / date filter | Needed once a commuter has a year of rows |
| **P3** | Decompose the three oversized screens | Maintainability |

---

## 6. Business recommendations

1. **The unreviewed-payment queue is the product's real bottleneck.** 17 of 32
   bookings are waiting on a human. The app now tells riders that honestly, which
   makes the operator's review latency visible to customers — worth pairing with
   an SLA or auto-approval for card payments.
2. **Card payments settle themselves; transfers do not.** Every manual-transfer
   booking costs an operator action. Promoting card as the default method reduces
   both the queue and the "is my seat confirmed?" support load.
3. **Office identity is now end-to-end.** Riders see who they booked with on the
   card, in details, and in history — the prerequisite for per-office ratings
   driving marketplace ranking.
4. **Push is the missing retention lever.** Payment approval and departure alerts
   are written to the database and never delivered. It is the single highest-value
   piece of backend work outstanding.
