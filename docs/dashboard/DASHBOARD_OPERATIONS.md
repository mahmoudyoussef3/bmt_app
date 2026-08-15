# Dashboard — Operations

> The question this half of the console answers: **"Can I successfully run today's
> transportation?"**

---

## 1. The operator's day

```
الرئيسية              What needs me right now?
   │  attention panel: unreviewed receipts, expiring documents,
   │  captain applications, open incidents, stale trips
   ▼
العمليات المباشرة      What is on the road, and is anything wrong?
   │  active trips + tracking health + incident queue
   ▼
الرحلات               Today's departures — seats, driver, bus, pricing
   │
   ▼
الحجوزات              The receipt queue — approve, reject, ask again
   │
   ▼
الشكاوى               What went wrong, and who is chasing it
```

---

## 2. الرئيسية — the console

Answers four questions in the order an operator asks them:

1. **How are we doing today?** — greeting line and four KPIs: today's trips, today's
   bookings, today's revenue, occupancy.
2. **Is anything broken?** — the attention panel, full width, directly under the KPIs. It
   is the one thing that must never be scrolled past, which is why it does not live in a
   side rail.
3. **What is running, and what came in?** — today's departures beside the newest bookings.
4. **How is the business trending?** — revenue line, route occupancy, standing capacity,
   activity feed.

It owns no query of its own: nine sibling use cases, composed. Since this pass it
tolerates any one of them failing, and names what it lost rather than blanking the page.

Occupancy is derived from real seat counts (booked ÷ capacity across today's trips), never
a fabricated percentage. The revenue series counts only bookings whose payment reached
approved, and is therefore labelled "الحجوزات" and not "الإيرادات" — folding in
subscription revenue would mean guessing, because subscriptions are not in that list.

---

## 3. العمليات المباشرة — the live board

The only reader of `trip_live_locations` and `driver_trip_reports`. Refreshes on a
realtime trigger *and* a steady poll, because realtime alone drops silently.

**Tracking health** is reported honestly rather than assumed:

| State | Meaning |
|---|---|
| حية | A recent fix arrived |
| متأخرة | Fixes are arriving, but stale |
| غير متصلة | The publisher has stopped |
| غير معروفة | This trip has never reported a position |

Positions come from the `dashboard_active_trip_fixes` RPC — one latest fix per active trip
in a single `distinct on`, rather than a feed per vehicle reduced client-side.

**Departure status** flags trips that are `due` or `overdue` against their scheduled time.

**Incident queue** — captain-raised reports, typed (طوارئ / عطل / إغلاق طريق / مشكلة راكب /
تأخير / أخرى) and severity-graded. The workflow is
`pending → acknowledged → resolved | dismissed`, and `acknowledged` is the state that
makes a shared desk work: it says a human already owns this report, so a second operator
does not call the same captain about the same problem. Resolving requires
`liveOpsIncidentAction`, which a support agent does not have.

---

## 4. الرحلات — the trip module

The largest module in the console. Three views of the same list (list, grouped, timeline),
a creation wizard, and a detail workspace with seats, pricing, passengers and events.

Operating rules:

- **A trip takes a driver.** The vehicle comes from that driver's active assignment and is
  snapshotted onto the trip. If the driver has no bus, the planner sends the operator to
  التعيينات — the fix is one screen away and the planner cannot make it.
- **One fare.** Set once, expanded to every stop pair; packages are flat multiples.
- **Past-dated open trips are flagged, not closed.** "فات موعدها" is a prompt for the
  operator. There is no expiry cron, by the owner's explicit choice.
- **Cancelling** offers a batch refund of the trip's bookings.

---

## 5. الحجوزات — the queue

Ordered by what an operator does, not by what is easiest to render: summary → filters →
**the queue** → reporting. Four analytics charts used to sit between the header and the
list, so the screen the office opens dozens of times a day started with a scroll.

Every action is an audited RPC (`office_approve_payment`, `office_reject_payment`,
reupload request, reassignment). Bulk approve/reject loops the same RPCs rather than
taking a shortcut.

---

## 6. What the operator still has to do by hand

Real gaps, argued in `DASHBOARD_ROADMAP.md`:

- **No-shows have no workflow.** Seat state records that a passenger did not board;
  nothing surfaces it, counts it, or lets an operator act on it.
- **Cancellations are not reported.** They are visible per booking, invisible in aggregate.
- **Station progress is not on the dashboard.** The Captain app drives boarding station by
  station; the operator sees the trip's overall status but not which stop it is at, except
  through the live map.
- **Delay does not propagate.** A trip that departs late does not annotate the trips
  behind it on the same route or the same bus.
- **Reaching a captain is not one click.** The board shows a phone number; contacting is
  manual and unlogged. The in-app captain chat was removed by the owner's decision in
  August 2026, and ops now reaches captains only through the notifications bell.
