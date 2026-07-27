# Operations Manual — a day on the EWT desk

How an office operator actually uses the dashboard, from signing in to closing the day.
Written as a working procedure, not a feature tour: each step says what to look at, what it
means, and what to do about it.

Modules referenced here are described in `DASHBOARD_FEATURES.md`; the flows are drawn in
`DASHBOARD_USER_FLOWS.md`; what is broken or missing is in `DASHBOARD_STATUS.md`.

**Two roles use this manual.** The owner (`المالك`) can do everything below. The support agent
(`خدمة العملاء`) sees live operations, bookings, tickets, reports, payment verification and
notifications — and is deliberately read-only on incident closure. Where a step is
owner-only, it says so.

---

## Before the first shift: what the dashboard assumes

The desk cannot run without these already in place. If a step below has nothing to show, this
is usually why.

1. **Routes exist** with stations in order, each with coordinates. Without coordinates a trip
   cannot be drawn on any map.
2. **Vehicles exist** with a seat layout (Hiace 14 / Coaster 30). The layout is what booking
   sells; a vehicle without one cannot carry a trip.
3. **Captains are approved** and assigned to the office.
4. **A ticket price is set per trip.** One fare, expanded to every stop pair — packages are
   flat multiples of it. There is no second price to enter.

---

## 1. Start of day — situational awareness first

**Open العمليات المباشرة (Live Operations) before anything else.** It is the only screen that
tells you about problems happening *now*; everything else can wait a few minutes.

Read it top to bottom:

| What you see | What it means | What to do |
|---|---|---|
| Red **بلاغ طوارئ نشط** banner | A captain has filed an SOS | Handle it before anything else on this page |
| **على الطريق** | Trips currently running | Context, not an action |
| **تأخّر الانطلاق** > 0 | Trips still boarding more than 10 minutes past schedule | Work these first — see §2 |
| **تتبع متعثّر** > 0 | Vehicles whose position feed is stale, offline or never started | See §3 |
| **بلاغات مفتوحة** with *"N لم يُستلم بعد"* | Incidents nobody has claimed | Claim them — see §4 |

The map below the summary shows every vehicle that is reporting a position, coloured by
tracking health. **Vehicles missing from the map are not missing trips** — the legend says how
many are running without a position, and they are all still listed in الرحلات على الطريق below.

The board refreshes itself (realtime plus a 15-second poll). You do not need to reload it, and
a brief network failure will not blank it — it keeps showing the last good picture.

---

## 2. Working an overdue departure

A trip is marked **تأخّر الانطلاق** when it is still boarding more than 10 minutes past its
scheduled time. Under 10 minutes is normal loading and is not flagged.

1. Tap the trip card — the map focuses on that vehicle.
2. Check the tracking badge. **غير معروفة** (never shared a position) usually means the captain
   has not opened the app or granted location permission; that is a different conversation from
   a captain who is stuck in traffic.
3. Call the captain (number is on the card).
4. Decide:
   - **Delay is short** — nothing to change; the trip will depart and the badge will switch to
     *انطلقت متأخرة* with the real lateness.
   - **Vehicle or captain unavailable** — reassign affected bookings to another departure from
     the bookings module (§5), or cancel the trip.

A trip already on the road is never "overdue". It may be shown as having *departed late*, which
is context for a passenger complaint, not a task.

---

## 3. Working a tracking problem

| Badge | Age of last position | Most likely cause | Action |
|---|---|---|---|
| **حية** | under 75s | Healthy | None |
| **متأخرة** | 75s – 4 min | A dropped update | Glance again on the next refresh |
| **غير متصلة** | over 4 min | Lost signal or the app was closed | Call the captain |
| **غير معروفة** | never reported | Location permission never granted, or sharing never started | Call the captain; this recurs unless fixed on their device |

Tracking health says nothing about whether the trip is running well — a captain with a dead
phone may be perfectly on schedule. Treat it as *"can I still see this vehicle?"*, not
*"is this trip in trouble?"*.

---

## 4. Working the incident queue

Reports arrive from captains on the road. The queue is ordered worst-first: emergencies above
breakdowns above delays, and within each level, unclaimed reports above ones someone already
owns.

**The workflow is two steps, deliberately.**

1. **استلام (claim).** One tap, no dialog. This tells every other operator that you own this
   report, so nobody calls the same captain twice. Do it *before* you pick up the phone, not
   after.
2. **تم الحل or استبعاد (close).** Both require a note.
   - **تم الحل** — the problem was dealt with. Write what you actually did: *"تم إرسال مركبة
     بديلة ونقل الركاب"*. This is the only record anyone will have next month.
   - **استبعاد** — no action was needed (a duplicate, a test, a mis-tap). Say which. Dismissed
     reports are kept out of the resolved-work statistics on purpose.

A claimed report stays on the board until you close it. If a colleague closed it while your
screen was stale, your action is refused with an explanation rather than overwriting theirs.

*Owner only.* Support agents see the full queue — that is why they have the module — but the
action buttons are not rendered for them.

---

## 5. Mid-morning — the receipt queue

Open **الحجوزات** (or **التحقق من المدفوعات** for the dedicated queue).

Open a booking and read the banner at the top of the inspector. It states one thing to do and
why. You should not need to interpret the two status chips yourself.

| Banner | Meaning | Action |
|---|---|---|
| **مراجعة الدفع** | A receipt is uploaded and waiting | Open the receipt, then approve or reject |
| **طلب إيصال** | Marked for review but no receipt attached | Ask the passenger to upload one |
| **بانتظار العميل** | Seat held; passenger has not paid, or must re-upload after a rejection | Nothing — the desk is not blocked |
| **جاهز للسفر** | Paid and confirmed | Nothing |
| **تعارض في الحالة** (red) | Booking state and payment state disagree | **Stop and resolve this first** — see below |

### Approving

Check the amount against the fare and the reference against the office account. Approving is
atomic: it confirms the booking, marks the seat paid, registers the passenger on the trip and
notifies the customer, all together. There is no half-approved state.

### Rejecting

Always give a real reason — the passenger sees it and needs to know what to fix. A rejected
receipt can be replaced by a better one without rebooking, which is the point.

### Contradictions

A red tile means the booking's money and its seat disagree. Each has one correct remedy:

| Contradiction | What actually happened | Remedy |
|---|---|---|
| **الحجز ملغى والدفع معتمد** | The seat was released but the office still holds the passenger's money | Refund the passenger |
| **الحجز مؤكد والدفع غير معتمد** | A seat is committed and blocking capacity with nothing collected | Collect, or release the seat |
| **الراكب سافر دون اعتماد الدفع** | Someone travelled without a settled payment | Collect, or write it off with a documented note |

Do not approve, reject or reassign a booking showing a red tile until the contradiction is
resolved — acting on it makes the disagreement worse.

---

## 6. Building tomorrow — trips

Open **الرحلات**.

1. Create the trip: route, date, departure time, vehicle, captain, ticket price.
2. Assigning a vehicle brings its seat layout with it; that layout is what the client app sells.
3. Move the trip to **مفتوحة للحجز** when you want it on sale. Until then it exists but sells
   nothing — that unpublished state *is* the draft, and it is where a trip should sit until it
   is genuinely ready.
4. Trips whose date has passed while still open are flagged **فات موعدها**. They are never
   closed automatically — that is a deliberate decision, so a trip you actually ran is not
   silently cancelled while you were busy. Close them yourself, with the honest answer:
   **نُفّذت بالفعل** if it ran, **لم تُنفَّذ** if it did not. The first records it as completed
   without spamming riders about a departure that already happened; the second cancels it and
   tells them.

The status ladder is **scheduled → open_for_booking → boarding → in_progress → completed**, with
cancellation available at any point before completion. Captains drive `boarding` and
`in_progress` from their app; the desk does not need to. **You cannot skip a rung** — the
database refuses it, whichever screen the request comes from.

### If فتح الحجز is greyed out

The trip is not ready to sell. The button says which of these is missing:

| Message | Fix |
|---|---|
| لا يوجد سائق معيّن | Assign a captain |
| لا توجد مركبة معيّنة | Assign a vehicle |
| لم يتم تجهيز مقاعد | The vehicle had no seat layout when the trip was made — fix the vehicle, remake the trip |
| لم يتم ضبط أسعار الرحلة | Open the **الأسعار** tab and set the fare. **This one matters most:** without it the client app charges the package catalogue price, not yours |
| تاريخ الرحلة قد فات | The departure day is in the past; the client app would never show it |

### Cancelling a trip

**إلغاء الرحلة** is on every trip that has not finished. Before you confirm, the dialog tells
you how many riders and seats it affects. You are asked for a reason, and once the captain has
started boarding a reason is **required** — that cancellation strands people who are already at
the stop, so the record has to say why.

Cancelling releases every seat, cancels every booking and passenger, and notifies every affected
rider — including ones whose receipt you had not reviewed yet.

**It does not refund anybody.** Money that was already approved stays approved, because nothing
has actually been paid back. Those bookings appear in the payments screen as paid-but-cancelled,
and that is your refund worklist.

### Deleting vs cancelling

Delete only works on an unpublished trip with no bookings — a genuine mistake you want gone.
Everything else must be **cancelled**. Deleting a booked trip would strip the trip off paying
customers' bookings with no refund trail and no notification, so the option is disabled with
that reason shown.

---

## 7. End of day

1. **Live Operations** — the incident queue should be empty, or every remaining report claimed
   with someone's name on it. Nothing should be sitting unclaimed overnight.
2. **Bookings** — no red contradiction tiles left. These are money problems and they do not
   improve with age.
3. **Receipts** — the review queue cleared, or the remainder genuinely waiting on customers.
4. **Trips** — tomorrow's departures exist, are open for booking, and each has a captain and a
   vehicle.
5. **Tickets** — nothing unanswered from today.

---

## 8. Things the dashboard guarantees

You can rely on these; they are enforced, not conventions.

- **A failed action never loses your workspace.** Filters, selection and the open record all
  survive; the error tells you the real reason.
- **You cannot approve a payment into a broken state.** The database refuses a booking that is
  not `reserved` or has no submitted receipt, and it updates booking, payment, seat, passenger
  and notification together or not at all.
- **You cannot reopen a closed incident**, and you cannot silently overwrite a colleague's
  resolution.
- **You only ever see your own office's data.** This is enforced by the database, not by the
  screen — there is no filter to get wrong, and no URL to tamper with.
- **A cancelled booking always records when it was cancelled.**
- **The live board never lies about tracking.** A vehicle that has not reported is shown as
  unknown or offline; it is never drawn at a guessed position.

## 9. Things it does *not* do yet

So you do not wait for them. Full list in `DASHBOARD_STATUS.md` and
`DASHBOARD_RECOMMENDATIONS.md`.

- Overdue trips do **not** notify anyone — you have to be looking at the board.
- Passengers are **not** told automatically when their trip is delayed.
- There is no incident history view; closed reports are recorded but not yet readable back.
- Seat holds from abandoned checkouts are not released on a schedule.
- Bulk payment approval is not atomic — approve large batches in smaller groups.
