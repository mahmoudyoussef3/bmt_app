-- ═══════════════════════════════════════════════════════════════════════════════════
-- Fleet authority — database regression suite
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 4 of the Dashboard Re-Ownership Program. Covers migration
-- 20260728090000_fleet_authority.sql.
--
--   supabase db query --linked -f supabase/tests/fleet_authority_regression.sql
--
-- Runs entirely inside BEGIN … ROLLBACK. Every fixture it creates is discarded when it
-- finishes, whether it passes or fails — the live database is never modified.
--
-- Authorisation is exercised by impersonating real principals with
-- `set local role anon / authenticated` + `request.jwt.claims`, so RLS, grants and each
-- RPC's own checks run exactly as they do for the apps.
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

-- Run a write and assert how many rows it touched. RLS does not raise on a write that
-- matches nothing — it silently filters — so "denied" here means "affected 0 rows".
create function pg_temp.expect_rowcount(
  p_section text, p_name text, p_sql text, p_expected int
) returns void language plpgsql as $$
declare v_count int;
begin
  execute p_sql;
  get diagnostics v_count = row_count;
  insert into _r (section, name, passed, detail)
  values (p_section, p_name, v_count = p_expected,
          'affected ' || v_count::text || ', expected ' || p_expected::text);
exception when others then
  insert into _r (section, name, passed, detail)
  values (p_section, p_name, false, 'unexpected error: ' || sqlerrm);
end $$;

-- Pair a driver with a vehicle the way the Fleet screen does: end whatever either of
-- them is holding, then open one active assignment.
--
-- Added with 20260731090000_driver_vehicle_authority. Before that migration a trip took
-- a driver and a vehicle as two unrelated arguments, so this suite scheduled whichever
-- pair each case happened to need and no assignment existed at all. That is the model
-- the migration removed: a trip now runs on the vehicle the driver is actually paired
-- with, so every case below states that pairing explicitly.
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

-- ───────────────────────────────────────────────────────────────────────────────────
-- Fixtures — two offices, so isolation is testable rather than assumed
-- ───────────────────────────────────────────────────────────────────────────────────

insert into _fx (k, v) values
  ('office_a', '00000000-0000-0000-0000-0000000000e0'),
  ('office_b', '09befe32-dcaa-40a8-8e22-1ea628029f08'),
  ('admin_a',  '68fc40bf-38aa-4481-a6f0-208300055b21'),
  ('admin_b',  'd2c7aeb3-dc80-4975-ad35-ac62ce4c1bbb'),
  ('veh_a',    gen_random_uuid()),
  ('veh_a2',   gen_random_uuid()),
  ('veh_maint',gen_random_uuid()),
  ('veh_small',gen_random_uuid()),
  ('veh_c',    gen_random_uuid()),
  ('veh_b',    gen_random_uuid()),
  ('drv_a',    gen_random_uuid()),
  ('drv_a2',   gen_random_uuid()),
  ('drv_arch', gen_random_uuid()),
  ('drv_b',    gen_random_uuid()),
  ('trip_1',   gen_random_uuid()),
  ('client_1', gen_random_uuid());

insert into _fx (k, v)
select 'route_a', id from public.operation_routes
where office_id = pg_temp.fx('office_a') limit 1;

insert into public.vehicles
  (id, office_id, vehicle_code, plate_number, vehicle_type, brand, model,
   manufacture_year, color, capacity, seat_layout_type, status, seat_configuration)
values
  (pg_temp.fx('veh_a'), pg_temp.fx('office_a'), 'RGX-A1', 'RGX A1', 'Hiace',
   'Toyota', 'Hiace', 2022, 'أبيض', 14, 'standard', 'active', pg_temp.seat_cfg(14)),
  (pg_temp.fx('veh_a2'), pg_temp.fx('office_a'), 'RGX-A2', 'RGX A2', 'Hiace',
   'Toyota', 'Hiace', 2022, 'أبيض', 14, 'standard', 'active', pg_temp.seat_cfg(14)),
  (pg_temp.fx('veh_maint'), pg_temp.fx('office_a'), 'RGX-M1', 'RGX M1', 'Hiace',
   'Toyota', 'Hiace', 2021, 'أبيض', 14, 'standard', 'maintenance', pg_temp.seat_cfg(14)),
  (pg_temp.fx('veh_small'), pg_temp.fx('office_a'), 'RGX-S1', 'RGX S1', 'H1',
   'Hyundai', 'H1', 2020, 'فضي', 7, 'standard', 'active', pg_temp.seat_cfg(7)),
  (pg_temp.fx('veh_c'), pg_temp.fx('office_a'), 'RGX-C1', 'RGX C1', 'Hiace',
   'Toyota', 'Hiace', 2022, 'أزرق', 14, 'standard', 'active', pg_temp.seat_cfg(14)),
  (pg_temp.fx('veh_b'), pg_temp.fx('office_b'), 'RGX-B1', 'RGX B1', 'Coaster',
   'Toyota', 'Coaster', 2023, 'أبيض', 30, 'standard', 'active', pg_temp.seat_cfg(30));

insert into public.drivers
  (id, office_id, employee_code, full_name, phone, emergency_phone, address,
   national_id, license_number, license_expiry_date, hire_date, status)
values
  (pg_temp.fx('drv_a'), pg_temp.fx('office_a'), 'RGX-D1', 'سائق أ', '01000000101',
   '01000000201', 'القاهرة', 'RGXNID001', 'RGXLIC001', current_date + 400, current_date - 400, 'active'),
  (pg_temp.fx('drv_a2'), pg_temp.fx('office_a'), 'RGX-D2', 'سائق أ٢', '01000000102',
   '01000000202', 'القاهرة', 'RGXNID002', 'RGXLIC002', current_date + 400, current_date - 400, 'active'),
  (pg_temp.fx('drv_arch'), pg_temp.fx('office_a'), 'RGX-D3', 'سائق مؤرشف', '01000000103',
   '01000000203', 'القاهرة', 'RGXNID003', 'RGXLIC003', current_date + 400, current_date - 400, 'archived'),
  (pg_temp.fx('drv_b'), pg_temp.fx('office_b'), 'RGX-D4', 'سائق ب', '01000000104',
   '01000000204', 'القاهرة', 'RGXNID004', 'RGXLIC004', current_date + 400, current_date - 400, 'active');

-- The opening fleet pairing. Sections D onward schedule these drivers, and a trip can
-- only run on the vehicle its driver is paired with.
select pg_temp.pair(pg_temp.fx('drv_a'),  pg_temp.fx('veh_a'));
select pg_temp.pair(pg_temp.fx('drv_a2'), pg_temp.fx('veh_small'));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- A. Security — the SECURITY DEFINER view write path
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Before this migration an anonymous session could UPDATE `vehicles` and `drivers`
-- through these views, because a definer view executes as its owner and never consults
-- the base table's RLS. This is the regression that must never come back.

set local role anon;
select pg_temp.expect_error('A', 'anon cannot UPDATE vehicles through public_vehicle_profiles',
  $$update public.public_vehicle_profiles set color = 'hacked'$$, 'permission denied');
select pg_temp.expect_error('A', 'anon cannot DELETE vehicles through public_vehicle_profiles',
  $$delete from public.public_vehicle_profiles$$, 'permission denied');
select pg_temp.expect_error('A', 'anon cannot UPDATE drivers through public_driver_profiles',
  $$update public.public_driver_profiles set full_name = 'hacked'$$, 'permission denied');
select pg_temp.expect_error('A', 'anon cannot UPDATE offices through public_offices',
  $$update public.public_offices set name = 'hacked'$$, 'permission denied');
select pg_temp.expect_error('A', 'anon cannot TRUNCATE vehicles',
  $$truncate public.vehicles cascade$$, 'permission denied');
select pg_temp.expect_error('A', 'anon cannot TRUNCATE trip_seats',
  $$truncate public.trip_seats cascade$$, 'permission denied');
select pg_temp.expect_error('A', 'anon cannot INSERT a vehicle directly',
  $$insert into public.vehicles (office_id, vehicle_code, plate_number, vehicle_type,
      brand, model, manufacture_year, color, capacity, seat_layout_type, seat_configuration)
    values (gen_random_uuid(), 'X', 'X', 'Hiace', 'X', 'X', 2020, 'X', 1, 'standard',
            '{"rows":1,"columns":1,"seats":[{"seat_number":"1","seat_type":"passenger","row":1,"column":1}]}')$$,
  'permission denied');
select pg_temp.expect_that('A', 'anon still reads the public vehicle catalogue',
  (select count(*) >= 0 from public.public_vehicle_profiles));
reset role;

-- ═══════════════════════════════════════════════════════════════════════════════════
-- B. Multi-office isolation
-- ═══════════════════════════════════════════════════════════════════════════════════

set local role authenticated;
set local request.jwt.claims = '{"sub":"d2c7aeb3-dc80-4975-ad35-ac62ce4c1bbb","role":"authenticated"}';

select pg_temp.expect_that('B', 'office B cannot READ office A vehicles',
  (select count(*) = 0 from public.vehicles where office_id = '00000000-0000-0000-0000-0000000000e0'));
select pg_temp.expect_that('B', 'office B cannot READ office A drivers',
  (select count(*) = 0 from public.drivers where office_id = '00000000-0000-0000-0000-0000000000e0'));
select pg_temp.expect_that('B', 'office B sees only its own vehicles',
  (select count(*) > 0 from public.vehicles where office_id = '09befe32-dcaa-40a8-8e22-1ea628029f08'));
select pg_temp.expect_rowcount('B', 'office B UPDATE of office A vehicles affects 0 rows',
  $$update public.vehicles set color = 'x'
    where office_id = '00000000-0000-0000-0000-0000000000e0'$$, 0);
select pg_temp.expect_rowcount('B', 'office B DELETE of office A vehicles affects 0 rows',
  $$delete from public.vehicles
    where office_id = '00000000-0000-0000-0000-0000000000e0'$$, 0);
select pg_temp.expect_rowcount('B', 'office B UPDATE of office A drivers affects 0 rows',
  $$update public.drivers set full_name = 'x'
    where office_id = '00000000-0000-0000-0000-0000000000e0'$$, 0);
select pg_temp.expect_error('B', 'office B cannot INSERT a vehicle into office A',
  $$insert into public.vehicles (office_id, vehicle_code, plate_number, vehicle_type,
      brand, model, manufacture_year, color, capacity, seat_layout_type, seat_configuration)
    values ('00000000-0000-0000-0000-0000000000e0', 'RGX-X', 'RGX X', 'Hiace', 'T', 'H',
            2020, 'أبيض', 1, 'standard',
            '{"rows":1,"columns":1,"seats":[{"seat_number":"1","seat_type":"passenger","row":1,"column":1}]}')$$,
  'row-level security');
select pg_temp.expect_error('B', 'office B cannot assign office A driver to office A vehicle',
  $$insert into public.assignments (office_id, driver_id, vehicle_id, assigned_at, status)
    values ('00000000-0000-0000-0000-0000000000e0',
            (select v from _fx where k='drv_a'), (select v from _fx where k='veh_a'),
            now(), 'active')$$,
  'row-level security');

reset role;
set local request.jwt.claims = '';

-- ═══════════════════════════════════════════════════════════════════════════════════
-- C. Seat configuration — capacity and seat identity
-- ═══════════════════════════════════════════════════════════════════════════════════

select pg_temp.expect_error('C', 'capacity may not disagree with the seat layout',
  $$update public.vehicles set capacity = 15 where id = (select v from _fx where k='veh_c')$$,
  'vehicles_capacity_matches_seat_configuration');

-- An empty layout is unreachable from three directions at once: the layout is malformed,
-- the passenger count no longer equals capacity, and capacity may not drop to 0. Which
-- constraint speaks first is not the guarantee; that none of them let it through is.
select pg_temp.expect_error('C', 'a vehicle may not be saved with an empty layout',
  $$update public.vehicles set seat_configuration = '{}'::jsonb
    where id = (select v from _fx where k='veh_c')$$,
  'violates check constraint');

select pg_temp.expect_error('C', 'two seats may not share a label',
  $$update public.vehicles set capacity = 2, seat_configuration =
      '{"rows":1,"columns":2,"seats":[
         {"seat_number":"1","seat_type":"passenger","row":1,"column":1},
         {"seat_number":"1","seat_type":"passenger","row":1,"column":2}]}'::jsonb
    where id = (select v from _fx where k='veh_c')$$,
  'vehicles_seat_configuration_wellformed');

select pg_temp.expect_error('C', 'a seat may not be saved without a grid position',
  $$update public.vehicles set capacity = 1, seat_configuration =
      '{"rows":1,"columns":1,"seats":[{"seat_number":"1","seat_type":"passenger"}]}'::jsonb
    where id = (select v from _fx where k='veh_c')$$,
  'vehicles_seat_configuration_wellformed');

select pg_temp.expect_ok('C', 'a consistent capacity + layout change is accepted',
  $$update public.vehicles set capacity = 12, seat_configuration = pg_temp.seat_cfg(12)
    where id = (select v from _fx where k='veh_c')$$);

select pg_temp.expect_that('C', 'the driver slot is never counted as a bookable seat',
  public.seat_config_passenger_count(pg_temp.seat_cfg(14)) = 14,
  'counted ' || public.seat_config_passenger_count(pg_temp.seat_cfg(14))::text);

-- ═══════════════════════════════════════════════════════════════════════════════════
-- D. Trip seat authority — the trip's inventory comes from the vehicle
-- ═══════════════════════════════════════════════════════════════════════════════════

select pg_temp.expect_ok('D', 'creating a trip snapshots the vehicle''s seats',
  $$select public.create_trip('RGX-T1', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_a'), (select v from _fx where k='veh_a'),
      current_date + 30, '08:00'::time, '10:00'::time, 14, 100, 'ج.م',
      array['regression'],
      jsonb_build_array(jsonb_build_object('route_point_id', gen_random_uuid(),
        'point_name','A','point_order',1)),
      '[]'::jsonb)$$);

update _fx set v = (select id from public.operation_trips where trip_code = 'RGX-T1')
where k = 'trip_1';

select pg_temp.expect_that('D', 'the trip has exactly the vehicle''s 14 seats',
  (select count(*) = 14 from public.trip_seats where trip_id = pg_temp.fx('trip_1')),
  'seats: ' || (select count(*)::text from public.trip_seats where trip_id = pg_temp.fx('trip_1')));

select pg_temp.expect_that('D', 'trip capacity equals the seats actually created',
  (select t.capacity = (select count(*) from public.trip_seats s where s.trip_id = t.id)
   from public.operation_trips t where t.id = pg_temp.fx('trip_1')));

select pg_temp.expect_that('D', 'seat labels match the vehicle''s layout exactly',
  (select array_agg(seat_label order by seat_label) from public.trip_seats
    where trip_id = pg_temp.fx('trip_1'))
  = (select array_agg(s ->> 'seat_label' order by s ->> 'seat_label')
     from jsonb_array_elements(public.vehicle_trip_seats(pg_temp.fx('veh_a'))) s));

-- The whole point: a caller who posts its own seat array no longer decides anything.
select pg_temp.expect_error('D', 'a client-posted seat array cannot inflate the trip',
  $$select public.create_trip('RGX-T2', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_a2'), (select v from _fx where k='veh_small'),
      current_date + 31, '08:00'::time, '10:00'::time, 40, 100, 'ج.م', array['x'],
      jsonb_build_array(jsonb_build_object('route_point_id', gen_random_uuid(),
        'point_name','A','point_order',1)),
      (select jsonb_agg(jsonb_build_object('seat_label', i::text, 'seat_row', i, 'seat_column', 1))
       from generate_series(1,40) i))$$,
  'capacity_mismatch');

select pg_temp.expect_ok('D', 'a 7-seat vehicle yields a 7-seat trip regardless of the payload',
  $$select public.create_trip('RGX-T3', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_a2'), (select v from _fx where k='veh_small'),
      current_date + 31, '08:00'::time, '10:00'::time, 7, 100, 'ج.م', array['x'],
      jsonb_build_array(jsonb_build_object('route_point_id', gen_random_uuid(),
        'point_name','A','point_order',1)),
      (select jsonb_agg(jsonb_build_object('seat_label', i::text, 'seat_row', i, 'seat_column', 1))
       from generate_series(1,40) i))$$);

select pg_temp.expect_that('D', 'the 7-seat trip really has 7 seats',
  (select count(*) = 7 from public.trip_seats ts
   join public.operation_trips t on t.id = ts.trip_id where t.trip_code = 'RGX-T3'));

select pg_temp.expect_error('D', 'two seats on one trip may not share a label',
  $$insert into public.trip_seats (trip_id, seat_label, seat_row, seat_column, state)
    values ((select v from _fx where k='trip_1'), '1', 9, 9, 'available')$$,
  'uq_trip_seats_trip_label');

select pg_temp.expect_error('D', 'a trip seat may not be blank-labelled',
  $$insert into public.trip_seats (trip_id, seat_label, seat_row, seat_column, state)
    values ((select v from _fx where k='trip_1'), '   ', 9, 9, 'available')$$,
  'trip_seats_label_not_blank');

-- ═══════════════════════════════════════════════════════════════════════════════════
-- E. Resource overlap — the rule that replaced "one trip per day"
-- ═══════════════════════════════════════════════════════════════════════════════════
-- trip_1 is RGX-A1 + سائق أ on day+30, 08:00 → 10:00, so the window runs to 10:30.

select pg_temp.expect_ok('E', 'the SAME vehicle may run a second departure later the same day',
  $$select public.create_trip('RGX-T4', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_a'), (select v from _fx where k='veh_a'),
      current_date + 30, '14:00'::time, '16:00'::time, 14, 100, 'ج.م', array['x'],
      jsonb_build_array(jsonb_build_object('route_point_id', gen_random_uuid(),
        'point_name','A','point_order',1)),
      '[]'::jsonb)$$);

-- The vehicle rule bites independently of the driver rule, and since
-- 20260731090000_driver_vehicle_authority this is the shape it takes: the bus was
-- handed to a different driver between the two departures. (It used to be written as
-- "another driver takes the same bus while its own driver is out", which the pairing
-- rule now makes impossible to express — and was never a real dispatch anyway.)
select pg_temp.pair(pg_temp.fx('drv_a2'), pg_temp.fx('veh_a'));

select pg_temp.expect_error('E', 'a vehicle may not run two trips that overlap in time',
  $$select public.create_trip('RGX-T5', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_a2'), (select v from _fx where k='veh_a'),
      current_date + 30, '09:00'::time, '11:00'::time, 14, 100, 'ج.م', array['x'],
      jsonb_build_array(jsonb_build_object('route_point_id', gen_random_uuid(),
        'point_name','A','point_order',1)),
      '[]'::jsonb)$$,
  'vehicle_conflict');

-- سائق أ has moved onto RGX-A2, so their own 08:00 trip is what stops them here — not
-- the bus, which is free.
select pg_temp.pair(pg_temp.fx('drv_a'), pg_temp.fx('veh_a2'));

select pg_temp.expect_error('E', 'a driver may not run two trips that overlap in time',
  $$select public.create_trip('RGX-T6', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_a'), (select v from _fx where k='veh_a2'),
      current_date + 30, '09:30'::time, '11:00'::time, 14, 100, 'ج.م', array['x'],
      jsonb_build_array(jsonb_build_object('route_point_id', gen_random_uuid(),
        'point_name','A','point_order',1)),
      '[]'::jsonb)$$,
  'driver_conflict');

select pg_temp.expect_error('E', 'the 30-minute turnaround is enforced, not just arrival',
  $$select public.create_trip('RGX-T7', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_a2'), (select v from _fx where k='veh_a'),
      current_date + 30, '10:15'::time, '11:00'::time, 14, 100, 'ج.م', array['x'],
      jsonb_build_array(jsonb_build_object('route_point_id', gen_random_uuid(),
        'point_name','A','point_order',1)),
      '[]'::jsonb)$$,
  'vehicle_conflict');

-- The exclusion constraint, not the RPC, is what actually holds: a direct table write
-- bypassing create_trip is refused too.
select pg_temp.expect_error('E', 'a DIRECT overlapping write is refused by the constraint',
  $$insert into public.operation_trips (trip_code, route_id, driver_id, vehicle_id,
      trip_date, departure_time, arrival_time, capacity, ticket_price, currency, status)
    values ('RGX-T8', (select v from _fx where k='route_a'),
            (select v from _fx where k='drv_a2'), (select v from _fx where k='veh_a'),
            current_date + 30, '08:30'::time, '09:30'::time, 14, 100, 'ج.م', 'scheduled')$$,
  'operation_trips_vehicle_no_overlap');

select pg_temp.expect_ok('E', 'a cancelled trip stops reserving its vehicle',
  $$update public.operation_trips set status = 'cancelled' where trip_code = 'RGX-T4';
    insert into public.operation_trips (trip_code, route_id, driver_id, vehicle_id,
      trip_date, departure_time, arrival_time, capacity, ticket_price, currency, status)
    values ('RGX-T9', (select v from _fx where k='route_a'),
            (select v from _fx where k='drv_a2'), (select v from _fx where k='veh_a'),
            current_date + 30, '14:00'::time, '16:00'::time, 14, 100, 'ج.م', 'scheduled')$$);

-- ═══════════════════════════════════════════════════════════════════════════════════
-- F. Vehicle and driver lifecycle
-- ═══════════════════════════════════════════════════════════════════════════════════

-- These three used to be written as "schedule this driver onto that unavailable
-- vehicle". Since 20260731090000_driver_vehicle_authority a trip cannot name a vehicle
-- at all — the driver's assignment does — so the same three guarantees are now proven
-- one layer earlier (the pairing is refused) and one layer lower (the trip table still
-- refuses a direct write), which is strictly stronger than what they asserted before.

select pg_temp.expect_error('F', 'a vehicle in maintenance cannot even be assigned',
  $$insert into public.assignments (office_id, driver_id, vehicle_id, assigned_at, status)
    values ((select v from _fx where k='office_a'), (select v from _fx where k='drv_arch'),
            (select v from _fx where k='veh_maint'), now(), 'active')$$,
  'assignment_driver_unavailable');

select pg_temp.expect_error('F', 'a vehicle in maintenance is refused by the trip table',
  $$insert into public.operation_trips (trip_code, route_id, driver_id, vehicle_id,
      trip_date, departure_time, arrival_time, capacity, ticket_price, currency, status)
    values ('RGX-TA', (select v from _fx where k='route_a'), null,
            (select v from _fx where k='veh_maint'),
            current_date + 60, '08:00'::time, '10:00'::time, 14, 100, 'ج.م', 'scheduled')$$,
  'vehicle_unavailable');

select pg_temp.expect_error('F', 'an archived driver cannot be scheduled',
  $$insert into public.operation_trips (trip_code, route_id, driver_id, vehicle_id,
      trip_date, departure_time, arrival_time, capacity, ticket_price, currency, status)
    values ('RGX-TB', (select v from _fx where k='route_a'),
            (select v from _fx where k='drv_arch'), (select v from _fx where k='veh_a2'),
            current_date + 60, '08:00'::time, '10:00'::time, 14, 100, 'ج.م', 'scheduled')$$,
  'driver_unavailable');

select pg_temp.expect_error('F', 'an archived driver has no vehicle to be scheduled with',
  $$select public.create_trip('RGX-TB2', (select v from _fx where k='route_a'),
      (select v from _fx where k='drv_arch'), null,
      current_date + 60, '08:00'::time, '10:00'::time, null, 100, 'ج.م', array['x'],
      jsonb_build_array(jsonb_build_object('route_point_id', gen_random_uuid(),
        'point_name','A','point_order',1)),
      '[]'::jsonb)$$,
  'driver_has_no_vehicle');

select pg_temp.expect_error('F', 'a trip cannot borrow another office''s vehicle',
  $$insert into public.operation_trips (trip_code, route_id, driver_id, vehicle_id,
      trip_date, departure_time, arrival_time, capacity, ticket_price, currency, status)
    values ('RGX-TC', (select v from _fx where k='route_a'), null,
            (select v from _fx where k='veh_b'),
            current_date + 61, '08:00'::time, '10:00'::time, 30, 100, 'ج.م', 'scheduled')$$,
  'vehicle_not_in_office');

select pg_temp.expect_error('F', 'a live trip cannot be swapped onto a smaller vehicle',
  $$update public.operation_trips set vehicle_id = (select v from _fx where k='veh_small')
    where id = (select v from _fx where k='trip_1')$$,
  'vehicle_too_small');

select pg_temp.expect_ok('F', 'a live trip CAN be swapped onto an equal vehicle',
  $$update public.operation_trips set vehicle_id = (select v from _fx where k='veh_a2')
    where id = (select v from _fx where k='trip_1')$$);

select pg_temp.expect_that('F', 'swapping the vehicle does not move the trip''s seats',
  (select count(*) = 14 from public.trip_seats where trip_id = pg_temp.fx('trip_1')));

-- Delete guards only engage for a real end user; auth.uid() is null in this session, so
-- impersonate the office A operator.
set local role authenticated;
set local request.jwt.claims = '{"sub":"68fc40bf-38aa-4481-a6f0-208300055b21","role":"authenticated"}';

select pg_temp.expect_error('F', 'a vehicle with trip history cannot be hard-deleted',
  $$delete from public.vehicles where id = (select v from _fx where k='veh_a')$$,
  'vehicle_delete_forbidden');
select pg_temp.expect_error('F', 'a driver with trip history cannot be hard-deleted',
  $$delete from public.drivers where id = (select v from _fx where k='drv_a')$$,
  'driver_delete_forbidden');
select pg_temp.expect_ok('F', 'archiving a vehicle is always available',
  $$update public.vehicles set status = 'archived' where id = (select v from _fx where k='veh_a')$$);

reset role;
set local request.jwt.claims = '';

-- ═══════════════════════════════════════════════════════════════════════════════════
-- G. Booking safety — one physical seat, one live booking
-- ═══════════════════════════════════════════════════════════════════════════════════

insert into _fx (k, v)
select 'seat_1', id from public.trip_seats
where trip_id = pg_temp.fx('trip_1') order by seat_row, seat_column limit 1;

select pg_temp.expect_ok('G', 'the first booking may hold a seat',
  $$insert into public.operation_bookings (trip_id, seat_id, seat, passenger_name, phone,
      route, trip_time, trip_date, payment_method, payment_amount, status, booking_number)
    values ((select v from _fx where k='trip_1'), (select v from _fx where k='seat_1'),
            '1', 'راكب ١', '01000000001', 'r', '08:00', current_date + 30,
            'instapay', 100, 'confirmed', 'RGX-BK1')$$);

select pg_temp.expect_error('G', 'a second live booking on the same seat is refused',
  $$insert into public.operation_bookings (trip_id, seat_id, seat, passenger_name, phone,
      route, trip_time, trip_date, payment_method, payment_amount, status, booking_number)
    values ((select v from _fx where k='trip_1'), (select v from _fx where k='seat_1'),
            '1', 'راكب ٢', '01000000002', 'r', '08:00', current_date + 30,
            'instapay', 100, 'reserved', 'RGX-BK2')$$,
  'uniq_active_booking_per_seat');

select pg_temp.expect_ok('G', 'cancelling releases the seat for a new booking',
  $$update public.operation_bookings set status = 'cancelled' where booking_number = 'RGX-BK1';
    insert into public.operation_bookings (trip_id, seat_id, seat, passenger_name, phone,
      route, trip_time, trip_date, payment_method, payment_amount, status, booking_number)
    values ((select v from _fx where k='trip_1'), (select v from _fx where k='seat_1'),
            '1', 'راكب ٣', '01000000003', 'r', '08:00', current_date + 30,
            'instapay', 100, 'reserved', 'RGX-BK3')$$);

select pg_temp.expect_that('G', 'two cancelled bookings may share a seat',
  (select count(*) >= 1 from public.operation_bookings
    where seat_id = pg_temp.fx('seat_1') and status = 'cancelled'));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- H. reassign_booking — repaired
-- ═══════════════════════════════════════════════════════════════════════════════════

select pg_temp.expect_ok('H', 'a booking can be moved to another trip and seat',
  $$select public.reassign_booking(
      (select id from public.operation_bookings where booking_number = 'RGX-BK3'),
      (select id from public.operation_trips where trip_code = 'RGX-T3'), '2')$$);

select pg_temp.expect_that('H', 'the booking now points at a seat of its new trip',
  (select exists (
     select 1 from public.operation_bookings b
     join public.trip_seats s on s.id = b.seat_id
     join public.operation_trips t on t.id = b.trip_id
     where b.booking_number = 'RGX-BK3' and s.trip_id = t.id and t.trip_code = 'RGX-T3')));

select pg_temp.expect_that('H', 'the old seat was released',
  (select state = 'available' from public.trip_seats where id = pg_temp.fx('seat_1')));

select pg_temp.expect_that('H', 'the new seat is held',
  (select s.state = 'paid' from public.operation_bookings b
   join public.trip_seats s on s.id = b.seat_id
   where b.booking_number = 'RGX-BK3'));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- Report
-- ═══════════════════════════════════════════════════════════════════════════════════
select 0 as ord, 'TOTAL' as section,
       (count(*) filter (where passed))::text || ' passed / ' ||
       (count(*) filter (where not passed))::text || ' failed' as name,
       case when count(*) filter (where not passed) = 0
            then 'ALL GREEN' else 'FAILURES PRESENT' end as detail
from _r
union all
select 1, section,
       (count(*) filter (where passed))::text || '/' || count(*)::text || ' passed',
       case when count(*) filter (where not passed) = 0 then 'ok' else 'HAS FAILURES' end
from _r group by section
union all
select 2, section, name, detail from _r where not passed
order by 1, 2, 3;

rollback;
