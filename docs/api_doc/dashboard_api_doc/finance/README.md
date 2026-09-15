# Dashboard · Finance (المدفوعات / المركز المالي)

**Money reporting only.** Finance never verifies, approves, refunds or adjusts anything — it reads
bookings, subscriptions, refund requests and the wallet ledger and derives three statements
(collected / receivable / liability) plus the revenue KPIs used by Home and Business Overview. It
does name the queues (payments to review, pending refunds) and hands off to `bookings/` and
`wallet/`. Exports are gated by the licensing RPC.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/finance/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.payments` = `/payments`) |
| Cubit | `presentation/cubit/finance_cubit.dart` (`finance_state.dart`) |
| Use cases | `domain/usecases/` (`GetPaymentsUseCase`, `GetRefundRequestsUseCase`, `GetSubscriptionsRecordsUseCase`, `GetRevenueMetricsUseCase` — **used by Home/Business Overview**, `GetWalletPositionUseCase`, `ExportFinanceStatementUseCase`) |
| Repo | `data/repositories/finance_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_finance_datasource.dart` (`SupabaseFinanceDatasource implements FinanceDatasource`) |
| Mapper | `data/mappers/finance_row_mapper.dart` (`FinanceRowMapper` — the rules that decide what a row *means*) |
| Export | `data/services/finance_statement_export_service.dart` (`LicensedExport.consume(format)` before building PDF/Excel/CSV) |
| Entities | `domain/entities/finance_entities.dart` (`PaymentRecord`, `SubscriptionRecord`, `RefundRequest`, `RevenueMetrics`, `FinanceLedger.rowCap = 3000`, statuses), `finance_money_model.dart` (`WalletFinancePosition`, `WalletMovement`, `SettledRefund`), `finance_analytics.dart`, `finance_attention.dart` |
| Permission | `DashboardPermission.payments` (admin only); feature key `finance` |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| N1 | Payments ledger (newest 3 000 bookings) | `GET operation_bookings?select=<15 cols>&order=created_at.desc&limit=3000` | `GET /api/v1/dashboard/finance/payments` |
| N2 | Revenue metrics (uncapped) | `GET operation_bookings?select=payment_amount,payment_status,created_at` + `GET subscriptions?select=status,total_price,paid_amount,created_at` | `GET /api/v1/dashboard/finance/revenue-metrics` |
| N3 | Refund requests (newest 3 000) | `GET refund_requests?select=…,client:clients(full_name)&order=created_at.desc&limit=3000` | `GET /api/v1/dashboard/finance/refunds` |
| N4 | Subscription records (newest 3 000) | `GET subscriptions?select=…,client:clients(full_name)&order=created_at.desc&limit=3000` | `GET /api/v1/dashboard/finance/subscriptions` |
| N5 | Wallet position | `POST rpc/office_wallet_overview` ‖ `GET wallet_transactions?status=eq.posted&limit=3000` ‖ `GET refund_requests?status=eq.settled&limit=3000` | `GET /api/v1/dashboard/finance/wallet-position` |
| N6 | Export statement | `POST rpc/office_consume_export {p_kind}` → file built in Dart | `POST /api/v1/dashboard/exports` |

All reads are office-scoped **by RLS only** (no `office_id` filter in the queries):
`bookings_office_manage`, `subscriptions_office_manage`, `refund_requests_office`,
`wallet_transactions_office_read` (`office_can('wallet_ledger_view')`). No error mapping in this datasource.

---

## N1 — Payments: `getPayments()` (`supabase_finance_datasource.dart:50`)

```
GET /rest/v1/operation_bookings
  ?select=id,booking_number,passenger_name,phone,route,pickup_point_name,dropoff_point_name,trip_date,
          payment_amount,payment_method,payment_status,payment_receipt_url,payment_rejection_reason,status,created_at
  &order=created_at.desc&limit=3000
```
**Unfiltered by payment state on purpose** — an earlier filtered version under-reported receivables.
`FinanceRowMapper.payment` (`finance_row_mapper.dart:29`):

| Rule | Detail |
|---|---|
| `status` (4 buckets) | `approved → success`; `refunded → refunded`; `rejected\|failed\|cancelled → cancelled`; anything else (`pending/submitted/underReview`) → `pending` **unless the booking is `cancelled`**, then `cancelled` (a receipt on a released seat is not a receivable) |
| `awaitingReview` | `payment_status ∈ {submitted, underReview}` and booking not cancelled |
| `paymentMethod` | normalised: lowercase, `[\s-]+ → _`; `card/credit_card/debit_card/visa/mastercard → card`; `instapay/insta_pay → instapay`; `wallet/e_wallet/ewallet/vodafone/vodafone_cash/etisalat_cash/orange_cash → vodafoneCash`; else `cash` |
| origin/destination | `pickup_point_name/dropoff_point_name` when both present, else split `route` on `→ ← -> <-` (`←`/`<-` swap the ends) |
| `amount` | `payment_amount` (num or string) |

**Proposed .NET:** `GET /api/v1/dashboard/finance/payments?from=&to=&status=&method=&page=` returning the
row + the derived `status`, `awaitingReview`, `origin`, `destination` so the rules live once.

---

## N2 — Revenue metrics: `getRevenueMetrics()` (line 66)

```
GET /rest/v1/operation_bookings?select=payment_amount,payment_status,created_at        (ALL rows, uncapped)
GET /rest/v1/subscriptions?select=status,total_price,paid_amount,created_at            (ALL rows, uncapped)
```
`BUSINESS RULE` (computed in Dart, must be reproduced exactly):
* Booking revenue counts **only `payment_status = 'approved'`**, by `created_at` (not trip date):
  `today` = since local midnight, `weekly` = last 7×24h, `monthly` = last 30×24h, `total`.
* Subscription revenue skips `cancelled` and `pending_payment`; counts **`paid_amount`** (what arrived —
  fallback `total_price` only when `paid_amount` is null); `activeSubscriptions` = count of `active`.
* `RevenueMetrics { todayRevenue, weeklyRevenue, monthlyRevenue, activeSubscriptions, totalBookingsRevenue, totalSubscriptionsRevenue }`
  where the first three are booking + subscription sums.

Deliberately uncapped because a capped sum presented as a total is the truncation this codebase forbids.
**Proposed .NET:** `GET /api/v1/dashboard/finance/revenue-metrics` computed by SQL aggregates.

---

## N3 — Refund requests: `getRefundRequests()` (line 125)

`GET refund_requests?select=id,booking_id,amount,status,reason,created_at,client:clients(full_name)&order=created_at.desc&limit=3000`
→ `RefundRequest { id, transactionId=booking_id, clientName, amount, date, status, reason }` with
`status`: `approved|settled → approved`, `rejected|failed|cancelled → rejected`, else `pending`.
(Deciding refunds happens in `wallet/`.)

## N4 — Subscription records: `getSubscriptions()` (line 135)

`GET subscriptions?select=id,customer_name,package_name,total_price,paid_amount,remaining_amount,status,payment_review_status,trips_count,trips_used,start_date,end_date,created_at,client:clients(full_name)&order=created_at.desc&limit=3000`
→ `SubscriptionRecord`: `paidAmount = paid_amount` (fallback `total_price` when null),
`remainingAmount = remaining_amount ?? clamp(price − paid)`, `awaitingReview = payment_review_status ∈ {pending, under_review}`
(**underscore spelling** here, unlike bookings), `remainingRides = trips_count > 0 ? clamp(count − used) : days left`,
`status`: `expired`, `cancelled`, `pending_payment|paused → pendingPayment`, else `active`.

## N5 — Wallet position: `getWalletPosition()` (line 149)

```
POST /rest/v1/rpc/office_wallet_overview {}
→ 200 { outstanding_balance, wallet_count, funded_wallet_count, frozen_count, cashback_total, credit_total, debit_total,
        refund_total, refund_wallet_total, pending_refund_count, pending_refund_amount, generated_at }
GET  /rest/v1/wallet_transactions?select=created_at,kind,amount&status=eq.posted&order=created_at.desc&limit=3000
GET  /rest/v1/refund_requests?select=settled_at,approved_amount,settlement_method&status=eq.settled&order=settled_at.desc&limit=3000
```
Only `outstanding_balance` is read from the RPC here (= the office's **liability** to riders). Movements
→ `WalletMovement { date, kind, amount }`; settled refunds → `SettledRefund { settledAt, amount=approved_amount, toWallet = settlement_method=='wallet' }`.
`BUSINESS RULE` (`office_wallet_overview`, `20260806090300_wallet_rpcs.sql`): requires `office_can('wallet_view')`
(both roles); refunds are summed from `refund_requests`, **not** the ledger (an InstaPay refund never posts
a wallet row). The three-statement model (collected / receivable / liability) is assembled in
`finance_state.dart` from N1–N5.

## N6 — Export

`FinanceStatementExportService.generateExportBytes(statement, format)` → `LicensedExport.consume(format)`
(`pdf` → feature `export_pdf`; `excel`/`csv` → `export_excel`; meter `max_exports_per_month`) then the file
is rendered client-side. See `../README.md` §1.3 and §2.

---

## Notes for the .NET team

1. Keep every mapping rule in `FinanceRowMapper` server-side and expose the derived fields; each rule
   fixed a live wrong number (the four traps: filtered ledger, camelCase status, `total_price` vs
   `paid_amount`, raw payment-method string).
2. The ledger reads `operation_bookings` directly — there is no `payments` table for bookings besides
   `booking_payments` (written by the RPCs, read by nobody on the dashboard). A real money ledger would
   unify `booking_payments`, `subscriptions.paid_amount`, `refund_requests` and `wallet_transactions`.
3. `revenue_daily_view` exists in SQL but the console does not read it (documented divergence).
4. Caps: lists 3 000 rows (`FinanceLedger.rowCap`); metrics uncapped. Server aggregates should replace both.
