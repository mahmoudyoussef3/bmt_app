# العملاء — Data Model

What a customer is made of, where each field comes from, and what the database
does **not** hold. Verified against the live schema on 2026-08-21.

---

## 1. There is no customer table

`clients` is an identity row and nothing else:

```
clients(id, full_name, phone, email, status, created_at, updated_at)
```

No `office_id`. No counters. No last-seen. `id` is a foreign key into
`auth.users`, so a customer cannot be created by an office — they arrive by
signing up in the Client app.

Everything an office knows about a passenger lives in six office-scoped tables
keyed on `client_id`. **A customer is a join, not a row**, which is why this
module's read surface is seven RPCs rather than a table select.

---

## 2. The ownership predicate

"My office's customer" is defined once, by a function that already existed:

```sql
office_owns_client(p_client_id, p_office_id)
  -- true when the client has a booking OR a subscription OR a wallet
  -- with that office
```

It is the same sentence the `clients_office_read` RLS policy enforces on the
table. Every RPC in this module re-asks it server-side, so a client id guessed
by the caller resolves to `not_authorized` rather than to another office's
passenger.

The directory builds its base set from the office-scoped tables first — each
indexed on `office_id` — and joins back to `clients`. The reverse (scan
`clients`, test each row) would seq-scan every passenger on the platform to find
one office's own.

---

## 3. What each surface reads

| Surface | Table | Office scope | Notes |
|---|---|---|---|
| Bookings, trips | `operation_bookings` | `office_id` | Carries `route`, `trip_date`, `trip_time`, `seat`, pickup/dropoff **names** — no join to `operation_routes` needed |
| Trip state | `operation_trips` | `office_id` | Joined for `status` and `trip_code` only |
| Boarding | `trip_passengers` | **none** — scoped via `operation_trips.office_id` | `boarded_at`, `status`, `no_show_reason` |
| Subscriptions | `subscriptions` | `office_id` | `trips_count` / `trips_used` are the usage source |
| Payments | `booking_payments` | `office_id` | Gateway columns deliberately never selected |
| Wallet | `wallets`, `wallet_transactions` | `office_id` | One wallet per `(office_id, client_id)` |
| Reviews | `trip_reviews` | `office_id` | `office_rating` is this office's own score |
| Tickets | `support_tickets` | `office_id` **nullable** | Rows with a null office are EWT's and are invisible here |
| Refunds | `refund_requests` | `office_id` | Only `settled` rows are totalled |

### The boarding join, and why it goes through the trip

`trip_passengers.booking_id` is **nullable** — a passenger can be put on a
manifest at the desk without a booking row — while `trip_id` is `NOT NULL`. The
trip is therefore the only reliable way to prove a manifest row belongs to this
office, so the boarding counts join `operation_trips`, not the booking.

---

## 4. The two subscription worlds

This is the trap that cost a bug during implementation, and it is load-bearing:

```
subscriptions              ← what الاشتراكات sells and reports, and what this module lists
transport_subscriptions    ← what the booking funnel consumes rides from
```

They are **different tables for different jobs**, and:

```sql
operation_bookings.subscription_id  REFERENCES transport_subscriptions(id)
```

A trips-tab join written against `subscriptions` compiles, runs, and returns
`NULL` on every row. The package name on a booking is resolved
`operation_bookings → transport_subscriptions → transport_packages.name_ar`.

The الاشتراكات tab lists `subscriptions`, matching the module of the same name,
so the two screens never disagree.

### Usage, and when it cannot be computed

Usage is `trips_used / trips_count`. **`trips_count = 0` is a real value** —
three rows in the live data carry it. The RPC returns `usage_percent` as `NULL`
in that case rather than dividing by zero, the entity keeps it nullable, and the
UI omits the bar and says why. A 0% bar would state that the customer has used
nothing when the truth is that nothing is measurable.

### Expiry is corrected in the predicate, not in the table

`subscriptions.status` goes stale: expiry is swept by
`office_expire_overdue_subscriptions()`, which only runs when the الاشتراكات
module calls it before reading. This module is a read surface and does not mutate
on read, so "current" is computed as:

```sql
status = 'active' AND (end_date IS NULL OR end_date >= current_date)
```

---

## 5. What the office cannot see, and is not shown

Documented rather than fabricated:

| Data | Why it is absent |
|---|---|
| **Loyalty points / balance** (`loyalty_accounts`) | RLS is `client_id = auth.uid()` — self-only. An office cannot read it, and no policy was added to make it readable. |
| **Notifications** (`notifications`) | Keyed on `user_id` with no office scope. It is the passenger's private inbox. |
| **Referrals** (`referrals`) | No `office_id`. The referral programme is platform-level; the office's view of it is المنصة → برنامج الإحالة. |
| **Ride-usage ledger** (`subscription_ride_usage`) | The table exists and is **empty** (0 rows). Per-ride timestamps would allow "last used their package N days ago"; until it is populated, that insight cannot be stated and is not. |
| **Contact log** | Nothing records that an operator called a passenger. `support_tickets.customer_contacted_at` is the nearest thing and belongs to a ticket, not to the person. |
| **Card/instrument details** | Not stored anywhere. `booking_payments.gateway_response` can carry processor payload and is never selected. |

---

## 6. Status vocabularies

Reused, never re-declared. `BookingStatus` and `PaymentStatus` live in
`features/bookings/domain/entities/operation_booking.dart` and mirror the
database CHECK allowlists; this module resolves against them.

| Axis | Column | Values |
|---|---|---|
| Booking | `operation_bookings.status` | `draft` `reserved` `confirmed` `boarded` `completed` `cancelled` |
| Payment | `operation_bookings.payment_status`, `booking_payments.status` | `pending` `submitted` `under_review` `approved` `rejected` `refunded` `failed` `cancelled` |
| Boarding | `trip_passengers.status` | `reserved` `completed` `no_show` |
| Subscription | `subscriptions.status` | `active` `expired` `cancelled` |
| Client | `clients.status` | `active` (only value present today) |
| Wallet entry | `wallet_transactions.kind` | `cashback` `manual_credit` `manual_debit` `refund` |

**The three axes are drawn separately and never merged.** A confirmed booking
with an approved payment and a `no_show` manifest row is a coherent, common
record: they paid and did not turn up.

---

## 7. Indexes added by this module

Three access paths did not exist before, because nobody had asked "what has this
person done":

```sql
idx_trip_passengers_customer   ON trip_passengers (customer_id) WHERE customer_id IS NOT NULL
idx_trip_reviews_client        ON trip_reviews (client_id, created_at DESC) WHERE client_id IS NOT NULL
idx_booking_payments_client    ON booking_payments (client_id, submitted_at DESC)
```

`operation_bookings` already had `(client_id, created_at DESC)`, and
`wallet_transactions` and `refund_requests` already had theirs.

---

## 8. Migration

`supabase/migrations/20260820150000_office_customers_module.sql` — indexes, the
`customers_view` capability, two guards, seven RPCs, grants. It contains no
`INSERT`, `UPDATE` or `DELETE`.
