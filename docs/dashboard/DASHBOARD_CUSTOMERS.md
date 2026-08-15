# Dashboard — Customers

> **The honest headline: the console has no customer module.** A passenger exists in five
> places and is assembled by the operator's memory. This document describes what is
> actually there, and what that costs.

---

## 1. Where a customer appears today

| Surface | What it shows | Keyed by |
|---|---|---|
| الحجوزات | Name, phone, seat, trip, receipt, payment state | booking row |
| الاشتراكات | Package, rides used, renewals, status | subscription row |
| محفظة العملاء | Wallet balance, full ledger, refunds | wallet / client id |
| الشكاوى | Ticket text, status, internal notes, contact record | `client_id` |
| التقييمات | Written review of a completed trip | review row |

Each is a list of *events*, filtered by its own module's concerns. None of them is a list
of *people*.

---

## 2. What that costs, concretely

A passenger calls: *"I paid twice for the trip to Alexandria last Thursday and nobody
refunded me."*

To answer, a support agent must:

1. Search الحجوزات by name or phone, and eyeball dates to find the trip.
2. Open each matching booking to compare receipts.
3. Switch to محفظة العملاء, find the same person again by a different key, and read the
   ledger to see whether a refund landed.
4. Switch to الشكاوى to see whether a colleague already opened a ticket about it.
5. Optionally check الاشتراكات in case the second charge was a package.

Five modules, four searches, no shared identity, and nothing anywhere records that the
call happened. That is the single biggest usability gap in the console.

---

## 3. What already exists to build on

The pieces are in place; only the assembly is missing.

- **`clients` is a real table** with a stable id, joined by name/phone into tickets and
  wallets already.
- **`operation_bookings.client_id`** links every booking to that identity.
- **Wallets are per-customer** and already have a directory with search and paging —
  `WalletDirectoryPage` is very nearly a customer directory that happens to be sorted by
  balance.
- **`MasterDetailLayout`** is the exact pattern a customer directory would use, and three
  modules already use it.
- **Tickets already record `customer_contacted_at`**, so the notion of "we spoke to them"
  exists in the schema.

---

## 4. What is genuinely absent

- **No customer directory or profile.** No route, no screen, no cubit.
- **No lifetime value, booking count, or first/last seen** per customer.
- **No cross-module history.** Bookings, refunds, wallet movements, tickets and reviews
  are never shown on one timeline.
- **No contact log.** Calls and messages leave no trace except a ticket note.
- **No segmentation.** "Customers who booked three times last month" is unanswerable.
- **No blocklist or fraud marking.** A passenger who repeatedly uploads forged receipts
  can only be handled one booking at a time.

---

## 5. Privacy boundaries

Whatever is built must respect the lines already drawn in the database:

- Passenger name and phone are visible to the office that took the booking, and to that
  office alone (`bookings_office_manage`, `trip_passengers_office_manage`).
- Captains see the manifest for their own trip only.
- `support_tickets` with `office_id IS NULL` are EWT's, and are invisible to every office.
- The Client app never sees another passenger, and only ever sees driver and vehicle data
  through the sanitised `public_driver_profiles` / `public_vehicle_profiles` views.
- A support agent can **read** a wallet balance but cannot adjust it or approve a refund.

A customer profile screen would aggregate data the office is already entitled to see —
which is what makes it safe to build, and why it should be built rather than worked around.

See `DASHBOARD_ROADMAP.md` Phase 3.
