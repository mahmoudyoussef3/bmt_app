# Client · Payments

Payment methods, promo codes, receipt upload (manual methods), Paymob card checkout and the
settlement poll. The booking itself is written by [`../seat_selection`](../seat_selection/README.md);
this feature only settles the fare.

## Overview

| Layer | Files (relative to `lib/apps/client/features/payments/`) |
|---|---|
| Live callers | `features/booking/presentation/widgets/wizard_payment_step.dart` (loads methods, picks one, uploads receipt via `features/booking/presentation/widgets/payment/receipt_picker.dart`), `features/booking/presentation/cubit/booking_wizard_confirm_cubit.dart` (card session + settlement poll), `presentation/screens/paymob_checkout_webview_screen.dart` (the gateway WebView) |
| Cubit | `PaymentCubit` (`presentation/cubit/payment_cubit.dart` — `loadCheckout()`, `applyPromo(code)`) |
| Use cases | `GetPaymentMethodsUseCase`, `ApplyPromoCodeUseCase`, `UploadPaymentReceiptUseCase`, `CreateCardPaymentSessionUseCase`, `StartCardCheckoutUseCase` (methods → card session), `AwaitCardSettlementUseCase` (poll), `GeneratePaymentReferenceUseCase` (pure) |
| Repo | `data/repositories/payment_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_payment_datasource.dart` |
| Entities | `domain/entities/payment_models.dart` (`PaymentMethodType`, `PaymentMethodData`, `PaymentCheckoutData`, `CardPaymentSession`, `CardPaymentState`) |
| `RETIRED` screens | `presentation/screens/payment_checkout_screen.dart`, `receipt_upload_screen.dart`, `payment_processing_screen.dart`, `booking_confirmation_screen.dart` — not routed; the wizard replaced them |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| P1 | List payment methods | `GET payment_methods?is_active=eq.true` | anon | `GET /api/v1/payments/methods` |
| P2 | Validate promo code | `GET promo_codes?code=eq.` | anon | `GET /api/v1/promo-codes/{code}` |
| P3 | Upload receipt | Storage `payment-receipts` upload + signed URL | session | `POST /api/v1/payments/receipts` (multipart) |
| P4 | Create card checkout session | Edge `POST /functions/v1/paymob-create-intention` | session | `POST /api/v1/payments/card-sessions` |
| P5 | Read card settlement state (poll) | `POST rpc/card_payment_state` | session | `GET /api/v1/bookings/{bookingId}/card-payment-state` |
| P6 | Gateway webhook (server-only) | Edge `paymob-payment-callback` → `settle_paymob_payment` | HMAC | `POST /api/v1/payments/webhooks/paymob` |

---

## P1 — Payment methods: `getPaymentMethods()` (`supabase_payment_datasource.dart:14-39`)

```
GET /rest/v1/payment_methods?select=*&is_active=eq.true&order=sort_order.asc
```

Mapping (`_mapPaymentMethod`, line 167): the row's `type` (fallback `method_type`, `code`) is
normalised (`-`→`_`, lower) and parsed to `PaymentMethodType`:

| Wire values accepted | Enum |
|---|---|
| `credit_card`, `card`, `visa`, `mastercard` | `creditCard` |
| `instapay`, `insta_pay` | `instapay` |
| `bank_transfer`, `bank` | `bankTransfer` |
| `vodafone_cash`, `mobile_wallet`, `wallet_transfer` | `vodafoneCash` |
| `wallet_balance`, `user_balance`, `balance` | `walletBalance` (**filtered out by the wizard** — the booking RPC has no wallet leg) |

Unknown types are dropped. Other fields: `title` (`name`), `subtitle` (`description`),
`recommended` (`is_recommended`), and from `metadata` jsonb: `transfer_account`, `account_holder`,
`gateway`, `integration_id`, `iframe_id`, `supported_channels[]`, `instructions`.
A missing table (`PGRST205`/`42P01`) returns an empty list rather than an error.

**Proposed .NET:** `GET /api/v1/payments/methods` → `[{ type, title, subtitle, recommended, transferAccount, accountHolder, instructions, supportedChannels }]`.
Never expose `integration_id`/`iframe_id` — the edge function already resolves them server-side per office.

---

## P2 — Promo code: `validatePromoCode(code)` (line 41)

```
GET /rest/v1/promo_codes?select=discount_amount,discount_type,max_uses,use_count
    &code=eq.<CODE upper>&is_active=eq.true&or=(expires_at.is.null,expires_at.gt.<now UTC ISO>)      (maybeSingle)
```

Returns `discount_amount` as an `int` when the row exists and `use_count < max_uses` (or `max_uses` null);
otherwise 0. **`discount_type` is read but both branches return the same number** — a `percentage`
code is treated as a flat amount (latent bug). Nothing increments `use_count` from the client, and
the discount is not sent to the booking RPC (the server resolves the fare), so **promo codes have no
effect on what is charged today**.

**Proposed .NET:** `GET /api/v1/promo-codes/{code}` → `{ valid, discountType, discountAmount }`, and
`NEEDS BACKEND DECISION`: apply the discount inside booking creation and count usage.

---

## P3 — Receipt upload: `uploadReceipt()` (line 71)

Caller: `pickAndUploadReceipt(bookingOrTripId: tripId)` — file picker limited to `jpg/jpeg/png/pdf`,
**max 8 MB** (`ReceiptTooLargeException`), content type from the extension.

```
POST /storage/v1/object/payment-receipts/<uid>/<tripId>/<epochMillis>_<safeFileName>
Content-Type: image/jpeg | image/png | application/pdf
x-upsert: false
<binary>

POST /storage/v1/object/sign/payment-receipts/<same path>
{ "expiresIn": 31536000 }                         // 1 year
→ { "signedURL": "/object/sign/payment-receipts/…?token=…" }
```

The returned **signed URL** is what goes into `p_receipt_url` (booking) and is what the dashboard
opens to review the payment. `safeFileName` = original name with anything outside `[a-zA-Z0-9._-]` replaced by `_`.
The path uses the **trip id** today (the booking does not exist yet at upload time).

`UNKNOWN`: bucket policies for `payment-receipts` are not in the migrations folder (configured in
the Supabase dashboard). Assume: authenticated users may upload under their own `<uid>/` prefix; reads via signed URL only.

**Proposed .NET:** `POST /api/v1/payments/receipts` (multipart: `file`, `tripId`) → `201 { receiptUrl }`
where `receiptUrl` is a long-lived or backend-resolvable reference. `NEEDS BACKEND DECISION`: object storage provider and URL lifetime.

---

## P4 — Card checkout session: `createCardPaymentSession()` (line 98)

Caller: `StartCardCheckoutUseCase` first re-reads P1 and throws `card_payment_unavailable` if no
`creditCard` method is active, then:

```
POST /functions/v1/paymob-create-intention
Authorization: Bearer <access token>
{
  "booking_id": "<uuid>", "amount": 120, "currency": "EGP",
  "trip_id": "<uuid>", "route": "New Cairo → Obour", "seat": "A3",
  "customer": { "email": "<user.email>", "name": "<metadata.full_name|name>", "phone": "<metadata.phone>" }
}
→ 200 { "checkout_url": "https://accept.paymob.com/api/acceptance/iframes/<iframe>?payment_token=…",
        "gateway_reference": "<paymob order id>", "order_id": 123456 }
   400 { "error": "<message>" }
```

App reads `checkout_url` (required, else `'Paymob checkout URL was not returned.'`) and
`gateway_reference` (fallback `order_id`, `intention_id`, booking id). A `FunctionException` is
reduced to `details.error|message|detail` or `reasonPhrase`.

**What the edge function does** (`supabase/functions/paymob-create-intention/index.ts`):

1. Resolves the **office's** merchant config for the booking via service-role RPC `resolve_booking_payment_config(p_booking_id)` (integration id, iframe id, API key); falls back to platform env `PAYMOB_API_KEY`, `PAYMOB_CARD_INTEGRATION_ID`, `PAYMOB_IFRAME_ID`. Any caller-supplied integration ids are ignored.
2. Paymob auth → create order (amount in cents, merchant order id = booking) → create payment key with the customer block.
3. **Links the Paymob order id to the booking** via service-role RPC `link_paymob_order(p_booking_id, p_order_id)` (writes `booking_payments.gateway_order_id`). Failure here is fatal on purpose.
4. Returns the iframe URL.

The app opens `checkout_url` in `PaymobCheckoutWebViewScreen`; the redirect URL's `success=true|false` /
`txn_response_code=APPROVED` is read (`_readOutcome`) **only as a hint** (`reportedPaid`) — never as the verdict.

**Proposed .NET:** `POST /api/v1/payments/card-sessions { bookingId }` → `{ checkoutUrl, gatewayReference }`.
Amount, currency, customer come from the booking + identity, not the body. Secrets stay server-side.

---

## P5 — Settlement state: `getCardPaymentState(bookingId)` (line 151)

```
POST /rest/v1/rpc/card_payment_state
{ "p_booking_id": "<uuid>" }
→ 200 { "booking_id", "booking_status": "reserved|confirmed|…", "payment_status": "pending|approved|failed|…",
        "gateway_status": "<booking_payments.status|null>", "settled": bool, "failed": bool }
```

SQL (`20260720090000_paymob_card_settlement.sql:275-304`): reads the booking (+ its payment row) where
`auth.uid() IS NULL OR client_id = auth.uid()`; `booking_not_found` otherwise;
`settled = payment_status = 'approved'`, `failed = payment_status IN ('failed','rejected')`.
Granted to `anon, authenticated, service_role`.

**Polling contract** (`AwaitCardSettlementUseCase`): every **1.5 s** for up to **20 s** after the WebView
closes when it reported success; **exactly once** (`timeout: Duration.zero`) when the rider abandoned.
Result handling in `BookingWizardConfirmCubit.cardPaymentFinished`: `settled` ⇒ confirmed; `failed` ⇒
`card_payment_declined`; still pending + `reportedPaid` ⇒ confirmed-with-verification banner; pending +
not reported ⇒ `card_payment_not_completed` (seat keeps its 30-min hold; rider can retry via S5).

**Proposed .NET:** `GET /api/v1/bookings/{bookingId}/card-payment-state` (owner only — drop the
`auth.uid() IS NULL` escape hatch) → the same JSON. Or push the verdict over SignalR.

---

## P6 — Gateway webhook (server-only, documented for completeness)

`supabase/functions/paymob-payment-callback/index.ts`: verifies Paymob's HMAC-SHA512 over the fixed
20-field list (`amount_cents, created_at, currency, error_occured, has_parent_transaction, id,
integration_id, is_3d_secure, is_auth, is_capture, is_refunded, is_standalone_payment, is_voided,
order.id, owner, pending, source_data.pan, source_data.sub_type, source_data.type, success`), then calls
service-role RPC `settle_paymob_payment(p_order_id, p_transaction_id, p_amount_cents, p_success, p_raw)`.

`BUSINESS RULE` (`20260720090000_paymob_card_settlement.sql:90`): finds `booking_payments` by
`gateway_order_id` (`payment_not_found`); idempotent if already `approved|refunded`; on failure marks
payment + booking `failed` and notifies the client (`payment_rejected`) — **the seat keeps its hold**;
on success requires `amount_cents == round(amount*100)` (`amount_mismatch`), then approves the
payment, confirms the booking, marks the seat `paid`, writes the manifest row and notifies. This is the
**only** path that can mark a card booking paid.

**Proposed .NET:** `POST /api/v1/payments/webhooks/paymob` with the same HMAC verification and idempotency.

---

## Notes for the .NET team

1. **Never trust the WebView redirect.** The app already treats it as a hint; keep the verdict on the server.
2. The receipt is uploaded **before** the booking exists (path keyed by trip id) — either keep that or
   allow a two-phase "create booking then attach receipt" flow.
3. Promo codes are read but not applied anywhere that affects the charge. Decide whether the feature ships.
4. `wallet_balance` as a payment method is filtered out of the wizard; the RPCs reject it (`payment_method_not_allowed`).
5. Merchant credentials are per office (`office_payment_configs`) with a platform fallback.
