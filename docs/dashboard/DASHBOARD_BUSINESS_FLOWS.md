# Dashboard — Business Flows

The workflows an office actually performs, in the order they happen, with the module that
owns each step and the server object that enforces it.

---

## 1. Standing up an office

```
Sign up (3 fields)  ──▶ register_office RPC
                          │
                          ├─ office status = active   → the dashboard works immediately
                          └─ listing_status = draft   → invisible to passengers
                                    │
                          EWT publishes it (مكاتب المنصة) → listed
```

The split matters and the sign-up form says it out loud: an operator who is not told their
office is unlisted reads an empty marketplace as a broken product.

Platform-side onboarding (`مكاتب المنصة`) is the other door: EWT creates the office and
its first admin using a service-role Edge Function.

---

## 2. Building capacity

```
المسارات        create route ──▶ add stations (name first, GPS optional)
                                  ──▶ order them, set dwell time, boarding rules
                                  ──▶ optional: calculate distance/duration via geo provider

إدارة الأسطول    add vehicle  ──▶ pick type ──▶ seat layout IS the capacity
                 add driver   ──▶ personal + licence data
                 assign       ──▶ one active vehicle per driver (trigger-enforced)
                 documents    ──▶ expiry dates feed the Home attention panel

طلبات الكباتن    captain applies with the office join code
                          ──▶ owner approves ──▶ becomes a driver record
```

Every create here is quota-gated: `before insert` triggers on `drivers`, `vehicles`,
`operation_routes` check `max_drivers` / `max_vehicles` / `max_routes`.

---

## 3. Selling a trip

```
الرحلات ─ planner
   1. route
   2. date + departure/arrival time
   3. DRIVER  ──▶ vehicle derived from that driver's active assignment
                  (no vehicle picker; a trigger refuses a mismatched pair)
   4. fare    ──▶ ONE ticket price, expanded to every stop pair
                  packages are flat multiples of it (×3.5 / ×3.75 / ×4 / ×4.5)
   5. publish ──▶ status open_for_booking, visible via public_trips
```

Two invariants that get violated by well-meaning changes:

- **There is never a second price input.** One fare per trip; everything else is derived.
- **Trips are not auto-expired.** A past-dated open trip is *flagged* to the operator
  ("فات موعدها"), never silently closed. That is the owner's explicit choice.

Creating a trip consumes `max_trips_per_month`.

---

## 4. A booking becomes money

```
Client app: passenger picks seat, pays, uploads receipt
        │
        ▼
operation_bookings row  ·  payment_status = submitted  ·  seat held
        │
        ▼
الحجوزات (or مراجعة المدفوعات) — operator opens the receipt
        │
        ├─ approve  ──▶ office_approve_payment RPC
        │                 ├─ seat confirmed
        │                 ├─ passenger record created
        │                 ├─ notification fired to the client
        │                 └─ amount becomes earned revenue
        │
        ├─ reject   ──▶ office_reject_payment RPC
        │                 └─ seat released
        │
        └─ ask again ──▶ request reupload (receipt unreadable)
```

**The dashboard never writes booking status columns directly.** Every transition goes
through an audited `SECURITY DEFINER` RPC so seat holds, passenger records and
notifications stay consistent. Bulk approve/reject in الحجوزات loops the same RPCs.

---

## 5. Running the day

```
العمليات المباشرة
   active trips (boarding · in_progress)
      ├─ tracking health   live / stale / offline / unknown
      ├─ departure status  pending / due / overdue / departed
      └─ seats sold vs capacity

   incident queue (from the Captain app)
      pending ──▶ acknowledged ──▶ resolved | dismissed
                     └─ says a human already owns this, so a second
                        operator does not call the same captain
```

Boarding itself is driven by the Captain app station by station; the dashboard observes.
`trip_live_locations` is written only by the captain's 30-second publisher.

---

## 6. Money going back out

```
Refund request (client or operator raised)
        │
        ▼
محفظة العملاء — refund queue
        │
        ├─ approve ──▶ wallet credit  ──▶ customer balance rises
        │                                 (a LIABILITY, not an expense line)
        └─ reject
                        │
                        ▼
              المركز المالي reports the position
              net revenue = collected − EXECUTED refunds
```

Three rules that are load-bearing:

1. A refund is **not** a second ledger row — it is mirrored onto the booking it reverses.
   Counting it separately double-subtracts.
2. A refund **request** is a liability signal, not a revenue movement. It sits outside the
   ledger until executed.
3. Finance **reads**. Refund decisions happen in محفظة العملاء, payment decisions in
   الحجوزات. Finance has no approve button anywhere and must not grow one.

Cancelling a trip offers a batch refund of its bookings.

---

## 7. After the trip

```
Trip completed
   ├─ التقييمات    passenger reviews land here — the only place written feedback exists
   ├─ الشكاوى      complaints route to the office by trip code, or by last booking
   ├─ المركز المالي  the money is recognised
   └─ التقارير      trips / bookings / revenue / drivers / vehicles / complaints
```

---

## 8. Provisioning a colleague

```
المستخدمون والصلاحيات — owner creates a staff login
        │
        ├─ SQL owns membership   (office_users row)
        └─ Edge Function owns the auth user (service role; the client SDK cannot)

Rules:
  · an operator cannot change their own role
  · an operator cannot disable themselves
  · removal is a DISABLE, never a delete — history must survive
  · creating staff consumes max_admin_users
```

---

## 9. The licence in the background

Every one of the flows above sits under the same three predicates:

```
role_permits ∧ office_entitled ∧ quota_allows
```

When the server refuses on the middle or right predicate, the datasource's
`LicensingGuard` publishes the refusal, the shell consumes it, refreshes the entitlement
document, and raises the upgrade card over whatever the module already said. The office
is never left guessing which of the three refused it.
