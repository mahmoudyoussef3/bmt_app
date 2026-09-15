# Dashboard · Customers (العملاء — Customer 360)

A read-only directory of the office's riders with a 360° profile: KPIs, filtered/paged directory,
profile metrics, trips (upcoming/past), subscriptions, payments, and an activity timeline.
**Read-only by design** — the module changes nothing; wallet/refund actions live in `wallet/`.
Everything is an RPC because `clients` carries **no `office_id`**: "my customer" is derived
(`office_owns_client`: has a booking, a subscription or a wallet with the office).

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/customers/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.customers` = `/customers`; browse → workspace split pane) |
| Cubit | `presentation/cubit/customers_cubit.dart` |
| Use cases | `domain/usecases/` (one per RPC) |
| Repo | `data/repositories/customers_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_customers_datasource.dart` (`SupabaseCustomersDatasource implements CustomersDatasource`) |
| Mapper / models | `data/models/customer_models.dart` (`CustomerMapper.overview/directory/profile/trips/subscription/payments/activity`) |
| Entities | `domain/entities/customer.dart`, `customer_profile.dart`, `customer_trip.dart`, `customer_subscription.dart`, `customer_payment.dart`, `customer_activity.dart`, `customer_filters.dart` |
| DI | `customers_di.dart` |
| Permission | `DashboardPermission.customers` (both roles) — server: `office_can('customers_view')` (both roles) |

## Operations

| # | Operation | Today (Supabase RPC) | Proposed .NET |
|---|---|---|---|
| C1 | Overview KPIs | `office_customers_overview()` | `GET /api/v1/dashboard/customers/overview` |
| C2 | Directory (filters, sort, paged) | `office_customer_directory(p_search, p_subscription, p_upcoming, p_activity, p_status, p_sort, p_limit, p_offset)` | `GET /api/v1/dashboard/customers` |
| C3 | Profile | `office_customer_profile(p_client_id)` | `GET /api/v1/dashboard/customers/{clientId}` |
| C4 | Trips (upcoming / past, paged) | `office_customer_trips(p_client_id, p_scope, p_limit, p_offset)` | `GET /api/v1/dashboard/customers/{clientId}/trips?scope=` |
| C5 | Subscriptions | `office_customer_subscriptions(p_client_id)` | `GET /api/v1/dashboard/customers/{clientId}/subscriptions` |
| C6 | Payments (paged) | `office_customer_payments(p_client_id, p_limit, p_offset)` | `GET /api/v1/dashboard/customers/{clientId}/payments` |
| C7 | Activity timeline | `office_customer_activity(p_client_id)` (`p_limit` default 40) | `GET /api/v1/dashboard/customers/{clientId}/activity` |

All RPCs (`20260820150000_office_customers_module.sql`) are `stable security definer`, `authenticated`,
and start with `customers_office_guard()` (`not_an_office_user`, `not_authorized` unless
`office_can('customers_view')`) then `customers_client_guard(p_client_id)` (`not_authorized` when
`office_owns_client` is false — **a foreign client id is indistinguishable from no permission**, by design).
Datasource maps `not_an_office_user`, `not_authorized`, `client_not_found`; `LicensingGuard.check` first.

---

## C1 — Overview: `fetchOverview()` (`supabase_customers_datasource.dart:38`)

`POST rpc/office_customers_overview {}` → `{ total_customers, active_customers (30-day activity),
with_active_subscription, with_upcoming_trip, new_customers (this month) }`. Counted over the whole owned
base, unaffected by directory filters.

## C2 — Directory: `fetchDirectory({filters, limit, offset})` (line 48)

```
POST rpc/office_customer_directory
{ "p_search": "<text>|null", "p_subscription": "active"|"none"|null, "p_upcoming": "has"|"none"|null,
  "p_activity": "active"|"dormant"|null, "p_status": "<clients.status>|null",
  "p_sort": "recent"|"name"|"bookings"|"upcoming"|"paid", "p_limit": 25, "p_offset": 0 }
→ 200 { "total": n, "rows": [ { client_id, full_name, phone, email, status, active_package_name,
          bookings_total, bookings_cancelled, bookings_completed, first_booking_at, last_booking_at,
          next_trip_date, total_paid, last_payment_at, last_wallet_at, last_activity_at } ] }
```
`BUSINESS RULE`: owned = clients with a booking ∪ subscription ∪ wallet with the office; search matches
name/phone/email `ilike` or `client_id` prefix; `active` = activity within 30 days, `dormant` = none in 90;
`p_limit` clamped 1..100; sort fallback by name.

## C3 — Profile: `fetchProfile(clientId)` (line 75)

`office_customer_profile { p_client_id }` → `{ client:{ client_id, full_name, phone, email, status, joined_at },
metrics:{ bookings_total, bookings_upcoming, bookings_completed, bookings_cancelled, first_booking_at, last_booking_at,
next_trip_date, boarded_count, no_show_count, total_paid, payments_count, last_payment_at, subscriptions_total,
active_subscriptions, refunds_settled_amount, tickets_total, tickets_open, reviews_count, avg_office_rating,
wallet_balance, wallet_currency, wallet_status, last_wallet_at }, active_subscription:{…}|null, top_routes:[…] }`.
`client_not_found` when the `clients` row is gone.

## C4 — Trips: `fetchTrips(clientId, {upcoming, limit, offset})` (line 88)

`office_customer_trips { p_client_id, p_scope: 'upcoming'|'past', p_limit: 20, p_offset }` →
`{ total, rows:[ { booking_id, booking_number, trip_id, trip_date, departure_time, route, seat, trip_status, booking status,
payment status, boarding_status, via_subscription, via_package, subscription_name, … } ] }`.

## C5 — Subscriptions: `fetchSubscriptions(clientId)` (line 111)

`office_customer_subscriptions { p_client_id }` → `[ { …subscriptions row…, is_current, trips_remaining, usage_percent } ]`.

## C6 — Payments: `fetchPayments(clientId, {limit, offset})` (line 129)

`office_customer_payments { p_client_id, p_limit: 20, p_offset }` → `{ total, total_approved, rows:[ …booking payments… ],
wallet:{…}, wallet_transactions:[…] }`.

## C7 — Activity: `fetchActivity(clientId)` (line 146)

`office_customer_activity { p_client_id }` → `[ { kind, at, subject, reference, amount } ]` with `kind ∈
payment_submitted | payment_approved | booking_cancelled | boarded | no_show | subscription_created |
refund_settled | ticket_opened | review_submitted`, newest first, 40 max.

---

## Notes for the .NET team

1. There is **no customer write** in this module — no edit, no merge, no block. Freezing a wallet is in `wallet/`.
2. Keep the ownership predicate (`office_owns_client`) as the single definition shared with the wallet RPCs;
   the .NET equivalent is one query the customer, wallet and notification endpoints all call.
3. The rider's identity table (`clients`) is platform-global; the office sees a rider only through what the
   rider did with the office. Do not add `office_id` to customers — one rider uses many offices.
4. Paging is real here (server `total` + `limit/offset`); this is the module shape the rest of the console
   should converge to.
