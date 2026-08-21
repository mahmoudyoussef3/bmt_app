# Dashboard — Customers

> **Superseded.** This document described the absence of a customer module. That
> module now exists: **العملاء**, under `المبيعات` in the sidebar.
>
> The full documentation lives in **[`customers/`](customers/)**:
> [Overview](customers/CLIENTS_OVERVIEW.md) ·
> [Architecture](customers/CLIENTS_ARCHITECTURE.md) ·
> [Features](customers/CLIENTS_FEATURES.md) ·
> [Data model](customers/CLIENTS_DATA_MODEL.md) ·
> [UX](customers/CLIENTS_UX.md) ·
> [Known issues](customers/CLIENTS_KNOWN_ISSUES.md)

This page is kept for the problem statement, because it is still the best
description of *why* the module was built — and because §5 is a privacy boundary
that has not changed.

---

## 1. The problem it was built to solve

A passenger used to exist in five places and be assembled by the operator's
memory:

| Surface | What it shows | Keyed by |
|---|---|---|
| الحجوزات | Name, phone, seat, trip, receipt, payment state | booking row |
| الاشتراكات | Package, rides used, renewals, status | subscription row |
| محفظة العملاء | Wallet balance, full ledger, refunds | wallet / client id |
| الشكاوى | Ticket text, status, internal notes, contact record | `client_id` |
| التقييمات | Written review of a completed trip | review row |

Each is a list of *events*, filtered by its own module's concerns. None of them
was a list of *people*.

A passenger calls: *"I paid twice for the trip to Alexandria last Thursday and
nobody refunded me."* Answering it meant five modules, four searches by two
different keys, and no record anywhere that the call had happened.

---

## 2. What the module resolved

- **A customer directory and profile.** `/customers`, `CustomersCubit` +
  `CustomerProfileCubit`, five tabs.
- **Lifetime totals, booking counts and first/last seen**, aggregated
  server-side per request rather than stored.
- **Cross-module history on one timeline.** Bookings, payments, boardings,
  subscriptions, wallet movements, reviews, tickets and settled refunds, unioned
  by `office_customer_activity`.
- **Directory-level segmentation**, in the four filters — subscription, upcoming
  trip, activity window, account status.

---

## 3. What is still absent

- **No contact log.** Calls and messages still leave no trace except a ticket
  note. This is the oldest remaining gap.
- **No blocklist or fraud marking.** A per-office block would need a new table
  and a decision about what it prevents; `clients.status` is the passenger's own
  account state and the office does not own it.
- **No arbitrary segmentation.** "Customers who booked three times last month"
  is still unanswerable.

See [`customers/CLIENTS_KNOWN_ISSUES.md`](customers/CLIENTS_KNOWN_ISSUES.md) for
the full list, including the data the database cannot expose to an office at all.

---

## 4. Privacy boundaries

Unchanged, and the module respects every line already drawn in the database:

- Passenger name and phone are visible to the office that took the booking, and
  to that office alone (`bookings_office_manage`, `trip_passengers_office_manage`).
- Captains see the manifest for their own trip only.
- `support_tickets` with `office_id IS NULL` are EWT's, and are invisible to
  every office.
- The Client app never sees another passenger, and only ever sees driver and
  vehicle data through the sanitised `public_driver_profiles` /
  `public_vehicle_profiles` views.
- A support agent can **read** a wallet balance but cannot adjust it or approve a
  refund.

The module aggregates data the office is already entitled to see — which is what
made it safe to build, and why it was built rather than worked around. It adds
one capability, `customers_view`, granted to both roles and checked server-side
in every RPC, and it writes nothing.

`clients` has no `office_id`; scoping comes from `office_owns_client` and the
`clients_office_read` policy, both of which predate the module.
