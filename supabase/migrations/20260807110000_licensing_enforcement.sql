-- ═══════════════════════════════════════════════════════════════════════════════════
-- EWT Entitlement Platform — Phase 4/6: enforcement
--
-- Design: docs/architecture/PLATFORM_LICENSING.md §1.2 F4, §5.3, §7.3, Part 15.
--
-- ── Why triggers and not RPC guards (decision 3) ────────────────────────────────────
--
-- The dashboard is a Supabase client holding the operator's own JWT. It can issue any
-- REST call RLS permits, and drivers, vehicles, routes and operators are written by
-- DIRECT TABLE INSERT — there is no RPC to put a guard in (F4). The three biggest
-- quota surfaces in the brief would therefore be unenforced by a guard-only design.
--
-- So the enforcement boundary is BEFORE INSERT triggers on the tables themselves.
-- assert_feature() ships alongside as the guard for RPCs added later, but it is a
-- convenience layer for better error messages, not the boundary.
--
-- ── It ships DISABLED (decision 8) ─────────────────────────────────────────────────
--
-- Every trigger below returns early while platform_settings.enforcement_mode = 'off',
-- which is what this migration leaves it at. Three live offices, all currently
-- unlimited: a rollout that changes behaviour on deploy day risks the entire customer
-- base at once.
--
--     off       → return immediately. Current behaviour, byte for byte.
--     shadow    → evaluate, LOG to platform_quota_violations, allow.
--     enforcing → block.
--
-- A non-empty violations table in shadow means a SEEDED LIMIT IS WRONG, not that a
-- customer is cheating. That is the entire point of the mode: the numbers get
-- corrected before they can hurt anybody.
--
-- ── The error carries the whole verdict ────────────────────────────────────────────
--
-- `raise exception … using detail = <verdict jsonb>` puts limit / used / remaining /
-- plan_key on the wire, so the Flutter layer renders "12 من 12 سائقًا على الأساسية"
-- instead of "quota_exceeded". That is the mechanism behind the upgrade dialog.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. The shadow-mode log
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.platform_quota_violations (
  id          bigserial primary key,
  office_id   uuid not null references public.offices(id) on delete restrict,
  feature_key text not null references public.platform_features(key) on delete restrict,
  verdict     jsonb not null,
  table_name  text not null,
  operation   text not null default 'INSERT',
  actor_id    uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now()
);

create index if not exists idx_quota_violations_office
  on public.platform_quota_violations (office_id, created_at desc);
create index if not exists idx_quota_violations_feature
  on public.platform_quota_violations (feature_key, created_at desc);

comment on table public.platform_quota_violations is
  'What WOULD have been blocked, recorded while enforcement_mode = ''shadow''. Rows '
  'here are evidence that a seeded limit is wrong, not that a customer is cheating.';

alter table public.platform_quota_violations enable row level security;

drop policy if exists quota_violations_read on public.platform_quota_violations;
create policy quota_violations_read on public.platform_quota_violations
  for select to authenticated
  using (public.is_platform_admin() or office_id = public.current_office_id());

revoke all on public.platform_quota_violations from anon, authenticated;
grant select on public.platform_quota_violations to authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. assert_feature — the RPC-side guard (§7.3)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Applied at the top of a gated RPC, immediately AFTER the existing office_can()
-- check and never instead of it:
--
--     if not public.office_can('wallet_adjust') then raise exception 'not_authorized'; end if;
--     perform public.assert_feature('cashback');
--
-- The order is deliberate. A support agent who may not adjust wallets should be told
-- that, not shown an upgrade prompt for a feature they still would not be allowed to
-- use. Role first, entitlement second (§7.1: three predicates, ANDed, never merged).

create or replace function public.assert_feature(p_key text)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_res jsonb;
begin
  if public.platform_enforcement_mode() <> 'enforcing' then
    return;
  end if;

  v_res := public.office_feature(p_key);

  if not public.platform_value_is_truthy(v_res -> 'value') then
    raise exception '%', case
        when v_res ->> 'blocked_by' is not null    then 'feature_dependency_blocked'
        when v_res ->> 'source' = 'license_hold'   then 'license_suspended'
        else 'feature_not_licensed'
      end
      using detail = v_res::text, errcode = 'check_violation';
  end if;
end;
$$;

revoke all on function public.assert_feature(text) from public, anon;
grant execute on function public.assert_feature(text) to authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. The generic quota / feature trigger (§5.3)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- One function, attached per table with the feature keys as trigger arguments. It
-- reads office_id off the row generically, because a trigger runs in the ROW's
-- context and not the caller's — which is also why it calls the `_for` variant of the
-- verdict function, the one revoked from every API role.

-- The decision itself, as an ordinary function. A trigger function cannot be called
-- from another trigger function — Postgres refuses — and three of the gates below are
-- transition-scoped wrappers that need exactly that. So the logic lives here and the
-- trigger entry points are thin.
create or replace function public.enforce_office_quota_keys(
  p_office_id uuid,
  p_keys      text[],
  p_table     text,
  p_op        text default 'INSERT'
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mode    text := public.platform_enforcement_mode();
  v_key     text;
  v_verdict jsonb;
begin
  if v_mode = 'off' or p_office_id is null or p_keys is null then
    return;
  end if;

  foreach v_key in array p_keys loop
    v_verdict := public.office_can_consume_for(p_office_id, v_key, 1);

    if not (v_verdict ->> 'allowed')::boolean then
      if v_mode = 'shadow' then
        insert into public.platform_quota_violations
          (office_id, feature_key, verdict, table_name, operation, actor_id)
        values (p_office_id, v_key, v_verdict, p_table, p_op, auth.uid());
        -- Observed, not blocked.
      else
        raise exception '%', coalesce(v_verdict ->> 'reason', 'quota_exceeded')
          using detail = v_verdict::text, errcode = 'check_violation';
      end if;
    end if;
  end loop;
end;
$$;


create or replace function public.enforce_office_quota()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- office_id is read off the row generically, because a trigger runs in the ROW's
  -- context and not the caller's. An unattributable row cannot be metered against
  -- anybody, and enforce_office_quota_keys returns early for one — better a missed
  -- meter than a failed write on a path licensing does not understand.
  perform public.enforce_office_quota_keys(
    nullif(to_jsonb(new) ->> 'office_id', '')::uuid,
    tg_argv, tg_table_name, tg_op);
  return new;
end;
$$;


-- Flow meters are incremented by the same transaction as the row they count, AFTER
-- the insert succeeds. Deleting that row later does NOT refund the quota — otherwise
-- an office on a 100-trip plan runs 1,000 trips by deleting each one when it
-- finishes (§5.2).
create or replace function public.record_office_usage()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_office uuid := nullif(to_jsonb(new) ->> 'office_id', '')::uuid;
  i int;
begin
  if v_office is null then return null; end if;
  for i in 0 .. tg_nargs - 1 loop
    perform public.office_usage_record(v_office, tg_argv[i], 1);
  end loop;
  return null;
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. Attachments — the three surfaces with no RPC (F4), plus the metered ones
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Fleet.
drop trigger if exists trg_quota_drivers on public.drivers;
create trigger trg_quota_drivers
  before insert on public.drivers
  for each row execute function public.enforce_office_quota('drivers', 'max_drivers');

drop trigger if exists trg_quota_vehicles on public.vehicles;
create trigger trg_quota_vehicles
  before insert on public.vehicles
  for each row execute function public.enforce_office_quota('max_vehicles');

-- Routes.
drop trigger if exists trg_quota_routes on public.operation_routes;
create trigger trg_quota_routes
  before insert on public.operation_routes
  for each row execute function public.enforce_office_quota('routes', 'max_routes');

-- Operators. §5.4 in force: this blocks operator 9, it never disables operators 1–8.
-- Locking a customer out of their own dashboard as a BILLING action is not a
-- downgrade, it is a lockout.
drop trigger if exists trg_quota_office_users on public.office_users;
create trigger trg_quota_office_users
  before insert on public.office_users
  for each row execute function public.enforce_office_quota('max_admin_users');

-- Trips: a flow meter, so the check is BEFORE and the increment is AFTER.
drop trigger if exists trg_quota_trips on public.operation_trips;
create trigger trg_quota_trips
  before insert on public.operation_trips
  for each row execute function public.enforce_office_quota('trips', 'max_trips_per_month');

drop trigger if exists trg_usage_trips on public.operation_trips;
create trigger trg_usage_trips
  after insert on public.operation_trips
  for each row execute function public.record_office_usage('max_trips_per_month');

-- Money. Gating the LEDGER rather than the wallet RPCs closes every path at once,
-- including any future writer, and needs no edit to a function that already works.
drop trigger if exists trg_quota_wallet on public.wallet_transactions;
create trigger trg_quota_wallet
  before insert on public.wallet_transactions
  for each row execute function public.enforce_office_quota('wallet');

create or replace function public.enforce_wallet_kind_feature()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- cashback is the one ledger kind that is separately licensed. Its dependency on
  -- `wallet` is declared in the catalog, so an office with cashback but no wallet
  -- resolves cashback to false and this refuses — the two facts never disagree.
  if new.kind = 'cashback' then
    perform public.enforce_office_quota_keys(
      new.office_id, tg_argv, tg_table_name, tg_op);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_quota_wallet_cashback on public.wallet_transactions;
create trigger trg_quota_wallet_cashback
  before insert on public.wallet_transactions
  for each row execute function public.enforce_wallet_kind_feature('cashback');

drop trigger if exists trg_quota_refunds on public.refund_requests;
create trigger trg_quota_refunds
  before insert on public.refund_requests
  for each row execute function public.enforce_office_quota('refunds');

-- Passenger fare bundles — the OTHER meaning of "package" (§1.2 F2). Licensing gates
-- whether the office may sell them; it never touches their prices or tiers (§2.6).
drop trigger if exists trg_quota_packages on public.packages;
create trigger trg_quota_packages
  before insert on public.packages
  for each row execute function public.enforce_office_quota('passenger_packages');

drop trigger if exists trg_quota_transport_packages on public.transport_packages;
create trigger trg_quota_transport_packages
  before insert on public.transport_packages
  for each row execute function public.enforce_office_quota('passenger_packages');


-- ── Two transition-scoped gates ─────────────────────────────────────────────────────

-- max_captains counts drivers who hold a captain-app account, so it is metered at the
-- moment an account is attached rather than at driver creation.
create or replace function public.enforce_captain_quota()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.user_id is not null and old.user_id is null then
    perform public.enforce_office_quota_keys(
      new.office_id, tg_argv, tg_table_name, tg_op);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_quota_captains on public.drivers;
create trigger trg_quota_captains
  before update of user_id on public.drivers
  for each row execute function public.enforce_captain_quota('max_captains');


-- max_live_trips is a stock meter on trips that are actually in flight, so it is
-- checked on the transition INTO flight, never on a trip that is already moving.
--
-- The `restricted` plan deliberately leaves this unlimited: a trip whose tickets are
-- already sold must be able to depart even while the office is suspended. Blocking it
-- strands passengers, and no billing outcome is worth that (decision 4).
create or replace function public.enforce_live_trip_quota()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status in ('boarding','in_progress')
     and old.status not in ('boarding','in_progress') then
    perform public.enforce_office_quota_keys(
      new.office_id, tg_argv, tg_table_name, tg_op);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_quota_live_trips on public.operation_trips;
create trigger trg_quota_live_trips
  before update of status on public.operation_trips
  for each row execute function public.enforce_live_trip_quota('max_live_trips');


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. Register the gates (§3.2) — this is what flips the console badge to `enforced`
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- A gate row means "this feature is gated by this named piece of code". Inserted by
-- the migration that CREATES the gate, so platform_features.enforcement_status can
-- never claim more than the code delivers.

insert into public.platform_feature_gates (feature_key, gate_kind, gate_ref, note) values
  ('drivers',             'trigger', 'trg_quota_drivers',            'إنشاء سائق'),
  ('max_drivers',         'trigger', 'trg_quota_drivers',            'حد السائقين النشطين'),
  ('max_vehicles',        'trigger', 'trg_quota_vehicles',           'حد المركبات'),
  ('routes',              'trigger', 'trg_quota_routes',             'إنشاء خط سير'),
  ('max_routes',          'trigger', 'trg_quota_routes',             'حد خطوط السير'),
  ('max_admin_users',     'trigger', 'trg_quota_office_users',       'حد مستخدمي اللوحة'),
  ('trips',               'trigger', 'trg_quota_trips',              'إنشاء رحلة'),
  ('max_trips_per_month', 'trigger', 'trg_quota_trips',              'فحص حصة الشهر'),
  ('max_trips_per_month', 'trigger', 'trg_usage_trips',              'تسجيل الاستهلاك'),
  ('max_live_trips',      'trigger', 'trg_quota_live_trips',         'الانتقال إلى رحلة جارية'),
  ('max_captains',        'trigger', 'trg_quota_captains',           'ربط حساب كابتن بسائق'),
  ('wallet',              'trigger', 'trg_quota_wallet',             'أي حركة على دفتر المحفظة'),
  ('cashback',            'trigger', 'trg_quota_wallet_cashback',    'حركة من نوع cashback'),
  ('refunds',             'trigger', 'trg_quota_refunds',            'إنشاء طلب استرداد'),
  ('passenger_packages',  'trigger', 'trg_quota_packages',           'إنشاء باقة ركاب'),
  ('passenger_packages',  'trigger', 'trg_quota_transport_packages', 'إنشاء باقة نقل')
on conflict (feature_key, gate_kind, gate_ref) do nothing;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Features this phase does NOT gate, named rather than quietly skipped
-- ═══════════════════════════════════════════════════════════════════════════════════
--
--   promotions   — Part 6 names `promo_codes` as the gate. That table does not exist
--                  in this database. The feature stays `declared` until it does.
--   loyalty      — `loyalty_accounts` carries no office_id, so there is nothing to
--                  meter an office by. Stays `declared`.
--   referrals    — no office-scoped write surface to gate. Stays `declared`.
--   live_tracking / live_ops_center / client_app / driver_app / finance / reports /
--   bookings / notifications / report_level / analytics_level / export_* —
--                  gated in Phase 6 (RLS + client surfaces) or in the Flutter layer,
--                  and their gate rows are inserted there.
--
-- Naming them here is the whole point of enforcement_status: shipping flags that
-- silently do nothing is how a licensing system loses credibility internally.

revoke all on function public.enforce_office_quota_keys(uuid, text[], text, text)
  from public, anon, authenticated;
revoke all on function public.enforce_office_quota()        from public, anon, authenticated;
revoke all on function public.record_office_usage()         from public, anon, authenticated;
revoke all on function public.enforce_wallet_kind_feature() from public, anon, authenticated;
revoke all on function public.enforce_captain_quota()       from public, anon, authenticated;
revoke all on function public.enforce_live_trip_quota()     from public, anon, authenticated;
