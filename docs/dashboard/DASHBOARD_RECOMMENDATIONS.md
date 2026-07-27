# Dashboard Recommendations

Where the EWT dashboard should go next, ordered by what it would actually be worth to an
office. Written after the Phase 1–2 audit (2026-07-27), so every item below is grounded in
something observed in the code or the live database, not in a generic feature wishlist.

Each item states the **evidence** it came from, so a reader can judge it rather than take it
on faith.

---

## How to read the priority column

| Tier | Meaning |
|---|---|
| **P0** | Correctness or money integrity. Do before adding features. |
| **P1** | Materially changes how much work an office can handle per operator. |
| **P2** | Real value, no urgency. |
| **P3** | Worth doing when the surrounding area is already open. |

---

## 1. Operational efficiency

### R1 · Automatic overdue escalation — **P1**
*Evidence:* Phase 1 added overdue-departure detection, but nothing happens when a trip goes
overdue except a badge appearing on a screen someone must be looking at.

A trip more than N minutes overdue should raise an `operational_alerts` row (the table and
bell already exist), so the desk is told rather than expected to notice. The threshold should
be per-office configuration, not a constant — a Cairo–Alexandria express and a rural feeder
route have different tolerances.

### R2 · Captain call-out from the trip card — **P1**
*Evidence:* the Live Ops trip card already displays the captain's phone number, and the
single most common response to an overdue or offline trip is to phone them.

A tel: link, and — once the captain messaging table added in `20260721130000` is wired up —
an in-app message with a canned "what is your status?" prompt. Log the contact attempt against
the trip so the next operator can see someone already tried.

### R3 · Bulk payment approval as one transaction — **P1**
*Evidence:* `bulkApprove` loops `office_approve_payment` once per booking with no surrounding
transaction (registered as risk S6 in `DASHBOARD_STATUS.md`). A failure halfway leaves half a
batch approved and no way to roll back.

A `bulk_office_approve_payment(uuid[])` RPC that approves all-or-nothing, returning per-booking
outcomes. Morning receipt review is the highest-volume repetitive task an operator does.

### R4 · Incident history and captain reliability — **P2**
*Evidence:* Phase 1 started recording `resolution_note`, `resolved_by`, `acknowledged_at` and
`acknowledged_by` on every incident. Nothing reads them back.

A history view answering "how many breakdowns has this vehicle had this quarter?" and "which
captain files the most delay reports?". The data is already accruing; only the surface is
missing. Also enables measuring **time-to-acknowledge**, the single best proxy for whether the
desk is keeping up.

### R5 · Saved filter views — **P3**
*Evidence:* every module rebuilds its filter state from scratch on each visit.

"My morning receipts", "tomorrow's departures", "unassigned trips" as named, per-operator
views.

---

## 2. Revenue

### R6 · Contradiction monitoring as a money report — **P0**
*Evidence:* Phase 2 added `booking_state_contradictions`. It currently returns zero rows, and
nothing watches it.

`paid_but_cancelled` is money the office is holding that belongs to a passenger;
`travelled_without_payment` is money the office never collected. Both are directly countable in
currency. A weekly figure — "EGP X in unresolved booking contradictions" — turns an abstract
data-integrity view into a number an owner will act on.

### R7 · Occupancy-based pricing signals — **P2**
*Evidence:* `trip_pricing` is one fare expanded across stop pairs, deliberately (see the trip
pricing model note). Nothing tells the operator whether that fare is right.

Not dynamic pricing — that would break the documented single-fare model. Instead: surface
"this route runs at 45% occupancy on Tuesdays and 95% on Thursdays" so the operator can decide
to add or drop a departure. The decision stays human; the dashboard supplies the evidence.

### R8 · Subscription renewal pipeline — **P2**
*Evidence:* `subscriptions` carries `end_date`, and nothing surfaces upcoming expiry.

A renewal queue ("12 subscriptions expire in the next 7 days") converts a passive expiry into
an outbound sales action. Cheapest revenue in the system: the customer already chose you.

### R9 · No-show and cancellation cost — **P3**
*Evidence:* `cancelled_at` is now reliably stamped (Phase 2), which makes lead-time analysis
possible for the first time.

A cancellation 10 minutes before departure costs the office a seat it cannot resell; one made
two days out costs nothing. Reporting the distribution is the prerequisite for any future
cancellation policy.

---

## 3. Customer experience

### R10 · Passenger-facing delay notification — **P1**
*Evidence:* Phase 1 detects overdue departures; the `notifications` table and client delivery
already work end-to-end.

When a trip goes overdue, tell the passengers who booked it. This is the highest-impact item on
this page for perceived service quality, and nearly all the machinery exists — an overdue trip
already knows its passengers via `trip_passengers`.

### R11 · Reason codes on rejection — **P2**
*Evidence:* payment rejection takes free text, so the same reason is phrased ten ways and
cannot be counted.

A short fixed list ("receipt unreadable", "amount mismatch", "duplicate", "wrong account")
plus optional free text. Enables "38% of rejections are unreadable receipts", which is a fixable
product problem in the client app, not an operations problem.

### R12 · Refund turnaround visibility — **P2**
*Evidence:* `refund_requests` has `status` and `reviewed_at` but no ageing surface.

Refund speed is what passengers tell their friends about. An ageing queue with a target makes
it manageable.

---

## 4. Automation

### R13 · Derive rather than duplicate — **P1 (ongoing principle)**
*Evidence:* `payment_review_status` drifted from `payment_status` on two live rows because both
were written by hand; Phase 2 fixed it by deriving one from the other in a trigger.

The same pattern is still present elsewhere and should be resolved the same way:
`operation_trips.booked_seats` and `operation_trips.revenue` are both denormalised, both
unmaintained, and both silently wrong (debt D2/D3). Either maintain them by trigger from
`trip_seats` and approved bookings, or drop them and compute on read. Leaving them as
unmaintained columns invites a future report to read one and be quietly wrong.

### R14 · Stale seat-hold release — **P2**
*Evidence:* `release_expired_seat_holds` exists as an RPC; nothing schedules it.

An abandoned checkout holds a seat until someone runs the function. A `pg_cron` schedule (or a
call on trip-board load) turns a manual chore into an invariant.

### R15 · Document expiry alerting — **P2**
*Evidence:* the driver/vehicle document model already computes `valid → expiringSoon → expired`.

Expiry should push an alert rather than wait to be noticed. A vehicle operating on an expired
licence is a regulatory exposure, not a UI nicety.

---

## 5. Platform and multi-office

### R16 · Cross-office platform console — **P2**
*Evidence:* platform admins already have office management and analytics, and
`dashboard_active_trip_fixes` already accepts a platform admin asking for any office.

A genuine cross-office live view — every office's active trips on one map — is now a small
step, and it is the natural product for whoever runs EWT itself rather than a single office.

### R17 · Close `trip_live_locations` RLS — **P0 (blocked, not deferred)**
*Evidence:* risk S1. Empirically confirmed: a direct read as an authenticated user returned
every office's positions.

Phase 1 removed the *dashboard's* dependence on the table being open, which was the
precondition. What remains is validating the client app's realtime tracking path against a
policy-protected table. **This belongs to the client workstream and must not be done blind** —
closing it without that validation would break passenger live tracking.

### R18 · Per-office operational thresholds — **P3**
*Evidence:* `boardingGrace` (10 min) and the tracking-health windows (75s / 4 min) are
constants chosen to match the captain app's 30s publish cadence.

They are good defaults and should stay defaults, but an office running intercity coaches may
want a different grace than one running city minibuses. Make them office configuration once a
second office asks.

---

## 6. Explicitly not recommended

Recording these so they are not proposed again without new evidence.

| Idea | Why not |
|---|---|
| **Dynamic / surge pricing** | Contradicts the documented single-fare model, where one ticket price expands to all stop pairs and packages are flat multiples. Would require rebuilding pricing end-to-end across three apps. |
| **Auto-cancelling past-dated open trips** | Deliberately rejected by the owner. Stale trips are *flagged* for the operator (فات موعدها), never auto-closed. |
| **A second mapping stack** | `core/widgets/maps` now serves the client, captain and dashboard. A module-specific map library would fragment marker, camera and tile behaviour. |
| **Auto-approving payments below a threshold** | The approval is the control. Automating it removes the only human check between a forged receipt and a confirmed seat. |
| **Reopening closed incidents** | Erases the record of who took ownership. A recurrence is a new report that can reference the old one. |
