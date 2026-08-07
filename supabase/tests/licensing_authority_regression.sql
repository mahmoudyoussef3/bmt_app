-- ═══════════════════════════════════════════════════════════════════════════════════
-- Licensing authority regression suite
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Exercises every control the entitlement platform claims to have, against the linked
-- database, in one pass:
--
--   deploy safety  — ships with enforcement off; the incumbent offices lose nothing
--   the ladder     — kill switch > license hold > override > plan > catalog default
--   dependencies   — can only SUBTRACT, and report BOTH the source and the blocker
--   validation     — -1, JSON null, wrong types and out-of-enum values are refused
--   stock vs flow  — deleting a row returns stock quota and does NOT return flow
--   creation gate  — a limit blocks the next row and never touches existing ones
--   enforcement    — off allows, shadow logs, enforcing blocks with the right code
--   isolation      — office A cannot read or write office B's license, overrides or
--                    usage, and cannot call any platform RPC
--   write paths    — no INSERT/UPDATE/DELETE policy exists on any licensing table
--   immutability   — the audit log refuses UPDATE and DELETE
--   degradation    — suspension delists but keeps captains, in-flight trips and
--                    reads alive
--   billing        — invoice numbers are gapless, issuance is idempotent per period
--   lifecycle      — trial expiry downgrades; a new office always gets a license
--
-- Runs entirely inside BEGIN … ROLLBACK. It creates real offices, drivers, licenses
-- and invoices and throws them all away; nothing survives the run, so it is safe
-- against the production-bound development database.
--
--   supabase db query --linked -f supabase/tests/licensing_authority_regression.sql
--
-- Every row of the output should read OK. Any row reading "BROKEN" or "LEAK" is a
-- regression.
--
-- Covers: 20260807090000 (foundation), 20260807090100 (catalog seed),
--         20260807100000 (resolution), 20260807100100 (console),
--         20260807110000 (enforcement), 20260807120000 (billing),
--         20260807130000 (lifecycle), 20260807140000 (marketplace).
-- ═══════════════════════════════════════════════════════════════════════════════════

begin;

create temp table probe(step text, result text) on commit drop;
create temp table fixture(k text primary key, v text) on commit drop;
grant all on probe to authenticated, anon;
grant all on fixture to authenticated, anon;


-- ───────────────────────────────────────────────────────────────────────────────────
-- Cast, resolved as superuser before any impersonation starts.
-- ───────────────────────────────────────────────────────────────────────────────────
do $$
declare
  v_office_a uuid;
  v_admin_a  uuid;
  v_office_b uuid;
  v_admin_b  uuid;
  v_platform uuid;
begin
  select ou.office_id, ou.user_id into v_office_a, v_admin_a
    from public.office_users ou
    join public.offices o on o.id = ou.office_id
   where ou.role = 'dashboard_admin' and ou.status = 'active' and o.status = 'active'
   order by o.created_at
   limit 1;

  if v_office_a is null then
    raise exception 'FIXTURE: no active office with an active dashboard_admin';
  end if;

  select ou.office_id, ou.user_id into v_office_b, v_admin_b
    from public.office_users ou
    join public.offices o on o.id = ou.office_id
   where ou.role = 'dashboard_admin' and ou.status = 'active'
     and ou.office_id <> v_office_a
   limit 1;

  if v_office_b is null then
    raise exception 'FIXTURE: needs a second office with an active dashboard_admin';
  end if;

  select user_id into v_platform from public.platform_admins limit 1;
  if v_platform is null then
    raise exception 'FIXTURE: no platform admin';
  end if;

  -- Section N needs an operator who is ONLY an office operator. On this database
  -- the incumbent office's owner is also the platform admin, and the read-only
  -- gate exempts platform admins by design — so testing the freeze as that user
  -- would prove nothing. Recorded separately rather than changing office_a,
  -- which every other section is written against.
  insert into fixture
  select 'office_np', ou.office_id::text
    from public.office_users ou
    join public.offices o on o.id = ou.office_id
   where ou.role = 'dashboard_admin' and ou.status = 'active' and o.status = 'active'
     and not exists (select 1 from public.platform_admins pa where pa.user_id = ou.user_id)
   order by o.created_at
   limit 1;

  insert into fixture
  select 'admin_np', ou.user_id::text
    from public.office_users ou
   where ou.office_id = (select v::uuid from fixture where k = 'office_np')
     and ou.role = 'dashboard_admin' and ou.status = 'active'
     and not exists (select 1 from public.platform_admins pa where pa.user_id = ou.user_id)
   limit 1;

  insert into fixture values
    ('office_a', v_office_a::text), ('admin_a', v_admin_a::text),
    ('office_b', v_office_b::text), ('admin_b', v_admin_b::text),
    ('platform', v_platform::text),
    -- The mode the platform actually ships in, captured before the suite forces
    -- its own. Section A asserts on this; every other section sets what it needs.
    ('shipped_mode', public.platform_enforcement_mode());

  -- The incumbents' true state, frozen here because later sections suspend,
  -- expire and re-plan office_a to test those paths. Section T asserts on this.
  insert into fixture
  select 'incumbent_drift',
         string_agg(o.name || ' → ' || coalesce(p.key, 'NO LICENCE')
                    || '/' || coalesce(l.status, '-')
                    || '/' || coalesce(o.licensing_hold, 'none'), ', ')
    from public.offices o
    left join public.office_licenses l on l.office_id = o.id
    left join public.platform_plans  p on p.id = l.plan_id
   where o.created_at < '2026-08-07'
     and (p.key is distinct from 'founder'
          or l.status is distinct from 'active'
          or coalesce(o.licensing_hold, 'none') <> 'none');
end $$;

-- Sections B–M were written against `off` and assert the resolver's behaviour
-- rather than the gates'. Now that the platform ships `enforcing`, they have to
-- state the mode they need instead of inheriting it, or a live gate would abort
-- a fixture insert that is not what the check is about. Sections N onward turn
-- enforcement back on explicitly, one scenario at a time.
update public.platform_settings set enforcement_mode = 'off' where id;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- A. Deploy safety — this subsystem must be invisible on the day it lands
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_office uuid := (select v::uuid from fixture where k = 'office_a');
  v_listed boolean;
  v_raw    boolean;
begin
  -- Was "ships with enforcement off" through Phase 6. The audit that preceded
  -- 20260808100000 closed every gap the shadow period existed to find, so the
  -- shipped state is now `enforcing` and a deploy that silently reverted it —
  -- the one failure mode that turns a licensing platform into decoration — is
  -- what this check catches.
  insert into probe values ('A1. ships with enforcement ON',
    case when (select v from fixture where k = 'shipped_mode') = 'enforcing' then 'OK'
         else 'BROKEN — ships '
              || (select v from fixture where k = 'shipped_mode') end);

  insert into probe values ('A2. every office has a license',
    case when not exists (select 1 from public.offices o
                           where not exists (select 1 from public.office_licenses l
                                              where l.office_id = o.id))
         then 'OK' else 'BROKEN — an office has no license row' end);

  insert into probe values ('A3. incumbent offices are unlimited',
    case when not exists (
           select 1 from public.offices o
           cross join public.platform_features f
            where f.value_type = 'limit'
              and o.created_at < '2026-08-07'
              and (public.platform_resolve_feature(o.id, null, f.key) #>> '{value}') <> 'unlimited'
              and f.key in ('max_drivers','max_vehicles','max_routes',
                            'max_trips_per_month','max_admin_users'))
         then 'OK — grandfathered on founder'
         else 'BROKEN — an incumbent office lost a capability' end);

  select public.office_is_listed(v_office) into v_listed;
  select (status = 'active' and listing_status = 'listed') into v_raw
    from public.offices where id = v_office;
  insert into probe values ('A4. marketplace unchanged',
    case when v_listed = v_raw then 'OK' else 'BROKEN — listing changed on deploy' end);

  insert into probe values ('A5. enforcement_status is honest',
    case when not exists (
           select 1 from public.platform_features f
            where f.enforcement_status = 'enforced'
              and not exists (select 1 from public.platform_feature_gates g
                               where g.feature_key = f.key))
         then 'OK — no feature claims a gate it does not have'
         else 'BROKEN — enforced without a gate' end);
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- B. The ladder (§4.1) — first match wins, and the source is reported
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_office  uuid := (select v::uuid from fixture where k = 'office_a');
  v_starter uuid := (select id from public.platform_plans where key = 'starter');
  v_r       jsonb;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'platform'))::text, true);

  perform public.platform_assign_plan(v_office, v_starter, 'monthly',
    '{"reason":"مجموعة اختبار"}'::jsonb);

  -- rung 3: the plan
  v_r := public.office_feature_for(v_office, 'max_drivers');
  insert into probe values ('B1. rung 3 — plan',
    case when (v_r ->> 'value') = '5' and (v_r ->> 'source') = 'plan' then 'OK'
         else 'BROKEN — ' || v_r::text end);

  -- rung 4: the catalog default, where the plan is silent
  v_r := public.office_feature_for(v_office, 'qr_tickets');
  insert into probe values ('B2. rung 4 — catalog default',
    case when (v_r ->> 'value') = 'false' and (v_r ->> 'source') = 'default' then 'OK'
         else 'BROKEN — ' || v_r::text end);

  -- rung 2: an override beats the plan, in both directions
  perform public.platform_set_override(v_office, 'max_drivers', '50'::jsonb,
    'تنازل تجاري للاختبار');
  v_r := public.office_feature_for(v_office, 'max_drivers');
  insert into probe values ('B3. rung 2 — override grants',
    case when (v_r ->> 'value') = '50' and (v_r ->> 'source') = 'override' then 'OK'
         else 'BROKEN — ' || v_r::text end);

  perform public.platform_set_override(v_office, 'max_drivers', '2'::jsonb,
    'تقييد تجاري للاختبار');
  v_r := public.office_feature_for(v_office, 'max_drivers');
  insert into probe values ('B4. rung 2 — override revokes',
    case when (v_r ->> 'value') = '2' then 'OK' else 'BROKEN — ' || v_r::text end);

  -- an EXPIRED override stops applying but is not deleted
  perform public.platform_set_override(v_office, 'max_drivers', '99'::jsonb,
    'تنازل منتهي للاختبار', now() - interval '1 day');
  v_r := public.office_feature_for(v_office, 'max_drivers');
  insert into probe values ('B5. expired override falls through, row survives',
    case when (v_r ->> 'source') = 'plan'
          and exists (select 1 from public.office_feature_overrides
                       where office_id = v_office and feature_key = 'max_drivers')
         then 'OK' else 'BROKEN — ' || v_r::text end);
  perform public.platform_clear_override(v_office, 'max_drivers', 'تنظيف الاختبار');

  -- rung 1: a license hold skips the override rung entirely
  perform public.platform_set_override(v_office, 'wallet', 'true'::jsonb,
    'تنازل يجب أن يسقط عند الإيقاف');
  perform public.platform_set_license_status(v_office, 'suspended', 'اختبار الإيقاف');
  v_r := public.office_feature_for(v_office, 'wallet');
  insert into probe values ('B6. rung 1 — license hold beats override',
    case when (v_r ->> 'source') = 'license_hold' and (v_r ->> 'value') = 'false' then 'OK'
         else 'BROKEN — ' || v_r::text end);
  perform public.platform_set_license_status(v_office, 'active', 'اختبار الاستئناف');
  perform public.platform_clear_override(v_office, 'wallet', 'تنظيف الاختبار');

  -- rung 0: the kill switch beats everything, including an override
  perform public.platform_set_override(v_office, 'cashback', 'true'::jsonb,
    'تنازل يجب أن يسقط عند مفتاح الإيقاف');
  perform public.platform_set_feature_status('cashback', 'disabled');
  v_r := public.office_feature_for(v_office, 'cashback');
  insert into probe values ('B7. rung 0 — kill switch beats everything',
    case when (v_r ->> 'source') = 'kill_switch' and (v_r ->> 'value') = 'false' then 'OK'
         else 'BROKEN — ' || v_r::text end);
  perform public.platform_set_feature_status('cashback', 'active');
  perform public.platform_clear_override(v_office, 'cashback', 'تنظيف الاختبار');
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- C. Dependencies subtract, and report both facts
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_office uuid := (select v::uuid from fixture where k = 'office_a');
  v_r      jsonb;
begin
  -- starter has wallet off, so cashback collapses even with an explicit grant
  perform public.platform_set_override(v_office, 'cashback', 'true'::jsonb,
    'اختبار الاعتمادية');
  v_r := public.office_feature_for(v_office, 'cashback');
  insert into probe values ('C1. dependency defeats an override, and says so',
    case when (v_r ->> 'value') = 'false'
          and (v_r ->> 'source') = 'override'
          and (v_r ->> 'blocked_by') = 'wallet'
         then 'OK — the console can explain this'
         else 'BROKEN — ' || v_r::text end);

  perform public.platform_set_override(v_office, 'wallet', 'true'::jsonb,
    'اختبار الاعتمادية');
  v_r := public.office_feature_for(v_office, 'cashback');
  insert into probe values ('C2. satisfying the prerequisite lets it through',
    case when (v_r ->> 'value') = 'true' and (v_r ->> 'blocked_by') is null then 'OK'
         else 'BROKEN — ' || v_r::text end);

  -- a limit collapses to 0, never to null and never upward
  perform public.platform_set_override(v_office, 'routes', 'false'::jsonb,
    'اختبار انهيار الحد');
  v_r := public.office_feature_for(v_office, 'max_routes');
  insert into probe values ('C3. a blocked limit collapses to 0',
    case when (v_r ->> 'value') = '0' and (v_r ->> 'blocked_by') = 'routes' then 'OK'
         else 'BROKEN — ' || v_r::text end);

  perform public.platform_clear_override(v_office, 'routes',   'تنظيف الاختبار');
  perform public.platform_clear_override(v_office, 'cashback', 'تنظيف الاختبار');
  perform public.platform_clear_override(v_office, 'wallet',   'تنظيف الاختبار');
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- D. Value validation — the type safety jsonb gave up (§2.3, §2.4)
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_office uuid := (select v::uuid from fixture where k = 'office_a');
  v_bad    int := 0;
  v_total  int := 0;
begin
  -- -1 as "unlimited" is the magic number that becomes a denial of service
  begin
    v_total := v_total + 1;
    perform public.platform_set_override(v_office, 'max_drivers', '-1'::jsonb, 'قيمة غير صالحة');
    v_bad := v_bad + 1;
  exception when others then null; end;

  -- JSON null is not a value; absence of a row is a different rung
  begin
    v_total := v_total + 1;
    perform public.platform_set_override(v_office, 'max_drivers', 'null'::jsonb, 'قيمة غير صالحة');
    v_bad := v_bad + 1;
  exception when others then null; end;

  -- a boolean feature will not take a number
  begin
    v_total := v_total + 1;
    perform public.platform_set_override(v_office, 'wallet', '7'::jsonb, 'قيمة غير صالحة');
    v_bad := v_bad + 1;
  exception when others then null; end;

  -- an enum will not take a value outside its allowed list
  begin
    v_total := v_total + 1;
    perform public.platform_set_override(v_office, 'report_level', '"galactic"'::jsonb, 'قيمة غير صالحة');
    v_bad := v_bad + 1;
  exception when others then null; end;

  -- an unknown feature key is refused rather than silently stored
  begin
    v_total := v_total + 1;
    perform public.platform_set_override(v_office, 'max_unicorns', 'true'::jsonb, 'قيمة غير صالحة');
    v_bad := v_bad + 1;
  exception when others then null; end;

  -- an override with no stated reason is refused
  begin
    v_total := v_total + 1;
    perform public.platform_set_override(v_office, 'wallet', 'true'::jsonb, 'x');
    v_bad := v_bad + 1;
  exception when others then null; end;

  insert into probe values ('D1. invalid values refused',
    case when v_bad = 0 then 'OK — all ' || v_total || ' refused'
         else 'BROKEN — ' || v_bad || ' of ' || v_total || ' accepted' end);

  -- and the ONE permitted string still works
  begin
    perform public.platform_set_override(v_office, 'max_drivers', '"unlimited"'::jsonb,
      'اختبار قيمة بلا حدود');
    insert into probe values ('D2. "unlimited" survives every layer',
      case when (public.office_feature_for(v_office,'max_drivers') ->> 'value') = 'unlimited'
           then 'OK' else 'BROKEN' end);
    perform public.platform_clear_override(v_office, 'max_drivers', 'تنظيف الاختبار');
  exception when others then
    insert into probe values ('D2. "unlimited" survives every layer', 'BROKEN — refused');
  end;
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- E. Stock vs flow (§5.2) — the classic quota bug, in both directions
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_office  uuid := (select v::uuid from fixture where k = 'office_a');
  v_before  bigint;
  v_after   bigint;
  v_driver  uuid;
  v_flow_1  bigint;
  v_flow_2  bigint;
begin
  v_before := public.office_usage_for(v_office, 'max_drivers');

  insert into public.drivers
    (office_id, employee_code, full_name, phone, emergency_phone, address,
     national_id, license_number, license_expiry_date, hire_date, status)
  values (v_office, 'LIC-REG-1', 'سائق اختبار التراخيص', '01000000901', '01000000902',
          'عنوان اختبار', '29900000000901', 'LN-REG-1', now() + interval '2 years',
          now(), 'active')
  returning id into v_driver;

  insert into probe values ('E1. stock meter counts the live rows',
    case when public.office_usage_for(v_office, 'max_drivers') = v_before + 1 then 'OK'
         else 'BROKEN' end);

  delete from public.drivers where id = v_driver;
  v_after := public.office_usage_for(v_office, 'max_drivers');
  insert into probe values ('E2. deleting a row RETURNS stock quota',
    case when v_after = v_before then 'OK — self-healing, no cache to drift'
         else 'BROKEN — deleting cost a permanent seat' end);

  v_flow_1 := public.office_usage_for(v_office, 'max_trips_per_month');
  perform public.office_usage_record(v_office, 'max_trips_per_month', 3);
  v_flow_2 := public.office_usage_for(v_office, 'max_trips_per_month');
  insert into probe values ('E3. flow meter accumulates',
    case when v_flow_2 = v_flow_1 + 3 then 'OK' else 'BROKEN' end);

  -- and there is deliberately no path that gives it back
  insert into probe values ('E4. flow quota is NOT refundable',
    case when public.office_usage_for(v_office, 'max_trips_per_month') = v_flow_2
         then 'OK — delete-and-recreate cannot farm free usage'
         else 'BROKEN' end);

  insert into probe values ('E5. every limit declares its meter',
    case when not exists (select 1 from public.platform_features
                           where value_type = 'limit'
                             and (meter_kind is null or meter_period is null))
         then 'OK' else 'BROKEN — a limit with no meter_kind' end);
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- F. Enforcement: off allows, shadow logs, enforcing blocks (§5.3, Part 15)
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_office uuid := (select v::uuid from fixture where k = 'office_a');
  v_msg    text;
  v_before int;
  v_n      int;
  v_live   int;
begin
  -- Drive the office hard over its limit without touching a single existing row.
  perform public.platform_set_override(v_office, 'max_drivers', '0'::jsonb,
    'اختبار سلوك التنفيذ');
  v_live := (select count(*) from public.drivers where office_id = v_office);

  ------------------------------------------------------------------------ off
  insert into public.drivers
    (office_id, employee_code, full_name, phone, emergency_phone, address,
     national_id, license_number, license_expiry_date, hire_date, status)
  values (v_office, 'LIC-REG-OFF', 'سائق وضع الإيقاف', '01000000911', '01000000912',
          'عنوان', '29900000000911', 'LN-OFF', now() + interval '2 years', now(), 'active');
  insert into probe values ('F1. mode=off changes nothing', 'OK');
  delete from public.drivers where employee_code = 'LIC-REG-OFF';

  --------------------------------------------------------------------- shadow
  update public.platform_settings set enforcement_mode = 'shadow' where id;
  v_before := (select count(*) from public.platform_quota_violations);

  insert into public.drivers
    (office_id, employee_code, full_name, phone, emergency_phone, address,
     national_id, license_number, license_expiry_date, hire_date, status)
  values (v_office, 'LIC-REG-SHADOW', 'سائق وضع الظل', '01000000921', '01000000922',
          'عنوان', '29900000000921', 'LN-SHADOW', now() + interval '2 years', now(), 'active');

  v_n := (select count(*) from public.platform_quota_violations) - v_before;
  insert into probe values ('F2. mode=shadow logs and allows',
    case when v_n = 1 then 'OK — 1 violation observed, write allowed'
         else 'BROKEN — ' || v_n || ' violations logged' end);
  delete from public.drivers where employee_code = 'LIC-REG-SHADOW';

  ------------------------------------------------------------------ enforcing
  update public.platform_settings set enforcement_mode = 'enforcing' where id;
  begin
    insert into public.drivers
      (office_id, employee_code, full_name, phone, emergency_phone, address,
       national_id, license_number, license_expiry_date, hire_date, status)
    values (v_office, 'LIC-REG-BLOCK', 'سائق ممنوع', '01000000931', '01000000932',
            'عنوان', '29900000000931', 'LN-BLOCK', now() + interval '2 years', now(), 'active');
    insert into probe values ('F3. mode=enforcing blocks', 'BROKEN — the insert succeeded');
  exception when others then
    get stacked diagnostics v_msg = message_text;
    insert into probe values ('F3. mode=enforcing blocks with a machine code',
      case when v_msg = 'quota_exceeded' then 'OK' else 'BROKEN — code was ' || v_msg end);
  end;

  -- §5.4: the block is on CREATION. Existing rows are untouched and still readable.
  insert into probe values ('F4. limits gate creation, never existence',
    case when (select count(*) from public.drivers where office_id = v_office) = v_live
         then 'OK — ' || v_live || ' existing drivers untouched'
         else 'BROKEN — enforcement deleted or hid operational data' end);

  -- assert_feature refuses with the entitlement code, not a permission one
  perform public.platform_set_override(v_office, 'wallet', 'false'::jsonb,
    'اختبار حارس الميزة');
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'admin_a'))::text, true);
  begin
    perform public.assert_feature('wallet');
    insert into probe values ('F5. assert_feature refuses', 'BROKEN — it allowed');
  exception when others then
    get stacked diagnostics v_msg = message_text;
    insert into probe values ('F5. assert_feature refuses with the entitlement code',
      case when v_msg = 'feature_not_licensed' then 'OK'
           else 'BROKEN — code was ' || v_msg end);
  end;

  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'platform'))::text, true);
  update public.platform_settings set enforcement_mode = 'off' where id;
  perform public.platform_clear_override(v_office, 'max_drivers', 'تنظيف الاختبار');
  perform public.platform_clear_override(v_office, 'wallet', 'تنظيف الاختبار');
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- G. Suspension DEGRADES — it never blacks out (§4.3, Part 11)
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_office uuid := (select v::uuid from fixture where k = 'office_a');
begin
  perform public.platform_set_license_status(v_office, 'suspended', 'اختبار التدهور');

  insert into probe values ('G1. suspended office is delisted',
    case when public.office_is_listed(v_office) = false
          and (select licensing_hold from public.offices where id = v_office) = 'delisted'
         then 'OK' else 'BROKEN' end);

  insert into probe values ('G2. captains keep signing in',
    case when (public.platform_resolve_feature(v_office, null, 'driver_app') ->> 'value') = 'true'
         then 'OK' else 'BROKEN — a billing action stranded a driver' end);

  insert into probe values ('G3. in-flight trips are never blocked',
    case when (public.platform_resolve_feature(v_office, null, 'max_live_trips') ->> 'value') = 'unlimited'
         then 'OK' else 'BROKEN — a sold ticket cannot depart' end);

  insert into probe values ('G4. own data stays readable',
    case when (public.platform_resolve_feature(v_office, null, 'finance')  ->> 'value') = 'true'
          and (public.platform_resolve_feature(v_office, null, 'reports')  ->> 'value') = 'true'
          and (public.platform_resolve_feature(v_office, null, 'bookings') ->> 'value') = 'true'
         then 'OK' else 'BROKEN — suspension hid a tenant''s records' end);

  insert into probe values ('G5. refund REQUESTS stay open, settlement does not',
    case when (public.platform_resolve_feature(v_office, null, 'refunds') ->> 'value') = 'true'
          and (public.platform_resolve_feature(v_office, null, 'wallet')  ->> 'value') = 'false'
         then 'OK — a passenger claim survives the office''s billing dispute'
         else 'BROKEN' end);

  insert into probe values ('G6. new inventory is blocked',
    case when (public.platform_resolve_feature(v_office, null, 'max_drivers')         ->> 'value') = '0'
          and (public.platform_resolve_feature(v_office, null, 'max_routes')          ->> 'value') = '0'
          and (public.platform_resolve_feature(v_office, null, 'max_trips_per_month') ->> 'value') = '0'
         then 'OK' else 'BROKEN' end);

  perform public.platform_set_license_status(v_office, 'active', 'انتهى الاختبار');
  insert into probe values ('G7. restore relists',
    case when public.office_is_listed(v_office) then 'OK' else 'BROKEN' end);
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- H. Billing and lifecycle
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_office uuid := (select v::uuid from fixture where k = 'office_a');
  v_inv    jsonb;
  v_n      int;
  v_slug   text := 'lic-reg-' || substr(gen_random_uuid()::text, 1, 8);
begin
  v_inv := public.platform_issue_invoice(v_office,
    date_trunc('month', now()) - interval '1 month', date_trunc('month', now()), '{}'::jsonb);

  insert into probe values ('H1. invoice numbers are gapless per year',
    case when (v_inv ->> 'invoice_number') ~ ('^INV-' || extract(year from now())::text || '-\d{4}$')
         then 'OK — ' || (v_inv ->> 'invoice_number')
         else 'BROKEN — ' || coalesce(v_inv ->> 'invoice_number', 'null') end);

  perform public.platform_issue_invoice(v_office,
    date_trunc('month', now()) - interval '1 month', date_trunc('month', now()), '{}'::jsonb);
  v_n := (select count(*) from public.office_invoices
           where office_id = v_office
             and period_start = date_trunc('month', now()) - interval '1 month');
  insert into probe values ('H2. issuance is idempotent per period',
    case when v_n = 1 then 'OK — the renewal job cannot double-bill'
         else 'BROKEN — ' || v_n || ' invoices for one period' end);

  perform public.platform_record_payment((v_inv ->> 'id')::uuid, 'تحويل بنكي', 'REG-1');
  insert into probe values ('H3. payment clears a dunning state',
    case when (select status from public.office_licenses where office_id = v_office) = 'active'
         then 'OK' else 'BROKEN' end);

  begin
    perform public.platform_void_invoice((v_inv ->> 'id')::uuid, 'محاولة إبطال فاتورة مسددة');
    insert into probe values ('H4. a PAID invoice cannot be voided', 'BROKEN — it voided');
  exception when others then
    insert into probe values ('H4. a PAID invoice cannot be voided',
      'OK — reversing received money is a refund, not an edit');
  end;

  -- F5 closed: every new office gets a license without anyone remembering to
  insert into public.offices (name, slug, status) values ('مكتب اختبار التراخيص', v_slug, 'active');
  insert into probe values ('H5. a new office always gets a license',
    case when exists (select 1 from public.office_licenses l
                       join public.offices o on o.id = l.office_id where o.slug = v_slug)
         then 'OK' else 'BROKEN — F5 is still open' end);

  -- the lifecycle job runs clean
  perform public.platform_run_licensing_lifecycle();
  perform public.platform_run_billing_cycle();
  insert into probe values ('H6. lifecycle and billing jobs run clean', 'OK');
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- I. Immutability
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare v_id bigint;
begin
  select id into v_id from public.platform_license_audit order by id desc limit 1;

  begin
    update public.platform_license_audit set reason = 'محاولة تعديل' where id = v_id;
    insert into probe values ('I1. audit refuses UPDATE, even from the owner', 'BROKEN');
  exception when others then
    insert into probe values ('I1. audit refuses UPDATE, even from the owner', 'OK');
  end;

  begin
    delete from public.platform_license_audit where id = v_id;
    insert into probe values ('I2. audit refuses DELETE, even from the owner', 'BROKEN');
  exception when others then
    insert into probe values ('I2. audit refuses DELETE, even from the owner', 'OK');
  end;

  insert into probe values ('I3. decisions are audited by trigger, not by callers',
    case when (select count(*) from public.platform_license_audit
                where entity_type = 'override' and created_at > now() - interval '5 minutes') > 0
         then 'OK' else 'BROKEN — override edits left no trail' end);
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- J. Cross-office isolation, under RLS, as a real office operator
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_office_a uuid := (select v::uuid from fixture where k = 'office_a');
  v_office_b uuid := (select v::uuid from fixture where k = 'office_b');
  v_n        int;
  v_r        jsonb;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'admin_b'), 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);

  ---------------------------------------------------------------------- reads
  select count(*) into v_n from public.office_licenses where office_id = v_office_a;
  insert into probe values ('J1. office B cannot read office A''s license',
    case when v_n = 0 then 'OK' else 'LEAK — ' || v_n || ' rows' end);

  select count(*) into v_n from public.office_feature_overrides where office_id = v_office_a;
  insert into probe values ('J2. office B cannot read office A''s overrides',
    case when v_n = 0 then 'OK' else 'LEAK — ' || v_n || ' rows' end);

  select count(*) into v_n from public.office_usage_counters where office_id = v_office_a;
  insert into probe values ('J3. office B cannot read office A''s usage',
    case when v_n = 0 then 'OK' else 'LEAK — ' || v_n || ' rows' end);

  select count(*) into v_n from public.office_invoices where office_id = v_office_a;
  insert into probe values ('J4. office B cannot read office A''s invoices',
    case when v_n = 0 then 'OK' else 'LEAK — ' || v_n || ' rows' end);

  select count(*) into v_n from public.platform_license_audit;
  insert into probe values ('J5. an office cannot read the platform audit log',
    case when v_n = 0 then 'OK' else 'LEAK — ' || v_n || ' rows' end);

  --------------------------------------------------------------------- writes
  begin
    insert into public.office_feature_overrides (office_id, feature_key, value, reason)
    values (v_office_b, 'wallet', 'true'::jsonb, 'ترقية ذاتية غير مصرح بها');
    insert into probe values ('J6. an office cannot grant itself a feature', 'LEAK — it worked');
  exception when others then
    insert into probe values ('J6. an office cannot grant itself a feature',
      'OK — no write policy exists on any licensing table');
  end;

  begin
    update public.office_licenses set plan_id =
      (select id from public.platform_plans where key = 'enterprise')
     where office_id = v_office_b;
    if found then
      insert into probe values ('J7. an office cannot upgrade its own plan', 'LEAK — it worked');
    else
      insert into probe values ('J7. an office cannot upgrade its own plan', 'OK');
    end if;
  exception when others then
    insert into probe values ('J7. an office cannot upgrade its own plan', 'OK');
  end;

  begin
    update public.offices set licensing_hold = 'none' where id = v_office_b;
    insert into probe values ('J8. an office cannot lift its own hold', 'LEAK — it worked');
  exception when others then
    insert into probe values ('J8. an office cannot lift its own hold', 'OK');
  end;

  ------------------------------------------------------- the platform surface
  begin
    perform public.platform_list_licenses();
    insert into probe values ('J9. an office cannot call a platform RPC', 'LEAK — it worked');
  exception when others then
    insert into probe values ('J9. an office cannot call a platform RPC',
      'OK — platform_admin_required');
  end;

  begin
    perform public.office_can_consume_for(v_office_a, 'max_drivers', 1);
    insert into probe values ('J10. the _for variants are unreachable', 'LEAK — it worked');
  exception when others then
    insert into probe values ('J10. the _for variants are unreachable',
      'OK — revoked from every API role');
  end;

  ------------------------------------------- the caller-facing verbs are scoped
  v_r := public.office_entitlements();
  insert into probe values ('J11. office_entitlements answers only for the caller',
    case when (v_r #>> '{license,plan_key}') is not null then 'OK — no office parameter exists'
         else 'BROKEN' end);

  perform set_config('role', 'postgres', true);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- K. Preview cannot lie, and the resolver is the only implementation
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_plan uuid := (select id from public.platform_plans where key = 'professional');
  v_prev jsonb;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'platform'))::text, true);

  v_prev := public.platform_preview_plan(v_plan);
  insert into probe values ('K1. plan preview runs the real resolver',
    case when (v_prev #>> '{max_drivers,value}') = '25'
          and (v_prev #>> '{cashback,value}') = 'true'
         then 'OK' else 'BROKEN — ' || coalesce(v_prev #>> '{max_drivers,value}', 'null') end);

  insert into probe values ('K2. plan compare uses the same values',
    case when (public.platform_compare_plans(array[v_plan]) #>> '{rows,0,values}') is not null
         then 'OK' else 'BROKEN' end);

  insert into probe values ('K3. health screen surfaces promises the code cannot keep',
    case when public.platform_licensing_health() ? 'sold_but_declared' then 'OK'
         else 'BROKEN' end);
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- L. A licence change reaches a console that is already open
-- ═══════════════════════════════════════════════════════════════════════════════════
-- `EntitlementService` subscribes to `office_licenses` so a suspension or a plan
-- change lands without a reload. A subscription to an unpublished table connects,
-- never errors and never fires, so the absence has to be asserted rather than
-- assumed — this check exists because it was in fact missing.

do $$
declare
  v_published boolean := exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'office_licenses');
  v_qual text := (select qual from pg_policies
                   where tablename = 'office_licenses' and cmd = 'SELECT' limit 1);
begin
  insert into probe values ('L1. office_licenses is published to realtime',
    case when v_published then 'OK'
         else 'BROKEN — the entitlement channel would never fire' end);

  -- Realtime re-evaluates the table's own SELECT policy per subscriber, so the
  -- helpers that policy calls must be SECURITY DEFINER or every event is dropped.
  insert into probe values ('L2. the read policy survives the realtime path',
    case when v_qual like '%current_office_id()%'
          and (select bool_and(p.prosecdef) from pg_proc p
                 join pg_namespace n on n.oid = p.pronamespace
                where n.nspname = 'public'
                  and p.proname in ('current_office_id', 'is_platform_admin'))
         then 'OK' else 'BROKEN — subscribers would receive nothing' end);

  -- Publishing must not have widened who can read a licence row.
  insert into probe values ('L3. publication did not widen read authority',
    case when v_qual like '%is_platform_admin()%' and v_qual like '%current_office_id()%'
         then 'OK' else 'LEAK — ' || coalesce(v_qual, 'no policy') end);
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- M. Both enforcement paths spell a refusal the same way (§7.2)
-- ═══════════════════════════════════════════════════════════════════════════════════
-- `assert_feature` raises the code directly; the quota trigger re-raises the
-- verdict's `reason`. The Dart client matches the raised message against a closed
-- set of six codes, so a path that invents a seventh spelling is not a refusal the
-- UI can explain — it is a generic error. The two paths drifted here once.

do $$
declare
  v_office   uuid := (select v from fixture where k = 'office_a')::uuid;
  v_dep_key  text;
  v_verdict  jsonb;
  v_codes    text[] := array['not_authorized', 'feature_not_licensed',
                             'feature_dependency_blocked', 'quota_exceeded',
                             'license_suspended', 'license_expired'];
begin
  -- A feature whose prerequisite is off: the resolver must report the blocker using
  -- the same code assert_feature would raise.
  select d.feature_key into v_dep_key
    from public.platform_feature_dependencies d
    join public.platform_features f on f.key = d.feature_key
   where f.value_type in ('boolean', 'limit')
   limit 1;

  if v_dep_key is null then
    insert into probe values ('M1. dependency refusal uses the canonical code',
      'OK — no dependency declared to exercise');
  else
    -- Force the prerequisite off for this office, so the dependency gate fires.
    insert into public.office_feature_overrides
      (office_id, feature_key, value, reason, created_by)
    select v_office, d.requires_key, 'false'::jsonb, 'regression: force blocker',
           (select v from fixture where k = 'platform')::uuid
      from public.platform_feature_dependencies d
     where d.feature_key = v_dep_key
     limit 1
    on conflict do nothing;

    v_verdict := public.office_can_consume_for(v_office, v_dep_key, 1);

    insert into probe values ('M1. dependency refusal uses the canonical code',
      case
        when (v_verdict ->> 'allowed')::boolean then 'OK — not blocked here'
        when v_verdict ->> 'reason' = any(v_codes) then 'OK'
        else 'BROKEN — ' || coalesce(v_verdict ->> 'reason', 'null')
             || ' is not one of the six codes the client can classify'
      end);
  end if;

  -- Every reason the verdict can produce, across every catalogued feature, must be
  -- a code the client knows. This is the check that would have caught the drift.
  insert into probe values ('M2. no verdict invents a code the client cannot read',
    coalesce((
      select 'BROKEN — ' || string_agg(distinct r, ', ')
        from (
          select public.office_can_consume_for(v_office, f.key, 1) ->> 'reason' as r
            from public.platform_features f
           where f.status <> 'hidden'
        ) v
       where r is not null and not (r = any(v_codes))
    ), 'OK'));
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- N. Read-only suspension is REAL, not just a value in the resolver (§14.3)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Section G proves a suspended office RESOLVES to the restricted plan. It never
-- proved the office could not simply UPDATE and DELETE its way around it, because
-- until 20260808090000 it could: every gate was BEFORE INSERT.
--
-- The split under test is configuration vs operation. Configuration freezes;
-- operation never does, because a licensing action that strands a passenger is a
-- safety incident and not a billing event (decision 4).

do $$
declare
  v_office uuid := (select v::uuid from fixture where k = 'office_np');
  v_admin  uuid := (select v from fixture where k = 'admin_np')::uuid;
  v_driver uuid;
  v_route  uuid;
  v_trip   uuid;
  v_msg    text;
begin
  if v_office is null or v_admin is null then
    insert into probe values ('N0. read-only suspension',
      'INCONCLUSIVE — no office operator on this database who is not also a '
      'platform admin, and the freeze exempts platform admins by design');
    return;
  end if;

  -- Build the fixtures rather than hoping the office has some. The office chosen
  -- here is whichever one has a non-platform operator, and on a development
  -- database that is often the empty one — a "nothing to exercise" pass on the
  -- read-only gate would be a hollow green on the largest control in the audit.
  select id into v_driver from public.drivers where office_id = v_office limit 1;
  if v_driver is null then
    insert into public.drivers
      (office_id, employee_code, full_name, phone, emergency_phone, address,
       national_id, license_number, license_expiry_date, hire_date, status)
    values (v_office, 'LIC-REG-RO', 'سائق اختبار القراءة', '01000000961', '01000000962',
            'عنوان', '29900000000961', 'LN-RO', now() + interval '2 years', now(), 'active')
    returning id into v_driver;
  end if;

  select id into v_route from public.operation_routes where office_id = v_office limit 1;
  if v_route is null then
    insert into public.operation_routes
      (office_id, route_code, name, start_city, end_city, status)
    values (v_office, 'LIC-REG-RO', 'خط اختبار القراءة',
            'القاهرة', 'الإسكندرية', 'active')
    returning id into v_route;
  end if;

  select id into v_trip from public.operation_trips where office_id = v_office limit 1;

  update public.platform_settings set enforcement_mode = 'enforcing' where id;
  perform public.platform_set_license_status(v_office, 'suspended', 'اختبار القراءة فقط');

  -- Become the office's own owner: the gate is about what the OFFICE may do, and
  -- a platform admin is deliberately exempt (checked in N5).
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);

  ------------------------------------------------------------------ cannot modify
  if v_driver is null then
    insert into probe values ('N1. suspended office cannot modify configuration',
      'OK — no driver fixture to exercise');
  else
    begin
      update public.drivers set full_name = full_name || ' *' where id = v_driver;
      insert into probe values ('N1. suspended office cannot modify configuration',
        'BROKEN — the update succeeded');
    exception when others then
      get stacked diagnostics v_msg = message_text;
      insert into probe values ('N1. suspended office cannot modify configuration',
        case when v_msg = 'license_suspended' then 'OK'
             else 'BROKEN — code was ' || v_msg end);
    end;
  end if;

  ------------------------------------------------------------------ cannot delete
  if v_route is null then
    insert into probe values ('N2. suspended office cannot delete configuration',
      'OK — no route fixture to exercise');
  else
    begin
      delete from public.operation_routes where id = v_route;
      insert into probe values ('N2. suspended office cannot delete configuration',
        'BROKEN — the delete succeeded');
    exception when others then
      get stacked diagnostics v_msg = message_text;
      insert into probe values ('N2. suspended office cannot delete configuration',
        case when v_msg = 'license_suspended' then 'OK'
             else 'BROKEN — code was ' || v_msg end);
    end;
  end if;

  ------------------------------------------------- operations are NEVER frozen
  -- The one that matters most: a bus already carrying passengers must be able to
  -- reach the end of its route while the office argues about an invoice.
  -- Building a trip needs a driver, a vehicle, a route, pricing and seats, which
  -- is a lot of unrelated schema to get right inside a licensing test. When the
  -- office has no trip, assert the RULE structurally instead of skipping: the
  -- read-only family must own a BEFORE DELETE on operation_trips and must NOT own
  -- a BEFORE UPDATE, because that trigger is what would strand a moving bus.
  if v_trip is null then
    insert into probe values ('N3. a running trip can still be advanced',
      case when not exists (
             select 1 from pg_trigger t
               join pg_class c on c.oid = t.tgrelid
               join pg_proc  f on f.oid = t.tgfoid
              where c.relname = 'operation_trips'
                and f.proname = 'enforce_license_read_only'
                and (t.tgtype & 16) <> 0)          -- UPDATE bit
           then 'OK — no UPDATE freeze exists on trips, by construction'
           else 'BROKEN — a read-only trigger can block a trip in flight' end);
  else
    begin
      update public.operation_trips set updated_at = now() where id = v_trip;
      insert into probe values ('N3. a running trip can still be advanced', 'OK');
    exception when others then
      get stacked diagnostics v_msg = message_text;
      insert into probe values ('N3. a running trip can still be advanced',
        'BROKEN — a licensing action stranded a trip: ' || v_msg);
    end;
  end if;

  -- Trip DELETE is the exception, because deleting a trip destroys the record of
  -- the tickets sold against it.
  if v_trip is null then
    insert into probe values ('N4. a trip with sold tickets cannot be deleted',
      case when exists (
             select 1 from pg_trigger t
               join pg_class c on c.oid = t.tgrelid
               join pg_proc  f on f.oid = t.tgfoid
              where c.relname = 'operation_trips'
                and f.proname = 'enforce_license_read_only'
                and (t.tgtype & 8) <> 0)           -- DELETE bit
           then 'OK — the DELETE freeze is installed, by construction'
           else 'BROKEN — a held office can destroy a sold trip' end);
  else
    begin
      delete from public.operation_trips where id = v_trip;
      insert into probe values ('N4. a trip with sold tickets cannot be deleted',
        'BROKEN — the delete succeeded');
    exception when others then
      insert into probe values ('N4. a trip with sold tickets cannot be deleted', 'OK');
    end;
  end if;

  -------------------------------------------------------- the platform is exempt
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'platform'),
                      'role', 'authenticated')::text, true);

  if v_driver is null then
    insert into probe values ('N5. a platform admin can still repair a held tenant',
      'OK — no driver fixture to exercise');
  else
    begin
      update public.drivers set updated_at = now() where id = v_driver;
      insert into probe values ('N5. a platform admin can still repair a held tenant', 'OK');
    exception when others then
      get stacked diagnostics v_msg = message_text;
      insert into probe values ('N5. a platform admin can still repair a held tenant',
        'BROKEN — ' || v_msg);
    end;
  end if;

  ---------------------------------------------------------- restore lifts the freeze
  perform public.platform_set_license_status(v_office, 'active', 'انتهى الاختبار');

  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);

  if v_driver is null then
    insert into probe values ('N6. restore lifts the freeze', 'OK — no fixture');
  else
    begin
      update public.drivers set updated_at = now() where id = v_driver;
      insert into probe values ('N6. restore lifts the freeze', 'OK');
    exception when others then
      get stacked diagnostics v_msg = message_text;
      insert into probe values ('N6. restore lifts the freeze', 'BROKEN — ' || v_msg);
    end;
  end if;

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'platform'))::text, true);
  update public.platform_settings set enforcement_mode = 'off' where id;
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- O. A stock quota cannot be farmed by cycling status (§5.2, §5.4)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- max_drivers counts rows with status = 'active'. With an INSERT-only trigger the
-- limit was advisory:
--
--     at 5/5 → deactivate one (4/5) → create a sixth (allowed) → re-activate the
--     fifth → six active drivers on a five-driver plan.
--
-- This reproduces that exact sequence and requires the last step to be refused.

do $$
declare
  v_office uuid := (select v::uuid from fixture where k = 'office_a');
  v_live   int;
  v_victim uuid;
  v_msg    text;
  v_final  int;
begin
  update public.platform_settings set enforcement_mode = 'enforcing' where id;

  v_live := (select count(*) from public.drivers
              where office_id = v_office and status = 'active');
  select id into v_victim from public.drivers
   where office_id = v_office and status = 'active' limit 1;

  if v_victim is null then
    insert into probe values ('O1. re-activation is metered',
      'OK — no active driver fixture to exercise');
    insert into probe values ('O2. the seat freed by deactivation is only lent once',
      'OK — no active driver fixture to exercise');
  else
    -- Pin the limit to exactly what the office has today.
    perform public.platform_set_override(v_office, 'max_drivers', to_jsonb(v_live),
      'اختبار حد المخزون عند التحديث');

    -- Step 1: free a seat. `suspended` and not `inactive`: drivers.status is
    -- CHECK-constrained to active | suspended | archived, and office_usage_stock
    -- counts only `active`, so suspending is exactly "gives the seat back".
    update public.drivers set status = 'suspended' where id = v_victim;

    -- Step 2: spend it. This must be allowed — the office is under its limit.
    insert into public.drivers
      (office_id, employee_code, full_name, phone, emergency_phone, address,
       national_id, license_number, license_expiry_date, hire_date, status)
    values (v_office, 'LIC-REG-CYCLE', 'سائق دورة الحد', '01000000941', '01000000942',
            'عنوان', '29900000000941', 'LN-CYCLE', now() + interval '2 years', now(), 'active');

    insert into probe values ('O2. the seat freed by deactivation is only lent once',
      case when (select count(*) from public.drivers
                  where office_id = v_office and status = 'active') = v_live
           then 'OK — back at the limit' else 'BROKEN — accounting is off' end);

    -- Step 3: take it back. THIS is the bypass, and it must fail.
    begin
      update public.drivers set status = 'active' where id = v_victim;
      insert into probe values ('O1. re-activation is metered',
        'BROKEN — the limit can be farmed by cycling status');
    exception when others then
      get stacked diagnostics v_msg = message_text;
      insert into probe values ('O1. re-activation is metered',
        case when v_msg = 'quota_exceeded' then 'OK'
             else 'BROKEN — code was ' || v_msg end);
    end;

    -- Nothing existing was harmed by any of it (§5.4).
    v_final := (select count(*) from public.drivers where office_id = v_office);
    insert into probe values ('O3. nothing existing was deleted or disabled by the gate',
      case when v_final >= v_live then 'OK' else 'BROKEN' end);

    delete from public.drivers where employee_code = 'LIC-REG-CYCLE';
    update public.drivers set status = 'active' where id = v_victim;
    perform public.platform_clear_override(v_office, 'max_drivers', 'تنظيف الاختبار');
  end if;

  update public.platform_settings set enforcement_mode = 'off' where id;
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- P. Every gate the catalog claims actually exists, and the new ones bite
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_office uuid := (select v::uuid from fixture where k = 'office_a');
  v_admin  uuid := (select v from fixture where k = 'admin_a')::uuid;
  v_missing text;
  v_msg     text;
  v_used_before bigint;
  v_used_after  bigint;
begin
  ---------------------------------------------------------- the registry is honest
  -- enforcement_status is derived from platform_feature_gates by trigger, so this
  -- can only fail if someone wrote the column by hand.
  select string_agg(f.key, ', ' order by f.key) into v_missing
    from public.platform_features f
   where f.enforcement_status = 'enforced'
     and not exists (select 1 from public.platform_feature_gates g
                      where g.feature_key = f.key);
  insert into probe values ('P1. no feature claims `enforced` without a gate',
    coalesce('BROKEN — ' || v_missing, 'OK'));

  -- The eleven features the audit gated. If one of them silently reverts to
  -- `declared`, the console starts telling the truth again and the plan starts
  -- lying — this is the check that notices.
  select string_agg(k, ', ' order by k) into v_missing
    from unnest(array['bookings','support_tickets','notifications','push_notifications',
                      'export_pdf','export_excel','max_exports_per_month',
                      'max_storage_mb','logo_max_kb','reports','finance',
                      'live_ops_center','report_level','analytics_level']) k
   where not exists (select 1 from public.platform_features f
                      where f.key = k and f.enforcement_status = 'enforced');
  insert into probe values ('P2. the audit''s new gates are all still registered',
    coalesce('BROKEN — back to declared: ' || v_missing, 'OK'));

  -- And the three that honestly cannot be gated yet stay honest. A gate row
  -- appearing here would mean someone claimed enforcement the code does not have.
  select string_agg(k, ', ' order by k) into v_missing
    from unnest(array['referrals','promotions','loyalty']) k
   where exists (select 1 from public.platform_features f
                  where f.key = k and f.enforcement_status = 'enforced');
  insert into probe values ('P3. features with no office-scoped surface stay `declared`',
    coalesce('BROKEN — claims enforcement it does not have: ' || v_missing, 'OK'));

  ---------------------------------------------------------------- the gates bite
  update public.platform_settings set enforcement_mode = 'enforcing' where id;
  perform public.platform_set_override(v_office, 'bookings', 'false'::jsonb,
    'اختبار بوابة الحجوزات');

  begin
    -- Only the columns with no default, so this stays a licensing test and not a
    -- schema test.
    insert into public.operation_bookings
      (passenger_name, phone, route, trip_time, trip_date, seat, payment_method,
       office_id)
    values ('راكب اختبار', '01000000951', 'اختبار', '08:00', current_date, '1',
            'cash', v_office);
    insert into probe values ('P4. the bookings gate refuses a new reservation',
      'BROKEN — the insert succeeded');
  exception
    when others then
      get stacked diagnostics v_msg = message_text;
      insert into probe values ('P4. the bookings gate refuses a new reservation',
        case when v_msg = 'feature_not_licensed' then 'OK'
             -- A schema-shaped failure is not what this check is about; it is
             -- reported rather than silently passed.
             else 'INCONCLUSIVE — ' || v_msg end);
  end;

  perform public.platform_clear_override(v_office, 'bookings', 'تنظيف الاختبار');

  ------------------------------------------------------- the export meter is real
  -- Grant the licence explicitly rather than inheriting whatever plan an earlier
  -- section left the office on: this check is about the METER, and it must not
  -- pass or fail for the unrelated reason that exports happened to be off.
  -- `reports` too, because export_pdf declares it as a prerequisite and the
  -- dependency gate would otherwise collapse the grant to false.
  perform public.platform_set_override(v_office, 'reports', 'true'::jsonb,
    'اختبار حصة التصدير');
  perform public.platform_set_override(v_office, 'export_pdf', 'true'::jsonb,
    'اختبار حصة التصدير');
  perform public.platform_set_override(v_office, 'max_exports_per_month', '1'::jsonb,
    'اختبار حصة التصدير');
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  v_used_before := public.office_usage_for(v_office, 'max_exports_per_month');
  perform public.office_consume_export('pdf');
  v_used_after := public.office_usage_for(v_office, 'max_exports_per_month');

  insert into probe values ('P5. an export consumes a metered unit server-side',
    case when v_used_after = v_used_before + 1 then 'OK'
         else 'BROKEN — the meter did not move' end);

  begin
    perform public.office_consume_export('pdf');
    insert into probe values ('P6. the export quota refuses the next one',
      'BROKEN — the quota is advisory');
  exception when others then
    get stacked diagnostics v_msg = message_text;
    insert into probe values ('P6. the export quota refuses the next one',
      case when v_msg = 'quota_exceeded' then 'OK' else 'BROKEN — ' || v_msg end);
  end;

  ------------------------------------- an unlicensed office cannot push notifications
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'platform'))::text, true);
  perform public.platform_set_override(v_office, 'push_notifications', 'false'::jsonb,
    'اختبار بوابة الإشعارات');
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  begin
    perform public.office_dispatch_notification(v_admin, 'عنوان', 'نص');
    insert into probe values ('P7. notification dispatch is gated',
      'BROKEN — it sent');
  exception when others then
    get stacked diagnostics v_msg = message_text;
    insert into probe values ('P7. notification dispatch is gated',
      case when v_msg = 'feature_not_licensed' then 'OK'
           else 'BROKEN — code was ' || v_msg end);
  end;

  -- …and even a licensed one cannot reach outside its own audience. This is the
  -- cross-tenant hole the replaced INSERT policy left open.
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'platform'))::text, true);
  -- GRANT it, do not merely clear the override: the office is on whatever plan the
  -- lifecycle section left it, and `starter` has push_notifications = false. A
  -- refusal on the entitlement axis would look like a pass while proving nothing
  -- about the scope check this row exists for.
  perform public.platform_set_override(v_office, 'notifications', 'true'::jsonb,
    'اختبار نطاق المستقبِلين');
  perform public.platform_set_override(v_office, 'push_notifications', 'true'::jsonb,
    'اختبار نطاق المستقبِلين');
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  begin
    perform public.office_dispatch_notification(
      (select v::uuid from fixture where k = 'admin_b'), 'عنوان', 'نص');
    insert into probe values ('P8. an office cannot notify another office''s people',
      'LEAK — it sent');
  exception when others then
    get stacked diagnostics v_msg = message_text;
    insert into probe values ('P8. an office cannot notify another office''s people',
      case when v_msg = 'recipient_not_in_office' then 'OK'
           else 'BROKEN — refused for the wrong reason: ' || v_msg end);
  end;

  -- …and the same RPC, licensed and correctly scoped, must actually send.
  begin
    perform public.office_dispatch_notification(v_admin, 'عنوان', 'نص');
    insert into probe values ('P9. a licensed office can notify its own people', 'OK');
  exception when others then
    get stacked diagnostics v_msg = message_text;
    insert into probe values ('P9. a licensed office can notify its own people',
      'BROKEN — ' || v_msg);
  end;

  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'platform'))::text, true);
  perform public.platform_clear_override(v_office, 'max_exports_per_month', 'تنظيف الاختبار');
  perform public.platform_clear_override(v_office, 'push_notifications', 'تنظيف الاختبار');
  perform public.platform_clear_override(v_office, 'notifications', 'تنظيف الاختبار');
  perform public.platform_clear_override(v_office, 'export_pdf', 'تنظيف الاختبار');
  perform public.platform_clear_override(v_office, 'reports', 'تنظيف الاختبار');
  update public.platform_settings set enforcement_mode = 'off' where id;
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- Q. All six refusal codes are reachable (§7.2)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- `license_expired` was documented, mapped in Dart, given its own renewal card —
-- and unreachable, because both enforcement paths collapsed all three held states
-- onto `license_suspended`. A code that can never be produced is a UI branch that
-- can never be shown.

do $$
declare
  v_office uuid := (select v::uuid from fixture where k = 'office_a');
  v_v      jsonb;
begin
  update public.platform_settings set enforcement_mode = 'enforcing' where id;

  perform public.platform_set_license_status(v_office, 'expired', 'اختبار كود الانتهاء');
  v_v := public.office_can_consume_for(v_office, 'max_drivers', 1);
  insert into probe values ('Q1. an expired licence says `license_expired`',
    case when v_v ->> 'reason' = 'license_expired' then 'OK'
         else 'BROKEN — ' || coalesce(v_v ->> 'reason', 'null') end);

  perform public.platform_set_license_status(v_office, 'suspended', 'اختبار كود الإيقاف');
  v_v := public.office_can_consume_for(v_office, 'max_drivers', 1);
  insert into probe values ('Q2. a suspended licence says `license_suspended`',
    case when v_v ->> 'reason' = 'license_suspended' then 'OK'
         else 'BROKEN — ' || coalesce(v_v ->> 'reason', 'null') end);

  perform public.platform_set_license_status(v_office, 'active', 'انتهى الاختبار');
  update public.platform_settings set enforcement_mode = 'off' where id;
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- R. The kill switch reaches every gate (§15.3)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- "enforcement_mode = 'off' restores current behaviour instantly at any point" is
-- the promise the whole rollout rests on. Three client-facing predicates resolved
-- features WITHOUT asking the mode, so a plan value could withdraw a marketplace
-- surface while the subsystem was supposedly disabled.

do $$
declare
  v_office uuid := (select v::uuid from fixture where k = 'office_a');
  v_trip   uuid;
begin
  select id into v_trip from public.operation_trips where office_id = v_office limit 1;

  -- Withdraw three client-facing features outright, then turn enforcement OFF.
  -- Every one of them must behave as though the subsystem did not exist.
  perform public.platform_set_override(v_office, 'passenger_packages', 'false'::jsonb,
    'اختبار مفتاح الإيقاف');
  perform public.platform_set_override(v_office, 'live_tracking', 'false'::jsonb,
    'اختبار مفتاح الإيقاف');
  perform public.platform_set_override(v_office, 'client_app', 'false'::jsonb,
    'اختبار مفتاح الإيقاف');
  update public.platform_settings set enforcement_mode = 'off' where id;

  insert into probe values ('R1. mode=off: packages stay on the marketplace',
    case when public.office_sells_packages(v_office) then 'OK'
         else 'BROKEN — a disabled subsystem hid a surface' end);

  insert into probe values ('R2. mode=off: live tracking keeps working',
    case when v_trip is null then 'OK — no trip fixture'
         when public.trip_tracking_licensed(v_trip) then 'OK'
         else 'BROKEN — a disabled subsystem hid the map' end);

  insert into probe values ('R3. mode=off: the office stays listed',
    case when public.office_is_listed(v_office) then 'OK'
         else 'BROKEN — a disabled subsystem delisted an office' end);

  -- …and the moment it is on, all three answer the other way, without anybody
  -- touching the offices table by hand.
  update public.platform_settings set enforcement_mode = 'enforcing' where id;

  insert into probe values ('R4. mode=enforcing: the same three gates now bite',
    case when not public.office_sells_packages(v_office)
          and (v_trip is null or not public.trip_tracking_licensed(v_trip))
          and not public.office_is_listed(v_office)
         then 'OK' else 'BROKEN — a gate ignored the switch' end);

  insert into probe values ('R5. flipping the switch reprojects licensing_hold',
    case when (select licensing_hold from public.offices where id = v_office) = 'delisted'
         then 'OK — the projection followed the mode'
         else 'BROKEN — holds went stale at the flip' end);

  update public.platform_settings set enforcement_mode = 'off' where id;
  perform public.platform_clear_override(v_office, 'passenger_packages', 'تنظيف الاختبار');
  perform public.platform_clear_override(v_office, 'live_tracking', 'تنظيف الاختبار');
  perform public.platform_clear_override(v_office, 'client_app', 'تنظيف الاختبار');
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- S. The plan matrix, end to end
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- One row per plan, asserting the shape the design sells rather than any single
-- value: what separates Starter from Professional, what Enterprise adds, and the
-- two non-public plans that exist for one job each.

do $$
declare
  v_plan record;
  v_val  text;
begin
  for v_plan in select id, key from public.platform_plans order by key loop
    case v_plan.key

      when 'starter' then
        insert into probe values ('S1. starter: limited, no money features',
          case when (public.platform_resolve_feature(null, v_plan.id, 'max_drivers') #>> '{value}') = '5'
                and (public.platform_resolve_feature(null, v_plan.id, 'wallet')      ->> 'value') = 'false'
                and (public.platform_resolve_feature(null, v_plan.id, 'refunds')     ->> 'value') = 'false'
                and (public.platform_resolve_feature(null, v_plan.id, 'client_app')  ->> 'value') = 'true'
               then 'OK' else 'BROKEN' end);

      when 'professional' then
        insert into probe values ('S2. professional: money features on, limits raised',
          case when (public.platform_resolve_feature(null, v_plan.id, 'max_drivers') #>> '{value}') = '25'
                and (public.platform_resolve_feature(null, v_plan.id, 'wallet')   ->> 'value') = 'true'
                and (public.platform_resolve_feature(null, v_plan.id, 'cashback') ->> 'value') = 'true'
               then 'OK' else 'BROKEN' end);

      when 'enterprise' then
        insert into probe values ('S3. enterprise: unlimited everywhere',
          case when not exists (
                 select 1 from public.platform_features f
                  where f.value_type = 'limit'
                    and f.key in ('max_drivers','max_vehicles','max_routes',
                                  'max_trips_per_month','max_admin_users')
                    and (public.platform_resolve_feature(null, v_plan.id, f.key) #>> '{value}')
                        <> 'unlimited')
               then 'OK' else 'BROKEN' end);

      when 'founder' then
        insert into probe values ('S4. founder: unlimited and not self-selectable',
          case when (select not is_public from public.platform_plans where id = v_plan.id)
                and (public.platform_resolve_feature(null, v_plan.id, 'max_drivers') #>> '{value}') = 'unlimited'
               then 'OK' else 'BROKEN' end);

      when 'restricted' then
        -- The fallback plan does exactly two things: stop new commitments, and
        -- refuse to strand anybody who already has one.
        insert into probe values ('S5. restricted: creation off, in-flight untouched',
          case when (public.platform_resolve_feature(null, v_plan.id, 'max_drivers')          #>> '{value}') = '0'
                and (public.platform_resolve_feature(null, v_plan.id, 'max_trips_per_month')  #>> '{value}') = '0'
                and (public.platform_resolve_feature(null, v_plan.id, 'max_live_trips')       #>> '{value}') = 'unlimited'
                and (public.platform_resolve_feature(null, v_plan.id, 'max_captains')         #>> '{value}') = 'unlimited'
                and (public.platform_resolve_feature(null, v_plan.id, 'driver_app')           ->> 'value')   = 'true'
                and (public.platform_resolve_feature(null, v_plan.id, 'client_app')           ->> 'value')   = 'false'
               then 'OK' else 'BROKEN' end);

      else null;
    end case;
  end loop;

  -- The dependency law, read off the plans rather than from a synthetic office:
  -- no plan may sell a feature whose prerequisite it withholds, because the
  -- resolver would collapse it and the customer would have bought nothing.
  select string_agg(distinct p.key || '/' || d.feature_key, ', ') into v_val
    from public.platform_plans p
    join public.platform_feature_dependencies d on true
   where p.status <> 'archived'
     and public.platform_value_is_truthy(
           public.platform_resolve_feature(null, p.id, d.feature_key) -> 'value')
     and not public.platform_value_meets(
           d.requires_key,
           public.platform_resolve_feature(null, p.id, d.requires_key) -> 'value',
           d.min_value);
  insert into probe values ('S6. no plan sells a feature its own prerequisites defeat',
    coalesce('BROKEN — ' || v_val, 'OK'));
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- T. The flip is a no-op for the incumbents (Part 15 step 3)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- The single most important property of enabling enforcement: the offices that
-- were here before the licensing system existed must not notice it happened.

do $$
declare
  v_office   uuid;
  v_bad      text;
  v_founder  uuid := (select id from public.platform_plans where key = 'founder');
begin
  update public.platform_settings set enforcement_mode = 'enforcing' where id;

  -- T1 reads the SNAPSHOT taken in the fixture block, not the live tables:
  -- sections F–Q suspend, expire and re-plan office_a inside this transaction, so
  -- the live rows here describe the test run rather than the platform. The
  -- snapshot is what the flip actually lands on.
  insert into probe values ('T1. every incumbent shipped on founder, active, unheld',
    coalesce('BROKEN — ' || (select v from fixture where k = 'incumbent_drift'), 'OK'));

  -- T2 asks the founder plan itself, for the limits that are actually ENFORCED.
  -- `max_branches` and `max_api_calls_per_month` are declared-only features with
  -- restrictive catalog defaults and no plan value; including them would fail a
  -- check about grandfathering for a reason that has nothing to do with it.
  select string_agg(f.key, ', ' order by f.key) into v_bad
    from public.platform_features f
   where f.value_type = 'limit'
     and f.enforcement_status = 'enforced'
     and (public.platform_resolve_feature(null, v_founder, f.key) #>> '{value}') <> 'unlimited';
  insert into probe values ('T2. the founder plan is unlimited in every enforced limit',
    coalesce('BROKEN — ' || v_bad, 'OK'));

  select string_agg(o.name, ', ') into v_bad
    from public.offices o
   where not public.office_license_writes_allowed(o.id);
  insert into probe values ('T3. no office is in a read-only hold after the flip',
    coalesce('BROKEN — ' || v_bad, 'OK'));

  select string_agg(o.name, ', ') into v_bad
    from public.offices o
   where o.listing_status = 'listed'
     and o.status = 'active'
     and not public.office_is_listed(o.id);
  insert into probe values ('T4. no listed office was delisted by the flip',
    coalesce('BROKEN — ' || v_bad, 'OK'));

  update public.platform_settings set enforcement_mode = 'off' where id;
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- U. TRUNCATE cannot step around any of it
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Row-level security gates SELECT/INSERT/UPDATE/DELETE. It does not gate TRUNCATE,
-- and neither do row triggers — so a client role holding the privilege walks past
-- every quota trigger, every feature gate and the read-only freeze in one statement.
-- Before 20260808090200, `authenticated` held it on five of the eleven tables the
-- freeze had just been installed on.

do $$
declare
  v_left text;
begin
  select string_agg(c.relname, ', ' order by c.relname) into v_left
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relkind = 'r'
     and (has_table_privilege('authenticated', c.oid, 'TRUNCATE')
          or has_table_privilege('anon', c.oid, 'TRUNCATE'));
  insert into probe values ('U1. no client role can TRUNCATE past a gate',
    coalesce('BROKEN — ' || v_left, 'OK'));

  -- The default privilege is the part that keeps it true: without it the next table
  -- anybody creates reopens the hole and nothing notices.
  -- Scoped to the `postgres`-owned default ACL: migrations run as postgres, so that
  -- entry governs every table this repo will ever create. The supabase_admin entry
  -- covers tables the platform itself creates and is not alterable from here — named
  -- in 20260808090200 rather than asserted on.
  select string_agg(e.grantee || '=' || e.privs, ', ') into v_left
    from pg_default_acl d
    join pg_namespace n on n.oid = d.defaclnamespace
   cross join lateral (
     select split_part(a, '=', 1) as grantee,
            split_part(split_part(a, '=', 2), '/', 1) as privs
       from unnest(d.defaclacl::text[]) a
   ) e
   where n.nspname = 'public'
     and d.defaclobjtype = 'r'
     and pg_get_userbyid(d.defaclrole) = 'postgres'
     and e.grantee in ('anon', 'authenticated')
     and e.privs like '%D%';
  insert into probe values ('U2. new tables do not reopen the hole',
    coalesce('BROKEN — default privileges still hand out TRUNCATE: ' || v_left,
             'OK — the default grant omits TRUNCATE'));
end $$;


-- Restore whatever the platform actually ships in, so a suite run leaves nothing
-- behind even if the surrounding transaction is somehow committed.
do $$
begin
  update public.platform_settings
     set enforcement_mode = (select v from fixture where k = 'shipped_mode')
   where id;
end $$;


select step, result from probe order by step;

rollback;
