-- ═══════════════════════════════════════════════════════════════════════════════════
-- Regression suite: platform office management
-- (migration 20260722090000_platform_office_management.sql)
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Covers the READING half of platform administration: the widened
-- `platform_list_offices()` and the new `platform_office_details()`.
--
-- Self-contained: builds a platform admin, two offices with operators, fleet and
-- traffic of their own, exercises the authorization boundary from both sides, checks
-- the counts are office-scoped rather than platform-wide, and asserts the private
-- surfaces these functions must never open. Then ROLLS EVERYTHING BACK.
--
-- Run as postgres (e.g. the Management API query endpoint): the script switches to
-- `role authenticated` with a forged request.jwt.claims to act as each principal, and
-- back to postgres for RLS-bypassing truth assertions.
--
-- Output: one row per check; the final DO block raises listing any failures.

begin;

create temporary table _pom_results (seq serial, name text, pass boolean, detail text)
  on commit drop;
grant all on _pom_results to authenticated;
grant all on _pom_results_seq_seq to authenticated;

-- ── Fixtures (all rolled back) ──────────────────────────────────────────────────────
--
-- Office M: listed and trading — one route, one trip, one vehicle, one driver.
-- Office N: draft with a blank card — the office that must not be publishable, and
--           whose data must never be counted into M's totals.

do $fix$
begin
  insert into public.offices (id, name, slug, status, listing_status, description,
                              service_areas, phone, email)
  values
    ('11f30000-0000-4000-8000-00000000001a', 'TEST-POM Office M', 'test-pom-m',
     'active', 'listed', 'مكتب اختبار الإدارة', array['TESTPOM-Alex'],
     '+201000000001', 'm@test-pom.invalid'),
    ('22f30000-0000-4000-8000-00000000002a', 'TEST-POM Office N', 'test-pom-n',
     'active', 'draft', '', array[]::text[], null, null);

  insert into auth.users (id, email, raw_user_meta_data) values
    ('99f30000-0000-4000-8000-0000000000f9', 'test-pom-platadmin@pom.invalid',
     '{"full_name":"TEST-POM Platform Admin","role":"office_user"}'::jsonb),
    ('11f30000-0000-4000-8000-0000000000d1', 'test-pom-op-m@pom.invalid',
     '{"full_name":"TEST-POM Owner M","role":"office_user"}'::jsonb),
    ('22f30000-0000-4000-8000-0000000000d2', 'test-pom-op-n@pom.invalid',
     '{"full_name":"TEST-POM Owner N","role":"office_user"}'::jsonb);

  -- The platform admin is an operator of N, not of M: the office an admin belongs to
  -- must be irrelevant to what platform administration can read, and putting them in
  -- the *other* office is what makes that assertion mean something.
  insert into public.office_users
        (office_id, user_id, username, full_name, role, status, created_at) values
    ('22f30000-0000-4000-8000-00000000002a', '99f30000-0000-4000-8000-0000000000f9',
     'test-pom-platadmin', 'TEST-POM Platform Admin', 'dashboard_admin', 'active',
     now() - interval '1 hour'),
    ('11f30000-0000-4000-8000-00000000001a', '11f30000-0000-4000-8000-0000000000d1',
     'test-pom-owner-m', 'TEST-POM Owner M', 'dashboard_admin', 'active',
     now() - interval '2 hour'),
    ('22f30000-0000-4000-8000-00000000002a', '22f30000-0000-4000-8000-0000000000d2',
     'test-pom-owner-n', 'TEST-POM Owner N', 'dashboard_admin', 'active', now());

  insert into public.platform_admins (user_id, note)
  values ('99f30000-0000-4000-8000-0000000000f9', 'TEST-POM fixture');

  -- Office M's operational data.
  insert into public.operation_routes
        (id, name, start_city, end_city, status, route_code, office_id)
  values ('11f30000-0000-4000-8000-0000000000a1', 'TEST-POM Route M', 'CityM1', 'CityM2',
          'active', 'RT-TEST-POM-M', '11f30000-0000-4000-8000-00000000001a');

  insert into public.operation_trips
        (id, trip_code, route_id, trip_date, departure_time, arrival_time,
         status, capacity, ticket_price, currency, office_id)
  values ('11f30000-0000-4000-8000-0000000000b1', 'TR-TEST-POM-M',
          '11f30000-0000-4000-8000-0000000000a1', current_date + 3, '09:00', '11:00',
          'open_for_booking', 4, 100, 'EGP', '11f30000-0000-4000-8000-00000000001a');

  insert into public.vehicles
        (id, vehicle_code, plate_number, vehicle_type, brand, model, manufacture_year,
         color, capacity, seat_layout_type, status, office_id)
  values ('11f30000-0000-4000-8000-0000000000c1', 'VH-TEST-POM-M', 'TEST-POM-M-01',
          'minibus', 'Toyota', 'Hiace', 2020, 'white', 14, '2-2', 'active',
          '11f30000-0000-4000-8000-00000000001a');

  insert into public.drivers
        (id, employee_code, full_name, phone, emergency_phone, address, national_id,
         license_number, license_expiry_date, hire_date, status, office_id)
  values ('11f30000-0000-4000-8000-0000000000e1', 'DR-TEST-POM-M', 'TEST-POM Driver M',
          '+201555000001', '+201555000002', 'TEST-POM address', '29001010100011',
          'LIC-TEST-POM-M', current_date + 365, current_date - 30, 'active',
          '11f30000-0000-4000-8000-00000000001a');

  -- Office N's, which must stay out of M's counts.
  insert into public.operation_routes
        (id, name, start_city, end_city, status, route_code, office_id)
  values ('22f30000-0000-4000-8000-0000000000a2', 'TEST-POM Route N', 'CityN1', 'CityN2',
          'active', 'RT-TEST-POM-N', '22f30000-0000-4000-8000-00000000002a');

  insert into public.vehicles
        (id, vehicle_code, plate_number, vehicle_type, brand, model, manufacture_year,
         color, capacity, seat_layout_type, status, office_id)
  values ('22f30000-0000-4000-8000-0000000000c2', 'VH-TEST-POM-N', 'TEST-POM-N-01',
          'bus', 'Toyota', 'Coaster', 2019, 'blue', 20, '2-2', 'active',
          '22f30000-0000-4000-8000-00000000002a');
end $fix$;

-- ═══ 1. Authorization ═══════════════════════════════════════════════════════════════
-- The single boundary both functions rest on. An office admin is the realistic
-- attacker here: authenticated, legitimate, and holding a session the client could
-- forge `is_platform_admin: true` into.

select set_config('request.jwt.claims',
  '{"sub":"11f30000-0000-4000-8000-0000000000d1","role":"authenticated"}', true);
set local role authenticated;

do $$
declare v_err text;
begin
  begin
    perform count(*) from public.platform_list_offices();
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _pom_results (name, pass, detail)
  values ('Office admin cannot list platform offices',
          v_err like '%platform_admin_required%', v_err);
end $$;

-- Their OWN office id, not another's: if the guard were scoped rather than absolute,
-- this is the call that would slip through, and it is the one that would hand an
-- office admin a surface their dashboard does not otherwise give them.
do $$
declare v_err text;
begin
  begin
    perform public.platform_office_details('11f30000-0000-4000-8000-00000000001a');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _pom_results (name, pass, detail)
  values ('Office admin cannot read details of their own office via the platform RPC',
          v_err like '%platform_admin_required%', v_err);
end $$;

do $$
declare v_err text;
begin
  begin
    perform public.platform_office_details('22f30000-0000-4000-8000-00000000002a');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _pom_results (name, pass, detail)
  values ('Office admin cannot read details of ANOTHER office',
          v_err like '%platform_admin_required%', v_err);
end $$;

reset role;

-- Neither function is reachable without a session at all.
insert into _pom_results (name, pass, detail)
select 'Neither platform read function is granted to anon',
       count(*) = 0,
       coalesce(string_agg(p.proname, ', '), 'none')
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('platform_list_offices', 'platform_office_details')
   and has_function_privilege('anon', p.oid, 'execute');

-- ═══ 2. The platform admin sees the whole platform ══════════════════════════════════

select set_config('request.jwt.claims',
  '{"sub":"99f30000-0000-4000-8000-0000000000f9","role":"authenticated"}', true);
set local role authenticated;

-- The point of the function: the draft office is the one nobody else can see, and it
-- is exactly the one needing attention.
insert into _pom_results (name, pass, detail)
select 'Platform admin sees both the listed and the draft office',
       count(*) = 2, count(*)::text
  from public.platform_list_offices()
 where name like 'TEST-POM%';

insert into _pom_results (name, pass, detail)
select 'List reports the office owner resolved from office_users',
       owner_name = 'TEST-POM Owner M' and owner_username = 'test-pom-owner-m',
       coalesce(owner_name, 'null') || ' / ' || coalesce(owner_username, 'null')
  from public.platform_list_offices()
 where slug = 'test-pom-m';

-- The five columns this migration added, all scoped to office M. Office N owns a route
-- and a vehicle too; if any of these leaked to a platform-wide count they would read 2.
insert into _pom_results (name, pass, detail)
select 'List counts are office-scoped, not platform-wide',
       vehicles = 1 and routes = 1 and trips = 1 and drivers = 1 and operators = 1,
       format('vehicles=%s routes=%s trips=%s drivers=%s operators=%s',
              vehicles, routes, trips, drivers, operators)
  from public.platform_list_offices()
 where slug = 'test-pom-m';

insert into _pom_results (name, pass, detail)
select 'List exposes updated_at for staleness triage',
       updated_at is not null, coalesce(updated_at::text, 'null')
  from public.platform_list_offices()
 where slug = 'test-pom-m';

-- ═══ 3. Details: shape and scoping ══════════════════════════════════════════════════

insert into _pom_results (name, pass, detail)
select 'Details returns the office identity',
       d ->> 'name' = 'TEST-POM Office M'
       and d ->> 'listing_status' = 'listed'
       and d ->> 'status' = 'active',
       format('%s / %s / %s', d ->> 'name', d ->> 'status', d ->> 'listing_status')
  from public.platform_office_details('11f30000-0000-4000-8000-00000000001a') d;

insert into _pom_results (name, pass, detail)
select 'Details counts are office-scoped',
       (d -> 'counts' ->> 'vehicles')::int = 1
       and (d -> 'counts' ->> 'routes')::int = 1
       and (d -> 'counts' ->> 'trips')::int = 1
       and (d -> 'counts' ->> 'drivers')::int = 1,
       d -> 'counts' #>> '{}'
  from public.platform_office_details('11f30000-0000-4000-8000-00000000001a') d;

insert into _pom_results (name, pass, detail)
select 'Details lists the office operators',
       jsonb_array_length(d -> 'operators') = 1
       and d -> 'operators' -> 0 ->> 'username' = 'test-pom-owner-m',
       d -> 'operators' #>> '{}'
  from public.platform_office_details('11f30000-0000-4000-8000-00000000001a') d;

do $$
declare v_err text;
begin
  begin
    perform public.platform_office_details('00000000-0000-4000-8000-000000000000');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _pom_results (name, pass, detail)
  values ('Details raises office_not_found for an unknown id',
          v_err like '%office_not_found%', v_err);
end $$;

-- ═══ 4. The marketplace preview matches what clients actually see ═══════════════════
-- The preview reads `public_offices`. That is the whole point: it cannot show a field
-- the client view stopped exposing, and it cannot claim visibility the view does not
-- grant. A draft office has no row there, so the key is null — the honest rendering of
-- "a passenger sees nothing".

insert into _pom_results (name, pass, detail)
select 'Listed office has a marketplace preview',
       d -> 'marketplace' is not null
       and d -> 'marketplace' ->> 'name' = 'TEST-POM Office M',
       coalesce(d -> 'marketplace' #>> '{}', 'null')
  from public.platform_office_details('11f30000-0000-4000-8000-00000000001a') d;

insert into _pom_results (name, pass, detail)
select 'Draft office has NO marketplace preview',
       d -> 'marketplace' is null or d ->> 'marketplace' is null,
       coalesce(d -> 'marketplace' #>> '{}', 'null')
  from public.platform_office_details('22f30000-0000-4000-8000-00000000002a') d;

-- The preview must not become a back door into columns the client view withholds.
insert into _pom_results (name, pass, detail)
select 'Marketplace preview withholds phone, email and status',
       not (d -> 'marketplace' ? 'phone')
       and not (d -> 'marketplace' ? 'email')
       and not (d -> 'marketplace' ? 'status'),
       coalesce(d -> 'marketplace' #>> '{}', 'null')
  from public.platform_office_details('11f30000-0000-4000-8000-00000000001a') d;

-- ═══ 5. Private surfaces stay shut ══════════════════════════════════════════════════
-- What these functions must never carry out, stated as assertions rather than left to
-- a reading of the SQL.

insert into _pom_results (name, pass, detail)
select 'Details exposes no auth.users email for any operator',
       not exists (
         select 1 from jsonb_array_elements(d -> 'operators') op
          where op ? 'email' or op ? 'password' or op ? 'user_id'),
       d -> 'operators' #>> '{}'
  from public.platform_office_details('11f30000-0000-4000-8000-00000000001a') d;

insert into _pom_results (name, pass, detail)
select 'Details exposes no join code',
       not (d ? 'join_code'), coalesce(d ->> 'join_code', 'absent')
  from public.platform_office_details('11f30000-0000-4000-8000-00000000001a') d;

-- `counts` is a magnitude surface. If a booking row, a passenger name or a driver
-- phone ever appears here it stops being one.
insert into _pom_results (name, pass, detail)
select 'Details returns booking/review magnitudes, never rows',
       jsonb_typeof(d -> 'counts' -> 'bookings') = 'number'
       and jsonb_typeof(d -> 'counts' -> 'reviews') = 'number',
       d -> 'counts' #>> '{}'
  from public.platform_office_details('11f30000-0000-4000-8000-00000000001a') d;

-- ═══ 6. Listing transitions still run through the one existing RPC ══════════════════
-- This migration adds no listing path of its own. Re-asserted here because the reading
-- half would be a tempting place to grow one.

do $$
declare v_err text;
begin
  begin
    perform public.platform_set_office_listing(
      '22f30000-0000-4000-8000-00000000002a', 'listed');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _pom_results (name, pass, detail)
  values ('An office with a blank card still cannot be listed',
          v_err like '%office_profile_incomplete%', v_err);
end $$;

do $$
declare v_state text;
begin
  perform public.platform_set_office_listing(
    '11f30000-0000-4000-8000-00000000001a', 'unlisted');
  select d ->> 'listing_status' into v_state
    from public.platform_office_details('11f30000-0000-4000-8000-00000000001a') d;
  insert into _pom_results (name, pass, detail)
  values ('Withdrawing an office is reflected in its details', v_state = 'unlisted', v_state);
end $$;

-- Withdrawn from the marketplace, still operating: the axis separation this whole
-- feature rests on. If these two ever collapse into one, this check fails first.
insert into _pom_results (name, pass, detail)
select 'A withdrawn office is still operationally active, and loses its preview',
       d ->> 'status' = 'active' and (d -> 'marketplace' is null or d ->> 'marketplace' is null),
       format('%s / %s / preview=%s', d ->> 'status', d ->> 'listing_status',
              coalesce(d -> 'marketplace' #>> '{}', 'null'))
  from public.platform_office_details('11f30000-0000-4000-8000-00000000001a') d;

do $$
declare v_state text;
begin
  perform public.platform_set_office_listing(
    '11f30000-0000-4000-8000-00000000001a', 'listed');
  select d ->> 'listing_status' into v_state
    from public.platform_office_details('11f30000-0000-4000-8000-00000000001a') d;
  insert into _pom_results (name, pass, detail)
  values ('Republishing a withdrawn office restores it', v_state = 'listed', v_state);
end $$;

reset role;

-- ═══ 7. Nothing pre-existing was disturbed ══════════════════════════════════════════

insert into _pom_results (name, pass, detail)
select 'platform_list_offices is still SECURITY DEFINER',
       bool_and(p.prosecdef), count(*)::text
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'platform_list_offices';

insert into _pom_results (name, pass, detail)
select 'The listing setter was not redefined by this migration',
       count(*) = 1, count(*)::text
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'platform_set_office_listing';

-- ── Verdict ─────────────────────────────────────────────────────────────────────────
do $$
declare bad text;
begin
  select string_agg(name || ' [' || coalesce(detail, 'null') || ']', '; ')
    into bad from _pom_results where not pass;
  if bad is not null then
    raise exception 'PLATFORM OFFICE MANAGEMENT REGRESSION FAILURES: %', bad;
  end if;
end $$;

select name, case when pass then 'PASS' else 'FAIL' end as result, detail
  from _pom_results order by seq;

rollback;
