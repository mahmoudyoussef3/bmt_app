-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 6 — Tracking Authority
--
-- Phase 5 (`20260728120000_captain_authority`) closed the WRITE hole on
-- `trip_live_locations`: anon could forge or erase any vehicle's position. It
-- deliberately left the READ path alone, on the standing assumption that
-- `trip_live_locations` has to stay RLS-free or realtime delivery to client maps
-- stops working. That assumption was recorded as an accepted open risk (R1).
--
-- It is not an acceptable risk, and the assumption is wrong. Measured on the live
-- database before this migration:
--
--     set local role anon;
--     select count(*), count(distinct trip_id) from public.trip_live_locations;
--     -- 14 rows, 5 trips
--
-- `anon` is the key that ships inside every install of the Client app. So anyone
-- holding the app — no account, no booking, no office — could read the live GPS
-- position of every vehicle on the platform, in every office, and (via the
-- realtime publication this table is a member of) stream them as they move.
-- `public_trips` publishes trip ids to the whole marketplace, so there is nothing
-- to guess: pick a trip id off the marketplace, subscribe, and follow the bus.
--
-- That is a cross-office isolation break, a passenger-privacy break, and a
-- physical-safety concern for the captain — all from a table that was left open
-- for a client-side convenience.
--
-- ── Why RLS is compatible with realtime after all ────────────────────────────────
--
-- Realtime evaluates a subscriber's SELECT policies against each WAL row, as that
-- subscriber's role. The trap — and almost certainly the original breakage — is
-- that a policy's subqueries are themselves subject to RLS on the tables they
-- touch. A policy written the obvious way:
--
--     using (exists (select 1 from operation_trips t where t.id = trip_id ...))
--
-- silently returns FALSE for every client, because clients hold no read policy on
-- `operation_trips` at all (`trips_captain_read` / `trips_office_manage` are the
-- only two). The map goes dark, RLS gets blamed, and the table gets left open.
--
-- The fix is to answer the ownership question inside a SECURITY DEFINER helper, so
-- the joins run without RLS interference and the policy body only ever touches the
-- row's own `trip_id`. That is `can_read_trip_fixes` below.
--
-- ── What this migration establishes ──────────────────────────────────────────────
--
--   1. can_read_trip_fixes / can_publish_trip_fix — the two ownership questions,
--      answered server-side, once, for every surface.
--   2. trip_live_locations: RLS on, anon SELECT revoked, read scoped to the four
--      parties who have a reason to look, insert scoped to the assigned captain.
--   3. trip_progress_events: the same write hole Phase 5 closed on its sibling —
--      anon still holds full INSERT/UPDATE/DELETE/TRUNCATE here.
--   4. prune_trip_live_locations — retention, so the fix table stays a live feed
--      rather than an unbounded movement archive of every passenger's journey.
-- ═══════════════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. The two ownership questions
-- ───────────────────────────────────────────────────────────────────────────────────

-- Who may watch a trip move?
--
-- SECURITY DEFINER for the reason above: this is called from an RLS policy on a
-- table in the realtime publication, and every table it joins (`operation_trips`,
-- `drivers`) is one the reader is not allowed to select from directly. STABLE so
-- the planner may cache it within a statement — it is called once per row per
-- subscriber on the realtime path, which is the hot path here.
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

    -- The office that operates the trip. Covers the Live Operations Center and
    -- every operator looking at their own fleet — and no one else's.
    or exists (
      select 1 from public.operation_trips t
       where t.id = p_trip_id
         and t.office_id is not null
         and t.office_id = public.current_office_id()
    )

    -- The captain driving it. They are the author of these rows; they can read
    -- back what they published.
    or exists (
      select 1 from public.operation_trips t
       where t.id = p_trip_id
         and t.driver_id is not null
         and t.driver_id = public.current_driver_id()
    )

    -- The passenger, and only for a booking that is actually paid for. The status
    -- set is the same one the Client app enforces in `TrackingTripQuery`
    -- (`trackableStatuses`) — a rider whose payment is still pending (`reserved`)
    -- or was rejected (`cancelled`) cannot watch the vehicle. Keeping the two in
    -- step matters: the app-side check is a courtesy, this one is the boundary.
    or exists (
      select 1 from public.operation_bookings b
       where b.trip_id = p_trip_id
         and b.client_id = auth.uid()
         and b.status in ('confirmed', 'boarded', 'completed')
    );
$$;

comment on function public.can_read_trip_fixes(uuid) is
  'May the current caller watch this trip''s live positions? Platform admin, the '
  'operating office, the assigned captain, or a passenger holding a paid booking '
  '(confirmed/boarded/completed) — nobody else. SECURITY DEFINER because it is '
  'called from an RLS policy on a realtime-published table and joins tables the '
  'reader has no read policy on; written that way a policy silently denies '
  'everyone and the table ends up left open instead.';

-- Who may publish a position for a trip?
--
-- The assigned captain, and no one else. This restates in a policy what
-- `enforce_live_location_authorship` (Phase 5) enforces in a trigger. Both are
-- kept: the policy is the boundary, the trigger is what overwrites a forged
-- `driver_id` with the server-resolved one, and neither is redundant with the
-- other.
create or replace function public.can_publish_trip_fix(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists (
    select 1
      from public.operation_trips t
     where t.id = p_trip_id
       and t.driver_id is not null
       and t.driver_id = public.current_driver_id()
  );
$$;

comment on function public.can_publish_trip_fix(uuid) is
  'May the current caller publish a live position for this trip? Only the captain '
  'the trip is assigned to. Paired with enforce_live_location_authorship(), which '
  'stamps driver_id server-side rather than trusting the payload.';

revoke all on function public.can_read_trip_fixes(uuid)  from public, anon;
revoke all on function public.can_publish_trip_fix(uuid) from public, anon;
grant execute on function public.can_read_trip_fixes(uuid)  to authenticated;
grant execute on function public.can_publish_trip_fix(uuid) to authenticated;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. trip_live_locations — close the read hole
-- ───────────────────────────────────────────────────────────────────────────────────

-- The anon key ships in the app. Nothing reachable with it alone should be a live
-- map of the fleet.
revoke select on public.trip_live_locations from anon;

alter table public.trip_live_locations enable row level security;

drop policy if exists "Clients can view live locations for booked trips" on public.trip_live_locations;
drop policy if exists "Drivers can insert live locations for their assigned trips" on public.trip_live_locations;
drop policy if exists trip_live_locations_read on public.trip_live_locations;
drop policy if exists trip_live_locations_captain_publish on public.trip_live_locations;

create policy trip_live_locations_read
  on public.trip_live_locations
  for select
  to authenticated
  using (public.can_read_trip_fixes(trip_id));

comment on policy trip_live_locations_read on public.trip_live_locations is
  'The one read boundary for live positions, shared by the Client map, the Captain '
  'app, the Live Operations Center and platform admin. Realtime evaluates this per '
  'delivered row, so the whole question is answered by a definer helper against the '
  'row''s trip_id and nothing else.';

create policy trip_live_locations_captain_publish
  on public.trip_live_locations
  for insert
  to authenticated
  with check (public.can_publish_trip_fix(trip_id));

comment on policy trip_live_locations_captain_publish on public.trip_live_locations is
  'Only the assigned captain publishes. There is no UPDATE or DELETE policy and no '
  'grant for either: a position that has been reported is a fact about where the '
  'vehicle was, and nothing on the client side may rewrite or erase it.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. trip_progress_events — the same hole, on the sibling table
-- ───────────────────────────────────────────────────────────────────────────────────
-- Created alongside `trip_live_locations` in `migration_02`, given RLS there, and
-- then left with RLS off and `anon` holding INSERT, UPDATE, DELETE and TRUNCATE.
-- No Dart code reads or writes it today, which is exactly why it went unnoticed
-- through five phases — an unused table with anon DML is still an anon-writable
-- table joined by foreign key to trips, drivers and stations.
--
-- Locked to the same shape as its sibling rather than dropped: the captain's
-- per-station progress trail is a feature the platform is likely to want, and a
-- table that is secure and empty costs nothing.

revoke insert, update, delete, truncate on public.trip_progress_events from anon;
revoke        update, delete, truncate on public.trip_progress_events from authenticated;
revoke select on public.trip_progress_events from anon;

alter table public.trip_progress_events enable row level security;

drop policy if exists "Drivers can insert progress events" on public.trip_progress_events;
drop policy if exists trip_progress_events_read on public.trip_progress_events;
drop policy if exists trip_progress_events_captain_insert on public.trip_progress_events;

create policy trip_progress_events_read
  on public.trip_progress_events
  for select
  to authenticated
  using (public.can_read_trip_fixes(trip_id));

create policy trip_progress_events_captain_insert
  on public.trip_progress_events
  for insert
  to authenticated
  with check (public.can_publish_trip_fix(trip_id));

comment on policy trip_progress_events_read on public.trip_progress_events is
  'Same audience as the live position feed — a progress trail says where a vehicle '
  'has been, which is the same disclosure.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 4. Retention
-- ───────────────────────────────────────────────────────────────────────────────────
-- One captain publishing every 30 s produces ~120 rows an hour, ~1,400 over a
-- twelve-hour service day. Fifty vehicles is ~70,000 rows a day, ~25M a year, and
-- none of it is read after the trip ends — the Client map, the Captain card and
-- the Live Ops board all want the *latest* fix, never the history.
--
-- Left alone this table becomes both a performance problem and a liability: a
-- permanent, per-passenger-journey movement archive that the platform never
-- decided to keep.
--
-- No pg_cron on this project, so this is a callable function rather than a
-- schedule. It is not wired to anything yet — that is stated plainly in
-- TRACKING_STATUS.md as a remaining item rather than implied to be running.
create or replace function public.prune_trip_live_locations(p_retain_days integer default 7)
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_deleted integer;
begin
  if p_retain_days is null or p_retain_days < 1 then
    raise exception 'retain_days_must_be_positive';
  end if;

  -- Fixes belonging to a trip that is still running are never pruned regardless of
  -- age, so a long-running or stuck trip cannot have its live feed deleted out from
  -- under the map watching it.
  delete from public.trip_live_locations l
   where l.recorded_at < now() - make_interval(days => p_retain_days)
     and not exists (
       select 1 from public.operation_trips t
        where t.id = l.trip_id
          and t.status in ('boarding', 'in_progress')
     );

  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;

comment on function public.prune_trip_live_locations(integer) is
  'Deletes live position fixes older than p_retain_days, skipping any trip still '
  'boarding or in progress. Live positions are a feed, not an archive; without this '
  'the table grows without bound and keeps a movement history of every journey. '
  'service_role only — intended for a scheduled job.';

revoke all on function public.prune_trip_live_locations(integer) from public, anon, authenticated;
grant execute on function public.prune_trip_live_locations(integer) to service_role;
