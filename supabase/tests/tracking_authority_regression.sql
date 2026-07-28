-- ═══════════════════════════════════════════════════════════════════════════════════
-- Tracking authority regression suite  (Phase 6)
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Impersonates every party that can point at `trip_live_locations` — an anonymous
-- visitor holding the shipped anon key, a passenger who paid, a passenger who did
-- not, the assigned captain, the operating office, and a *different* office — and
-- asserts in one pass that each of them sees exactly what they are entitled to and
-- nothing more.
--
-- Runs entirely inside BEGIN … ROLLBACK. It inserts one position fix and throws it
-- away; nothing survives the run, so it is safe against the production-bound
-- development database.
--
--   supabase db query --linked -f supabase/tests/tracking_authority_regression.sql
--
-- Every row of the output should read OK. Any row reading "STILL EXPLOITABLE",
-- "LEAK" or "BROKEN" is a regression.
--
-- Covers: 20260728120000 (write authorship), 20260729090000 (tracking authority),
--         20260729093000 (TRUNCATE hygiene).
--
-- ── Fixtures ────────────────────────────────────────────────────────────────────
-- The identities below are read out of the linked database rather than hardcoded,
-- so the suite keeps working as data changes. It needs at least one trip carrying
-- live fixes; if there is none it aborts loudly rather than passing vacuously.
-- ═══════════════════════════════════════════════════════════════════════════════════

begin;

create temp table probe(step text, result text) on commit drop;
create temp table fixture(k text primary key, v uuid) on commit drop;
grant all on probe to authenticated, anon;
grant all on fixture to authenticated, anon;

-- ───────────────────────────────────────────────────────────────────────────────────
-- Resolve the cast, as a superuser, before any impersonation starts.
-- ───────────────────────────────────────────────────────────────────────────────────
do $$
declare v_trip uuid; v_office uuid;
begin
  select l.trip_id into v_trip
    from public.trip_live_locations l
    join public.operation_trips t on t.id = l.trip_id
   where t.driver_id is not null and t.office_id is not null
   group by l.trip_id order by count(*) desc limit 1;

  if v_trip is null then
    insert into probe values ('00. fixture', 'ABORTED — no trip has live fixes');
    return;
  end if;

  select office_id into v_office from public.operation_trips where id = v_trip;

  insert into fixture values ('trip', v_trip), ('office', v_office);

  -- The trip's driver and vehicle are resolved here, as superuser, and read back out
  -- of `fixture` by the impersonated probes below. They must not be re-read from
  -- `operation_trips` inside a probe: an outsider holds no read policy on that table,
  -- so `insert … select … from operation_trips` would select zero rows and insert
  -- nothing — which looks identical to "the insert was accepted" and quietly turns a
  -- forgery test into a false positive.
  insert into fixture
  select 'driver', t.driver_id from public.operation_trips t where t.id = v_trip;
  insert into fixture
  select 'vehicle', t.vehicle_id from public.operation_trips t where t.id = v_trip;

  -- The captain who drives it.
  insert into fixture
  select 'captain_user', d.user_id from public.drivers d
   join public.operation_trips t on t.driver_id = d.id
   where t.id = v_trip and d.user_id is not null and d.status = 'active';

  -- A passenger holding a paid booking on it.
  insert into fixture
  select 'paid_client', b.client_id from public.operation_bookings b
   where b.trip_id = v_trip and b.client_id is not null
     and b.status in ('confirmed','boarded','completed') limit 1;

  -- Somebody with an account but no paid booking on this trip. Any signed-up user
  -- will do — this is the "crafted API call from a stranger" case.
  insert into fixture
  select 'outsider', b.client_id from public.operation_bookings b
   where b.client_id is not null
     and not exists (select 1 from public.operation_bookings x
                      where x.trip_id = v_trip and x.client_id = b.client_id
                        and x.status in ('confirmed','boarded','completed'))
   limit 1;

  -- An operator in the office that runs the trip, and one in any other office.
  insert into fixture
  select 'office_user', u.user_id from public.office_users u
   where u.office_id = v_office and u.status = 'active' limit 1;
  insert into fixture
  select 'other_office_user', u.user_id from public.office_users u
   where u.office_id <> v_office and u.status = 'active' limit 1;

  -- A trip in some other office, used to prove cross-office read isolation.
  insert into fixture
  select 'foreign_trip', t.id from public.operation_trips t
   where t.office_id is not null and t.office_id <> v_office limit 1;
end $$;

-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. The anonymous visitor — the app's shipped key, no account at all.
-- ═══════════════════════════════════════════════════════════════════════════════════
set local role anon;

do $$
declare v_n int;
begin
  begin
    select count(*) into v_n from public.trip_live_locations;
    insert into probe values ('01. anon reads live positions',
      case when v_n = 0 then 'OK — blocked (0 rows)'
           else 'STILL EXPLOITABLE — ' || v_n || ' fixes readable with the shipped key' end);
  exception when insufficient_privilege then
    insert into probe values ('01. anon reads live positions', 'OK — blocked (no grant)');
  end;

  begin
    perform 1 from public.trip_progress_events;
    insert into probe values ('02. anon reads progress events', 'LEAK — readable');
  exception when insufficient_privilege then
    insert into probe values ('02. anon reads progress events', 'OK — blocked (no grant)');
  end;

  begin
    insert into public.trip_live_locations (trip_id, driver_id, vehicle_id, latitude, longitude)
    values ((select v from fixture where k = 'trip'),
            (select v from fixture where k = 'driver'),
            (select v from fixture where k = 'vehicle'), 30.0, 31.0);
    get diagnostics v_n = row_count;
    insert into probe values ('03. anon forges a position',
      case when v_n > 0 then 'STILL EXPLOITABLE — ' || v_n || ' forged fix stored'
           else 'OK — blocked' end);
  exception when others then
    insert into probe values ('03. anon forges a position', 'OK — blocked');
  end;

  begin
    delete from public.trip_live_locations;
    insert into probe values ('04. anon erases the fleet''s positions', 'STILL EXPLOITABLE');
  exception when others then
    insert into probe values ('04. anon erases the fleet''s positions', 'OK — blocked');
  end;
end $$;

reset role;

-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. The passenger who paid — must be able to watch their own vehicle.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare v_n int; v_trip uuid; v_foreign uuid;
begin
  if not exists (select 1 from fixture where k = 'paid_client') then
    insert into probe values ('05. paid passenger', 'SKIPPED — no paid booking in fixture'); return;
  end if;
  select v into v_trip from fixture where k = 'trip';
  select v into v_foreign from fixture where k = 'foreign_trip';

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'paid_client'),
                      'role', 'authenticated')::text, true);

  select count(*) into v_n from public.trip_live_locations where trip_id = v_trip;
  insert into probe values ('05. paid passenger watches their own trip',
    case when v_n > 0 then 'OK — ' || v_n || ' fixes visible'
         else 'BROKEN — the map they paid for is dark' end);

  select count(*) into v_n from public.trip_live_locations where trip_id is distinct from v_trip;
  insert into probe values ('06. paid passenger reads other trips',
    case when v_n = 0 then 'OK — blocked' else 'LEAK — ' || v_n || ' foreign fixes visible' end);

  perform set_config('role', 'postgres', true);
end $$;

reset role;

-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. The signed-in stranger — an account, but no paid booking on this trip.
--    This is the attack the open table allowed: trip ids are published to the whole
--    marketplace by `public_trips`, so there is nothing to guess.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare v_n int; v_trip uuid;
begin
  if not exists (select 1 from fixture where k = 'outsider') then
    insert into probe values ('07. stranger', 'SKIPPED — no outsider in fixture'); return;
  end if;
  select v into v_trip from fixture where k = 'trip';

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'outsider'),
                      'role', 'authenticated')::text, true);

  select count(*) into v_n from public.trip_live_locations where trip_id = v_trip;
  insert into probe values ('07. stranger tracks a marketplace trip id',
    case when v_n = 0 then 'OK — blocked'
         else 'STILL EXPLOITABLE — ' || v_n || ' fixes readable without a booking' end);

  begin
    insert into public.trip_live_locations (trip_id, driver_id, vehicle_id, latitude, longitude)
    values (v_trip,
            (select v from fixture where k = 'driver'),
            (select v from fixture where k = 'vehicle'), 0.0, 0.0);
    get diagnostics v_n = row_count;
    insert into probe values ('08. stranger forges a position',
      case when v_n > 0 then 'STILL EXPLOITABLE — ' || v_n || ' forged fix stored'
           else 'OK — blocked' end);
  exception when others then
    insert into probe values ('08. stranger forges a position', 'OK — blocked');
  end;

  perform set_config('role', 'postgres', true);
end $$;

reset role;

-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. The assigned captain — must be able to publish, and only to their own trip.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare v_n int; v_trip uuid; v_foreign uuid; v_stamped uuid; v_id uuid;
begin
  if not exists (select 1 from fixture where k = 'captain_user') then
    insert into probe values ('09. captain', 'SKIPPED — trip has no active captain'); return;
  end if;
  select v into v_trip from fixture where k = 'trip';
  select v into v_foreign from fixture where k = 'foreign_trip';

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'captain_user'),
                      'role', 'authenticated')::text, true);

  begin
    insert into public.trip_live_locations (trip_id, driver_id, vehicle_id, latitude, longitude, accuracy)
    values (v_trip,
            (select v from fixture where k = 'driver'),
            (select v from fixture where k = 'vehicle'), 30.0444, 31.2357, 8.0)
    returning id, driver_id into v_id, v_stamped;
    insert into probe values ('09. captain publishes to their own trip',
      case when v_id is not null then 'OK' else 'BROKEN — nothing stored' end);
  exception when others then
    insert into probe values ('09. captain publishes to their own trip', 'BROKEN: ' || sqlerrm);
  end;

  -- The trigger must overwrite a forged driver_id with the server-resolved captain.
  begin
    insert into public.trip_live_locations (trip_id, driver_id, vehicle_id, latitude, longitude)
    values (v_trip, '00000000-0000-0000-0000-000000000001'::uuid,
            (select v from fixture where k = 'vehicle'), 30.1, 31.1)
    returning driver_id into v_stamped;
    insert into probe values ('10. forged driver_id is overwritten',
      case when v_stamped = public.current_driver_id() then 'OK — stamped server-side'
           else 'STILL EXPLOITABLE — payload driver_id kept' end);
  exception when others then
    insert into probe values ('10. forged driver_id is overwritten', 'OK — rejected outright');
  end;

  if v_foreign is null then
    insert into probe values ('11. captain publishes to another office''s trip',
      'SKIPPED — no trip outside this office');
  else
    begin
      insert into public.trip_live_locations (trip_id, driver_id, vehicle_id, latitude, longitude)
      values (v_foreign,
              (select v from fixture where k = 'driver'),
              (select v from fixture where k = 'vehicle'), 30.2, 31.2);
      get diagnostics v_n = row_count;
      insert into probe values ('11. captain publishes to another office''s trip',
        case when v_n > 0 then 'STILL EXPLOITABLE — ' || v_n || ' cross-office fix stored'
             else 'OK — blocked' end);
    exception when others then
      insert into probe values ('11. captain publishes to another office''s trip', 'OK — blocked');
    end;
  end if;

  -- A published position is a fact. Nothing on the client side rewrites or erases it.
  begin
    update public.trip_live_locations set latitude = 0 where trip_id = v_trip;
    insert into probe values ('12. captain rewrites a published position', 'LEAK — update accepted');
  exception when others then
    insert into probe values ('12. captain rewrites a published position', 'OK — blocked');
  end;

  begin
    delete from public.trip_live_locations where trip_id = v_trip;
    insert into probe values ('13. captain erases a published position', 'LEAK — delete accepted');
  exception when others then
    insert into probe values ('13. captain erases a published position', 'OK — blocked');
  end;

  perform set_config('role', 'postgres', true);
end $$;

reset role;

-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. Office isolation — the operating office sees its fleet, another office sees none.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare v_n int; v_trip uuid;
begin
  select v into v_trip from fixture where k = 'trip';

  if exists (select 1 from fixture where k = 'office_user') then
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims',
      json_build_object('sub', (select v from fixture where k = 'office_user'),
                        'role', 'authenticated')::text, true);
    select count(*) into v_n from public.trip_live_locations where trip_id = v_trip;
    insert into probe values ('14. operating office reads its own fleet',
      case when v_n > 0 then 'OK — ' || v_n || ' fixes visible'
           else 'BROKEN — the Live Ops board is dark' end);
    perform set_config('role', 'postgres', true);
  else
    insert into probe values ('14. operating office', 'SKIPPED — no active office user');
  end if;

  if exists (select 1 from fixture where k = 'other_office_user') then
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims',
      json_build_object('sub', (select v from fixture where k = 'other_office_user'),
                        'role', 'authenticated')::text, true);
    select count(*) into v_n from public.trip_live_locations where trip_id = v_trip;
    insert into probe values ('15. another office reads this fleet',
      case when v_n = 0 then 'OK — blocked'
           else 'LEAK — ' || v_n || ' cross-office fixes visible' end);
    perform set_config('role', 'postgres', true);
  else
    insert into probe values ('15. another office', 'SKIPPED — single-office database');
  end if;
end $$;

reset role;

-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Retention is service_role only — no client-side caller can trigger a purge.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
begin
  perform set_config('role', 'authenticated', true);
  begin
    perform public.prune_trip_live_locations(7);
    insert into probe values ('16. a signed-in user purges the feed', 'LEAK — execute allowed');
  exception when insufficient_privilege then
    insert into probe values ('16. a signed-in user purges the feed', 'OK — blocked');
  when others then
    insert into probe values ('16. a signed-in user purges the feed', 'OK — blocked (' || sqlerrm || ')');
  end;
  perform set_config('role', 'postgres', true);
end $$;

reset role;

-- ═══════════════════════════════════════════════════════════════════════════════════
-- 7. TRUNCATE — the privilege row-level security does not gate.
--    RLS covers SELECT/INSERT/UPDATE/DELETE only. A client role holding TRUNCATE
--    empties the table with every policy on it intact and irrelevant.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
begin
  perform set_config('role', 'authenticated', true);
  begin
    truncate public.driver_trip_reports;
    insert into probe values ('17. a signed-in user empties the incident queue',
      'STILL EXPLOITABLE — truncate accepted');
  exception when insufficient_privilege then
    insert into probe values ('17. a signed-in user empties the incident queue', 'OK — blocked');
  when others then
    insert into probe values ('17. a signed-in user empties the incident queue',
      'OK — blocked (' || sqlerrm || ')');
  end;
  perform set_config('role', 'postgres', true);
end $$;

reset role;

select step, result from probe order by step;

rollback;
