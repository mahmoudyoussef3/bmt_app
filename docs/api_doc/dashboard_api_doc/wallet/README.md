# Dashboard · Customer Wallets & Refunds (محفظة العملاء)

The office's rider wallets (per office, per client), the append-only hash-chained ledger, refund
requests (file / decide / trip batch), manual adjustments (cashback, credit, debit), reversals,
freeze/unfreeze, and tamper verification. **Every write is an RPC**; neither `wallets` nor
`wallet_transactions` has any INSERT/UPDATE/DELETE policy for any role, and the office id is
**never sent** — every RPC resolves it from `current_office_id()`.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/wallet/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.wallet` = `/wallet`; three tabs: العملاء / السجل / الاستردادات) |
| Cubit | `presentation/cubit/wallet_cubit.dart` |
| Use cases | `domain/usecases/` (one per operation below) |
| Repo | `data/repositories/wallet_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_wallet_datasource.dart` (`SupabaseWalletDatasource implements WalletDatasource`) |
| Mapper / models | `data/models/wallet_models.dart` (`WalletMapper.overview/directory/summary/ledger/transaction/refund/refundableBooking/cancelledTrip/batchResult/walletRow/chain`) |
| Entities | `domain/entities/wallet.dart`, `wallet_summary.dart`, `wallet_transaction.dart`, `refund_request.dart`, `wallet_vocabulary.dart` (`WalletKind`, `WalletCategory`, `WalletSource`, `WalletEntryStatus`, `WalletStatus`, `RefundStatus`, `RefundSettlement`) |
| Export | `data/services/wallet_statement_export_service.dart` (`LicensedExport.consume('csv')`) |
| Permissions (UX) | `customerWallets` (both roles), `walletAdjustments` / `walletApprovals` (admin) — **server truth is `office_can(capability)`**, see below |
| Feature keys | `wallet`, `refunds`, `cashback` |

### Server capability matrix (`office_can`, `20260820150000_office_customers_module.sql`)

| Capability | dashboard_admin | support_agent | Used by |
|---|---|---|---|
| `wallet_view` | ✓ | ✓ | overview, directory, summary, refundable bookings |
| `wallet_ledger_view` | ✓ | ✓ | ledger |
| `wallet_export` | ✓ | – | CSV export (client-side gate) |
| `refund_request` | ✓ | ✓ | create refund (agent's lands `pending`) |
| `refund_decide` | ✓ | – | decide, trip batch, cancelled-trips list; makes an owner's create auto-settle |
| `wallet_adjust` | ✓ | – | cashback / credit / debit |
| `wallet_reverse` | ✓ | – | reverse, verify chain |
| `wallet_freeze` | ✓ | – | set status |

## Operations

| # | Operation | Today (Supabase RPC) | Proposed .NET |
|---|---|---|---|
| W1 | Overview strip | `office_wallet_overview()` | `GET /api/v1/dashboard/wallet/overview` |
| W2 | Customer directory (paged, search) | `office_wallet_directory(p_search, p_limit, p_offset)` | `GET /api/v1/dashboard/wallet/customers` |
| W3 | One customer's wallet (entries ≤ 200, pending refunds, totals) | `office_wallet_summary(p_client_id)` | `GET /api/v1/dashboard/wallet/customers/{clientId}` |
| W4 | Office ledger (filters, paged) | `office_wallet_ledger(p_filters, p_limit, p_offset)` | `GET /api/v1/dashboard/wallet/ledger` |
| W5 | Refund queue | `GET refund_requests?office_id=eq.&status=in.(…)&limit=300` (table read) | `GET /api/v1/dashboard/refunds` |
| W6 | Refundable bookings of a client | `office_wallet_refundable_bookings(p_client_id)` | `GET /api/v1/dashboard/wallet/customers/{clientId}/refundable-bookings` |
| W7 | Cancelled trips with money owed | `office_cancelled_trips_with_refunds()` | `GET /api/v1/dashboard/refunds/cancelled-trips` |
| W8 | Adjustment (cashback / credit / debit) | `office_wallet_cashback` / `office_wallet_credit` / `office_wallet_debit` | `POST /api/v1/dashboard/wallet/adjustments` |
| W9 | Reverse an entry | `office_wallet_reverse(p_transaction_id, p_reason, p_request_key, p_category)` | `POST /api/v1/dashboard/wallet/transactions/{id}/reverse` |
| W10 | Freeze / unfreeze | `office_wallet_set_status(p_client_id, p_status, p_reason)` | `PATCH /api/v1/dashboard/wallet/customers/{clientId}/status` |
| W11 | Verify chain | `office_wallet_verify_chain(p_client_id)` | `GET /api/v1/dashboard/wallet/customers/{clientId}/verify-chain` |
| W12 | File a refund | `office_refund_create(...)` | `POST /api/v1/dashboard/refunds` |
| W13 | Decide a refund | `office_refund_decide(...)` | `POST /api/v1/dashboard/refunds/{id}/decision` |
| W14 | Refund a cancelled trip (batch) | `office_refund_trip_batch(...)` | `POST /api/v1/dashboard/refunds/trip-batch` |
| W15 | Export statement | `office_consume_export {p_kind:'csv'}` + client-side CSV | `POST /api/v1/dashboard/exports` |

All RPCs are `SECURITY DEFINER`, granted to `authenticated`, raise **bare machine codes**; the datasource
maps 30 of them (`_messages`, line 350) — keep every code:
`not_an_office_user, not_authorized, self_adjustment_denied, client_not_in_office, invalid_amount,
amount_exceeds_policy, reason_required, invalid_category, request_key_conflict, refund_exceeds_payment,
adjustment_rate_limited, daily_cap_exceeded, wallet_frozen, insufficient_wallet_balance, already_reversed,
cannot_reverse_reversal, transaction_not_found, refund_not_found, refund_not_actionable,
guest_booking_no_wallet, invalid_settlement_method, cross_office_denied, booking_not_found, trip_not_found,
wallet_not_found, wallet_ledger_immutable, wallet_balance_requires_ledger_entry` (+ `invalid_decision`,
`invalid_status`).

### The ledger's laws (`20260806090100_wallet_core.sql`) — `BUSINESS RULE`

1. `Σ wallet_transactions.amount = wallets.balance`, always; `balance_after` on every row; `seq` is gapless
   per wallet; each row carries `prev_hash`/`entry_hash` (a hash chain, `head_hash` on the wallet).
2. `kind` is a **closed** CHECK (`refund | cashback | manual_credit | manual_debit | wallet_spend |
   wallet_topup | reversal`); `category` is **open** but validated per kind by `wallet_category_allowed`.
3. Money never moves without a ledger row: `wallet_post_entry` is the only writer (revoked from
   `authenticated`); a direct `update wallets set balance` is blocked (`wallet_balance_requires_ledger_entry`);
   ledger rows are immutable except `status → reversed` (`wallet_ledger_immutable`).
4. Refunds live in `refund_requests`, not in the ledger; only a **wallet-settled** refund posts a ledger row.
5. Every write is idempotent on `p_request_key` (uuid generated client-side per dialog); the same key with
   different data ⇒ `request_key_conflict`.
6. `wallet_post_entry` guards: capability (`office_can`), `self_adjustment_denied` (operator's own client
   account), `client_not_in_office` (`office_owns_client`), amount > 0, per-office policy caps
   (`office_wallet_policies.max_single_credit/max_single_debit`, defaults 1000), reason required, category
   valid, `adjustment_rate_limited` (`max_operator_hourly_ops`, default 30/h), `daily_cap_exceeded`
   (`max_operator_daily_promo`, default 2000/day for cashback+credit), `wallet_frozen` (debits/spends only
   — a frozen wallet still accepts credits), `insufficient_wallet_balance` (`available_balance`, no overdraft).
   Creates the wallet on first posting. Pushes a client notification unless `p_notify=false`.

---

## W1 — Overview: `fetchOverview()` (`supabase_wallet_datasource.dart:35`)

```
POST /rest/v1/rpc/office_wallet_overview {}
→ 200 { outstanding_balance, wallet_count, funded_wallet_count, frozen_count, cashback_total, credit_total,
        debit_total, refund_total, refund_wallet_total, pending_refund_count, pending_refund_amount, generated_at }
```
`refund_total` comes from `refund_requests.status='settled'`, never the ledger.

## W2 — Directory: `fetchDirectory({search, limit, offset})` (line 45)

```
POST rpc/office_wallet_directory { "p_search": "<text>|null", "p_limit": 50, "p_offset": 0 }
→ 200 { "total": n, "rows": [ { client_id, full_name, phone, status, balance, wallet_status, entry_count,
                                last_activity_at, pending_refunds } ] }
```
"My office's customer" = has a booking or a subscription with the office, or a wallet. `p_limit` clamped
1..200. Search = `ilike` on name/phone. Order: balance desc, last activity desc, name.

## W3 — Summary: `fetchSummary(clientId)` (line 66)

```
POST rpc/office_wallet_summary { "p_client_id" }
→ 200 { client:{id, full_name, phone, status, created_at},
        wallet:{ exists:false, balance:0, … } | { exists:true, id, balance, available_balance, status, frozen_reason, frozen_at,
                 entry_count, lifetime_credited, lifetime_debited, last_seq, head_hash, updated_at },
        totals_by_kind:{ "<kind>": <abs sum> }, pending_refunds:[ …refund rows (pending|approved)… ],
        entries:[ { id, seq, kind, category, source, amount, balance_before, balance_after, status, reason, notes,
                    booking_id, booking_number, refund_id, reverses_transaction_id, reversed_by,
                    performed_by, performed_by_name, performed_by_role, created_at } … ≤200 by seq desc ] }
```
`client_not_in_office` when the client never dealt with the office. "No wallet" is not an error.

## W4 — Ledger: `fetchLedger({filters, limit, offset})` (line 79)

```
POST rpc/office_wallet_ledger { "p_filters": { client_id?, booking_id?, performed_by?, date_from?, date_to?, min_amount?, max_amount?,
                                               kinds?:[], categories?:[], statuses?:[], sources?:[], direction?:'credit'|'debit',
                                               has_reversal?:bool, search? }, "p_limit": 100, "p_offset": 0 }
→ 200 { total, sum_credit, sum_debit, rows:[ …same row shape as W3 entries + client_id, client_name, client_phone… ] }
```
`p_limit` clamped 1..500; ordered `created_at desc, seq desc`. **Proposed .NET:** same filters as query params.

## W5 — Refund queue: `fetchRefundQueue(statuses)` (line 96)

```
GET /rest/v1/refund_requests?select=id,client_id,booking_id,trip_id,amount,approved_amount,currency,status,category,reason,notes,
    source,settlement_method,settled_at,wallet_transaction_id,external_transaction_id,trip_cancellation_batch_id,
    requested_by_name,reviewed_by_name,reviewed_at,created_at,client:clients(full_name,phone),booking:operation_bookings(booking_number)
    &office_id=eq.<office>&status=in.(pending,approved,settled,rejected,failed,cancelled)&order=created_at.desc&limit=300
```
The one table read in the module (RLS `refund_requests_office`). `status` vocabulary:
`pending | approved | settled | rejected | failed | cancelled`; `settlement_method`:
`wallet | original_method | cash | bank_transfer`.

## W6 / W7 — Targets for the write dialogs (lines 126 / 143)

* `office_wallet_refundable_bookings(p_client_id)` → `[ { booking_id, booking_number, trip_id, trip_date, route, seat, status,
  payment_status, payment_amount, created_at, paid_amount, payment_method, payment_state, refundable_amount } ]` —
  non-draft bookings with `refund_capacity > 0`.
* `office_cancelled_trips_with_refunds()` → `[ { trip_id, trip_date, departure_time, status, route_name, pending_bookings, refundable_amount } ]`
  — cancelled trips whose `reserved|confirmed|boarded` bookings still have capacity (needs `refund_decide`).

`refund_capacity(booking)` = `coalesce(booking_payments.amount, operation_bookings.payment_amount) − Σ settled approved_amount`.

## W8 — Adjustments: `postAdjustment({kind, clientId, amount, category, reason, notes, requestKey})` (line 156)

```
POST rpc/office_wallet_cashback | office_wallet_credit | office_wallet_debit
{ "p_client_id", "p_amount": 50.0, "p_category": "promotion|compensation|loyalty|retention|marketing_campaign|referral"   (cashback)
                                               | "support_adjustment|goodwill|correction|migration"                       (credit)
                                               | "correction|wrong_cashback|accounting_adjustment|clawback"               (debit),
  "p_reason": "…", "p_notes": "…|null", "p_request_key": "<uuid>" }
→ 200 { …wallet_transactions row… }
```
Kind is fixed by the function name (never a parameter). Capability `wallet_adjust`.

## W9 — Reverse: `reverseTransaction({transactionId, reason, category, requestKey})` (line 192)

`office_wallet_reverse { p_transaction_id, p_reason, p_request_key, p_category: operator_error|duplicate|fraud|dispute }`
→ posts a `reversal` row of `abs(original.amount)` with the opposite sign, marks the original `reversed`
(`already_reversed`, `cannot_reverse_reversal`); reversing a settled refund's wallet leg sets that
`refund_requests` row to `cancelled` (returns capacity to the booking). Capability `wallet_reverse`.

## W10 — Freeze: `setWalletStatus({clientId, status, reason})` (line 215)

`office_wallet_set_status { p_client_id, p_status: 'active'|'frozen', p_reason }` → wallet row. Reason
required both ways; stamps `frozen_reason/by/at`; pushes an operational alert `wallet_status` (`high`).
Capability `wallet_freeze`.

## W11 — Verify chain: `verifyChain(clientId)` (line 236)

`office_wallet_verify_chain { p_client_id }` → `{ wallet_id, verified, fault: null|sequence_gap|chain_break|hash_mismatch|balance_drift|head_mismatch,
divergent_seq, entries, ledger_balance, cached_balance, head_hash }`. A fault **auto-freezes** the wallet and
raises an `urgent` alert `wallet_chain_divergence`. Capability `wallet_reverse`.

## W12 — File a refund: `createRefund({bookingId, amount, category, reason, notes, settlement, requestKey})` (line 249)

```
POST rpc/office_refund_create
{ "p_booking_id", "p_amount", "p_category": "trip_cancelled|booking_cancelled|driver_unavailable|office_error|duplicate_payment|service_failure|other",
  "p_reason", "p_notes", "p_settlement_method": "wallet|original_method|cash|bank_transfer", "p_request_key" }
→ 200 { …refund_requests row… }
```
`BUSINESS RULE` (`refund_file` + `refund_apply_settlement`, `20260806090300_wallet_rpcs.sql:63-275`):
capability `refund_request`; office owns the booking; idempotent on key; **locks the booking row** (the
serialisation point for the cumulative cap); `invalid_amount`, `refund_exceeds_payment` (capacity re-checked
at settle time too). An **owner's** refund (`refund_decide`) is born `approved` and settled in the same call;
a **support agent's** is born `pending` and lands in the queue. Settlement: `wallet` posts the ledger leg via
`wallet_post_entry(kind='refund', notify=false)` (`guest_booking_no_wallet` when `client_id` is null — cash
is the first-class path for guests); any method stamps `settled/settlement_method/settled_at/wallet_transaction_id`;
when Σ settled ≥ paid, `booking_payments.status` and `operation_bookings.payment_status` flip to `refunded`.
Trigger `on_refund_request_change` notifies the rider and raises an operational alert (suppressed per row inside a batch).

## W13 — Decide: `decideRefund({refundId, approve, approvedAmount, settlement, reason, requestKey})` (line 278)

`office_refund_decide { p_refund_id, p_decision:'approve'|'reject', p_approved_amount?, p_settlement_method, p_reason?, p_request_key }`
— capability `refund_decide`; `refund_not_actionable` unless `pending|approved`; reject requires a reason
(stored in `notes`); approve sets `approved_amount` (default requested amount) then settles as in W12.

## W14 — Trip batch: `refundTripBatch({tripId, category, reason, settlement, requestKey})` (line 305)

`office_refund_trip_batch { p_trip_id, p_category:'trip_cancelled', p_reason:'إلغاء الرحلة', p_settlement_method, p_request_key }`
→ `{ batch_id, trip_id, refunded, skipped, total_amount, refunds:[ {refund_id, booking_id, amount, status} ] }`.
Capability `refund_decide`; iterates `reserved|confirmed|boarded` bookings of the trip **ordered by
client_id** (deadlock-free), refunds each one's full capacity with a deterministic per-booking key
(`uuid_v5(batch, booking_id)`) so a re-run is exactly-once; guest seats settle `cash` when `wallet` was
asked; one operational alert `refund_batch` for the whole batch.

---

## Notes for the .NET team

1. Port the ledger laws as DB constraints + one posting function; do not reimplement them in application code
   only. The hash chain and `verify_chain` are the tamper evidence the owner relies on.
2. Idempotency keys are generated by the dialog (one per open dialog) — keep `requestKey` on every write.
3. Refund settlement outside the wallet (`cash`, `bank_transfer`, `original_method`) records **no** money
   movement anywhere except `refund_requests`; Finance's statements depend on that table.
4. The per-office policy row (`office_wallet_policies`) is read by the posting function; today no dashboard
   screen edits it (`wallet_policy_edit` capability exists, unused).
5. Notifications: adjustments and refunds notify the rider (`push_notification`), freezes/batches/divergences
   raise operational alerts — see `notifications/`.
