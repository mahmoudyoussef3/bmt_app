# Paymob card payments

Two functions, one job each:

| Function | Called by | Purpose |
|---|---|---|
| `paymob-create-intention` | the app | Builds the Paymob order + payment key, returns the iframe URL, and links the order to the booking. |
| `paymob-payment-callback` | **Paymob** | Verifies the HMAC and settles the booking server-side. |

## Why the callback exists

The app sees the gateway through a WebView. What comes back on the redirect
(`?success=true`) is a URL the device can rewrite, so it is treated as a claim
about the outcome, never as proof of payment. The booking is only ever marked
paid by `settle_paymob_payment`, which runs from the HMAC-verified callback.

After the WebView closes the app polls `card_payment_state` for ~20s. If the
callback has not landed by then the booking is shown as *pending verification*
— never as failed, because the rider's card may well have been charged.

## Secrets

Never commit these; set them on the project:

```bash
supabase secrets set PAYMOB_API_KEY='<API key from Paymob → Settings → Account Info>'
supabase secrets set PAYMOB_HMAC_SECRET='<HMAC from the same page>'

# Optional — these default to the values baked into the function.
supabase secrets set PAYMOB_CARD_INTEGRATION_ID='4923808'
supabase secrets set PAYMOB_IFRAME_ID='893140'
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically.

## Deploy

```bash
supabase db push          # 20260720090000_paymob_card_settlement.sql

supabase functions deploy paymob-create-intention
supabase functions deploy paymob-payment-callback --no-verify-jwt
```

`--no-verify-jwt` is required and safe: Paymob calls with no Supabase JWT, and
the HMAC signature is what authenticates the request. An unverified body is
never acted on.

## Register the callback in Paymob

Paymob dashboard → Developers → Payment Integrations → your card integration:

- **Transaction processed callback** →
  `https://<project-ref>.supabase.co/functions/v1/paymob-payment-callback`
- **Transaction response callback** → your existing redirect URL (the one the
  WebView catches). This one is cosmetic; it settles nothing.

## Test cards

Use Paymob's test integration and their published test cards. A successful
payment should, within a second or two, leave:

- `operation_bookings.status = 'confirmed'`, `payment_status = 'approved'`
- `booking_payments.status = 'approved'` with `gateway_transaction_id` set
- `trip_seats.state = 'paid'`
- a `trip_passengers` row and a client notification

Re-delivering the same callback must change nothing — `settle_paymob_payment`
is idempotent, because Paymob retries.
