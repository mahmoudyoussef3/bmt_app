# Captain App — Recommendations

> What to build next and why, ranked by business value rather than engineering appetite.
> **Nothing in this document is implemented.** It exists to be argued with and prioritised.
>
> **Companions.** [`CAPTAIN_APP_STATUS.md`](CAPTAIN_APP_STATUS.md) (what is done) ·
> [`CAPTAIN_APP_BUGS.md`](CAPTAIN_APP_BUGS.md) (what is broken) ·
> [`CAPTAIN_APP_BUSINESS_SERVICES.md`](CAPTAIN_APP_BUSINESS_SERVICES.md) (what the
> platform could sell).
>
> **Last revised.** 2026-07-23.

---

## Classification

| Tier | Meaning |
| --- | --- |
| **Critical** | Closes a live risk or an outage the customer can see. Do these first. |
| **High value** | Moves a business number — retention, trust, compliance. |
| **Medium value** | Clear benefit, no urgency. |
| **Nice to have** | Polish. Do them when they are cheap. |

---

# Critical

## R1 · Close `trip_live_locations` RLS without breaking delivery

**Business problem.** Every position of every vehicle on the platform is readable and
writable by anyone, authenticated or not. The write path is defended (the driver on each
fix is server-resolved), so this is a **confidentiality and integrity** risk rather than a
spoofing one — but a competitor or a curious user can currently watch the entire fleet
move in real time, and any authenticated user could inject false positions into a
customer's tracking map.

**Why it is still open.** The table is kept open because Realtime delivery to client maps
was verified in that configuration. Enabling RLS blind risks a silent outage on the single
most customer-visible feature. That trade was correct to make; it is not correct to keep.

**Proposed solution.**
1. Write a SELECT policy for clients holding a booking on the trip, plus an INSERT policy
   mirroring the verified write path.
2. Apply inside `BEGIN … ROLLBACK` and confirm the policies admit the right rows.
3. **Verify with a real subscribed client map before committing** — this is the step that
   cannot be skipped, and the reason this is a task rather than a patch.

**Benefit.** Removes the last known open surface on the captain data plane.
**Complexity.** Medium — the policy is easy; the delivery verification is the work.
**Priority.** Highest of the open items.

## R2 · Somewhere for an incident to land

**Business problem.** A captain can file an incident or hold the SOS control for three
seconds, and the report reaches a table **no Dashboard screen reads**. The app promises
escalation and delivers a database row. In an emergency that is worse than offering
nothing, because the captain stops looking for another way to get help.

**Proposed solution.** An operations inbox for `driver_trip_reports` — list, filter by
office, acknowledge, resolve — plus a push to the on-duty operator when a report arrives.
The RLS policy for office access already exists (added in BUG-302), so the data layer is
ready.

**Captain benefit.** Reporting does something.
**Business benefit.** Duty of care, and the raw material for incident analytics.
**Complexity.** Medium — one Dashboard surface plus a notification hook.
**Priority.** Do with or immediately after R1.

---

# High value

## R3 · Background / foreground-service location

**Business problem.** Sharing is foreground-only. The moment the captain pockets the phone
or the screen locks, the client's map goes stale. This is the largest remaining gap in
tracking fidelity and the one most visible to paying customers — **a tracking feature that
silently stops is worse for trust than one that was never promised.**

Note that BUG-301 fixed a *different* silent stop (scrolling). This one remains and is by
design.

**Proposed solution.** An Android foreground service and iOS background location modes,
with the cadence tuned for battery and a persistent notification telling the captain that
sharing is active — which is also the honest thing to do.

**Captain benefit.** Stops having to keep the app open.
**Business benefit.** The map stops going dark mid-trip.
**Complexity.** High — platform permissions, store review, battery tuning, and a privacy
position worth writing down before starting.
**Priority.** First feature after the two critical items.

## R4 · Emergency escalation beyond a report

**Business problem.** SOS currently files a form. Real help means a call placed, an
operator paged, and the vehicle's position pinned for whoever responds.

**Proposed solution.** Build on R2: an SOS raises a distinct alert class that pages the
on-duty operator, surfaces the live position, and offers the captain a one-tap call.

**Captain benefit.** Help while driving, not a ticket.
**Business benefit.** Safety compliance and duty of care.
**Complexity.** Medium, once R2 exists.

## R5 · Captain earnings / payout view

**Business problem.** Drivers leave fleets that are opaque about pay. This is consistently
the most requested feature in comparable products, and the app currently says nothing
about money at all.

**Proposed solution.** A per-day and per-trip earnings view, driven by whatever payout
model the business settles on.

**Captain benefit.** Sees what the day earned.
**Business benefit.** Retention — the cheapest driver is the one who does not leave.
**Complexity.** Medium, and **blocked on a payout model existing first**. That decision is
the prerequisite, not the screen.

---

# Medium value

## R6 · Performance & punctuality analytics

On-time percentage, ratings trend, passengers carried. Gives the captain an objective
picture of their own work and the business a quality signal it can build an incentive
scheme on. The trip and review data already exists.
**Complexity.** Medium.

## R7 · Document-expiry reminders

Licence and vehicle papers, warned before they lapse. An expired licence discovered at a
checkpoint is a cancelled trip, a stranded busload and a fine. **The expiry data is already
on the profile** — this is mostly a reminder job and a card.
**Complexity.** Low–Medium. The best value-per-effort item on this list.

## R8 · Offline queue for status and location

Intercity routes have dead zones. Nothing is lost today — only delayed — but a queue would
make the Cairo–Alexandria desert road behave like everywhere else.
**Complexity.** Medium. Justify it with route telemetry before building it.

## R9 · Trip completion proof (photo or signature)

Settlement evidence, and protection for the captain in a dispute about whether a trip ran.
**Complexity.** Medium — needs storage and an upload path, which R11 also wants.

---

# Nice to have

## R10 · Thread list on the trip chats page

The page offers one entry — message all passengers — while per-passenger threads are
reachable only from the manifest. A captain looking for "the conversation with the
passenger in seat B3" has to know the route. Listing the trip's active threads closes it.
**Complexity.** Low.

## R11 · Real voice notes and photo attachments in chat

Restores the two controls removed in BUG-203, properly this time. Needs storage, upload
and playback — the same infrastructure R9 needs, so sequence them together.
**Complexity.** Medium.

## R12 · Shift / availability declaration

Lets a captain flag unavailability in the app instead of phoning the office.
**Complexity.** Medium — needs an operations-side scheduling concept to be useful.

## R13 · In-app fuel & maintenance log

Fleet cost visibility from the person closest to the vehicle.
**Complexity.** Medium.

## R14 · Retire the legacy `admins` and `user_roles` tables

Not captain scope, but found by this audit. Both are stale, both have RLS off with full
`anon` DML, and neither is an authorisation source any more — `is_admin()` resolves
through `office_users`, `is_platform_admin()` through `platform_admins`. `user_roles` is
still read by the Dashboard tickets datasource, so that read has to move first.
**Complexity.** Low, once the Dashboard read is migrated.

---

## Recommended sequence

```
Now      → R1 Close trip_live_locations RLS      — the last open captain surface
         → R2 Incident inbox                     — makes SOS mean something
Sprint 1 → R3 Background location                — the customer-visible gap
Sprint 2 → R7 Document expiry + R10 Thread list  — cheap, compliance + polish
Sprint 3 → R4 Emergency escalation               — safety, builds on R2
Then     → R5 Earnings (once a payout model exists)
Backlog  → R6, R8, R9, R11, R12, R13, R14
```

**One caution on sequencing.** R1 and R2 are small next to R3, and the temptation will be
to start with the visible feature. R3 makes tracking better; R1 stops the fleet's live
positions being public. Order them by risk, not by demo value.

---

## What is deliberately *not* recommended

Recorded so they are not re-proposed each cycle:

| Not doing | Why |
| --- | --- |
| Letting captains cancel or publish trips | Those are operations decisions with financial consequences. Correct as-is. |
| In-app turn-by-turn navigation | The device's maps app does it better and the captain already knows theirs. |
| A second price input on trips | The platform has one fare by design — see the pricing model. |
| Auto-closing past-dated trips | Flagged for the operator instead, by the owner's explicit choice. |
