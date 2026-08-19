-- ═══════════════════════════════════════════════════════════════════════════════════
-- Station boarding authority regression suite
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Drives the complete station → arrival → wait → boarding → validation → departure →
-- next station scenario against the linked database, impersonating a real captain and
-- two real riders, and asserts both halves of every rule: what must work still works,
-- and what must be refused is still refused.
--
-- Runs entirely inside BEGIN … ROLLBACK. It forces a finished trip back to `boarding`,
-- rewrites its manifest, drives it, and throws all of it away. Nothing survives the
-- run, so it is safe against the production-bound development database.
--
--   supabase db query --linked -f supabase/tests/station_boarding_regression.sql
--
-- Every row of the output should read OK or "blocked". Any row reading BROKEN or
-- "STILL POSSIBLE" is a regression.
--
-- Covers: 20260811090000 (station boarding authority) as amended by 20260819120000
-- (departure gated on boarding alone), and the parts of 20260728120000 (captain
-- authority) and 20260729090000 (tracking authority) they change.
-- ═══════════════════════════════════════════════════════════════════════════════════

begin;

create temp table probe(step text, result text) on commit drop;
grant all on probe to authenticated;

-- ── Fixtures ────────────────────────────────────────────────────────────────────────
-- Point these at a captain who has a trip with at least three route points, and two
-- clients. Everything else is derived.
create temp table fx(
  captain_user uuid,
  rider_a      uuid,
  rider_b      uuid,
  trip_id      uuid,
  booking_a    uuid,
  booking_b    uuid,
  pax_a        uuid,
  pax_b        uuid,
  pax_c        uuid,
  st1          uuid,
  st2          uuid
) on commit drop;
grant all on fx to authenticated;

insert into fx(captain_user, rider_a, rider_b) values (
  'dcad0f26-7815-4646-b69d-b94b123ab4ef',   -- captain (drivers.user_id)
  '625ea9b6-620c-4eae-a8df-eace918e8872',   -- rider A — boards at station 1
  '674b3ec4-54ef-4ed7-b9ec-f234d9d0b736'    -- rider B — still waiting at station 2
);

do $$
declare
  v_driver uuid;
  v_trip   uuid;
  v_rp1    record;
  v_rp2    record;
  v_office uuid;
  v_booking_a uuid;
  v_booking_b uuid;
begin
  select d.id into v_driver from public.drivers d
   where d.user_id = (select captain_user from fx);
  if v_driver is null then
    insert into probe values ('00. captain fixture', 'ABORTED — no driver for captain_user');
    return;
  end if;

  select t.id, t.office_id into v_trip, v_office
    from public.operation_trips t
   where t.driver_id = v_driver
     and (select count(*) from public.trip_route_points rp where rp.trip_id = t.id) >= 3
   order by t.created_at desc
   limit 1;

  if v_trip is null then
    insert into probe values ('00. trip fixture', 'ABORTED — captain has no trip with 3+ points');
    return;
  end if;

  update fx set trip_id = v_trip;
  insert into probe values ('00. fixture trip', v_trip::text);

  -- Force the trip to `boarding`. `bmt.trip_transition` is the transaction-local flag
  -- trg_enforce_trip_write_authority checks; setting it is exactly what
  -- update_trip_status does, and it is the only way to stage a trip mid-lifecycle
  -- without walking the whole publish gate.
  perform set_config('bmt.trip_transition', v_trip::text, true);
  update public.operation_trips
     set status = 'boarding', actual_start_time = null, actual_end_time = null
   where id = v_trip;
  perform set_config('bmt.trip_transition', '', true);

  -- A clean slate: no board, no arrival events, no manifest.
  delete from public.trip_station_progress where trip_id = v_trip;
  delete from public.trip_events   where trip_id = v_trip and title in ('وصول محطة', 'راكب لم يصعد');
  delete from public.trip_passengers where trip_id = v_trip;
  -- Existing bookings are stood down rather than deleted: settled ones are referenced
  -- by booking_payments, and the point is only that they stop counting.
  update public.operation_bookings set status = 'cancelled' where trip_id = v_trip;

  select rp.route_point_id, rp.point_name into v_rp1
    from public.trip_route_points rp where rp.trip_id = v_trip order by rp.point_order limit 1;
  select rp.route_point_id, rp.point_name into v_rp2
    from public.trip_route_points rp where rp.trip_id = v_trip order by rp.point_order offset 1 limit 1;

  -- Three riders: two expected at station 1 (A confirms, C never shows), one at
  -- station 2 (B, still waiting when the vehicle leaves station 1).
  insert into public.operation_bookings
    (client_id, trip_id, passenger_name, phone, route, trip_time, trip_date, seat,
     payment_method, status, payment_status, office_id)
  values
    ((select rider_a from fx), v_trip, 'راكب أ', '01000000001', 'اختبار', '08:00',
     current_date, 'A1', 'cash', 'confirmed', 'approved', v_office)
  returning id into v_booking_a;

  insert into public.operation_bookings
    (client_id, trip_id, passenger_name, phone, route, trip_time, trip_date, seat,
     payment_method, status, payment_status, office_id)
  values
    ((select rider_b from fx), v_trip, 'راكب ب', '01000000002', 'اختبار', '08:00',
     current_date, 'B1', 'cash', 'confirmed', 'approved', v_office)
  returning id into v_booking_b;

  update fx set booking_a = v_booking_a, booking_b = v_booking_b;

  insert into public.trip_passengers
    (trip_id, customer_id, booking_id, passenger_name, phone, seat_label,
     pickup_point_id, pickup_point_name, dropoff_point_id, dropoff_point_name, status)
  values
    (v_trip, (select rider_a from fx), v_booking_a, 'راكب أ', '01000000001',
     'A1', v_rp1.route_point_id, v_rp1.point_name, v_rp2.route_point_id, v_rp2.point_name, 'reserved'),
    (v_trip, null, null, 'راكب ج', '01000000003',
     'C1', v_rp1.route_point_id, v_rp1.point_name, v_rp2.route_point_id, v_rp2.point_name, 'reserved'),
    (v_trip, (select rider_b from fx), v_booking_b, 'راكب ب', '01000000002',
     'B1', v_rp2.route_point_id, v_rp2.point_name, v_rp1.route_point_id, v_rp1.point_name, 'reserved');

  update fx set
    pax_a = (select id from public.trip_passengers where trip_id = v_trip and passenger_name = 'راكب أ'),
    pax_b = (select id from public.trip_passengers where trip_id = v_trip and passenger_name = 'راكب ب'),
    pax_c = (select id from public.trip_passengers where trip_id = v_trip and passenger_name = 'راكب ج');

  insert into probe values ('00. fixture manifest', '3 passengers, 2 bookings');
end $$;

-- ── 1. The board builds itself ──────────────────────────────────────────────────────
do $$
declare v_n int; v_trip uuid := (select trip_id from fx);
begin
  if v_trip is null then return; end if;
  perform public.ensure_trip_station_progress(v_trip);
  select count(*) into v_n from public.trip_station_progress where trip_id = v_trip;
  insert into probe values ('01. board seeded from route points',
    case when v_n >= 3 then 'OK — ' || v_n || ' stations' else 'BROKEN — ' || v_n end);

  insert into probe values ('01b. tallies denormalised at seed',
    (select case when expected_boardings = 2 and pending_count = 2
                 then 'OK — station 1 expects 2'
                 else 'BROKEN — expected ' || expected_boardings || ' pending ' || pending_count end
       from public.trip_station_progress where trip_id = v_trip and sequence = 1));

  insert into probe values ('01c. seeding is idempotent',
    case when public.ensure_trip_station_progress(v_trip) = 0
         then 'OK — second call inserts nothing' else 'BROKEN — duplicated' end);

  update fx set
    st1 = (select id from public.trip_station_progress where trip_id = v_trip and sequence = 1),
    st2 = (select id from public.trip_station_progress where trip_id = v_trip and sequence = 2);
end $$;

-- ── 2. The captain arrives ──────────────────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"dcad0f26-7815-4646-b69d-b94b123ab4ef","role":"authenticated"}';

do $$
declare v_trip uuid := (select trip_id from fx); v_res jsonb; v_n int;
begin
  if v_trip is null then return; end if;

  v_res := public.captain_arrive_station(v_trip);
  insert into probe values ('02. captain marks arrival',
    case when v_res->>'success' = 'true' and (v_res->>'sequence')::int = 1
         then 'OK — at station 1' else 'BROKEN — ' || v_res::text end);

  insert into probe values ('02b. station is waiting_for_passengers',
    (select case when status = 'waiting_for_passengers' and actual_arrival_at is not null
                 then 'OK' else 'BROKEN — ' || status end
       from public.trip_station_progress where trip_id = v_trip and sequence = 1));

  select count(*) into v_n from public.trip_events
   where trip_id = v_trip and title = 'وصول محطة';
  insert into probe values ('02c. arrival event filed for the other apps',
    case when v_n = 1 then 'OK' else 'BROKEN — ' || v_n || ' events' end);

  -- Double tap.
  v_res := public.captain_arrive_station(v_trip);
  select count(*) into v_n from public.trip_station_progress
   where trip_id = v_trip and actual_arrival_at is not null;
  insert into probe values ('02d. double tap does not advance',
    case when v_res->>'unchanged' = 'true' and v_n = 1
         then 'OK — idempotent' else 'STILL POSSIBLE — ' || v_n || ' arrived' end);
end $$;

-- ── 3. Condition A: the captain cannot leave with passengers unresolved ─────────────
do $$
declare v_trip uuid := (select trip_id from fx);
begin
  if v_trip is null then return; end if;
  begin
    perform public.captain_depart_station(v_trip);
    insert into probe values ('03. depart with 2 pending', 'STILL POSSIBLE — captain left');
  exception when others then
    insert into probe values ('03. depart with 2 pending',
      case when sqlerrm like 'passengers_not_boarded%' then 'blocked — ' || sqlerrm
           else 'BROKEN — wrong refusal: ' || sqlerrm end);
  end;
end $$;

-- ── 4. The rider confirms their own boarding ────────────────────────────────────────
set local request.jwt.claims = '{"sub":"625ea9b6-620c-4eae-a8df-eace918e8872","role":"authenticated"}';

do $$
declare v_trip uuid := (select trip_id from fx); v_res jsonb;
begin
  if v_trip is null then return; end if;

  v_res := public.passenger_confirm_boarding((select booking_a from fx));
  insert into probe values ('04. rider A confirms boarding',
    case when v_res->>'success' = 'true' then 'OK' else 'BROKEN — ' || v_res::text end);

  insert into probe values ('04b. booking flips to boarded',
    (select case when status = 'boarded' then 'OK' else 'BROKEN — ' || status end
       from public.operation_bookings where id = (select booking_a from fx)));

  insert into probe values ('04c. manifest row flips to confirmed',
    (select case when status = 'confirmed' and boarding_source = 'passenger'
                 then 'OK' else 'BROKEN — ' || status || '/' || coalesce(boarding_source,'null') end
       from public.trip_passengers where id = (select pax_a from fx)));

  insert into probe values ('04d. station tally updates in place',
    (select case when boarded_count = 1 and pending_count = 1
                 then 'OK — 2 expected, 1 boarded, 1 pending'
                 else 'BROKEN — boarded ' || boarded_count || ' pending ' || pending_count end
       from public.trip_station_progress where trip_id = v_trip and sequence = 1));

  -- Duplicate boarding request.
  v_res := public.passenger_confirm_boarding((select booking_a from fx));
  insert into probe values ('04e. duplicate boarding request',
    case when v_res->>'unchanged' = 'true' then 'OK — idempotent'
         else 'BROKEN — ' || v_res::text end);

  -- Someone else's booking.
  begin
    perform public.passenger_confirm_boarding((select booking_b from fx));
    insert into probe values ('04f. board another rider''s booking', 'STILL POSSIBLE');
  exception when others then
    insert into probe values ('04f. board another rider''s booking',
      case when sqlerrm like 'not_your_booking%' then 'blocked' else 'BROKEN — ' || sqlerrm end);
  end;
end $$;

-- Rider B's pickup is station 2; the vehicle is at station 1.
set local request.jwt.claims = '{"sub":"674b3ec4-54ef-4ed7-b9ec-f234d9d0b736","role":"authenticated"}';
do $$
begin
  if (select trip_id from fx) is null then return; end if;
  begin
    perform public.passenger_confirm_boarding((select booking_b from fx));
    insert into probe values ('04g. board from the wrong station', 'STILL POSSIBLE');
  exception when others then
    insert into probe values ('04g. board from the wrong station',
      case when sqlerrm like 'not_your_station%' then 'blocked' else 'BROKEN — ' || sqlerrm end);
  end;
end $$;

-- ── 5. The no-show is recorded, never skipped ───────────────────────────────────────
set local request.jwt.claims = '{"sub":"dcad0f26-7815-4646-b69d-b94b123ab4ef","role":"authenticated"}';

do $$
declare v_trip uuid := (select trip_id from fx); v_res jsonb;
begin
  if v_trip is null then return; end if;

  -- Still one pending, so still blocked.
  begin
    perform public.captain_depart_station(v_trip);
    insert into probe values ('05. depart with 1 pending', 'STILL POSSIBLE');
  exception when others then
    insert into probe values ('05. depart with 1 pending',
      case when sqlerrm like 'passengers_not_boarded:1%' then 'blocked' else 'BROKEN — ' || sqlerrm end);
  end;

  -- The direct write the captain used to have.
  begin
    update public.trip_passengers set status = 'no_show' where id = (select pax_c from fx);
    insert into probe values ('05b. captain writes no_show directly',
      case when found then 'STILL POSSIBLE — silent skip' else 'blocked' end);
  exception when others then
    insert into probe values ('05b. captain writes no_show directly', 'blocked — ' || sqlerrm);
  end;

  -- "Other" with no explanation is a skip with extra steps.
  begin
    perform public.captain_resolve_no_show((select pax_c from fx), 'other', null);
    insert into probe values ('05c. no-show "other" without a note', 'STILL POSSIBLE');
  exception when others then
    insert into probe values ('05c. no-show "other" without a note',
      case when sqlerrm like 'no_show_note_required%' then 'blocked' else 'BROKEN — ' || sqlerrm end);
  end;

  v_res := public.captain_resolve_no_show((select pax_c from fx), 'did_not_arrive', null);
  insert into probe values ('05d. no-show resolved with a reason',
    case when v_res->>'success' = 'true' then 'OK' else 'BROKEN — ' || v_res::text end);

  insert into probe values ('05e. resolution is attributable',
    (select case when no_show_reason = 'did_not_arrive'
                  and resolved_by is not null and resolved_at is not null
                 then 'OK — reason, author and time recorded'
                 else 'BROKEN' end
       from public.trip_passengers where id = (select pax_c from fx)));

  insert into probe values ('05f. no-show filed as a trip event',
    (select case when count(*) = 1 then 'OK' else 'BROKEN — ' || count(*) end
       from public.trip_events where trip_id = v_trip and title = 'راكب لم يصعد'));

  insert into probe values ('05g. boarding requirement now resolved',
    (select case when pending_count = 0 then 'OK — 0 pending'
                 else 'BROKEN — ' || pending_count end
       from public.trip_station_progress where trip_id = v_trip and sequence = 1));
end $$;

-- ── 6. The clock is NOT a gate (20260819120000) ─────────────────────────────────────
-- The published departure time and the configured dwell are shown to both apps and
-- enforced by neither: nobody can join this station's manifest any more, so a stop
-- whose riders are all accounted for has nobody left to wait for. Both probes here
-- invert what 20260811090000 asserted — an early departure must now SUCCEED.
reset role;

do $$
declare v_trip uuid := (select trip_id from fx);
begin
  if v_trip is null then return; end if;
  -- Arrived just now, five minutes of configured dwell still unspent, and the published
  -- departure half an hour out: under the old rule both clocks blocked this.
  update public.trip_station_progress
     set actual_arrival_at     = now(),
         min_dwell_seconds     = 300,
         expected_departure_at = now() + interval '30 minutes'
   where trip_id = v_trip and sequence = 1;
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"dcad0f26-7815-4646-b69d-b94b123ab4ef","role":"authenticated"}';

do $$
declare v_trip uuid := (select trip_id from fx); v_res jsonb;
begin
  if v_trip is null then return; end if;
  begin
    v_res := public.captain_depart_station(v_trip);
    insert into probe values ('06. boarding resolved departs before dwell and schedule',
      case when v_res->>'success' = 'true' then 'OK — left early'
           else 'BROKEN — ' || v_res::text end);
  exception when others then
    insert into probe values ('06. boarding resolved departs before dwell and schedule',
      'BROKEN — still blocked: ' || sqlerrm);
  end;
end $$;

-- Rewind: station 1 back to standing, station 2 back to upcoming, and the trip back to
-- `boarding` — so section 7 still proves that *leaving the first station* is what puts
-- a trip in progress, rather than reading a flag section 6 already set.
reset role;
do $$
declare v_trip uuid := (select trip_id from fx);
begin
  if v_trip is null then return; end if;

  update public.trip_station_progress
     set actual_departure_at = null,
         status              = 'waiting_for_passengers',
         departed_by         = null
   where trip_id = v_trip and sequence = 1;
  update public.trip_station_progress
     set status = 'upcoming'
   where trip_id = v_trip and sequence = 2;

  perform set_config('bmt.trip_transition', v_trip::text, true);
  update public.operation_trips
     set status = 'boarding', actual_start_time = null
   where id = v_trip;
  perform set_config('bmt.trip_transition', '', true);
end $$;

-- ── 7. The gate satisfied: the trip advances, exactly once ──────────────────────────
reset role;
do $$
declare v_trip uuid := (select trip_id from fx);
begin
  if v_trip is null then return; end if;
  update public.trip_station_progress
     set actual_arrival_at     = now() - interval '20 minutes',
         min_dwell_seconds     = 300,
         expected_departure_at = now() - interval '10 minutes'
   where trip_id = v_trip and sequence = 1;
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"dcad0f26-7815-4646-b69d-b94b123ab4ef","role":"authenticated"}';

do $$
declare v_trip uuid := (select trip_id from fx); v_res jsonb; v_n int;
begin
  if v_trip is null then return; end if;

  v_res := public.captain_depart_station(v_trip);
  insert into probe values ('07. depart with the boarding gate satisfied',
    case when v_res->>'success' = 'true' and (v_res->>'sequence')::int = 1
         then 'OK' else 'BROKEN — ' || v_res::text end);

  insert into probe values ('07b. station 1 departed, station 2 arriving',
    (select case when (select status from public.trip_station_progress
                        where trip_id = v_trip and sequence = 1) = 'departed'
                  and (select status from public.trip_station_progress
                        where trip_id = v_trip and sequence = 2) = 'arriving'
                 then 'OK' else 'BROKEN' end));

  insert into probe values ('07c. leaving the first station departs the trip',
    (select case when status = 'in_progress' then 'OK'
                 else 'BROKEN — ' || status end
       from public.operation_trips where id = v_trip));

  -- The duplicate-progression guard: a retry must refuse, never advance station 2.
  begin
    perform public.captain_depart_station(v_trip);
    insert into probe values ('07d. duplicate departure request', 'STILL POSSIBLE — skipped a station');
  exception when others then
    insert into probe values ('07d. duplicate departure request',
      case when sqlerrm like 'no_current_station%' then 'blocked' else 'BROKEN — ' || sqlerrm end);
  end;

  select count(*) into v_n from public.trip_station_progress
   where trip_id = v_trip and actual_departure_at is not null;
  insert into probe values ('07e. exactly one station departed',
    case when v_n = 1 then 'OK' else 'STILL POSSIBLE — ' || v_n || ' departed' end);
end $$;

-- ── 8. Per-rider tracking visibility ────────────────────────────────────────────────
set local request.jwt.claims = '{"sub":"625ea9b6-620c-4eae-a8df-eace918e8872","role":"authenticated"}';
do $$
declare v_trip uuid := (select trip_id from fx);
begin
  if v_trip is null then return; end if;
  insert into probe values ('08. boarded rider loses the live position',
    case when public.can_read_trip_fixes(v_trip) then 'STILL POSSIBLE' else 'blocked' end);
  insert into probe values ('08b. boarded rider keeps the station board',
    case when public.can_read_trip_stations(v_trip) then 'OK' else 'BROKEN' end);
end $$;

set local request.jwt.claims = '{"sub":"674b3ec4-54ef-4ed7-b9ec-f234d9d0b736","role":"authenticated"}';
do $$
declare v_trip uuid := (select trip_id from fx);
begin
  if v_trip is null then return; end if;
  insert into probe values ('08c. waiting rider on the same trip still sees it',
    case when public.can_read_trip_fixes(v_trip) then 'OK' else 'BROKEN — tracking died for everyone' end);
end $$;

-- ── 9. Nobody writes the board directly ─────────────────────────────────────────────
do $$
declare v_trip uuid := (select trip_id from fx);
begin
  if v_trip is null then return; end if;
  begin
    update public.trip_station_progress set actual_departure_at = now()
     where trip_id = v_trip and sequence = 2;
    insert into probe values ('09. rider writes the board',
      case when found then 'STILL POSSIBLE' else 'blocked — no rows' end);
  exception when others then
    insert into probe values ('09. rider writes the board', 'blocked — ' || sqlerrm);
  end;
end $$;

set local request.jwt.claims = '{"sub":"dcad0f26-7815-4646-b69d-b94b123ab4ef","role":"authenticated"}';
do $$
declare v_trip uuid := (select trip_id from fx);
begin
  if v_trip is null then return; end if;
  begin
    update public.trip_station_progress set actual_departure_at = now()
     where trip_id = v_trip and sequence = 2;
    insert into probe values ('09b. captain writes the board',
      case when found then 'STILL POSSIBLE' else 'blocked — no rows' end);
  exception when others then
    insert into probe values ('09b. captain writes the board', 'blocked — ' || sqlerrm);
  end;
end $$;

-- ── 10. Cross-captain isolation ─────────────────────────────────────────────────────
-- Resolved as postgres: `drivers` is office-scoped, so a captain cannot look another
-- captain up to name them here.
reset role;
create temp table other_captain(user_id uuid) on commit drop;
grant all on other_captain to authenticated;
insert into other_captain
select d.user_id from public.drivers d
 where d.user_id is not null
   and d.user_id <> (select captain_user from fx)
 limit 1;

set local role authenticated;

do $$
declare v_other uuid; v_trip uuid;
begin
  select user_id into v_other from other_captain;
  if v_other is null then
    insert into probe values ('10. cross-captain isolation', 'SKIPPED — only one captain');
    return;
  end if;
  v_trip := (select trip_id from fx);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_other, 'role', 'authenticated')::text, true);
  begin
    perform public.captain_depart_station(v_trip);
    insert into probe values ('10. another captain departs this trip', 'STILL POSSIBLE');
  exception when others then
    insert into probe values ('10. another captain departs this trip',
      case when sqlerrm like 'not_your_trip%' then 'blocked' else 'BROKEN — ' || sqlerrm end);
  end;
end $$;

reset role;
select step, result from probe order by step;

rollback;
