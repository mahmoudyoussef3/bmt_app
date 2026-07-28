# Client App — Payment Lifecycle

## 1. Methods

Loaded from `payment_methods` (`is_active = true`, readable by `anon` and
`authenticated`). Four are accepted by the booking RPC:

| Client enum | RPC code | Settlement |
|---|---|---|
| `creditCard` | `credit_card` | Paymob, HMAC-verified callback |
| `instapay` | `instapay` | manual transfer + receipt, operator reviews |
| `vodafoneCash` | `vodafone_cash` | manual transfer + receipt, operator reviews |
| `bankTransfer` | `bank_transfer` | manual transfer + receipt, operator reviews |

`walletBalance` exists in the Dart enum but has no RPC code and no backing
balance table. It is not offered by the wizard.

> The retired checkout funnel mapped `vodafoneCash` to `'mobile_wallet'` and
> `walletBalance` to `'wallet_balance'` — neither of which the RPC accepts. That
> funnel is no longer reachable; see `CLIENT_ARCHITECTURE.md` §4.

## 2. Card leg (Paymob)

```
BookingWizardConfirmCubit.confirm()
  └─ PlaceSeatBookingUseCase  → booking row, payment_status = 'pending'
  └─ StartCardCheckoutUseCase → Edge fn `paymob-create-intention` → checkout_url
  └─ emit BookingWizardCardCheckout(checkoutUrl)
       │
       ▼   PaymobCheckoutWebViewScreen  (rider leaves the app's control)
       │
  cardPaymentFinished(reportedPaid)
       │  reportedPaid is ONLY what the redirect URL claimed — a value the
       │  rider's own device could have written. It decides nothing.
       ▼
  AwaitCardSettlementUseCase(bookingId, timeout: reportedPaid ? default : 0)
       └─ reads `card_payment_state(booking_id)` — our DB, settled by the
          HMAC-verified Paymob callback (`settle_paymob_payment`)
       │
       ├─ settled → BookingWizardConfirmed(requiresVerification: false)
       ├─ failed  → BookingWizardConfirmFailed('card_payment_declined')
       ├─ pending + reportedPaid  → Confirmed(requiresVerification: true)
       │     the card may well have been charged and the callback is simply
       │     late; telling the rider it failed would cost them their seat
       └─ pending + !reportedPaid → Failed('card_payment_not_completed')
```

No Paymob key ever reaches Flutter. `PAYMOB_API_KEY`,
`PAYMOB_CARD_INTEGRATION_ID` and `PAYMOB_IFRAME_ID` are read from Supabase
secrets inside the Edge Function.

A seat whose card payment never completed **keeps its hold**, so the rider can
choose another method and settle the booking that already exists via
`update_existing_booking_payment`.

## 3. Manual transfer leg

1. Rider transfers out of band and photographs the receipt.
2. `UploadPaymentReceiptUseCase` writes to the **private** `payment-receipts`
   bucket under `<auth.uid()>/…` and takes a time-boxed signed URL.
3. `confirm_seat_booking_v2` refuses without a receipt
   (`payment_receipt_required`), writes `payment_status = 'submitted'`,
   `payment_review_status = 'pending'`, and holds the seat for 30 minutes.
4. A `payment_review` notification goes to the office.
5. The operator approves (`approve_payment`) or rejects (`reject_payment`) in
   the Dashboard.

## 4. Payment states as the rider sees them

`PaymentStatus` (`trip_status_mapper.dart`) maps the DB vocabulary:

| DB value | `PaymentStatus` | Shown |
|---|---|---|
| `approved`, `paid` | `paid` | Paid |
| `submitted`, `under_review` | `underReview` | Under review |
| `pending` | `pending` | Pending |
| `rejected`, `failed` | `failed` | Failed |
| `refunded` | `refunded` | Refunded |
| `cancelled` | `cancelled` | Cancelled |
| anything else | `pending` | Pending |

Payment status appears in three places, and they agree because they share
`tripAttentionCopy`:

- **My Trips card** — one-line strip (`TripCardAttentionStrip`) when unsettled.
- **Trip Details** — full banner above the hero (`TripAttentionBanner`) plus the
  fare/status card (`TripPaymentCard`).
- **Notifications** — `payment_approved` / `payment_rejected` open that booking.

## 5. Pricing authority

The fare is resolved **entirely server-side** in `confirm_seat_booking_v2`:

```
subscription present   → 0, and a ride is decremented
otherwise              → trip_pricing for the exact (trip, from_point, to_point)
                         bucketed onto the package's duration tier
                         └─ falls back to transport_packages.price
```

`p_payment_amount` is accepted for backward compatibility and never read past
validation. There is exactly one function that can create a booking, and it owns
the price. See `CLIENT_SECURITY.md` §2.3 for the three legacy functions that did
trust the client and have been dropped.

## 6. Refunds

`refund_requests` is client-owns + office-scoped. A cancelled-but-paid booking
surfaces `TripAttention.refundDue`, whose banner links to the support centre —
the app never silently absorbs money that is owed back.

## 7. Gaps

- **No wallet balance.** The enum member has no table behind it.
- **No promo codes.** `promo_codes` does not exist in the database; the promo
  field went with the retired funnel, but
  `PaymentRepository.validatePromoCode` and its datasource method remain and
  will always return 0.
- **No re-payment entry from My Trips.** `update_existing_booking_payment` works
  and the wizard can call it, but nothing routes an existing booking id into the
  wizard. See `CLIENT_BOOKING_LIFECYCLE.md` §6.
