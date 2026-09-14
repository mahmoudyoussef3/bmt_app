# Client App — API Reference (Supabase → .NET hand-off)

> **Scope:** every backend call the **Client (passenger) app** makes today.
> Source: `lib/apps/client/` (package `bmt_app`), read at branch `api_docs`.
> Server-side rules: `supabase/migrations/` (latest definition of each function/view wins) and
> `supabase/functions/`.

---

## 1. How the client reaches the backend today

There is **no REST API layer of our own**. The app holds a Supabase publishable key and talks
to Supabase directly through the `supabase_flutter` SDK. Every request is routed through one Dio
instance (`lib/core/network/dio_factory.dart` → `AppInterceptors`) via
`lib/core/network/supabase_dio_adapter.dart`, so headers/timeouts/logging are centralised.

```
Base URL (all flavors, overridable by --dart-define CLIENT_SUPABASE_URL):
  https://nbwzourpbnmewwklewyr.supabase.co

  /auth/v1/...                GoTrue        sign-up, sign-in, password reset, update user, sign-out
  /rest/v1/<table_or_view>    PostgREST     direct reads/writes, filtered by RLS
  /rest/v1/rpc/<function>     PostgREST     SECURITY DEFINER SQL functions = the business layer
  /storage/v1/object/...      Storage       receipt + support-attachment uploads
  /functions/v1/<name>        Edge Function paymob-create-intention (card checkout)
  wss://.../realtime/v1/...   Realtime      Postgres CDC subscriptions (home, trips, tracking, notifications)
```

Config source: `lib/core/flavors/app_flavor.dart` (`AppFlavorConfig.forFlavor(AppFlavor.client)`).
Timeouts: connect/receive/send 60 s (`lib/core/network/api_constants.dart`).

### 1.1 Headers sent on every request

| Header | Value | Set by |
|---|---|---|
| `apikey` | Supabase publishable key (`sb_publishable_…`) | `DioFactory` — `SUPABASE-SPECIFIC`, drop in .NET |
| `Authorization` | `Bearer <access_token>` — **only when a session exists** | `AppInterceptors.onRequest` |
| `Content-Type` | `application/json` | `DioFactory` |
| `Accept` | `application/json` (PostgREST calls override per-call: `application/vnd.pgrst.object+json` for `.single()` / `.maybeSingle()`) | `DioFactory` / SDK |
| `Prefer` | PostgREST-specific per call: `return=representation` after insert/update with `.select()`, `count=exact` for counted reads, `resolution=merge-duplicates` for upserts | SDK |

### 1.2 Identity the app reads from the token / user object

The app reads these from the Supabase `User` object (i.e. from the JWT + user metadata). The .NET
token or a `/me` endpoint must supply the same facts:

| Read as | Used for |
|---|---|
| `auth.currentUser.id` (UUID `sub`) | `client_id` on every write; own-row filters on reads |
| `auth.currentUser.email` | profile fallback email, Paymob customer email |
| `userMetadata['full_name']` (fallback `['name']`) | greeting on Home, passenger name on booking, Paymob customer name |
| `userMetadata['phone']` | passenger phone on booking, Paymob customer phone |
| `auth.currentSession != null` | "is signed in" — decides Home shell vs Welcome screen |

`NEEDS BACKEND DECISION` — the .NET JWT claim set / `/me` shape must carry `sub`, `email`,
`full_name`, `phone`.

### 1.3 Session behaviour

* Session (access + refresh token) is persisted and refreshed by the SDK. **No app-level refresh code.**
* `client_app.dart` subscribes to `auth.onAuthStateChange`: a session ⇒ register FCM token; no
  session ⇒ deactivate FCM token and route to Welcome.
* **All three EWT apps share one session store per device.** The client vets any restored session
  against the `clients` table (`ClientAccountGuard.ensureClientSession`, see `auth/`) and signs out a
  captain/dashboard session it finds. `NEEDS BACKEND DECISION`: issue audience-scoped tokens so a
  captain token is rejected by client endpoints.

### 1.4 Anonymous vs authenticated

The marketplace browse surface is readable **without a session** today (offices, routes, stations,
trips, seats, prices, packages, aggregate driver/vehicle ratings). Everything under "me" requires a
session. Each feature file states the requirement per operation.

### 1.5 Error contract — keep the machine codes

SQL functions raise **bare exception names** (`seat_unavailable`, `lock_expired`,
`booking_already_confirmed`, …). The Dart datasources match on `error.message.contains('<code>')`
and translate to localized copy. **The .NET backend must return these exact codes** (as a stable
`code` field) or every mapped message silently degrades to a generic fallback. Each feature file
lists the codes its datasource matches.

Non-RPC failures are surfaced through `lib/core/network/api_error_handler.dart` which maps HTTP
status → `Failure(code)`: `TIMEOUT`, `NO_INTERNET`, `400`, `401`, `403`, `404`, `422`,
`SERVER_ERROR`, `UNKNOWN`; the body's `message` or `error_description` is used as the user string
when present.

---

## 2. Reading a feature file

Each `<feature>/README.md` has:

1. **Overview** — screens, cubits, and the datasource file(s) that own the calls.
2. **Operations table** — one row per backend call.
3. **Per operation** — Dart call chain (screen → cubit → use case → repo → datasource method with
   `file:line`), the exact Supabase request as sent today, request params/body, the response shape and
   **which fields the app reads**, business rules (from SQL), error codes, and the proposed .NET endpoint.
4. **Realtime / storage / external** sections where relevant.
5. **Notes for the .NET team** — traps and decisions.

Proposed `/api/v1/...` endpoint names match the index in `docs/API_DOCUMENTATION.md` §11.

---

## 3. Feature index

| Feature folder | What it covers | Backend touchpoints |
|---|---|---|
| [auth](auth/README.md) | sign-up, sign-in, sign-out, password reset, session vetting, Remember-Me, pending phone/social | GoTrue; `clients` table; RPC `check_phone_exists`; trigger `handle_new_client_user` |
| [onboarding](onboarding/README.md) | first-run onboarding flag | **local only** (secure storage) |
| [home](home/README.md) | Home feed: bookable departures, rider's live bookings, active package, search suggestions | `operation_routes`, `public_trips`, `operation_bookings`, `subscriptions`; realtime channel |
| [booking](booking/README.md) | search (route matching + scoring), popular routes, map pins, search options, vehicle listing, the booking wizard's session→RPC param mapping | `operation_routes`, `route_stations`, `public_trips`, `public_offices` |
| [seat_selection](seat_selection/README.md) | seat map + **the booking write path**: lock → confirm → (update payment) | `trip_seats`, `public_trips`; RPCs `lock_trip_seat`, `release_trip_seat_lock`, `confirm_seat_booking_v2`, `update_existing_booking_payment`, `book_trip_seat` (`RETIRED`) |
| [payments](payments/README.md) | payment methods, promo codes, receipt upload, Paymob card session, settlement polling | `payment_methods`, `promo_codes`; Storage `payment-receipts`; Edge `paymob-create-intention`; RPC `card_payment_state` |
| [packages](packages/README.md) | office catalogue packages, a trip's fare menu, rider's active subscription | `transport_packages`, `subscriptions` |
| [trips](trips/README.md) | My Trips list/detail (own bookings + trip/vehicle/driver/seat map/stops), cancel booking, trip reviews | `operation_bookings`, `public_trips`, `trip_seats`, `trip_route_points`, `trip_reviews`; RPCs `cancel_booking_by_client`, `submit_trip_review`; realtime |
| [tracking](tracking/README.md) | live vehicle tracking for a paid booking, station board, boarding confirmation | `operation_bookings`, `trip_route_points`, `public_trips`, `trip_live_locations`, `trip_events`, `trip_passengers`, `trip_station_progress`, `trip_reviews`; RPC `passenger_confirm_boarding`; 2 realtime channels + fallback poll |
| [seat_release](seat_release/README.md) | seat-release hub (subscription summary + upcoming bookings + cancellations this month) | `subscriptions`, `operation_bookings` |
| [support](support/README.md) | support tickets (list/create/detail), related booking picker, office picker, attachments | `support_tickets`, `support_attachments`, `operation_bookings`, `public_offices`; Storage `support-attachments` |
| [communication](communication/README.md) | legacy chat threads stored as JSONB on complaints | `operation_complaints` |
| [notifications](notifications/README.md) | inbox, unread badge, mark read; FCM device token registration; push deep-link resolution | `notifications` (+ realtime stream), `notification_tokens` (core) |
| [profile](profile/README.md) | profile hub (client row + active package + trip counts), update profile; legal text (local) | `clients`, `subscriptions`, `operation_bookings` (+`public_trips` inner join count); GoTrue update-user |
| [routes](routes/README.md) | routes catalogue with per-route availability, route details + stops | `operation_routes`, `route_stations`, `public_trips`, `public_offices` |
| [offices](offices/README.md) | offices directory, office routes, office trips | `public_offices`, `operation_routes`, `public_trips` |
| [referrals](referrals/README.md) | referral rewards hub | `loyalty_accounts`, `loyalty_rewards`, `referrals`, `referral_leaderboard` (view) |
| [loyalty](loyalty/README.md) | points balance, ledger, tiers, rewards, redeem | `loyalty_accounts`, `loyalty_transactions`, `loyalty_tiers`, `loyalty_rewards` |
| [wallet](wallet/README.md) | rider's per-office wallets and recent ledger | RPC `client_wallet_summary` |

---

## 4. Master inventory (everything the client touches)

### 4.1 RPCs (`POST /rest/v1/rpc/<name>`)

| RPC | Feature | Latest SQL definition | Status |
|---|---|---|---|
| `check_phone_exists(p_phone)` | auth | `20260704214500_check_phone_rpc.sql` | live (granted to `public`) |
| `lock_trip_seat(p_trip_id, p_seat_id, p_client_id)` | seat_selection | `20260727160000_trip_lifecycle_authority.sql` | live |
| `release_trip_seat_lock(p_trip_id, p_seat_id, p_client_id)` | seat_selection | `20260714090000_fix_orphan_seat_locks.sql` | live |
| `confirm_seat_booking_v2(… 22 args)` | seat_selection | `20260820100000_trip_scoped_packages.sql` | live — **the** booking write |
| `update_existing_booking_payment(p_booking_id, p_payment_method, p_receipt_url, p_payment_reference, p_payer_phone)` | seat_selection | `20260706153000_update_existing_booking_payment.sql` | live |
| `book_trip_seat(…)` | seat_selection | dropped in `20260730090000_client_trust_hardening.sql` | `RETIRED` — Dart method still exists, server function is gone |
| `card_payment_state(p_booking_id)` | payments | `20260720090000_paymob_card_settlement.sql` | live |
| `cancel_booking_by_client(p_booking_id, p_reason)` | trips | `20260714100000_client_cancel_before_approval.sql` | live |
| `submit_trip_review(p_booking_id, 4 ratings, p_comment)` | trips | `20260721090300_multi_office_rpcs.sql` | live |
| `passenger_confirm_boarding(p_booking_id)` | tracking | `20260811090000_station_boarding_authority.sql` | live |
| `client_wallet_summary()` | wallet | `20260806090600_client_wallet_read.sql` | live |

### 4.2 Tables / views read or written (`/rest/v1/<name>`)

| Name | Kind | Features | Client access today |
|---|---|---|---|
| `clients` | table | auth, profile | own row (select/update/upsert) |
| `public_offices` | **view** over `offices` (active + listed only; 8 public columns) | booking, offices, routes, packages, support, home | anon + authenticated select |
| `public_trips` | **view** over `operation_trips` (statuses `open_for_booking/boarding/in_progress/completed` of listed offices; sanitised `drivers`/`vehicles` jsonb) | home, booking, seat_selection, trips, tracking, routes, offices, profile | anon + authenticated select — **the only trip surface the client may read** |
| `operation_routes` | table | home, booking, routes, offices | marketplace read (active routes of listed offices) |
| `route_stations` | table | booking, routes | marketplace read |
| `trip_seats` | table | home (embed), booking (embed), seat_selection, trips | marketplace read of listed trips; writes only via RPC |
| `trip_pricing` / `trip_package_prices` | tables (embedded) | home, booking, seat_selection, offices | marketplace read |
| `trip_route_points` | table | booking (embed), trips, tracking | read |
| `operation_bookings` | table | home, trips, tracking, seat_release, support, profile | own rows (`client_id = auth.uid()`); insert via RPC only |
| `subscriptions` | table | home, packages, seat_release, profile | own rows |
| `transport_packages` | table | packages | active packages of listed offices |
| `trip_reviews` | table | trips, tracking | own rows; write via RPC only |
| `trip_events` | table | home (realtime), trips (realtime), tracking | read |
| `trip_live_locations` | table | tracking | read gated by `can_read_trip_fixes()` |
| `trip_passengers` | table | tracking | own manifest row |
| `trip_station_progress` | table | tracking | read |
| `payment_methods` | table | payments | read (`is_active`) |
| `promo_codes` | table | payments | read |
| `support_tickets` | table | support | own rows (select/insert) |
| `support_attachments` | table | support | rows of own tickets (select/insert) |
| `operation_complaints` | table | communication | own rows (select/update) |
| `notifications` | table | notifications | own rows (select/update) + realtime stream |
| `notification_tokens` | table | notifications (core `FcmService`) | own rows (upsert/update) |
| `loyalty_accounts` | table | loyalty, referrals | own row (select/update) |
| `loyalty_transactions` | table | loyalty | own rows (select/insert) |
| `loyalty_tiers`, `loyalty_rewards` | tables | loyalty, referrals | public read |
| `referrals` | table | referrals | rows where referrer or referred is me |
| `referral_leaderboard` | **view** | referrals | authenticated read |

### 4.3 Storage buckets

| Bucket | Feature | Operation |
|---|---|---|
| `payment-receipts` | payments | `uploadBinary` to `<uid>/<bookingOrTripId>/<ts>_<name>` then `createSignedUrl` (1 year) |
| `support-attachments` | support | `upload` to `tickets/<ticketId>/<uuid>_<name>` then `getPublicUrl` |

### 4.4 Edge functions

| Function | Feature | Purpose |
|---|---|---|
| `paymob-create-intention` | payments | creates a Paymob order + payment key for a booking, links order→booking, returns iframe checkout URL |
| `paymob-payment-callback` | payments (server-only) | Paymob's HMAC-verified transaction webhook → `settle_paymob_payment` (not called by the app; documented because it is the only thing allowed to mark a card booking paid) |

### 4.5 Realtime subscriptions

| Channel / stream | Feature | Tables watched |
|---|---|---|
| `client_home_trips` | home | `trip_seats`, `trip_events`, `operation_bookings` (all events, unfiltered) |
| `client_trips:<userId>` | trips | `operation_bookings` (filter `client_id=eq.<uid>`), `trip_events` (unfiltered) |
| `location_updates:<tripId>` | tracking | `trip_live_locations` INSERT (filter `trip_id=eq.<tripId>`) + subscribe-status → link health |
| `client_tracking:<tripId>` | tracking | `operation_bookings`, `trip_events`, `trip_passengers`, `trip_route_points`, `trip_seats`, `trip_station_progress` (filter `trip_id=eq.<tripId>`) |
| `.stream(primaryKey:['id'])` on `notifications` (×2) | notifications | own rows, inbox list + unread count |

### 4.6 GoTrue (auth) endpoints used

`POST /auth/v1/signup`, `POST /auth/v1/token?grant_type=password`, `POST /auth/v1/recover`,
`PUT /auth/v1/user` (password + metadata), `POST /auth/v1/logout`, plus the SDK's implicit
`POST /auth/v1/token?grant_type=refresh_token` and the deep-link code exchange for password recovery.

---

## 5. Cross-cutting vocabulary (exact wire values)

**`operation_trips.status`** (as exposed through `public_trips`): `open_for_booking` (the only
sellable status), `boarding`, `in_progress`, `completed`. `scheduled` and `cancelled` are hidden
from the client by the view. Client-side rule: `lib/apps/client/core/utils/bookable_trip.dart`.

**`trip_seats.state`**: `available` | `reserved` (locked, or paid-pending-review) | `paid`. Seat
availability is **always** counted from `trip_seats` — the denormalised `booked_seats` counter is
not maintained by the booking flow.

**`operation_bookings.status`**: `draft` | `reserved` (payment under review) | `confirmed`
(payment approved) | `boarded` | `completed` | `cancelled`.

**`operation_bookings.payment_status`**: `pending` (card, awaiting gateway) | `submitted` (receipt
uploaded, awaiting operator) | `approved` | `rejected` | `failed` | `cancelled` | `refunded`.

**`payment_method`** accepted by the booking RPCs: `credit_card` | `instapay` | `vodafone_cash` |
`bank_transfer`.

**Dates/times:** `trip_date` is `yyyy-MM-dd`; `departure_time`/`arrival_time`/`trip_time` are
Postgres `time` rendered `HH:mm:ss`; timestamps are ISO-8601 with offset.

**Money:** `numeric` columns arrive as JSON numbers (or strings for large values — the wallet
datasource guards for this); currency defaults to `EGP`.
