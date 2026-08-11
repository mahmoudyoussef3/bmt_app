-- ═══════════════════════════════════════════════════════════════════════════════════
-- Station-based trip progress, passenger boarding control, and per-rider tracking
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Until now a trip's progress through its stations existed only as a *count*: the
-- captain tapped "تم الوصول للمحطة", a narrative row landed in `trip_events`, and all
-- three apps inferred "we are at station N" by counting those rows
-- (`stationArrivalFloor`). That count is not a state machine. It cannot say when the
-- vehicle arrived, who is supposed to board here, whether they did, or whether the
-- captain is allowed to leave — so nothing stopped a captain tapping straight through
-- five stations in five seconds and stranding every rider waiting at them.
--
-- This migration makes the station the unit of trip progress, and makes leaving one a
-- transition the *database* decides:
--
--     canProceed = boarding requirement resolved AND earliest departure reached
--
-- Both halves are enforced here, in `captain_depart_station`. The Captain App renders
-- the same rule so the button is honestly disabled, but the app is a representation of
-- the rule, never the rule itself.
--
-- ── What is reused, deliberately ────────────────────────────────────────────────────
--
--   * `trip_route_points` stays the only station list. Its `arrival_offset` /
--     `departure_offset` are "HH:MM" durations from route start (written by
--     `RouteScheduleCalculator`), and the gap between them is the dwell the operator
--     configured for that stop. That gap is the minimum wait — nothing new is invented.
--   * `trip_passengers.status` stays the boarding vocabulary: `reserved` (expected) →
--     `confirmed` (physically aboard) → `no_show` / `cancelled` / `completed`. No
--     parallel status system is introduced.
--   * `operation_bookings.status` already carried an unused `boarded` value. That is
--     the rider-side boarding flag, and — see §7 — the switch that turns their live
--     vehicle tracking off.
--   * `trip_events` keeps receiving the arrival marker with the exact title the three
--     apps already count, so every existing progress surface keeps working unchanged.
--
-- ── What is new ─────────────────────────────────────────────────────────────────────
--
--   1. `trip_station_progress` — the per-station record, with denormalised boarding
--      counts so one realtime table answers every question both apps ask.
--   2. `ensure_trip_station_progress` — seeds it from the trip's stops, and backfills
--      trips that were already running when this shipped.
--   3. `captain_arrive_station` / `captain_depart_station` — the two captain
--      transitions, row-locked so a double-tap can never skip a station.
--   4. `passenger_confirm_boarding` — the rider confirms their own boarding, and only
--      their own, and only at the station the vehicle is actually standing at.
--   5. `captain_resolve_no_show` — the controlled alternative to a Skip button: a
--      reason, an author, a timestamp, and an audit event.
--   6. RLS: the board is readable by the four parties with a reason to see it and
--      writable by nobody outside these RPCs.
--   7. `can_read_trip_fixes` narrowed: a rider who has boarded stops seeing the
--      vehicle's live position. Riders still waiting keep seeing it. The captain keeps
--      publishing throughout.
-- ═══════════════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────────────
-- 0. Manifest columns: how a boarding or a no-show was resolved
-- ───────────────────────────────────────────────────────────────────────────────────
-- `trip_passengers.status` already says *what* happened. These say *when*, *by whom*
-- and *why* — which is the whole difference between a recorded no-show and a skipped
-- passenger.

alter table public.trip_passengers
  add column if not exists boarded_at       timestamptz,
  add column if not exists boarding_source  text,
  add column if not exists no_show_reason   text,
  add column if not exists resolution_note  text,
  add column if not exists resolved_by      uuid,
  add column if not exists resolved_at      timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'trip_passengers_boarding_source_check'
  ) then
    alter table public.trip_passengers
      add constraint trip_passengers_boarding_source_check
      check (boarding_source is null
             or boarding_source in ('passenger', 'captain', 'office'));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'trip_passengers_no_show_reason_check'
  ) then
    alter table public.trip_passengers
      add constraint trip_passengers_no_show_reason_check
      check (no_show_reason is null
             or no_show_reason in ('did_not_arrive', 'cancelled_by_passenger',
                                   'passenger_requested', 'other'));
  end if;
end $$;

comment on column public.trip_passengers.boarding_source is
  'Who recorded the boarding: the passenger themselves (Client app), the captain '
  '(manifest), or the office. Null for rows boarded before this was tracked.';
comment on column public.trip_passengers.no_show_reason is
  'Why a passenger did not travel. Required by captain_resolve_no_show — a passenger '
  'may only be cleared out of a station''s boarding requirement with a stated reason.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. trip_station_progress — the station lifecycle
-- ───────────────────────────────────────────────────────────────────────────────────
-- One row per stop of one trip, snapshotted from `trip_route_points` when the trip
-- starts boarding.
--
-- `status` holds only what is *persisted fact*:
--
--     upcoming ──▶ arriving ──▶ waiting_for_passengers ──▶ departed
--
-- `ready_to_depart` is deliberately NOT a stored value. It is a function of stored
-- facts and the current clock (`pending_count = 0 AND now() >= earliest departure`),
-- and a stored column cannot become true because a minute passed — it would need a
-- ticker writing to the database to stay honest. It is derived, identically, by
-- `captain_depart_station` below and by `StationGate` in
-- `lib/core/tracking/progress/station_board.dart`.
--
-- The four counts are denormalised from `trip_passengers` by trigger. They could be
-- computed by joining, but a rider is only allowed to read *their own* manifest row —
-- so without these the Client app could never show "3 expected, 2 boarded", and the
-- Captain App would need a second realtime subscription to the manifest to keep a
-- number on screen fresh. One table, one subscription, one truth.

create table if not exists public.trip_station_progress (
  id                      uuid primary key default gen_random_uuid(),
  trip_id                 uuid not null references public.operation_trips(id)   on delete cascade,
  trip_route_point_id     uuid not null references public.trip_route_points(id) on delete cascade,

  -- `route_stations.id` — the namespace `trip_passengers.pickup_point_id` uses. Kept
  -- alongside the trip-scoped point id because that is what a manifest row joins on.
  route_point_id          uuid,
  point_name              text not null,
  sequence                int  not null check (sequence > 0),

  -- Planned schedule, resolved to real instants against the office's timezone.
  expected_arrival_at     timestamptz,
  expected_departure_at   timestamptz,

  -- The configured dwell (departure_offset − arrival_offset). This is the "minimum
  -- waiting" the operator set for the stop; a vehicle that arrives late still owes its
  -- passengers this long to board.
  min_dwell_seconds       int  not null default 0 check (min_dwell_seconds >= 0),

  actual_arrival_at       timestamptz,
  actual_departure_at     timestamptz,

  status                  text not null default 'upcoming'
    check (status in ('upcoming', 'arriving', 'waiting_for_passengers', 'departed')),

  -- Denormalised from trip_passengers by trg_trip_passengers_station_counts.
  expected_boardings      int  not null default 0 check (expected_boardings >= 0),
  boarded_count           int  not null default 0 check (boarded_count      >= 0),
  pending_count           int  not null default 0 check (pending_count      >= 0),
  no_show_count           int  not null default 0 check (no_show_count      >= 0),

  arrived_by              uuid,
  departed_by             uuid,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),

  constraint trip_station_progress_point_unique    unique (trip_id, trip_route_point_id),
  constraint trip_station_progress_sequence_unique unique (trip_id, sequence),

  -- A station cannot have departed before it arrived, and cannot be marked departed
  -- without a departure instant. The state column and the timestamps are two views of
  -- the same fact; this keeps them from drifting apart.
  constraint trip_station_progress_timeline check (
    (actual_departure_at is null or actual_arrival_at is not null)
    and (actual_departure_at is null or actual_departure_at >= actual_arrival_at)
    and (status <> 'departed' or actual_departure_at is not null)
    and (status <> 'waiting_for_passengers' or actual_arrival_at is not null)
  )
);

create index if not exists idx_trip_station_progress_trip
  on public.trip_station_progress (trip_id, sequence);

-- The "which station is the vehicle at right now" lookup, run by every RPC below.
create index if not exists idx_trip_station_progress_current
  on public.trip_station_progress (trip_id, sequence)
  where actual_departure_at is null;

comment on table public.trip_station_progress is
  'Per-station progress of one trip: planned and actual arrival/departure, lifecycle '
  'status, and the boarding tally at that stop. Written only by the captain_* and '
  'passenger_* RPCs in this migration — there is no write policy, so no app can move a '
  'trip between stations by writing a row.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. Seeding and backfill
-- ───────────────────────────────────────────────────────────────────────────────────

-- "HH:MM" (or "HH:MM:SS") duration from route start → interval. Anything else — an
-- empty string, a null, a station the operator never timed — is zero rather than an
-- error: a missing offset means "no planned time for this stop", and the gate below
-- degrades to the boarding requirement alone.
create or replace function public.parse_route_offset(p_offset text)
returns interval
language sql
immutable
as $$
  select case
    when p_offset ~ '^\s*\d{1,4}:[0-5]\d(:[0-5]\d)?\s*$' then btrim(p_offset)::interval
    else interval '0'
  end;
$$;

comment on function public.parse_route_offset(text) is
  'trip_route_points.arrival_offset / departure_offset are "HH:MM" durations measured '
  'from route start, not clock times. This is the one place that is parsed.';

-- Recompute every station''s boarding tally for a trip from the manifest.
--
-- Recomputed wholesale rather than adjusted incrementally: the arithmetic of "this
-- passenger moved from reserved to confirmed, so decrement one and increment another"
-- has to be right for every one of the status pairs and for pickup-point changes too,
-- and a single missed case leaves a station permanently un-departable. A manifest is
-- tens of rows; correctness is worth the scan.
create or replace function public.recount_trip_stations(p_trip_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  update public.trip_station_progress sp
     set expected_boardings = c.expected,
         boarded_count      = c.boarded,
         pending_count      = c.pending,
         no_show_count      = c.no_show,
         updated_at         = now()
    from (
      select s.id,
             count(p.id) filter (where p.status <> 'cancelled')               as expected,
             count(p.id) filter (where p.status in ('confirmed', 'completed')) as boarded,
             count(p.id) filter (where p.status = 'reserved')                 as pending,
             count(p.id) filter (where p.status = 'no_show')                  as no_show
        from public.trip_station_progress s
        left join public.trip_passengers p
               on p.trip_id = s.trip_id
              and (
                    (p.pickup_point_id is not null
                     and p.pickup_point_id = s.route_point_id)
                 or (p.pickup_point_id is null
                     and btrim(coalesce(p.pickup_point_name, '')) = btrim(s.point_name))
              )
       where s.trip_id = p_trip_id
       group by s.id
    ) c
   where sp.id = c.id
     and (sp.expected_boardings, sp.boarded_count, sp.pending_count, sp.no_show_count)
         is distinct from (c.expected, c.boarded, c.pending, c.no_show);
end;
$$;

comment on function public.recount_trip_stations(uuid) is
  'Refreshes the denormalised boarding tallies on trip_station_progress from the '
  'manifest. SECURITY DEFINER because it runs from a trigger on trip_passengers, where '
  'the writer (a captain, a rider via RPC) holds no write policy on the board.';

create or replace function public.sync_trip_station_counts()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  perform public.recount_trip_stations(coalesce(new.trip_id, old.trip_id));
  -- A pickup point moved between stations touches two trips only if the trip itself
  -- changed, which the manifest never does; but guard it anyway rather than silently
  -- leaving a stale tally behind.
  if tg_op = 'UPDATE' and new.trip_id is distinct from old.trip_id then
    perform public.recount_trip_stations(old.trip_id);
  end if;
  return null;
end;
$$;

drop trigger if exists trg_trip_passengers_station_counts on public.trip_passengers;
create trigger trg_trip_passengers_station_counts
  after insert or update or delete on public.trip_passengers
  for each row execute function public.sync_trip_station_counts();

-- Build (or complete) the station board for a trip.
--
-- Idempotent and safe to call from every read path: a trip that was already boarding
-- when this migration shipped gets its board built on the first request, with the
-- stations the captain already reported reconstructed from the arrival events they
-- filed. Without that backfill an in-flight trip would restart at station one and every
-- rider already aboard would be asked to board again.
create or replace function public.ensure_trip_station_progress(p_trip_id uuid)
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_trip     record;
  v_tz       text;
  v_base     timestamptz;
  v_inserted int := 0;
  v_seeded   boolean;
begin
  select t.id, t.office_id, t.trip_date, t.departure_time, t.status
    into v_trip
    from public.operation_trips t
   where t.id = p_trip_id;

  if not found then
    return 0;
  end if;

  -- A board only means something for a trip that is running or about to. Building one
  -- for a cancelled or long-completed trip would be inventing operational history.
  if v_trip.status not in ('boarding', 'in_progress') then
    return 0;
  end if;

  -- The same office-timezone convention the wallet and licensing periods use
  -- (`office_wallet_policies.timezone`, default Africa/Cairo). `trip_date` and
  -- `departure_time` are wall-clock in the office's zone; this is the one place in this
  -- feature they are turned into instants.
  select coalesce(
           (select w.timezone from public.office_wallet_policies w
             where w.office_id = v_trip.office_id),
           'Africa/Cairo')
    into v_tz;

  v_base := (v_trip.trip_date + v_trip.departure_time) at time zone v_tz;

  insert into public.trip_station_progress (
    trip_id, trip_route_point_id, route_point_id, point_name, sequence,
    expected_arrival_at, expected_departure_at, min_dwell_seconds, status
  )
  select
    rp.trip_id,
    rp.id,
    rp.route_point_id,
    coalesce(nullif(btrim(rp.point_name), ''), 'محطة'),
    row_number() over (order by rp.point_order, rp.created_at, rp.id),
    v_base + public.parse_route_offset(rp.arrival_offset),
    v_base + greatest(public.parse_route_offset(rp.departure_offset),
                      public.parse_route_offset(rp.arrival_offset)),
    greatest(
      extract(epoch from public.parse_route_offset(rp.departure_offset)
                       - public.parse_route_offset(rp.arrival_offset))::int,
      0),
    case when row_number() over (order by rp.point_order, rp.created_at, rp.id) = 1
         then 'arriving' else 'upcoming' end
  from public.trip_route_points rp
  where rp.trip_id = p_trip_id
  -- Untargeted: a partial re-seed can collide on either unique constraint, and both
  -- mean the same thing — that row is already there.
  on conflict do nothing;

  get diagnostics v_inserted = row_count;

  if v_inserted = 0 then
    return 0;
  end if;

  perform public.recount_trip_stations(p_trip_id);

  -- ── Backfill from arrival events ──────────────────────────────────────────────────
  -- The captain's station arrivals are already on record as `trip_events` rows titled
  -- 'وصول محطة' — the marker `countStationArrivalEvents` counts in all three apps.
  -- Replay them in order onto the fresh board so the trip resumes where it actually is.
  select exists (
    select 1 from public.trip_events e
     where e.trip_id = p_trip_id and e.title = 'وصول محطة'
  ) into v_seeded;

  if v_seeded then
    with arrivals as (
      select row_number() over (order by e.created_at, e.id) as n, e.created_at
        from public.trip_events e
       where e.trip_id = p_trip_id
         and e.title = 'وصول محطة'
    )
    update public.trip_station_progress sp
       set actual_arrival_at = a.created_at,
           status            = 'waiting_for_passengers',
           updated_at        = now()
      from arrivals a
     where sp.trip_id = p_trip_id
       and sp.sequence = a.n
       and sp.actual_arrival_at is null;

    -- Every arrived station except the last one the vehicle reached has been left. Its
    -- departure instant is unknowable after the fact; the next station's arrival is the
    -- closest honest answer, and for the last one it is the arrival itself.
    update public.trip_station_progress sp
       set actual_departure_at = coalesce(nxt.actual_arrival_at, sp.actual_arrival_at),
           status              = 'departed',
           updated_at          = now()
      from public.trip_station_progress nxt
     where sp.trip_id = p_trip_id
       and nxt.trip_id = sp.trip_id
       and nxt.sequence = sp.sequence + 1
       and sp.actual_arrival_at is not null
       and sp.actual_departure_at is null
       and nxt.actual_arrival_at is not null;

    -- The stop after the last arrival is the one being driven towards.
    update public.trip_station_progress sp
       set status = 'arriving', updated_at = now()
     where sp.trip_id = p_trip_id
       and sp.status = 'upcoming'
       and sp.sequence = (
         select min(s2.sequence) from public.trip_station_progress s2
          where s2.trip_id = p_trip_id and s2.actual_arrival_at is null
       );
  end if;

  return v_inserted;
end;
$$;

comment on function public.ensure_trip_station_progress(uuid) is
  'Builds the station board for a boarding/in-progress trip from trip_route_points, '
  'and reconstructs the stations already visited from the captain''s arrival events. '
  'Idempotent — every read and write path calls it, so a trip that started before this '
  'feature shipped self-heals on first contact instead of restarting at station one.';

-- Seed the board the moment a trip starts boarding, so the captain's first screen is
-- already correct rather than waiting for a lazy call to fill it in.
create or replace function public.seed_trip_station_progress()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.status = 'boarding' and old.status is distinct from new.status then
    perform public.ensure_trip_station_progress(new.id);
  end if;
  return null;
end;
$$;

drop trigger if exists trg_seed_trip_station_progress on public.operation_trips;
create trigger trg_seed_trip_station_progress
  after update of status on public.operation_trips
  for each row execute function public.seed_trip_station_progress();

-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. The departure gate, in one place
-- ───────────────────────────────────────────────────────────────────────────────────
-- The earliest instant the vehicle may leave a station it has arrived at.
--
-- Two clocks, whichever is later:
--
--   * the configured dwell, measured from the *actual* arrival — a vehicle that pulls
--     in twenty minutes late still owes its passengers the three minutes the operator
--     allotted for boarding;
--   * the published departure time — a vehicle that arrives early may not leave before
--     the time the riders were told, because they are not there yet.
--
-- Null when neither is known (an untimed stop), which means the boarding requirement is
-- the only gate.
create or replace function public.station_earliest_departure(
  p_actual_arrival_at   timestamptz,
  p_expected_departure_at timestamptz,
  p_min_dwell_seconds   int
)
returns timestamptz
language sql
immutable
as $$
  select greatest(
    case when p_actual_arrival_at is null then null
         else p_actual_arrival_at + make_interval(secs => coalesce(p_min_dwell_seconds, 0))
    end,
    p_expected_departure_at
  );
$$;

comment on function public.station_earliest_departure(timestamptz, timestamptz, int) is
  'The later of (actual arrival + configured dwell) and the published departure time. '
  'Mirrored exactly by StationGate.earliestDeparture in '
  'lib/core/tracking/progress/station_board.dart — the Dart side disables a button, '
  'this side refuses the transition.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 4. Captain transitions
-- ───────────────────────────────────────────────────────────────────────────────────

-- Resolve and lock the trip, asserting the caller is its captain and it is running.
-- Factored out because all three captain RPCs below open the same way, and a check that
-- exists in two of three places is the one that gets forgotten.
create or replace function public.assert_captain_running_trip(p_trip_id uuid)
returns public.operation_trips
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_driver uuid;
  v_trip   public.operation_trips;
begin
  v_driver := public.current_driver_id();
  if v_driver is null then
    raise exception 'not_a_captain';
  end if;

  -- FOR UPDATE serialises every station transition on this trip against every other
  -- one. Two taps arriving together do not become two stations.
  select * into v_trip
    from public.operation_trips
   where id = p_trip_id
   for update;

  if not found then
    raise exception 'trip_not_found';
  end if;
  if v_trip.driver_id is distinct from v_driver then
    raise exception 'not_your_trip';
  end if;
  if v_trip.status not in ('boarding', 'in_progress') then
    raise exception 'trip_not_running:%', v_trip.status;
  end if;

  return v_trip;
end;
$$;

-- The captain reports reaching the current station.
create or replace function public.captain_arrive_station(p_trip_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_trip    public.operation_trips;
  v_station public.trip_station_progress;
begin
  v_trip := public.assert_captain_running_trip(p_trip_id);
  perform public.ensure_trip_station_progress(p_trip_id);

  -- Already standing at a station: a retried request, a double tap, a reconnect
  -- replaying a call that had in fact succeeded. Nothing is wrong, and advancing would
  -- be wrong.
  select * into v_station
    from public.trip_station_progress
   where trip_id = p_trip_id
     and actual_arrival_at is not null
     and actual_departure_at is null
   order by sequence
   limit 1
   for update;

  if found then
    return jsonb_build_object(
      'success', true, 'unchanged', true,
      'station_id', v_station.id, 'sequence', v_station.sequence,
      'point_name', v_station.point_name);
  end if;

  select * into v_station
    from public.trip_station_progress
   where trip_id = p_trip_id
     and actual_departure_at is null
   order by sequence
   limit 1
   for update;

  if not found then
    raise exception 'no_pending_station';
  end if;

  update public.trip_station_progress
     set actual_arrival_at = now(),
         status            = 'waiting_for_passengers',
         arrived_by        = auth.uid(),
         updated_at        = now()
   where id = v_station.id;

  -- The same marker the Dashboard, the Client timeline and the Captain's own assigned
  -- trip list already count. Written here rather than by the app so that arriving at a
  -- station and recording having arrived cannot come apart.
  insert into public.trip_events (trip_id, title, description, done)
  values (p_trip_id, 'وصول محطة',
          'وصلت الرحلة إلى محطة: ' || v_station.point_name, true);

  return jsonb_build_object(
    'success', true, 'unchanged', false,
    'station_id', v_station.id, 'sequence', v_station.sequence,
    'point_name', v_station.point_name);
end;
$$;

comment on function public.captain_arrive_station(uuid) is
  'Marks the trip''s next un-departed station as reached, and files the arrival event '
  'the rest of the platform counts. Idempotent while the vehicle is standing at a '
  'station, so a double tap cannot skip one.';

-- The gated transition. Everything this feature is about happens here.
create or replace function public.captain_depart_station(p_trip_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_trip      public.operation_trips;
  v_station   public.trip_station_progress;
  v_earliest  timestamptz;
  v_next      int;
  v_tz        text;
begin
  v_trip := public.assert_captain_running_trip(p_trip_id);
  perform public.ensure_trip_station_progress(p_trip_id);

  select * into v_station
    from public.trip_station_progress
   where trip_id = p_trip_id
     and actual_arrival_at is not null
     and actual_departure_at is null
   order by sequence
   limit 1
   for update;

  if not found then
    -- Either the vehicle has not reported arriving anywhere yet, or this station was
    -- already departed by a request that beat this one. Both are refusals, not
    -- advances: the alternative is a retry silently departing the *next* station.
    raise exception 'no_current_station';
  end if;

  -- Condition A — the boarding requirement.
  -- Recounted first: the tally is maintained by trigger, but a rider confirming
  -- boarding in the same instant as this call must not be able to lose the race and be
  -- left behind, and re-reading under the trip lock closes that window.
  perform public.recount_trip_stations(p_trip_id);
  select * into v_station from public.trip_station_progress where id = v_station.id;

  if v_station.pending_count > 0 then
    raise exception 'passengers_not_boarded:%', v_station.pending_count;
  end if;

  -- Condition B — the departure clock.
  v_earliest := public.station_earliest_departure(
    v_station.actual_arrival_at, v_station.expected_departure_at,
    v_station.min_dwell_seconds);

  if v_earliest is not null and now() < v_earliest then
    select coalesce(
             (select w.timezone from public.office_wallet_policies w
               where w.office_id = v_trip.office_id),
             'Africa/Cairo')
      into v_tz;
    raise exception 'departure_time_not_reached:%',
      to_char(v_earliest at time zone v_tz, 'HH24:MI');
  end if;

  update public.trip_station_progress
     set actual_departure_at = now(),
         status              = 'departed',
         departed_by         = auth.uid(),
         updated_at          = now()
   where id = v_station.id;

  v_next := v_station.sequence + 1;

  update public.trip_station_progress
     set status = 'arriving', updated_at = now()
   where trip_id = p_trip_id
     and sequence = v_next
     and status = 'upcoming';

  -- Leaving the first station *is* the trip departing. Routed through the captain
  -- wrapper so the status allowlist (20260723090000) stays the single authority on
  -- which transitions a captain may cause.
  if v_trip.status = 'boarding' then
    perform public.captain_update_trip_status(p_trip_id, 'in_progress', null);
  end if;

  return jsonb_build_object(
    'success',       true,
    'station_id',    v_station.id,
    'sequence',      v_station.sequence,
    'point_name',    v_station.point_name,
    'departed_at',   now(),
    'next_sequence', case when exists (
                            select 1 from public.trip_station_progress
                             where trip_id = p_trip_id and sequence = v_next)
                          then v_next else null end);
end;
$$;

comment on function public.captain_depart_station(uuid) is
  'The one way a trip advances between stations. Refuses unless the caller is the '
  'trip''s captain, the station is the one the vehicle is standing at, every expected '
  'passenger is resolved (boarded, no-show or cancelled), and the configured dwell and '
  'published departure time have both passed. Row-locked, so concurrent requests can '
  'never advance two stations.';

-- The controlled alternative to a Skip button.
create or replace function public.captain_resolve_no_show(
  p_trip_passenger_id uuid,
  p_reason            text,
  p_note              text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_pax  public.trip_passengers;
  v_trip public.operation_trips;
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if p_reason not in ('did_not_arrive', 'cancelled_by_passenger',
                      'passenger_requested', 'other') then
    raise exception 'invalid_no_show_reason:%', p_reason;
  end if;

  -- "Other" without a note is a skip with extra steps.
  if p_reason = 'other' and v_note is null then
    raise exception 'no_show_note_required';
  end if;

  select * into v_pax
    from public.trip_passengers
   where id = p_trip_passenger_id
   for update;

  if not found then
    raise exception 'passenger_not_found';
  end if;

  v_trip := public.assert_captain_running_trip(v_pax.trip_id);

  if v_pax.status = 'no_show' then
    return jsonb_build_object('success', true, 'unchanged', true,
                              'passenger_id', v_pax.id);
  end if;

  -- A rider who is already aboard, or whose booking the office cancelled, is not a
  -- no-show. Only someone still expected can become one.
  if v_pax.status <> 'reserved' then
    raise exception 'passenger_not_pending:%', v_pax.status;
  end if;

  update public.trip_passengers
     set status          = 'no_show',
         no_show_reason  = p_reason,
         resolution_note = v_note,
         resolved_by     = auth.uid(),
         resolved_at     = now(),
         updated_at      = now()
   where id = v_pax.id;

  insert into public.trip_events (trip_id, title, description, done)
  values (
    v_pax.trip_id,
    'راكب لم يصعد',
    'الراكب ' || coalesce(nullif(btrim(v_pax.passenger_name), ''), 'غير معروف')
      || ' (محطة ' || coalesce(nullif(btrim(v_pax.pickup_point_name), ''), 'غير محددة') || ')'
      || ' — ' || case p_reason
                    when 'did_not_arrive'         then 'لم يحضر'
                    when 'cancelled_by_passenger' then 'ألغى الراكب'
                    when 'passenger_requested'    then 'بناءً على طلب الراكب'
                    else 'سبب آخر'
                  end
      || coalesce(': ' || v_note, ''),
    true);

  perform public.recount_trip_stations(v_pax.trip_id);

  return jsonb_build_object('success', true, 'unchanged', false,
                            'passenger_id', v_pax.id, 'reason', p_reason);
end;
$$;

comment on function public.captain_resolve_no_show(uuid, text, text) is
  'Clears a passenger out of a station''s boarding requirement by recording *why* they '
  'are not travelling, who decided that, and when. The captain has no direct write to '
  'no_show — this is the only path, so a passenger can never be quietly stepped over.';

-- Close the direct path. The captain policy previously admitted 'no_show' as a value
-- the captain could write straight onto the manifest, which is exactly the silent skip
-- the RPC above exists to prevent. Boarding a rider by hand stays a direct write — it
-- is the captain's own observation and needs no justification.
drop policy if exists trip_passengers_captain_board on public.trip_passengers;

create policy trip_passengers_captain_board on public.trip_passengers
  for update to authenticated
  using (
    exists (select 1 from public.operation_trips tr
             where tr.id = trip_id
               and tr.driver_id = public.current_driver_id())
    and status not in ('cancelled', 'completed')
  )
  with check (
    exists (select 1 from public.operation_trips tr
             where tr.id = trip_id
               and tr.driver_id = public.current_driver_id())
    and status in ('reserved', 'confirmed')
  );

comment on policy trip_passengers_captain_board on public.trip_passengers is
  'The captain may move a rider between reserved and confirmed — that is the check-in '
  'they perform with their own eyes. no_show is deliberately absent: it removes a '
  'passenger from a station''s boarding requirement, so it goes through '
  'captain_resolve_no_show, which demands a reason and files an audit event.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 5. The rider confirms their own boarding
-- ───────────────────────────────────────────────────────────────────────────────────
create or replace function public.passenger_confirm_boarding(p_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_booking public.operation_bookings;
  v_trip    public.operation_trips;
  v_station public.trip_station_progress;
  v_pax     public.trip_passengers;
  v_matches boolean;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_booking
    from public.operation_bookings
   where id = p_booking_id
   for update;

  if not found then
    raise exception 'booking_not_found';
  end if;

  -- A rider marks their own booking boarded and no one else's. This is the whole
  -- authorisation check, and it is here rather than in the app.
  if v_booking.client_id is distinct from auth.uid() then
    raise exception 'not_your_booking';
  end if;

  -- Idempotent: a double tap, or a retry after a timeout that had in fact succeeded.
  if v_booking.status = 'boarded' then
    return jsonb_build_object('success', true, 'unchanged', true,
                              'booking_id', v_booking.id);
  end if;

  if v_booking.status <> 'confirmed' then
    raise exception 'booking_not_boardable:%', v_booking.status;
  end if;

  select * into v_trip from public.operation_trips where id = v_booking.trip_id;
  if not found then
    raise exception 'trip_not_found';
  end if;
  if v_trip.status not in ('boarding', 'in_progress') then
    raise exception 'trip_not_running:%', v_trip.status;
  end if;

  perform public.ensure_trip_station_progress(v_booking.trip_id);

  -- The vehicle has to actually be standing somewhere. Without this a rider could
  -- confirm boarding from home and disappear out of their station's tally before the
  -- bus ever got there.
  select * into v_station
    from public.trip_station_progress
   where trip_id = v_booking.trip_id
     and actual_arrival_at is not null
     and actual_departure_at is null
   order by sequence
   limit 1;

  if not found then
    raise exception 'vehicle_not_at_station';
  end if;

  select * into v_pax
    from public.trip_passengers
   where trip_id = v_booking.trip_id
     and (booking_id = v_booking.id or customer_id = auth.uid())
   order by (booking_id = v_booking.id) desc
   limit 1;

  -- …and it has to be *their* station. Matched on the manifest's point id, falling back
  -- to the name for trips whose points predate the id being recorded.
  if found then
    v_matches := (v_pax.pickup_point_id is not null
                  and v_pax.pickup_point_id = v_station.route_point_id)
              or (v_pax.pickup_point_id is null
                  and btrim(coalesce(v_pax.pickup_point_name, ''))
                      = btrim(v_station.point_name));

    if not v_matches then
      raise exception 'not_your_station:%', v_station.point_name;
    end if;

    if v_pax.status not in ('reserved', 'confirmed') then
      raise exception 'passenger_not_boardable:%', v_pax.status;
    end if;

    update public.trip_passengers
       set status          = 'confirmed',
           boarded_at      = coalesce(boarded_at, now()),
           boarding_source = coalesce(boarding_source, 'passenger'),
           updated_at      = now()
     where id = v_pax.id;
  end if;

  update public.operation_bookings
     set status = 'boarded', updated_at = now()
   where id = v_booking.id;

  perform public.recount_trip_stations(v_booking.trip_id);

  return jsonb_build_object(
    'success',     true,
    'unchanged',   false,
    'booking_id',  v_booking.id,
    'station_id',  v_station.id,
    'point_name',  v_station.point_name,
    'boarded_at',  now());
end;
$$;

comment on function public.passenger_confirm_boarding(uuid) is
  'The rider''s "نعم، صعدت". Refuses unless the booking is theirs, is paid for, and the '
  'vehicle is standing at that rider''s own pickup station. Sets the booking to '
  'boarded — which is also what stops this rider (and only this rider) from seeing the '
  'vehicle''s live position, see can_read_trip_fixes below.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 6. Grants and read boundary
-- ───────────────────────────────────────────────────────────────────────────────────

-- Who may watch a trip's station board?
--
-- Wider than the live-position feed on purpose: a rider who has boarded no longer needs
-- to know where the vehicle *is*, but very much still needs to know which stations are
-- left and when they arrive. A board says "station three at 09:15"; it does not say
-- where the vehicle is standing right now.
create or replace function public.can_read_trip_stations(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    public.is_platform_admin()
    or exists (
      select 1 from public.operation_trips t
       where t.id = p_trip_id
         and t.office_id is not null
         and t.office_id = public.current_office_id()
    )
    or exists (
      select 1 from public.operation_trips t
       where t.id = p_trip_id
         and t.driver_id is not null
         and t.driver_id = public.current_driver_id()
    )
    or exists (
      select 1 from public.operation_bookings b
       where b.trip_id = p_trip_id
         and b.client_id = auth.uid()
         and b.status in ('confirmed', 'boarded', 'completed')
    );
$$;

comment on function public.can_read_trip_stations(uuid) is
  'May the caller watch this trip''s station board? The operating office, the assigned '
  'captain, a passenger holding a paid booking, or platform admin. SECURITY DEFINER for '
  'the same reason as can_read_trip_fixes — it is called from an RLS policy on a '
  'realtime-published table and joins tables the reader has no read policy on.';

revoke all on function public.can_read_trip_stations(uuid) from public, anon;
grant execute on function public.can_read_trip_stations(uuid) to authenticated;

alter table public.trip_station_progress enable row level security;

revoke all    on public.trip_station_progress from public, anon, authenticated;
grant  select on public.trip_station_progress to authenticated;

drop policy if exists trip_station_progress_read on public.trip_station_progress;
create policy trip_station_progress_read
  on public.trip_station_progress
  for select to authenticated
  using (public.can_read_trip_stations(trip_id));

comment on policy trip_station_progress_read on public.trip_station_progress is
  'Read-only, for the four parties with a reason to look. There is deliberately no '
  'INSERT/UPDATE/DELETE policy and no grant for any of them: every write goes through '
  'the SECURITY DEFINER RPCs, which is what makes the departure gate enforceable rather '
  'than advisory.';

-- Realtime: the board is what both apps subscribe to, so the captain sees a boarding
-- confirmation land and the rider sees the station advance without either app polling.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'trip_station_progress'
  ) then
    alter publication supabase_realtime add table public.trip_station_progress;
  end if;
end $$;

-- Realtime sends only the primary key in the old record of an UPDATE unless the table
-- replicates its full old row; the apps diff on status and counts, so they need it.
alter table public.trip_station_progress replica identity full;

revoke all on function public.parse_route_offset(text)                       from public, anon;
revoke all on function public.station_earliest_departure(timestamptz, timestamptz, int)
                                                                             from public, anon;
revoke all on function public.recount_trip_stations(uuid)                    from public, anon, authenticated;
revoke all on function public.ensure_trip_station_progress(uuid)             from public, anon, authenticated;
revoke all on function public.assert_captain_running_trip(uuid)              from public, anon, authenticated;
revoke all on function public.captain_arrive_station(uuid)                   from public, anon;
revoke all on function public.captain_depart_station(uuid)                   from public, anon;
revoke all on function public.captain_resolve_no_show(uuid, text, text)      from public, anon;
revoke all on function public.passenger_confirm_boarding(uuid)               from public, anon;

grant execute on function public.parse_route_offset(text)                    to authenticated;
grant execute on function public.station_earliest_departure(timestamptz, timestamptz, int)
                                                                             to authenticated;
grant execute on function public.captain_arrive_station(uuid)                to authenticated;
grant execute on function public.captain_depart_station(uuid)                to authenticated;
grant execute on function public.captain_resolve_no_show(uuid, text, text)   to authenticated;
grant execute on function public.passenger_confirm_boarding(uuid)            to authenticated;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 7. Per-rider tracking visibility
-- ───────────────────────────────────────────────────────────────────────────────────
-- Live vehicle position answers exactly one question: "how long until it reaches me?"
-- Once a rider is aboard, that question is answered and the position is no longer
-- theirs to have — it is the rest of the vehicle's passengers, and the captain's own
-- movements, for the remainder of the run.
--
-- So the passenger arm narrows from three statuses to one. What this is NOT is a switch
-- on the trip: the captain keeps publishing, and every *other* booking on the same trip
-- that is still `confirmed` keeps reading. Visibility is per booking, evaluated per
-- delivered row, which is precisely what an RLS policy on a realtime-published table
-- does.
--
--   Passenger A — confirmed, waiting … reads fixes
--   Passenger B — confirmed, waiting … reads fixes
--   Passenger C — boarded            … reads nothing
--
-- `completed` goes with `boarded`: a journey that is over has no live position either,
-- and leaving it in would hand every past rider a permanent feed of the vehicle.
create or replace function public.can_read_trip_fixes(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    -- The platform admin. Deliberate, and the only unscoped reader on the table.
    public.is_platform_admin()

    -- The office that operates the trip.
    or exists (
      select 1 from public.operation_trips t
       where t.id = p_trip_id
         and t.office_id is not null
         and t.office_id = public.current_office_id()
    )

    -- The captain driving it, who is the author of these rows.
    or exists (
      select 1 from public.operation_trips t
       where t.id = p_trip_id
         and t.driver_id is not null
         and t.driver_id = public.current_driver_id()
    )

    -- The passenger — while they are still waiting for the vehicle, and no longer.
    -- `reserved` (payment pending) and `cancelled` never could; `boarded` and
    -- `completed` no longer can.
    or exists (
      select 1 from public.operation_bookings b
       where b.trip_id = p_trip_id
         and b.client_id = auth.uid()
         and b.status = 'confirmed'
    );
$$;

comment on function public.can_read_trip_fixes(uuid) is
  'May the current caller watch this trip''s live positions? Platform admin, the '
  'operating office, the assigned captain, or a passenger who is still waiting for the '
  'vehicle (booking status confirmed). A passenger who has boarded loses it and every '
  'passenger still waiting keeps it — the gate is per booking, never per trip, and the '
  'captain never stops publishing.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 8. Backfill
-- ───────────────────────────────────────────────────────────────────────────────────
-- Any trip already boarding or running when this shipped gets its board now, rather
-- than on whichever app happens to open it first.
do $$
declare v_trip uuid;
begin
  for v_trip in
    select id from public.operation_trips where status in ('boarding', 'in_progress')
  loop
    perform public.ensure_trip_station_progress(v_trip);
  end loop;
end $$;
