# Finance — Features

What each surface does, and what it deliberately does not.

---

## نظرة عامة — the thirty-second read

Ordered as an argument, not as a grid:

1. **صافي الإيراد hero** — the headline figure, the shape of the period beside
   it, and the arithmetic that produced it spelled out underneath
   (`إجمالي المتحصلات − المرتجعات المنفذة = صافي الإيراد`). It carries the line
   *"الإيراد بعد المرتجعات فقط — ليس ربحاً: لا تُخصم منه أي تكاليف تشغيل"*,
   because an owner reading a large number needs to know what it is not.
2. **Four KPIs** — مستحقات لم تُحصّل · معدل التحصيل · المرتجعات المنفذة · عدد
   المعاملات. Each carries a period-over-period movement when there is a
   comparable window that had something in it; when there is not, no arrow is
   shown rather than a delta against zero.
3. **يحتاج المتابعة** — the queues and the way to each one.
4. **اتجاه الإيراد اليومي** — net collected per day.
5. **مصادر الإيراد** / **طرق التحصيل** — bookings vs packages, and by rail.
6. **أعلى المسارات إيراداً** / **أعلى العملاء إنفاقاً**.
7. **القوائم الثلاث والتسوية** — collapsed by default.

### Why four KPIs and not eight

The four that went were redundant or misplaced: booking and subscription revenue
are the «مصادر الإيراد» donut directly below, average ticket is a row of the
comparison table on التحليلات, and pending refund requests are a queue with an
owner. A KPI band is a summary, and a summary that repeats the chart under it
has stopped summarising.

Four is also the width the shared `DashboardKpiGrid` lays out at desktop sizes.
A fifth tile does not make a denser band, it makes a row of four and an orphan.

### The collection-rate delta is in points

"94% → 87%" is reported as **−7.0 نقطة**, not −7.4%. Expressing a movement in a
rate as a percentage of itself is the kind of arithmetic that starts an argument.

---

## الحركات المالية — the ledger

Every money movement in the window, as records rather than as a queue.

- **Search** across passenger name, booking number, phone, route and package.
- **Filters**: type (booking / subscription), payment method, money status.
- **Sort**: newest, oldest, largest, smallest.
- **Pagination** at 25 rows.
- **A row opens.** Tapping any row opens the full transaction detail.
- **Row tints**: amber for a receipt awaiting review, red for money held against
  a cancelled seat. Never colour alone — the same rows carry an explicit
  «يحتاج مراجعة» / «مقعد ملغي» pill in the status column.
- **Totals strip** that reports what is *on screen* when a filter is active, and
  says so, so a filtered view never invites the operator to read the period
  total as the filtered one.

There is no action column. Acting on a payment happens in الحجوزات.

### Route labels

`operation_bookings.route` stores origin and destination already joined with an
arrow. Printing that raw announces the journey **backwards** whenever bidi
resolves the line the other way — which, for the Latin place names the geocoder
returns for most Egyptian stops, is most of the time. The ledger and the route
ranking split the stored string and recompose it through `RouteDirectionText`,
which isolates each endpoint and picks the arrow from the ambient direction. The
full original stays in the tooltip.

---

## تفاصيل الحركة — the transaction detail

The chain behind one row, in one dialog:

```
Transaction id
  → Payment      status · method · date · receipt · rejection reason
  → Booking      number · passenger · phone · seat state · trip date
  → Route        origin → destination
  → Refund       request status · amount · date · reason   (when one exists)
  → Effect       what this row did to the period's headline figure
```

The **effect line** is the part that makes the overview trustworthy: any single
row can be traced into the number at the top of the screen. A pending row says
*"خارج صافي الإيراد — تُحسب ضمن «قيد التحصيل» حتى يصل المبلغ"*; a refunded row
says its net effect is zero; collected money on a cancelled seat says the office
is still holding it and owes a decision.

It decides nothing. The only action is «افتح الحجوزات» / «افتح مراجعة الإيصالات»,
which closes the dialog and switches module.

---

## التحليلات

- **مؤشرات الأداء** — average daily revenue, best day, busiest day, revenue
  concentration, refund rate, collection rate.
- **الإيراد التراكمي** — how the window filled up.
- **أداء أيام الأسبوع** — Saturday-first, the way an Egyptian operating week
  reads.
- **عدد المعاملات اليومي** — volume, not value; capped at the last 30 bars
  because a 90-bar chart is unreadable.
- **مقارنة بالفترة السابقة** — five metrics against the named baseline. The
  column header is the baseline's own name («يونيو 2026»), not the word
  "previous".
- **توزيع الحركات حسب الحالة**.

Refunds are shown `inverted`: a refund line growing 40% is not good news dressed
in green.

---

## التقارير

- **Export toolbar** — PDF / Excel / CSV, licence-metered.
- **قائمة الدخل** — the formal statement, with the excluded figures shown as
  memo lines under «بنود خارج الصافي» rather than quietly dropped.
- **التحصيل حسب طريقة الدفع** — shares are of *booking* revenue, because a
  package purchase records no rail. The table states the covered total and then
  names the subscription revenue that carries no method, so the reader is never
  left hunting for a missing three quarters.
- **طلبات الاسترداد** — by status, with the outstanding liability called out.
- **الحركة اليومية** — the day table.

---

## Empty, loading and error states

| Situation | What the screen says |
|---|---|
| No ledger at all | «لا توجد حركات مالية بعد» — explains that the first sale starts every metric, instead of showing zeros everywhere |
| Nothing in this window | «لا توجد حركات في {period}» + a button that widens to كل الفترات |
| Filters match nothing | «لا توجد حركات مطابقة» + مسح التصفية |
| No collection in the window | the trend panel says so instead of drawing a flat line at zero that looks like data |
| No collected revenue | the source and method donuts say so instead of rendering an empty ring |
| Nothing needs attention | «لا شيء معلق — كل حركة مالية وصلت لقرار», because an empty panel is indistinguishable from a failed one |
| Row cap reached | the period bar says the window may be incomplete |
| Load failure | the whole module shows the error with a retry; an export failure keeps the loaded screen and reports itself as a message, because losing the operator's period and filters over a failed download is the worse outcome |

---

## Colour

Green = collected · Amber = pending or needs attention · Red = problem ·
Neutral = informational. Never as the only signal: statuses carry a text pill,
attention rows carry a severity glyph and a worded action, and the ledger's
refunded rows carry a strikethrough as well as a colour.
