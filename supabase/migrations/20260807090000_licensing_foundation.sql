-- ═══════════════════════════════════════════════════════════════════════════════════
-- EWT Entitlement Platform — Phase 1/6: the foundation
--
-- Design: docs/architecture/PLATFORM_LICENSING.md §3.1–§3.4, §3.8, Part 15 step 1.
--
-- What this establishes:
--
--   1. platform_settings          — the singleton kill switch. Ships 'off'.
--   2. platform_feature_categories— console grouping, as data.
--   3. platform_features          — the catalog: what the platform CAN sell.
--   4. platform_feature_dependencies — prerequisites, FK-enforced, cycle-guarded.
--   5. platform_feature_gates     — "where is this actually enforced", as data.
--   6. platform_plans             — named bundles of default values.
--   7. platform_plan_features     — a plan's values. Absence = catalog default.
--   8. platform_plan_revisions    — append-only snapshot before every plan edit.
--   9. platform_license_audit     — append-only decision trail, written by triggers.
--
-- ── The naming law (§1.2 F2), restated because it has no flexibility ────────────────
--
-- `packages` / `transport_packages` / `subscriptions` / `transport_subscriptions`
-- already exist and mean PASSENGER FARE BUNDLES. The licensing domain says `plan`
-- and `license`, prefixed `platform_` (catalog side) or `office_` (tenant side).
-- The strings "package" and "subscription" do not appear in this subsystem, in SQL
-- or in Dart.
--
-- ── Why jsonb values rather than typed columns (§2.3) ───────────────────────────────
--
-- The requirement is "add future features without schema redesign". A typed-column
-- table costs a migration + a model + a mapper + a UI change per feature. So values
-- are jsonb and the type safety moves INTO the catalog: `value_type` declares the
-- shape, `value_schema` constrains it, and platform_validate_feature_value() is
-- called by a BEFORE trigger on every table that stores one.
--
-- It has to be a trigger and not a CHECK constraint because validation requires a
-- lookup in platform_features, and CHECK cannot subquery. Stated here so nobody
-- "fixes" it into a constraint later.
--
-- ── Deploy-day behaviour ────────────────────────────────────────────────────────────
--
-- Zero. This migration creates tables nothing reads yet and leaves
-- platform_settings.enforcement_mode = 'off'. Phase 2 adds resolution; Phase 4 adds
-- enforcement. Rollback up to Phase 5 is `drop table`.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. platform_plans — created first because platform_settings points at two of them
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.platform_plans (
  id             uuid primary key default gen_random_uuid(),

  -- Stable family identifier. Survives renames; referenced by seeds, tests and the
  -- settings table. The name is display; the key is identity.
  key            text not null unique
                   check (key ~ '^[a-z][a-z0-9_-]{2,47}$'),

  name_ar        text not null,
  name_en        text not null,
  tagline_ar     text not null default '',

  status         text not null default 'draft'
                   check (status in ('draft','active','archived')),

  -- Can an office land on this by self-selection, or is it assignment-only?
  -- `founder`, `enterprise` and `restricted` are is_public = false.
  is_public      boolean not null default false,

  -- Nullable because 'custom' and 'free' cycles have no list price.
  price_monthly  numeric(12,2) check (price_monthly >= 0),
  price_yearly   numeric(12,2) check (price_yearly  >= 0),
  currency       text not null default 'EGP',

  trial_days     int not null default 0 check (trial_days between 0 and 365),

  -- Where an office falls when its license lapses. Self-reference, nullable to
  -- terminate the chain.
  downgrade_to_plan_id uuid references public.platform_plans(id) on delete restrict,

  sort_order     int not null default 100,
  notes          text not null default '',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

comment on table public.platform_plans is
  'A named bundle of default feature values. A plan is a TEMPLATE WITH NO BEHAVIOUR: '
  'it holds no logic, conditions or code, which is what makes it safe to edit live. '
  'Anything a plan "does" is a value the resolver reads.';

drop trigger if exists update_platform_plans_updated_at on public.platform_plans;
create trigger update_platform_plans_updated_at
  before update on public.platform_plans
  for each row execute function public.update_updated_at_column();


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. platform_settings — the singleton, and the kill switch
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.platform_settings (
  -- Singleton by construction: one row, and the PK CHECK makes a second impossible.
  id boolean primary key default true check (id),

  -- The kill switch (§0 decision 8, Part 15).
  --   off       — resolvers answer, nothing enforces. Current behaviour, exactly.
  --   shadow    — enforcement points evaluate and LOG, block nothing.
  --   enforcing — enforcement points block.
  -- Moving between them is a one-row UPDATE. No deploy disables this subsystem.
  enforcement_mode text not null default 'off'
                     check (enforcement_mode in ('off','shadow','enforcing')),

  -- The fallback plan resolved for suspended / cancelled offices (§4.3). NOT
  -- hardcoded: what a suspended office keeps is a commercial decision, so it is
  -- a plan the owner can edit like any other.
  restricted_plan_id     uuid references public.platform_plans(id) on delete restrict,

  -- What a self-registered office lands on (§15.2 step 6).
  default_signup_plan_id uuid references public.platform_plans(id) on delete restrict,

  -- Days between past_due and suspended (§14.3). Data, because it is negotiable.
  grace_days       int not null default 7 check (grace_days between 0 and 90),

  -- Days before trial/period end that a warning alert is emitted.
  warn_days_before int not null default 7 check (warn_days_before between 0 and 60),

  updated_at timestamptz not null default now()
);

comment on table public.platform_settings is
  'Singleton. enforcement_mode is the subsystem kill switch: setting it to ''off'' '
  'restores pre-licensing behaviour instantly, without a deploy.';

insert into public.platform_settings (id) values (true) on conflict (id) do nothing;

drop trigger if exists update_platform_settings_updated_at on public.platform_settings;
create trigger update_platform_settings_updated_at
  before update on public.platform_settings
  for each row execute function public.update_updated_at_column();


-- Read by every enforcement point. STABLE and tiny, so it costs one cached lookup
-- per statement even when called from a per-row trigger.
create or replace function public.platform_enforcement_mode()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select s.enforcement_mode from public.platform_settings s where s.id), 'off');
$$;

comment on function public.platform_enforcement_mode() is
  'off | shadow | enforcing. Every quota trigger and feature guard returns early when off.';


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. The catalog
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Categories are data so the console grows sections without a deploy.
create table if not exists public.platform_feature_categories (
  key         text primary key check (key ~ '^[a-z][a-z0-9_]{2,31}$'),
  name_ar     text not null,
  icon_key    text not null default '',
  sort_order  int  not null default 100
);


create table if not exists public.platform_features (
  key                text primary key
                       check (key ~ '^[a-z][a-z0-9_]{2,63}$'),

  name_ar            text not null,
  name_en            text not null,
  description_ar     text not null default '',

  category_key       text not null references public.platform_feature_categories(key)
                       on delete restrict,

  value_type         text not null
                       check (value_type in ('boolean','limit','enum','config')),

  -- Shape constraint beyond value_type.
  --   enum   {"allowed": ["basic","pro"]}
  --   limit  {"min": 0, "max": 100000}
  --   config {"kind": "url"} | {"kind": "int"} | {"kind": "text"}
  value_schema       jsonb not null default '{}'::jsonb,

  -- The bottom rung of the resolution ladder (§4.1 rung 4). Applies when no
  -- override and no plan value produced one. MUST be the safe answer, because it
  -- is also what a platform-wide kill switch resolves to.
  default_value      jsonb not null,

  -- Lifecycle of the FEATURE ITSELF, distinct from whether an office has it.
  --   active     — sellable, resolvable
  --   hidden     — resolvable, not offered in the plan builder (internal / beta)
  --   deprecated — resolvable, warns in the console, not addable to new plans
  --   disabled   — platform kill switch: resolves to default_value for EVERYONE
  status             text not null default 'active'
                       check (status in ('active','hidden','deprecated','disabled')),

  -- Is the flag real, or a promise? (§0 decision 7.) DERIVED from
  -- platform_feature_gates by trigger — never written by hand, so the console's
  -- badge cannot drift from what the code actually does.
  enforcement_status text not null default 'declared'
                       check (enforcement_status in ('enforced','declared')),

  -- Purchasable by an office on some higher plan? Decides hidden-vs-locked in the
  -- nav (§7.4): hiding a purchasable feature makes it unsellable, and showing an
  -- unpurchasable one is noise.
  is_public          boolean not null default true,

  -- Metering discriminator (§5.2). Getting this wrong is the classic quota bug.
  --   stock — a COUNT of live rows; deleting a row returns quota
  --   flow  — an accumulating counter per period; deletion does NOT refund
  meter_kind         text check (meter_kind in ('stock','flow')),
  meter_period       text check (meter_period in ('lifetime','month')),
  unit_ar            text not null default '',

  sort_order         int  not null default 100,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),

  -- A limit must declare how it is metered; a non-limit must not pretend to be one.
  constraint platform_features_meter_coherent check (
    (value_type = 'limit' and meter_kind is not null and meter_period is not null)
    or (value_type <> 'limit' and meter_kind is null and meter_period is null)
  )
);

comment on table public.platform_features is
  'The feature catalog: what the platform can sell. `key` is the primary key rather '
  'than a surrogate uuid because feature keys appear in trigger bodies, RPC guards, '
  'Dart constants and audit rows, and a uuid would be unreadable in every one.';

comment on column public.platform_features.enforcement_status is
  'Derived from platform_feature_gates by trigger. enforced = at least one real gate '
  'exists; declared = catalogued and sellable in principle, no code gates it yet.';

create index if not exists idx_platform_features_category
  on public.platform_features (category_key, sort_order);

drop trigger if exists update_platform_features_updated_at on public.platform_features;
create trigger update_platform_features_updated_at
  before update on public.platform_features
  for each row execute function public.update_updated_at_column();


-- Dependencies: a table rather than an array column, so it is joinable, FK-enforced,
-- and can carry a minimum value rather than only "requires".
create table if not exists public.platform_feature_dependencies (
  feature_key   text not null references public.platform_features(key) on delete cascade,
  requires_key  text not null references public.platform_features(key) on delete restrict,

  -- For non-boolean prerequisites: analytics_ai requires analytics_level >= 'advanced'.
  -- NULL means "requires truthy".
  min_value     jsonb,

  primary key (feature_key, requires_key),
  constraint no_self_dependency check (feature_key <> requires_key)
);


-- "View where they are used" (the brief) as real data rather than a doc comment.
-- Populated by the migration that adds each gate; read by the console.
create table if not exists public.platform_feature_gates (
  id           bigserial primary key,
  feature_key  text not null references public.platform_features(key) on delete cascade,
  gate_kind    text not null check (gate_kind in ('trigger','rpc','rls','view','ui')),
  gate_ref     text not null,
  note         text not null default '',
  unique (feature_key, gate_kind, gate_ref)
);

comment on table public.platform_feature_gates is
  'Every place a feature is actually enforced. The console reads this for the "أين '
  'تُستخدم" panel, and a trigger derives platform_features.enforcement_status from it.';


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. enforcement_status is derived, in both directions
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.platform_feature_gate_sync()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_key text := coalesce(new.feature_key, old.feature_key);
begin
  update public.platform_features f
     set enforcement_status = case
           when exists (select 1 from public.platform_feature_gates g
                         where g.feature_key = v_key) then 'enforced'
           else 'declared'
         end
   where f.key = v_key
     and f.enforcement_status is distinct from case
           when exists (select 1 from public.platform_feature_gates g
                         where g.feature_key = v_key) then 'enforced'
           else 'declared'
         end;
  return null;
end;
$$;

drop trigger if exists trg_feature_gate_sync on public.platform_feature_gates;
create trigger trg_feature_gate_sync
  after insert or update or delete on public.platform_feature_gates
  for each row execute function public.platform_feature_gate_sync();


-- The other direction: a hand-written enforcement_status on the feature row is
-- overwritten by the truth. There is exactly one source for this column.
create or replace function public.platform_feature_derive_enforcement()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.enforcement_status := case
    when exists (select 1 from public.platform_feature_gates g
                  where g.feature_key = new.key) then 'enforced'
    else 'declared'
  end;
  return new;
end;
$$;

drop trigger if exists trg_feature_derive_enforcement on public.platform_features;
create trigger trg_feature_derive_enforcement
  before insert or update on public.platform_features
  for each row execute function public.platform_feature_derive_enforcement();


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. Dependency cycle guard
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- A cycle in the dependency graph makes the resolver recurse forever, which is a
-- platform-wide outage rather than a bad row. The graph is tens of edges, so a
-- recursive walk on every insert is free.

create or replace function public.platform_feature_dependency_no_cycle()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    with recursive walk(k) as (
      select new.requires_key
      union
      select d.requires_key
        from public.platform_feature_dependencies d
        join walk w on d.feature_key = w.k
    )
    select 1 from walk where k = new.feature_key
  ) then
    raise exception 'feature_dependency_cycle'
      using detail = new.feature_key || ' -> ' || new.requires_key;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_feature_dependency_no_cycle on public.platform_feature_dependencies;
create trigger trg_feature_dependency_no_cycle
  before insert or update on public.platform_feature_dependencies
  for each row execute function public.platform_feature_dependency_no_cycle();


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Value validation (§2.3) — the type safety that jsonb gave up
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Called by a BEFORE INSERT OR UPDATE trigger on EVERY table that stores a feature
-- value: plan values here, office overrides in Phase 2. One function, so "what is a
-- valid value for this feature" has exactly one answer.

create or replace function public.platform_validate_feature_value(
  p_key   text,
  p_value jsonb
) returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_feature public.platform_features;
  v_type    text;
  v_num     numeric;
begin
  select * into v_feature from public.platform_features where key = p_key;
  if not found then
    raise exception 'unknown_feature' using detail = p_key;
  end if;

  if p_value is null or jsonb_typeof(p_value) = 'null' then
    -- JSON null is never a value. "No value" is the ABSENCE of a row, which is a
    -- different rung of the ladder (§2.4).
    raise exception 'feature_value_null' using detail = p_key;
  end if;

  v_type := jsonb_typeof(p_value);

  case v_feature.value_type

    when 'boolean' then
      if v_type <> 'boolean' then
        raise exception 'feature_value_type_mismatch'
          using detail = p_key || ': expected boolean, got ' || v_type;
      end if;

    when 'limit' then
      -- An integer, or the JSON string "unlimited". Never -1, never null (§2.4):
      -- -1 is a magic number arithmetic silently accepts, and null is
      -- indistinguishable from "no row" once it reaches Dart.
      if v_type = 'string' then
        if p_value #>> '{}' <> 'unlimited' then
          raise exception 'feature_value_invalid_limit'
            using detail = p_key || ': the only permitted string is "unlimited"';
        end if;
      elsif v_type = 'number' then
        v_num := (p_value #>> '{}')::numeric;
        if v_num <> trunc(v_num) or v_num < 0 then
          raise exception 'feature_value_invalid_limit'
            using detail = p_key || ': a limit is a non-negative integer or "unlimited"';
        end if;
        if v_feature.value_schema ? 'min'
           and v_num < (v_feature.value_schema ->> 'min')::numeric then
          raise exception 'feature_value_below_min'
            using detail = p_key || ': min ' || (v_feature.value_schema ->> 'min');
        end if;
        if v_feature.value_schema ? 'max'
           and v_num > (v_feature.value_schema ->> 'max')::numeric then
          raise exception 'feature_value_above_max'
            using detail = p_key || ': max ' || (v_feature.value_schema ->> 'max');
        end if;
      else
        raise exception 'feature_value_type_mismatch'
          using detail = p_key || ': expected a limit, got ' || v_type;
      end if;

    when 'enum' then
      if v_type <> 'string' then
        raise exception 'feature_value_type_mismatch'
          using detail = p_key || ': expected a string, got ' || v_type;
      end if;
      if not (v_feature.value_schema ? 'allowed') then
        raise exception 'feature_schema_incomplete'
          using detail = p_key || ': enum features must declare value_schema.allowed';
      end if;
      if not (v_feature.value_schema -> 'allowed' @> jsonb_build_array(p_value #>> '{}')) then
        raise exception 'feature_value_not_allowed'
          using detail = p_key || ': ' || (p_value #>> '{}');
      end if;

    when 'config' then
      -- Open by design: a webhook url, a byte cap, a retention window. Only
      -- objects and arrays are refused, because a config value has to render in
      -- one form field.
      if v_type in ('object','array') then
        raise exception 'feature_value_type_mismatch'
          using detail = p_key || ': a config value must be scalar';
      end if;
      if (v_feature.value_schema ->> 'kind') = 'int' and v_type = 'number' then
        v_num := (p_value #>> '{}')::numeric;
        if v_num <> trunc(v_num) then
          raise exception 'feature_value_type_mismatch'
            using detail = p_key || ': expected an integer';
        end if;
      end if;

  end case;
end;
$$;

comment on function public.platform_validate_feature_value(text, jsonb) is
  'The type safety that jsonb values gave up, moved into the catalog. A trigger and '
  'not a CHECK constraint because validation needs a lookup in platform_features and '
  'CHECK cannot subquery — do not "fix" this into a constraint.';


create or replace function public.platform_feature_value_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.platform_validate_feature_value(new.feature_key, new.value);
  return new;
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 7. platform_plan_features + revisions
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.platform_plan_features (
  plan_id      uuid not null references public.platform_plans(id) on delete cascade,

  -- restrict, not cascade: deleting a catalogued feature that plans reference must
  -- fail loudly. Deprecate features; never delete them.
  feature_key  text not null references public.platform_features(key) on delete restrict,

  value        jsonb not null,
  primary key (plan_id, feature_key)
);

comment on table public.platform_plan_features is
  'A plan''s default configuration. The ABSENCE of a row means "fall through to the '
  'catalog default" — it does not mean off.';

drop trigger if exists trg_plan_feature_value_valid on public.platform_plan_features;
create trigger trg_plan_feature_value_valid
  before insert or update on public.platform_plan_features
  for each row execute function public.platform_feature_value_guard();


-- Append-only snapshot of a plan's full state before each edit. Compare, audit,
-- rollback and grandfathering all read from here (§2.5).
create table if not exists public.platform_plan_revisions (
  id          uuid primary key default gen_random_uuid(),
  plan_id     uuid not null references public.platform_plans(id) on delete restrict,
  revision    int  not null,
  snapshot    jsonb not null,          -- {plan: {...}, features: {key: value, …}}
  changed_by  uuid references auth.users(id) on delete set null,
  reason      text not null default '',
  created_at  timestamptz not null default now(),
  unique (plan_id, revision)
);

create index if not exists idx_plan_revisions_plan
  on public.platform_plan_revisions (plan_id, revision desc);

comment on table public.platform_plan_revisions is
  'History plus an escape hatch, not parallel live variants. Plan edits propagate '
  'immediately by design; office_licenses.pinned_revision_id freezes one office to a '
  'past revision, and exists so grandfathering is later a UI task, not a migration.';


-- Snapshot helper. Used by the plan-write RPC (Phase 3) and callable from a test.
create or replace function public.platform_plan_snapshot(p_plan_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'plan', to_jsonb(p) - 'created_at' - 'updated_at',
    'features', coalesce(
      (select jsonb_object_agg(pf.feature_key, pf.value)
         from public.platform_plan_features pf where pf.plan_id = p.id),
      '{}'::jsonb)
  )
  from public.platform_plans p where p.id = p_plan_id;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 8. platform_license_audit (§3.8) — the first actor-attributed log on the platform
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.platform_license_audit (
  id           bigserial primary key,

  -- The office affected. NULL for catalog and plan changes, which are platform-wide.
  office_id    uuid references public.offices(id) on delete restrict,

  entity_type  text not null
                 check (entity_type in ('feature','category','plan','plan_feature',
                                        'license','override','invoice','usage','settings')),
  entity_ref   text not null,

  action       text not null
                 check (action in ('created','updated','deleted','enabled','disabled',
                                   'plan_changed','limit_changed','override_created',
                                   'override_removed','trial_started','trial_extended',
                                   'renewed','suspended','restored','cancelled')),

  old_value    jsonb,
  new_value    jsonb,

  actor_id     uuid references auth.users(id) on delete set null,
  actor_label  text not null default '',   -- denormalised: survives actor deletion
  reason       text not null default '',

  -- Best-effort, PostgREST path only (F9). NEVER a security control: anything that
  -- can set X-Forwarded-For upstream of the edge can set this.
  ip           inet,
  user_agent   text,

  created_at   timestamptz not null default now()
);

create index if not exists idx_license_audit_office
  on public.platform_license_audit (office_id, created_at desc);
create index if not exists idx_license_audit_entity
  on public.platform_license_audit (entity_type, entity_ref, created_at desc);
create index if not exists idx_license_audit_created
  on public.platform_license_audit (created_at desc);

comment on table public.platform_license_audit is
  'Append-only licensing decision trail, written by TRIGGERS rather than by callers — '
  'an audit log a caller can forget to write is not an audit log. No hash chain: the '
  'wallet ledger has one because it records money that must reconcile; the '
  'reconciliation target for a decision is the invoice it produced (§13.5).';


-- Who did it, in a form that survives the actor being deleted.
create or replace function public.platform_actor_label()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid   uuid := auth.uid();
  v_label text;
begin
  if v_uid is null then
    return 'النظام';
  end if;

  select coalesce(nullif(btrim(ou.full_name), ''), ou.username)
    into v_label
    from public.office_users ou
   where ou.user_id = v_uid and ou.status = 'active'
   limit 1;

  if v_label is not null then
    return v_label;
  end if;

  if exists (select 1 from public.platform_admins where user_id = v_uid) then
    return 'مدير المنصة';
  end if;

  return 'مستخدم';
end;
$$;


-- Advisory request context (F9). Returns (ip, user_agent), both NULL off the
-- PostgREST path. Isolated in one function so no caller repeats the exception
-- handling, and so the "never a control" rule has one place to be stated.
create or replace function public.platform_request_context()
returns jsonb
language plpgsql
stable
as $$
declare
  v_headers json;
begin
  begin
    v_headers := nullif(current_setting('request.headers', true), '')::json;
  exception when others then
    v_headers := null;
  end;

  return jsonb_build_object(
    'ip', nullif(split_part(coalesce(v_headers ->> 'x-forwarded-for', ''), ',', 1), ''),
    'user_agent', nullif(v_headers ->> 'user-agent', ''));
end;
$$;


-- The single audit writer. Every licensing RPC and trigger funnels through it, so
-- there is one shape for "a licensing decision was made".
create or replace function public.platform_audit_write(
  p_office_id   uuid,
  p_entity_type text,
  p_entity_ref  text,
  p_action      text,
  p_old_value   jsonb default null,
  p_new_value   jsonb default null,
  p_reason      text  default ''
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ctx jsonb := public.platform_request_context();
begin
  insert into public.platform_license_audit
    (office_id, entity_type, entity_ref, action,
     old_value, new_value, actor_id, actor_label, reason, ip, user_agent)
  values
    (p_office_id, p_entity_type, p_entity_ref, p_action,
     p_old_value, p_new_value, auth.uid(), public.platform_actor_label(),
     coalesce(p_reason, ''),
     (v_ctx ->> 'ip')::inet, v_ctx ->> 'user_agent');
end;
$$;


-- Generic row-level audit trigger. tg_argv[0] = entity_type, tg_argv[1] = the column
-- carrying entity_ref. office_id is picked up automatically when the row has one.
create or replace function public.platform_audit_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_entity text  := tg_argv[0];
  v_refcol text  := tg_argv[1];
  v_row    jsonb := to_jsonb(coalesce(new, old));
  v_action text;
  v_old    jsonb;
  v_new    jsonb;
begin
  v_action := case tg_op
    when 'INSERT' then 'created'
    when 'UPDATE' then 'updated'
    else 'deleted'
  end;

  if tg_op <> 'INSERT' then v_old := to_jsonb(old); end if;
  if tg_op <> 'DELETE' then v_new := to_jsonb(new); end if;

  -- An UPDATE that changed nothing anyone can see is not a decision.
  if tg_op = 'UPDATE' and (v_old - 'updated_at') = (v_new - 'updated_at') then
    return null;
  end if;

  perform public.platform_audit_write(
    nullif(v_row ->> 'office_id', '')::uuid,
    v_entity,
    coalesce(v_row ->> v_refcol, ''),
    v_action,
    v_old,
    v_new,
    coalesce(current_setting('bmt.licensing_reason', true), ''));

  return null;
end;
$$;

drop trigger if exists trg_audit_features on public.platform_features;
create trigger trg_audit_features
  after insert or update or delete on public.platform_features
  for each row execute function public.platform_audit_trigger('feature', 'key');

drop trigger if exists trg_audit_categories on public.platform_feature_categories;
create trigger trg_audit_categories
  after insert or update or delete on public.platform_feature_categories
  for each row execute function public.platform_audit_trigger('category', 'key');

drop trigger if exists trg_audit_plans on public.platform_plans;
create trigger trg_audit_plans
  after insert or update or delete on public.platform_plans
  for each row execute function public.platform_audit_trigger('plan', 'key');

drop trigger if exists trg_audit_plan_features on public.platform_plan_features;
create trigger trg_audit_plan_features
  after insert or update or delete on public.platform_plan_features
  for each row execute function public.platform_audit_trigger('plan_feature', 'feature_key');

drop trigger if exists trg_audit_settings on public.platform_settings;
create trigger trg_audit_settings
  after update on public.platform_settings
  for each row execute function public.platform_audit_trigger('settings', 'id');


-- Immutability: belt and braces, matching the wallet ledger. The revoke stops the
-- API roles; the trigger binds the table owner too, so removing evidence requires
-- disabling a trigger — which is itself a schema change, and therefore detectable.
create or replace function public.platform_audit_append_only()
returns trigger
language plpgsql
as $$
begin
  raise exception 'audit_is_append_only';
end;
$$;

drop trigger if exists trg_license_audit_append_only on public.platform_license_audit;
create trigger trg_license_audit_append_only
  before update or delete on public.platform_license_audit
  for each row execute function public.platform_audit_append_only();

drop trigger if exists trg_plan_revisions_append_only on public.platform_plan_revisions;
create trigger trg_plan_revisions_append_only
  before update or delete on public.platform_plan_revisions
  for each row execute function public.platform_audit_append_only();


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 9. RLS and grants (§13.3)
-- ═══════════════════════════════════════════════════════════════════════════════════

alter table public.platform_settings            enable row level security;
alter table public.platform_feature_categories  enable row level security;
alter table public.platform_features            enable row level security;
alter table public.platform_feature_dependencies enable row level security;
alter table public.platform_feature_gates       enable row level security;
alter table public.platform_plans               enable row level security;
alter table public.platform_plan_features       enable row level security;
alter table public.platform_plan_revisions      enable row level security;
alter table public.platform_license_audit       enable row level security;

-- Catalog and plans are READABLE by any authenticated operator: an office may
-- legitimately learn what exists and what it could buy. Drafts are platform-only,
-- because a draft plan is an unfinished commercial decision.
drop policy if exists platform_features_read on public.platform_features;
create policy platform_features_read on public.platform_features
  for select to authenticated using (true);

drop policy if exists platform_feature_categories_read on public.platform_feature_categories;
create policy platform_feature_categories_read on public.platform_feature_categories
  for select to authenticated using (true);

drop policy if exists platform_feature_dependencies_read on public.platform_feature_dependencies;
create policy platform_feature_dependencies_read on public.platform_feature_dependencies
  for select to authenticated using (true);

-- Gates name internal triggers and functions. That is platform plumbing, not a
-- customer-facing fact.
drop policy if exists platform_feature_gates_read on public.platform_feature_gates;
create policy platform_feature_gates_read on public.platform_feature_gates
  for select to authenticated using (public.is_platform_admin());

drop policy if exists platform_plans_read on public.platform_plans;
create policy platform_plans_read on public.platform_plans
  for select to authenticated
  using (status <> 'draft' or public.is_platform_admin());

drop policy if exists platform_plan_features_read on public.platform_plan_features;
create policy platform_plan_features_read on public.platform_plan_features
  for select to authenticated
  using (exists (select 1 from public.platform_plans p
                  where p.id = plan_id
                    and (p.status <> 'draft' or public.is_platform_admin())));

drop policy if exists platform_plan_revisions_read on public.platform_plan_revisions;
create policy platform_plan_revisions_read on public.platform_plan_revisions
  for select to authenticated using (public.is_platform_admin());

drop policy if exists platform_license_audit_read on public.platform_license_audit;
create policy platform_license_audit_read on public.platform_license_audit
  for select to authenticated using (public.is_platform_admin());

drop policy if exists platform_settings_read on public.platform_settings;
create policy platform_settings_read on public.platform_settings
  for select to authenticated using (public.is_platform_admin());

-- No INSERT / UPDATE / DELETE policy exists on ANY table above, for any role. RLS
-- alone therefore denies every mutation, and the only write path is a SECURITY
-- DEFINER RPC that audits itself. Same construction office_payment_configs uses.
--
-- TRUNCATE is never filtered by RLS — the lesson recorded in the Phase 6 tracking
-- work. Revoke it explicitly rather than relying on the policies above.
revoke all on public.platform_settings             from anon, authenticated;
revoke all on public.platform_feature_categories   from anon, authenticated;
revoke all on public.platform_features             from anon, authenticated;
revoke all on public.platform_feature_dependencies from anon, authenticated;
revoke all on public.platform_feature_gates        from anon, authenticated;
revoke all on public.platform_plans                from anon, authenticated;
revoke all on public.platform_plan_features        from anon, authenticated;
revoke all on public.platform_plan_revisions       from anon, authenticated;
revoke all on public.platform_license_audit        from anon, authenticated;

grant select on public.platform_settings             to authenticated;
grant select on public.platform_feature_categories   to authenticated;
grant select on public.platform_features             to authenticated;
grant select on public.platform_feature_dependencies to authenticated;
grant select on public.platform_feature_gates        to authenticated;
grant select on public.platform_plans                to authenticated;
grant select on public.platform_plan_features        to authenticated;
grant select on public.platform_plan_revisions       to authenticated;
grant select on public.platform_license_audit        to authenticated;

revoke all on function public.platform_validate_feature_value(text, jsonb) from public, anon, authenticated;
revoke all on function public.platform_plan_snapshot(uuid)                 from public, anon, authenticated;
revoke all on function public.platform_audit_write(uuid, text, text, text, jsonb, jsonb, text)
  from public, anon, authenticated;
revoke all on function public.platform_actor_label()      from public, anon, authenticated;
revoke all on function public.platform_request_context()  from public, anon, authenticated;

-- Granted to authenticated because Phase 4's guards call it from paths that run as
-- the caller. It leaks one word about the platform's own rollout state and nothing
-- about any office.
grant execute on function public.platform_enforcement_mode() to authenticated;
