-- ═══════════════════════════════════════════════════════════════════════════════════
-- Trip lifecycle — database regression suite
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 3 of the Dashboard Re-Ownership Program.
--
--   supabase db query --linked -f supabase/tests/trip_lifecycle_regression.sql
--
-- Runs entirely inside BEGIN … ROLLBACK. Every fixture it creates is discarded when it
-- finishes, whether it passes or fails — the live database is never modified. This is
-- also the only way to exercise `boarding` and `in_progress`, which no production trip
-- has ever been in.
--
-- Authorisation is exercised by impersonating real principals with
-- `set local role authenticated` + `request.jwt.claims`, so RLS and every RPC's own
-- checks run exactly as they do for the apps.
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

-- Expect the statement to raise, with sqlerrm containing p_needle.
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

-- Expect the statement to succeed.
create function pg_temp.expect_ok(
  p_section text, p_name text, p_sql text
) returns void language plpgsql as $$
begin
  execute p_sql;
  insert into _r (section, name, passed, detail) values (p_section, p_name, true, 'ok');
exception when others then
  insert into _r (section, name, passed, detail)
  values (p_section, p_name, false, 'unexpected error: ' || sqlerrm);
end $$;

create function pg_temp.expect_that(
  p_section text, p_name text, p_cond boolean, p_detail text default ''
) returns void language plpgsql as $$
begin
  insert into _r (section, name, passed, detail)
  values (p_section, p_name, coalesce(p_cond, false), p_detail);
end $$;

create function pg_temp.as_user(p_uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
end $$;

-- `reset role` restores the role but not the JWT claims, and auth.uid() reads the
-- claims — so without this every fixture built after an impersonated section would
-- still be attributed to that user.
create function pg_temp.as_service() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '', true);
end $$;

-- ───────────────────────────────────────────────────────────────────────────────────
-- Principals (real rows in the live database)
-- ───────────────────────────────────────────────────────────────────────────────────
insert into _fx (k, v) values
  ('office_a',        '00000000-0000-0000-0000-0000000000e0'),
  ('office_b',        '09befe32-dcaa-40a8-8e22-1ea628029f08'),
  ('operator_a',      '68fc40bf-38aa-4481-a6f0-208300055b21'),
  ('operator_b',      'd2c7aeb3-dc80-4975-ad35-ac62ce4c1bbb'),
  ('driver_a',        '8440408b-0534-4471-8de3-85832de00b8c'),
  ('driver_a_user',   '0c2a87f5-a5d5-41f9-8132-4fd0a14268e2'),
  ('driver_b',        'b23e8b62-c4db-431e-93bc-da71478aef4c'),
  ('driver_b_user',   'a44f99a7-7f0c-44c4-a4c2-60da237cc7fd'),
  ('route_a',         '20a21eaf-9f79-46b8-92a0-de0b299f9f54'),
  ('vehicle_a',       '683f4542-71ab-44b5-ac81-aae70aee32f4'),
  ('client_1',        'f6d901ac-1b2a-420d-9265-ae8e3c3e9654'),
  ('client_2',        '6ab16dee-a931-444a-8488-fbbb0d8dce19');

insert into _fx (k, v) values ('vehicle_b', gen_random_uuid());

-- ───────────────────────────────────────────────────────────────────────────────────
-- Fleet pairing
-- ───────────────────────────────────────────────────────────────────────────────────
-- Added with 20260731090000_driver_vehicle_authority: a trip may only run on the
-- vehicle its driver is actually assigned to, so this suite's two drivers each need
-- one. `driver_b` gets a vehicle of its own — before the migration it borrowed
-- `vehicle_a` from `driver_a`, which is exactly the dispatch the migration forbids.
-- All of this is inside the suite's transaction and rolls back with everything else.

insert into public.vehicles
  (id, office_id, vehicle_code, plate_number, vehicle_type, brand, model,
   manufacture_year, color, capacity, seat_layout_type, status, seat_configuration)
values
  (pg_temp.fx('vehicle_b'), pg_temp.fx('office_a'), 'TLC-B', 'TLC B', 'Hiace',
   'Toyota', 'Hiace', 2022, 'أبيض', 3, 'standard',
   'active', '{"rows":2,"columns":3,"seats":[
      {"seat_number":"D","seat_type":"driver","row":1,"column":1},
      {"seat_number":"1","seat_type":"passenger","row":2,"column":1},
      {"seat_number":"2","seat_type":"passenger","row":2,"column":2},
      {"seat_number":"3","seat_type":"passenger","row":2,"column":3}]}'::jsonb);

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

select pg_temp.pair(pg_temp.fx('driver_a'), pg_temp.fx('vehicle_a'));
select pg_temp.pair(pg_temp.fx('driver_b'), pg_temp.fx('vehicle_b'));

-- ───────────────────────────────────────────────────────────────────────────────────
-- Fixture builder
-- ───────────────────────────────────────────────────────────────────────────────────
-- Built as `postgres` with auth.uid() null, which the write-authority trigger treats as
-- service context — the same carve-out migrations and backfills use.

-- Every fixture trip gets its own day. This suite was written before Phase 4 added the
-- `operation_trips_{driver,vehicle}_no_overlap` exclusion constraints, and it schedules
-- ~40 trips onto one driver and one bus — all at 08:00, all on `current_date + 10`. The
-- second insert has been failing on the constraint ever since, which took the whole
-- suite down before its first assertion. The day is shifted away from today in whatever
-- direction the caller asked for, so "past" fixtures stay in the past and "future" ones
-- stay in the future; nothing here asserts on a specific date.
create sequence pg_temp.trip_day_seq;

create function pg_temp.mk_trip(
  p_key       text,
  p_status    text,
  p_date      date  default current_date + 10,
  p_driver    uuid  default null,
  p_vehicle   uuid  default null,
  p_seats     int   default 4,
  p_pricing   boolean default true
) returns uuid language plpgsql as $$
declare
  v_id   uuid;
  v_p1   uuid;
  v_p2   uuid;
  v_day  int := nextval('pg_temp.trip_day_seq');
  v_date date := case when p_date < current_date then p_date - v_day
                      else p_date + v_day end;
begin
  insert into public.operation_trips (
    trip_code, route_id, driver_id, vehicle_id, trip_date, departure_time,
    arrival_time, status, capacity, ticket_price, currency
  ) values (
    'TEST-' || p_key || '-' || substr(gen_random_uuid()::text, 1, 6),
    pg_temp.fx('route_a'),
    coalesce(p_driver, pg_temp.fx('driver_a')),
    coalesce(p_vehicle, pg_temp.fx('vehicle_a')),
    v_date, '08:00', '10:00', p_status, greatest(p_seats, 1), 50, 'ج.م'
  ) returning id into v_id;

  -- Nulling after insert: sync_trip_office needs route_id, and the not-null office
  -- guard would reject a driverless insert path otherwise.
  if p_driver is null and p_key like '%nodriver%' then
    update public.operation_trips set driver_id = null where id = v_id;
  end if;

  insert into public.trip_route_points (trip_id, route_point_id, point_name, point_order)
  values (v_id, null, 'A', 1) returning id into v_p1;
  insert into public.trip_route_points (trip_id, route_point_id, point_name, point_order)
  values (v_id, null, 'B', 2) returning id into v_p2;

  if p_seats > 0 then
    insert into public.trip_seats (trip_id, seat_label, seat_row, seat_column, state)
    select v_id, n::text, 1, n, 'available' from generate_series(1, p_seats) n;
  end if;

  if p_pricing then
    insert into public.trip_pricing (
      trip_id, from_point_id, to_point_id, from_point_name, to_point_name,
      from_point_order, to_point_order, one_time_price, five_days_price,
      ten_days_price, monthly_price, three_months_price, currency, is_active
    ) values (v_id, v_p1, v_p2, 'A', 'B', 1, 2, 50, 175, 187, 200, 225, 'ج.م', true);
  end if;

  insert into _fx (k, v) values (p_key, v_id);
  return v_id;
end $$;

-- A booked seat with a booking, a payment and a manifest row.
create function pg_temp.mk_booking(
  p_trip uuid, p_client uuid, p_key text,
  p_booking_status text default 'confirmed',
  p_payment_status text default 'approved',
  p_with_passenger boolean default true
) returns uuid language plpgsql as $$
declare
  v_seat  uuid;
  v_label text;
  v_bk    uuid;
begin
  select id, seat_label into v_seat, v_label from public.trip_seats
  where trip_id = p_trip and state = 'available' order by seat_label limit 1;

  update public.trip_seats
  set state = 'paid', passenger_id = p_client,
      held_at = now(), hold_expires_at = now() + interval '30 minutes',
      lock_expires_at = now() + interval '5 minutes'
  where id = v_seat;

  insert into public.operation_bookings (
    client_id, trip_id, passenger_name, phone, route, trip_time, trip_date,
    seat, payment_method, payment_amount, seat_id, status, booking_number,
    payment_status, created_by_source
  ) values (
    p_client, p_trip, 'Fixture Rider', '01000000000', 'A → B', '08:00',
    (select trip_date from public.operation_trips where id = p_trip),
    v_label, 'instapay', 50, v_seat, p_booking_status,
    'TEST-' || substr(gen_random_uuid()::text, 1, 10), p_payment_status, 'client'
  ) returning id into v_bk;

  if p_with_passenger then
    insert into public.trip_passengers (
      booking_id, trip_id, customer_id, passenger_name, phone, seat_id, seat_label,
      pickup_point_name, dropoff_point_name, payment_method, status
    ) values (
      v_bk, p_trip, p_client, 'Fixture Rider', '01000000000', v_seat, v_label,
      'A', 'B', 'instapay', 'confirmed'
    );
  end if;

  insert into _fx (k, v) values (p_key, v_bk);
  insert into _fx (k, v) values (p_key || '_seat', v_seat);
  return v_bk;
end $$;

-- ═══════════════════════════════════════════════════════════════════════════════════
-- A. Valid transitions
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('a_sched',   'scheduled');
select pg_temp.mk_trip('a_open',    'open_for_booking');
select pg_temp.mk_trip('a_board',   'boarding');
select pg_temp.mk_trip('a_prog',    'in_progress');
select pg_temp.mk_trip('a_sched_c', 'scheduled');
select pg_temp.mk_trip('a_open_c',  'open_for_booking');
select pg_temp.mk_trip('a_board_c', 'boarding');
select pg_temp.mk_trip('a_prog_c',  'in_progress');

select pg_temp.as_user(pg_temp.fx('operator_a'));
set local role authenticated;

select pg_temp.expect_ok('A', 'scheduled -> open_for_booking',
  $q$ select public.office_update_trip_status(pg_temp.fx('a_sched'), 'open_for_booking') $q$);
select pg_temp.expect_ok('A', 'open_for_booking -> boarding',
  $q$ select public.office_update_trip_status(pg_temp.fx('a_open'), 'boarding') $q$);
select pg_temp.expect_ok('A', 'boarding -> in_progress',
  $q$ select public.office_update_trip_status(pg_temp.fx('a_board'), 'in_progress') $q$);
select pg_temp.expect_ok('A', 'in_progress -> completed',
  $q$ select public.office_update_trip_status(pg_temp.fx('a_prog'), 'completed') $q$);
select pg_temp.expect_ok('A', 'scheduled -> cancelled',
  $q$ select public.office_cancel_trip(pg_temp.fx('a_sched_c'), 'fixture') $q$);
select pg_temp.expect_ok('A', 'open_for_booking -> cancelled',
  $q$ select public.office_cancel_trip(pg_temp.fx('a_open_c'), 'fixture') $q$);
select pg_temp.expect_ok('A', 'boarding -> cancelled (with reason)',
  $q$ select public.office_cancel_trip(pg_temp.fx('a_board_c'), 'breakdown') $q$);
select pg_temp.expect_ok('A', 'in_progress -> cancelled (with reason)',
  $q$ select public.office_cancel_trip(pg_temp.fx('a_prog_c'), 'breakdown') $q$);

reset role;
select pg_temp.as_service();
select pg_temp.expect_that('A', 'transitions actually persisted',
  (select count(*) = 8 from public.operation_trips t join _fx f on f.v = t.id
   where f.k in ('a_sched','a_open','a_board','a_prog','a_sched_c','a_open_c','a_board_c','a_prog_c')
     and t.status in ('open_for_booking','boarding','in_progress','completed','cancelled')),
  'all eight fixtures moved');

-- Emergency cancel needs a reason.
select pg_temp.mk_trip('a_board_nr', 'boarding');
select pg_temp.mk_trip('a_prog_nr',  'in_progress');
select pg_temp.as_user(pg_temp.fx('operator_a'));
set local role authenticated;
select pg_temp.expect_error('A', 'boarding -> cancelled without reason is refused',
  $q$ select public.office_update_trip_status(pg_temp.fx('a_board_nr'), 'cancelled') $q$,
  'cancellation_reason_required');
select pg_temp.expect_error('A', 'in_progress -> cancelled without reason is refused',
  $q$ select public.office_update_trip_status(pg_temp.fx('a_prog_nr'), 'cancelled') $q$,
  'cancellation_reason_required');
reset role;
select pg_temp.as_service();

-- ═══════════════════════════════════════════════════════════════════════════════════
-- B. Invalid transitions
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('b_sched', 'scheduled');
select pg_temp.mk_trip('b_open',  'open_for_booking');
select pg_temp.mk_trip('b_board', 'boarding');
select pg_temp.mk_trip('b_prog',  'in_progress');
select pg_temp.mk_trip('b_done',  'completed');
select pg_temp.mk_trip('b_canc',  'cancelled');

select pg_temp.as_user(pg_temp.fx('operator_a'));
set local role authenticated;

select pg_temp.expect_error('B', 'scheduled -> boarding',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_sched'), 'boarding') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'scheduled -> in_progress',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_sched'), 'in_progress') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'scheduled -> completed',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_sched'), 'completed') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'open_for_booking -> in_progress',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_open'), 'in_progress') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'open_for_booking -> completed (the stale-banner button)',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_open'), 'completed') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'open_for_booking -> scheduled (no un-publish)',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_open'), 'scheduled') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'boarding -> open_for_booking',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_board'), 'open_for_booking') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'boarding -> completed',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_board'), 'completed') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'in_progress -> boarding',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_prog'), 'boarding') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'completed -> open_for_booking (terminal)',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_done'), 'open_for_booking') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'completed -> cancelled (terminal)',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_done'), 'cancelled', 'x') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'cancelled -> open_for_booking (terminal)',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_canc'), 'open_for_booking') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'cancelled -> boarding (terminal)',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_canc'), 'boarding') $q$, 'invalid_transition');
select pg_temp.expect_error('B', 'unknown status is rejected',
  $q$ select public.office_update_trip_status(pg_temp.fx('b_sched'), 'departed') $q$, 'invalid_transition');
reset role;
select pg_temp.as_service();

-- ═══════════════════════════════════════════════════════════════════════════════════
-- C. Publish readiness gate
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('c_nopricing', 'scheduled', current_date + 10, null, null, 4, false);
select pg_temp.mk_trip('c_noseats',   'scheduled', current_date + 10, null, null, 0, true);
select pg_temp.mk_trip('c_past',      'scheduled', current_date - 3);
select pg_temp.mk_trip('c_ok',        'scheduled');

select pg_temp.mk_trip('c_nodriver',  'scheduled');
update public.operation_trips set driver_id = null where id = pg_temp.fx('c_nodriver');
select pg_temp.mk_trip('c_novehicle', 'scheduled');

-- Since 20260731090000_driver_vehicle_authority a trip that has a driver but no vehicle
-- can no longer be produced at all — the driver's assignment supplies the vehicle, and
-- taking it away is refused. The `no_vehicle` publish gate below therefore only ever
-- applies to rows that predate that rule, so the fixture is built the way such a row
-- would have been: with the pairing trigger stood down for exactly one statement, as
-- `postgres`, inside this suite's rolled-back transaction.
select pg_temp.expect_error('C', 'a driver''s trip can no longer lose its vehicle',
  $q$ update public.operation_trips set vehicle_id = null
      where id = pg_temp.fx('c_novehicle') $q$,
  'driver_vehicle_mismatch');

alter table public.operation_trips disable trigger trg_trip_resource_authority;
update public.operation_trips set vehicle_id = null where id = pg_temp.fx('c_novehicle');
alter table public.operation_trips enable trigger trg_trip_resource_authority;

select pg_temp.as_user(pg_temp.fx('operator_a'));
set local role authenticated;
select pg_temp.expect_error('C', 'publish blocked: no pricing',
  $q$ select public.office_update_trip_status(pg_temp.fx('c_nopricing'), 'open_for_booking') $q$,
  'trip_not_publishable:no_pricing');
select pg_temp.expect_error('C', 'publish blocked: no seats',
  $q$ select public.office_update_trip_status(pg_temp.fx('c_noseats'), 'open_for_booking') $q$,
  'trip_not_publishable:no_seats');
select pg_temp.expect_error('C', 'publish blocked: past date',
  $q$ select public.office_update_trip_status(pg_temp.fx('c_past'), 'open_for_booking') $q$,
  'trip_not_publishable:past_date');
select pg_temp.expect_error('C', 'publish blocked: no driver',
  $q$ select public.office_update_trip_status(pg_temp.fx('c_nodriver'), 'open_for_booking') $q$,
  'trip_not_publishable:no_driver');
select pg_temp.expect_error('C', 'publish blocked: no vehicle',
  $q$ select public.office_update_trip_status(pg_temp.fx('c_novehicle'), 'open_for_booking') $q$,
  'trip_not_publishable:no_vehicle');
select pg_temp.expect_ok('C', 'publish allowed when ready',
  $q$ select public.office_update_trip_status(pg_temp.fx('c_ok'), 'open_for_booking') $q$);
reset role;
select pg_temp.as_service();
select pg_temp.expect_that('C', 'blocked trips stayed scheduled',
  (select count(*) = 5 from public.operation_trips t join _fx f on f.v = t.id
   where f.k in ('c_nopricing','c_noseats','c_past','c_nodriver','c_novehicle')
     and t.status = 'scheduled'));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- D. Authorisation
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('d_open',   'open_for_booking');
select pg_temp.mk_trip('d_open2',  'open_for_booking');
select pg_temp.mk_trip('d_other',  'open_for_booking', current_date + 10,
                       pg_temp.fx('driver_b'), pg_temp.fx('vehicle_b'));

-- Foreign office operator
select pg_temp.as_user(pg_temp.fx('operator_b'));
set local role authenticated;
select pg_temp.expect_error('D', 'foreign-office operator cannot transition',
  $q$ select public.office_update_trip_status(pg_temp.fx('d_open'), 'boarding') $q$, 'not_authorized');
select pg_temp.expect_error('D', 'foreign-office operator cannot cancel',
  $q$ select public.office_cancel_trip(pg_temp.fx('d_open'), 'x') $q$, 'not_authorized');
select pg_temp.expect_error('D', 'foreign-office operator cannot close a stale trip',
  $q$ select public.office_close_stale_trip(pg_temp.fx('d_open'), 'cancelled', 'x') $q$, 'not_authorized');
reset role;
select pg_temp.as_service();

-- Plain client, no office and no driver row
select pg_temp.as_user(pg_temp.fx('client_1'));
set local role authenticated;
select pg_temp.expect_error('D', 'plain client cannot transition',
  $q$ select public.office_update_trip_status(pg_temp.fx('d_open'), 'boarding') $q$, 'not_authorized');
select pg_temp.expect_error('D', 'plain client is not a captain',
  $q$ select public.captain_update_trip_status(pg_temp.fx('d_open'), 'boarding') $q$, 'not_a_captain');
select pg_temp.expect_error('D', 'update_trip_status is not executable by authenticated',
  $q$ select public.update_trip_status(pg_temp.fx('d_open'), 'boarding') $q$, 'permission denied');
reset role;
select pg_temp.as_service();

-- Assigned captain
select pg_temp.as_user(pg_temp.fx('driver_a_user'));
set local role authenticated;
select pg_temp.expect_ok('D', 'assigned captain may start boarding',
  $q$ select public.captain_update_trip_status(pg_temp.fx('d_open'), 'boarding') $q$);
select pg_temp.expect_error('D', 'captain may not cancel',
  $q$ select public.captain_update_trip_status(pg_temp.fx('d_open'), 'cancelled', 'x') $q$,
  'status_not_allowed_for_captain');
select pg_temp.expect_error('D', 'captain may not publish',
  $q$ select public.captain_update_trip_status(pg_temp.fx('d_open2'), 'open_for_booking') $q$,
  'status_not_allowed_for_captain');
select pg_temp.expect_error('D', 'captain may not touch another captain''s trip',
  $q$ select public.captain_update_trip_status(pg_temp.fx('d_other'), 'boarding') $q$, 'not_your_trip');
select pg_temp.expect_error('D', 'captain may not cancel via the office wrapper either',
  $q$ select public.office_update_trip_status(pg_temp.fx('d_open2'), 'cancelled', 'x') $q$,
  'status_not_allowed_for_captain');
select pg_temp.expect_error('D', 'captain may not publish via the office wrapper either',
  $q$ select public.office_update_trip_status(pg_temp.fx('d_open2'), 'open_for_booking') $q$,
  'status_not_allowed_for_captain');
reset role;
select pg_temp.as_service();

-- ═══════════════════════════════════════════════════════════════════════════════════
-- E. Direct-write bypass (the hole this phase closes)
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('e_open',  'open_for_booking');
select pg_temp.mk_trip('e_prog',  'in_progress');
select pg_temp.mk_trip('e_done',  'completed');
select pg_temp.mk_trip('e_sched', 'scheduled');
select pg_temp.mk_trip('e_board', 'boarding');

select pg_temp.as_user(pg_temp.fx('operator_a'));
set local role authenticated;
select pg_temp.expect_error('E', 'operator cannot write status directly',
  $q$ update public.operation_trips set status = 'completed' where id = pg_temp.fx('e_open') $q$,
  'trip_status_direct_update_forbidden');
select pg_temp.expect_error('E', 'operator cannot resurrect a completed trip directly',
  $q$ update public.operation_trips set status = 'open_for_booking' where id = pg_temp.fx('e_done') $q$,
  'trip_status_direct_update_forbidden');
select pg_temp.expect_error('E', 'completed trip cannot be re-priced',
  $q$ update public.operation_trips set ticket_price = 1 where id = pg_temp.fx('e_done') $q$,
  'trip_locked');
select pg_temp.expect_error('E', 'completed trip cannot be re-dated',
  $q$ update public.operation_trips set trip_date = current_date + 30 where id = pg_temp.fx('e_done') $q$,
  'trip_locked');
select pg_temp.expect_error('E', 'running trip cannot be re-priced',
  $q$ update public.operation_trips set ticket_price = 1 where id = pg_temp.fx('e_prog') $q$,
  'trip_locked');
select pg_temp.expect_ok('E', 'boarding trip may still swap vehicle (breakdown)',
  $q$ update public.operation_trips set vehicle_id = pg_temp.fx('vehicle_a') where id = pg_temp.fx('e_board') $q$);
select pg_temp.expect_ok('E', 'scheduled trip may still be re-planned',
  $q$ update public.operation_trips set departure_time = '09:00', ticket_price = 60
      where id = pg_temp.fx('e_sched') $q$);
reset role;
select pg_temp.as_service();

-- Captain writing the table directly, at all
select pg_temp.as_user(pg_temp.fx('driver_a_user'));
set local role authenticated;
-- The status guard fires before the captain guard, so a captain writing `status`
-- directly is rejected as an unauthorised transition rather than as an unauthorised
-- writer. Both are correct; the transition message is the more precise one.
select pg_temp.expect_error('E', 'captain cannot write status directly',
  $q$ update public.operation_trips set status = 'completed' where id = pg_temp.fx('e_open') $q$,
  'trip_status_direct_update_forbidden');
select pg_temp.expect_error('E', 'captain cannot rewrite the fare on their own trip',
  $q$ update public.operation_trips set ticket_price = 1 where id = pg_temp.fx('e_open') $q$,
  'trip_direct_write_forbidden');
select pg_temp.expect_error('E', 'captain cannot reassign their own trip',
  $q$ update public.operation_trips set driver_id = pg_temp.fx('driver_b') where id = pg_temp.fx('e_open') $q$,
  'trip_direct_write_forbidden');
reset role;
select pg_temp.as_service();

select pg_temp.expect_that('E', 'no direct write landed',
  (select status = 'open_for_booking' and ticket_price = 50
   from public.operation_trips where id = pg_temp.fx('e_open')));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- F. Cancellation side effects
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('f_trip', 'open_for_booking');
select pg_temp.mk_booking(pg_temp.fx('f_trip'), pg_temp.fx('client_1'), 'f_paid',
                          'confirmed', 'approved', true);
-- A rider whose payment is still under review: no trip_passengers row, and before this
-- phase they were cancelled without ever being told.
select pg_temp.mk_booking(pg_temp.fx('f_trip'), pg_temp.fx('client_2'), 'f_pending',
                          'reserved', 'submitted', false);

create temp table _n0 as
select count(*) as n from public.notifications where user_id = pg_temp.fx('client_2');

select pg_temp.as_user(pg_temp.fx('operator_a'));
set local role authenticated;
select pg_temp.expect_ok('F', 'cancel a trip carrying bookings',
  $q$ select public.office_cancel_trip(pg_temp.fx('f_trip'), 'vehicle breakdown') $q$);
reset role;
select pg_temp.as_service();

select pg_temp.expect_that('F', 'all bookings cancelled',
  (select count(*) = 0 from public.operation_bookings
   where trip_id = pg_temp.fx('f_trip') and status not in ('cancelled','rejected')));
select pg_temp.expect_that('F', 'passengers cancelled (were orphaned before)',
  (select count(*) = 0 from public.trip_passengers
   where trip_id = pg_temp.fx('f_trip') and status not in ('cancelled','no_show','completed')));
select pg_temp.expect_that('F', 'seats released',
  (select count(*) = 0 from public.trip_seats
   where trip_id = pg_temp.fx('f_trip') and state not in ('available','blocked')));
select pg_temp.expect_that('F', 'seat holds cleared',
  (select count(*) = 0 from public.trip_seats
   where trip_id = pg_temp.fx('f_trip')
     and (held_at is not null or hold_expires_at is not null or lock_expires_at is not null)));
select pg_temp.expect_that('F', 'payment_status left alone (money did not move)',
  (select payment_status = 'approved' from public.operation_bookings where id = pg_temp.fx('f_paid')));
select pg_temp.expect_that('F', 'under-review rider is now notified',
  (select count(*) > (select n from _n0) from public.notifications
   where user_id = pg_temp.fx('client_2')));
select pg_temp.expect_that('F', 'cancellation event records the refund exposure',
  (select description like '%استرداد%' from public.trip_events
   where trip_id = pg_temp.fx('f_trip') and event_code = 'trip_cancelled'
   order by event_time desc limit 1));
select pg_temp.expect_that('F', 'cancellation event records the reason',
  (select description like '%vehicle breakdown%' from public.trip_events
   where trip_id = pg_temp.fx('f_trip') and event_code = 'trip_cancelled'
   order by event_time desc limit 1));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- G. Completion side effects
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('g_trip', 'in_progress');
select pg_temp.mk_booking(pg_temp.fx('g_trip'), pg_temp.fx('client_1'), 'g_boarded',
                          'confirmed', 'approved', true);
select pg_temp.mk_booking(pg_temp.fx('g_trip'), pg_temp.fx('client_2'), 'g_absent',
                          'confirmed', 'approved', true);
update public.trip_passengers set status = 'reserved'
where trip_id = pg_temp.fx('g_trip') and customer_id = pg_temp.fx('client_2');

select pg_temp.as_user(pg_temp.fx('operator_a'));
set local role authenticated;
select pg_temp.expect_ok('G', 'complete a running trip',
  $q$ select public.office_update_trip_status(pg_temp.fx('g_trip'), 'completed') $q$);
reset role;
select pg_temp.as_service();

select pg_temp.expect_that('G', 'confirmed bookings become completed',
  (select status = 'completed' from public.operation_bookings where id = pg_temp.fx('g_boarded')));
select pg_temp.expect_that('G', 'boarded passenger becomes completed',
  (select status = 'completed' from public.trip_passengers
   where trip_id = pg_temp.fx('g_trip') and customer_id = pg_temp.fx('client_1')));
select pg_temp.expect_that('G', 'unboarded passenger becomes no_show',
  (select status = 'no_show' from public.trip_passengers
   where trip_id = pg_temp.fx('g_trip') and customer_id = pg_temp.fx('client_2')));
select pg_temp.expect_that('G', 'actual_end_time stamped',
  (select actual_end_time is not null from public.operation_trips where id = pg_temp.fx('g_trip')));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- H. Idempotency and concurrency
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('h_trip', 'open_for_booking');
select pg_temp.as_user(pg_temp.fx('operator_a'));
set local role authenticated;
select pg_temp.expect_ok('H', 'first boarding call',
  $q$ select public.office_update_trip_status(pg_temp.fx('h_trip'), 'boarding') $q$);
select pg_temp.expect_that('H', 'repeat call is a no-op, not an error',
  (select (public.office_update_trip_status(pg_temp.fx('h_trip'), 'boarding') ->> 'unchanged')::boolean));
select pg_temp.expect_error('H', 'a second racer sees invalid_transition, never a double apply',
  $q$ select public.office_update_trip_status(pg_temp.fx('h_trip'), 'in_progress'),
             public.office_update_trip_status(pg_temp.fx('h_trip'), 'in_progress'),
             public.office_update_trip_status(pg_temp.fx('h_trip'), 'boarding') $q$,
  'invalid_transition');
reset role;
select pg_temp.as_service();
select pg_temp.expect_that('H', 'exactly one boarding event was written',
  (select count(*) = 1 from public.trip_events
   where trip_id = pg_temp.fx('h_trip') and event_code = 'boarding_started'));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- I. Booking availability
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('i_sched',  'scheduled');
select pg_temp.mk_trip('i_open',   'open_for_booking');
select pg_temp.mk_trip('i_board',  'boarding');
select pg_temp.mk_trip('i_done',   'completed');
select pg_temp.mk_trip('i_canc',   'cancelled');
select pg_temp.mk_trip('i_past',   'open_for_booking', current_date - 2);

create function pg_temp.seat_of(p_key text) returns uuid language sql stable as $$
  select id from public.trip_seats where trip_id = pg_temp.fx(p_key) and state = 'available' limit 1
$$;

select pg_temp.as_user(pg_temp.fx('client_1'));
set local role authenticated;
select pg_temp.expect_error('I', 'cannot lock a seat on a scheduled trip',
  $q$ select public.lock_trip_seat(pg_temp.fx('i_sched'), pg_temp.seat_of('i_sched'), pg_temp.fx('client_1')) $q$,
  'trip_not_bookable');
select pg_temp.expect_error('I', 'cannot lock a seat on a boarding trip',
  $q$ select public.lock_trip_seat(pg_temp.fx('i_board'), pg_temp.seat_of('i_board'), pg_temp.fx('client_1')) $q$,
  'trip_not_bookable');
select pg_temp.expect_error('I', 'cannot lock a seat on a completed trip',
  $q$ select public.lock_trip_seat(pg_temp.fx('i_done'), pg_temp.seat_of('i_done'), pg_temp.fx('client_1')) $q$,
  'trip_not_bookable');
select pg_temp.expect_error('I', 'cannot lock a seat on a cancelled trip',
  $q$ select public.lock_trip_seat(pg_temp.fx('i_canc'), pg_temp.seat_of('i_canc'), pg_temp.fx('client_1')) $q$,
  'trip_not_bookable');
select pg_temp.expect_error('I', 'cannot lock a seat on a departed (past-dated) trip',
  $q$ select public.lock_trip_seat(pg_temp.fx('i_past'), pg_temp.seat_of('i_past'), pg_temp.fx('client_1')) $q$,
  'trip_not_bookable');
select pg_temp.expect_ok('I', 'can lock a seat on a bookable trip',
  $q$ select public.lock_trip_seat(pg_temp.fx('i_open'), pg_temp.seat_of('i_open'), pg_temp.fx('client_1')) $q$);
reset role;
select pg_temp.as_service();

select pg_temp.expect_that('I', 'trip_is_bookable agrees with the six cases',
  (select public.trip_is_bookable(pg_temp.fx('i_open'))
      and not public.trip_is_bookable(pg_temp.fx('i_sched'))
      and not public.trip_is_bookable(pg_temp.fx('i_board'))
      and not public.trip_is_bookable(pg_temp.fx('i_done'))
      and not public.trip_is_bookable(pg_temp.fx('i_canc'))
      and not public.trip_is_bookable(pg_temp.fx('i_past'))));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- J. Delete guard
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('j_open',      'open_for_booking');
select pg_temp.mk_trip('j_booked',    'scheduled');
select pg_temp.mk_trip('j_deletable', 'scheduled');
select pg_temp.mk_booking(pg_temp.fx('j_booked'), pg_temp.fx('client_1'), 'j_bk');

select pg_temp.as_user(pg_temp.fx('operator_a'));
set local role authenticated;
select pg_temp.expect_error('J', 'a published trip cannot be deleted',
  $q$ delete from public.operation_trips where id = pg_temp.fx('j_open') $q$,
  'trip_delete_forbidden');
select pg_temp.expect_error('J', 'a trip with bookings cannot be deleted',
  $q$ delete from public.operation_trips where id = pg_temp.fx('j_booked') $q$,
  'trip_delete_forbidden');
select pg_temp.expect_ok('J', 'an unpublished, unbooked trip can still be deleted',
  $q$ delete from public.operation_trips where id = pg_temp.fx('j_deletable') $q$);
reset role;
select pg_temp.as_service();

-- ═══════════════════════════════════════════════════════════════════════════════════
-- K. booked_seats and public_trips.available_seats
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('k_trip', 'open_for_booking', current_date + 10, null, null, 6);
select pg_temp.expect_that('K', 'starts at zero',
  (select booked_seats = 0 from public.operation_trips where id = pg_temp.fx('k_trip')));

update public.trip_seats set state = 'paid'
where id in (select id from public.trip_seats where trip_id = pg_temp.fx('k_trip') limit 2);
select pg_temp.expect_that('K', 'occupying two seats bumps booked_seats to 2',
  (select booked_seats = 2 from public.operation_trips where id = pg_temp.fx('k_trip')));
select pg_temp.expect_that('K', 'public_trips.available_seats follows (4 of 6)',
  (select available_seats = 4 from public.public_trips where id = pg_temp.fx('k_trip')));

update public.trip_seats set state = 'available' where trip_id = pg_temp.fx('k_trip');
select pg_temp.expect_that('K', 'releasing them drops it back to 0',
  (select booked_seats = 0 from public.operation_trips where id = pg_temp.fx('k_trip')));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- L. Stale-trip close
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.mk_trip('l_ran',    'open_for_booking', current_date - 5);
select pg_temp.mk_trip('l_notrun', 'open_for_booking', current_date - 5);
select pg_temp.mk_trip('l_sched',  'scheduled',        current_date - 5);
select pg_temp.mk_trip('l_done',   'completed',        current_date - 5);
select pg_temp.mk_booking(pg_temp.fx('l_ran'), pg_temp.fx('client_1'), 'l_bk');

create temp table _n1 as
select count(*) as n from public.notifications where user_id = pg_temp.fx('client_1');

select pg_temp.as_user(pg_temp.fx('operator_a'));
set local role authenticated;
select pg_temp.expect_ok('L', 'a stale open trip that ran can be closed as operated',
  $q$ select public.office_close_stale_trip(pg_temp.fx('l_ran'), 'operated') $q$);
select pg_temp.expect_ok('L', 'a stale open trip that did not run can be cancelled',
  $q$ select public.office_close_stale_trip(pg_temp.fx('l_notrun'), 'cancelled', 'never departed') $q$);
select pg_temp.expect_error('L', 'a never-published trip cannot be claimed to have operated',
  $q$ select public.office_close_stale_trip(pg_temp.fx('l_sched'), 'operated') $q$, 'trip_never_published');
select pg_temp.expect_error('L', 'an already-closed trip is refused',
  $q$ select public.office_close_stale_trip(pg_temp.fx('l_done'), 'cancelled', 'x') $q$, 'trip_already_closed');
select pg_temp.expect_error('L', 'an unknown outcome is refused',
  $q$ select public.office_close_stale_trip(pg_temp.fx('l_notrun'), 'maybe') $q$, 'trip_already_closed');
reset role;
select pg_temp.as_service();

select pg_temp.expect_that('L', 'the operated trip is completed',
  (select status = 'completed' from public.operation_trips where id = pg_temp.fx('l_ran')));
select pg_temp.expect_that('L', 'its booking was closed too',
  (select status = 'completed' from public.operation_bookings where id = pg_temp.fx('l_bk')));
select pg_temp.expect_that('L', 'no stale replay notifications were sent',
  (select count(*) = (select n from _n1) from public.notifications
   where user_id = pg_temp.fx('client_1')));
select pg_temp.expect_that('L', 'the full chain is in the audit trail',
  (select count(distinct event_code) = 3 from public.trip_events
   where trip_id = pg_temp.fx('l_ran')
     and event_code in ('boarding_started','trip_departed','trip_completed')));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- M. Audit trail codes
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.expect_that('M', 'publish writes trip_published',
  (select exists (select 1 from public.trip_events
   where trip_id = pg_temp.fx('a_sched') and event_code = 'trip_published')));
select pg_temp.expect_that('M', 'boarding writes boarding_started',
  (select exists (select 1 from public.trip_events
   where trip_id = pg_temp.fx('a_open') and event_code = 'boarding_started')));
select pg_temp.expect_that('M', 'departure writes trip_departed',
  (select exists (select 1 from public.trip_events
   where trip_id = pg_temp.fx('a_board') and event_code = 'trip_departed')));
select pg_temp.expect_that('M', 'completion writes trip_completed',
  (select exists (select 1 from public.trip_events
   where trip_id = pg_temp.fx('a_prog') and event_code = 'trip_completed')));
select pg_temp.expect_that('M', 'cancellation writes trip_cancelled',
  (select exists (select 1 from public.trip_events
   where trip_id = pg_temp.fx('a_open_c') and event_code = 'trip_cancelled')));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- N. Marketplace visibility
-- ═══════════════════════════════════════════════════════════════════════════════════
select pg_temp.expect_that('N', 'public_trips hides unpublished trips',
  (select not exists (select 1 from public.public_trips where id = pg_temp.fx('b_sched'))));
select pg_temp.expect_that('N', 'public_trips hides cancelled trips',
  (select not exists (select 1 from public.public_trips where id = pg_temp.fx('b_canc'))));
select pg_temp.expect_that('N', 'public_trips shows published trips',
  (select exists (select 1 from public.public_trips where id = pg_temp.fx('b_open'))));
select pg_temp.expect_that('N', 'public_trips still shows a running trip its riders follow',
  (select exists (select 1 from public.public_trips where id = pg_temp.fx('b_prog'))));
select pg_temp.expect_that('N', 'public_trips still shows a completed trip for review',
  (select exists (select 1 from public.public_trips where id = pg_temp.fx('b_done'))));

-- ═══════════════════════════════════════════════════════════════════════════════════
-- Report
-- ═══════════════════════════════════════════════════════════════════════════════════
-- One result set, because the CLI surfaces only the last one: the totals row first,
-- then a row per section, then a row per failure with its detail.
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
