-- ═══════════════════════════════════════════════════════════════════════════════════
-- Driver–vehicle authority — database regression suite
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 7 of the Dashboard Re-Ownership Program. Covers migration
-- 20260731090000_driver_vehicle_authority.sql.
--
--   supabase db query --linked -f supabase/tests/driver_vehicle_authority_regression.sql
--
-- Runs entirely inside BEGIN … ROLLBACK. Every fixture it creates is discarded when it
-- finishes, whether it passes or fails — the live database is never modified.
--
-- Authorisation is exercised by impersonating real principals with
-- `set local role anon / authenticated` + `request.jwt.claims`, so RLS, grants and each
-- RPC's own checks run exactly as they do for the Dashboard.
--
-- Output: one row per case. `passed = false` anywhere is a failure.

begin;

-- ───────────────────────────────────────────────────────────────────────────────────
-- Harness
-- ───────────────────────────────────────────────────────────────────────────────────

create temp table _r (
  seq     serial,
  section text,
  name    text,
  passed  boolean,
  detail  text
);
grant all on _r to public;
grant all on sequence _r_seq_seq to public;

create temp table _fx (k text primary key, v uuid);
grant select on _fx to public;

create function pg_temp.fx(p_key text) returns uuid
language sql stable as $$ select v from _fx where k = p_key $$;

create function pg_temp.expect_error(
  p_section text, p_name text, p_sql text, p_needle text
) returns void language plpgsql as $$
begin
  execute p_sql;
  insert into _r (section, name, passed, detail)
  values (p_section, p_name, false, 'expected an error containing "' || p_needle || '", none raised');
exception when others then
  insert into _r (section, name, passed, detail)
  values (p_section, p_name, position(p_needle in sqlerrm) > 0,
          case when position(p_needle in sqlerrm) > 0 then 'raised: ' || sqlerrm
               else 'wrong error: ' || sqlerrm || ' (wanted "' || p_needle || '")' end);
end $$;

create function pg_temp.expect_ok(
  p_section text, p_name text, p_sql text
) returns void language plpgsql as $$
begin
  execute p_sql;
  insert into _r (section, name, passed, detail)
  values (p_section, p_name, true, 'ok');
exception when others then
  insert into _r (section, name, passed, detail)
  values (p_section, p_name, false, 'unexpected error: ' || sqlerrm);
end $$;

create function pg_temp.expect_that(
  p_section text, p_name text, p_condition boolean, p_detail text default null
) returns void language plpgsql as $$
begin
  insert into _r (section, name, passed, detail)
  values (p_section, p_name, coalesce(p_condition, false), coalesce(p_detail, ''));
end $$;

-- A valid seat_configuration of p_count bookable seats, three across, plus the driver.
create function pg_temp.seat_cfg(p_count int) returns jsonb
language sql immutable as $$
  select jsonb_build_object(
    'rows', ((p_count + 2) / 3) + 1,
    'columns', 3,
    'seats',
      jsonb_build_array(jsonb_build_object(
        'seat_number', 'D', 'seat_type', 'driver', 'row', 1, 'column', 1))
      || coalesce((
        select jsonb_agg(jsonb_build_object(
          'seat_number', i::text,
          'seat_type', 'passenger',
          'row', ((i - 1) / 3) + 2,
          'column', ((i - 1) % 3) + 1))
        from generate_series(1, p_count) i), '[]'::jsonb)
  );
$$;

-- Pair a driver with a vehicle the way the Fleet screen does: end whatever either of
-- them is holding, then open one active assignment. Used by the conflict cases, where
-- the *point* is that the fleet was re-paired between two trips.
create function pg_temp.pair(p_driver uuid, p_vehicle uuid) returns void
language plpgsql as $$
declare v_office uuid;
begin
  update public.assignments set status = 'ended', ended_at = now(), updated_at = now()
   where status = 'active' and (driver_id = p_driver or vehicle_id = p_vehicle);

  select office_id into v_office from public.drivers where id = p_driver;

  insert into public.assignments (office_id, driver_id, vehicle_id, assigned_at, status)
  values (v_office, p_driver, p_vehicle, now(), 'active');
end $$;

-- One station is enough: create_trip only requires the array to be non-empty.
create function pg_temp.points() returns jsonb
language sql stable as $$
  select jsonb_build_array(jsonb_build_object(
    'route_point_id', gen_random_uuid(), 'point_name', 'محطة', 'point_order', 1));
$$;

-- ───────────────────────────────────────────────────────────────────────────────────
-- Fixtures — two offices, so isolation is testable rather than assumed
-- ───────────────────────────────────────────────────────────────────────────────────

insert into _fx (k, v) values
  ('office_a',  '00000000-0000-0000-0000-0000000000e0'),
  ('office_b',  '09befe32-dcaa-40a8-8e22-1ea628029f08'),
  ('admin_a',   '68fc40bf-38aa-4481-a6f0-208300055b21'),
  ('veh_x',     gen_random_uuid()),
  ('veh_y',     gen_random_uuid()),
  ('veh_z',     gen_random_uuid()),
  ('veh_maint', gen_random_uuid()),
  ('veh_b',     gen_random_uuid()),
  ('drv_x',     gen_random_uuid()),
  ('drv_y',     gen_random_uuid()),
  ('drv_solo',  gen_random_uuid()),
  ('drv_susp',  gen_random_uuid()),
  ('drv_b',     gen_random_uuid()),
  ('trip_hist', gen_random_uuid());

insert into _fx (k, v)
select 'route_a', id from public.operation_routes
where office_id = pg_temp.fx('office_a') and status = 'active' limit 1;

insert into public.vehicles
  (id, office_id, vehicle_code, plate_number, vehicle_type, brand, model,
   manufacture_year, color, capacity, seat_layout_type, status, seat_configuration)
values
  (pg_temp.fx('veh_x'), pg_temp.fx('office_a'), 'DVA-X', 'DVA X', 'Hiace',
   'Toyota', 'Hiace', 2022, 'أبيض', 14, 'standard', 'active', pg_temp.seat_cfg(14)),
  (pg_temp.fx('veh_y'), pg_temp.fx('office_a'), 'DVA-Y', 'DVA Y', 'H1',
   'Hyundai', 'H1', 2021, 'فضي', 7, 'standard', 'active', pg_temp.seat_cfg(7)),
  (pg_temp.fx('veh_z'), pg_temp.fx('office_a'), 'DVA-Z', 'DVA Z', 'Hiace',
   'Toyota', 'Hiace', 2023, 'أزرق', 14, 'standard', 'active', pg_temp.seat_cfg(14)),
  (pg_temp.fx('veh_maint'), pg_temp.fx('office_a'), 'DVA-M', 'DVA M', 'Hiace',
   'Toyota', 'Hiace', 2020, 'أبيض', 14, 'standard', 'maintenance', pg_temp.seat_cfg(14)),
  (pg_temp.fx('veh_b'), pg_temp.fx('office_b'), 'DVA-B', 'DVA B', 'Coaster',
   'Toyota', 'Coaster', 2023, 'أبيض', 30, 'standard', 'active', pg_temp.seat_cfg(30));

insert into public.drivers
  (id, office_id, employee_code, full_name, phone, emergency_phone, address,
   national_id, license_number, license_expiry_date, hire_date, status)
values
  (pg_temp.fx('drv_x'), pg_temp.fx('office_a'), 'DVA-D1', 'سائق إكس', '01000000301',
   '01000000401', 'القاهرة', 'DVANID001', 'DVALIC001', current_date + 400, current_date - 400, 'active'),
  (pg_temp.fx('drv_y'), pg_temp.fx('office_a'), 'DVA-D2', 'سائق واي', '01000000302',
   '01000000402', 'القاهرة', 'DVANID002', 'DVALIC002', current_date + 400, current_date - 400, 'active'),
  (pg_temp.fx('drv_solo'), pg_temp.fx('office_a'), 'DVA-D3', 'سائق بلا مركبة', '01000000303',
   '01000000403', 'القاهرة', 'DVANID003', 'DVALIC003', current_date + 400, current_date - 400, 'active'),
  (pg_temp.fx('drv_susp'), pg_temp.fx('office_a'), 'DVA-D4', 'سائق موقوف', '01000000304',
   '01000000404', 'القاهرة', 'DVANID004', 'DVALIC004', current_date + 400, current_date - 400, 'suspended'),
  (pg_temp.fx('drv_b'), pg_temp.fx('office_b'), 'DVA-D5', 'سائق مكتب ب', '01000000305',
   '01000000405', 'القاهرة', 'DVANID005', 'DVALIC005', current_date + 400, current_date - 400, 'active');

-- ═══════════════════════════════════════════════════════════════════════════════════
-- A. The resolver, and what an assignment is allowed to say
-- ═══════════════════════════════════════════════════════════════════════════════════

select pg_temp.expect_ok('A', 'a driver can be paired with a vehicle of the same office',
  $$insert into public.assignments (office_id, driver_id, vehicle_id, assigned_at, status)
    values ((select v from _fx where k='office_a'), (select v from _fx where k='drv_x'),
            (select v from _fx where k='veh_x'), now(), 'active')$$);

select pg_temp.expect_that('A', 'driver_active_vehicle resolves the assigned vehicle',
  public.driver_active_vehicle(pg_temp.fx('drv_x')) = pg_temp.fx('veh_x'),
  'resolved: ' || coalesce(public.driver_active_vehicle(pg_temp.fx('drv_x'))::text, 'null'));

select pg_temp.expect_that('A', 'an unassigned driver resolves to nothing',
  public.driver_active_vehicle(pg_temp.fx('drv_solo')) is null);

select pg_temp.expect_error('A', 'a driver may not hold two vehicles at once',
  $$insert into public.assignments (office_id, driver_id, vehicle_id, assigned_at, status)
    values ((select v from _fx where k='office_a'), (select v from _fx where k='drv_x'),
            (select v from _fx where k='veh_z'), now(), 'active')$$,
  'uniq_active_assignment_per_driver');

select pg_temp.expect_error('A', 'a vehicle may not be held by two drivers at once',
  $$insert into public.assignments (office_id, driver_id, vehicle_id, assigned_at, status)
    values ((select v from _fx where k='office_a'), (select v from _fx where k='drv_y'),
            (select v from _fx where k='veh_x'), now(), 'active')$$,
  'uniq_active_assignment_per_vehicle');

-- The rule RLS could never express: RLS gates the assignment row's own office_id, and
-- says nothing about the two entities the row points at.
select pg_temp.expect_error('A', 'a driver may not be paired with another office''s vehicle',
  $$insert into public.assignments (office_id, driver_id, vehicle_id, assigned_at, status)
    values ((select v from _fx where k='office_a'), (select v from _fx where k='drv_y'),
            (select v from _fx where k='veh_b'), now(), 'active')$$,
  'assignment_cross_office');

select pg_temp.expect_error('A', 'the assignment row must belong to the pair''s office',
  $$insert into public.assignments (office_id, driver_id, vehicle_id, assigned_at, status)
    values ((select v from _fx where k='office_b'), (select v from _fx where k='drv_y'),
            (select v from _fx where k='veh_z'), now(), 'active')$$,
  'assignment_cross_office');

select pg_temp.expect_error('A', 'a suspended driver cannot be given a vehicle',
  $$insert into public.assignments (office_id, driver_id, vehicle_id, assigned_at, status)
    values ((select v from _fx where k='office_a'), (select v from _fx where k='drv_susp'),
            (select v from _fx where k='veh_z'), now(), 'active')$$,
  'assignment_driver_unavailable');

select pg_temp.expect_error('A', 'a vehicle in maintenance cannot be given a driver',
  $$insert into public.assignments (office_id, driver_id, vehicle_id, assigned_at, status)
    values ((select v from _fx where k='office_a'), (select v from _fx where k='drv_y'),
            (select v from _fx where k='veh_maint'), now(), 'active')$$,
  'assignment_vehicle_unavailable');

-- History is exempt on purpose: a driver who left keeps the record of the bus they drove.
select pg_temp.expect_ok('A', 'an ENDED assignment may reference a suspended driver',
  $$insert into public.assignments (office_id, driver_id, vehicle_id, assigned_at,
                                    ended_at, status)
    values ((select v from _fx where k='office_a'), (select v from _fx where k='drv_susp'),
            (select v from _fx where k='veh_z'), now() - interval '10 days', now(), 'ended')$$);

select pg_temp.expect_that('A', 'an ended assignment does not resolve as active',
  public.driver_active_vehicle(pg_temp.fx('drv_susp')) is null);

-- Losing 'active' releases the bus, in the database rather than in one client's Dart.
select pg_temp.expect_ok('A', 'pairing drv_y with veh_z',
  $$select pg_temp.pair((select v from _fx where k='drv_y'),
                        (select v from _fx where k='veh_z'))$$);

select pg_temp.expect_ok('A', 'suspending a driver is allowed while they hold a vehicle',
  $$update public.drivers set status = 'suspended'
    where id = (select v from _fx where k='drv_y')$$);

select pg_temp.expect_that('A', 'suspending the driver ended the assignment',
  public.driver_active_vehicle(pg_temp.fx('drv_y')) is null);

select pg_temp.expect_ok('A', 'reinstating the driver and re-pairing',
  $$update public.drivers set status = 'active'
      where id = (select v from _fx where k='drv_y');
    select pg_temp.pair((select v from _fx where k='drv_y'),
                        (select v from _fx where k='veh_z'))$$);

select pg_temp.expect_ok('A', 'sending the vehicle to maintenance is allowed',
  $$update public.vehicles set status = 'maintenance'
    where id = (select v from _fx where k='veh_z')$$);

select pg_temp.expect_that('A', 'sidelining the vehicle ended the assignment',
  public.driver_active_vehicle(pg_temp.fx('drv_y')) is null);

select pg_temp.expect_ok('A', 'restoring the vehicle and re-pairing',
  $$update public.vehicles set status = 'active'
      where id = (select v from _fx where k='veh_z');
    select pg_temp.pair((select v from _fx where k='drv_y'),
                        (select v from _fx where k='veh_z'))$$);

-- ═══════════════════════════════════════════════════════════════════════════════════
-- B. office_create_trip — the operator picks a driver, nothing else
-- ═══════════════════════════════════════════════════════════════════════════════════

select pg_temp.expect_that('B', 'the old vehicle-taking signature is gone',
  (select count(*) = 0 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'office_create_trip'
      and pg_get_function_identity_arguments(p.oid) like '%uuid, uuid, uuid%'),
  coalesce((select string_agg(pg_get_function_identity_arguments(p.oid), ' | ')
            from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'office_create_trip'), 'none'));

select pg_temp.expect_that('B', 'exactly one office_create_trip exists',
  (select count(*) = 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'office_create_trip'));

select pg_temp.expect_that('B', 'authenticated may execute it, anon may not',
  has_function_privilege('authenticated',
    'public.office_create_trip(uuid, uuid, date, time, time, numeric, text, text[], jsonb, text)',
    'execute')
  and not has_function_privilege('anon',
    'public.office_create_trip(uuid, uuid, date, time, time, numeric, text, text[], jsonb, text)',
    'execute'));

select pg_temp.expect_that('B', 'create_trip stays closed to both API roles',
  not has_function_privilege('authenticated',
    'public.create_trip(text, uuid, uuid, uuid, date, time, time, int, numeric, text, text[], jsonb, jsonb)',
    'execute')
  and not has_function_privilege('anon',
    'public.create_trip(text, uuid, uuid, uuid, date, time, time, int, numeric, text, text[], jsonb, jsonb)',
    'execute'));

set local role authenticated;
set local request.jwt.claims = '{"sub":"68fc40bf-38aa-4481-a6f0-208300055b21","role":"authenticated"}';

select pg_temp.expect_ok('B', 'an operator creates a trip from the driver alone',
  $$select public.office_create_trip(
      (select v from _fx where k='route_a'), (select v from _fx where k='drv_x'),
      current_date + 120, '08:00'::time, '10:00'::time, 100, 'ج.م',
      array['regression'], pg_temp.points(), 'DVA-T1')$$);

reset role;
set local request.jwt.claims = '';

update _fx set v = (select id from public.operation_trips where trip_code = 'DVA-T1')
where k = 'trip_hist';

select pg_temp.expect_that('B', 'the trip took the driver''s assigned vehicle',
  (select vehicle_id = pg_temp.fx('veh_x') from public.operation_trips
    where id = pg_temp.fx('trip_hist')),
  'vehicle: ' || coalesce((select vehicle_id::text from public.operation_trips
                            where id = pg_temp.fx('trip_hist')), 'null'));

select pg_temp.expect_that('B', 'capacity came from that vehicle, not from the caller',
  (select capacity = 14 from public.operation_trips where id = pg_temp.fx('trip_hist')),
  'capacity: ' || (select capacity::text from public.operation_trips
                    where id = pg_temp.fx('trip_hist')));

select pg_temp.expect_that('B', 'the seat map is the vehicle''s own layout',
  (select array_agg(seat_label order by seat_label) from public.trip_seats
    where trip_id = pg_temp.fx('trip_hist'))
  = (select array_agg(s ->> 'seat_label' order by s ->> 'seat_label')
     from jsonb_array_elements(public.vehicle_trip_seats(pg_temp.fx('veh_x'))) s));

select pg_temp.expect_that('B', 'trip capacity equals the seats actually created',
  (select t.capacity = (select count(*) from public.trip_seats s where s.trip_id = t.id)
   from public.operation_trips t where t.id = pg_temp.fx('trip_hist')));

set local role authenticated;
set local request.jwt.claims = '{"sub":"68fc40bf-38aa-4481-a6f0-208300055b21","role":"authenticated"}';

select pg_temp.expect_error('B', 'a driver with no vehicle cannot be scheduled',
  $$select public.office_create_trip(
      (select v from _fx where k='route_a'), (select v from _fx where k='drv_solo'),
      current_date + 121, '08:00'::time, '10:00'::time, 100, 'ج.م',
      array['x'], pg_temp.points(), 'DVA-T2')$$,
  'driver_has_no_vehicle');

select pg_temp.expect_error('B', 'a suspended driver cannot be scheduled',
  $$select public.office_create_trip(
      (select v from _fx where k='route_a'), (select v from _fx where k='drv_susp'),
      current_date + 121, '08:00'::time, '10:00'::time, 100, 'ج.م',
      array['x'], pg_temp.points(), 'DVA-T3')$$,
  'driver_unavailable');

select pg_temp.expect_error('B', 'another office''s driver cannot be scheduled',
  $$select public.office_create_trip(
      (select v from _fx where k='route_a'), (select v from _fx where k='drv_b'),
      current_date + 121, '08:00'::time, '10:00'::time, 100, 'ج.م',
      array['x'], pg_temp.points(), 'DVA-T4')$$,
  'driver_not_in_office');

select pg_temp.expect_error('B', 'a trip must name a driver',
  $$select public.office_create_trip(
      (select v from _fx where k='route_a'), null,
      current_date + 121, '08:00'::time, '10:00'::time, 100, 'ج.م',
      array['x'], pg_temp.points(), 'DVA-T5')$$,
  'driver_required');

reset role;
set local request.jwt.claims = '';

set local role anon;
select pg_temp.expect_error('B', 'anon cannot reach office_create_trip at all',
  $$select public.office_create_trip(
      '00000000-0000-0000-0000-000000000000'::uuid,
      '00000000-0000-0000-0000-000000000000'::uuid,
      current_date, '08:00'::time, '10:00'::time, 1, 'ج.م',
      array['x'], '[]'::jsonb, 'DVA-T6')$$,
  'permission denied');
reset role;

-- ═══════════════════════════════════════════════════════════════════════════════════
-- C. create_trip — a vehicle supplied by an internal caller is checked, not trusted
-- ═══════════════════════════════════════════════════════════════════════════════════

select pg_temp.expect_ok('C', 'the driver''s own vehicle is accepted when passed explicitly',
  $$select public.create_trip('DVA-T7', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_x'), (select v from _fx where k='veh_x'),
      current_date + 122, '08:00'::time, '10:00'::time, null, 100, 'ج.م',
      array['x'], pg_temp.points(), null)$$);

select pg_temp.expect_error('C', 'a vehicle the driver does not operate is refused',
  $$select public.create_trip('DVA-T8', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_x'), (select v from _fx where k='veh_y'),
      current_date + 123, '08:00'::time, '10:00'::time, null, 100, 'ج.م',
      array['x'], pg_temp.points(), null)$$,
  'driver_vehicle_mismatch');

select pg_temp.expect_ok('C', 'omitting the vehicle still produces the right one',
  $$select public.create_trip('DVA-T9', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_x'), null,
      current_date + 124, '08:00'::time, '10:00'::time, null, 100, 'ج.م',
      array['x'], pg_temp.points(), null)$$);

select pg_temp.expect_that('C', 'the derived trip carries the assigned vehicle',
  (select vehicle_id = pg_temp.fx('veh_x') from public.operation_trips
    where trip_code = 'DVA-T9'));

select pg_temp.expect_error('C', 'an unassigned driver is refused here too',
  $$select public.create_trip('DVA-TA', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_solo'), null,
      current_date + 125, '08:00'::time, '10:00'::time, null, 100, 'ج.م',
      array['x'], pg_temp.points(), null)$$,
  'driver_has_no_vehicle');

-- ═══════════════════════════════════════════════════════════════════════════════════
-- D. The rule lives on the table, not only in the RPC
-- ═══════════════════════════════════════════════════════════════════════════════════

select pg_temp.expect_error('D', 'a DIRECT insert with a mismatched pair is refused',
  $$insert into public.operation_trips (trip_code, route_id, driver_id, vehicle_id,
      trip_date, departure_time, arrival_time, capacity, ticket_price, currency, status)
    values ('DVA-TB', (select v from _fx where k='route_a'),
            (select v from _fx where k='drv_x'), (select v from _fx where k='veh_y'),
            current_date + 126, '08:00'::time, '10:00'::time, 14, 100, 'ج.م', 'scheduled')$$,
  'driver_vehicle_mismatch');

select pg_temp.expect_error('D', 'a DIRECT insert with a driver but no vehicle is refused',
  $$insert into public.operation_trips (trip_code, route_id, driver_id, vehicle_id,
      trip_date, departure_time, arrival_time, capacity, ticket_price, currency, status)
    values ('DVA-TC', (select v from _fx where k='route_a'),
            (select v from _fx where k='drv_solo'), null,
            current_date + 126, '08:00'::time, '10:00'::time, 14, 100, 'ج.م', 'scheduled')$$,
  'driver_has_no_vehicle');

select pg_temp.expect_ok('D', 'a DIRECT insert with the real pair is accepted',
  $$insert into public.operation_trips (trip_code, route_id, driver_id, vehicle_id,
      trip_date, departure_time, arrival_time, capacity, ticket_price, currency, status)
    values ('DVA-TD', (select v from _fx where k='route_a'),
            (select v from _fx where k='drv_x'), (select v from _fx where k='veh_x'),
            current_date + 127, '08:00'::time, '10:00'::time, 14, 100, 'ج.م', 'scheduled')$$);

select pg_temp.expect_error('D', 'swapping in a driver assigned elsewhere is refused',
  $$update public.operation_trips set driver_id = (select v from _fx where k='drv_y')
    where trip_code = 'DVA-TD'$$,
  'driver_vehicle_mismatch');

-- ═══════════════════════════════════════════════════════════════════════════════════
-- E. History — a reassignment must not reach backwards
-- ═══════════════════════════════════════════════════════════════════════════════════
-- DVA-T1 was created while drv_x operated veh_x. Move drv_x onto veh_y and the trip
-- must not notice.

select pg_temp.expect_ok('E', 'the driver is reassigned to a different vehicle',
  $$select pg_temp.pair((select v from _fx where k='drv_x'),
                        (select v from _fx where k='veh_y'))$$);

select pg_temp.expect_that('E', 'the resolver now points at the new vehicle',
  public.driver_active_vehicle(pg_temp.fx('drv_x')) = pg_temp.fx('veh_y'));

select pg_temp.expect_that('E', 'the existing trip keeps the vehicle it was created with',
  (select vehicle_id = pg_temp.fx('veh_x') from public.operation_trips
    where id = pg_temp.fx('trip_hist')));

select pg_temp.expect_that('E', 'the existing trip keeps its 14-seat map',
  (select count(*) = 14 from public.trip_seats where trip_id = pg_temp.fx('trip_hist')),
  'seats: ' || (select count(*)::text from public.trip_seats
                 where trip_id = pg_temp.fx('trip_hist')));

select pg_temp.expect_that('E', 'the existing trip keeps its capacity',
  (select capacity = 14 from public.operation_trips where id = pg_temp.fx('trip_hist')));

-- Editing a historical trip's schedule must stay possible after the reassignment: the
-- pairing is judged only when the pair itself changes.
select pg_temp.expect_ok('E', 'the historical trip''s schedule is still editable',
  $$update public.operation_trips
       set driver_id = driver_id, vehicle_id = vehicle_id, departure_time = '08:30'
     where id = (select v from _fx where k='trip_hist')$$);

select pg_temp.expect_that('E', 'that edit did not touch the trip''s vehicle',
  (select vehicle_id = pg_temp.fx('veh_x') from public.operation_trips
    where id = pg_temp.fx('trip_hist')));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- F. Conflicts — the driver and the bus they are on are one resource
-- ═══════════════════════════════════════════════════════════════════════════════════
-- drv_x now operates veh_y. DVA-T1 runs on day+120 at 08:30 → 10:00 (+30 turnaround).

select pg_temp.expect_error('F', 'the same driver cannot run two overlapping trips',
  $$select public.create_trip('DVA-TE', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_x'), null,
      current_date + 120, '09:00'::time, '11:00'::time, null, 100, 'ج.م',
      array['x'], pg_temp.points(), null)$$,
  'driver_conflict');

select pg_temp.expect_ok('F', 'the same driver CAN run a later departure the same day',
  $$select public.create_trip('DVA-TF', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_x'), null,
      current_date + 120, '14:00'::time, '16:00'::time, null, 100, 'ج.م',
      array['x'], pg_temp.points(), null)$$);

-- The vehicle rule still bites independently, and this is the shape it now takes: the
-- bus was handed to a different driver between the two departures.
select pg_temp.expect_ok('F', 'veh_x is handed to another driver',
  $$select pg_temp.pair((select v from _fx where k='drv_solo'),
                        (select v from _fx where k='veh_x'))$$);

select pg_temp.expect_error('F', 'a free driver cannot take a bus that is already out',
  $$select public.create_trip('DVA-TG', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_solo'), null,
      current_date + 120, '09:00'::time, '11:00'::time, null, 100, 'ج.م',
      array['x'], pg_temp.points(), null)$$,
  'vehicle_conflict');

select pg_temp.expect_error('F', 'the 30-minute turnaround is enforced, not just arrival',
  $$select public.create_trip('DVA-TH', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_solo'), null,
      current_date + 120, '10:15'::time, '11:00'::time, null, 100, 'ج.م',
      array['x'], pg_temp.points(), null)$$,
  'vehicle_conflict');

select pg_temp.expect_ok('F', 'different drivers on different buses may depart together',
  $$select public.create_trip('DVA-TI', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_y'), null,
      current_date + 120, '08:30'::time, '10:00'::time, null, 100, 'ج.م',
      array['x'], pg_temp.points(), null)$$);

-- The exclusion constraints, not the RPC, are what hold under concurrency: two sessions
-- committing at once never both pass the RPC's SELECT. A direct write proves the
-- constraint is still the backstop.
select pg_temp.expect_error('F', 'a DIRECT overlapping write is refused by the constraint',
  $$insert into public.operation_trips (trip_code, route_id, driver_id, vehicle_id,
      trip_date, departure_time, arrival_time, capacity, ticket_price, currency, status)
    values ('DVA-TJ', (select v from _fx where k='route_a'),
            (select v from _fx where k='drv_solo'), (select v from _fx where k='veh_x'),
            current_date + 120, '09:30'::time, '10:30'::time, 14, 100, 'ج.م', 'scheduled')$$,
  'operation_trips_vehicle_no_overlap');

select pg_temp.expect_that('F', 'both overlap exclusion constraints are still in place',
  (select count(*) = 2 from pg_constraint
    where conrelid = 'public.operation_trips'::regclass
      and conname in ('operation_trips_driver_no_overlap',
                      'operation_trips_vehicle_no_overlap')));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- Results
-- ═══════════════════════════════════════════════════════════════════════════════════

select section, name, passed, detail from _r order by seq;

select
  count(*)                        as total,
  count(*) filter (where passed)  as passed,
  count(*) filter (where not passed) as failed
from _r;

rollback;
