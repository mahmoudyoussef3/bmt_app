# Finance — Architecture

Where every number on the screen comes from, and which layer is allowed to
decide what it means.

---

## 1. The map

```
FinanceScreen  (presentation/screens)
  └─ FinancePeriodBar · _SectionTabs
  └─ FinanceOverviewTab · FinanceLedgerTab · FinanceAnalyticsTab · FinanceReportsTab
        ↕ BlocConsumer
FinanceCubit  (presentation/cubit)
        ↓ use cases only
GetPaymentsUseCase · GetRefundRequestsUseCase · GetFinanceSubscriptionsUseCase
GetWalletPositionUseCase · GetRevenueMetricsUseCase · ExportFinanceStatementUseCase
        ↓ repository interface
FinanceRepository  (domain/repositories)
        ↑ implemented by
FinanceRepositoryImpl  (data/repositories)
        ↓
FinanceDatasource ── SupabaseFinanceDatasource (data/datasources)
        ↓ row → entity
FinanceRowMapper  (data/mappers)
        ↓
Supabase: operation_bookings · subscriptions · refund_requests
          wallet_transactions · rpc office_wallet_overview
```

The presentation layer never touches Supabase, never parses a row, and holds no
financial rule of its own. Everything it renders is either a field of
`FinanceLoaded` or a getter on `FinanceAnalytics` / `FinanceAttention`.

---

## 2. Where each figure comes from

| Figure | Source |
|---|---|
| Collected / net revenue | `operation_bookings.payment_amount` where `payment_status = 'approved'`, dated by `created_at` |
| Outstanding (مستحقات لم تُحصّل) | the same rows with an unsettled payment **and a seat that still exists** |
| Cancelled / written off | rejected, failed or cancelled payments, plus any unpaid fare on a cancelled seat |
| Refunded | `payment_status = 'refunded'`, mirrored on the booking |
| By payment method | approved booking rows, grouped by normalised `payment_method` |
| Subscription revenue | `subscriptions.paid_amount` for active/expired packages |
| Subscription receivable | `subscriptions.remaining_amount` |
| Daily movement | booking + subscription rows bucketed by day |
| Refund requests | `refund_requests` (office-scoped by RLS) |
| Wallet position | `office_wallet_overview` + `wallet_transactions` + settled `refund_requests` |

Every query is office-scoped **by RLS** (`office_id = current_office_id()`),
never by a client-side filter, so a figure cannot be widened by editing a
request.

---

## 3. Status translation

The database carries eight payment states and six booking states. Finance reads
money, so it collapses them onto a four-value money vocabulary — and it reads
the two axes **together**, because neither alone is enough.

```
payment_status          seat state        →  money status
──────────────────────────────────────────────────────────
approved                any               →  محصّلة   (success)
refunded                any               →  مستردة   (refunded)
rejected/failed/cancelled  any            →  ملغاة    (cancelled)
pending/submitted/underReview  live       →  قيد التحصيل (pending)
pending/submitted/underReview  cancelled  →  ملغاة    (cancelled)
```

The last line is the one that matters. A fare awaiting payment on a **released**
seat is not "قيد التحصيل": the seat is gone, `approve_payment` refuses it, and
nobody is waiting for the money. Filing it as outstanding inflates the
receivable an owner is chasing with fares that can never arrive.

Two derived predicates ride on top:

- `isUnreleasedLiability` — collected money on a cancelled seat. Still revenue
  (the office has the cash) but a refund decision nobody has made.
- `awaitingReview` — a receipt uploaded on a live seat. The only Finance signal
  that maps to a real queue elsewhere in the console.

`FinanceRowMapper` owns all of this as pure functions, deliberately lifted out
of the datasource so it can be tested against real database shapes without a
Supabase client. Every correctness bug this module has had lived in exactly
those functions.

---

## 4. The three-statement model

One "net revenue" figure was not enough. Trace three events through it:

```
1. Customer books, pays 300 cash          → gross 300
2. Trip cancelled, 300 refunded to wallet → refunds 300, net 0
3. Customer rebooks, pays with the 300    → excluded from gross, net still 0
```

The office ran two trips, kept 300 EGP, and the report said it earned nothing.
The error is conflating **cash** with **revenue**. A wallet balance is neither —
it is a **liability**.

```
REVENUE   (accrual)  = Σ fare of sold bookings    − Σ refunds granted (any destination)
CASH      (treasury) = Σ external tender received − Σ refunds settled outside the wallet
LIABILITY            = Σ wallet balances
```

Revenue is keyed on the **fare** and is indifferent to how it was tendered. Cash
is keyed on **tender** and is indifferent to what was sold. That separation makes
double-counting structurally impossible rather than a rule someone remembers.

### The control identity

```
CASH_in − CASH_out  =  REVENUE − PROMOTIONAL_COST + ΔLIABILITY
```

Asserted on every load, to the piastre. When it fails the module says so — and
the failure is promoted into «يحتاج المتابعة» as the top row, which is what
makes it safe for the reconciliation panel itself to start collapsed.

`externalTender` is computed as `grossReceived − Σ|wallet_spend| in window`.
`wallet_spend` is reserved and unemitted in V1, so that subtracts zero today;
wiring it now is what keeps the identity balanced on the day wallet checkout
ships, instead of turning the panel red for a healthy office.

---

## 5. Derivation, and when it runs

`FinanceLoaded` holds the **full** ledger and the **whole** wallet position, and
derives the period view in memory. That is deliberate: switching period must not
produce a screen where the KPI band, the identity check and the statement were
computed from three different snapshots.

Derivation walks the ledger twice — this window and the comparison window — and
buckets it six ways. It is cheap per *load* and expensive per *keystroke*, so
`copyWith` carries `analytics` and `attention` forward whenever none of their
five inputs moved:

```
ledger · refundRequests · walletPosition · period (+ customRange) · loadedAt
```

Filters, paging, sort order, the visible tab and the export flag are none of
them. Typing in the search box, turning a page and switching tabs all reuse the
existing derivation; changing the period or reloading recomputes it. Two cubit
tests pin this so the next extension of `copyWith` cannot quietly undo it.

`filteredEntries` is a `late final` rather than a getter: the ledger tab reads it
three times per build and the list can hold three thousand rows.

---

## 6. Files

```
features/finance/
├── data/
│   ├── datasources/
│   │   ├── finance_datasource.dart          # interface
│   │   └── supabase_finance_datasource.dart # queries only
│   ├── mappers/
│   │   └── finance_row_mapper.dart          # row → entity, pure
│   ├── repositories/finance_repository_impl.dart
│   └── services/finance_statement_export_service.dart
├── domain/
│   ├── entities/
│   │   ├── finance_entities.dart      # vocabulary, FinanceWindow, ledger
│   │   ├── finance_analytics.dart     # the period view, derived
│   │   ├── finance_attention.dart     # the queues, derived
│   │   └── finance_money_model.dart   # the three statements
│   ├── repositories/finance_repository.dart
│   └── usecases/*.dart
└── presentation/
    ├── cubit/{finance_cubit,finance_state}.dart
    ├── screens/finance_screen.dart
    └── widgets/
        ├── finance_period_bar.dart
        ├── finance_attention_panel.dart
        ├── finance_overview_tab.dart
        ├── finance_ledger_tab.dart
        ├── finance_transaction_detail.dart
        ├── finance_analytics_tab.dart
        ├── finance_reports_tab.dart
        ├── finance_money_statements_panel.dart
        ├── finance_common.dart
        └── finance_format.dart
```

---

## 7. The module hand-off

`FinanceScreen` takes an `onOpenModule` callback, wired in `dashboard_shell.dart`
to the shell's own `_openRoute`. It is how the module stays read-only while
still being useful: the attention panel and the transaction detail hand the
operator to the module that owns the decision rather than growing a decision of
their own.

`onOpenModule` is nullable. The screen tests and the showcase harness pass null,
and the hand-off simply does not render — the panel is still a correct read.

---

## 8. Who else reads Finance

`FinanceRepository` is not private to this module. Two other surfaces consume
`GetRevenueMetricsUseCase`:

- `DashboardHomeCubit` — the operator console's revenue tiles
- `BusinessOverviewCubit` — «نظرة تنفيذية»

They read the same use case rather than recomputing, which is why a correction
to the subscription arithmetic here corrects all three at once. `RevenueMetrics`
is the shared contract; anything richer stays inside Finance.
