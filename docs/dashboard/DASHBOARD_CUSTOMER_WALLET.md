# Wallet & Financial Adjustments — Final Architecture

Status: **final design, awaiting approval**. No code written.
Audited against the linked database on 2026-08-06. Revision 3 — supersedes revisions 1 and 2.

> **Revision 3 scope.** Revision 2 designed a correct refund-and-adjustment feature. Revision 3 re-frames it as
> an **extensible financial subsystem**: the same V1 surface, but shaped so that wallet payments, split
> payments, reserved balances, promotional campaigns and external payment providers arrive as *additions*
> rather than migrations. One genuine structural limit was found and closed (§2.8); everything else was already
> additive and is now written down as a contract (Part 3A) rather than left to be rediscovered.
> **No V1 feature scope was added.**

---

## Part 0 — Verdict

**Approve the foundations, with seven material changes.** The first design was right about ownership,
immutability, cached balance, RPC-only writes and RLS isolation. It was wrong or incomplete in seven places,
three of them serious:

| # | Change | Severity |
|---|---|---|
| 1 | **The accounting model was wrong.** Excluding wallet-paid bookings from revenue understates earnings by the full fare. Replaced with three independent statements plus a provable control identity (§7). | 🔴 Critical |
| 2 | **Refunds are not a wallet operation.** A refund to InstaPay never touches the wallet, so a wallet-ledger-derived refund total silently omits them. The refund record moves to a hardened `refund_requests` (§3.3, §10). | 🔴 Critical |
| 3 | **Client deletion destroys financial history today** — `refund_requests.client_id` is `ON DELETE CASCADE` and `clients.id → auth.users` is `ON DELETE CASCADE`. Deleting one Supabase auth user erases their refund record. (§15.1) | 🔴 Critical |
| 4 | One flat `kind` enum replaced by **kind + category + source** — closed accounting axis, open business axis. (§2.4) | 🟠 Structural |
| 5 | Ledger gains a **per-wallet sequence and hash chain**, making tampering detectable rather than merely blocked. (§2.5, §12) | 🟠 Structural |
| 6 | **Bulk trip-cancellation refund** added. Refunding a 14-seat cancelled bus one customer at a time is not a product. (§10.4) | 🟠 Missing rule |
| 7 | Fraud controls added: **self-dealing block, per-operator velocity caps, request fingerprinting**. (§13) | 🟠 Missing rule |
| 8 | **The wallet was hardcoded to a customer.** `client_wallets.client_id NOT NULL` is the one thing in the design that a future capability could not extend without a rename-and-migrate. Generalised to `wallets` + an `owner_type` discriminator, still emitting only `'client'` in V1. (§2.8) | 🟠 Structural |
| 9 | Five **ledger laws** written down as the maintainability contract, plus additive blueprints for holds, lots/expiry, campaigns, transfers and providers. (Part 3A) | 🟢 Contract |

Two claims from revision 1 are **withdrawn**: "exclude wallet-paid bookings from gross" and "refunds are summed
from the wallet ledger". Both are replaced below.

Everything else — `(office, customer)` ownership, non-negative balance, immutable append-only ledger, cached
balance, RPC-only writes, no cashback expiry in V1 — survives review and is re-justified rather than assumed.

---

## Part 1 — Audit (retained, plus new findings)

### 1.1 Carried forward from revision 1

- `loyalty_accounts.wallet_balance` exists, 0 rows, no office column, self-`SELECT` policy only, no writer.
  `loyalty_transactions` stores points, not money. Cannot be extended.
- The wallet is stubbed in three layers: `payment_methods.wallet_balance` (`is_active = false`),
  `PaymentMethodType.walletBalance`, and `wizard_payment_mapping.dart` mapping it to `null`.
- [supabase_referral_rewards_datasource.dart:22-27](lib/apps/client/features/referrals/data/datasources/supabase_referral_rewards_datasource.dart#L22-L27)
  zeroes a balance client-side with no ledger and reports a payout that never happened (RLS denies the write
  without throwing). Latent only because the balance is always 0.
- `booking_payments.status = 'refunded'` is unreachable — nothing in the schema writes it.
- `operation_bookings.payment_status` uses `underReview`; `booking_payments.status` uses `under_review`.
- Finance's refund UI was deleted 2026-08-01 and never rehomed.
- No customer entity exists in the dashboard.
- Isolation primitives (`current_office_id`, `office_role`, `assert_office_owns_booking`) are solid; the
  `clients_office_read` predicate already defines "my office's customer".

### 1.2 New findings from this pass

**F1 — Financial history is deletable through a cascade chain (critical).**
```
auth.users ──ON DELETE CASCADE──▶ clients ──ON DELETE CASCADE──▶ refund_requests
                                          └─ON DELETE CASCADE──▶ loyalty_accounts
```
Deleting a Supabase auth user silently destroys that customer's refund history. `operation_bookings.client_id`
is `ON DELETE SET NULL`, so the bookings survive but become unattributable. Any financial table added now must
use `ON DELETE RESTRICT`, and the consequence must be accepted deliberately (§15.1).

**F2 — `refund_requests` is not usable as a financial record as it stands.**
`booking_id` is **`text`**, not a uuid FK. `reviewed_by` is **`text`**, not a user reference. `status` has **no
CHECK constraint**. `office_id` is `ON DELETE SET NULL` while its RLS policy requires `office_id is not null` —
so deleting an office makes every one of its refunds invisible to everyone, forever. All four are fixable for
free: the table has **0 rows**.

**F3 — `pg_cron` is not installed.** Verified: `pg_extension` holds `btree_gist, pg_stat_statements, pgcrypto,
plpgsql, supabase_vault, uuid-ossp`. There is no in-database scheduler, so cashback expiry, wallet sweeps and
automatic reconciliation jobs cannot run without adding an extension or an external scheduler. This is a
concrete technical reason to defer expiry (§11), not a preference.

**F4 — `pgcrypto` *is* installed**, so `digest(..., 'sha256')` is available at zero infrastructure cost. Hash
chaining the ledger becomes a ~15-line addition rather than a project (§2.5).

**F5 — Referral rewards were already designed to pay into a wallet.** `referral_rewards.reward_type` accepts
`'wallet'` and the dashboard config lists it ([referral_reward_config.dart:29](lib/apps/dashboard/features/referrals/domain/entities/referral_reward_config.dart#L29)).
`referrals` and `referral_reward_transactions` are empty. Referral payout is therefore a **cashback category**
with a `referral_id` link — not a new transaction type, and not a second reward system (§2.4).

**F6 — Guest bookings exist.** `operation_bookings.client_id` is nullable. A booking with no client has no
wallet to refund into, so cash settlement must be a first-class path, not a fallback (§10.2).

**F7 — `request.headers` is unavailable on direct connections.** It returned `NULL` in this session. PostgREST
sets it for API-originated calls only, and its contents are client-supplied. It is advisory context, never
evidence (§12.4).

---

## Part 2 — Architecture review: challenges and decisions

### 2.1 Wallet ownership — challenged, retained

Four models were considered against the requirement "no office may ever access another office's balances".

| Model | Verdict |
|---|---|
| **Global customer wallet** | ❌ Value collected by Office A becomes spendable at Office B with no inter-office settlement. There is no clearing mechanism in this platform and building one is a different product. RLS cannot isolate a single balance column across offices. |
| **Wallet per `(office, customer)`** | ✅ **Retained.** Matches how the money was actually collected, matches the `office_id = current_office_id()` idiom every other table uses, and makes isolation a schema property rather than a query discipline. |
| **Credit-note / voucher per refund** | ❌ for V1. Solves expiry and provenance elegantly, but the customer sees five balances instead of one, checkout must choose which note to spend, and the operator UX becomes note administration. Correct for airlines, wrong for a 14-seat minibus office. |
| **Wallet + credit lots (hybrid)** | ⏸ Deferred, and **provably additive**: lots arrive as a new `wallet_credit_lots` table referencing existing transaction ids plus a consumption RPC. No change to `wallets` or `wallet_transactions` is required. That is why V1 does not need to reserve a `lot_id` column. |

A customer who uses three offices holds three wallets and sees three labelled balances. That is the honest
model — these are three separate credit relationships with three separate businesses.

**Not `(office, customer, currency)`.** Everything is EGP; `currency` is pinned by CHECK. Multi-currency, if it
ever arrives, is one wallet row per currency — additive. No `exchange_rate` column: a field nobody maintains is
worse than no field.

### 2.2 The accounting model was wrong — this is the headline correction

Revision 1 said: *gross includes `refunded` bookings, excludes wallet-paid bookings; refunds are summed from the
wallet ledger.* Trace three events through it:

```
1. Customer books, pays 300 cash        → gross 300
2. Trip cancelled, 300 refunded to wallet → refunds 300, net 0
3. Customer rebooks, pays with the 300   → excluded from gross, net still 0
```

The office ran two trips, kept 300 EGP, and the report says it earned **nothing**. The error is conflating
**cash** with **revenue**. A wallet balance is neither — it is a **liability**: money the office holds and owes
back as service.

The fix is to stop computing one number and start computing three, each independently simple:

```
REVENUE  (accrual)  = Σ fare of confirmed bookings          − Σ refunds granted (any destination)
CASH     (treasury) = Σ approved non-wallet payments        − Σ refunds settled outside the wallet
LIABILITY           = Σ wallets.balance
```

Revenue is keyed on the **booking fare** and is indifferent to how it was tendered. Cash is keyed on **tender**
and is indifferent to what was sold. That separation is what makes double-counting structurally impossible
rather than a rule someone must remember. Full model, control identity and worked examples in **§7**.

### 2.3 A refund is not a wallet operation

Revision 1 assumed every refund lands in the wallet. Offices refund to InstaPay, to a card via Paymob, and in
cash. Those refunds never touch the wallet, so any refund total derived from the wallet ledger under-reports —
by exactly the amounts most likely to be disputed.

**Decision: `refund_requests` becomes the authoritative refund record for every refund, whatever its
destination.** One row per refund decision, carrying `settlement_method ∈ (wallet, original_method, cash,
bank_transfer)`. Only `settlement_method = 'wallet'` also posts a `wallet_transactions` row, linked both ways.

Consequences, all good:
- Finance reads refunds from **one** place, and it is the place that knows all of them.
- Partial refunds get a natural home: many refund rows per booking, cumulative cap enforced against the payment.
- The client-initiated request and the office-initiated refund become the **same record at different stages** —
  one pipeline, one audit trail, one queue (§10).
- The table's four structural defects (F2) get fixed while it is still empty.

### 2.4 One enum replaced by three axes

A single flat type list conflates three different questions. Splitting them is what keeps this maintainable:

| Axis | Question | Property | Values |
|---|---|---|---|
| `kind` | What happened to the balance? | **Closed.** The accounting depends on it. | `refund`, `cashback`, `manual_credit`, `manual_debit`, `wallet_spend`, `wallet_topup`, `reversal` |
| `category` | Why? | **Open.** The business adds reasons forever. | per kind — see §5.2 |
| `source` | Who drove it? | Closed, small. | `dashboard`, `client`, `system`, `migration` |

This directly answers the transaction-type question. `promotional_credit`, `referral_reward`,
`system_correction` and `migration` are **not kinds** — they behave identically to `cashback` or
`manual_credit`/`manual_debit` in every calculation. Making them kinds would inflate the closed accounting axis
with rows that need no accounting distinction, and every future `case` statement would grow with them. They are
categories and sources:

- referral payout → `kind=cashback, category=referral, source=system, referral_id=…` (F5)
- data import → `kind=manual_credit, category=migration, source=migration, performed_by=null`
- system correction → `kind=manual_debit, category=correction, source=system`

`expiration` is a genuine kind, deferred with the feature (§11). All seven kinds go into the CHECK constraint
**on day one** — including `wallet_spend` and `wallet_topup`, which V1 never emits. Unlike a reserved *column*
(which I argued against for `expires_at`), a reserved *enum value* has no UI surface, makes no promise to
anyone, and removes a constraint migration from V2's path.

### 2.5 Ledger integrity: sequence + hash chain

The requirement is "impossible to tamper with". The achievable guarantee needs stating honestly: **RLS,
revocations and triggers stop application-level tampering; nothing inside Postgres stops a database owner.**
What closes that gap is making tampering *detectable*.

1. **Per-wallet sequence.** `seq bigint`, `unique (wallet_id, seq)`, assigned as `prev.seq + 1` under the wallet
   row lock. A deleted row leaves a gap; a forged row collides. Ordering becomes deterministic, which
   `created_at` alone never is under concurrency.
2. **Hash chain.** `prev_hash bytea`, `entry_hash = sha256(prev_hash ‖ canonical(row))` via pgcrypto (F4 —
   already installed). Altering any historical row invalidates every hash after it. A single query verifies a
   whole wallet.
3. **Chain head export.** The daily statement export includes each wallet's head hash, so an off-database copy
   exists that in-database edits cannot reach.

Cost: ~15 lines in one function and one verification query. For a system whose stated requirement is
tamper-proof financial history, that is the cheapest honest answer available.

### 2.6 Non-negative balance — retained

Re-argued rather than assumed. `CHECK (balance >= 0)`:

1. The platform has no instrument to collect a debt — no invoicing, no credit terms, no dunning. A negative
   balance would be a number that can never be resolved.
2. Every debit is discretionary and operator-initiated. If a correction would go below zero, the honest outcome
   is "you cannot claw back more than is there"; the remainder is a business dispute, not a ledger entry.
3. Once credit is spendable (V2), a negative balance is silently netted against the customer's next ride —
   turning a ride purchase into debt collection without consent.
4. It removes a bug class: with a non-negative invariant, "the balance is wrong" is *always* a ledger failure,
   never an intended state to reason about.

Escape hatch, deliberately narrow and not in V1: an explicit per-office `overdraft_limit` in
`office_wallet_policies` (§3.4), defaulting to 0. A configured limit, never a silently signed number.

### 2.7 V2 readiness — wallet spending needs zero schema change

The brief asks that V2 wallet payments require no major database change. That is achievable, and the reason is
worth stating because it drives a V1 decision:

**Wallet tender is recorded only in `wallet_transactions` (`kind = wallet_spend`, `booking_id` set). It is never
written to `booking_payments`.**

- `booking_payments.booking_id` is `UNIQUE` — one external payment per booking. Recording wallet tender there
  would force split-tender rows and a constraint migration. Keeping it out avoids that entirely.
- `operation_bookings.payment_amount` stays the **fare** (300), `booking_payments.amount` stays the **external
  tender** (200), the wallet ledger holds the **wallet leg** (100). Three columns, three distinct meanings, no
  overlap — which is exactly what §7's three statements read.

V2's whole surface becomes: a wallet leg inside `confirm_seat_booking_v2`, flipping
`payment_methods.wallet_balance.is_active`, and un-stubbing the client wizard. No new table, no altered
constraint, no backfill.

### 2.8 The one structural limit — the wallet was hardcoded to a customer

Every planned capability was tested against the revision-2 schema to see whether it lands as an addition or a
migration:

| Future capability | What it needs | Additive? |
|---|---|---|
| Wallet payments at checkout | `kind = wallet_spend`, `booking_id` | ✅ already present |
| Split tender: wallet + one external method | nothing — ledger holds the wallet leg, `booking_payments` the external one | ✅ zero change |
| Reserved balances / holds | `wallet_holds` table + `reserved_balance` | ✅ additive (§3A.2) |
| Promotional campaigns | `wallet_campaigns` table + `campaign_id` FK | ✅ additive (§3A.4) |
| Cashback expiry / credit lots | two tables, back-computed from `seq` | ✅ additive (§3A.3) |
| External providers (top-up, provider refunds) | an edge table, not ledger columns | ✅ additive (§3A.5) |
| Wallet-to-wallet transfer | `transfer_group_id` + paired entries | ✅ additive (§3A.6) |
| **Driver / captain earnings wallet** | a wallet whose owner is not a client | ❌ **blocked** |
| **Office float or platform commission account** | same | ❌ **blocked** |

The last two are blocked by one line: `client_wallets.client_id uuid NOT NULL`. A transportation platform that
pays captains, or a multi-office SaaS that eventually takes a commission, needs a wallet whose owner is a driver,
an office, or the platform. Neither is speculative for this product — captains already have `drivers.office_id`
and a `user_id`.

The expensive part of fixing that later is **not** the column. It is renaming `client_wallets` → `wallets`
across the whole app layer, changing twelve RPC signatures, and re-labelling every entity, repository and test.
That is a refactor; the column is an `ALTER`.

**Decision: name and shape it generically now, keep it pinned to clients.**

```sql
owner_type text not null default 'client' check (owner_type = 'client')   -- widen, don't rename
client_id  uuid not null references public.clients(id) on delete restrict
unique (office_id, client_id) where owner_type = 'client'                 -- partial, so siblings can join
```

V1 is behaviourally identical to revision 2 — one value, one owner kind, one CHECK. Adding driver wallets later
is: widen the CHECK, drop `NOT NULL` on `client_id`, add `driver_id` with its own FK and partial unique index.
Additive, no rename, no data migration, no application refactor. The ledger is already keyed on `wallet_id`
rather than `client_id`, so it needs nothing at all.

This is the same discipline applied to `overdraft_limit` (§3.4): the extension point exists and is
**CHECK-pinned closed**, so relaxing the CHECK is the single deliberate act that enables it. It differs from
the `expires_at` column rejected in §11 because it makes no promise to any user and nobody has to maintain it.

---

## Part 3 — Recommended database schema

### 3.1 `wallets`

```sql
create table public.wallets (
  id                uuid primary key default gen_random_uuid(),
  office_id         uuid not null references public.offices(id) on delete restrict,

  -- Owner. V1 emits only 'client'; the discriminator exists so driver, office and
  -- platform wallets are an ALTER rather than a rename-and-migrate (§2.8).
  owner_type        text not null default 'client' check (owner_type = 'client'),
  client_id         uuid not null references public.clients(id) on delete restrict,

  balance           numeric(12,2) not null default 0 check (balance >= 0),
  -- Value committed to a pending operation but not yet spent. CHECK-pinned to 0 in
  -- V1; relaxing that CHECK is the single act that enables holds (§3A.2). Every
  -- debit and spend validates against available_balance from day one, so enabling
  -- holds changes no RPC logic.
  reserved_balance  numeric(12,2) not null default 0 check (reserved_balance = 0),
  available_balance numeric(12,2)
                    generated always as (balance - reserved_balance) stored,

  currency          text not null default 'EGP' check (currency = 'EGP'),
  lifetime_credited numeric(12,2) not null default 0 check (lifetime_credited >= 0),
  lifetime_debited  numeric(12,2) not null default 0 check (lifetime_debited  >= 0),
  entry_count       bigint not null default 0,
  last_seq          bigint not null default 0,
  head_hash         bytea,
  status            text not null default 'active' check (status in ('active','frozen')),
  frozen_reason     text,
  frozen_by         uuid references auth.users(id) on delete restrict,
  frozen_at         timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint wallet_reserved_le_balance check (reserved_balance <= balance),
  constraint wallet_frozen_has_reason
    check (status <> 'frozen' or nullif(btrim(coalesce(frozen_reason,'')),'') is not null)
);

-- Partial, so a driver/office wallet can later get its own without touching this one.
create unique index uniq_wallet_client
  on public.wallets (office_id, client_id) where owner_type = 'client';
```

A **frozen** wallet still accepts credits (you must always be able to refund someone) but refuses debits and
spends. Freezing is a fraud hold, not a punishment.

### 3.2 `wallet_transactions`

```sql
create table public.wallet_transactions (
  id             uuid primary key default gen_random_uuid(),
  -- wallet_id is the ONLY structural link to the owner. client_id below is a
  -- denormalised copy kept solely so the client self-read RLS policy needs no
  -- join; a future non-client wallet simply leaves it null and never matches it.
  wallet_id      uuid not null references public.wallets(id)   on delete restrict,
  office_id      uuid not null references public.offices(id)   on delete restrict,
  client_id      uuid          references public.clients(id)   on delete restrict,
  seq            bigint not null,

  kind     text not null check (kind in
             ('refund','cashback','manual_credit','manual_debit',
              'wallet_spend','wallet_topup','reversal')),
  category text not null,
  source   text not null default 'dashboard'
             check (source in ('dashboard','client','system','migration')),

  amount         numeric(12,2) not null check (amount <> 0),   -- credits +, debits −
  balance_before numeric(12,2) not null check (balance_before >= 0),
  balance_after  numeric(12,2) not null check (balance_after  >= 0),
  currency       text not null default 'EGP' check (currency = 'EGP'),
  status         text not null default 'posted' check (status in ('posted','reversed')),

  reason text not null check (length(btrim(reason)) > 0),
  notes  text,

  -- Typed references. Deliberately NOT (reference_type, reference_id): a ledger's
  -- value is referential integrity, and a polymorphic pair cannot carry a FK.
  booking_id              uuid references public.operation_bookings(id) on delete restrict,
  refund_id               uuid references public.refund_requests(id)    on delete restrict,
  subscription_id         uuid references public.subscriptions(id)      on delete restrict,
  referral_id             uuid references public.referrals(id)          on delete restrict,
  reverses_transaction_id uuid references public.wallet_transactions(id) on delete restrict,
  metadata                jsonb not null default '{}'::jsonb,

  performed_by      uuid references auth.users(id) on delete restrict,  -- null ⇒ system/migration
  performed_by_name text not null,
  performed_by_role text,
  request_key         uuid not null,
  request_fingerprint text not null,
  client_ip           inet,          -- advisory (F7)
  user_agent          text,          -- advisory (F7)

  prev_hash  bytea,
  entry_hash bytea not null,
  created_at timestamptz not null default now(),

  constraint wtx_arithmetic check (balance_after = balance_before + amount),
  constraint wtx_sign check (
        (kind in ('refund','cashback','manual_credit','wallet_topup') and amount > 0)
     or (kind in ('manual_debit','wallet_spend')                      and amount < 0)
     or (kind = 'reversal')),
  constraint wtx_reversal_link  check ((kind = 'reversal') = (reverses_transaction_id is not null)),
  constraint wtx_refund_link    check (kind <> 'refund'      or refund_id  is not null),
  constraint wtx_spend_link     check (kind <> 'wallet_spend' or booking_id is not null),
  constraint wtx_actor          check (performed_by is not null or source in ('system','migration')),
  unique (wallet_id, seq),
  unique (office_id, request_key)
);

create index idx_wtx_wallet_seq     on public.wallet_transactions (wallet_id, seq desc);
create index idx_wtx_office_created on public.wallet_transactions (office_id, created_at desc);
create index idx_wtx_office_kind    on public.wallet_transactions (office_id, kind, created_at desc);
create index idx_wtx_booking        on public.wallet_transactions (booking_id) where booking_id is not null;
create index idx_wtx_performer      on public.wallet_transactions (performed_by, created_at desc);
```

**Dropped from revision 1:** `booking_payment_id` (derivable — `booking_payments` is unique per booking) and
`trip_id` (derivable from the booking). Two fewer nullable columns that could disagree with their source.
**Rejected:** `exchange_rate` (single currency), `external_transaction_id` (belongs on the refund record, which
is what actually talks to Paymob — §3.3).

`balance_after = balance_before + amount` as a table CHECK means an arithmetically wrong row cannot be inserted
at all, regardless of which function computes it.

### 3.3 `refund_requests` — hardened into the refund record

All of this is free: the table has 0 rows.

```sql
alter table public.refund_requests
  alter column booking_id type uuid using nullif(booking_id,'')::uuid,
  add  constraint refund_booking_fk foreign key (booking_id)
       references public.operation_bookings(id) on delete restrict,

  alter column client_id set not null,
  drop constraint refund_requests_client_id_fkey,           -- was ON DELETE CASCADE  (F1)
  add  constraint refund_requests_client_fk foreign key (client_id)
       references public.clients(id) on delete restrict,

  alter column office_id set not null,
  drop constraint refund_requests_office_fk,                -- was ON DELETE SET NULL (F2)
  add  constraint refund_requests_office_fk foreign key (office_id)
       references public.offices(id) on delete restrict,

  drop column reviewed_by,                                  -- was text (F2)
  add  column reviewed_by uuid references auth.users(id) on delete restrict,
  add  column reviewed_by_name text,
  add  column requested_by uuid references auth.users(id) on delete restrict,
  add  column source text not null default 'client'
       check (source in ('client','dashboard')),
  add  column approved_amount numeric(12,2) check (approved_amount > 0),
  add  column settlement_method text
       check (settlement_method in ('wallet','original_method','cash','bank_transfer')),
  add  column settled_at timestamptz,
  add  column wallet_transaction_id uuid references public.wallet_transactions(id) on delete restrict,
  add  column external_transaction_id text,
  add  column request_key uuid,
  add  column trip_cancellation_batch_id uuid,

  add  constraint refund_status_check check (status in
       ('pending','approved','rejected','settled','failed','cancelled')),
  add  constraint refund_settled_shape check (
        status <> 'settled'
        or (approved_amount is not null and settlement_method is not null and settled_at is not null)),
  add  constraint refund_wallet_link check (
        settlement_method is distinct from 'wallet'
        or status <> 'settled'
        or wallet_transaction_id is not null);
```

The existing `sync_refund_request_office()` trigger and `on_refund_request_change()` notification trigger are
kept unchanged — they already do the right thing.

### 3.4 `office_wallet_policies` — limits as data, not deploys

```sql
create table public.office_wallet_policies (
  office_id                uuid primary key references public.offices(id) on delete restrict,
  max_single_credit        numeric(12,2) not null default 1000  check (max_single_credit  > 0),
  max_single_debit         numeric(12,2) not null default 1000  check (max_single_debit   > 0),
  max_operator_daily_promo numeric(12,2) not null default 2000  check (max_operator_daily_promo >= 0),
  max_operator_hourly_ops  int           not null default 30    check (max_operator_hourly_ops  > 0),
  overdraft_limit          numeric(12,2) not null default 0     check (overdraft_limit = 0),
  require_second_approval_above numeric(12,2),
  timezone                 text not null default 'Africa/Cairo',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

`overdraft_limit` is CHECK-pinned to 0 in V1 — the column documents the extension point without enabling it.
Relaxing the CHECK is the deliberate act that turns overdraft on. Daily caps are evaluated in the office's own
timezone, not the server's or the operator's device (§15.8).

### 3.5 RLS

| Table | Office | Client | Write |
|---|---|---|---|
| `wallets` | `SELECT` where `office_id = current_office_id()` | `SELECT` where `client_id = auth.uid()` | none — RPC only |
| `wallet_transactions` | `SELECT` where `office_id = current_office_id()` | `SELECT` where `client_id = auth.uid()` | none — RPC only |
| `refund_requests` | existing `refund_requests_office` (ALL) | existing self read + insert | tightened to `SELECT` for office; decisions via RPC |
| `office_wallet_policies` | `SELECT` where office matches; `UPDATE` where office matches **and** `office_role() = 'dashboard_admin'` | none | direct (non-financial config) |

**No INSERT/UPDATE/DELETE policy exists on either wallet table for any role.** RLS alone therefore denies every
mutation, and the only path to money movement is a SECURITY DEFINER RPC. Plus explicit
`revoke insert, update, delete, truncate` from `anon, authenticated` — TRUNCATE is never filtered by RLS, the
lesson already recorded from the Phase 6 tracking work.

---

## Part 3A — The extensibility contract

What keeps a financial subsystem maintainable for years is not spare columns — it is a small set of invariants
that every future feature must respect. Columns can be added cheaply; a violated invariant is discovered two
years later as a balance that does not reconcile. These five laws are the contract. Everything in §3A.2–§3A.7
is a **blueprint, not a build**: each is shown to be additive, and none is implemented in V1.

### 3A.1 The five ledger laws

**L1 — The ledger records settled value movement only.**
Commitments — holds, authorisations, pending campaign accruals, scheduled expiries — live in their own tables
and **never** post a ledger row. Corollary: `Σ amount = balance` per wallet, always, with no exceptions anyone
has to remember. This is the law most likely to be broken by a well-meaning future implementation of holds, and
it is why §3A.2 is spelled out in advance.

**L2 — Balance is derived; every derived structure must be back-computable from the ledger.**
The ledger is complete, ordered (`seq`) and immutable, so any future model — credit lots, tax buckets, tier
accrual, cohort analysis — can be *replayed* from history rather than migrated onto live balances. This is what
makes expiry (§3A.3) a feature addition instead of a data-migration project.

**L3 — `kind` is closed; `category` is open.**
A new business reason is a `category`. A new *balance effect* is a `kind`. If a proposed kind is computed
identically to an existing one in §7, it is a category. Adding a kind is a one-line
`drop constraint / add constraint` — cheap, but it forces a decision about accounting treatment, which is
exactly the friction it should have.

**L4 — Money never moves without a `wallet_transactions` row.**
No side-channel column, no direct `update wallets set balance = …`, no exceptions for imports or corrections.
Enforced structurally: the balance columns are only writable by `wallet_post_entry`, which always inserts.

**L5 — External systems integrate at the edge, never in the ledger.**
Provider identifiers, gateway payloads, HMACs and callback state live on an *instrument* row
(`booking_payments`, `refund_requests`, a future `wallet_topups`). The ledger references it by typed FK and
stays provider-agnostic forever. This is why revision 2's `external_transaction_id` sits on the refund record
and why no `provider` / `provider_ref` column is being added to `wallet_transactions` — see §3A.5.

### 3A.2 Reserved balances / holds — blueprint

```sql
create table public.wallet_holds (            -- NOT BUILT IN V1
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id) on delete restrict,
  amount    numeric(12,2) not null check (amount > 0),
  status    text not null default 'active' check (status in ('active','captured','released','expired')),
  booking_id uuid references public.operation_bookings(id) on delete restrict,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
```

Rules, fixed now so they cannot be got wrong later:
- A hold **never** posts a ledger row (L1). It increments `wallets.reserved_balance`.
- Capturing a hold posts one `wallet_spend` and decrements `reserved_balance`.
- Releasing or expiring a hold posts nothing and decrements `reserved_balance`.
- Invariants: `reserved_balance = Σ active holds` and `reserved_balance <= balance` (already constrained).
- Debits and spends validate against `available_balance`, **which V1 already does** — so enabling holds changes
  zero RPC logic. Only `check (reserved_balance = 0)` is relaxed.

Expiring holds needs a scheduler, and `pg_cron` is not installed (F3); until it is, a hold expires lazily on the
next read of that wallet. Worth knowing before, not after.

### 3A.3 Credit lots and expiry — blueprint

```sql
create table public.wallet_credit_lots (      -- NOT BUILT IN V1
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id) on delete restrict,
  source_transaction_id uuid not null references public.wallet_transactions(id) on delete restrict,
  original_amount  numeric(12,2) not null check (original_amount  > 0),
  remaining_amount numeric(12,2) not null check (remaining_amount >= 0),
  expires_at timestamptz
);
create table public.wallet_lot_consumptions (id …, lot_id …, transaction_id …, amount …);
```

Backfill is a **replay, not a migration** (L2): walk each wallet's ledger in `seq` order, open a lot per credit,
consume FIFO on each debit. Deterministic because `seq` is gapless and unique. That is the entire reason `seq`
exists beyond tamper detection, and it is why V1 does not need a `lot_id` column on the ledger.

### 3A.4 Promotional campaigns — blueprint

```sql
create table public.wallet_campaigns (        -- NOT BUILT IN V1
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references public.offices(id) on delete restrict,
  name text not null, budget numeric(12,2), spent numeric(12,2) not null default 0,
  starts_at timestamptz, ends_at timestamptz, rules jsonb not null default '{}'::jsonb,
  status text not null default 'draft'
);
alter table public.wallet_transactions
  add column campaign_id uuid references public.wallet_campaigns(id) on delete restrict;
```

A campaign award is `kind = cashback, category = promotion, campaign_id = …` — no new kind (L3). Budget
enforcement reuses the existing lock-then-validate order: the campaign row is locked alongside the wallet, and
`spent + amount <= budget` is checked *after* both locks are held. Until then, `metadata` carries a free-text
campaign label with no integrity guarantee, which is honest about what it is.

### 3A.5 External payment providers — blueprint, and a rejected shortcut

**Rejected:** adding `provider` / `provider_ref` columns to `wallet_transactions`. It looks cheap and violates
L5 — every new PSP would then touch the ledger, and provider-specific state (callback status, HMAC verification,
retry counts, raw payloads) has no home there.

**Accepted:** a top-up creates an instrument row shaped exactly like the `booking_payments` the schema already
has, and *its settlement* posts the ledger entry:

```sql
create table public.wallet_topups (           -- NOT BUILT IN V1
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id) on delete restrict,
  office_id uuid not null references public.offices(id) on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  provider text not null,                       -- paymob | fawry | …
  gateway_order_id text, gateway_transaction_id text, gateway_response jsonb,
  status text not null default 'pending',
  wallet_transaction_id uuid references public.wallet_transactions(id) on delete restrict
);
alter table public.wallet_transactions add column topup_id uuid references public.wallet_topups(id);
```

`kind = wallet_topup` is already in the CHECK. Adding Fawry, Stripe or a bank rail then touches one edge table
and `office_payment_configs` — never the ledger, never the balance logic. Provider refunds work the same way
through `refund_requests.external_transaction_id`, which already exists (§3.3).

### 3A.6 Wallet-to-wallet transfers and platform commission — blueprint

A transfer is **two ledger rows in one transaction** — a debit on one wallet, a credit on another — sharing a
`transfer_group_id uuid` (additive column) and locking wallets in ascending id order. Net effect across the
system is zero, so no new accounting treatment is needed.

Commission and captain payouts need a non-client wallet, which is exactly what §2.8's `owner_type` unlocks:
widen the CHECK, add the owner FK and its partial unique index. The ledger, the RPCs, the RLS shape and the
reconciliation query are all already owner-agnostic.

### 3A.7 Split payments — where the real limit is, and it is not in the wallet

| Split shape | Status |
|---|---|
| Wallet + one external method | ✅ works today: ledger holds the wallet leg, `booking_payments` the external one, `operation_bookings.payment_amount` stays the fare (§2.7) |
| Wallet + wallet (two wallets on one booking) | ✅ additive: two `wallet_spend` rows on the same `booking_id` |
| **Two or more external methods on one booking** | ❌ blocked by `booking_payments_booking_id_key UNIQUE (booking_id)` — verified live |

The last one is a **pre-existing constraint in the payments module, not in the wallet**, and it is called out
here so it is not discovered mid-V2. Lifting it means dropping that unique index and adding an invariant that
`Σ booking_payments.amount + Σ wallet legs = operation_bookings.payment_amount`. That work belongs to the
payments module and is deliberately not bundled into this one — but the wallet design does not stand in its way,
because the wallet leg was kept out of `booking_payments` precisely so the two can evolve independently.

### 3A.8 Application-layer naming

The same principle applies above the database, where a rename is far more expensive than an `ALTER`:

- Module folder `lib/apps/dashboard/features/wallet/` — not `customer_wallets/`.
- Entities `Wallet`, `WalletTransaction`, `WalletOwner`, `WalletPolicy` — not `CustomerWallet`.
- Repository and use cases key on **`walletId`**, taking `clientId` only at the directory/lookup boundary.
- The Arabic UI label stays **محفظة العملاء**, because in V1 every wallet does belong to a customer. The user-facing
  name is a product decision; the code name is an architectural one, and they are allowed to differ.

---

## Part 4 — RPC design

All `SECURITY DEFINER … set search_path = public`, `revoke all from public, anon`, `grant execute to authenticated`.

| RPC | Caller | Purpose |
|---|---|---|
| `office_wallet_summary(p_client_id)` | view | balance, lifetime totals, per-kind totals, pending refunds, recent entries |
| `office_wallet_directory(p_search, p_limit, p_offset)` | view | customers of this office with balances and last activity |
| `office_wallet_ledger(p_filters jsonb, p_limit, p_offset)` | view | office-wide transaction search (§8.3) |
| `office_refund_create(p_booking_id, p_amount, p_category, p_reason, p_notes, p_settlement_method, p_request_key)` | agent + owner | files a refund request; **auto-approves and settles when the caller is the owner** |
| `office_refund_decide(p_refund_id, p_decision, p_approved_amount, p_settlement_method, p_reason, p_request_key)` | owner | approve → settle, or reject |
| `office_refund_trip_batch(p_trip_id, p_category, p_reason, p_settlement_method, p_request_key)` | owner | one refund per confirmed booking on a cancelled trip (§10.4) |
| `office_wallet_cashback(p_client_id, p_amount, p_category, p_reason, p_notes, p_request_key)` | owner | promotional credit |
| `office_wallet_credit(p_client_id, p_amount, p_category, p_reason, p_notes, p_request_key)` | owner | manual credit |
| `office_wallet_debit(p_client_id, p_amount, p_category, p_reason, p_notes, p_request_key)` | owner | manual debit |
| `office_wallet_reverse(p_transaction_id, p_reason, p_request_key)` | owner | posts the inverse entry, marks the original `reversed` |
| `office_wallet_set_status(p_client_id, p_status, p_reason)` | owner | freeze / unfreeze |
| `office_wallet_verify_chain(p_client_id)` | owner | recompute seq + hash chain, report the first divergence |

Every write funnels through one private `wallet_post_entry(...)`, itself
`revoke all from public, anon, authenticated` so it can never be called directly and bypass the per-kind guards.
Its order is load-bearing:

```
 1. v_office := current_office_id()                        → not_an_office_user
 2. capability check via office_can(...)                   → not_authorized            (§6)
 3. self-dealing check: performed_by <> client's auth uid  → self_adjustment_denied    (§13.1)
 4. customer eligibility (clients_office_read predicate)   → client_not_in_office
 5. amount = round(p_amount,2); > 0; ≤ policy single cap   → invalid_amount / amount_exceeds_policy
 6. reason non-blank; category valid for kind              → reason_required / invalid_category
 7. idempotency: (office_id, request_key) lookup
       ├─ hit + same fingerprint → return original, no second entry, no second notification
       └─ hit + different fingerprint → request_key_conflict                            (§13.3)
 8. SELECT … FOR UPDATE the wallet row (created on first use, inside this transaction)
 9. post-lock validation — everything that could race is read HERE, never before:
       • cumulative refunds for the booking   → refund_exceeds_payment
       • operator velocity + daily promo cap  → adjustment_rate_limited / daily_cap_exceeded
       • frozen wallet, for debits and spends → wallet_frozen
       • available_balance ≥ |amount|, debits  → insufficient_wallet_balance
10. seq := last_seq + 1; prev_hash := head_hash; entry_hash := sha256(...)
11. INSERT the ledger row  (table CHECKs enforce the arithmetic)
12. UPDATE the wallet cache: balance, lifetimes, entry_count, last_seq, head_hash
13. push_notification(client) + push_operational_alert(office)
```

Step 9 is the concurrency contract: **no value used in a validation decision is read before the lock is held.**
Revision 1 left this implicit; two admins refunding the same booking simultaneously would each have validated
against a stale cumulative total.

---

## Part 5 — Business rules

### 5.1 Amounts

- Positive, `round(…, 2)`, EGP only. Zero and negative inputs rejected — direction comes from `kind`, never sign.
- Per-transaction cap from `office_wallet_policies`; per-operator daily promotional cap; per-operator hourly
  operation count.
- Refund cap: `approved_amount ≤ booking_payments.amount − Σ settled refunds for that booking`.

### 5.2 Categories per kind

| Kind | Categories |
|---|---|
| `refund` | `trip_cancelled`, `booking_cancelled`, `driver_unavailable`, `office_error`, `duplicate_payment`, `service_failure`, `other` |
| `cashback` | `promotion`, `loyalty`, `compensation`, `retention`, `marketing_campaign`, `referral` |
| `manual_credit` | `support_adjustment`, `goodwill`, `migration`, `correction` |
| `manual_debit` | `correction`, `wrong_cashback`, `accounting_adjustment`, `clawback` |
| `reversal` | `operator_error`, `fraud`, `duplicate`, `dispute` |
| `wallet_spend` / `wallet_topup` | V2 |

Validated in SQL against a per-kind allowlist, so reporting can group on it without cleaning free text.

### 5.3 Reversal

- Reverses exactly one `posted` entry; the original flips to `reversed` (the single permitted mutation, §12.2).
- Reversing a `reversal` is refused (`cannot_reverse_reversal`); an already-reversed entry is refused
  (`already_reversed`).
- If the credit was already spent and the balance is insufficient, the reversal is **refused**, not forced
  negative. The operator debits what remains and records the difference as an out-of-band receivable.
- A reversal of a settled refund also moves the refund record to `cancelled` and unlocks the booking's refund
  capacity.

### 5.4 Wallet status

`frozen` blocks `manual_debit` and `wallet_spend`; credits and refunds still post. Freeze and unfreeze both
require a reason and both raise an operational alert.

---

## Part 6 — Permission model

Three dashboard permissions, not eight. Eight capability flags across a two-role system is administration
theatre; the *server* keeps the fine-grained capability list so more roles can be added later without touching
call sites.

```dart
enum DashboardPermission {
  …
  customerWallets,     // see customers, balances, ledger
  walletAdjustments,   // move money
  walletApprovals,     // decide refund requests, reverse, freeze, set policy
}
```

| Capability | المالك `dashboard_admin` | خدمة العملاء `support_agent` |
|---|---|---|
| View wallet + full history | ✅ | ✅ |
| Office-wide ledger + metrics | ✅ | ✅ |
| Raise a refund **request** | ✅ | ✅ |
| Approve / settle a refund | ✅ | ❌ |
| Cashback / credit / debit | ✅ | ❌ |
| Reverse a transaction | ✅ | ❌ |
| Freeze a wallet | ✅ | ❌ |
| Edit wallet policy | ✅ | ❌ |
| **Export history** | ✅ | ❌ |

Two deliberate calls:

- **Support agents see everything and move nothing.** They are the ones who hear "where is my money", so
  denying visibility just makes them guess. Their escalation path already exists — `refund_requests` has an
  alert trigger and a client notification.
- **Export is owner-only.** A full customer financial history in a spreadsheet is a data-exfiltration surface,
  and it is the one read that leaves the audited system.

Server-side, every RPC calls `public.office_can(p_capability text)` — today a `switch` on `office_role()`. When
a third role (finance manager, branch supervisor) arrives, it changes in one function, not in twelve RPCs. The
Dart permission set is UX; `office_can` is the security boundary.

---

## Part 7 — Accounting model

### 7.1 Three statements

```
REVENUE   = Σ payment_amount of bookings in ('confirmed','boarded','completed')
          − Σ approved_amount of settled refunds                       (any destination)

CASH      = Σ booking_payments.amount where status='approved'          (external tender only)
          − Σ approved_amount of settled refunds where settlement_method <> 'wallet'

LIABILITY = Σ wallets.balance
          = Σ (refunds_to_wallet + cashback + manual_credit + topups)
          − Σ (wallet_spend + manual_debit)  ± reversals
```

**PROMOTIONAL COST** = Σ (`cashback` + `manual_credit`) is reported separately. It is a marketing/compensation
expense that creates a liability with no cash received — subtracting it from revenue would understate what the
office actually sold. Owner-facing:

```
صافي الإيراد          = REVENUE
مساهمة بعد الحوافز    = REVENUE − PROMOTIONAL COST
النقدية المحصّلة       = CASH
التزامات المحفظة       = LIABILITY
```

### 7.2 The control identity

```
CASH_in − CASH_out  =  REVENUE − PROMOTIONAL_COST + (LIABILITY_end − LIABILITY_start)
```

Finance asserts this on every load. If it does not balance to the piastre, something is broken and the module
says so rather than displaying a plausible wrong number.

| Scenario | Cash | Revenue | Promo | ΔL | Identity |
|---|---|---|---|---|---|
| Book 300 cash | 300 | 300 | 0 | 0 | 300 = 300 ✓ |
| …refunded 300 to wallet | 300 | 0 | 0 | +300 | 300 = 0 + 300 ✓ |
| …customer rebooks with wallet | 300 | 300 | 0 | 0 | 300 = 300 ✓ |
| …refunded 300 to InstaPay instead | 0 | 0 | 0 | 0 | 0 = 0 ✓ |
| Cashback 100, unspent | 0 | 0 | 100 | +100 | 0 = −100 + 100 ✓ |
| Cashback 100, spent on a 100 ride | 0 | 100 | 100 | 0 | 0 = 0 ✓ |

Row 3 is the case revision 1 got wrong: it reported 0 where the office earned 300.

### 7.3 Impact on the Finance module

Finance **stays read-only** — the 2026-08-01 boundary is not reopened. What changes:

- `FinanceAnalytics.from(...)` computes the three statements instead of one, and asserts §7.2.
- Two new reads: settled refunds from `refund_requests`, balances from `wallets`.
- Revenue keys on **booking status + fare** rather than `payment_status`; equivalent today (both are set by
  `approve_payment`), and correct once wallet tender exists.
- New KPIs: النقدية المحصّلة, التزامات المحفظة, تكلفة الحوافز.
- `finance_analytics_test.dart` gains the six §7.2 scenarios as cases.

---

## Part 8 — Dashboard UX structure

### 8.1 V1 scope — one module, four surfaces

`lib/apps/dashboard/features/wallet/` (§3A.8), route `/wallet`, label **محفظة العملاء** in the
**المالية** nav group.

| Surface | Why V1 |
|---|---|
| **1. Customer Wallet Directory** | There is no customer entity in the dashboard at all (§1.1). Everything else needs it. |
| **2. Wallet Detail** | The working screen — balance, history, actions. |
| **3. Financial Activity** (office-wide ledger) | Search, filters, metrics, export. Answers "what did my staff do this week". |
| **4. Refund Requests queue** | Gives the orphaned approval step a home and makes the agent→owner pipeline real. |

**Deferred, with reasons:**
- *Cashback campaigns* — a budgeting and targeting system, not a wallet feature. Belongs after V1 proves manual
  cashback is actually used (§11).
- *Reports* — Finance already owns reporting and now reads wallet data (§7.3). A second reporting surface is how
  two numbers start disagreeing.
- *Standalone Manual Adjustments page* — **rejected outright, not deferred.** Money movement must always start
  from a named customer. A context-free "adjust a balance" form is precisely the control weakness this module
  exists to remove.

### 8.2 Wallet Detail — what belongs on it

```
┌ DashboardModuleHeader · محفظة العملاء ───────────────────────────────────────┐
│ [الأرصدة القائمة 12,450] [كاش باك 3,200] [مرتجعات 8,100] [تسويات 640]        │
│ [طلبات معلّقة 3]                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
┌ العملاء ─────────────┐ ┌ أحمد محمود · 0100… · عميل منذ مارس 2026 ───────────┐
│ 🔍 بحث اسم/هاتف      │ │ ╔═══════════════════════════════════════════════╗  │
│ ● أحمد محمود  250.00 │ │ ║  الرصيد الحالي        250.00 ج.م              ║  │
│ ○ سارة علي      0.00 │ │ ║  آخر حركة: أمس · 12 عملية · محفظة نشطة        ║  │
│ ○ محمد حسن     75.50 │ │ ╚═══════════════════════════════════════════════╝  │
│                      │ │ [استرداد] [كاش باك] [إضافة رصيد] [خصم]  ⋯[تجميد]  │
│                      │ │ ┌ مرتجعات ┐┌ كاش باك ┐┌ إضافات ┐┌ خصومات ┐┌مصروف┐│
│                      │ │ │  200.00 ││  100.00 ││   0.00 ││  50.00 ││ 0.00││
│                      │ │ └─────────┘└─────────┘└────────┘└────────┘└─────┘│
│                      │ │ ⚠ طلب استرداد معلّق · 120.00 · حجز #1042 [مراجعة] │
│                      │ │ ── سجل الحركات (غير قابل للتعديل) ───────────────  │
│                      │ │ #12  05 أغس  استرداد  +200.00 → 250.00  حجز #1042 │
│                      │ │ #11  01 أغس  كاش باك  +100.00 →  50.00  تعويض     │
│                      │ │ #10  28 يول  خصم       −50.00 → −50.00  تصحيح ↩︎  │
└──────────────────────┘ └────────────────────────────────────────────────────┘
```

Design rules behind that layout:

- **Balance is the single largest element.** It is the one number every conversation starts from.
- **Lifetime totals are a strip, not cards.** They are context, not the headline; five KPI cards would compete
  with the balance.
- **Pending refunds surface inline as a banner**, not in a separate tab — an operator must not be able to issue
  a second refund while unaware one is already waiting. This is a control, not a convenience.
- **Every row shows the running balance and its sequence number.** The customer's question is never "what was
  the amount", it is "why is my balance this". A ledger without the running total does not answer it.
- **Reversed entries stay visible**, struck through with a link to the reversing entry. Nothing disappears.
- Support agents see the same screen with the four action buttons replaced by one **طلب استرداد**.

### 8.3 Filters — Financial Activity

| Filter | Note |
|---|---|
| Customer (name / phone) | debounced |
| Transaction type | `kind`, multi-select |
| **Category** | the "why" axis — the filter operators will actually reach for |
| Status | posted / reversed |
| Date range | preset chips + custom |
| Amount range | min / max |
| Office user | who performed it — the self-audit filter |
| Booking / trip | booking number or trip code |
| Direction | credit / debit |
| **Source** | dashboard / client / system / migration |
| **Has reversal** | isolates corrected entries — the first thing anyone investigating a discrepancy wants |

The last three are additions beyond the brief; each answers a question an operator will otherwise ask by
scrolling.

---

## Part 9–11 — Workflows

### 9. Refund workflow — one pipeline, two entry points

The brief asks whether a mandatory Support Agent → Request → Owner Approval chain is safer. **Yes for the
record, no for the ceremony.** The recommendation:

> **Every refund is a `refund_requests` row. The owner's own refund is born approved and settles in the same
> transaction; a support agent's is born pending.**

```
   support agent                          owner
        │                                   │
   office_refund_create              office_refund_create
   status = pending                  status = settled  (auto-approved, one click)
        │                                   │
        ├──▶ operational alert ──▶ Refund Requests queue
        │                                   │
        └──────▶ office_refund_decide ──────┘
                          │
                 approve → post ledger entry (if settlement = wallet)
                         → booking_payments.status = 'refunded' when fully refunded
                         → client notification
                 reject  → status = rejected, reason recorded, client notified
```

Why not force the owner through two steps: with as few as one owner per office, mandatory second-person
approval either deadlocks or gets worked around by sharing a login — which destroys the audit trail the control
was meant to create. Instead, high-value owner refunds get **step-up confirmation** (re-type the amount) and
`require_second_approval_above` exists in policy for offices that have two owners and want it. Genuine
maker–checker is offered where it is possible, not mandated where it is not.

Uniform record, uniform audit, one queue, one place Finance reads.

### 9.2 Settlement methods

`wallet` (default, no cash leaves), `original_method` (Paymob reversal — records
`external_transaction_id`), `cash`, `bank_transfer`. Only `wallet` posts a ledger entry; all four produce a
refund record and reduce REVENUE (§7.1). Guest bookings (F6) cannot use `wallet` — the RPC refuses it and the
UI hides the option.

### 9.3 Partial refunds

Many refund rows per booking, cumulative cap enforced under the wallet lock. `booking_payments.status` flips to
`refunded` only when cumulative equals the payment; partial refunds leave it `approved`, and REVENUE is correct
either way because it subtracts refund *amounts*, not statuses.

### 9.4 Trip cancellation batch — the missing rule

Cancelling a trip is the single most common refund cause, and a 14-seat bus means 14 refunds. `office_refund_trip_batch`
creates one refund row per confirmed booking in one transaction under one request key, locking wallets in
ascending id order to avoid deadlock, and stamps them all with `trip_cancellation_batch_id` so the operator can
see, verify and if necessary reverse the batch as a unit. Without this the feature is unusable on the day it
matters most.

### 10. Cashback workflow — V1 scope

**In V1:** manual cashback to one customer, with a category, amount, mandatory reason, optional notes, subject
to per-transaction and per-operator daily caps. Referral payouts post as `category = referral` from `source =
system` when the referral engine is switched on (F5) — no second reward mechanism.

**Not in V1, with reasons:**
- *Campaigns* (audience rules, budget, start/end) — a targeting and budgeting system in its own right. Build it
  once manual cashback has shown what offices actually award.
- *Expiration* — needs FIFO lot accounting to know which pounds expired, plus a scheduler. **`pg_cron` is not
  installed** (F3). Deferring is a technical fact, not a preference. The V1 ledger needs no change to support
  it later (§2.1).
- *Marketing budgets* — meaningful only alongside campaigns.

V1 does **not** show an expiry field. A date the system does not enforce is worse than no date.

### 11. Manual adjustment workflow — required controls

| Control | Credit / Cashback | Debit |
|---|---|---|
| Mandatory category | ✅ | ✅ |
| Mandatory free-text reason | ✅ | ✅ |
| Notes | optional | optional |
| Amount cap (policy) | ✅ | ✅ |
| Operator daily cap | ✅ | — |
| Double confirmation | — | ✅ restate customer, amount, resulting balance |
| Step-up (re-type amount) | above policy threshold | above policy threshold |
| Owner-only | ✅ | ✅ |
| Operational alert to office | ✅ | ✅ |
| Customer notification | ✅ | ✅ |
| Reversible | ✅ | ✅ |

Debits get the heavier treatment because they take money away from a customer who is not in the room. The
confirmation restates it in words:

> سيتم خصم 50.00 ج.م من رصيد أحمد محمود. الرصيد بعد الخصم: 25.50 ج.م.
> لا يمكن التراجع عن هذه العملية إلا بعملية عكسية مسجّلة في السجل.

---

## Part 12 — Security model

1. **RLS**: `SELECT`-only policies on both wallet tables, office- and self-scoped. No write policy exists, so
   RLS alone denies every mutation from every client.
2. **Grants**: `revoke insert, update, delete, truncate … from anon, authenticated`. TRUNCATE is never filtered
   by RLS.
3. **Immutability trigger**: `BEFORE UPDATE OR DELETE` raising `wallet_ledger_immutable`, permitting exactly one
   transition — `status: posted → reversed` — and nothing else. It binds the table owner too, so a future
   SECURITY DEFINER function that gets it wrong still fails.
4. **RPC-only writes**: every mutating function is SECURITY DEFINER with `search_path = public`; the shared
   `wallet_post_entry` is revoked from `authenticated` so the per-kind guards cannot be bypassed.
5. **Authorisation**: `office_can(...)` inside every RPC, independent of the Dart permission set.
6. **Cross-office**: `assert_office_owns_booking()` for refunds; the `clients_office_read` predicate for
   customer eligibility; `office_id` written from `current_office_id()` server-side and never accepted as a
   parameter.
7. **Tamper evidence**: per-wallet `seq` + sha256 chain (§2.5), verifiable by `office_wallet_verify_chain`, with
   the head hash included in every export.
8. **Context capture**: `client_ip` and `user_agent` from `request.headers` when present. Recorded as
   **advisory** — they are client-supplied and absent on direct connections (F7). They help investigations; they
   are not evidence, and no control depends on them.

---

## Part 13 — Fraud prevention

| Vector | Control |
|---|---|
| **Self-dealing** — an operator crediting their own customer account | Hard block: `performed_by = client's auth uid` → `self_adjustment_denied`. Plus a report flagging adjustments where the customer's phone matches an office user's (surfaced, not blocked — families exist). |
| **Duplicate refund** | Cumulative cap per booking, read **after** the wallet lock. Two concurrent refunds serialise; the second sees the first's amount. |
| **Double cashback** | `(office_id, request_key)` unique index; key generated once per dialog open. |
| **Replay with a stale key** | `request_fingerprint = md5(kind‖client‖amount‖booking)`. Same key + different fingerprint → `request_key_conflict`, rather than silently returning an unrelated transaction and reporting success. |
| **Rapid repeated requests** | `max_operator_hourly_ops` and `max_operator_daily_promo` per operator, evaluated in the office timezone. |
| **Unauthorised adjustment** | `office_can` in-RPC; UI permissions are not the boundary. |
| **Race conditions** | `SELECT … FOR UPDATE` on the wallet row is the single serialisation point; all validation reads happen after it. Batch operations lock wallets in ascending id order. |
| **Balance drift** | `balance_after = balance_before + amount` as a table CHECK, `unique (wallet_id, seq)`, and a reconciliation query asserting `Σ amount = balance` per wallet — run in the regression suite and available from the UI. |
| **Silent history edit** | Immutability trigger + hash chain + off-database head export. |
| **Insider deletion** | `ON DELETE RESTRICT` on every FK into the ledger; sequence gaps make a deletion detectable even if a restriction were dropped. |

---

## Part 14 — Edge cases

| # | Case | Handling |
|---|---|---|
| 1 | **Customer hard-deleted** (F1) | `ON DELETE RESTRICT` on wallet, ledger and refund FKs. **Accepted consequence: deleting a Supabase auth user who holds wallet history will now fail.** That is correct — the supported path is `clients.status = 'archived'`, which the schema already has. Must be documented for whoever next deletes a test user. |
| 2 | **Office archived with outstanding liability** | `platform_set_office_status(…, 'archived')` refuses while `Σ balance > 0`; the platform admin sees the liability and must record a settlement decision first. Otherwise archiving silently strands customer money. |
| 3 | **Booking refunded twice** | Cumulative cap under lock → `refund_exceeds_payment`. |
| 4 | **Refund larger than payment** | Same check, at request time and again at settle time (the amount can be edited in between). |
| 5 | **Partial then partial again** | Supported by design; each is its own refund row, cap applies to the running sum. |
| 6 | **Two admins acting simultaneously** | Append-only ledger: both entries post, the balance is their sum, no lost update is possible. The UI re-reads the balance after each post. |
| 7 | **Network retry / double tap** | Idempotency key + fingerprint. The retry returns the original transaction and does **not** send a second notification. |
| 8 | **Reversing a spent credit** | Refused rather than forced negative; operator debits what remains and records the rest out of band. |
| 9 | **Double reversal** | `already_reversed` / `cannot_reverse_reversal`. |
| 10 | **Guest booking refund** (F6) | No `client_id` ⇒ no wallet. `settlement_method = 'wallet'` refused; UI hides the option and defaults to `cash`. |
| 11 | **Refund after the trip departed** | Allowed (service failure is a real category) but flagged in the ledger and in the operator report. |
| 12 | **Refund of a partly-wallet-paid booking** (V2) | Splits proportionally: wallet portion back to wallet, external portion by settlement method. Rule fixed now so V2 has no discretion. |
| 13 | **Wallet migration / historical import** | `kind = manual_credit, category = migration, source = migration, performed_by = null`, one batch request key. The `wtx_actor` CHECK permits a null actor only for `system`/`migration`. |
| 14 | **Day-boundary drift** | Daily caps use `office_wallet_policies.timezone` (Africa/Cairo), not the server's UTC or the operator's device clock. Finance's existing device-local day boundaries are a pre-existing issue, noted but not in scope. |
| 15 | **Client-app clock skew / stale balance** | The client screen is read-only; the balance always comes from the server, never computed locally. |
| 16 | **Chain divergence detected** | `office_wallet_verify_chain` reports the first divergent `seq`. The wallet is auto-frozen and an urgent operational alert is raised — a wallet whose history cannot be trusted must not keep transacting. |

---

## Part 15 — Migration strategy

**This is the cheapest possible moment to do this work.** `loyalty_accounts`: 0 rows. `refund_requests`: 0 rows.
`referrals`: 0 rows. There is no data to migrate and no backfill to write — every structural fix in §3.3 is free
today and expensive in six months.

| Step | Migration | Risk | Rollback |
|---|---|---|---|
| 1 | `..._wallet_core.sql` — tables, CHECKs, indexes, RLS, revokes, immutability trigger, `office_can`, `wallet_post_entry`, hash helpers | Additive only | `drop table` (nothing references them yet) |
| 2 | `..._refund_record.sql` — the §3.3 alters | **Non-additive**, but on an empty table | Column-level revert; verified by row count = 0 immediately before |
| 3 | `..._wallet_rpcs.sql` — the twelve RPCs + grants | Additive | `drop function` |
| 4 | `..._wallet_policies.sql` — policy table + per-office defaults for the 3 existing offices | Additive | `drop table` |
| 5 | Retire the dead path — `comment on column loyalty_accounts.wallet_balance`, delete `redeemWalletBalance()` | App-side | git revert |

Each step is dry-run against the linked database (`begin … rollback`) before apply, per the single-database
rule. `loyalty_accounts.wallet_balance` is **not dropped** — it is commented as superseded; dropping it belongs
with the wider loyalty cleanup, not with a money feature.

### 15.1 Forward migration cost of each future capability

The point of Part 3A is that this table stays cheap. Every row was checked against the §3 schema:

| Capability | Migration required | Data migration | App refactor |
|---|---|---|---|
| Wallet payments at checkout (V2) | none | none | client wizard only |
| Wallet + external split tender | none | none | none |
| Reserved balances / holds | `wallet_holds` + relax one CHECK | none | none — debits already read `available_balance` |
| Credit lots + cashback expiry | 2 tables | **replay** from `seq`, not a migration | none |
| Promotional campaigns | 1 table + 1 nullable FK | none | campaign UI only |
| External providers / top-ups | 1 edge table + 1 nullable FK | none | none in the ledger |
| Wallet-to-wallet transfer | 1 nullable column | none | none |
| Driver / office / platform wallets | widen 1 CHECK, drop 1 `NOT NULL`, add 1 FK + index | none | **none** (§2.8) |
| Two+ external methods on one booking | drop `booking_payments_booking_id_key` | none | payments module — **outside the wallet** (§3A.7) |

Every row above is additive except the last, which lives in the payments module and is unblocked rather than
caused by this design.

---

## Part 16 — Phased implementation plan

| Phase | Content | Gate |
|---|---|---|
| **0** | Migrations 1–4 (§15) | Dry-run clean; `flutter analyze` untouched |
| **1** | `supabase/tests/wallet_authority_regression.sql` — cross-office read/write blocked; ledger UPDATE/DELETE/TRUNCATE blocked; support-agent adjustment blocked; over-refund blocked; debit below zero blocked; frozen-wallet debit blocked; self-adjustment blocked; duplicate key returns the original and posts nothing; conflicting fingerprint rejected; `Σ ledger = balance`; hash chain verifies | Every row reads OK or "blocked" |
| **2** | Dashboard module — data → domain → presentation, `wallet_di.dart`, route + nav + permissions. Surfaces 1 & 2 (§8.1) | Widget + cubit tests green |
| **3** | Surfaces 3 & 4 — Financial Activity ledger with filters and export, Refund Requests queue | Support agent sees no adjustment control |
| **4** | Finance alignment (§7.3) — three statements, control identity, new KPIs, six scenario tests | `finance_analytics_test.dart` green, Finance still read-only |
| **5** | Trip-cancellation batch refund (§9.4) | Batch idempotency + deadlock-order test |
| **6** | Client app — read-only wallet screen, notification deep-link, deletion of `redeemWalletBalance()` | Client suite stays green |
| **V2** | Wallet spend at checkout — wallet leg in `confirm_seat_booking_v2`, activate `payment_methods.wallet_balance`, un-stub the wizard. **No wallet-schema change required** (§2.7) | — |

Tests: `wallet_arithmetic_test.dart` (pure Dart — caps, cumulative refunds, reversal maths, the §7.2 identity),
`wallet_cubit_test.dart`, `wallet_screen_test.dart`, `wallet_permission_test.dart`, plus the
Phase 1 SQL suite. The ~78 known pre-existing failures stay out of scope.

---

## Part 17 — Final recommendation

**Approve, with the seven changes in Part 0 folded in.** The revised design is materially different from
revision 1 in three ways that matter, and I would not want the original built:

1. **The accounting was wrong**, and provably so — it reported zero revenue for an office that earned 300 EGP.
   The three-statement model with a control identity replaces a rule someone has to remember with an equation
   the module checks on every load.
2. **Refunds were modelled as a wallet feature** when only some refunds touch the wallet. Making
   `refund_requests` the authoritative record for all of them fixes the reporting gap, gives partial refunds a
   home, and unifies the agent and owner paths into one auditable pipeline.
3. **Financial history is currently deletable** through a cascade nobody intended. That is worth fixing on its
   own merits, and it must be fixed before a ledger is attached to those tables.

The remaining changes — three axes instead of one enum, sequence and hash chaining, batch trip refunds, and the
fraud controls — are what separate a feature that works from one that is still trustworthy in three years.

What I am **not** recommending, deliberately: campaigns, expiry, multi-currency, credit lots, holds, wallet
top-ups, transfers, double-entry bookkeeping with debit/credit accounts, or a general-purpose adjustments page.
Each is defensible in a larger business; each would add surface this platform cannot yet fill. **All of them
remain additive** — §15.1 prices each one, and the only non-additive item on that list sits in the payments
module and is unblocked, not caused, by this design.

The revision-3 pass added exactly two things to V1: one discriminator column (`owner_type`) and one
CHECK-pinned column pair (`reserved_balance` / `available_balance`). Both are inert — no UI, no writer, no
maintenance — and both remove a future *refactor* rather than a future *migration*, which is the distinction
worth paying for in advance. The rest of Part 3A is written-down intent, and written-down intent costs nothing
but is the only thing that stops the next person from implementing holds as ledger entries and quietly breaking
`Σ ledger = balance`.

Two decisions are yours and are not technical:

- **Refund approval ceremony.** I recommend owner refunds settle in one step with step-up confirmation, because
  mandatory second-person approval in a one-owner office gets solved by sharing a login. If your offices have
  two owners and you want hard maker–checker, `require_second_approval_above` is already in the policy table.
- **Support-agent visibility.** I recommend they see all balances and history but move nothing. The alternative
  — hiding balances from the people who answer the phone — is defensible only if you have had a leak.
