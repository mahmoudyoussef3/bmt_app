# Dashboard · Subscriptions (الاشتراكات) + Packages catalogue (الباقات)

Two things live in this module:

1. **Subscriptions** — the office's book of sold multi-ride packages (`subscriptions` table): list,
   detail, manual creation (pending payment), confirm payment, renew, consume a ride, cancel, plus the
   ride-usage ledger and a trip picker.
2. **Packages catalogue** (`plans/`) — the office's `transport_packages` rows (what the client app
   sells and what a trip's fare menu is built from).

**Two worlds trap** (see `../README.md` §5 and `docs/API_DOCUMENTATION.md` §10.8): the client booking flow writes `transport_packages` /
`transport_subscriptions`; this tab reads `subscriptions` (+ the legacy `packages` table for the
creation picker). `approve_payment` mirrors a multi-ride booking into `subscriptions` so it appears here.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/subscriptions/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.subscriptions` = `/subscriptions`) |
| Cubits | `presentation/cubit/subscriptions_cubit.dart`; `plans/presentation/cubit/subscription_plans_cubit.dart` |
| Use cases | `domain/usecases/` (`GetSubscriptionsUseCase` — also used by Home/Business Overview, `GetSubscriptionDetailsUseCase`, `CreateSubscriptionUseCase`, `CancelSubscriptionUseCase`, `RenewSubscriptionUseCase`, `MarkRideUsedUseCase`, `ConfirmSubscriptionPaymentUseCase`, `GetSubscriptionTripsUseCase`, `GetRideUsageUseCase`, `GetCreationOptionsUseCase`); `plans/domain/usecases/` |
| Repo | `data/repositories/subscriptions_repository_impl.dart` |
| **Datasources** | `data/datasources/supabase_subscriptions_datasource.dart` (`SupabaseSubscriptionsDatasource`), `plans/data/datasources/subscription_plans_datasource.dart` (`SubscriptionPlansDatasource`) |
| Models / entities | `data/models/user_subscription_model.dart`; `domain/entities/user_subscription.dart` (`SubscriptionStatus`, `SubscriptionType`, `SubscriptionCreationOptions`), `subscription_trip.dart` (`SubscriptionTrip`, `SubscriptionRideUsage`); `plans/domain/entities/subscription_plan.dart` (`SubscriptionPlan`, `PlanStatus`) |
| Permission | `DashboardPermission.subscriptions` (admin only); feature key `passenger_packages` |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| S1 | List (newest 1 500) | `POST rpc/office_expire_overdue_subscriptions` → `GET subscriptions?select=<embed>&order=created_at.desc&limit=1500` | `GET /api/v1/dashboard/subscriptions` |
| S2 | Detail | same RPC → `GET subscriptions?id=eq.` | `GET /api/v1/dashboard/subscriptions/{id}` |
| S3 | Create (manual, pending payment) | `POST subscriptions` | `POST /api/v1/dashboard/subscriptions` |
| S4 | Cancel | `PATCH subscriptions {status:'cancelled'}` | `POST /api/v1/dashboard/subscriptions/{id}/cancel` |
| S5 | Renew | `POST rpc/office_request_subscription_renewal` → `GET subscriptions?id=eq.<new>` | `POST /api/v1/dashboard/subscriptions/{id}/renew` |
| S6 | Confirm payment | `POST rpc/office_confirm_subscription_payment` → re-read | `POST /api/v1/dashboard/subscriptions/{id}/confirm-payment` |
| S7 | Consume a ride | `POST rpc/office_consume_subscription_ride {p_subscription_id, p_trip_id}` → re-read | `POST /api/v1/dashboard/subscriptions/{id}/consume-ride` |
| S8 | Trips picker | `GET operation_trips?select=…&office_id=eq.&order=trip_date.desc,departure_time.desc` (unbounded) | `GET /api/v1/dashboard/trips?fields=minimal` |
| S9 | Ride usage ledger | `GET subscription_ride_usage?select=id,subscription_id,trip_id,used_at&office_id=eq.&order=used_at.desc` | `GET /api/v1/dashboard/subscriptions/ride-usage` |
| S10 | Creation options | `GET clients?limit=200`, `GET packages?status=neq.archived`, `GET operation_routes?office_id=eq.&status=neq.archived` | `GET /api/v1/dashboard/subscriptions/creation-options` |
| P1 | Catalogue packages | `GET transport_packages?office_id=eq.&trip_id=is.null&order=display_order` | `GET /api/v1/dashboard/packages` |
| P2 | Create package | `GET max(display_order)` → `POST transport_packages` | `POST /api/v1/dashboard/packages` |
| P3 | Update package | `PATCH transport_packages?id=eq.` | `PATCH /api/v1/dashboard/packages/{id}` |
| P4 | Activate / pause | `PATCH transport_packages {active}` | `PATCH /api/v1/dashboard/packages/{id}/status` |
| P5 | Delete package | `DELETE transport_packages?id=eq.` | `DELETE /api/v1/dashboard/packages/{id}` |

`RLS`: `subscriptions_office_manage` (`FOR ALL`, `office_id = current_office_id()`), `transport_packages`
office policy + marketplace read. The subscriptions datasource has **no error mapping** — Postgres
messages surface raw; `plans/` wraps writes in `LicensingGuard.run`.

---

## S1 / S2 — List & detail (`fetchSubscriptions()` line 24, `fetchSubscriptionDetails()` line 35)

```
POST /rest/v1/rpc/office_expire_overdue_subscriptions   {}   → 200 <int rows expired>
GET  /rest/v1/subscriptions
  ?select=*,client:clients(full_name,phone),package:packages(id,title,days,trips_count),
          route:operation_routes!subscriptions_route_fk(id,name,start_city,end_city)
  &order=created_at.desc&limit=1500
```

`BUSINESS RULE` — `office_expire_overdue_subscriptions` (`20260721090300_multi_office_rpcs.sql:330`): on
**every** list/detail load, sets `status='expired'` for the caller's office rows where `status='active'
and end_date < current_date`. There is no cron; the read path expires. Replace with a scheduled job or a
computed status.

Row → `UserSubscriptionModel` (`_fromRow` line 249):

| Field | Source |
|---|---|
| `id, userId=client_id, packageId, routeId, originTripId, originBookingId` | columns |
| `userName / userPhone` | `customer_name/customer_phone` ?? `client.full_name/phone` |
| `packageName` | `package.title` ?? `package_name` ?? 'باقة' |
| `routeLabel` | route `name` or `'<start_city> → <end_city>'` ?? `route_name` |
| `type` | derived from `package.days`: ≤1 oneTime, ≤7 fiveDays, ≤14 tenDaysMonthly, ≥80 threeMonths, else monthly |
| `price=total_price, paidAmount, remainingAmount, renewalsCount` | numeric/string tolerant |
| `totalRides=trips_count ?? package.trips_count`, `usedRides=trips_used`, `remainingRides=clamp(total−used)` | |
| `status` | `active` / `expired` / `cancelled` / `pending_payment`\|`paused` → pendingPayment (default) |
| `startDate, endDate (default now+30d), createdAt, updatedAt` | |

`SUPABASE-SPECIFIC`: the `!subscriptions_route_fk` hint disambiguates the embed. **Proposed .NET:**
`GET /api/v1/dashboard/subscriptions?status=&search=&page=` with `client`, `package`, `route` flattened.

---

## S3 — Create: `createSubscription(subscription)` (line 46)

```
POST /rest/v1/subscriptions      Prefer: return=representation
{ office_id, client_id?, customer_name, customer_phone, package_id?, package_name, route_id?,
  route_name: <routeLabel or packageName>, start_date, end_date, status:'pending_payment',
  total_price, paid_amount:0, remaining_amount:<total_price>, trips_count, trips_used:0 }
```
`BUSINESS RULE` trigger `assert_subscription_route_office` (`20260731100000…:101`):
`subscription_route_office_mismatch` if `route_id` belongs to another office. `package_id` references
the **legacy `packages` table** (S10 picker), not `transport_packages`.

**Proposed .NET:** `POST /api/v1/dashboard/subscriptions { clientId?, customerName, customerPhone, packageId, routeId?, startDate, endDate, totalPrice, tripsCount }` → `201`.

## S4 — Cancel (line 80)

`PATCH subscriptions?id=eq. { status:'cancelled' }` — a direct write, no guard, no refund, no ride-ledger effect.

## S5 — Renew (line 91)

```
POST rpc/office_request_subscription_renewal { "p_subscription_id": "<uuid>" }  → 200 { …new subscription row… }
GET  subscriptions?select=<embed>&id=eq.<new id>
```
`BUSINESS RULE` (`request_subscription_renewal`, `20260731100000…:328`): copies the source row into a
**new** `pending_payment` subscription starting `max(end_date+1, today)`, lasting `packages.days`
(fallback old duration, min 1), `paid_amount 0`, `remaining = total_price`, `renewals_count + 1`,
`trips_used 0`, same route/trip/booking links. No check that the source is active.

## S6 — Confirm payment (line 120)

```
POST rpc/office_confirm_subscription_payment { "p_subscription_id" }  → 200 { …row… }
```
`BUSINESS RULE` (`confirm_subscription_payment`, `20260706100000…`): only when `status='pending_payment'`
(else raises `'Subscription is not awaiting payment'` — a sentence, not a code); sets `active`,
`payment_review_status='accepted'`, `paid_amount=total_price`, `remaining_amount=0`,
`start_date=max(start_date, today)`, `end_date=start + packages.days − 1`.
**No wallet/finance ledger entry is written** — the money is only reflected in `paid_amount`.

## S7 — Consume a ride (line 106)

```
POST rpc/office_consume_subscription_ride { "p_subscription_id", "p_trip_id": "<uuid>|null" }  → 200 { …row… }
```
`BUSINESS RULE` (`consume_subscription_ride`, `20260731100000…:238`): requires `active`, `start_date ≤ today ≤ end_date`,
rides left (`trips_count = 0` means unlimited); `trips_used + 1`; auto-`expired` when the last ride is used;
inserts `subscription_ride_usage { subscription_id, office_id, trip_id, recorded_by }` — the unique index
per (subscription, trip) raises `ride_already_recorded_for_trip`. Wrapper adds `trip_not_found` /
`cross_office_denied` for the trip. Error for an inactive row is a sentence ('Subscription is inactive, expired, or has no rides left').

## S8 / S9 / S10 — pickers and ledger

* S8 `fetchTrips()` (line 134): **all** office trips, newest first — unbounded.
* S9 `fetchRideUsage()` (line 161): `subscription_ride_usage` for the office, newest first — unbounded.
* S10 `fetchCreationOptions()` (line 182): `clients` (**global, first 200 by name — `clients` has no
  `office_id`**, so every rider on the platform is offered), `packages` (legacy table, non-archived, by
  price), office routes (non-archived). `NEEDS BACKEND DECISION`: scope the client picker to riders who
  booked with the office (as the Customers module does).

---

## P1–P5 — Packages catalogue (`subscription_plans_datasource.dart`)

```
GET /rest/v1/transport_packages?select=id,name_ar,name_en,package_type,price,duration_days,ride_count,description_ar,description_en,active,display_order
    &office_id=eq.<office>&trip_id=is.null&order=display_order.asc
POST /rest/v1/transport_packages
{ office_id, name_ar, name_en, package_type: <existing or 'custom_<hash>'>, price, duration_days, ride_count,
  description_ar, description_en, active, display_order: <max+1> }
PATCH /rest/v1/transport_packages?id=eq. { same minus office_id/display_order }
PATCH /rest/v1/transport_packages?id=eq. { active: true|false }
DELETE /rest/v1/transport_packages?id=eq.
```
`trip_id IS NULL` excludes trip-scoped packages (see `trips/` T14). `package_type` is a free-text
discriminator (a dropped enum); `PlanStatus.active ⇔ active=true`, paused otherwise. Delete has no guard —
`trip_package_prices.package_id` / `operation_bookings.package_id` references are left to FK behaviour.
`BUSINESS RULE` (pricing model): packages are flat prices, never `rides × fare`; the single-ride shape is
the ticket, not a package.

**Proposed .NET:** `GET/POST/PATCH/DELETE /api/v1/dashboard/packages`, `PATCH /packages/{id}/status`.
Refuse delete when priced on a trip or referenced by a booking.

---

## Notes for the .NET team

1. Expiry is done **on read** today. Move it to a job (or compute `effectiveStatus`) and drop the RPC.
2. Three subscription-ish tables exist: `subscriptions` (this tab, finance, reports, client "my package"),
   `transport_subscriptions` (ride ledger written by `approve_payment`), `packages` (legacy catalogue used
   only by the S10 picker and the day-count math in renew/confirm). Consolidate; until then keep all three
   paths writing the same facts.
3. The client-picker is not office-scoped (`clients` has no `office_id`).
4. Confirm-payment does not touch the wallet/finance ledgers; Finance derives subscription revenue from
   `subscriptions.paid_amount` (see `finance/`).
5. Error strings from these RPCs are English sentences, not codes — normalise to codes
   (`subscription_not_pending`, `subscription_not_consumable`, `ride_already_recorded_for_trip`, …).
