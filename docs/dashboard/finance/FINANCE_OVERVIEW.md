# Finance — Overview

> **Finance reports. It does not decide.** Payment verification lives in الحجوزات,
> refund decisions in محفظة العملاء, subscription changes in الاشتراكات. The
> financial centre has no approve button and must not grow one.
>
> That rule is about **authority**, not silence. Finance *names* the queues and
> hands the operator off to the module that owns each decision — see
> [Needs Attention](#4-needs-attention).

`/payments` — «المركز المالي». Owner only (`DashboardPermission.payments`).

---

## 1. What it is for

If an office owner opens this screen for thirty seconds, they should leave
knowing:

1. **Where the money stands** — what was kept, what is still owed, what went back.
2. **What needs a decision today** — and where to go and make it.
3. **Which way it is moving** — against a comparable earlier window.
4. **Where it comes from** — by source, rail, route and customer.

Everything else — the individual movements, the formal statement, the export —
is one tab away and exists to answer a challenge to one of those four.

---

## 2. The four tabs

| Tab | Question it answers |
|---|---|
| نظرة عامة | Where does the money stand, and what needs me? |
| الحركات المالية | Show me every individual movement, and open one |
| التحليلات | What shape is it — by weekday, cumulatively, vs last period? |
| التقارير | The income statement, and a file of it |

The period bar is **pinned to the module header** rather than scrolling with the
content, because every figure on every tab is scoped by it. An operator who
cannot see the period cannot read the page.

---

## 3. The period

Two kinds of window, because owners ask two different questions:

| Preset | Shape | Bounds |
|---|---|---|
| اليوم | rolling | midnight → now |
| آخر ٧ أيام | rolling | 7 days ending today |
| **هذا الشهر** | calendar | 1st of the month → now |
| **الشهر الماضي** | calendar | the whole previous calendar month |
| آخر ٣٠ يوم | rolling | 30 days ending today |
| آخر ٩٠ يوم | rolling | 90 days ending today |
| كل الفترات | unbounded | everything the ledger holds |
| فترة مخصصة | custom | two dates the operator picks |

**Rolling answers "how are we doing"; calendar answers "close the month".** On
the 3rd, «هذا الشهر» and «آخر ٣٠ يوم» differ by an order of magnitude, and an
owner reconciling against paper means the calendar one. Offering only rolling
windows is why the module used to disagree with the books on every day except
the 30th.

The bar states the window it resolved to in dates — `من 2026/08/01 إلى
2026/08/19` — plus what the comparison is measured against and whether the
period is still filling up. A chip is a name; the reader needs the boundary.

### What "الفترة السابقة" means

- **Rolling**: the same window shifted back by its own length, keeping the same
  time of day at both ends. At 15:00, «اليوم» is compared with yesterday *up to
  15:00* — not with the whole of yesterday, which would report a collapse every
  afternoon.
- **Calendar, month to date**: the same span of the previous month (19 days
  against 19 days), clamped so 31 March compares against 28 February rather
  than borrowing three days of March.
- **Calendar, complete month**: the whole month before it.
- **كل الفترات**: nothing. Every delta reads `—`.

---

## 4. Needs Attention

«يحتاج المتابعة» is the panel that makes Finance a tool rather than a report. It
derives queues from data the module already holds, prices each one, and opens
the module that can clear it.

| Queue | Derived from | Goes to |
|---|---|---|
| معادلة الضبط غير متوازنة | the control identity failing | stays here |
| إيصالات بانتظار المراجعة | `payment_status ∈ {submitted, underReview}` on a live seat | مراجعة المدفوعات |
| طلبات استرداد بلا قرار | `refund_requests.status = pending` | محفظة العملاء |
| مبالغ محصّلة على حجوزات ملغاة | approved payment + cancelled seat | الحجوزات |
| حجوزات قائمة لم تُحصّل | unpaid fare, live seat, no receipt uploaded | الحجوزات |
| اشتراكات محصّلة جزئياً | `remaining_amount > 0` | الاشتراكات |
| اشتراكات بانتظار الدفع | `status = pending_payment` | الاشتراكات |

Three rules the panel keeps:

1. **It counts the whole book, not the period.** A receipt uploaded six weeks
   ago is still undecided today. Scoping it to the period bar would let an
   operator make work disappear by choosing a shorter window. The subtitle says
   so in words.
2. **No row is counted twice.** A receipt awaiting review is also, by
   construction, an unpaid fare on a live seat. The review queue — the one with
   an action attached — wins, and the chase queue reports only what nobody is
   looking at.
3. **A clear board says so.** An empty panel that renders as nothing is
   indistinguishable from one that failed to load.

A broken control identity is pinned first whatever its size: it does not mean
"there is 25 ج.م to chase", it means every other figure on the screen may be
wrong.

---

## 5. The accounting model

```
  Total collected            all bookings whose payment reached approved
− Executed refunds           refunds actually paid back
─────────────────────────
= NET REVENUE                the line the owner keeps

  Memo lines (shown, excluded from the net):
    · Pending collection     unpaid fare on a seat that still exists
    · Cancelled / rejected   never was money, or the seat went away
    · Pending refund requests outstanding liability, not yet subtracted
```

Rules that must not be reinvented:

1. **A refund is not a separate ledger row.** It is mirrored onto the booking it
   reverses. Adding it as its own row double-subtracts.
2. **Refund requests are a liability signal**, deliberately kept out of the
   ledger so an approved refund is never subtracted twice.
3. **Wallet balances are a liability, not income.** The wallet subsystem keeps
   its own hash-chained ledger and its own three statements. Finance reads
   `WalletFinancePosition`; it does not recompute it.
4. **Excluded amounts are shown, not dropped.** A figure quietly removed from a
   total is indistinguishable from a bug.
5. **A fare on a cancelled seat is not a receivable.** Nobody is waiting for it.
   Money already collected on one *is* still revenue — the office holds it — but
   it is flagged as an unreleased liability rather than left silent.
6. **A package is worth what arrived, not what was invoiced.** A subscription
   that went active on a deposit contributes its `paid_amount`; the balance is
   reported as outstanding.

Beside the single net figure sits the **three-statement model** — revenue, cash
and liability computed independently, with a control identity that is asserted
on every load. See `FINANCE_ARCHITECTURE.md` §4.

---

## 6. The row cap

The ledger query is capped at `DashboardQueryCaps.financeLedger` (3,000). When
the cap is hit, `FinanceLoaded.ledgerCapReached` is true and the period bar says
so. An office whose period exceeds the cap is told its window may be incomplete
rather than shown a quietly truncated total.

`getRevenueMetrics()` is deliberately **uncapped**: it computes sums, and a sum
over the newest three thousand rows presented as the total is exactly the silent
truncation the cap contract exists to forbid.

---

## 7. Export

PDF, Excel and CSV, all three carrying the same figures as the screen — income
statement, collection by method, daily movement, and the ledger.

- **PDF** uses the Cairo font and RTL text direction; the default Helvetica
  cannot render Arabic at all.
- **CSV** is UTF-8 with a BOM (`CsvEncoder(addBom: true)` + `utf8.encode`). This
  is not cosmetic: `String.codeUnits` yields UTF-16 units and
  `Uint8List.fromList` truncates each to its low byte, which turns every Arabic
  character into mojibake.
- Exports are **licence-metered** through `LicensedExport.consume(format)`,
  against `export_pdf` / `export_excel`.

---

## 8. The wallet, in one paragraph

«محفظة العملاء» is a separate module with its own permissions (`customerWallets`
to view, `walletAdjustments` to move money, `walletApprovals` to approve a
refund). It is a directory of customer wallets with a per-customer ledger, a
refund queue, and a chain verification that proves the ledger has not been
tampered with. A support agent can look up a balance to answer "where is my
money" and can do nothing else. The office's liability to its customers is the
sum of those balances, and that figure is what Finance reads.

---

## 9. What Finance does not have

Stated plainly because their absence is a business gap, not an oversight:

- **No cash-movement or drawer reconciliation.** Finance knows what was
  *collected digitally*; it cannot tell an owner what cash a station agent is
  holding.
- **No cost or expense side.** Fuel, salaries, maintenance and platform fees are
  nowhere. "Net revenue" is revenue net of refunds — it is not profit, and the
  UI says so on the hero card.
- **No per-route or per-vehicle P&L.** Revenue attributes to routes; costs do
  not exist to attribute against.
- **No trip-level revenue.** See `FINANCE_KNOWN_ISSUES.md` §3.
