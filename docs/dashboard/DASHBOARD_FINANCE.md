# Dashboard — Finance

> **Finance reports. It does not decide.** Payment verification lives in الحجوزات, refund
> decisions in محفظة العملاء, subscription changes in الاشتراكات. The financial centre has
> no approve button and must not grow one.

---

## 1. The module

`/payments` — «المركز المالي». Owner only. Four tabs behind one pinned period bar:

| Tab | Question it answers |
|---|---|
| نظرة عامة | Where does the money stand this period? |
| الحركات المالية | Show me every individual movement |
| التحليلات | What shape is it — by payment method, by day? |
| التقارير | The income statement, and a file of it |

The period bar is **pinned to the module header** rather than scrolling with the content,
because every figure on every tab is scoped by it. An operator who cannot see the period
cannot read the page.

---

## 2. The accounting model

```
  Total collected            all bookings whose payment reached approved
− Executed refunds           refunds actually paid back
─────────────────────────
= NET REVENUE                the line the owner keeps

  Memo lines (shown, excluded from the net):
    · Pending collection     submitted / under review — not money yet
    · Cancelled / rejected   never was money
    · Pending refund requests outstanding liability, not yet subtracted
```

Rules that must not be reinvented:

1. **A refund is not a separate ledger row.** It is mirrored onto the booking it reverses.
   Adding it as its own row double-subtracts.
2. **Refund requests are a liability signal**, deliberately kept out of the ledger so an
   approved refund is never subtracted twice.
3. **Wallet balances are a liability, not income.** The wallet subsystem keeps its own
   hash-chained ledger and its own three statements. Finance reads
   `WalletFinancePosition`; it does not recompute it.
4. **Excluded amounts are shown, not dropped.** A figure quietly removed from a total is
   indistinguishable from a bug.

`FinanceLoaded` holds the **full** ledger and the **whole** wallet position, and derives
the period view in memory. That is deliberate: switching period must not produce a screen
where the KPI band, the identity check and the statement were computed from three
different snapshots.

---

## 3. Where the numbers come from

| Figure | Source |
|---|---|
| Collected / net revenue | `operation_bookings.payment_amount` where payment reached approved, dated by `created_at` |
| By payment method | Same rows, grouped by `payment_method` |
| Daily movement | Same rows, bucketed by day |
| Refund requests | `refund_requests` (office-scoped by RLS) |
| Wallet position | The wallet RPCs |
| Subscriptions | `subscriptions` |

`revenue_daily_view` is the office-scoped daily roll-up used by التقارير. It is
deliberately **not** licence-gated, unlike the other three report views, because Finance
reads it too and withdrawing it with `reports` would take down a module the office still
holds.

---

## 4. The row cap

The ledger query is capped. When the cap is hit, `FinanceLoaded.ledgerCapReached` is true
and the period bar says so. An office whose period exceeds the cap is told its window may
be incomplete rather than shown a quietly truncated total.

---

## 5. Export

PDF, Excel and CSV, all three carrying the same figures as the screen — income statement,
collection by method, daily movement, and the ledger.

- **PDF** uses the Cairo font and RTL text direction; the default Helvetica cannot render
  Arabic at all.
- **CSV** is UTF-8 with a BOM (`CsvEncoder(addBom: true)` + `utf8.encode`). This is not
  cosmetic: `String.codeUnits` yields UTF-16 units and `Uint8List.fromList` truncates each
  to its low byte, which turns every Arabic character into mojibake. The reports module
  had exactly that bug until this pass; Finance and Wallet always did it correctly.
- Exports are **licence-metered** through `LicensedExport.consume(format)`, against
  `export_pdf` / `export_excel`.

---

## 6. The wallet, in one paragraph

«محفظة العملاء» is a separate module with its own permissions (`customerWallets` to view,
`walletAdjustments` to move money, `walletApprovals` to approve a refund). It is a
directory of customer wallets with a per-customer ledger, a refund queue, and a chain
verification that proves the ledger has not been tampered with. A support agent can look
up a balance to answer "where is my money" and can do nothing else. The office's liability
to its customers is the sum of those balances, and that figure is what Finance reads.

---

## 7. What Finance does not have

Stated plainly because their absence is a business gap, not an oversight:

- **No cash-movement or drawer reconciliation.** Finance knows what was *collected
  digitally*; it cannot tell an owner what cash a station agent is holding.
- **No cost or expense side.** Fuel, salaries, maintenance and platform fees are nowhere.
  "Net revenue" is revenue net of refunds — it is not profit, and the UI must never call
  it profit.
- **No period-over-period comparison** on the statement itself.
- **No per-route or per-vehicle P&L.** Revenue attributes to routes in التقارير; costs do
  not exist to attribute against.
