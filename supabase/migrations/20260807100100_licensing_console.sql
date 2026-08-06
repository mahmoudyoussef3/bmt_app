-- ═══════════════════════════════════════════════════════════════════════════════════
-- EWT Entitlement Platform — Phase 3/6 (server): the platform-admin console surface
--
-- Design: docs/architecture/PLATFORM_LICENSING.md Part 8, §3.4, §3.9, §9.
--
-- Every function here begins with the same guard `platform_list_offices` uses:
--
--     if not public.is_platform_admin() then raise exception 'platform_admin_required';
--
-- `is_platform_admin()` is the ONLY identity that may write anything in this
-- subsystem (§13.1). No new identity concept is introduced.
--
-- Every function returns `jsonb`, following the precedent set by
-- platform_office_details and the wallet RPCs, and every mutating one publishes its
-- reason into `bmt.licensing_reason` so the audit triggers written in Phase 1 pick it
-- up. The reason is captured by the TRIGGER, not by the caller — an audit log a
-- caller can forget to write is not an audit log.
--
-- ── The one change to an existing table (§3.9) ─────────────────────────────────────
--
-- `offices.licensing_hold` ships here, INERT: it is maintained by a trigger on
-- office_licenses from this migration onward, and nothing reads it until Phase 6
-- adds one term to office_is_listed(). It exists because office_is_listed() is
-- called from RLS policies on the hottest anon read path in the Client app, and
-- joining office_licenses → platform_plans → platform_plan_features inside every
-- marketplace policy is a real cost for an answer that changes twice a year per
-- office. This is the one place the design deliberately denormalises.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. offices.licensing_hold — the projection of the license state machine
-- ═══════════════════════════════════════════════════════════════════════════════════

alter table public.offices
  add column if not exists licensing_hold text
    check (licensing_hold in ('none','read_only','delisted'));

comment on column public.offices.licensing_hold is
  'Denormalised consequence of office_licenses.status, maintained by trigger. NULL is '
  'read as ''none''. Exists so office_is_listed() — an RLS predicate on the hottest '
  'anon read path — gains one cheap term instead of a three-table join (§3.9).';

-- The license status → hold projection, in one place (§14.3).
create or replace function public.license_hold_for_status(p_status text)
returns text
language sql
immutable
as $$
  select case p_status
    when 'suspended' then 'delisted'
    when 'cancelled' then 'delisted'
    when 'expired'   then 'read_only'
    else 'none'
  end;
$$;

create or replace function public.office_license_project_hold()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.offices
     set licensing_hold = public.license_hold_for_status(new.status)
   where id = new.office_id
     and coalesce(licensing_hold, 'none')
         is distinct from public.license_hold_for_status(new.status);
  return null;
end;
$$;

drop trigger if exists trg_license_project_hold on public.office_licenses;
create trigger trg_license_project_hold
  after insert or update of status on public.office_licenses
  for each row execute function public.office_license_project_hold();

-- Backfill the column for the licenses Phase 2 created.
update public.offices o
   set licensing_hold = public.license_hold_for_status(l.status)
  from public.office_licenses l
 where l.office_id = o.id
   and coalesce(o.licensing_hold, 'none')
       is distinct from public.license_hold_for_status(l.status);

update public.offices set licensing_hold = 'none' where licensing_hold is null;

-- Platform-owned, exactly like listing_status: an office lifting its own billing
-- hold would defeat the point.
revoke update (licensing_hold) on public.offices from anon, authenticated;
grant select (licensing_hold) on public.offices to anon, authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. Shared guard
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.assert_platform_admin()
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'platform_admin_required';
  end if;
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. Catalog reads
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.platform_feature_catalog()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();

  return jsonb_build_object(
    'categories', coalesce((
      select jsonb_agg(to_jsonb(c) order by c.sort_order, c.key)
        from public.platform_feature_categories c), '[]'::jsonb),

    'features', coalesce((
      select jsonb_agg(
        to_jsonb(f)
        || jsonb_build_object(
             -- "أين تُستخدم": the real triggers, RPCs and policies behind the flag.
             'gates', coalesce((
               select jsonb_agg(jsonb_build_object(
                        'gate_kind', g.gate_kind, 'gate_ref', g.gate_ref, 'note', g.note)
                      order by g.gate_kind, g.gate_ref)
                 from public.platform_feature_gates g where g.feature_key = f.key), '[]'::jsonb),
             -- Both directions, so the console can warn that disabling this would
             -- collapse others.
             'requires', coalesce((
               select jsonb_agg(jsonb_build_object('key', d.requires_key, 'min_value', d.min_value))
                 from public.platform_feature_dependencies d where d.feature_key = f.key), '[]'::jsonb),
             'required_by', coalesce((
               select jsonb_agg(d.feature_key)
                 from public.platform_feature_dependencies d where d.requires_key = f.key), '[]'::jsonb),
             'plan_count', (
               select count(*) from public.platform_plan_features pf where pf.feature_key = f.key),
             'override_count', (
               select count(*) from public.office_feature_overrides o where o.feature_key = f.key),
             -- "الأثر": how many offices currently resolve to each value.
             'impact', coalesce((
               select jsonb_object_agg(x.v, x.n) from (
                 select (public.office_feature_for(o.id, f.key) #>> '{value}') v, count(*) n
                   from public.offices o group by 1) x), '{}'::jsonb))
        order by f.category_key, f.sort_order, f.key)
      from public.platform_features f), '[]'::jsonb));
end;
$$;


create or replace function public.platform_upsert_feature(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_key text := p_payload ->> 'key';
  v_row public.platform_features;
begin
  perform public.assert_platform_admin();
  perform set_config('bmt.licensing_reason', coalesce(p_payload ->> 'reason', ''), true);

  if v_key is null then
    raise exception 'feature_key_required';
  end if;

  insert into public.platform_features as f
    (key, name_ar, name_en, description_ar, category_key, value_type, value_schema,
     default_value, status, is_public, meter_kind, meter_period, unit_ar, sort_order)
  values (
    v_key,
    coalesce(p_payload ->> 'name_ar', v_key),
    coalesce(p_payload ->> 'name_en', v_key),
    coalesce(p_payload ->> 'description_ar', ''),
    p_payload ->> 'category_key',
    p_payload ->> 'value_type',
    coalesce(p_payload -> 'value_schema', '{}'::jsonb),
    coalesce(p_payload -> 'default_value', 'false'::jsonb),
    coalesce(p_payload ->> 'status', 'active'),
    coalesce((p_payload ->> 'is_public')::boolean, true),
    p_payload ->> 'meter_kind',
    p_payload ->> 'meter_period',
    coalesce(p_payload ->> 'unit_ar', ''),
    coalesce((p_payload ->> 'sort_order')::int, 100))
  on conflict (key) do update set
    name_ar        = coalesce(p_payload ->> 'name_ar',        f.name_ar),
    name_en        = coalesce(p_payload ->> 'name_en',        f.name_en),
    description_ar = coalesce(p_payload ->> 'description_ar', f.description_ar),
    category_key   = coalesce(p_payload ->> 'category_key',   f.category_key),
    -- value_type and the meter columns are NOT editable after creation: changing
    -- them would invalidate every plan value and every counter already stored
    -- against the key. Deprecate the feature and add a new one instead.
    value_schema   = coalesce(p_payload -> 'value_schema',    f.value_schema),
    default_value  = coalesce(p_payload -> 'default_value',   f.default_value),
    status         = coalesce(p_payload ->> 'status',         f.status),
    is_public      = coalesce((p_payload ->> 'is_public')::boolean, f.is_public),
    unit_ar        = coalesce(p_payload ->> 'unit_ar',        f.unit_ar),
    sort_order     = coalesce((p_payload ->> 'sort_order')::int, f.sort_order)
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;


create or replace function public.platform_set_feature_status(p_key text, p_status text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.platform_features;
begin
  perform public.assert_platform_admin();
  perform set_config('bmt.licensing_reason',
    case p_status when 'disabled' then 'مفتاح إيقاف على مستوى المنصة' else '' end, true);

  update public.platform_features set status = p_status
   where key = p_key returning * into v_row;

  if not found then
    raise exception 'unknown_feature' using detail = p_key;
  end if;
  return to_jsonb(v_row);
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. Plan reads
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.platform_list_plans()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();

  return coalesce((
    select jsonb_agg(
      to_jsonb(p)
      || jsonb_build_object(
           'office_count', (select count(*) from public.office_licenses l where l.plan_id = p.id),
           'feature_count', (select count(*) from public.platform_plan_features pf where pf.plan_id = p.id),
           'revision', (select coalesce(max(r.revision), 0)
                          from public.platform_plan_revisions r where r.plan_id = p.id),
           'downgrade_to_key', (select d.key from public.platform_plans d
                                 where d.id = p.downgrade_to_plan_id))
      order by p.sort_order, p.key)
    from public.platform_plans p), '[]'::jsonb);
end;
$$;


create or replace function public.platform_plan_detail(p_plan_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_plan public.platform_plans;
begin
  perform public.assert_platform_admin();

  select * into v_plan from public.platform_plans where id = p_plan_id;
  if not found then raise exception 'plan_not_found'; end if;

  return jsonb_build_object(
    'plan', to_jsonb(v_plan),
    'features', coalesce((
      select jsonb_object_agg(pf.feature_key, pf.value)
        from public.platform_plan_features pf where pf.plan_id = p_plan_id), '{}'::jsonb),
    'offices', coalesce((
      select jsonb_agg(jsonb_build_object('office_id', o.id, 'name', o.name,
                                          'status', l.status)
             order by o.name)
        from public.office_licenses l join public.offices o on o.id = l.office_id
       where l.plan_id = p_plan_id), '[]'::jsonb),
    'revisions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', r.id, 'revision', r.revision, 'reason', r.reason,
               'created_at', r.created_at, 'snapshot', r.snapshot)
             order by r.revision desc)
        from public.platform_plan_revisions r where r.plan_id = p_plan_id), '[]'::jsonb));
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. Plan writes — every one snapshots a revision first (§2.5)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Plan edits propagate to every subscribed office IMMEDIATELY, because the resolver
-- reads plan values at resolution time and there is no per-office copy to keep in
-- sync. The revision is what makes that safe: compare, audit, rollback, and the
-- grandfathering hook (office_licenses.pinned_revision_id) all read from it.

create or replace function public.platform_save_plan(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id       uuid := nullif(p_payload ->> 'id', '')::uuid;
  v_key      text := p_payload ->> 'key';
  v_reason   text := coalesce(p_payload ->> 'reason', '');
  v_plan     public.platform_plans;
  v_features jsonb := p_payload -> 'features';
  v_entry    record;
begin
  perform public.assert_platform_admin();
  perform set_config('bmt.licensing_reason', v_reason, true);

  -- Snapshot BEFORE anything changes, so a revision is always the state that was
  -- replaced rather than the state that replaced it.
  if v_id is not null and exists (select 1 from public.platform_plans where id = v_id) then
    insert into public.platform_plan_revisions (plan_id, revision, snapshot, changed_by, reason)
    select v_id,
           coalesce((select max(revision) from public.platform_plan_revisions r
                      where r.plan_id = v_id), 0) + 1,
           public.platform_plan_snapshot(v_id),
           auth.uid(),
           v_reason;
  end if;

  insert into public.platform_plans as p
    (id, key, name_ar, name_en, tagline_ar, status, is_public,
     price_monthly, price_yearly, currency, trial_days, downgrade_to_plan_id,
     sort_order, notes)
  values (
    coalesce(v_id, gen_random_uuid()),
    v_key,
    coalesce(p_payload ->> 'name_ar', v_key),
    coalesce(p_payload ->> 'name_en', v_key),
    coalesce(p_payload ->> 'tagline_ar', ''),
    coalesce(p_payload ->> 'status', 'draft'),
    coalesce((p_payload ->> 'is_public')::boolean, false),
    nullif(p_payload ->> 'price_monthly', '')::numeric,
    nullif(p_payload ->> 'price_yearly', '')::numeric,
    coalesce(p_payload ->> 'currency', 'EGP'),
    coalesce((p_payload ->> 'trial_days')::int, 0),
    nullif(p_payload ->> 'downgrade_to_plan_id', '')::uuid,
    coalesce((p_payload ->> 'sort_order')::int, 100),
    coalesce(p_payload ->> 'notes', ''))
  on conflict (id) do update set
    key                  = coalesce(p_payload ->> 'key', p.key),
    name_ar              = coalesce(p_payload ->> 'name_ar', p.name_ar),
    name_en              = coalesce(p_payload ->> 'name_en', p.name_en),
    tagline_ar           = coalesce(p_payload ->> 'tagline_ar', p.tagline_ar),
    status               = coalesce(p_payload ->> 'status', p.status),
    is_public            = coalesce((p_payload ->> 'is_public')::boolean, p.is_public),
    price_monthly        = case when p_payload ? 'price_monthly'
                                then nullif(p_payload ->> 'price_monthly', '')::numeric
                                else p.price_monthly end,
    price_yearly         = case when p_payload ? 'price_yearly'
                                then nullif(p_payload ->> 'price_yearly', '')::numeric
                                else p.price_yearly end,
    currency             = coalesce(p_payload ->> 'currency', p.currency),
    trial_days           = coalesce((p_payload ->> 'trial_days')::int, p.trial_days),
    downgrade_to_plan_id = case when p_payload ? 'downgrade_to_plan_id'
                                then nullif(p_payload ->> 'downgrade_to_plan_id', '')::uuid
                                else p.downgrade_to_plan_id end,
    sort_order           = coalesce((p_payload ->> 'sort_order')::int, p.sort_order),
    notes                = coalesce(p_payload ->> 'notes', p.notes)
  returning * into v_plan;

  -- Feature values are replaced wholesale when the payload carries them, so
  -- REMOVING a key from the map means "fall through to the catalog default" —
  -- which is a different thing from setting it false, and the console says so.
  if v_features is not null and jsonb_typeof(v_features) = 'object' then
    delete from public.platform_plan_features pf
     where pf.plan_id = v_plan.id
       and not (v_features ? pf.feature_key);

    for v_entry in select key, value from jsonb_each(v_features) loop
      insert into public.platform_plan_features (plan_id, feature_key, value)
      values (v_plan.id, v_entry.key, v_entry.value)
      on conflict (plan_id, feature_key) do update set value = excluded.value;
    end loop;
  end if;

  return public.platform_plan_detail(v_plan.id);
end;
$$;


create or replace function public.platform_clone_plan(
  p_plan_id  uuid,
  p_new_key  text,
  p_new_name text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new uuid;
begin
  perform public.assert_platform_admin();
  perform set_config('bmt.licensing_reason', 'نسخ من باقة قائمة', true);

  insert into public.platform_plans
    (key, name_ar, name_en, tagline_ar, status, is_public,
     price_monthly, price_yearly, currency, trial_days, downgrade_to_plan_id,
     sort_order, notes)
  select p_new_key, p_new_name, p_new_name, p.tagline_ar,
         'draft',          -- a clone is never live on arrival
         false,
         p.price_monthly, p.price_yearly, p.currency, p.trial_days,
         p.downgrade_to_plan_id, p.sort_order + 1,
         'نسخة من: ' || p.key
    from public.platform_plans p where p.id = p_plan_id
  returning id into v_new;

  if v_new is null then raise exception 'plan_not_found'; end if;

  insert into public.platform_plan_features (plan_id, feature_key, value)
  select v_new, pf.feature_key, pf.value
    from public.platform_plan_features pf where pf.plan_id = p_plan_id;

  return public.platform_plan_detail(v_new);
end;
$$;


-- Feature × plan matrix. Values come from the REAL resolver run against each plan,
-- so a compare cannot disagree with what an office on that plan would actually get.
create or replace function public.platform_compare_plans(p_plan_ids uuid[])
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();

  return jsonb_build_object(
    'plans', coalesce((
      select jsonb_agg(jsonb_build_object('id', p.id, 'key', p.key, 'name_ar', p.name_ar)
             order by p.sort_order)
        from public.platform_plans p where p.id = any(p_plan_ids)), '[]'::jsonb),
    'rows', coalesce((
      select jsonb_agg(jsonb_build_object(
               'key', f.key, 'name_ar', f.name_ar, 'category_key', f.category_key,
               'value_type', f.value_type,
               'values', (select jsonb_object_agg(p.key,
                                   public.platform_resolve_feature(null, p.id, f.key) -> 'value')
                            from public.platform_plans p where p.id = any(p_plan_ids)))
             order by f.category_key, f.sort_order)
        from public.platform_features f where f.status <> 'hidden'), '[]'::jsonb));
end;
$$;


-- "Preview effective permissions": the SAME resolver against a hypothetical office on
-- this plan with no overrides. A reimplementation would eventually drift, and a
-- preview that lies is worse than none.
create or replace function public.platform_preview_plan(p_plan_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();

  return coalesce((
    select jsonb_object_agg(f.key,
             public.platform_resolve_feature(null, p_plan_id, f.key)
             || jsonb_build_object('name_ar', f.name_ar,
                                   'category_key', f.category_key,
                                   'unit_ar', f.unit_ar,
                                   'enforcement_status', f.enforcement_status,
                                   'sort_order', f.sort_order))
      from public.platform_features f where f.status <> 'hidden'), '{}'::jsonb);
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Office license: read, assign, suspend, trial
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.platform_office_license(p_office_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();

  return jsonb_build_object(
    'office', (select jsonb_build_object(
                 'id', o.id, 'name', o.name, 'slug', o.slug,
                 'status', o.status, 'listing_status', o.listing_status,
                 'licensing_hold', coalesce(o.licensing_hold, 'none'))
                 from public.offices o where o.id = p_office_id),
    'entitlements', public.platform_license_document(p_office_id),
    'overrides', coalesce((
      select jsonb_agg(jsonb_build_object(
               'feature_key', ov.feature_key,
               'name_ar', f.name_ar,
               'category_key', f.category_key,
               'value_type', f.value_type,
               'value', ov.value,
               -- The direction the console renders as ▲ upgrade / ▼ restriction.
               'plan_value', public.platform_resolve_feature(null,
                               (select l.plan_id from public.office_licenses l
                                 where l.office_id = p_office_id), ov.feature_key) -> 'value',
               'reason', ov.reason,
               'expires_at', ov.expires_at,
               'expired', ov.expires_at is not null and ov.expires_at <= now(),
               'created_at', ov.created_at)
             order by f.category_key, f.sort_order)
        from public.office_feature_overrides ov
        join public.platform_features f on f.key = ov.feature_key
       where ov.office_id = p_office_id), '[]'::jsonb),
    'activity', coalesce((
      select jsonb_agg(to_jsonb(a) order by a.created_at desc)
        from (select * from public.platform_license_audit
               where office_id = p_office_id
               order by created_at desc limit 50) a), '[]'::jsonb));
end;
$$;


create or replace function public.platform_assign_plan(
  p_office_id uuid,
  p_plan_id   uuid,
  p_cycle     text  default 'monthly',
  p_options   jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reason text := coalesce(p_options ->> 'reason', '');
  v_plan   public.platform_plans;
  v_trial  int;
  v_status text;
begin
  perform public.assert_platform_admin();
  perform set_config('bmt.licensing_reason', v_reason, true);

  select * into v_plan from public.platform_plans where id = p_plan_id;
  if not found then raise exception 'plan_not_found'; end if;
  if v_plan.status = 'archived' then raise exception 'plan_archived'; end if;

  v_trial  := coalesce((p_options ->> 'trial_days')::int, 0);
  v_status := case when v_trial > 0 then 'trialing' else 'active' end;

  insert into public.office_licenses as l
    (office_id, plan_id, status, billing_cycle, price_override, currency,
     trial_ends_at, period_start, period_end, auto_renew, contract_ref, notes)
  values (
    p_office_id, p_plan_id, v_status, p_cycle,
    nullif(p_options ->> 'price_override', '')::numeric,
    coalesce(p_options ->> 'currency', v_plan.currency),
    case when v_trial > 0 then now() + make_interval(days => v_trial) end,
    now(),
    case p_cycle
      when 'monthly' then now() + interval '1 month'
      when 'yearly'  then now() + interval '1 year'
      else null
    end,
    coalesce((p_options ->> 'auto_renew')::boolean, p_cycle in ('monthly','yearly')),
    nullif(p_options ->> 'contract_ref', ''),
    coalesce(p_options ->> 'notes', ''))
  on conflict (office_id) do update set
    plan_id        = excluded.plan_id,
    -- A plan change lifts a hold: assigning a plan IS the restore action.
    status         = excluded.status,
    billing_cycle  = excluded.billing_cycle,
    price_override = excluded.price_override,
    currency       = excluded.currency,
    trial_ends_at  = excluded.trial_ends_at,
    period_start   = excluded.period_start,
    period_end     = excluded.period_end,
    auto_renew     = excluded.auto_renew,
    contract_ref   = coalesce(excluded.contract_ref, l.contract_ref),
    notes          = case when coalesce(excluded.notes, '') = '' then l.notes else excluded.notes end,
    suspended_at   = null,
    suspended_reason = null;

  perform public.platform_audit_write(
    p_office_id, 'license', p_office_id::text, 'plan_changed',
    null, jsonb_build_object('plan_key', v_plan.key, 'cycle', p_cycle), v_reason);

  perform public.push_operational_alert(
    'license_plan_changed',
    'تغيّرت باقة المكتب',
    'الباقة الحالية: ' || v_plan.name_ar,
    jsonb_build_object('plan_key', v_plan.key),
    'normal', '/settings/billing', p_office_id);

  return public.platform_office_license(p_office_id);
end;
$$;


create or replace function public.platform_set_license_status(
  p_office_id uuid,
  p_status    text,
  p_reason    text default ''
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old text;
begin
  perform public.assert_platform_admin();

  if p_status in ('suspended','cancelled') and length(btrim(coalesce(p_reason,''))) < 8 then
    raise exception 'reason_required';
  end if;

  perform set_config('bmt.licensing_reason', coalesce(p_reason, ''), true);

  select status into v_old from public.office_licenses where office_id = p_office_id;
  if v_old is null then raise exception 'license_not_found'; end if;

  update public.office_licenses
     set status           = p_status,
         suspended_at     = case when p_status = 'suspended' then now() end,
         suspended_reason = case when p_status in ('suspended','cancelled')
                                 then btrim(p_reason) end,
         trial_ends_at    = case when p_status = 'trialing' then trial_ends_at end
   where office_id = p_office_id;

  perform public.platform_audit_write(
    p_office_id, 'license', p_office_id::text,
    case p_status
      when 'suspended' then 'suspended'
      when 'cancelled' then 'cancelled'
      when 'active'    then 'restored'
      else 'updated'
    end,
    jsonb_build_object('status', v_old),
    jsonb_build_object('status', p_status),
    coalesce(p_reason, ''));

  -- Suspension DEGRADES; it never blacks out. The office keeps serving passengers
  -- who already hold tickets and its captains keep driving (§4.3, Part 11). The
  -- alert says what to do about it rather than simply announcing the punishment.
  perform public.push_operational_alert(
    'license_' || p_status,
    case p_status
      when 'suspended' then 'تم إيقاف ترخيص المكتب مؤقتًا'
      when 'cancelled' then 'تم إلغاء ترخيص المكتب'
      when 'active'    then 'تم استئناف ترخيص المكتب'
      else 'تغيّرت حالة ترخيص المكتب'
    end,
    case p_status
      when 'suspended' then 'الحساب في وضع القراءة فقط: الرحلات القائمة والتذاكر المُباعة تكمل كالمعتاد، ولا يمكن إنشاء جديد. ' || coalesce(btrim(p_reason), '')
      when 'active'    then 'عادت كل القدرات كما كانت.'
      else coalesce(btrim(p_reason), '')
    end,
    jsonb_build_object('status', p_status),
    case when p_status in ('suspended','cancelled') then 'high' else 'normal' end,
    '/settings/billing', p_office_id);

  return public.platform_office_license(p_office_id);
end;
$$;


create or replace function public.platform_start_trial(
  p_office_id uuid,
  p_plan_id   uuid,
  p_days      int default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_days int;
begin
  perform public.assert_platform_admin();

  select coalesce(p_days, trial_days) into v_days
    from public.platform_plans where id = p_plan_id;
  if v_days is null then raise exception 'plan_not_found'; end if;
  if v_days <= 0 then raise exception 'trial_days_required'; end if;

  perform public.platform_assign_plan(
    p_office_id, p_plan_id, 'monthly',
    jsonb_build_object('trial_days', v_days, 'reason', 'بدء فترة تجريبية'));

  perform public.platform_audit_write(
    p_office_id, 'license', p_office_id::text, 'trial_started',
    null, jsonb_build_object('days', v_days), 'بدء فترة تجريبية');

  return public.platform_office_license(p_office_id);
end;
$$;


create or replace function public.platform_extend_trial(
  p_office_id uuid,
  p_days      int,
  p_reason    text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old timestamptz;
  v_new timestamptz;
begin
  perform public.assert_platform_admin();
  if length(btrim(coalesce(p_reason,''))) < 8 then raise exception 'reason_required'; end if;
  perform set_config('bmt.licensing_reason', p_reason, true);

  select trial_ends_at into v_old from public.office_licenses
   where office_id = p_office_id and status = 'trialing';
  if v_old is null then raise exception 'not_trialing'; end if;

  v_new := greatest(v_old, now()) + make_interval(days => greatest(p_days, 1));

  update public.office_licenses set trial_ends_at = v_new where office_id = p_office_id;

  perform public.platform_audit_write(
    p_office_id, 'license', p_office_id::text, 'trial_extended',
    jsonb_build_object('trial_ends_at', v_old),
    jsonb_build_object('trial_ends_at', v_new), p_reason);

  return public.platform_office_license(p_office_id);
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 7. Overrides
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.platform_set_override(
  p_office_id  uuid,
  p_key        text,
  p_value      jsonb,
  p_reason     text,
  p_expires_at timestamptz default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();

  -- The reason is enforced by a CHECK on the table too. It is repeated here so the
  -- caller gets a machine code rather than a constraint-violation string.
  if length(btrim(coalesce(p_reason,''))) < 8 then
    raise exception 'reason_required';
  end if;
  perform set_config('bmt.licensing_reason', p_reason, true);

  insert into public.office_feature_overrides
    (office_id, feature_key, value, reason, expires_at, created_by)
  values (p_office_id, p_key, p_value, btrim(p_reason), p_expires_at, auth.uid())
  on conflict (office_id, feature_key) do update set
    value      = excluded.value,
    reason     = excluded.reason,
    expires_at = excluded.expires_at,
    created_by = excluded.created_by;

  perform public.platform_audit_write(
    p_office_id, 'override', p_key, 'override_created',
    null, jsonb_build_object('value', p_value, 'expires_at', p_expires_at), p_reason);

  return public.platform_office_license(p_office_id);
end;
$$;


create or replace function public.platform_clear_override(
  p_office_id uuid,
  p_key       text,
  p_reason    text default ''
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old jsonb;
begin
  perform public.assert_platform_admin();
  perform set_config('bmt.licensing_reason', coalesce(p_reason, ''), true);

  select value into v_old from public.office_feature_overrides
   where office_id = p_office_id and feature_key = p_key;

  delete from public.office_feature_overrides
   where office_id = p_office_id and feature_key = p_key;

  perform public.platform_audit_write(
    p_office_id, 'override', p_key, 'override_removed',
    jsonb_build_object('value', v_old), null, coalesce(p_reason, ''));

  return public.platform_office_license(p_office_id);
end;
$$;


-- Bulk edit (a brief requirement). One transaction, one reason, one audit row per
-- feature — so a bulk action is still individually explainable afterwards.
create or replace function public.platform_bulk_set_overrides(
  p_office_id uuid,
  p_values    jsonb,
  p_reason    text,
  p_expires_at timestamptz default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_entry record;
begin
  perform public.assert_platform_admin();
  if length(btrim(coalesce(p_reason,''))) < 8 then raise exception 'reason_required'; end if;

  for v_entry in select key, value from jsonb_each(p_values) loop
    if jsonb_typeof(v_entry.value) = 'null' then
      perform public.platform_clear_override(p_office_id, v_entry.key, p_reason);
    else
      perform public.platform_set_override(
        p_office_id, v_entry.key, v_entry.value, p_reason, p_expires_at);
    end if;
  end loop;

  return public.platform_office_license(p_office_id);
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 8. Cross-office reads: licenses, audit, usage, health
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.platform_list_licenses()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();

  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'office_id',     o.id,
             'office_name',   o.name,
             'office_slug',   o.slug,
             'listing_status', o.listing_status,
             'licensing_hold', coalesce(o.licensing_hold, 'none'),
             'plan_key',      p.key,
             'plan_name_ar',  p.name_ar,
             'status',        coalesce(l.status, 'none'),
             'billing_cycle', l.billing_cycle,
             'price',         coalesce(l.price_override, p.price_monthly),
             'currency',      coalesce(l.currency, 'EGP'),
             'trial_ends_at', l.trial_ends_at,
             'period_end',    l.period_end,
             'auto_renew',    coalesce(l.auto_renew, false),
             'override_count', (select count(*) from public.office_feature_overrides ov
                                 where ov.office_id = o.id),
             'over_limit',    (select count(*) from public.platform_features f
                                where f.value_type = 'limit'
                                  and (public.platform_resolve_feature(o.id, null, f.key) #>> '{value}')
                                        <> 'unlimited'
                                  and public.office_usage_for(o.id, f.key)
                                      > (public.platform_resolve_feature(o.id, null, f.key) #>> '{value}')::bigint))
           order by o.name)
      from public.offices o
      left join public.office_licenses l on l.office_id = o.id
      left join public.platform_plans  p on p.id = l.plan_id), '[]'::jsonb);
end;
$$;


-- Named platform_audit_log rather than the design's `platform_license_audit` so the
-- RPC and the TABLE it reads do not share a name — one letter of ambiguity in a
-- support conversation is not worth the symmetry.
create or replace function public.platform_audit_log(
  p_filters jsonb default '{}'::jsonb,
  p_limit   int   default 100,
  p_offset  int   default 0
) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();

  return coalesce((
    select jsonb_agg(to_jsonb(a) order by a.created_at desc)
      from (
        select l.*, o.name as office_name
          from public.platform_license_audit l
          left join public.offices o on o.id = l.office_id
         where (not (p_filters ? 'office_id')
                or l.office_id = (p_filters ->> 'office_id')::uuid)
           and (not (p_filters ? 'entity_type')
                or l.entity_type = (p_filters ->> 'entity_type'))
           and (not (p_filters ? 'action')
                or l.action = (p_filters ->> 'action'))
           and (not (p_filters ? 'since')
                or l.created_at >= (p_filters ->> 'since')::timestamptz)
         order by l.created_at desc
         limit greatest(least(p_limit, 500), 1) offset greatest(p_offset, 0)
      ) a), '[]'::jsonb);
end;
$$;


create or replace function public.platform_usage_report()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();

  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'office_id', o.id,
             'office_name', o.name,
             'plan_key', (select p.key from public.office_licenses l
                            join public.platform_plans p on p.id = l.plan_id
                           where l.office_id = o.id),
             'metrics', (
               select coalesce(jsonb_agg(jsonb_build_object(
                        'key', f.key,
                        'name_ar', f.name_ar,
                        'unit_ar', f.unit_ar,
                        'meter_kind', f.meter_kind,
                        'limit', public.platform_resolve_feature(o.id, null, f.key) -> 'value',
                        'used', public.office_usage_for(o.id, f.key))
                      order by f.category_key, f.sort_order), '[]'::jsonb)
                 from public.platform_features f
                where f.value_type = 'limit' and f.status <> 'hidden'))
           order by o.name)
      from public.offices o), '[]'::jsonb);
end;
$$;


-- Not in the brief. Added because it is what actually gets opened daily.
create or replace function public.platform_licensing_health()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_warn int;
begin
  perform public.assert_platform_admin();

  select warn_days_before into v_warn from public.platform_settings where id;

  return jsonb_build_object(
    'enforcement_mode', public.platform_enforcement_mode(),

    'trials_ending', coalesce((
      select jsonb_agg(jsonb_build_object('office_id', o.id, 'office_name', o.name,
                                          'trial_ends_at', l.trial_ends_at))
        from public.office_licenses l join public.offices o on o.id = l.office_id
       where l.status = 'trialing'
         and l.trial_ends_at <= now() + make_interval(days => v_warn)), '[]'::jsonb),

    'past_due', coalesce((
      select jsonb_agg(jsonb_build_object('office_id', o.id, 'office_name', o.name,
                                          'status', l.status, 'period_end', l.period_end))
        from public.office_licenses l join public.offices o on o.id = l.office_id
       where l.status in ('past_due','grace','suspended')), '[]'::jsonb),

    -- The over-limit list. This is a REAL state, not a failure: limits gate
    -- creation, never existence, so an office that downgraded is legitimately over
    -- and keeps operating (§5.4). It is shown rather than silently corrected.
    'over_limit', coalesce((
      select jsonb_agg(jsonb_build_object(
               'office_id', o.id, 'office_name', o.name,
               'feature_key', f.key, 'name_ar', f.name_ar,
               'limit', (public.platform_resolve_feature(o.id, null, f.key) #>> '{value}')::bigint,
               'used', public.office_usage_for(o.id, f.key)))
        from public.offices o
        cross join public.platform_features f
       where f.value_type = 'limit'
         and (public.platform_resolve_feature(o.id, null, f.key) #>> '{value}') <> 'unlimited'
         and public.office_usage_for(o.id, f.key)
             > (public.platform_resolve_feature(o.id, null, f.key) #>> '{value}')::bigint), '[]'::jsonb),

    -- A promise the code does not keep: a `declared` feature turned on by an active
    -- plan. Shipping flags that silently do nothing is how a licensing system loses
    -- credibility internally (§0 decision 7).
    'sold_but_declared', coalesce((
      select jsonb_agg(jsonb_build_object('plan_key', p.key, 'feature_key', f.key,
                                          'name_ar', f.name_ar, 'value', pf.value))
        from public.platform_plan_features pf
        join public.platform_plans p    on p.id  = pf.plan_id
        join public.platform_features f on f.key = pf.feature_key
       where p.status = 'active'
         and f.enforcement_status = 'declared'
         and public.platform_value_is_truthy(pf.value)), '[]'::jsonb),

    'overrides_expiring', coalesce((
      select jsonb_agg(jsonb_build_object('office_id', o.id, 'office_name', o.name,
                                          'feature_key', ov.feature_key,
                                          'expires_at', ov.expires_at))
        from public.office_feature_overrides ov join public.offices o on o.id = ov.office_id
       where ov.expires_at is not null
         and ov.expires_at between now() and now() + make_interval(days => v_warn)), '[]'::jsonb),

    'offices_without_license', coalesce((
      select jsonb_agg(jsonb_build_object('office_id', o.id, 'office_name', o.name))
        from public.offices o
       where not exists (select 1 from public.office_licenses l where l.office_id = o.id)), '[]'::jsonb));
end;
$$;


create or replace function public.platform_settings_read()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();
  return (select to_jsonb(s)
                 || jsonb_build_object(
                      'restricted_plan_key',
                      (select p.key from public.platform_plans p where p.id = s.restricted_plan_id),
                      'default_signup_plan_key',
                      (select p.key from public.platform_plans p where p.id = s.default_signup_plan_id))
            from public.platform_settings s where s.id);
end;
$$;


create or replace function public.platform_update_settings(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();
  perform set_config('bmt.licensing_reason', coalesce(p_payload ->> 'reason', ''), true);

  update public.platform_settings s set
    enforcement_mode       = coalesce(p_payload ->> 'enforcement_mode', s.enforcement_mode),
    restricted_plan_id     = case when p_payload ? 'restricted_plan_id'
                                  then nullif(p_payload ->> 'restricted_plan_id','')::uuid
                                  else s.restricted_plan_id end,
    default_signup_plan_id = case when p_payload ? 'default_signup_plan_id'
                                  then nullif(p_payload ->> 'default_signup_plan_id','')::uuid
                                  else s.default_signup_plan_id end,
    grace_days             = coalesce((p_payload ->> 'grace_days')::int, s.grace_days),
    warn_days_before       = coalesce((p_payload ->> 'warn_days_before')::int, s.warn_days_before)
  where s.id;

  return public.platform_settings_read();
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 9. Grants — platform admin only, enforced in the body as well as the grant
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- The grant lets `authenticated` CALL them; assert_platform_admin() decides whether
-- the call does anything. Both layers, because a grant is a deployment fact and the
-- body check is a code fact, and neither should be the only one.

revoke all on function public.assert_platform_admin()                      from public, anon;
revoke all on function public.license_hold_for_status(text)                from public, anon;
revoke all on function public.platform_feature_catalog()                   from public, anon;
revoke all on function public.platform_upsert_feature(jsonb)               from public, anon;
revoke all on function public.platform_set_feature_status(text, text)      from public, anon;
revoke all on function public.platform_list_plans()                        from public, anon;
revoke all on function public.platform_plan_detail(uuid)                   from public, anon;
revoke all on function public.platform_save_plan(jsonb)                    from public, anon;
revoke all on function public.platform_clone_plan(uuid, text, text)        from public, anon;
revoke all on function public.platform_compare_plans(uuid[])               from public, anon;
revoke all on function public.platform_preview_plan(uuid)                  from public, anon;
revoke all on function public.platform_office_license(uuid)                from public, anon;
revoke all on function public.platform_assign_plan(uuid, uuid, text, jsonb) from public, anon;
revoke all on function public.platform_set_license_status(uuid, text, text) from public, anon;
revoke all on function public.platform_start_trial(uuid, uuid, int)        from public, anon;
revoke all on function public.platform_extend_trial(uuid, int, text)       from public, anon;
revoke all on function public.platform_set_override(uuid, text, jsonb, text, timestamptz) from public, anon;
revoke all on function public.platform_clear_override(uuid, text, text)    from public, anon;
revoke all on function public.platform_bulk_set_overrides(uuid, jsonb, text, timestamptz) from public, anon;
revoke all on function public.platform_list_licenses()                     from public, anon;
revoke all on function public.platform_audit_log(jsonb, int, int)          from public, anon;
revoke all on function public.platform_usage_report()                      from public, anon;
revoke all on function public.platform_licensing_health()                  from public, anon;
revoke all on function public.platform_settings_read()                     from public, anon;
revoke all on function public.platform_update_settings(jsonb)              from public, anon;
revoke all on function public.office_license_project_hold()                from public, anon, authenticated;

grant execute on function public.platform_feature_catalog()                   to authenticated;
grant execute on function public.platform_upsert_feature(jsonb)               to authenticated;
grant execute on function public.platform_set_feature_status(text, text)      to authenticated;
grant execute on function public.platform_list_plans()                        to authenticated;
grant execute on function public.platform_plan_detail(uuid)                   to authenticated;
grant execute on function public.platform_save_plan(jsonb)                    to authenticated;
grant execute on function public.platform_clone_plan(uuid, text, text)        to authenticated;
grant execute on function public.platform_compare_plans(uuid[])               to authenticated;
grant execute on function public.platform_preview_plan(uuid)                  to authenticated;
grant execute on function public.platform_office_license(uuid)                to authenticated;
grant execute on function public.platform_assign_plan(uuid, uuid, text, jsonb) to authenticated;
grant execute on function public.platform_set_license_status(uuid, text, text) to authenticated;
grant execute on function public.platform_start_trial(uuid, uuid, int)        to authenticated;
grant execute on function public.platform_extend_trial(uuid, int, text)       to authenticated;
grant execute on function public.platform_set_override(uuid, text, jsonb, text, timestamptz) to authenticated;
grant execute on function public.platform_clear_override(uuid, text, text)    to authenticated;
grant execute on function public.platform_bulk_set_overrides(uuid, jsonb, text, timestamptz) to authenticated;
grant execute on function public.platform_list_licenses()                     to authenticated;
grant execute on function public.platform_audit_log(jsonb, int, int)          to authenticated;
grant execute on function public.platform_usage_report()                      to authenticated;
grant execute on function public.platform_licensing_health()                  to authenticated;
grant execute on function public.platform_settings_read()                     to authenticated;
grant execute on function public.platform_update_settings(jsonb)              to authenticated;
grant execute on function public.assert_platform_admin()                      to authenticated;
grant execute on function public.license_hold_for_status(text)                to authenticated;
