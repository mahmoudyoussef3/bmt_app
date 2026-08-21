# Dashboard — Finance

> **The detail lives in [`finance/`](finance/).** This page is the short version
> and the list of invariants; it is kept because other documents link to it.
>
> | Document | Answers |
> |---|---|
> | [`finance/FINANCE_OVERVIEW.md`](finance/FINANCE_OVERVIEW.md) | What the module is for, the periods, the accounting model, the attention queues |
> | [`finance/FINANCE_ARCHITECTURE.md`](finance/FINANCE_ARCHITECTURE.md) | Layer map, where every figure comes from, status translation, the three statements, memoisation |
> | [`finance/FINANCE_FEATURES.md`](finance/FINANCE_FEATURES.md) | What each tab does, the transaction detail, empty/loading/error states |
> | [`finance/FINANCE_UX.md`](finance/FINANCE_UX.md) | The design rules and the reasoning behind the non-obvious ones |
> | [`finance/FINANCE_KNOWN_ISSUES.md`](finance/FINANCE_KNOWN_ISSUES.md) | What is still wrong, what needs a backend change, what was fixed |

---

## The module

`/payments` — «المركز المالي». Owner only. Four tabs behind one pinned period
bar: نظرة عامة · الحركات المالية · التحليلات · التقارير.

**Finance reports. It does not decide.** Payment verification lives in الحجوزات,
refund decisions in محفظة العملاء, subscription changes in الاشتراكات. There is
no approve button here and there must not be one.

That is a rule about **authority**, not about silence. «يحتاج المتابعة» names
every queue with money waiting on a decision and opens the module that owns it.
Naming a queue is reading; clearing it happens elsewhere.

---

## Invariants that must not be reinvented

1. **A refund is not a separate ledger row.** It is mirrored onto the booking it
   reverses. Adding it as its own row double-subtracts.
2. **Refund requests are a liability signal**, kept out of the ledger so an
   approved refund is never subtracted twice.
3. **Wallet balances are a liability, not income.** Finance reads
   `WalletFinancePosition`; it does not recompute it.
4. **Excluded amounts are shown, not dropped.** A figure quietly removed from a
   total is indistinguishable from a bug.
5. **The ledger query filters nothing by payment state.** Deciding in the query
   which money is worth knowing about is how «قيد التحصيل» came to report a
   fraction of what the office was owed.
6. **Payment state is read together with seat state.** An unpaid fare on a
   cancelled seat is not a receivable; nobody is waiting for it.
7. **A package is worth what arrived, not what was invoiced.**
8. **`getRevenueMetrics()` stays uncapped.** It computes sums, and a capped sum
   presented as a total is the silent truncation the cap contract forbids.
9. **The control identity is asserted on every load**, and a failure is stated
   with its exact gap rather than displaying a plausible wrong number.
10. **No figure is invented.** No comparable window means `—`, never `0%`.

---

## The accounting model, in one block

```
  Total collected            bookings whose payment reached approved
− Executed refunds           refunds actually paid back
─────────────────────────
= NET REVENUE                the line the owner keeps

  Memo lines (shown, excluded from the net):
    · Pending collection     unpaid fare on a seat that still exists
    · Cancelled / rejected   never was money, or the seat went away
    · Pending refund requests outstanding liability, not yet subtracted
```

Beside it, three statements computed independently — revenue (accrual), cash
(treasury) and liability (wallet balances) — with the control identity

```
CASH_in − CASH_out  =  REVENUE − PROMOTIONAL_COST + ΔLIABILITY
```

Net revenue is revenue net of refunds. **It is not profit** — there is no
expense side anywhere in the system, and the UI must never call it profit.

---

## Export

PDF, Excel and CSV carry the same figures as the screen. PDF uses the Cairo font
and RTL; CSV is UTF-8 with a BOM (`String.codeUnits` + `Uint8List.fromList`
turns every Arabic character into mojibake). Both are licence-metered through
`LicensedExport.consume(format)`.

---

## The row cap

The ledger is capped at `DashboardQueryCaps.financeLedger`. When the cap is hit
the period bar says the window may be incomplete rather than showing a quietly
truncated total.
