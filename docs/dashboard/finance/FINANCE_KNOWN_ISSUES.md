# Finance — Known issues and limitations

What is still wrong, what cannot be built without a backend change, and what was
deliberately left alone. Figures quoted were measured against the production
database on 2026-08-21.

---

## 1. `revenue_daily_view` disagrees with Finance — REQUIRES BACKEND CHANGE

**Current limitation.** The reports module reads `revenue_daily_view`, defined
as:

```sql
COALESCE(sum(payment_amount) FILTER (
  WHERE status <> ALL (ARRAY['rejected','cancelled'])
), 0) AS total_bookings_revenue
```

It filters on the **booking** status and ignores `payment_status` entirely, so
every unpaid-but-live booking counts as revenue. Finance counts only
`payment_status = 'approved'`.

**Measured on the live office:** Finance reports **12,476 ج.م** of collected
booking revenue; the view reports **13,765 ج.م** for the same rows. Two modules
of the same console, two "revenue" figures, 1,289 ج.م apart. `'rejected'` is not
even a member of the booking-status check constraint, so half the filter is dead.

**Why it prevents the desired UX.** An owner who opens التقارير after المركز
المالي sees a different number for the same month and has no way to reconcile
them. Neither screen is wrong about its own definition, and neither states it.

**Exact backend change required.**

```sql
create or replace view public.revenue_daily_view as
select (created_at at time zone 'UTC')::date as report_date,
       office_id,
       count(*)::integer as total_bookings,
       coalesce(sum(payment_amount) filter (
         where payment_status = 'approved'
       ), 0::numeric) as total_bookings_revenue
  from operation_bookings b
 where office_id = current_office_id() or is_platform_admin()
 group by 1, 2
 order by 1;
```

**Risk.** Every office's reported revenue drops to the collected figure — a
visible, downward change to a headline number. It is the *correct* figure, but
it will be noticed and must be announced rather than shipped quietly.

**Migration strategy.** One migration replacing the view; no data change, no RLS
change, reversible by restoring the previous definition. Ship it alongside a
note in the reports module explaining the restatement, and verify the two
modules agree for a sample office before and after.

**Not done here** because it changes a production financial figure outside the
module under audit, which §20 of the brief reserves for an explicit decision.

---

## 2. Wallet-tendered fares are wired but unexercised — RECOMMENDED

`FinanceAnalytics` computes `externalTender = grossReceived − Σ|wallet_spend|`
inside the window. `wallet_spend` is reserved in the `wallet_transactions` kind
constraint and **never emitted by V1**, so that subtracts zero today.

The wiring exists so the control identity stays balanced on the day wallet
checkout ships. Before that day:

- a wallet-paid booking must be written with `payment_method = 'wallet'` **and**
  a matching `wallet_spend` row, or the identity will break;
- `FinanceRowMapper.method` already maps `wallet` onto «فودافون كاش», which will
  become wrong the moment a wallet leg is a real payment rail. It needs its own
  `FinancePaymentMethod` value at that point, not before — inventing an enum
  member for a rail nobody uses would put an always-empty slice on the donut.

---

## 3. There is no trip-level revenue — REQUIRES DATA WORK

`operation_bookings.trip_id` is populated on only 18 of 43 live rows, so
"revenue by trip" cannot be computed honestly for the majority of the book. The
module therefore does not offer it, rather than offering a figure that silently
covers 40% of the rows.

Attribution runs to the **route** instead, via `operation_bookings.route`, which
is `NOT NULL`.

---

## 4. Route attribution fragments across spellings — RECOMMENDED

`route` is free text, so the same corridor appears under several spellings:

```
American University in Cairo (AUC) - New Cairo, QH, Egypt
American University in Cairo (AUC) - New Cairo
```

«أعلى المسارات إيراداً» groups on the exact string, so one corridor can occupy
two ranking rows. Normalising by trimming administrative suffixes would be
guessing; the real fix is upstream, in the route builder, so a booking stores a
`route_id` alongside the display text. Until then the ranking is correct per
recorded string and the full text is in the tooltip.

The label itself is now split and recomposed through `RouteDirectionText`, so at
least the direction is right — a stored `'A → B'` printed raw reverses under bidi
for Latin place names.

---

## 5. `getRevenueMetrics()` is a full-table scan — ACCEPTED, WITH A CEILING

It reads every `operation_bookings` and `subscriptions` row for the office, on
every visit to the console home *and* the executive overview. It is uncapped on
purpose: it computes sums, and a sum over the newest three thousand rows
presented as the total is exactly the silent truncation the cap contract forbids.

Mitigations in place: three narrow columns per table, no joins. The real fix is
server-side aggregation — a `office_revenue_totals()` RPC returning the six
figures — which is a new function and therefore out of scope for this pass.

---

## 6. Wallet movements and settled refunds are capped

`getWalletPosition()` reads the newest 3,000 `wallet_transactions` and the newest
3,000 settled refunds. The opening liability is back-computed from the present
balance by unwinding movements, so an office whose wallet ledger exceeds the cap
would compute an opening balance from an incomplete tail.

No office is near this today (the live ledger holds four rows). It is recorded
here because the failure mode is a *plausible wrong number* rather than an error,
and the control identity is the thing that would catch it.

---

## 7. Deliberately absent

- **No cash-drawer reconciliation.** Finance knows what was collected digitally.
- **No expense side.** "Net revenue" is revenue net of refunds. The hero card
  says so in words; nothing in the module calls it profit.
- **No per-route or per-vehicle P&L.** Costs do not exist to attribute against.
- **No approve / reject / refund controls.** By charter, enforced by a test.

---

## 8. Fixed in this pass

Recorded so a future reader can tell which of the above are old and which are
new. All four were provable against live rows.

| Was | Effect on the live office |
|---|---|
| The ledger query filtered out `payment_status = 'pending'` and `'cancelled'` | 17 bookings worth **710 ج.م** were invisible; «قيد التحصيل» reported 961 ج.م instead of 1,671 ج.م |
| Booking status was never read, so a fare on a cancelled seat counted as collectable | 3 cancelled bookings worth **450 ج.م** were shown as money still being chased |
| A part-paid package contributed its full `total_price` | one package invoiced at 720 with 400 paid added **320 ج.م** of revenue that had not arrived |
| `payment_method` was compared raw, so `'Credit Card'` did not match `'credit_card'` | 2 card payments were reported as cash |

The first three also flowed into `RevenueMetrics`, and therefore into the console
home and the executive overview, which read the same use case.
