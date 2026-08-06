-- ═══════════════════════════════════════════════════════════════════════════════════
-- EWT Entitlement Platform — Phase 2/6: resolution
--
-- Design: docs/architecture/PLATFORM_LICENSING.md §3.5–§3.7, Part 4, Part 5.
--
-- What this establishes:
--
--   1. office_licenses           — the office's commercial state. PK on office_id, so
--                                  "one license per office" is a database fact.
--   2. office_feature_overrides  — per-office exceptions, with a MANDATORY reason.
--   3. office_usage_counters     — FLOW meters only. Stock is counted, never stored.
--   4. platform_resolve_feature  — the ladder. ONE resolver, parameterised, so the
--                                  plan preview cannot drift from the real answer.
--   5. Two verbs                 — office_feature() reads a VALUE;
--                                  office_can_consume() returns a WRITE VERDICT.
--   6. office_entitlements()     — the whole document, one round trip, at sign-in.
--   7. Backfill                  — every existing office onto `founder`, unlimited.
--
-- ── Still nothing enforces anything ────────────────────────────────────────────────
--
-- This phase makes the platform able to ANSWER "what does this office have". Nothing
-- asks yet. enforcement_mode stays 'off'; Phase 4 adds the asking.
--
-- ── The ladder (§4.1), first match wins for the value ───────────────────────────────
--
--   0  kill switch    platform_features.status = 'disabled'      → default_value
--   1  license hold   status ∈ {suspended, cancelled, expired}   → restricted plan
--   2  override       a non-expired office_feature_overrides row → its value
--   3  plan           a platform_plan_features row               → its value
--   4  catalog        always                                     → default_value
--
--   5  dependencies   can only ever SUBTRACT. Never raise.
--   6  usage          does not change the value; produces a separate verdict.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. office_licenses (§3.5)
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.office_licenses (
  -- Primary key, not merely FK + unique. "Every office has ONE license" becomes a
  -- database fact rather than a convention nobody can enforce later.
  --
  -- on delete restrict (F8): an office with billing history must not be deletable
  -- through a cascade from auth.users.
  office_id       uuid primary key references public.offices(id) on delete restrict,

  plan_id         uuid not null references public.platform_plans(id) on delete restrict,

  -- Freeze to a historical plan revision (§2.5). NULL = follow the live plan.
  -- Inert in V1: nothing writes it, and there is deliberately no UI. The column
  -- exists so grandfathering is later a UI task rather than a migration.
  pinned_revision_id uuid references public.platform_plan_revisions(id) on delete restrict,

  status          text not null default 'trialing'
                    check (status in ('trialing','active','past_due','grace',
                                      'suspended','cancelled','expired')),

  billing_cycle   text not null default 'monthly'
                    check (billing_cycle in ('monthly','yearly','custom','free')),

  -- Negotiated price. NULL = use the plan's list price for the cycle.
  price_override  numeric(12,2) check (price_override >= 0),
  currency        text not null default 'EGP',

  trial_ends_at   timestamptz,
  period_start    timestamptz not null default now(),
  period_end      timestamptz,          -- NULL for 'custom' / perpetual contracts
  grace_ends_at   timestamptz,
  auto_renew      boolean not null default true,

  -- Enterprise contract metadata. Free text on purpose: a contract reference and a
  -- salesperson's note are not a schema.
  contract_ref    text,
  notes           text not null default '',

  suspended_at    timestamptz,
  suspended_reason text,

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  -- A trial must say when it ends; a non-trial must not pretend to be one.
  constraint license_trial_coherent check (
    (status = 'trialing') = (trial_ends_at is not null)
  )
);

create index if not exists idx_office_licenses_plan   on public.office_licenses (plan_id);
create index if not exists idx_office_licenses_status on public.office_licenses (status, period_end);

comment on table public.office_licenses is
  'The office''s commercial state. There is deliberately no history table: every '
  'change is an audit row and, where money is involved, an invoice. A third record '
  'of the truth is a third thing to disagree.';

drop trigger if exists update_office_licenses_updated_at on public.office_licenses;
create trigger update_office_licenses_updated_at
  before update on public.office_licenses
  for each row execute function public.update_updated_at_column();

drop trigger if exists trg_audit_licenses on public.office_licenses;
create trigger trg_audit_licenses
  after insert or update or delete on public.office_licenses
  for each row execute function public.platform_audit_trigger('license', 'office_id');


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. office_feature_overrides (§3.6)
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.office_feature_overrides (
  office_id    uuid not null references public.offices(id)          on delete restrict,
  feature_key  text not null references public.platform_features(key) on delete restrict,

  value        jsonb not null,

  -- Mandatory, and length-checked. An override with no stated reason becomes a
  -- permanent unexplained exception, because in two years nobody will dare remove
  -- it. This NOT NULL is the cheapest available control against override sprawl.
  reason       text not null check (length(btrim(reason)) >= 8),

  -- Temporary grants: a sales concession, a trial extension, a goodwill gesture.
  -- NULL = permanent. An EXPIRED override stops applying but is NOT deleted — the
  -- row is the record that the concession happened.
  expires_at   timestamptz,

  created_by   uuid references auth.users(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  -- One row per (office, feature). An office cannot hold two contradictory
  -- overrides for the same feature, which removes the whole "which one wins" bug
  -- class before it exists.
  primary key (office_id, feature_key)
);

create index if not exists idx_office_overrides_feature
  on public.office_feature_overrides (feature_key);
create index if not exists idx_office_overrides_expiry
  on public.office_feature_overrides (expires_at) where expires_at is not null;

comment on table public.office_feature_overrides is
  'Per-office, per-feature exceptions, highest priority below a license hold. They '
  'both GRANT and REVOKE — the brief''s own example is disabling API access on '
  'Enterprise — so the resolver treats an override as authoritative regardless of '
  'direction, and the console shows it as ▲ upgrade or ▼ restriction.';

drop trigger if exists update_office_overrides_updated_at on public.office_feature_overrides;
create trigger update_office_overrides_updated_at
  before update on public.office_feature_overrides
  for each row execute function public.update_updated_at_column();

drop trigger if exists trg_override_value_valid on public.office_feature_overrides;
create trigger trg_override_value_valid
  before insert or update on public.office_feature_overrides
  for each row execute function public.platform_feature_value_guard();

drop trigger if exists trg_audit_overrides on public.office_feature_overrides;
create trigger trg_audit_overrides
  after insert or update or delete on public.office_feature_overrides
  for each row execute function public.platform_audit_trigger('override', 'feature_key');


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. office_usage_counters (§3.7) — FLOW meters only
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.office_usage_counters (
  office_id   uuid not null references public.offices(id) on delete restrict,
  metric_key  text not null references public.platform_features(key) on delete restrict,

  -- 'lifetime', or 'YYYY-MM' in the office's billing timezone.
  period_key  text not null,

  used_value  bigint not null default 0 check (used_value >= 0),
  updated_at  timestamptz not null default now(),

  primary key (office_id, metric_key, period_key)
);

comment on table public.office_usage_counters is
  'FLOW meters only — "how many happened this period". Stock ("how many exist right '
  'now") is a COUNT at check time and is deliberately absent here: storing it would '
  'create a cache that drifts the first time a row is deleted outside the app, and '
  'self-healing beats reconciliation (§5.2). Rows are never reset — a new month is a '
  'new row, which makes usage history free and removes the "the reset job did not '
  'run" bug class entirely.';


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. Value helpers
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Truthiness of a resolved value, for the dependency gate.
create or replace function public.platform_value_is_truthy(p_value jsonb)
returns boolean
language sql
immutable
as $$
  select case jsonb_typeof(coalesce(p_value, 'null'::jsonb))
    when 'boolean' then (p_value #>> '{}') = 'true'
    when 'number'  then (p_value #>> '{}')::numeric <> 0
    when 'string'  then (p_value #>> '{}') not in ('', 'false', '0')
    when 'null'    then false
    else true
  end;
$$;

-- Is `p_value` at least `p_min` for this feature? Enums compare by position in
-- value_schema.allowed, which is why the allowed array is ordered least-to-most.
create or replace function public.platform_value_meets(
  p_key   text,
  p_value jsonb,
  p_min   jsonb
) returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_f     public.platform_features;
  v_have  int;
  v_want  int;
begin
  if p_min is null then
    return public.platform_value_is_truthy(p_value);
  end if;

  select * into v_f from public.platform_features where key = p_key;
  if not found then return false; end if;

  if v_f.value_type = 'enum' then
    select ordinality into v_have
      from jsonb_array_elements_text(v_f.value_schema -> 'allowed') with ordinality
     where value = (p_value #>> '{}');
    select ordinality into v_want
      from jsonb_array_elements_text(v_f.value_schema -> 'allowed') with ordinality
     where value = (p_min #>> '{}');
    return coalesce(v_have, 0) >= coalesce(v_want, 0);
  end if;

  if v_f.value_type = 'limit' then
    if (p_value #>> '{}') = 'unlimited' then return true; end if;
    if (p_min   #>> '{}') = 'unlimited' then return false; end if;
    return (p_value #>> '{}')::numeric >= (p_min #>> '{}')::numeric;
  end if;

  return public.platform_value_is_truthy(p_value);
end;
$$;

-- What a feature collapses to when a prerequisite is missing. Only ever a reduction.
create or replace function public.platform_collapsed_value(p_key text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case f.value_type
    when 'boolean' then 'false'::jsonb
    when 'limit'   then '0'::jsonb
    when 'enum'    then coalesce(f.value_schema -> 'allowed' -> 0, f.default_value)
    else f.default_value
  end
  from public.platform_features f where f.key = p_key;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. THE RESOLVER (§4.1)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- One function, parameterised, because the plan preview must run the REAL resolver —
-- a reimplementation would eventually lie, and a preview that lies is worse than no
-- preview at all (§3.4).
--
--   p_office_id  the office, or NULL for a hypothetical one (plan preview)
--   p_plan_id    force a plan, or NULL to derive it from the office's license
--
-- Recursion: the dependency gate calls this function for each prerequisite. The
-- cycle trigger on platform_feature_dependencies is what makes that safe.

create or replace function public.platform_resolve_feature(
  p_office_id uuid,
  p_plan_id   uuid,
  p_key       text
) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_f          public.platform_features;
  v_settings   public.platform_settings;
  v_license    public.office_licenses;
  v_plan_id    uuid;
  v_plan_key   text;
  v_value      jsonb;
  v_source     text;
  v_expires    timestamptz;
  v_blocked    text;
  v_dep        record;
  v_dep_val    jsonb;
  v_snapshot   jsonb;
  v_lic_status text := 'none';
  v_hold       boolean := false;
begin
  select * into v_f from public.platform_features where key = p_key;
  if not found then
    raise exception 'unknown_feature' using detail = p_key;
  end if;

  select * into v_settings from public.platform_settings where id;

  ---------------------------------------------------------------- rung 0: kill switch
  -- A platform-wide off switch. `disabled` means the platform withdrew the feature
  -- from everyone at once, so no plan value and no override can bring it back.
  if v_f.status = 'disabled' then
    return jsonb_build_object(
      'key', p_key, 'value', v_f.default_value, 'value_type', v_f.value_type,
      'source', 'kill_switch', 'blocked_by', null,
      'plan_key', null, 'license_status', v_lic_status, 'expires_at', null);
  end if;

  if p_office_id is not null then
    select * into v_license from public.office_licenses where office_id = p_office_id;
    if found then
      v_lic_status := v_license.status;
      v_hold := v_license.status in ('suspended','cancelled','expired');
    end if;
  end if;

  ------------------------------------------------------------- effective plan choice
  if p_plan_id is not null then
    v_plan_id := p_plan_id;                       -- preview / forced
  elsif v_hold then
    -- Rung 1. NOT "everything off": what a suspended office keeps is read from a
    -- designated fallback plan, so it is an editable commercial decision rather
    -- than a hardcoded one (§4.3).
    v_plan_id := coalesce(v_settings.restricted_plan_id, v_license.plan_id);
  elsif v_license.office_id is not null then
    v_plan_id := v_license.plan_id;
  else
    -- F5: an office can exist with no license row, because office_self_signup
    -- creates one without a platform admin in the loop. "No license" is not an
    -- error state — it is the default plan.
    v_plan_id := v_settings.default_signup_plan_id;
  end if;

  select key into v_plan_key from public.platform_plans where id = v_plan_id;

  if v_hold and p_plan_id is null then
    ------------------------------------------------------------- rung 1: license hold
    -- Deliberately skips the override rung: a concession granted last month must
    -- not survive suspension.
    select pf.value into v_value
      from public.platform_plan_features pf
     where pf.plan_id = v_plan_id and pf.feature_key = p_key;
    v_value  := coalesce(v_value, v_f.default_value);
    v_source := 'license_hold';

  else
    ---------------------------------------------------------------- rung 2: override
    if p_office_id is not null and p_plan_id is null then
      select o.value, o.expires_at into v_value, v_expires
        from public.office_feature_overrides o
       where o.office_id = p_office_id
         and o.feature_key = p_key
         and (o.expires_at is null or o.expires_at > now());
      if v_value is not null then
        v_source := 'override';
      end if;
    end if;

    ------------------------------------------------------------------- rung 3: plan
    if v_source is null and v_plan_id is not null then
      if v_license.pinned_revision_id is not null and p_plan_id is null then
        -- Grandfathering: read the frozen snapshot instead of the live plan.
        select r.snapshot into v_snapshot
          from public.platform_plan_revisions r
         where r.id = v_license.pinned_revision_id;
        v_value := v_snapshot -> 'features' -> p_key;
      else
        select pf.value into v_value
          from public.platform_plan_features pf
         where pf.plan_id = v_plan_id and pf.feature_key = p_key;
      end if;

      if v_value is not null then
        v_source := 'plan';
      end if;
    end if;

    ---------------------------------------------------------------- rung 4: catalog
    if v_source is null then
      v_value  := v_f.default_value;
      v_source := 'default';
    end if;
  end if;

  --------------------------------------------------------------- gate 5: dependencies
  -- Only ever subtracts. If cashback requires wallet and wallet is off, cashback is
  -- off even when an explicit override says true — the override IS honoured at rung
  -- 2 and then defeated here, and both facts are reported (`source` stays 'override',
  -- `blocked_by` names the prerequisite) so the console can say exactly that instead
  -- of appearing to ignore the operator.
  for v_dep in
    select requires_key, min_value
      from public.platform_feature_dependencies
     where feature_key = p_key
  loop
    v_dep_val := public.platform_resolve_feature(p_office_id, p_plan_id, v_dep.requires_key) -> 'value';
    if not public.platform_value_meets(v_dep.requires_key, v_dep_val, v_dep.min_value) then
      v_blocked := v_dep.requires_key;
      exit;
    end if;
  end loop;

  if v_blocked is not null then
    v_value := public.platform_collapsed_value(p_key);
  end if;

  return jsonb_build_object(
    'key',            p_key,
    'value',          v_value,
    'value_type',     v_f.value_type,
    'source',         v_source,
    'blocked_by',     v_blocked,
    'plan_key',       v_plan_key,
    'license_status', v_lic_status,
    'expires_at',     v_expires);
end;
$$;

comment on function public.platform_resolve_feature(uuid, uuid, text) is
  'The entitlement ladder. `source` in the result is not decoration: it is what lets '
  'the console answer "why does this office have this?" in one click, and what makes '
  'a support conversation two minutes instead of twenty.';


-- Trigger-facing variant: takes an explicit office because a trigger runs in the
-- ROW's context, not the caller's. Revoked from every API role at the bottom of this
-- file, so it cannot be used to probe another office's entitlements.
create or replace function public.office_feature_for(p_office_id uuid, p_key text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select public.platform_resolve_feature(p_office_id, null, p_key);
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Usage meters (§5.1, §5.2)
-- ═══════════════════════════════════════════════════════════════════════════════════

-- The office's billing period key. `office_wallet_policies.timezone` already exists
-- and already means exactly this, so a month boundary is the same instant for the
-- wallet's daily caps and for a licensing meter.
create or replace function public.office_period_key(p_office_id uuid, p_period text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select case
    when p_period = 'month' then
      to_char(now() at time zone coalesce(
        (select w.timezone from public.office_wallet_policies w where w.office_id = p_office_id),
        'Africa/Cairo'), 'YYYY-MM')
    else 'lifetime'
  end;
$$;


-- STOCK: counted at check time, never stored.
--
-- The honest cost of the stock/flow split (§5.2): adding a metered stock feature
-- touches this CASE. That is a real limit on "no schema redesign" and it is named
-- rather than hidden. It is accepted because the alternative — storing the count SQL
-- as data and EXECUTEing it — is a SQL-injection surface owned by the console's own
-- input fields.
create or replace function public.office_usage_stock(p_office_id uuid, p_key text)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select case p_key
    when 'max_drivers' then
      (select count(*) from public.drivers d
        where d.office_id = p_office_id and d.status = 'active')
    when 'max_vehicles' then
      (select count(*) from public.vehicles v where v.office_id = p_office_id)
    when 'max_routes' then
      (select count(*) from public.operation_routes r where r.office_id = p_office_id)
    when 'max_admin_users' then
      (select count(*) from public.office_users u
        where u.office_id = p_office_id and u.status = 'active')
    when 'max_captains' then
      (select count(*) from public.drivers d
        where d.office_id = p_office_id and d.user_id is not null and d.status = 'active')
    when 'max_live_trips' then
      (select count(*) from public.operation_trips t
        where t.office_id = p_office_id and t.status in ('boarding','in_progress'))
    when 'max_storage_mb' then
      -- Best-effort: every bucket follows the `<office_id>/…` prefix convention the
      -- office-logos policy established.
      (select coalesce(sum((o.metadata ->> 'size')::bigint), 0) / 1048576
         from storage.objects o
        where (storage.foldername(o.name))[1] = p_office_id::text)
    else 0::bigint
  end;
$$;


-- FLOW: an accumulating counter. Deleting the row it counted does NOT refund it —
-- otherwise an office on a 100-trip plan runs 1,000 trips by deleting each one after
-- it completes.
create or replace function public.office_usage_flow(p_office_id uuid, p_key text)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select c.used_value
       from public.office_usage_counters c
       join public.platform_features f on f.key = c.metric_key
      where c.office_id = p_office_id
        and c.metric_key = p_key
        and c.period_key = public.office_period_key(p_office_id, f.meter_period)),
    0::bigint);
$$;


create or replace function public.office_usage_for(p_office_id uuid, p_key text)
returns bigint
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_kind text;
begin
  select meter_kind into v_kind from public.platform_features where key = p_key;
  if v_kind = 'stock' then
    return public.office_usage_stock(p_office_id, p_key);
  elsif v_kind = 'flow' then
    return public.office_usage_flow(p_office_id, p_key);
  end if;
  return 0;
end;
$$;


-- Increment a flow meter. Called by the same trigger that enforces it, in the same
-- transaction as the row it counts. A no-op for stock meters by construction.
create or replace function public.office_usage_record(
  p_office_id uuid,
  p_key       text,
  p_amount    bigint default 1
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_period text;
begin
  select public.office_period_key(p_office_id, f.meter_period) into v_period
    from public.platform_features f
   where f.key = p_key and f.meter_kind = 'flow';

  if v_period is null then
    return;
  end if;

  insert into public.office_usage_counters (office_id, metric_key, period_key, used_value)
  values (p_office_id, p_key, v_period, greatest(p_amount, 0))
  on conflict (office_id, metric_key, period_key) do update
    set used_value = office_usage_counters.used_value + excluded.used_value,
        updated_at = now();
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 7. VERB 2 — the write verdict (§4.4)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Separate from office_feature() because reading "is wallet on" for a nav item and
-- asking "may I create driver 11" have different costs (one does a COUNT), different
-- callers (UI vs trigger) and different failure modes.

create or replace function public.office_can_consume_for(
  p_office_id uuid,
  p_key       text,
  p_amount    bigint default 1
) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_res       jsonb;
  v_type      text;
  v_value     jsonb;
  v_limit     bigint;
  v_used      bigint;
  v_unlimited boolean := false;
  v_allowed   boolean;
  v_reason    text := null;
begin
  v_res   := public.platform_resolve_feature(p_office_id, null, p_key);
  v_type  := v_res ->> 'value_type';
  v_value := v_res -> 'value';

  -- A non-limit feature has no quota; the verdict degenerates to "is it on".
  if v_type <> 'limit' then
    v_allowed := public.platform_value_is_truthy(v_value);
    if not v_allowed then
      v_reason := case
        when v_res ->> 'blocked_by' is not null then 'dependency_blocked'
        when v_res ->> 'source' = 'license_hold' then 'license_suspended'
        else 'feature_not_licensed'
      end;
    end if;
    return jsonb_build_object(
      'allowed', v_allowed, 'limit', null, 'used', null, 'remaining', null,
      'unlimited', false, 'reason', v_reason, 'feature', p_key,
      'plan_key', v_res ->> 'plan_key', 'source', v_res ->> 'source',
      'blocked_by', v_res ->> 'blocked_by',
      'license_status', v_res ->> 'license_status');
  end if;

  v_used := public.office_usage_for(p_office_id, p_key);

  if (v_value #>> '{}') = 'unlimited' then
    v_unlimited := true;
    v_allowed   := true;
  else
    v_limit   := (v_value #>> '{}')::bigint;
    v_allowed := (v_used + greatest(p_amount, 0)) <= v_limit;
    if not v_allowed then
      v_reason := case
        when v_res ->> 'blocked_by' is not null then 'dependency_blocked'
        when v_res ->> 'source' = 'license_hold' then 'license_suspended'
        else 'quota_exceeded'
      end;
    end if;
  end if;

  return jsonb_build_object(
    'allowed',   v_allowed,
    'limit',     case when v_unlimited then null else v_limit end,
    'used',      v_used,
    'remaining', case when v_unlimited then null else greatest(v_limit - v_used, 0) end,
    'unlimited', v_unlimited,
    'reason',    v_reason,
    'feature',   p_key,
    'plan_key',  v_res ->> 'plan_key',
    'source',    v_res ->> 'source',
    'blocked_by', v_res ->> 'blocked_by',
    'license_status', v_res ->> 'license_status');
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 8. Caller-facing verbs — no office parameter, by construction (§13.4)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- There is no value a caller can pass to read another office's entitlements. The
-- office comes from current_office_id(), exactly as OfficeContext's doc comment
-- describes for the Dart side.

create or replace function public.office_feature(p_key text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  return public.platform_resolve_feature(v_office, null, p_key);
end;
$$;

create or replace function public.office_feature_value(p_key text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select public.office_feature(p_key) -> 'value';
$$;

-- Boolean sugar: the 90% case, and the one safe to reference from an RLS policy.
-- Returns FALSE rather than raising for a non-office caller, because a policy
-- expression that raises turns every guarded query into an error instead of an
-- empty result.
create or replace function public.office_has(p_key text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
begin
  if v_office is null then
    return false;
  end if;
  return public.platform_value_is_truthy(
    public.platform_resolve_feature(v_office, null, p_key) -> 'value');
end;
$$;

create or replace function public.office_can_consume(p_key text, p_amount bigint default 1)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  return public.office_can_consume_for(v_office, p_key, p_amount);
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 9. The document (§4.5) — one round trip, called once at sign-in
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.platform_license_document(p_office_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_license public.office_licenses;
  v_plan    public.platform_plans;
  v_lic     jsonb;
  v_features jsonb := '{}'::jsonb;
  v_f       record;
  v_res     jsonb;
  v_used    bigint;
begin
  select * into v_license from public.office_licenses where office_id = p_office_id;

  if found then
    select * into v_plan from public.platform_plans where id = v_license.plan_id;
    v_lic := jsonb_build_object(
      'plan_key',      v_plan.key,
      'plan_name_ar',  v_plan.name_ar,
      'status',        v_license.status,
      'billing_cycle', v_license.billing_cycle,
      'price',         coalesce(v_license.price_override,
                                case v_license.billing_cycle
                                  when 'yearly' then v_plan.price_yearly
                                  else v_plan.price_monthly
                                end),
      'currency',      v_license.currency,
      'trial_ends_at', v_license.trial_ends_at,
      'period_start',  v_license.period_start,
      'period_end',    v_license.period_end,
      'grace_ends_at', v_license.grace_ends_at,
      'auto_renew',    v_license.auto_renew,
      'contract_ref',  v_license.contract_ref,
      'suspended_reason', v_license.suspended_reason);
  else
    -- F5 again: no license is the default plan, not an error.
    select p.* into v_plan
      from public.platform_plans p
      join public.platform_settings s on s.default_signup_plan_id = p.id;
    v_lic := jsonb_build_object(
      'plan_key',     v_plan.key,
      'plan_name_ar', v_plan.name_ar,
      'status',       'none',
      'billing_cycle', null,
      'auto_renew',   false);
  end if;

  for v_f in
    select f.key, f.value_type, f.name_ar, f.category_key, f.unit_ar,
           f.is_public, f.enforcement_status, f.meter_kind, f.sort_order
      from public.platform_features f
     where f.status <> 'hidden'
     order by f.category_key, f.sort_order
  loop
    v_res := public.platform_resolve_feature(p_office_id, null, v_f.key);

    if v_f.value_type = 'limit' then
      v_used := public.office_usage_for(p_office_id, v_f.key);
      v_res := v_res || jsonb_build_object(
        'used', v_used,
        'remaining', case
          when (v_res #>> '{value}') = 'unlimited' then null
          else greatest((v_res #>> '{value}')::bigint - v_used, 0)
        end);
    end if;

    v_features := v_features || jsonb_build_object(
      v_f.key,
      v_res || jsonb_build_object(
        'name_ar',      v_f.name_ar,
        'category_key', v_f.category_key,
        'unit_ar',      v_f.unit_ar,
        'is_public',    v_f.is_public,
        'enforcement_status', v_f.enforcement_status,
        'meter_kind',   v_f.meter_kind,
        'sort_order',   v_f.sort_order));
  end loop;

  return jsonb_build_object(
    'license',     v_lic,
    'features',    v_features,
    'enforcement_mode', public.platform_enforcement_mode(),
    'resolved_at', now());
end;
$$;


create or replace function public.office_entitlements()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  return public.platform_license_document(v_office);
end;
$$;

comment on function public.office_entitlements() is
  'Every feature resolved for the caller''s office, plus usage and the license '
  'summary, in one round trip. Loaded at sign-in exactly like current_office_context. '
  'A client-side HINT, nothing more — every write it enables is re-checked server-side.';


-- The office's own billing screen. Same document, minus the per-feature noise.
create or replace function public.office_license_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
  v_doc    jsonb;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  v_doc := public.platform_license_document(v_office);
  return jsonb_build_object(
    'license', v_doc -> 'license',
    'limits',  (select coalesce(jsonb_object_agg(k, v), '{}'::jsonb)
                  from jsonb_each(v_doc -> 'features') e(k, v)
                 where v ->> 'value_type' = 'limit'),
    'resolved_at', v_doc -> 'resolved_at');
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 10. Backfill (§15.2 step 3) — every existing office onto `founder`
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Three live offices, all currently unlimited. They land on a plan that is unlimited
-- in every dimension, is_public = false so nobody can accidentally select it, on a
-- perpetual custom cycle with auto_renew off so no billing job ever touches them.
--
-- THEY NEVER LOSE ANYTHING. Same guarantee the multi-office migration gave the
-- incumbent office.

insert into public.office_licenses
  (office_id, plan_id, status, billing_cycle, period_start, period_end, auto_renew, notes)
select o.id,
       (select id from public.platform_plans where key = 'founder'),
       'active', 'custom', now(), null, false,
       'ترحيل: مكتب قائم قبل نظام التراخيص — كل القدرات بلا حدود، بلا فوترة.'
  from public.offices o
 where not exists (select 1 from public.office_licenses l where l.office_id = o.id)
on conflict (office_id) do nothing;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 11. RLS and grants (§13.3, §13.4)
-- ═══════════════════════════════════════════════════════════════════════════════════

alter table public.office_licenses          enable row level security;
alter table public.office_feature_overrides enable row level security;
alter table public.office_usage_counters    enable row level security;

drop policy if exists office_licenses_read on public.office_licenses;
create policy office_licenses_read on public.office_licenses
  for select to authenticated
  using (office_id = public.current_office_id() or public.is_platform_admin());

drop policy if exists office_overrides_read on public.office_feature_overrides;
create policy office_overrides_read on public.office_feature_overrides
  for select to authenticated
  using (office_id = public.current_office_id() or public.is_platform_admin());

drop policy if exists office_usage_read on public.office_usage_counters;
create policy office_usage_read on public.office_usage_counters
  for select to authenticated
  using (office_id = public.current_office_id() or public.is_platform_admin());

-- No insert / update / delete policy on any of the three, for anyone. Writes happen
-- exclusively through security definer RPCs, so the only path is the audited one.
revoke all on public.office_licenses          from anon, authenticated;
revoke all on public.office_feature_overrides from anon, authenticated;
revoke all on public.office_usage_counters    from anon, authenticated;

grant select on public.office_licenses          to authenticated;
grant select on public.office_feature_overrides to authenticated;
grant select on public.office_usage_counters    to authenticated;

-- The explicit-office variants exist for triggers only. Revoked from every API role
-- so they cannot be used to probe another office's limits.
revoke all on function public.platform_resolve_feature(uuid, uuid, text)   from public, anon, authenticated;
revoke all on function public.office_feature_for(uuid, text)               from public, anon, authenticated;
revoke all on function public.office_can_consume_for(uuid, text, bigint)   from public, anon, authenticated;
revoke all on function public.office_usage_stock(uuid, text)               from public, anon, authenticated;
revoke all on function public.office_usage_flow(uuid, text)                from public, anon, authenticated;
revoke all on function public.office_usage_for(uuid, text)                 from public, anon, authenticated;
revoke all on function public.office_usage_record(uuid, text, bigint)      from public, anon, authenticated;
revoke all on function public.office_period_key(uuid, text)                from public, anon, authenticated;
revoke all on function public.platform_license_document(uuid)              from public, anon, authenticated;
revoke all on function public.platform_collapsed_value(text)               from public, anon, authenticated;
revoke all on function public.platform_value_meets(text, jsonb, jsonb)     from public, anon, authenticated;

revoke all on function public.office_feature(text)                  from public, anon;
revoke all on function public.office_feature_value(text)            from public, anon;
revoke all on function public.office_has(text)                      from public, anon;
revoke all on function public.office_can_consume(text, bigint)      from public, anon;
revoke all on function public.office_entitlements()                 from public, anon;
revoke all on function public.office_license_summary()              from public, anon;
revoke all on function public.platform_value_is_truthy(jsonb)       from public, anon;

grant execute on function public.office_feature(text)               to authenticated;
grant execute on function public.office_feature_value(text)         to authenticated;
grant execute on function public.office_can_consume(text, bigint)   to authenticated;
grant execute on function public.office_entitlements()              to authenticated;
grant execute on function public.office_license_summary()           to authenticated;
grant execute on function public.platform_value_is_truthy(jsonb)    to authenticated;

-- office_has() is referenced from RLS policy expressions (Phase 6), which are
-- evaluated with the querying role's privileges — the trap documented in
-- 20260721140000 §2. A revoked function in a policy turns every guarded query into a
-- permission error instead of an empty result, so both API roles get it.
grant execute on function public.office_has(text) to anon, authenticated;
