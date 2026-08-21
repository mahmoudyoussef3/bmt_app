# العملاء — Features

Every surface, and the column behind it.

---

## 1. Directory

### KPIs

Five counts, measured over the whole customer base — **not** the filtered page,
so they do not move when the operator narrows the list under them.

| Tile | Definition |
|---|---|
| إجمالي العملاء | Distinct clients with a booking, subscription or wallet at this office |
| العملاء النشطون | Booked at least once in the last 30 days |
| لديهم اشتراك ساري | Have a `subscriptions` row that is `active` and not past `end_date` |
| لديهم رحلة قادمة | Have a non-cancelled booking dated today or later |
| عملاء جدد | **First booking with this office** within 30 days |

"New" is measured from the first booking with *this* office, not from
`clients.created_at`: a passenger who registered two years ago and bought here
yesterday is new to this office.

Four of the five are tappable and apply the predicate that produced them, so the
number and the list behind it can never disagree — they are the same predicate
asked of the same function. عملاء جدد is not tappable: "first booking within 30
days" is not one of the four directory filters, and a tile that applied
something *close* would be worse than one that applies nothing.

The KPI block is **expanded by default**, against the console's folded-by-default
header convention. The five counts are this module's headline and each is a
shortcut; folded, العملاء opens on a table with no answer to "how many, and how
many need me". Folded it still shows a four-chip summary.

### Search

One debounced field (300 ms), matched server-side against:

- `full_name` (partial, case-insensitive)
- `phone` (partial)
- `email` (partial)
- `client_id` (**prefix**, so the short id an operator reads off a profile works)

### Filters

Four, each answering a question an owner actually asks:

| Filter | Options |
|---|---|
| الاشتراك | الكل · لديه اشتراك ساري · بدون اشتراك ساري |
| الرحلات القادمة | الكل · لديه رحلة قادمة · لا توجد رحلات قادمة |
| النشاط | الكل · نشط خلال ٣٠ يوماً · خامل منذ ٩٠ يوماً |
| حالة الحساب | الكل · نشط · موقوف · محظور (`clients.status`, the database's own vocabulary) |

**نشط and خامل are deliberately not complements.** A customer last seen 45 days
ago is neither. Calling them opposites would make the two counts sum to less
than the base and invite the owner to read the gap as a contradiction.

Filters fold into a chip summary and **persist across navigation** via
`DashboardFilterMemory` — the shell rebuilds a module from scratch on every
navigation, and rebuilding a filter by hand after every profile visit is the tax
this removes. Any filter change resets to page 1.

### Sort

Five keys, each with the one sensible direction, applied server-side: الأحدث
نشاطاً (default), الاسم, الأكثر حجزاً, أقرب رحلة, الأعلى إنفاقاً. Column headers
sort too. Letting a header toggle to "the customer who has spent least" would be
a control nobody uses standing in front of one everybody does.

### Table

Seven columns plus an action: العميل (name + phone), الحالة, الاشتراك (name +
`x من y رحلة`), الرحلة القادمة, آخر نشاط, الحجوزات (+ cancelled count), المدفوع.

Server-side paged at 25. **This is paging, not a cap** — reaching further is
another request rather than a truncation, so the module carries no
`DashboardCapNotice` and the total beside the table is the real total.

Below 1100px the same rows render as cards with their own pager; seven truncated
columns answer none of the questions the screen exists for.

---

## 2. Customer 360

### Header

Avatar initials, name, phone, email (when present), short id (first 8 chars,
uppercased — the most anyone can repeat over the phone without a mistake),
registration date, account status badge.

Three quick actions — عرض الرحلات · عرض الاشتراكات · عرض المدفوعات — which jump
to a tab of this same page. They never navigate away and never change state.

### ملخص العميل

Deterministic chips, each a function of a recorded field:

| Chip | Condition |
|---|---|
| عميل نشط | last activity ≤ 30 days |
| خامل منذ N يوماً | last activity ≥ 90 days, N named |
| لا يوجد نشاط مع المكتب | no activity and no bookings |
| لديه اشتراك ساري | a current subscription |
| اشتراكه ينتهي خلال N أيام | current subscription expiring within 7 days |
| لم يستخدم أي رحلة من اشتراكه | `trips_used == 0` **and** `trips_count > 0` |
| لديه رحلة اليوم / غداً / خلال N أيام | soonest non-cancelled booking |
| ألغى N٪ من حجوزاته (x من y) | cancellation rate ≥ 30% and ≥ 4 bookings |
| لم يحضر N رحلات | `no_show` count ≥ 2 |
| لديه رصيد في المحفظة | wallet balance > 0 |
| لديه N شكوى مفتوحة | open tickets > 0 |

No score. No prediction. Each chip that reports a share reports its denominator
with it — "٤٠٪" alone invites the reader to supply their own.

### نظرة عامة

Eight KPI tiles (bookings total / completed / upcoming / cancelled, total paid,
wallet balance, subscriptions, last activity), then two panels:

- **الاشتراك الحالي** — package, route, dates, rides used/remaining, days left,
  and a usage bar **only when it can be computed**.
- **سلوك السفر** — boardings, no-shows, attendance rate (null until a manifest
  reaches a verdict), reviews with the office's own average, tickets, refunded
  amount. Cancellations are *not* repeated here; the KPI row above carries them.

Plus **المسارات الأكثر استخداماً**, the top three routes derived from the
customer's own non-cancelled bookings. Three, because a "top route" over one or
two trips is noise.

### الرحلات

القادمة / السابقة as separate server queries, ordered in opposite directions. A
cancelled booking is always past — it is not something the passenger is still
going to do.

Columns: route (+ package name when the ride came from one), date, time,
pickup/dropoff, seat, **booking status**, **payment status + amount**,
**boarding status**, booking number. Paged at 10. Cards below 1000px.

Only the visible scope's total is shown; the other has not been fetched, and
printing a count for a list nobody loaded would be a guess.

### الاشتراكات

Every subscription with this office, current first. Per card: package, route,
status (a row still marked `active` past its end date is labelled منتهي, because
that is what it is), dates, rides count/used/remaining, price, outstanding
amount, renewals, days left, and a usage bar — or, when `trips_count = 0`, the
sentence *"لا يمكن حساب نسبة الاستخدام: هذه الباقة لا تحدد عدد رحلات."*

### المدفوعات

A money summary (total paid, wallet balance / available / lifetime credited and
debited — or *"لم تُفتح محفظة لهذا العميل"*, which is not the same statement as a
zero balance), then a paged payment table: date, amount, method, status, related
booking, reference.

Then **حركة المحفظة**, the newest 50 ledger entries with signed amounts (U+2212,
not a hyphen — at that size in an RTL column a hyphen is easy to miss), running
balance and who performed each.

**No card numbers, no tokens, no processor payload.** The RPC does not select
`gateway_response`, `gateway_transaction_id` or `gateway_order_id` at all — a
read path that never fetches them cannot leak them, which is stronger than a
widget that chooses not to draw them. `payment_reference` *is* shown: it is the
transfer reference the customer quotes when they call.

### النشاط

A chronological feed grouped by day, unioned server-side from eleven real
timestamp columns across seven tables:

booking created · booking cancelled · receipt submitted · payment approved ·
boarded · no-show resolved · subscription created · wallet movement (four kinds)
· review submitted · ticket opened · refund settled.

Newest 40. When it comes back full it carries a `DashboardCapNotice` saying so
and pointing at the tabs that hold the complete history — the feed is a window,
and the oldest row it happens to hold must not read as the beginning of time.

An unrecognised `wallet_*` kind renders as *"حركة على الحساب"* rather than as a
raw wire value.

---

## 3. Permissions

`DashboardPermission.customers`, granted to **both** roles, and
`office_can('customers_view')` checked again server-side in every RPC.

Support agents get it because the module aggregates bookings, wallets and
tickets — three surfaces they already read in full — into one view of the person.
Withholding the summary of data they can already page through would protect
nothing and would leave the person who answers "where is my money" assembling it
by hand across five modules.

It is read-only. `walletAdjustments` and `walletApprovals` remain owner-only and
are asserted so.

The module carries **no licensing feature key**. It adds no capability the office
is not already paying for; it reorganises what they can already see. Nothing to
lock, nothing to sell.
