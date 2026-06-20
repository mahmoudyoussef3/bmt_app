# Client App — Business Flow & Architecture

> App brand: **EasyWay / BMT** · Platform: Flutter (mobile + tablet) · Backend: **Supabase**
> (Postgres, Auth, Storage, Realtime, Edge Functions) · Payments: **Paymob** via a Supabase
> Edge Function.
>
> This document is the source of truth for the Client App's business workflows, the
> backend contracts it depends on, and the remaining backend work required to remove the
> last functional gaps. It complements the repo-level `PROJECT_INDEX.md`, `CLAUDE.md`,
> `AGENTS.md`, and the partial `docs/supabase_schema.sql`.

---

## 1. Business Overview

EasyWay is a daily-commute / intercity shuttle booking product. Operations (routes,
trips, vehicles, drivers, pricing, packages) are **owned by the Dashboard** and are the
single source of truth. The Client App is a **read-mostly consumer** of that operational
data plus a **transaction surface** for bookings, payments, subscriptions, seat release,
loyalty, referrals, and support.

The Client App never owns operational entities. It creates passenger-scoped records
(bookings, payment receipts, support tickets, seat locks) and reads operational state.

## 2. Target Users

- **Daily commuters** booking a recurring seat on a fixed route/time.
- **Occasional riders** booking a one-time trip on a popular route.
- **Subscribers** who buy a package (monthly/weekly) for a route and manage usage,
  renewals, and seat release.

## 3. Core User Stories

1. As a new user I am onboarded, then I sign up / sign in with email + password.
2. As a rider I search a route (pickup, destination, date, time) and see available trips.
3. As a rider I pick a vehicle and an available seat and pay (card via Paymob, wallet
   transfer with receipt, or cash on boarding).
4. As a rider I track my active trip live on a map (vehicle position, ETA, timeline).
5. As a subscriber I view my package usage and release seats I will not use, earning
   compensation when the seat is rebooked.
6. As a user I open support tickets / refund requests and follow their status.
7. As a user I earn loyalty points and referral rewards and redeem vouchers.
8. As a user I manage my profile, notification preferences, language, and theme.

## 4. End-to-End User Journey

```
First launch
  Splash (ClientSplashScreen)
   → Onboarding (only if not seen before — persisted via OnboardingCubit)
   → Welcome → Sign In / Sign Up / Forgot Password   [Supabase email+password]
   → Client Shell (bottom navigation)

Client Shell tabs
  Routes Hub · My Trips · Notifications · Profile  (+ Home/search entry)

Booking funnel
  Home/Search entry → Search Trip → Route/Map Selection → Available Trips
   → Vehicle Listing → Vehicle Details → Seat Selection (lock seat)
   → Payment Checkout → (success) Booking confirmed → My Trips → Trip Details
   → Live Tracking

Subscription funnel
  Routes Hub / Packages → Subscription screen → choose plan → pay → active subscription
   → Seat Release Center (manage daily seats)

Support funnel
  Profile/Support → Support Center → Create Ticket / Create Refund → Ticket Details
```

The app entry, routing table, and per-feature `BlocProvider` scopes live in
[client_app.dart](../lib/apps/client/client_app.dart). Auth gating is driven by
`Supabase ... onAuthStateChange`; onboarding gating by `OnboardingCubit`.

## 5. Architecture

Clean Architecture, enforced per feature under `lib/apps/client/features/<feature>/`:

```
presentation/   screens · widgets · cubit (Cubit + State)
domain/         entities · repositories (contracts) · usecases
data/           datasources (abstract + Supabase impl) · models · repositories (impl)
```

Dependency direction is strictly `presentation → domain → data`. Domain is
framework-independent (no Flutter imports). UI talks only to Cubits; Cubits talk only to
UseCases; UseCases talk to repository contracts; repositories delegate to datasources.

- **DI:** `get_it` via `clientGetIt`, registered in
  `lib/apps/client/core/di/client_di.dart` and invoked from `ClientApp.initState`.
- **Theme/tokens:** `lib/apps/client/core/theme/` (`client_colors`, `client_typography`,
  spacing) plus shared `lib/core/theme`.
- **Shared widgets:** `lib/apps/client/core/widgets/` (client buttons, skeletons, error
  cards) and `lib/core/widgets/`.
- **Localization:** Flutter `gen-l10n` from `lib/l10n/app_en.arb` / `app_ar.arb`
  → `AppLocalizations`. Locale is controlled by `LocaleCubit`. The Client App UI is
  English; the platform remains bilingual (the Dashboard uses Arabic).

## 6. State Management

`flutter_bloc` Cubits, one per feature, each exposing a small immutable state
(loading / loaded / error variants). Screens render with `BlocBuilder` /
`BlocSelector` at the smallest scope. No repository or datasource access from widgets.

## 7. Modules & Responsibilities

| Module | Responsibility | Primary backend |
| --- | --- | --- |
| `onboarding` | First-run intro, "seen" flag | local persistence |
| `auth` | Email/password sign in/up, reset, sign out | Supabase Auth, `clients` |
| `home` | Search entry, featured routes/trips, price preview | `operation_trips`, `operation_routes`, `route_stations`, `trip_pricing` |
| `routes` | Route discovery hub | `operation_routes`, `route_stations` |
| `booking` | Search → routes → trips → vehicle selection | `operation_trips`, `operation_routes`, `route_stations`, `trip_pricing` |
| `seat_selection` | Seat map, lock + confirm booking | `trip_seats`, `operation_trips`, RPC `lock_trip_seat` / `confirm_seat_booking` |
| `payments` | Methods, Paymob card session, receipt upload | `payment_methods`, Storage `payment-receipts`, Edge `paymob-create-intention` |
| `trips` | My trips, trip details, review, cancellation | `operation_bookings`, `operation_trips` |
| `tracking` | Live map, vehicle position, timeline, ETA | `trip_live_locations`, `trip_route_points`, `operation_trips` |
| `packages` | Plans, subscribe, usage, receipt | `packages`, `package_vehicle_tiers`, `subscriptions` |
| `seat_release` | Release daily seats, compensation view | `subscriptions`, `operation_bookings` |
| `notifications` | In-app notifications list | `notifications` |
| `support` | Tickets, refund requests, attachments | `support_tickets`, `support_attachments`, `refund_requests` |
| `communication` | Support conversation threads | `operation_complaints` (`conversation` JSONB) |
| `loyalty` | Points, tiers, vouchers | `loyalty_accounts`, `loyalty_tiers`, `loyalty_rewards`, `loyalty_transactions` |
| `referrals` | Referral code, rewards | `referrals` |
| `profile` / `settings` | Profile, preferences, language, theme, FAQ, terms | `clients`, Supabase Auth metadata |

## 8. Backend Tables & Functions Used (inferred from client queries)

Tables: `clients`, `operation_routes`, `route_stations`, `operation_trips`,
`trip_pricing`, `trip_seats`, `trip_route_points`, `trip_live_locations`,
`operation_bookings`, `subscriptions`, `packages`, `package_vehicle_tiers`,
`payment_methods`, `notifications`, `support_tickets`, `support_attachments`,
`refund_requests`, `operation_complaints`, `loyalty_accounts`, `loyalty_tiers`,
`loyalty_rewards`, `loyalty_transactions`, `referrals`.

> Note: `docs/supabase_schema.sql` is a **partial** dump (core operations tables only).
> Several client-referenced tables above (e.g. `route_stations`, `trip_seats`,
> `trip_live_locations`, `payment_methods`, `notifications`, `support_*`) exist in the
> live database but are not in that file.

RPCs: `lock_trip_seat`, `confirm_seat_booking`, `book_trip_seat` (deprecated).
Storage buckets: `payment-receipts`.
Edge Functions: `paymob-create-intention`
([source](../supabase/functions/paymob-create-intention/index.ts)).

## 9. Payment Flow

1. Client loads active methods from `payment_methods` (graceful empty state if the table
   is not provisioned).
2. **Card (Paymob):** Client calls Edge Function `paymob-create-intention` with the
   booking id, amount (minor units), currency `EGP`, trip context, the method's
   `integration_id` / `iframe_id`, and customer contact. The function returns a
   `checkout_url`, opened in a WebView. **No Paymob keys live in Flutter** — the function
   reads `PAYMOB_API_KEY`, `PAYMOB_CARD_INTEGRATION_ID`, `PAYMOB_IFRAME_ID` from
   Supabase secrets (`Deno.env`).
3. **Wallet transfer / InstaPay:** user transfers manually and uploads a receipt image
   to Storage `payment-receipts` (a time-boxed signed URL is persisted on the booking).
4. **Cash on boarding:** booking is created as pending cash.
5. States handled: loading, success, failure (function error surfaced), cancelled
   (WebView dismissed), retry. Final booking/payment status must be committed by the
   Edge Function or a Paymob webhook (server-authoritative).

Source: [supabase_payment_datasource.dart](../lib/apps/client/features/payments/data/datasources/supabase_payment_datasource.dart).

## 10. Booking Flow

Search query (`BookingSearchQuery`) → trips from `operation_trips` joined with
`operation_routes` / `route_stations` / `trip_pricing` → vehicle selection →
**seat selection with a real lock**: `lock_trip_seat` (RPC) holds the seat, then
`confirm_seat_booking` (RPC) commits it, creating an `operation_bookings` row. Seat
states map from `trip_seats.state` (`available` vs reserved). Lock/booking errors
(`seat_unavailable`, `lock_expired`, `trip_full`) are surfaced as typed exceptions.
Seats are never generated client-side; if trip/route/seat/pricing rows are missing the
UI shows an error/empty state, not fake fallback data.

## 11. Live Trip Flow

`tracking` resolves the active `operation_bookings` row → `trip_id`, then reads:
`trip_route_points` (polyline + stop names), `operation_trips` (+ joined
route/driver/vehicle metadata), and the latest `trip_live_locations` row (vehicle
position/heading/speed). Trip status maps to a `TrackingTripState` timeline
(Booking confirmed → Driver on the way → Boarding → Trip started → Arrived). When there
is no active trip/location, a clean empty state is shown — no fake vehicle markers.

> **Enhancement (recommended):** subscribe to `trip_live_locations` via Supabase Realtime
> for push updates instead of one-shot reads; otherwise add a polling timer.

## 12. Package / Subscription Flow

Plans from `packages` (+ `package_vehicle_tiers`) are loaded for real. Activating a plan
persists a real `subscriptions` row via `PackagesCubit.subscribe()` →
`CreateSubscriptionUseCase` → `SupabasePackagesDatasource.createSubscription` (columns
match the Dashboard: `client_id`, `package_name`, `route_name`, `start_date`, `end_date`,
`status='active'`, `total_price`, `paid_amount`, `remaining_amount`), and the receipt
shows the real returned subscription id. The Seat Release Center reads the active
`subscriptions` row and upcoming `operation_bookings` to let the user release a daily
seat; cancelled bookings this month are used as the released-seats proxy. Usage numbers
and percentages are derived from real rows — no fake prices or fabricated percentages.

## 13. Support / Ticket Flow

`support` creates `support_tickets` (+ `support_attachments`) and `refund_requests`,
and lists/opens them with live status. `communication` reads support conversation
threads from `operation_complaints.conversation` (JSONB). Tickets are visible to the
Dashboard for handling.

## 14. Notifications Flow

`notifications` are read per user from the `notifications` table and rendered in the
Notifications tab; relative timestamps are formatted in English in the model layer.
Tapping a notification routes to the relevant destination.

> **Enhancement (recommended):** add push delivery (FCM) and a realtime subscription on
> `notifications` for unread badges.

## 15. Error / Loading / Empty State Strategy

- **Data layer** catches exceptions and maps Postgrest/storage/function errors to typed
  `Exception`s with English messages. Missing-table codes (`PGRST205`, `42P01`) degrade
  to empty results so optional surfaces show empty states rather than crashing.
- **Domain** returns typed results to Cubits.
- **Presentation** renders loading skeletons (`client_skeleton`), empty states, and
  error cards (`client_error_card`) with retry. Loading skeletons are acceptable; fake
  business data is not. The shared `AsyncStateView` is a Dashboard helper and is
  intentionally not used by the Client App.

## 16. Security Notes

- Paymob API keys/secrets live only in the Edge Function via Supabase secrets; the client
  only ever receives a `checkout_url`. **Do not** move any gateway secret into Flutter.
- All passenger data access is auth-scoped (`auth.currentUser.id`); rely on Supabase RLS
  to enforce row ownership server-side.
- Receipt uploads use per-user, per-booking storage paths and time-boxed signed URLs.
- Seat locking is server-authoritative through RPC / DB constraints.
- Password reset uses the `easyway://reset-password/` deep link.

---

## 17. Changes Applied in This Audit Pass

**Arabic → English (no mixed UI):** removed all Arabic from the Client App. Affected
data sources: `settings`, `seat_release`, `tracking`, `seat_selection`, `home`,
`booking_search`, `vehicle_booking` (status labels, reasons, day names, timeline labels,
exception messages, currency symbol `ج.م` → `EGP`). Verified: zero Arabic remains under
`lib/apps/client`.

**Fake/hardcoded data removed:**
- `supabase_settings_datasource` no longer fabricates Arabic FAQs, terms, and a fake
  "current device". Editorial help content moved to English constants in
  `settings_static_content.dart`; the active session is now derived from the real
  authenticated session; default language defaults to `en`.
- Removed the unreachable `/subscription-confirmation` route that injected a hardcoded
  `EGP 1,200/month` price, plus its now-orphaned screen.

**Dead-ends / "claims-without-action" fixed:**
- Trip Details "Call" now launches the real dialer (`tel:`) via `url_launcher` instead of
  showing the number in a snackbar.
- Referral "copy code" / "share", Loyalty "copy voucher", and Subscription "copy id"
  now actually write to the clipboard (previously claimed success without copying).
- Removed the dead `more_vert` button in the communication app bar.

**Dead code removed:** unused `SocialSignInButton` widget; orphaned subscription
confirmation screen.

**Simulated logic replaced with real backend writes:**
- **Subscription activation** now persists a real `subscriptions` row
  (`PackagesCubit.subscribe()` → `CreateSubscriptionUseCase` →
  `SupabasePackagesDatasource.createSubscription`) and surfaces the real id + activation
  errors. The previous timer + client-generated `SUB-YYYY-XXXXX` id is gone.
- **Support messaging** now persists to `operation_complaints.conversation` (JSONB)
  via `CommunicationCubit.addMessage` → `SendConversationMessageUseCase` →
  `SupabaseCommunicationDatasource.appendClientMessage` (optimistic add + backend
  write, client-scoped). The fake "agent auto-reply" simulation was removed.

**Live tracking confirmed live:** `TrackingCubit` already polls `trip_live_locations`
every 10s (`Timer.periodic` → silent refresh) and cancels on trip completion / cubit
close — the map updates without a manual refresh.

All changes verified with `flutter analyze` → **No issues found**; client tests pass.

---

## 18. Known Gaps & Required Backend Work

These items need backend provisioning or a larger build-out; the client architecture is
in place / documented but the feature is not yet fully live.

1. **In-app calls (`communication`).** Messaging is now **real** — client messages
   persist to `operation_complaints.conversation` and the fake auto-reply was removed.
   **Still required:** (a) Realtime/polling on `operation_complaints` so agent replies
   appear live, and (b) a real telephony/VoIP path for the in-app "call" UI (or replace
   it with a `tel:` deep link to a support line). The call screen still simulates audio
   levels and should be treated as preview until (b) lands.

2. **FAQs & legal content.** No `faqs` / legal table exists (confirmed against
   `docs/supabase_schema.sql`). Content is English static constants in
   `settings_static_content.dart`. **Required:**
   `app_faqs(id, category, question, answer, sort_order, locale)` and
   `app_legal_sections(id, title, body, progress, sort_order, locale)`; then load from
   Supabase and drop the constants.

3. **Cross-device sessions.** The settings "active sessions" list can only show the live
   session. **Required:** `user_sessions(id, user_id, device, platform, last_active_at,
   is_current)` to manage/revoke other devices.

4. **Terms & Privacy links** in the auth footer show a "will open when published" notice.
   **Required:** hosted URLs (open via `url_launcher`) or in-app legal screens backed by
   `app_legal_sections`.

5. **Social sign-in (Google/Apple).** Removed as dead UI. **Required (if desired):**
   configure Supabase OAuth providers and add a real `signInWithOAuth` flow.

6. **Boarding QR** (`trip_qr_card`) is a decorative placeholder. **Required:** add a QR
   package (e.g. `qr_flutter`) and encode the real booking reference / check-in token.

7. **Multi-passenger booking** (`seat_passenger_preview_card`,
   `passenger_info_bottom_sheet`) is UI-only. **Required:** extend the booking RPC to
   accept multiple passengers + per-passenger details.

8. **Vehicle images** (`vehicle_image_strip`) render local placeholders. **Required:**
   a `vehicles.image_urls` source; fall back to placeholders only while loading.

9. **Live tracking transport.** ✅ Implemented — `TrackingCubit` polls
   `trip_live_locations` every 10s and cancels on completion. Optional upgrade: switch
   polling to a Supabase Realtime subscription to cut latency and battery use.

10. **Payment methods table.** `payment_methods` must expose `type`/`code`, `title`,
    `is_active`, `sort_order`, and a `metadata` JSON with `integration_id`, `iframe_id`,
    `gateway`, `transfer_account`, `account_holder`, `supported_channels`, `instructions`.

11. **Cancellation / refund / review persistence.** Confirm these write to backend
    (`refund_requests`, booking status, a reviews table) rather than only showing a
    success snackbar.

12. **Subscription activation persistence.** ✅ Implemented — `PackagesCubit.subscribe()`
    writes a real `subscriptions` row and returns the id. **Optional follow-up:** route
    the activation through the Paymob/wallet payment step before marking it paid (today it
    records `paid_amount == total_price` on activation).

### Code-health follow-ups (non-blocking)
Several presentation files greatly exceed the 120-line guideline
(`settings_screen.dart` ~1.8k lines, `subscription_screen.dart`, `seat_release_screen.dart`,
`communication_screen.dart`). Recommend decomposing them into smaller widgets in a
dedicated refactor pass.
