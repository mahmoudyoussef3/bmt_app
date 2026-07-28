# Client App — Features

One row per feature directory under `lib/apps/client/features/`. "Backend" names
the surfaces the feature actually queries.

| Feature | What it does | Backend | Notes |
|---|---|---|---|
| `onboarding` | First-run intro, "seen" flag | local (SharedPreferences) | 5.9 MB of PNGs — see `CLIENT_PERFORMANCE.md` |
| `auth` | Email/password sign in / up / reset, Remember Me | Supabase Auth, `clients` | Session persists via Supabase's own cache; Remember Me is a separate local cache |
| `home` | Search entry, departures board, active booking, quick actions | `operation_routes`, `public_trips`, `operation_bookings` | Realtime signal is unfiltered — see `CLIENT_PERFORMANCE.md` §2.1 |
| `offices` | Office directory + office profile (departures, routes, packages) | `public_offices`, `operation_routes`, `public_trips`, `packages` | Empty profile now ends in two ways onward, not a dead end |
| `routes` | Route discovery hub | `operation_routes`, `route_stations` | |
| `booking` | Search → routes → trips → **wizard** (stops, seat, package, payment) | `public_trips`, `operation_routes`, `route_stations`, `trip_pricing` | The only live booking funnel |
| `seat_selection` | Seat map data + the lock/confirm/release use cases | `trip_seats`, RPC `lock_trip_seat`, `confirm_seat_booking_v2`, `release_trip_seat_lock` | Its **screen** is retired; the wizard consumes its cubit and use cases |
| `payments` | Methods, Paymob session, receipt upload, card settlement | `payment_methods`, storage `payment-receipts`, Edge `paymob-create-intention`, RPC `card_payment_state` | Standalone checkout screens retired |
| `trips` | My Trips, Trip Details, cancellation, review | `operation_bookings`, `public_trips`, `trip_seats`, `trip_reviews`, RPC `cancel_booking_by_client` | Now carries three state axes + attention model |
| `tracking` | Live map, position stream, route progress, ETA | `trip_live_locations`, `trip_route_points`, `public_trips` | |
| `packages` | Plan marketplace (multi-office), My Subscription | `transport_packages`, `packages`, `subscriptions` | Catalogue only; plans are bought inside the wizard |
| `seat_release` | Release a subscription day's seat, compensation view | `subscriptions`, `operation_bookings` | Screen exceeds the 120-line guideline |
| `notifications` | Inbox, unread badge, category filter, **tap routing** | `notifications` | Destination now derived from `type` + `data` |
| `support` | Tickets, refund requests, attachments, office picker | `support_tickets`, `support_attachments`, `refund_requests`, storage `support-attachments` | Attachment RLS fixed 2026-07-30 |
| `communication` | Support conversation threads | `operation_complaints.conversation` (JSONB) | Agent replies do not arrive live; the "call" screen is a preview |
| `loyalty` | Points, tiers, vouchers | `loyalty_accounts`, `loyalty_tiers`, `loyalty_rewards`, `loyalty_transactions` | |
| `referrals` | Referral code, rewards, leaderboard | `referrals`, `referral_leaderboard` | |
| `profile` | Profile, preferences, language, theme, legal | `clients`, Supabase Auth metadata | FAQ/legal are static constants — no backing table exists |

## Cross-cutting

| Concern | Where |
|---|---|
| Design system | `core/theme/client_*` + `core/widgets/client_*` (`ClientButton`, `ClientCard`, `ClientAppBar`, `ClientSkeleton`, `ClientStatusBadge`, `ClientErrorCard`, `ClientBottomSheet`) |
| Money formatting | `core/utils/client_money.dart` — one format across the app |
| Localization | `context.l10n` (`AppLocalizations`), `en` + `ar`, RTL-aware |
| Maps | `lib/core/maps` shared with Captain and Dashboard |
| Tracking engine | `lib/core/tracking` shared with Captain and Dashboard |
| Push | `lib/core/notifications/fcm_service.dart`, per-app destination resolver |

## Feature-level gaps

| Gap | Impact |
|---|---|
| **No FCM sender exists.** `notification_tokens` is written but nothing reads it — there is no Edge Function or trigger that sends a push. | Push notifications are never delivered. The in-app inbox works (realtime). |
| **No booking event timeline.** | See `CLIENT_HISTORY.md` §6 |
| **No re-payment entry from My Trips.** | See `CLIENT_BOOKING_LIFECYCLE.md` §6 |
| **`promo_codes` table does not exist.** | Promo validation always returns 0; the UI that used it is retired |
| **No wallet balance table.** | `PaymentMethodType.walletBalance` is unbacked |
| **FAQ / legal have no table.** | Static constants in `settings_static_content.dart` |
| **Multi-passenger booking is UI-only.** | The RPC takes one passenger |
| **Boarding QR is decorative.** | No check-in token is encoded |
