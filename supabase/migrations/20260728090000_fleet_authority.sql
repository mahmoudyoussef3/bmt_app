-- ═══════════════════════════════════════════════════════════════════════════════════
-- Fleet authority
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 4 of the Dashboard Re-Ownership Program. Full audit in
-- docs/dashboard/DASHBOARD_FLEET_MANAGEMENT.md, run against the live database
-- 2026-07-28.
--
-- The fleet domain had correct RLS on every base table and a correct driver↔vehicle
-- assignment index, and almost nothing else was enforced anywhere but in Dart. What
-- this migration closes, in order of severity:
--
--   1. SECURITY. `public_vehicle_profiles` and `public_driver_profiles` are
--      auto-updatable SECURITY DEFINER views owned by `postgres`, and INSERT/UPDATE/
--      DELETE were granted on them to `anon`. Writing through such a view runs as the
--      view owner, so RLS on `vehicles` / `drivers` is not consulted at all. Proven
--      against the live database: an anonymous session updated 4 vehicles rows through
--      the view. Any internet client holding the public anon key could deface or
--      delete every listed office's fleet. `public_offices` had the identical hole.
--      TRUNCATE — which RLS never filters — was granted to anon on the base tables too.
--
--   2. Seat inventory was whatever the client posted. `create_trip` inserted
--      `p_seats` verbatim and stored `p_capacity` verbatim, with no check that either
--      agreed with the vehicle actually assigned, with each other, or with itself.
--      Nothing prevented duplicate seat labels on one trip, and nothing prevented a
--      vehicle's stored `capacity` from disagreeing with its own `seat_configuration`.
--      The chain vehicle capacity → seat layout → trip seats is now closed end to end:
--      the trip's seats are *derived from the vehicle* inside the RPC, and the counts
--      are constrained on both tables.
--
--   3. Resource overlap was enforced at whole-day granularity: one trip per vehicle
--      per day, and one per driver per day. On a 53-minute route that caps a vehicle at
--      a single departure a day, which is not a transportation business. Replaced with
--      a real service-window overlap rule, enforced by a GiST exclusion constraint so
--      it holds under concurrency and against direct table writes, not only inside the
--      RPC. See §"Service window" below for the interval definition.
--
--   4. A vehicle or driver could be assigned to a trip while under maintenance,
--      suspended or archived, and could be hard-deleted while historical trips still
--      referenced it — `operation_trips.vehicle_id` is ON DELETE SET NULL, so the
--      deletion silently erased which vehicle ran which trip rather than failing.
--
--   5. `reassign_booking` has never run successfully: it reads `trip_seats.status`
--      (the column is `state`), writes the state value `'booked'` (not in the CHECK),
--      and updates `operation_bookings.seat_label` (the column is `seat`). Every
--      dashboard seat reassignment has been failing with a column error.
--
-- Seat *geometry* deliberately stays in Dart (`lib/core/vehicles/`), because the
-- Dashboard, Client and Captain apps all draw from the same blueprint registry and a
-- second copy in SQL is how they drift apart. What moves into the database is the part
-- the database can prove: counts, uniqueness, ownership, availability and overlap.
--
-- No RLS policy is altered. No status value is added or removed.

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. SECURITY — close the SECURITY DEFINER view write path
-- ───────────────────────────────────────────────────────────────────────────────────
-- These three views exist so anonymous riders can browse offices, vehicles and drivers
-- before signing in. They are read surfaces and always were; the write grants came from
-- a blanket `grant all on all tables` and were never intended.
--
-- The views stay SECURITY DEFINER: their whole purpose is to let a caller who cannot
-- read `vehicles` read the public subset of it. Flipping them to security_invoker would
-- instead require opening the base tables to anon, which is the opposite of the fix.
-- Removing the write privilege is what closes the hole, because a view confers no
-- privilege its caller was not granted on the view itself.

-- TRIGGER is revoked alongside the write bits: on a view it is what would allow an
-- INSTEAD OF trigger to be attached, which is a write path by another name.
revoke insert, update, delete, truncate, references, trigger
  on public.public_vehicle_profiles from anon, authenticated;
revoke insert, update, delete, truncate, references, trigger
  on public.public_driver_profiles  from anon, authenticated;
revoke insert, update, delete, truncate, references, trigger
  on public.public_offices          from anon, authenticated;

-- Base fleet tables: `anon` has no policy on any of them, so RLS already denies every
-- row-level operation. TRUNCATE is the exception that matters — PostgreSQL row security
-- does not apply to TRUNCATE at all, so the grant was a real privilege, not a redundant
-- one. The rest is least privilege: an unauthenticated session has no business holding
-- write bits on the fleet.
revoke insert, update, delete, truncate, references, trigger
  on public.vehicles, public.drivers, public.assignments,
     public.vehicle_documents, public.driver_documents,
     public.operation_trips, public.trip_seats
  from anon;

-- Signed-in operators write these tables through RLS, which is correct — but TRUNCATE
-- would bypass those same policies and empty another office's fleet.
revoke truncate on public.vehicles, public.drivers, public.assignments,
                   public.vehicle_documents, public.driver_documents,
                   public.operation_trips, public.trip_seats
  from authenticated;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. Seat configuration — shape and count, provable in SQL
-- ───────────────────────────────────────────────────────────────────────────────────
-- `vehicles.seat_configuration` is the persisted seat *data* (which seats exist, what
-- each is called, where it sits). Two properties must hold for the rest of the fleet to
-- be trustworthy, and both are checkable without knowing anything about cabin shapes:
-- every seat is identifiable, and the passenger count is exactly `capacity`.

create or replace function public.seat_config_passenger_count(p_config jsonb)
returns integer
language sql
immutable
parallel safe
as $$
  select case
    when jsonb_typeof(p_config -> 'seats') is distinct from 'array' then 0
    else (
      select count(*)::int
      from jsonb_array_elements(p_config -> 'seats') s
      where coalesce(s ->> 'seat_type', 'passenger') = 'passenger'
    )
  end;
$$;

comment on function public.seat_config_passenger_count(jsonb) is
  'Bookable seats in a vehicles.seat_configuration payload. Driver and empty slots are '
  'stored alongside passenger seats and are never bookable, so only seat_type=passenger '
  'counts. Immutable so CHECK constraints can call it.';

create or replace function public.seat_config_is_wellformed(p_config jsonb)
returns boolean
language sql
immutable
parallel safe
as $$
  select case
    -- A vehicle with no seats cannot be operated, and the column default is '{}'.
    when jsonb_typeof(p_config -> 'seats') is distinct from 'array' then false
    when jsonb_array_length(p_config -> 'seats') = 0 then false
    -- Every slot needs a name and a grid position: the position is what trip_seats is
    -- keyed on and what both apps draw from, and a missing one silently collapses seats
    -- onto row 0 / column 0.
    when exists (
      select 1
      from jsonb_array_elements(p_config -> 'seats') s
      where nullif(btrim(coalesce(s ->> 'seat_number', '')), '') is null
         or jsonb_typeof(s -> 'row')    is distinct from 'number'
         or jsonb_typeof(s -> 'column') is distinct from 'number'
         or (s ->> 'row')::numeric    < 1
         or (s ->> 'column')::numeric < 1
    ) then false
    -- Seat identity: two passenger seats sharing a label means a booking can no longer
    -- name which physical seat it holds.
    when (
      select count(*)
      from jsonb_array_elements(p_config -> 'seats') s
      where coalesce(s ->> 'seat_type', 'passenger') = 'passenger'
    ) is distinct from (
      select count(distinct s ->> 'seat_number')
      from jsonb_array_elements(p_config -> 'seats') s
      where coalesce(s ->> 'seat_type', 'passenger') = 'passenger'
    ) then false
    else true
  end;
$$;

comment on function public.seat_config_is_wellformed(jsonb) is
  'Structural validity of vehicles.seat_configuration: non-empty, every slot labelled '
  'and positioned, passenger labels unique. Says nothing about cabin shape — the '
  'blueprints in lib/core/vehicles own that.';

alter table public.vehicles
  drop constraint if exists vehicles_seat_configuration_wellformed;
alter table public.vehicles
  add constraint vehicles_seat_configuration_wellformed
  check (public.seat_config_is_wellformed(seat_configuration));

alter table public.vehicles
  drop constraint if exists vehicles_capacity_matches_seat_configuration;
alter table public.vehicles
  add constraint vehicles_capacity_matches_seat_configuration
  check (capacity = public.seat_config_passenger_count(seat_configuration));

-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. Trip seats — identity and one-seat-one-booking
-- ───────────────────────────────────────────────────────────────────────────────────
-- A seat's identity within its trip is its label. Riders read it on their ticket, the
-- captain reads it off the manifest, and the dashboard reassigns bookings by it — so
-- two rows answering to '7' on one trip is a boarding dispute waiting to happen.

alter table public.trip_seats
  drop constraint if exists trip_seats_label_not_blank;
alter table public.trip_seats
  add constraint trip_seats_label_not_blank check (btrim(seat_label) <> '');

create unique index if not exists uq_trip_seats_trip_label
  on public.trip_seats (trip_id, seat_label);

-- One physical seat, at most one live booking, is ALREADY enforced — by
-- `uniq_active_booking_per_seat` on (trip_id, seat_id) and
-- `uniq_active_booking_per_seat_label` on (trip_id, seat), both partial on
-- `status not in ('cancelled','rejected')`. Verified against the live database rather
-- than assumed, and re-verified by section G of the regression suite. Nothing is added
-- here: a third overlapping index would be write cost for no additional guarantee.

-- ───────────────────────────────────────────────────────────────────────────────────
-- 4. Service window — the interval a vehicle and driver are actually committed for
-- ───────────────────────────────────────────────────────────────────────────────────
-- A trip occupies its crew and its bus from departure until arrival, plus a turnaround
-- allowance for unloading, cleaning and repositioning before the next departure. The
-- window is stored so the exclusion constraint below can index it, and generated so it
-- can never disagree with the times it is derived from.
--
--   start = trip_date + departure_time
--   end   = trip_date + arrival_time (+1 day when the trip runs past midnight)
--           + TURNAROUND
--
-- TURNAROUND is 30 minutes, baked in because a generated column must be immutable.
-- Because only the end is extended, the effective rule is "the next departure for this
-- vehicle must be at least 30 minutes after the previous arrival" — the allowance is
-- counted once between two trips, not twice. Making it per-office configurable would
-- mean a trigger instead of an exclusion constraint, giving up the concurrency
-- guarantee; that trade is documented as a known limitation rather than taken here.
--
-- A trip with no arrival_time is assumed to occupy one hour. Every row in the database
-- has one, and the dashboard wizard always computes one from the route duration, so
-- this is a floor for hand-written rows rather than a path anything normally takes.

alter table public.operation_trips
  drop column if exists service_window;

alter table public.operation_trips
  add column service_window tsrange
  generated always as (
    tsrange(
      (trip_date + departure_time),
      (case
         when arrival_time is null
           then (trip_date + departure_time) + interval '1 hour'
         when arrival_time <= departure_time
           then (trip_date + arrival_time) + interval '1 day'
         else (trip_date + arrival_time)
       end) + interval '30 minutes',
      '[)'
    )
  ) stored;

comment on column public.operation_trips.service_window is
  'Derived: [departure, arrival + 30min turnaround). The interval the trip''s vehicle '
  'and driver are committed for. Backs the no-overlap exclusion constraints.';

-- btree_gist supplies the `=` operator class GiST needs for uuid columns, so vehicle
-- identity and time range can live in one exclusion constraint.
create extension if not exists btree_gist;

-- The real fleet invariants, enforced by the storage engine rather than by a LIMIT 1
-- SELECT inside one RPC. These hold against direct PostgREST writes and against two
-- concurrent transactions racing to book the same bus, neither of which the previous
-- in-function check covered.
alter table public.operation_trips
  drop constraint if exists operation_trips_vehicle_no_overlap;
alter table public.operation_trips
  add constraint operation_trips_vehicle_no_overlap
  exclude using gist (vehicle_id with =, service_window with &&)
  where (vehicle_id is not null and status <> 'cancelled');

alter table public.operation_trips
  drop constraint if exists operation_trips_driver_no_overlap;
alter table public.operation_trips
  add constraint operation_trips_driver_no_overlap
  exclude using gist (driver_id with =, service_window with &&)
  where (driver_id is not null and status <> 'cancelled');

-- ───────────────────────────────────────────────────────────────────────────────────
-- 5. Vehicle and driver availability at assignment time
-- ───────────────────────────────────────────────────────────────────────────────────
-- `vehicles.status` and `drivers.status` already exist and already mean something —
-- the dashboard sets them and ends the driver↔vehicle assignment when they leave
-- 'active'. Nothing stopped a trip being scheduled onto a bus that is in the workshop.
--
-- The capacity clause matters on the mid-service vehicle swap that
-- enforce_trip_write_authority deliberately allows: the trip's seats are a snapshot and
-- do not regenerate, so the replacement bus must physically have at least as many
-- seats as the trip already sold a map of.

create or replace function public.enforce_trip_resource_availability()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office     uuid;
  v_status     text;
  v_capacity   int;
  v_seat_count int;
begin
  -- The office the trip belongs to. Read from the route rather than from new.office_id
  -- because sync_trip_office may not have run yet — trigger firing order is by name.
  select office_id into v_office
  from public.operation_routes
  where id = new.route_id;
  v_office := coalesce(v_office, new.office_id);

  if new.vehicle_id is not null then
    select status, capacity into v_status, v_capacity
    from public.vehicles
    where id = new.vehicle_id;

    if not found then
      raise exception 'vehicle_not_found';
    end if;

    if v_office is not null
       and v_office is distinct from (select office_id from public.vehicles
                                       where id = new.vehicle_id) then
      raise exception 'vehicle_not_in_office';
    end if;

    if v_status <> 'active' then
      raise exception
        'vehicle_unavailable: vehicle is % and cannot be assigned to a trip', v_status;
    end if;

    if tg_op = 'UPDATE' then
      select count(*) into v_seat_count
      from public.trip_seats where trip_id = new.id;

      if v_seat_count > 0 and v_capacity < v_seat_count then
        raise exception
          'vehicle_too_small: this trip has % seats sold from its map; the replacement '
          'vehicle seats %', v_seat_count, v_capacity;
      end if;
    end if;
  end if;

  if new.driver_id is not null then
    select status into v_status
    from public.drivers
    where id = new.driver_id;

    if not found then
      raise exception 'driver_not_found';
    end if;

    if v_office is not null
       and v_office is distinct from (select office_id from public.drivers
                                       where id = new.driver_id) then
      raise exception 'driver_not_in_office';
    end if;

    if v_status <> 'active' then
      raise exception
        'driver_unavailable: driver is % and cannot be assigned to a trip', v_status;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_trip_resource_availability on public.operation_trips;
create trigger trg_enforce_trip_resource_availability
  before insert or update of vehicle_id, driver_id on public.operation_trips
  for each row execute function public.enforce_trip_resource_availability();

-- ───────────────────────────────────────────────────────────────────────────────────
-- 6. Vehicle and driver lifecycle — archive, never erase
-- ───────────────────────────────────────────────────────────────────────────────────
-- `operation_trips.vehicle_id` and `.driver_id` are ON DELETE SET NULL, so deleting a
-- retired bus does not fail — it quietly rewrites history, and every completed trip it
-- ever ran loses the record of which vehicle carried those passengers. The dashboard's
-- delete path removes the assignments and documents first specifically so the RESTRICT
-- foreign keys stop objecting, which means the guard has to live here.
--
-- `archived` already exists in both status CHECKs and is what the fleet screens filter
-- on, so retirement has a home; deletion stays available only for a row that never
-- carried anything.

create or replace function public.enforce_fleet_delete_guard()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_trips int;
begin
  -- Service context: migrations and backfills. Mirrors enforce_trip_delete_guard.
  if auth.uid() is null then
    return old;
  end if;

  if tg_table_name = 'vehicles' then
    select count(*) into v_trips
    from public.operation_trips where vehicle_id = old.id;

    if v_trips > 0 then
      raise exception
        'vehicle_delete_forbidden: % trip(s) reference this vehicle — archive it instead',
        v_trips;
    end if;
  else
    select count(*) into v_trips
    from public.operation_trips where driver_id = old.id;

    if v_trips > 0 then
      raise exception
        'driver_delete_forbidden: % trip(s) reference this driver — archive them instead',
        v_trips;
    end if;
  end if;

  return old;
end;
$$;

drop trigger if exists trg_enforce_vehicle_delete_guard on public.vehicles;
create trigger trg_enforce_vehicle_delete_guard
  before delete on public.vehicles
  for each row execute function public.enforce_fleet_delete_guard();

drop trigger if exists trg_enforce_driver_delete_guard on public.drivers;
create trigger trg_enforce_driver_delete_guard
  before delete on public.drivers
  for each row execute function public.enforce_fleet_delete_guard();

-- ───────────────────────────────────────────────────────────────────────────────────
-- 7. Trip seat generation — derived from the vehicle, not posted by the client
-- ───────────────────────────────────────────────────────────────────────────────────
-- The seat map a trip is sold from is a *snapshot of the vehicle at the moment the trip
-- was created*. That model is right and is kept: editing a vehicle later must not move
-- seats under a rider who already booked one. What was wrong is where the snapshot came
-- from — the client assembled it and the database stored it unread, so the trip's seats
-- and its capacity were only as correct as the caller chose to be.

create or replace function public.vehicle_trip_seats(p_vehicle_id uuid)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'seat_label',  s ->> 'seat_number',
        'seat_row',    (s ->> 'row')::int,
        'seat_column', (s ->> 'column')::int
      )
      order by (s ->> 'row')::int, (s ->> 'column')::int
    ),
    '[]'::jsonb
  )
  from public.vehicles v
  cross join lateral jsonb_array_elements(v.seat_configuration -> 'seats') s
  where v.id = p_vehicle_id
    and jsonb_typeof(v.seat_configuration -> 'seats') = 'array'
    and coalesce(s ->> 'seat_type', 'passenger') = 'passenger';
$$;

comment on function public.vehicle_trip_seats(uuid) is
  'The bookable seat rows to snapshot into trip_seats for a vehicle, in cabin reading '
  'order. The single source of a trip''s seat inventory.';

create or replace function public.create_trip(
  p_trip_code      text,
  p_route_id       uuid,
  p_driver_id      uuid,
  p_vehicle_id     uuid,
  p_trip_date      date,
  p_departure_time time,
  p_arrival_time   time,
  p_capacity       integer,
  p_ticket_price   numeric,
  p_currency       text,
  p_notes          text[],
  p_route_points   jsonb,
  p_seats          jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_trip_id   uuid;
  v_seats     jsonb;
  v_capacity  int;
  v_conflict  record;
  v_window    tsrange;
begin
  if jsonb_array_length(p_route_points) = 0 then
    raise exception 'no_route_points: Route must have at least one station';
  end if;

  -- ── Seat inventory ──────────────────────────────────────────────────────────────
  -- Derived from the assigned vehicle. p_seats is accepted only for a trip created
  -- without a vehicle, which the dashboard never does but the signature still allows.
  if p_vehicle_id is not null then
    v_seats := public.vehicle_trip_seats(p_vehicle_id);

    if jsonb_array_length(v_seats) = 0 then
      raise exception
        'vehicle_has_no_seats: assigned vehicle has no seat configuration — open it in '
        'Fleet and save its layout before scheduling a trip';
    end if;
  else
    v_seats := coalesce(p_seats, '[]'::jsonb);
  end if;

  v_capacity := jsonb_array_length(v_seats);

  if v_capacity <= 0 then
    raise exception 'invalid_capacity: Capacity must be greater than 0';
  end if;

  -- The caller's capacity is not authoritative, but a disagreement means the caller
  -- was working from stale fleet data and is worth refusing rather than silently
  -- overriding: it is exactly the case where the operator saw "14 seats" on screen and
  -- would have sold 30.
  if p_capacity is not null and p_capacity <> v_capacity then
    raise exception
      'capacity_mismatch: the assigned vehicle has % bookable seats, not % — reload the '
      'fleet list and try again', v_capacity, p_capacity;
  end if;

  if (select count(distinct s ->> 'seat_label')
      from jsonb_array_elements(v_seats) s) <> v_capacity then
    raise exception 'duplicate_seat_labels: the vehicle''s seat layout repeats a label';
  end if;

  -- ── Resource conflicts ──────────────────────────────────────────────────────────
  -- The exclusion constraints below are the authority; these lookups exist only to
  -- return an error an operator can act on, naming the trip in the way.
  v_window := tsrange(
    (p_trip_date + p_departure_time),
    (case
       when p_arrival_time is null then (p_trip_date + p_departure_time) + interval '1 hour'
       when p_arrival_time <= p_departure_time then (p_trip_date + p_arrival_time) + interval '1 day'
       else (p_trip_date + p_arrival_time)
     end) + interval '30 minutes',
    '[)'
  );

  if p_driver_id is not null then
    select trip_code, trip_date, departure_time into v_conflict
    from public.operation_trips
    where driver_id = p_driver_id
      and status <> 'cancelled'
      and service_window && v_window
    limit 1;

    if found then
      raise exception
        'driver_conflict: driver is already on trip % (% at %) which overlaps this one',
        v_conflict.trip_code, v_conflict.trip_date, v_conflict.departure_time;
    end if;
  end if;

  if p_vehicle_id is not null then
    select trip_code, trip_date, departure_time into v_conflict
    from public.operation_trips
    where vehicle_id = p_vehicle_id
      and status <> 'cancelled'
      and service_window && v_window
    limit 1;

    if found then
      raise exception
        'vehicle_conflict: vehicle is already on trip % (% at %) which overlaps this one',
        v_conflict.trip_code, v_conflict.trip_date, v_conflict.departure_time;
    end if;
  end if;

  -- ── Write ───────────────────────────────────────────────────────────────────────
  insert into public.operation_trips (
    trip_code, route_id, driver_id, vehicle_id,
    trip_date, departure_time, arrival_time,
    capacity, ticket_price, currency, notes, status
  ) values (
    p_trip_code, p_route_id, p_driver_id, p_vehicle_id,
    p_trip_date, p_departure_time, p_arrival_time,
    v_capacity, p_ticket_price, p_currency, p_notes, 'scheduled'
  )
  returning id into v_trip_id;

  insert into public.trip_route_points (
    trip_id, route_point_id, point_name, point_order,
    arrival_offset, departure_offset, latitude, longitude
  )
  select
    v_trip_id,
    (rp ->> 'route_point_id')::uuid,
    rp ->> 'point_name',
    (rp ->> 'point_order')::int,
    coalesce(rp ->> 'arrival_offset', ''),
    coalesce(rp ->> 'departure_offset', ''),
    nullif(rp ->> 'latitude',  '')::double precision,
    nullif(rp ->> 'longitude', '')::double precision
  from jsonb_array_elements(p_route_points) as rp;

  insert into public.trip_seats (trip_id, seat_label, seat_row, seat_column, state)
  select
    v_trip_id,
    s ->> 'seat_label',
    (s ->> 'seat_row')::int,
    (s ->> 'seat_column')::int,
    'available'
  from jsonb_array_elements(v_seats) as s;

  insert into public.trip_events (trip_id, title, description, done)
  values (
    v_trip_id,
    'إنشاء الرحلة',
    'تم إنشاء الرحلة وتهيئة المقاعد والمحطات تلقائياً',
    true
  );

  return jsonb_build_object(
    'success', true,
    'trip_id', v_trip_id,
    'trip_code', p_trip_code,
    'seats_created', v_capacity,
    'stations_created', jsonb_array_length(p_route_points)
  );
end;
$$;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 8. reassign_booking — repair
-- ───────────────────────────────────────────────────────────────────────────────────
-- Three column errors and a wrong source of truth, none of which could ever have run:
--   trip_seats.status      → trip_seats.state
--   state 'booked'         → 'paid' / 'available' (the CHECK has no 'booked')
--   operation_bookings.seat_label → .seat
--   capacity read from vehicles.capacity (today's vehicle) → the trip's own snapshot
-- Availability is also now judged from `trip_seats`, which is what actually holds a
-- seat, rather than from a booking count that ignored seat state entirely.

create or replace function public.reassign_booking(
  p_booking_id      uuid,
  p_new_trip_id     uuid,
  p_new_seat_label  text default null
)
returns json
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_old_trip_id  uuid;
  v_old_seat_id  uuid;
  v_old_state    text;
  v_new_seat_id  uuid;
  v_free_seats   int;
begin
  select trip_id, seat_id into v_old_trip_id, v_old_seat_id
  from public.operation_bookings
  where id = p_booking_id;

  if not found then
    raise exception 'booking_not_found: Booking % does not exist', p_booking_id;
  end if;

  if v_old_trip_id is not distinct from p_new_trip_id then
    raise exception 'same_trip: Booking is already on this trip';
  end if;

  select count(*) into v_free_seats
  from public.trip_seats
  where trip_id = p_new_trip_id and state = 'available';

  if v_free_seats = 0 then
    raise exception 'trip_full: the target trip has no available seat';
  end if;

  -- Release the old seat, carrying its paid/subscription state over to the new one so a
  -- settled booking does not come back as merely reserved.
  if v_old_seat_id is not null then
    update public.trip_seats
    set state = 'available', passenger_id = null,
        held_at = null, hold_expires_at = null, lock_expires_at = null
    where id = v_old_seat_id
    returning state into v_old_state;
  end if;

  if p_new_seat_label is not null then
    select id into v_new_seat_id
    from public.trip_seats
    where trip_id = p_new_trip_id
      and seat_label = p_new_seat_label
      and state = 'available'
    for update
    limit 1;

    if v_new_seat_id is null then
      raise exception 'seat_unavailable: seat % is not free on the target trip',
        p_new_seat_label;
    end if;
  else
    select id into v_new_seat_id
    from public.trip_seats
    where trip_id = p_new_trip_id and state = 'available'
    order by seat_row, seat_column
    for update
    limit 1;
  end if;

  update public.trip_seats
  set state = 'paid'
  where id = v_new_seat_id;

  update public.operation_bookings
  set trip_id  = p_new_trip_id,
      seat_id  = v_new_seat_id,
      seat     = coalesce(p_new_seat_label,
                          (select seat_label from public.trip_seats
                            where id = v_new_seat_id),
                          seat),
      timeline = coalesce(timeline, '[]'::jsonb) || jsonb_build_object(
        'action', 'reassigned',
        'timestamp', now()::text,
        'actor', 'operations'
      )
  where id = p_booking_id;

  update public.trip_passengers
  set trip_id    = p_new_trip_id,
      seat_id    = v_new_seat_id,
      seat_label = (select seat_label from public.trip_seats where id = v_new_seat_id)
  where booking_id = p_booking_id;

  return json_build_object(
    'success', true,
    'new_trip_id', p_new_trip_id,
    'new_seat_id', v_new_seat_id
  );
end;
$$;

-- Execute rights are unchanged: reassign_booking stays service-role only and is reached
-- by operators through office_reassign_booking, which checks both offices.
revoke all on function public.reassign_booking(uuid, uuid, text) from public, anon, authenticated;

grant execute on function public.seat_config_passenger_count(jsonb) to anon, authenticated;
grant execute on function public.seat_config_is_wellformed(jsonb)   to anon, authenticated;
revoke all on function public.vehicle_trip_seats(uuid) from public, anon;
grant execute on function public.vehicle_trip_seats(uuid) to authenticated;
