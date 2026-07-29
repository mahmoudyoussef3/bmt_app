-- ═══════════════════════════════════════════════════════════════════════════════════
-- Driver–vehicle authority
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 7 of the Dashboard Re-Ownership Program. Audited against the live database
-- 2026-07-29.
--
-- The business model this platform actually runs on is: an office owns its drivers and
-- its vehicles, and pairs them — one driver, one bus. `assignments` already records
-- that pairing and already holds "at most one active per driver / per vehicle" through
-- two partial unique indexes. Everything downstream then ignored it.
--
-- What was wrong, in order of severity:
--
--   1. TRIP SCHEDULING IGNORED THE ASSIGNMENT ENTIRELY. `office_create_trip` took a
--      driver id and a vehicle id as two independent arguments and checked only that
--      each belonged to the caller's office. Nothing checked that the vehicle was the
--      one that driver actually operates. Proven against production: 6 of the 10 trips
--      on file pair a driver with a bus that is not their assigned bus — e.g. a driver
--      whose active assignment is `kjmkm8787` scheduled onto `test 19` and `c smcs43`.
--      Those trips dispatch a driver to a vehicle another driver is assigned to.
--
--   2. The assignment table accepted combinations the fleet cannot honour: a driver
--      from office A paired with a vehicle from office B (RLS gates the *row's*
--      office_id, not the two entities it points at), a suspended driver holding an
--      active bus, an archived bus held by an active driver. The Dashboard ended
--      assignments when a driver was suspended; nothing made that true of the database.
--
--   3. Suspending a driver or sidelining a vehicle left the pairing intact for anyone
--      writing outside the Dashboard's Dart path.
--
-- What this migration makes true, and where:
--
--   • `public.driver_active_vehicle(uuid)` is the single resolver of "which bus does
--     this driver operate right now". Everything server-side reads the pairing through
--     it.
--   • `office_create_trip` no longer accepts a vehicle, a capacity or a seat array. It
--     takes the driver and derives the rest. The old 13-argument signature is dropped,
--     so a stale client fails loudly instead of silently scheduling a mismatch.
--   • `create_trip` — the inner function, callable only by service contexts — rejects a
--     driver/vehicle pair that contradicts the active assignment with
--     `driver_vehicle_mismatch`.
--   • The same rule is enforced on `operation_trips` by trigger, so it holds for direct
--     table writes and future RPCs, not only for today's call path.
--   • `assignments` gets an integrity trigger: same office for the row, the driver and
--     the vehicle; both active while the assignment is.
--   • Losing 'active' status ends the pairing, in the database.
--
-- HISTORY IS NOT REWRITTEN. The pairing rule is enforced on INSERT and on an UPDATE
-- that actually changes `driver_id` or `vehicle_id` — never on rows at rest. A trip
-- created in July keeps the vehicle it was created with after the driver is reassigned
-- in August, which is the whole point of snapshotting `vehicle_id` onto the trip. The 6
-- pre-existing mismatched trips above are left exactly as they are; they are a record
-- of what was dispatched, and correcting them would be inventing history.
--
-- No RLS policy is altered. No status value is added or removed. Seat geometry stays in
-- Dart (`lib/core/vehicles/`) as established by 20260728090000_fleet_authority.

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. The resolver
-- ───────────────────────────────────────────────────────────────────────────────────
-- SECURITY DEFINER because callers that legitimately need the pairing (the trip RPCs,
-- the trigger below) run in contexts where `assignments` RLS would filter it away — a
-- definer trigger reading an invoker-visible table is the bug pattern that made
-- Realtime and RLS disagree in Phase 6. It reads one column of one row by primary-key
-- adjacent index and exposes nothing an operator could not already read for their own
-- office: the caller must supply a driver id, and receives only a vehicle id back.

create or replace function public.driver_active_vehicle(p_driver_id uuid)
returns uuid
language sql
stable
security definer
set search_path to 'public'
as $$
  select vehicle_id
  from public.assignments
  where driver_id = p_driver_id
    and status = 'active'
  limit 1;
$$;

comment on function public.driver_active_vehicle(uuid) is
  'The vehicle a driver currently operates, from their one active assignment. The '
  'single source of the driver→vehicle resolution: trip creation derives the vehicle '
  'from this rather than accepting one from the client.';

revoke all on function public.driver_active_vehicle(uuid) from public, anon;
grant execute on function public.driver_active_vehicle(uuid) to authenticated;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. Assignment integrity
-- ───────────────────────────────────────────────────────────────────────────────────
-- The unique indexes from migration_14 answer "how many", never "which". These are the
-- "which" rules: the two entities being paired must be the same office's, and must both
-- be operational for as long as the pairing is active. An `ended` assignment is history
-- and is deliberately exempt — a driver who left is allowed to have a record of the bus
-- they used to drive.

create or replace function public.enforce_assignment_integrity()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_driver_office uuid;
  v_driver_status text;
  v_vehicle_office uuid;
  v_vehicle_status text;
begin
  select office_id, status into v_driver_office, v_driver_status
  from public.drivers where id = new.driver_id;

  if not found then
    raise exception 'driver_not_found';
  end if;

  select office_id, status into v_vehicle_office, v_vehicle_status
  from public.vehicles where id = new.vehicle_id;

  if not found then
    raise exception 'vehicle_not_found';
  end if;

  if v_driver_office is distinct from v_vehicle_office then
    raise exception
      'assignment_cross_office: driver and vehicle belong to different offices';
  end if;

  if new.office_id is distinct from v_driver_office then
    raise exception
      'assignment_cross_office: the assignment must belong to the same office as the '
      'driver and vehicle';
  end if;

  if new.status = 'active' then
    if v_driver_status <> 'active' then
      raise exception
        'assignment_driver_unavailable: driver is % and cannot hold a vehicle',
        v_driver_status;
    end if;

    if v_vehicle_status <> 'active' then
      raise exception
        'assignment_vehicle_unavailable: vehicle is % and cannot be assigned',
        v_vehicle_status;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_assignment_integrity on public.assignments;
create trigger trg_enforce_assignment_integrity
  before insert or update of driver_id, vehicle_id, office_id, status
  on public.assignments
  for each row execute function public.enforce_assignment_integrity();

-- Losing 'active' releases the bus. The Dashboard already did this in Dart on its way
-- past `updateDriverStatus` / `updateVehicleStatus`; here it becomes a property of the
-- data rather than of one client's code path, and it keeps §2's active-status rule
-- self-consistent instead of leaving rows that violate it in place.

create or replace function public.end_assignments_on_fleet_status_change()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.status = 'active' or old.status is not distinct from new.status then
    return new;
  end if;

  update public.assignments
     set status     = 'ended',
         ended_at   = now(),
         updated_at = now()
   where status = 'active'
     and ((tg_table_name = 'drivers'  and driver_id  = new.id)
       or (tg_table_name = 'vehicles' and vehicle_id = new.id));

  return new;
end;
$$;

drop trigger if exists trg_end_assignments_on_driver_status on public.drivers;
create trigger trg_end_assignments_on_driver_status
  after update of status on public.drivers
  for each row execute function public.end_assignments_on_fleet_status_change();

drop trigger if exists trg_end_assignments_on_vehicle_status on public.vehicles;
create trigger trg_end_assignments_on_vehicle_status
  after update of status on public.vehicles
  for each row execute function public.end_assignments_on_fleet_status_change();

-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. The trip pairing rule, on the table
-- ───────────────────────────────────────────────────────────────────────────────────
-- Extends `enforce_trip_resource_availability` (20260728090000) rather than adding a
-- second trigger, so the whole resource gate stays in one place and fires in one order.
-- Everything the earlier version checked is retained verbatim; the pairing block at the
-- end is what is new.
--
-- Scope, deliberately narrow: INSERT always, UPDATE only when driver_id or vehicle_id
-- actually change. `UPDATE OF col` fires when a column appears in the SET list even if
-- the value is identical, and the Dashboard's trip-info save writes driver_id and
-- vehicle_id on every save — without the is-distinct-from test, editing the departure
-- time of a trip whose driver has since been reassigned would fail.

create or replace function public.enforce_trip_resource_availability()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office        uuid;
  v_status        text;
  v_capacity      int;
  v_seat_count    int;
  v_pair_changed  boolean;
  v_assigned      uuid;
  v_plate         text;
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

  -- ── The pairing ────────────────────────────────────────────────────────────────
  v_pair_changed := tg_op = 'INSERT'
    or new.driver_id  is distinct from old.driver_id
    or new.vehicle_id is distinct from old.vehicle_id;

  if v_pair_changed and new.driver_id is not null then
    v_assigned := public.driver_active_vehicle(new.driver_id);

    if v_assigned is null then
      raise exception
        'driver_has_no_vehicle: this driver has no vehicle assigned — assign one in '
        'Fleet before scheduling them';
    end if;

    if new.vehicle_id is null or new.vehicle_id <> v_assigned then
      select plate_number into v_plate from public.vehicles where id = v_assigned;
      raise exception
        'driver_vehicle_mismatch: this driver operates % — a trip cannot put them on '
        'another vehicle', coalesce(v_plate, v_assigned::text);
    end if;
  end if;

  return new;
end;
$$;

-- Renamed, deliberately. Postgres fires BEFORE triggers in alphabetical order by
-- trigger name, and `trg_enforce_trip_resource_availability` sorted ahead of
-- `trg_enforce_trip_write_authority` — so a caller with no right to touch the trip at
-- all was told about the fleet's assignment state before being told they were not
-- allowed to write. The write was still refused either way, but authorisation belongs
-- first: `trg_trip_resource_authority` sorts after `trg_enforce_…`, which puts the
-- authority gate back in front of every fleet check on this table.
drop trigger if exists trg_enforce_trip_resource_availability on public.operation_trips;
drop trigger if exists trg_trip_resource_authority on public.operation_trips;
create trigger trg_trip_resource_authority
  before insert or update of vehicle_id, driver_id on public.operation_trips
  for each row execute function public.enforce_trip_resource_availability();

comment on function public.enforce_trip_resource_availability() is
  'Ownership, availability and driver↔vehicle pairing for a trip''s resources. The '
  'pairing is judged only when the trip''s driver or vehicle changes, so reassigning a '
  'driver never invalidates the trips they already ran.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 4. create_trip — reject a contradicting pair by name
-- ───────────────────────────────────────────────────────────────────────────────────
-- The trigger above is the authority and would catch this at INSERT. This exists so an
-- internal or admin caller that passes a vehicle explicitly gets `driver_vehicle_
-- mismatch` *before* the seat map is built from the wrong bus, and so the error names
-- the vehicle the driver actually operates.
--
-- Everything else in this function is unchanged from 20260728090000: seats and capacity
-- still derive from the vehicle, the caller's capacity is still refused when it
-- disagrees, conflicts are still reported against the service window.

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
  v_assigned  uuid;
  v_vehicle   uuid;
begin
  if jsonb_array_length(p_route_points) = 0 then
    raise exception 'no_route_points: Route must have at least one station';
  end if;

  -- ── Driver → vehicle ────────────────────────────────────────────────────────────
  -- The assignment decides. A caller may pass the vehicle it believes is right, and
  -- gets told when it is not; a caller that passes nothing gets the right one anyway.
  v_vehicle := p_vehicle_id;

  if p_driver_id is not null then
    v_assigned := public.driver_active_vehicle(p_driver_id);

    if v_assigned is null then
      raise exception
        'driver_has_no_vehicle: this driver has no vehicle assigned — assign one in '
        'Fleet before scheduling them';
    end if;

    if p_vehicle_id is not null and p_vehicle_id <> v_assigned then
      raise exception
        'driver_vehicle_mismatch: the driver''s active assignment is vehicle %, not %',
        v_assigned, p_vehicle_id;
    end if;

    v_vehicle := v_assigned;
  end if;

  -- ── Seat inventory ──────────────────────────────────────────────────────────────
  -- Derived from the resolved vehicle. p_seats is accepted only for a trip created
  -- without a driver and without a vehicle, which the dashboard never does but the
  -- signature still allows.
  if v_vehicle is not null then
    v_seats := public.vehicle_trip_seats(v_vehicle);

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

  if v_vehicle is not null then
    select trip_code, trip_date, departure_time into v_conflict
    from public.operation_trips
    where vehicle_id = v_vehicle
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
    p_trip_code, p_route_id, p_driver_id, v_vehicle,
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
    'vehicle_id', v_vehicle,
    'seats_created', v_capacity,
    'stations_created', jsonb_array_length(p_route_points)
  );
end;
$$;

comment on function public.create_trip(text, uuid, uuid, uuid, date, time, time, int,
                                       numeric, text, text[], jsonb, jsonb) is
  'Creates a trip with its stations and seat map in one transaction. The vehicle is '
  'resolved from the driver''s active assignment; a p_vehicle_id that contradicts it is '
  'refused with driver_vehicle_mismatch. Not callable by API roles — go through '
  'office_create_trip.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 5. office_create_trip — the operator's door, driver-first
-- ───────────────────────────────────────────────────────────────────────────────────
-- The old signature is dropped rather than kept alongside. Keeping it would leave a
-- granted, SECURITY DEFINER path that still accepts a client-chosen vehicle, and a
-- stale build silently scheduling mismatches is worse than one that fails on the first
-- attempt with a clear "function does not exist".

drop function if exists public.office_create_trip(
  uuid, uuid, uuid, date, time, time, int, numeric, text, text[], jsonb, jsonb, text);

create or replace function public.office_create_trip(
  p_route_id       uuid,
  p_driver_id      uuid,
  p_trip_date      date,
  p_departure_time time,
  p_arrival_time   time,
  p_ticket_price   numeric,
  p_currency       text,
  p_notes          text[],
  p_route_points   jsonb,
  p_trip_code      text default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_office  uuid := public.current_office_id();
  v_code    text;
  v_vehicle uuid;
  v_status  text;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;

  -- Every referenced entity must be ours. Without this an operator could schedule a
  -- trip onto another office's route or driver.
  if not exists (select 1 from public.operation_routes
                  where id = p_route_id and office_id = v_office) then
    raise exception 'route_not_in_office';
  end if;

  if p_driver_id is null then
    raise exception 'driver_required: a trip must be scheduled onto a driver';
  end if;

  select status into v_status
  from public.drivers
  where id = p_driver_id and office_id = v_office;

  if not found then
    raise exception 'driver_not_in_office';
  end if;

  if v_status <> 'active' then
    raise exception
      'driver_unavailable: driver is % and cannot be assigned to a trip', v_status;
  end if;

  -- The vehicle is never taken from the caller. It is whatever this driver is paired
  -- with at the moment the trip is created — and that pairing is then snapshotted onto
  -- the trip, so a later reassignment leaves this trip alone.
  v_vehicle := public.driver_active_vehicle(p_driver_id);

  if v_vehicle is null then
    raise exception
      'driver_has_no_vehicle: this driver has no vehicle assigned — assign one in '
      'Fleet before scheduling them';
  end if;

  -- The assignment trigger keeps driver, vehicle and assignment in one office, so this
  -- cannot currently fail. It is kept because it is the check that would catch it if a
  -- future path ever writes an assignment around that trigger.
  select status into v_status
  from public.vehicles
  where id = v_vehicle and office_id = v_office;

  if not found then
    raise exception 'vehicle_not_in_office';
  end if;

  if v_status <> 'active' then
    raise exception
      'vehicle_unavailable: vehicle is % and cannot be assigned to a trip', v_status;
  end if;

  v_code := coalesce(nullif(trim(coalesce(p_trip_code, '')), ''),
                     public.next_office_trip_code(v_office));

  return public.create_trip(
    v_code, p_route_id, p_driver_id, v_vehicle, p_trip_date, p_departure_time,
    p_arrival_time, null, p_ticket_price, p_currency, p_notes,
    p_route_points, null
  );
end;
$$;

comment on function public.office_create_trip(uuid, uuid, date, time, time, numeric,
                                              text, text[], jsonb, text) is
  'Office-scoped trip creation. The operator picks a driver; the vehicle, its capacity '
  'and the trip''s seat map are derived from the driver''s active assignment. There is '
  'deliberately no vehicle parameter — a driver and a vehicle chosen independently is '
  'how a bus gets dispatched to two places at once.';

revoke all on function public.office_create_trip(uuid, uuid, date, time, time, numeric,
                                                 text, text[], jsonb, text)
  from public, anon;
grant execute on function public.office_create_trip(uuid, uuid, date, time, time,
                                                    numeric, text, text[], jsonb, text)
  to authenticated;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 6. Index for the resolver
-- ───────────────────────────────────────────────────────────────────────────────────
-- `uniq_active_assignment_per_driver` is already a partial unique index on driver_id
-- where status = 'active', which is exactly the lookup `driver_active_vehicle` does —
-- so the resolver is a single index probe and no new index is needed. Recorded here so
-- the next reader does not add a redundant one.
