-- ═══════════════════════════════════════════════════════════════════════════════════
-- Wallet & Financial Adjustments — Step 1/4: office wallet policies
--
-- Design: docs/dashboard/DASHBOARD_CUSTOMER_WALLET.md §3.4.
--
-- Limits are data, not deploys. Every cap the ledger enforces — single credit,
-- single debit, an operator's daily promotional budget, an operator's hourly
-- operation count — is a row an owner can change, not a constant someone has to
-- ship a migration to move.
--
-- ── Why this runs BEFORE the core tables (a deliberate deviation from §15) ───────
--
-- §15 orders the policy table last. It cannot be: `wallet_post_entry` (step 2)
-- reads a policy row on every posting, so the table has to exist first. The four
-- steps are otherwise exactly as specified. Ordering is the only change.
--
-- ── Two CHECK-pinned extension points ───────────────────────────────────────────
--
--   overdraft_limit               — pinned to 0. Relaxing the CHECK is the single
--                                   deliberate act that turns overdraft on (§2.6).
--   require_second_approval_above — nullable, unenforced in V1. Present so an
--                                   office with two owners can adopt hard
--                                   maker–checker without a migration (§9).
--
-- `timezone` exists because a *daily* cap evaluated in UTC resets at 2am Cairo,
-- which is neither the operator's day nor the office's (§14, case 14).
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.office_wallet_policies (
  office_id                     uuid primary key
                                references public.offices(id) on delete restrict,

  -- Per-transaction ceilings. A cap of 0 would freeze the module, so both are
  -- constrained strictly positive: "disable adjustments" is a role decision
  -- (§6), never a silently zeroed limit.
  max_single_credit             numeric(12,2) not null default 1000
                                check (max_single_credit > 0),
  max_single_debit              numeric(12,2) not null default 1000
                                check (max_single_debit > 0),

  -- Per-operator, per-day promotional budget (cashback + manual credit) and a
  -- per-operator hourly operation count. Both are anti-fraud velocity controls
  -- (§13), not accounting limits — they bound how fast one account can move
  -- money, whatever the individual amounts are.
  max_operator_daily_promo      numeric(12,2) not null default 2000
                                check (max_operator_daily_promo >= 0),
  max_operator_hourly_ops       int not null default 30
                                check (max_operator_hourly_ops > 0),

  -- CHECK-pinned closed. The column documents the extension point; the CHECK is
  -- what stops it being used before anyone has decided how a debt gets collected.
  overdraft_limit               numeric(12,2) not null default 0
                                check (overdraft_limit = 0),

  -- Recorded, not enforced, in V1. See the header.
  require_second_approval_above numeric(12,2)
                                check (require_second_approval_above is null
                                       or require_second_approval_above > 0),

  timezone                      text not null default 'Africa/Cairo',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- A bad timezone name would make every daily cap raise at posting time, i.e.
  -- money would stop moving because of a typo in a config row. Reject it here.
  constraint office_wallet_policy_tz_valid
    check (now() at time zone timezone is not null)
);

comment on table public.office_wallet_policies is
  'Per-office wallet limits. Read by wallet_post_entry on every posting; editable by the office owner.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- Defaults for the offices that exist today. Offices created later get their row
-- lazily from wallet_office_policy() in step 2 — no trigger on `offices`, so
-- office onboarding cannot fail because of a wallet table.
-- ───────────────────────────────────────────────────────────────────────────────────
insert into public.office_wallet_policies (office_id)
select id from public.offices
on conflict (office_id) do nothing;

-- ───────────────────────────────────────────────────────────────────────────────────
-- RLS. This is configuration, not money, so it is written directly rather than
-- through an RPC — but only by the owner, and only for their own office.
-- ───────────────────────────────────────────────────────────────────────────────────
alter table public.office_wallet_policies enable row level security;

drop policy if exists office_wallet_policies_read on public.office_wallet_policies;
create policy office_wallet_policies_read
  on public.office_wallet_policies
  for select
  to authenticated
  using (office_id = public.current_office_id());

drop policy if exists office_wallet_policies_update on public.office_wallet_policies;
create policy office_wallet_policies_update
  on public.office_wallet_policies
  for update
  to authenticated
  using  (office_id = public.current_office_id()
          and public.office_role() = 'dashboard_admin')
  with check (office_id = public.current_office_id()
          and public.office_role() = 'dashboard_admin');

-- No INSERT or DELETE policy: a policy row's lifecycle belongs to the office's,
-- and both are created server-side.
revoke all on public.office_wallet_policies from anon;
revoke all on public.office_wallet_policies from authenticated;
grant select, update on public.office_wallet_policies to authenticated;

drop trigger if exists update_office_wallet_policies_updated_at
  on public.office_wallet_policies;
create trigger update_office_wallet_policies_updated_at
  before update on public.office_wallet_policies
  for each row execute function public.update_updated_at_column();
