-- ═══════════════════════════════════════════════════════════════════════════════════
-- Wallet & Financial Adjustments — Step 2/4: the ledger core
--
-- Design: docs/dashboard/DASHBOARD_CUSTOMER_WALLET.md §2, §3.1, §3.2, §3.5, §3A, §12.
--
-- What this establishes:
--
--   1. wallets              — one balance per (office, customer), non-negative,
--                             owner-generic in shape and client-pinned by CHECK.
--   2. wallet_transactions  — the append-only ledger: sequenced, hash-chained,
--                             arithmetically self-checking, referentially typed.
--   3. Two guard triggers   — the ledger is immutable (one permitted transition),
--                             and a balance cannot move without a ledger row.
--   4. wallet_post_entry    — the ONLY writer. Revoked from every client role, so
--                             the per-kind guards in step 4's RPCs cannot be
--                             bypassed by calling the shared writer directly.
--
-- ── The five laws this file enforces (§3A.1) ────────────────────────────────────
--
--   L1  The ledger records settled value movement only  →  Σ amount = balance, always.
--   L2  Balance is derived; `seq` makes history replayable.
--   L3  `kind` is closed (CHECK), `category` is open (allowlist function).
--   L4  Money never moves without a ledger row          →  wallet_balance_guard().
--   L5  External systems integrate at the edge          →  no provider columns here.
--
-- ── What is achievable, stated honestly (§2.5) ──────────────────────────────────
--
-- RLS, revocations and triggers stop application-level tampering. Nothing inside
-- Postgres stops a database owner. What closes that gap is making tampering
-- *detectable*: a gapless per-wallet sequence plus a sha256 chain, so a deleted
-- row leaves a hole and an edited row invalidates every hash after it.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. Capability boundary
-- ═══════════════════════════════════════════════════════════════════════════════════

-- The server's own answer to "may this operator do this?", independent of the
-- Dart permission set (which is UX). Every wallet RPC calls it.
--
-- It is a switch on office_role() rather than a table because the dashboard has
-- exactly two roles. When a third arrives (finance manager, branch supervisor),
-- it changes here — in one function — instead of in twelve RPCs.
create or replace function public.office_can(p_capability text)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select case public.office_role()
    when 'dashboard_admin' then p_capability in (
      'wallet_view',        -- see customers, balances, ledger
      'wallet_ledger_view', -- office-wide financial activity
      'wallet_export',      -- the one read that leaves the audited system
      'refund_request',     -- file a refund request
      'refund_decide',      -- approve / reject / settle
      'wallet_adjust',      -- cashback, manual credit, manual debit
      'wallet_reverse',
      'wallet_freeze',
      'wallet_policy_edit')
    -- Support agents see everything and move nothing (§6). They are the ones who
    -- hear "where is my money", so denying visibility just makes them guess.
    when 'support_agent' then p_capability in (
      'wallet_view',
      'wallet_ledger_view',
      'refund_request')
    else false
  end;
$$;

comment on function public.office_can(text) is
  'Server-side capability check for the wallet module. The Dart permission set is UX; this is the boundary.';


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. wallets (§3.1)
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.wallets (
  id                uuid primary key default gen_random_uuid(),
  office_id         uuid not null references public.offices(id) on delete restrict,

  -- Owner. V1 emits only 'client'. The discriminator exists so that driver,
  -- office and platform wallets later become "widen the CHECK, add an FK" rather
  -- than "rename client_wallets → wallets across twelve RPCs and the whole app
  -- layer" (§2.8). The column is inert: no UI, no writer, no maintenance.
  owner_type        text not null default 'client' check (owner_type = 'client'),
  client_id         uuid not null references public.clients(id) on delete restrict,

  -- Non-negative by CHECK, re-argued in §2.6: this platform has no instrument to
  -- collect a debt, so a negative balance would be a number that can never be
  -- resolved. It also removes a bug class — "the balance is wrong" becomes
  -- *always* a ledger failure, never an intended state.
  balance           numeric(12,2) not null default 0 check (balance >= 0),

  -- Value committed to a pending operation but not yet spent. CHECK-pinned to 0
  -- in V1; relaxing that CHECK is the single act that enables holds (§3A.2).
  -- Every debit validates against available_balance from day one, so enabling
  -- holds changes no posting logic.
  reserved_balance  numeric(12,2) not null default 0 check (reserved_balance = 0),
  available_balance numeric(12,2) generated always as (balance - reserved_balance) stored,

  currency          text not null default 'EGP' check (currency = 'EGP'),

  -- Cached aggregates. Derived, never authoritative: §13's reconciliation query
  -- asserts them against Σ amount, and wallet_balance_guard() makes
  -- wallet_post_entry the only thing that may move them.
  lifetime_credited numeric(12,2) not null default 0 check (lifetime_credited >= 0),
  lifetime_debited  numeric(12,2) not null default 0 check (lifetime_debited  >= 0),
  entry_count       bigint not null default 0 check (entry_count >= 0),
  last_seq          bigint not null default 0 check (last_seq >= 0),
  head_hash         bytea,

  -- A frozen wallet still accepts credits — you must always be able to refund
  -- someone — but refuses debits and spends. Freezing is a fraud hold, not a
  -- punishment (§5.4).
  status            text not null default 'active' check (status in ('active','frozen')),
  frozen_reason     text,
  frozen_by         uuid references auth.users(id) on delete restrict,
  frozen_at         timestamptz,

  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  constraint wallet_reserved_le_balance check (reserved_balance <= balance),
  constraint wallet_frozen_has_reason
    check (status <> 'frozen'
           or nullif(btrim(coalesce(frozen_reason,'')),'') is not null)
);

-- Partial, so a driver/office wallet can later get its own unique index without
-- touching this one.
create unique index if not exists uniq_wallet_client
  on public.wallets (office_id, client_id) where owner_type = 'client';

create index if not exists idx_wallets_office_balance
  on public.wallets (office_id, balance desc);

comment on table public.wallets is
  'Customer credit balance, one per (office, customer). Value collected by one office is not spendable at another — there is no inter-office clearing mechanism and building one is a different product (§2.1).';


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. wallet_transactions (§3.2)
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.wallet_transactions (
  id             uuid primary key default gen_random_uuid(),

  -- wallet_id is the ONLY structural link to the owner. client_id below is a
  -- denormalised copy kept solely so the client self-read policy needs no join;
  -- a future non-client wallet simply leaves it null and never matches it.
  wallet_id      uuid not null references public.wallets(id) on delete restrict,
  office_id      uuid not null references public.offices(id) on delete restrict,
  client_id      uuid          references public.clients(id) on delete restrict,

  -- Per-wallet, gapless, assigned under the wallet row lock. A deleted row
  -- leaves a gap; a forged row collides. Ordering becomes deterministic, which
  -- created_at alone never is under concurrency (§2.5).
  seq            bigint not null check (seq > 0),

  -- Three axes, not one enum (§2.4):
  --   kind     — what happened to the balance. CLOSED; the accounting depends on it.
  --   category — why. OPEN; the business adds reasons forever.
  --   source   — who drove it. Closed, small.
  -- wallet_spend and wallet_topup are in the CHECK on day one although V1 never
  -- emits them: a reserved enum value has no UI surface and makes no promise to
  -- anyone, and it removes a constraint migration from V2's path.
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

  -- Typed references, deliberately NOT (reference_type, reference_id): a
  -- ledger's value is referential integrity, and a polymorphic pair cannot carry
  -- a foreign key. ON DELETE RESTRICT throughout — financial history is not
  -- deletable through a cascade (F1).
  booking_id              uuid references public.operation_bookings(id)  on delete restrict,
  refund_id               uuid references public.refund_requests(id)     on delete restrict,
  subscription_id         uuid references public.subscriptions(id)       on delete restrict,
  referral_id             uuid references public.referrals(id)           on delete restrict,
  reverses_transaction_id uuid references public.wallet_transactions(id) on delete restrict,
  metadata                jsonb not null default '{}'::jsonb,

  performed_by      uuid references auth.users(id) on delete restrict,  -- null ⇒ system/migration
  performed_by_name text not null,
  performed_by_role text,

  -- Idempotency, and the evidence that a retry is a retry rather than a second
  -- intention (§13).
  request_key         uuid not null,
  request_fingerprint text not null,

  -- Advisory only (F7): request.headers is client-supplied and absent on direct
  -- connections. These help an investigation; no control depends on them.
  client_ip           inet,
  user_agent          text,

  prev_hash  bytea,
  entry_hash bytea not null,
  created_at timestamptz not null default now(),

  -- An arithmetically wrong row cannot be inserted at all, regardless of which
  -- function computed it.
  constraint wtx_arithmetic check (balance_after = balance_before + amount),

  -- Direction comes from kind, never from a caller's sign. `reversal` is exempt
  -- because it mirrors whatever it reverses.
  constraint wtx_sign check (
        (kind in ('refund','cashback','manual_credit','wallet_topup') and amount > 0)
     or (kind in ('manual_debit','wallet_spend')                      and amount < 0)
     or (kind = 'reversal')),

  constraint wtx_reversal_link check ((kind = 'reversal') = (reverses_transaction_id is not null)),
  constraint wtx_refund_link   check (kind <> 'refund'       or refund_id  is not null),
  constraint wtx_spend_link    check (kind <> 'wallet_spend' or booking_id is not null),
  constraint wtx_actor         check (performed_by is not null or source in ('system','migration')),

  unique (wallet_id, seq),
  unique (office_id, request_key)
);

create index if not exists idx_wtx_wallet_seq     on public.wallet_transactions (wallet_id, seq desc);
create index if not exists idx_wtx_office_created on public.wallet_transactions (office_id, created_at desc);
create index if not exists idx_wtx_office_kind    on public.wallet_transactions (office_id, kind, created_at desc);
create index if not exists idx_wtx_booking        on public.wallet_transactions (booking_id) where booking_id is not null;
create index if not exists idx_wtx_refund         on public.wallet_transactions (refund_id)  where refund_id is not null;
create index if not exists idx_wtx_performer      on public.wallet_transactions (performed_by, created_at desc);
create index if not exists idx_wtx_client         on public.wallet_transactions (client_id, created_at desc);

comment on table public.wallet_transactions is
  'Append-only wallet ledger. Immutable except posted → reversed; sequenced and hash-chained per wallet so tampering is detectable, not merely blocked.';


-- Is this customer one of the calling office's? Mirrors the `clients_office_read`
-- RLS predicate, plus "we already hold a wallet for them" — a customer whose only
-- booking was later removed must not become unrefundable.
--
-- Defined here rather than beside office_can() because it reads `wallets`, and a
-- SQL-language function body is parsed at creation time.
create or replace function public.office_owns_client(p_client_id uuid, p_office_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select p_client_id is not null
     and p_office_id is not null
     and (exists (select 1 from public.operation_bookings b
                   where b.client_id = p_client_id and b.office_id = p_office_id)
       or exists (select 1 from public.subscriptions s
                   where s.client_id = p_client_id and s.office_id = p_office_id)
       or exists (select 1 from public.wallets w
                   where w.client_id = p_client_id and w.office_id = p_office_id));
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. The open axis: category allowlist per kind (§5.2, law L3)
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Validated in SQL rather than left as free text so reporting can group on it
-- without cleaning. A new business reason is one line here — no accounting
-- decision required. A new *balance effect* is a new `kind`, which is a CHECK
-- migration, and that friction is deliberate.
create or replace function public.wallet_category_allowed(p_kind text, p_category text)
returns boolean
language sql
immutable
as $$
  select case p_kind
    when 'refund' then p_category in
      ('trip_cancelled','booking_cancelled','driver_unavailable','office_error',
       'duplicate_payment','service_failure','other')
    when 'cashback' then p_category in
      ('promotion','loyalty','compensation','retention','marketing_campaign','referral')
    when 'manual_credit' then p_category in
      ('support_adjustment','goodwill','migration','correction')
    when 'manual_debit' then p_category in
      ('correction','wrong_cashback','accounting_adjustment','clawback')
    when 'reversal' then p_category in
      ('operator_error','fraud','duplicate','dispute')
    -- V2 kinds. Listed so the allowlist is complete on day one; nothing emits them.
    when 'wallet_spend' then p_category in ('booking','subscription')
    when 'wallet_topup' then p_category in ('gateway','cash','bank_transfer')
    else false
  end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. Hash chain (§2.5) — pgcrypto is already installed (F4), so this costs ~15 lines
-- ═══════════════════════════════════════════════════════════════════════════════════

-- entry_hash = sha256(prev_hash ‖ canonical(row)).
--
-- The canonical form pins the fields that define the entry's financial meaning
-- and its position in the chain. Amounts are rendered at fixed scale and the
-- timestamp in UTC with microseconds, so the same row hashes identically on any
-- connection whatever its locale or TimeZone setting.
create or replace function public.wallet_entry_hash(
  p_prev_hash     bytea,
  p_wallet_id     uuid,
  p_seq           bigint,
  p_kind          text,
  p_category      text,
  p_amount        numeric,
  p_balance_after numeric,
  p_created_at    timestamptz,
  p_performed_by  uuid,
  p_request_key   uuid
)
returns bytea
language sql
immutable
as $$
  select extensions.digest(
    coalesce(p_prev_hash, ''::bytea) ||
    convert_to(
      concat_ws('|',
        p_wallet_id::text,
        p_seq::text,
        p_kind,
        p_category,
        to_char(p_amount,        'FM9999999990.00'),
        to_char(p_balance_after, 'FM9999999990.00'),
        to_char(p_created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US'),
        coalesce(p_performed_by::text, ''),
        p_request_key::text),
      'UTF8'),
    'sha256');
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Guard triggers (§12.3, law L4)
-- ═══════════════════════════════════════════════════════════════════════════════════

-- The ledger is immutable. Exactly one transition is permitted — posted →
-- reversed — and every other column must be byte-identical.
--
-- NOT security definer, and no role exemption: it binds the table owner too, so
-- a future SECURITY DEFINER function that gets this wrong still fails rather
-- than silently rewriting history.
create or replace function public.wallet_ledger_guard()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'wallet_ledger_immutable';
  end if;

  if old.status = 'posted' and new.status = 'reversed'
     and new.id             = old.id
     and new.wallet_id      = old.wallet_id
     and new.office_id      = old.office_id
     and new.seq            = old.seq
     and new.kind           = old.kind
     and new.category       = old.category
     and new.amount         = old.amount
     and new.balance_before = old.balance_before
     and new.balance_after  = old.balance_after
     and new.created_at     = old.created_at
     and new.entry_hash     = old.entry_hash
     and new.prev_hash      is not distinct from old.prev_hash
     and new.request_key    = old.request_key
  then
    return new;
  end if;

  raise exception 'wallet_ledger_immutable';
end;
$$;

drop trigger if exists trg_wallet_tx_immutable on public.wallet_transactions;
create trigger trg_wallet_tx_immutable
  before update or delete on public.wallet_transactions
  for each row execute function public.wallet_ledger_guard();


-- Law L4, enforced structurally: money never moves without a ledger row.
--
-- RLS already denies every mutation from every client role. This trigger closes
-- the remaining path — a SECURITY DEFINER function running as the table owner
-- that updates `balance` directly. wallet_post_entry sets a transaction-local
-- flag around its own UPDATE; nothing else can.
create or replace function public.wallet_balance_guard()
returns trigger
language plpgsql
as $$
begin
  if new.balance           is distinct from old.balance
     or new.lifetime_credited is distinct from old.lifetime_credited
     or new.lifetime_debited  is distinct from old.lifetime_debited
     or new.entry_count       is distinct from old.entry_count
     or new.last_seq          is distinct from old.last_seq
     or new.head_hash         is distinct from old.head_hash
  then
    if coalesce(current_setting('bmt.wallet_posting', true), '') <> 'on' then
      raise exception 'wallet_balance_requires_ledger_entry';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_wallet_balance_guard on public.wallets;
create trigger trg_wallet_balance_guard
  before update on public.wallets
  for each row execute function public.wallet_balance_guard();

drop trigger if exists update_wallets_updated_at on public.wallets;
create trigger update_wallets_updated_at
  before update on public.wallets
  for each row execute function public.update_updated_at_column();


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 7. RLS and grants (§3.5, §12.1–12.2)
-- ═══════════════════════════════════════════════════════════════════════════════════

alter table public.wallets             enable row level security;
alter table public.wallet_transactions enable row level security;

-- SELECT only. No INSERT/UPDATE/DELETE policy exists on either table for any
-- role, so RLS alone denies every mutation and the only path to money movement
-- is a SECURITY DEFINER RPC.
drop policy if exists wallets_office_read on public.wallets;
create policy wallets_office_read
  on public.wallets for select to authenticated
  using (office_id = public.current_office_id());

drop policy if exists wallets_self_read on public.wallets;
create policy wallets_self_read
  on public.wallets for select to authenticated
  using (client_id = auth.uid());

drop policy if exists wallet_transactions_office_read on public.wallet_transactions;
create policy wallet_transactions_office_read
  on public.wallet_transactions for select to authenticated
  using (office_id = public.current_office_id());

drop policy if exists wallet_transactions_self_read on public.wallet_transactions;
create policy wallet_transactions_self_read
  on public.wallet_transactions for select to authenticated
  using (client_id = auth.uid());

-- TRUNCATE is never filtered by RLS — the lesson already recorded from the
-- Phase 6 tracking work. Revoke it explicitly.
revoke all on public.wallets             from anon;
revoke all on public.wallets             from authenticated;
revoke all on public.wallet_transactions from anon;
revoke all on public.wallet_transactions from authenticated;
grant select on public.wallets             to authenticated;
grant select on public.wallet_transactions to authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 8. Policy accessor — lazily materialises a default row for a new office
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.wallet_office_policy(p_office_id uuid)
returns public.office_wallet_policies
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_policy public.office_wallet_policies;
begin
  select * into v_policy from public.office_wallet_policies where office_id = p_office_id;
  if found then
    return v_policy;
  end if;

  insert into public.office_wallet_policies (office_id) values (p_office_id)
  on conflict (office_id) do nothing;

  select * into v_policy from public.office_wallet_policies where office_id = p_office_id;
  return v_policy;
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 9. wallet_post_entry — the only writer (§4)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- The order of the steps below is load-bearing, and step 9 is the concurrency
-- contract: NO value used in a validation decision is read before the wallet row
-- lock is held. Two operators adjusting the same wallet simultaneously otherwise
-- each validate against a stale total.
--
-- `p_amount` is always a positive magnitude. Direction comes from `p_kind`,
-- never from the caller's sign — except for `reversal`, whose direction is read
-- off the entry it reverses.
create or replace function public.wallet_post_entry(
  p_client_id               uuid,
  p_capability              text,
  p_kind                    text,
  p_category                text,
  p_amount                  numeric,
  p_reason                  text,
  p_notes                   text    default null,
  p_request_key             uuid    default null,
  p_source                  text    default 'dashboard',
  p_booking_id              uuid    default null,
  p_refund_id               uuid    default null,
  p_subscription_id         uuid    default null,
  p_referral_id             uuid    default null,
  p_reverses_transaction_id uuid    default null,
  p_metadata                jsonb   default '{}'::jsonb,
  p_notify                  boolean default true,
  p_office_id               uuid    default null   -- system/migration sources only
)
returns public.wallet_transactions
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office      uuid;
  v_actor       uuid := auth.uid();
  v_actor_name  text;
  v_actor_role  text;
  v_policy      public.office_wallet_policies;
  v_amount      numeric(12,2);
  v_signed      numeric(12,2);
  v_request_key uuid := coalesce(p_request_key, gen_random_uuid());
  v_fingerprint text;
  v_wallet      public.wallets;
  v_existing    public.wallet_transactions;
  v_original    public.wallet_transactions;
  v_row         public.wallet_transactions;
  v_seq         bigint;
  v_hash        bytea;
  v_created_at  timestamptz := clock_timestamp();
  v_day_start   timestamptz;
  v_promo_today numeric;
  v_ops_hour    int;
  v_headers     json;
  v_client_name text;
begin
  ------------------------------------------------------------------ 1. office
  if p_source in ('system','migration') then
    v_office := coalesce(p_office_id, public.current_office_id());
  else
    v_office := public.current_office_id();
  end if;
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;

  ------------------------------------------------------------- 2. capability
  -- Skipped for system/migration, which have no operator to authorise; that
  -- path is reachable only from another SECURITY DEFINER function, because this
  -- one is revoked from every client role.
  if p_source in ('dashboard','client') and not public.office_can(p_capability) then
    raise exception 'not_authorized';
  end if;

  ----------------------------------------------------------- 3. self-dealing
  -- clients.id IS the auth user id, so this is the whole check (§13.1).
  if v_actor is not null and v_actor = p_client_id then
    raise exception 'self_adjustment_denied';
  end if;

  ------------------------------------------------------- 4. customer eligible
  if not public.office_owns_client(p_client_id, v_office) then
    raise exception 'client_not_in_office';
  end if;

  ------------------------------------------------------------- 5./6. inputs
  v_policy := public.wallet_office_policy(v_office);

  if p_kind = 'reversal' then
    -- The magnitude and direction of a reversal are properties of the entry it
    -- reverses, not of the caller's request.
    select * into v_original from public.wallet_transactions
      where id = p_reverses_transaction_id and office_id = v_office;
    if not found then
      raise exception 'transaction_not_found';
    end if;
    if v_original.kind = 'reversal' then
      raise exception 'cannot_reverse_reversal';
    end if;
    if v_original.status <> 'posted' then
      raise exception 'already_reversed';
    end if;
    if v_original.client_id is distinct from p_client_id then
      raise exception 'transaction_not_found';
    end if;
    v_amount := abs(v_original.amount);
  else
    v_amount := round(coalesce(p_amount, 0), 2);
    if v_amount <= 0 then
      raise exception 'invalid_amount';
    end if;
    if p_kind in ('refund','cashback','manual_credit','wallet_topup')
       and v_amount > v_policy.max_single_credit then
      raise exception 'amount_exceeds_policy';
    end if;
    if p_kind in ('manual_debit','wallet_spend')
       and v_amount > v_policy.max_single_debit then
      raise exception 'amount_exceeds_policy';
    end if;
  end if;

  if nullif(btrim(coalesce(p_reason,'')), '') is null then
    raise exception 'reason_required';
  end if;
  if not public.wallet_category_allowed(p_kind, p_category) then
    raise exception 'invalid_category';
  end if;

  --------------------------------------------------------- 7. idempotency
  v_fingerprint := md5(concat_ws('|',
    p_kind,
    p_client_id::text,
    to_char(v_amount, 'FM9999999990.00'),
    coalesce(p_booking_id::text, '')));

  select * into v_existing from public.wallet_transactions
    where office_id = v_office and request_key = v_request_key;
  if found then
    -- A retry returns the original and posts nothing — and, critically, sends no
    -- second notification (§14, case 7).
    if v_existing.request_fingerprint = v_fingerprint then
      return v_existing;
    end if;
    -- Same key, different intention: refuse rather than silently return an
    -- unrelated transaction and report success (§13).
    raise exception 'request_key_conflict';
  end if;

  ------------------------------------------------------------- 8. lock
  select * into v_wallet from public.wallets
    where office_id = v_office and client_id = p_client_id and owner_type = 'client'
    for update;

  if not found then
    insert into public.wallets (office_id, owner_type, client_id)
    values (v_office, 'client', p_client_id)
    on conflict (office_id, client_id) where owner_type = 'client' do nothing;

    select * into v_wallet from public.wallets
      where office_id = v_office and client_id = p_client_id and owner_type = 'client'
      for update;
  end if;

  ------------------------------------------- 9. post-lock validation ONLY
  v_signed := case
    when p_kind in ('refund','cashback','manual_credit','wallet_topup') then  v_amount
    when p_kind in ('manual_debit','wallet_spend')                      then -v_amount
    when p_kind = 'reversal'                                            then -v_original.amount
  end;

  if v_actor is not null then
    select count(*) into v_ops_hour from public.wallet_transactions
      where office_id = v_office
        and performed_by = v_actor
        and created_at >= now() - interval '1 hour';
    if v_ops_hour >= v_policy.max_operator_hourly_ops then
      raise exception 'adjustment_rate_limited';
    end if;

    if p_kind in ('cashback','manual_credit') then
      -- Evaluated in the OFFICE's timezone, not the server's UTC and not the
      -- operator's device clock (§14, case 14).
      v_day_start := date_trunc('day', now() at time zone v_policy.timezone)
                     at time zone v_policy.timezone;
      select coalesce(sum(amount), 0) into v_promo_today
        from public.wallet_transactions
       where office_id = v_office
         and performed_by = v_actor
         and kind in ('cashback','manual_credit')
         and status = 'posted'
         and created_at >= v_day_start;
      if v_promo_today + v_amount > v_policy.max_operator_daily_promo then
        raise exception 'daily_cap_exceeded';
      end if;
    end if;
  end if;

  if v_wallet.status = 'frozen' and p_kind in ('manual_debit','wallet_spend') then
    raise exception 'wallet_frozen';
  end if;

  -- available_balance, not balance: enabling holds later changes nothing here.
  if v_signed < 0 and v_wallet.available_balance + v_signed < 0 then
    raise exception 'insufficient_wallet_balance';
  end if;

  ------------------------------------------------------- 10. seq + hash chain
  v_seq  := v_wallet.last_seq + 1;
  v_hash := public.wallet_entry_hash(
    v_wallet.head_hash, v_wallet.id, v_seq, p_kind, p_category,
    v_signed, v_wallet.balance + v_signed, v_created_at, v_actor, v_request_key);

  -- Actor identity, resolved once. performed_by_name is stored rather than
  -- joined so the ledger still reads correctly after an office user is renamed
  -- or removed.
  select ou.full_name, ou.role into v_actor_name, v_actor_role
    from public.office_users ou
   where ou.user_id = v_actor and ou.office_id = v_office
   limit 1;

  if v_actor_name is null then
    v_actor_name := case p_source
      when 'migration' then 'ترحيل بيانات'
      when 'system'    then 'النظام'
      else 'مستخدم المكتب'
    end;
  end if;

  -- Advisory context (F7): present on PostgREST calls, NULL on direct
  -- connections, client-supplied either way. Never used in a decision.
  begin
    v_headers := nullif(current_setting('request.headers', true), '')::json;
  exception when others then
    v_headers := null;
  end;

  ------------------------------------------------------------- 11. insert
  insert into public.wallet_transactions (
    wallet_id, office_id, client_id, seq,
    kind, category, source,
    amount, balance_before, balance_after,
    reason, notes,
    booking_id, refund_id, subscription_id, referral_id,
    reverses_transaction_id, metadata,
    performed_by, performed_by_name, performed_by_role,
    request_key, request_fingerprint, client_ip, user_agent,
    prev_hash, entry_hash, created_at
  ) values (
    v_wallet.id, v_office, p_client_id, v_seq,
    p_kind, p_category, p_source,
    v_signed, v_wallet.balance, v_wallet.balance + v_signed,
    btrim(p_reason), nullif(btrim(coalesce(p_notes,'')), ''),
    p_booking_id, p_refund_id, p_subscription_id, p_referral_id,
    p_reverses_transaction_id, coalesce(p_metadata, '{}'::jsonb),
    v_actor, v_actor_name, coalesce(v_actor_role, public.office_role()),
    v_request_key, v_fingerprint,
    nullif(split_part(coalesce(v_headers ->> 'x-forwarded-for', ''), ',', 1), '')::inet,
    nullif(v_headers ->> 'user-agent', ''),
    v_wallet.head_hash, v_hash, v_created_at
  )
  returning * into v_row;

  ------------------------------------------------------- 12. cache the balance
  perform set_config('bmt.wallet_posting', 'on', true);
  update public.wallets
     set balance           = v_wallet.balance + v_signed,
         lifetime_credited = lifetime_credited + greatest(v_signed, 0),
         lifetime_debited  = lifetime_debited  + greatest(-v_signed, 0),
         entry_count       = entry_count + 1,
         last_seq          = v_seq,
         head_hash         = v_hash,
         updated_at        = now()
   where id = v_wallet.id;
  perform set_config('bmt.wallet_posting', 'off', true);

  -- A reversal closes the entry it mirrors. This is the single mutation the
  -- immutability trigger permits (§12.3).
  if p_kind = 'reversal' then
    update public.wallet_transactions
       set status = 'reversed'
     where id = v_original.id;
  end if;

  ------------------------------------------------------------ 13. tell people
  if p_notify then
    select full_name into v_client_name from public.clients where id = p_client_id;

    perform public.push_notification(
      p_client_id,
      case when v_signed > 0 then 'إضافة رصيد إلى محفظتك' else 'خصم من رصيد محفظتك' end,
      case when v_signed > 0
        then 'تمت إضافة ' || to_char(abs(v_signed), 'FM9999999990.00') ||
             ' ج.م إلى محفظتك. الرصيد الحالي: ' ||
             to_char(v_wallet.balance + v_signed, 'FM9999999990.00') || ' ج.م.'
        else 'تم خصم ' || to_char(abs(v_signed), 'FM9999999990.00') ||
             ' ج.م من محفظتك. الرصيد الحالي: ' ||
             to_char(v_wallet.balance + v_signed, 'FM9999999990.00') || ' ج.م.'
      end,
      'payment', 'client',
      jsonb_build_object('wallet_transaction_id', v_row.id, 'kind', p_kind),
      '/wallet');

    perform public.push_operational_alert(
      'wallet_' || p_kind,
      case when v_signed > 0 then 'إضافة رصيد لمحفظة عميل' else 'خصم من محفظة عميل' end,
      coalesce(v_client_name, 'عميل') || ' — ' ||
        to_char(abs(v_signed), 'FM9999999990.00') || ' ج.م — ' || btrim(p_reason),
      jsonb_build_object('wallet_transaction_id', v_row.id,
                         'client_id', p_client_id,
                         'kind', p_kind),
      case when p_kind in ('manual_debit','reversal') then 'high' else 'normal' end,
      '/wallet',
      v_office);
  end if;

  return v_row;
end;
$$;

-- The shared writer is revoked from every client role, so the per-kind guards in
-- the RPCs above it cannot be bypassed by calling it directly.
revoke all on function public.wallet_post_entry(
  uuid, text, text, text, numeric, text, text, uuid, text,
  uuid, uuid, uuid, uuid, uuid, jsonb, boolean, uuid) from public;
revoke all on function public.wallet_post_entry(
  uuid, text, text, text, numeric, text, text, uuid, text,
  uuid, uuid, uuid, uuid, uuid, jsonb, boolean, uuid) from anon;
revoke all on function public.wallet_post_entry(
  uuid, text, text, text, numeric, text, text, uuid, text,
  uuid, uuid, uuid, uuid, uuid, jsonb, boolean, uuid) from authenticated;

revoke all on function public.wallet_office_policy(uuid) from public;
revoke all on function public.wallet_office_policy(uuid) from anon;
revoke all on function public.wallet_office_policy(uuid) from authenticated;

grant execute on function public.office_can(text)                     to authenticated;
grant execute on function public.office_owns_client(uuid, uuid)       to authenticated;
grant execute on function public.wallet_category_allowed(text, text)  to authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 10. Reconciliation — Σ amount = balance, per wallet (§13)
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Available to the regression suite and to the UI. Returns one row per wallet
-- that does NOT reconcile, so an empty result is the healthy answer.
create or replace function public.wallet_reconcile(p_office_id uuid default null)
returns table (
  wallet_id       uuid,
  client_id       uuid,
  cached_balance  numeric,
  ledger_balance  numeric,
  entry_count     bigint,
  ledger_entries  bigint,
  max_seq         bigint,
  seq_gaps        bigint
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select w.id, w.client_id, w.balance,
         coalesce(t.total, 0), w.entry_count,
         coalesce(t.n, 0), coalesce(t.max_seq, 0),
         coalesce(t.max_seq, 0) - coalesce(t.n, 0)
    from public.wallets w
    left join lateral (
      select sum(amount) as total, count(*) as n, max(seq) as max_seq
        from public.wallet_transactions x where x.wallet_id = w.id
    ) t on true
   where (p_office_id is null or w.office_id = p_office_id)
     and (w.balance <> coalesce(t.total, 0)
       or w.entry_count <> coalesce(t.n, 0)
       or coalesce(t.max_seq, 0) <> coalesce(t.n, 0));
$$;

revoke all on function public.wallet_reconcile(uuid) from public;
revoke all on function public.wallet_reconcile(uuid) from anon;
revoke all on function public.wallet_reconcile(uuid) from authenticated;
