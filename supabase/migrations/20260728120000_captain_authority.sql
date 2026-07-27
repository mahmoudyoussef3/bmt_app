-- ═══════════════════════════════════════════════════════════════════════════════════
-- Captain authority: the captain reports, operations owns the record
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 5 audit, 2026-07-28. The multi-office sweep (20260721090200) gave the captain
-- one policy per table, all of them `for all`, all of them gated on nothing but "this
-- trip is mine". Ownership was the only question asked. What the captain was allowed to
-- *do* with a row they owned was never constrained, and four of those tables have since
-- grown an operations-side workflow that assumes the captain cannot rewrite history:
--
--   • `driver_trip_reports` gained an incident lifecycle (20260727090000) whose whole
--     point is that a human operator takes ownership of an alarm.
--   • `trip_events` gained `event_code` and became the trip's authoritative audit trail
--     (20260727160000); Live Ops reads it.
--   • `trip_passengers` became financially load-bearing: `update_trip_status('completed')`
--     turns everyone the captain did not board into `no_show`.
--   • `captain_messages` carries `sender_type`, which the Captain App reads to decide
--     which side of the thread a message belongs on.
--
-- Every exploit below was proven against the linked database inside BEGIN … ROLLBACK
-- while impersonating a real captain, before this migration was written:
--
--   B. captain self-RESOLVES own SOS ......... EXPLOITABLE — 1 row(s) updated
--   C. captain DELETES own SOS ............... EXPLOITABLE — evidence destroyed
--   D1. captain INSERTs an audit-coded event . EXPLOITABLE — forged trip_departed
--   D2. captain DELETES an audit event ....... EXPLOITABLE — audit row destroyed
--   E. captain DELETES manifest rows ......... EXPLOITABLE — 1 passenger(s) erased
--   F. captain FORGES an ops message ......... EXPLOITABLE
--   O. trip_live_locations, anon full DML .... any visitor may forge or erase positions
--
-- Cross-driver and cross-office isolation were tested in the same session and are
-- sound — reads of another driver's trip and manifest returned 0 rows, and
-- `captain_update_trip_status` on another driver's trip raised `not_your_trip`. The
-- status allowlist (20260723090000, re-established by 20260727160000) is binding on
-- both wrappers and the raw setter is ungranted. None of that is changed here.
--
-- The shape this migration establishes, for every captain-facing table:
--
--        captain  →  append-only, own trips, own identity
--        office   →  full lifecycle authority (unchanged)
--
-- Cancellation, publishing, incident triage and manifest composition stay with
-- operations. The captain reports what happened; they do not get to edit the record of
-- what happened.

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. driver_trip_reports — the captain raises the alarm, operations owns it
-- ───────────────────────────────────────────────────────────────────────────────────
-- A captain who can set their own report to 'resolved' can take an SOS out of the
-- operations queue without a single operator ever seeing it, and a captain who can
-- DELETE it can remove the fact that it was ever raised. Both are the exact failure the
-- incident lifecycle exists to prevent.
--
-- Filing is also newly scoped to the captain's *own trip*: the old policy checked only
-- `driver_id = current_driver_id()`, so a captain could attach a report to any trip id
-- in the platform — including another office's — simply by naming it.

drop policy if exists driver_trip_reports_captain_rw on public.driver_trip_reports;

create policy driver_trip_reports_captain_read on public.driver_trip_reports
  for select to authenticated
  using (driver_id = public.current_driver_id());

create policy driver_trip_reports_captain_file on public.driver_trip_reports
  for insert to authenticated
  with check (
    driver_id = public.current_driver_id()
    and exists (select 1 from public.operation_trips tr
                 where tr.id = trip_id
                   and tr.driver_id = public.current_driver_id())
    -- A report enters the queue as 'pending'. Nothing else is a legal opening state:
    -- the other three are operator verdicts.
    and status = 'pending'
  );

comment on policy driver_trip_reports_captain_file on public.driver_trip_reports is
  'Captains file incidents against their own trips, always as pending. Acknowledging, '
  'resolving and dismissing are operator verdicts — there is deliberately no captain '
  'UPDATE or DELETE policy, so a filed incident cannot be closed or erased by the '
  'person who filed it.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. trip_events — the captain appends narrative, never touches the audit trail
-- ───────────────────────────────────────────────────────────────────────────────────
-- `update_trip_status` stamps a coded row for every lifecycle transition
-- (`trip_departed`, `boarding_started`, `trip_completed`, …). It runs SECURITY DEFINER
-- as the table owner, so it is unaffected by the policies below.
--
-- The captain writes two kinds of row, both narrative: the station-arrival marker
-- (`markStationArrived`) and the "report to operations" note (`TripStatusDataSource`).
-- Neither names an event_code, so both take the column default `'other'` — the column
-- is NOT NULL, which is why the line drawn below is a denylist of the five codes the
-- state machine owns rather than "must be null". The captain may add to the story, and
-- may not write — or delete — the entries that record a lifecycle transition.

drop policy if exists trip_events_captain_rw on public.trip_events;

create policy trip_events_captain_read on public.trip_events
  for select to authenticated
  using (exists (select 1 from public.operation_trips tr
                  where tr.id = trip_id
                    and tr.driver_id = public.current_driver_id()));

create policy trip_events_captain_append on public.trip_events
  for insert to authenticated
  with check (
    exists (select 1 from public.operation_trips tr
             where tr.id = trip_id
               and tr.driver_id = public.current_driver_id())
    and event_code not in (
      'trip_published', 'boarding_started', 'trip_departed',
      'trip_completed', 'trip_cancelled'
    )
  );

comment on policy trip_events_captain_append on public.trip_events is
  'Captains append narrative events (station arrivals, reports to operations) to their '
  'own trips, which take event_code''s default of ''other''. The five lifecycle codes are '
  'reserved for update_trip_status, so a captain cannot forge a trip_departed. No '
  'captain UPDATE or DELETE policy exists — the trail is append-only to them.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. trip_passengers — the captain works the manifest, does not compose it
-- ───────────────────────────────────────────────────────────────────────────────────
-- The manifest is the record of who paid to be on the vehicle. A captain needs exactly
-- one verb on it — set a rider's boarding status — and had all four.
--
-- Two separate guards, because RLS alone cannot express both:
--   • the policy decides WHICH ROWS and WHICH STATUS VALUES (USING = old row,
--     WITH CHECK = new row);
--   • the trigger decides WHICH COLUMNS, which a policy cannot see.

drop policy if exists trip_passengers_captain_rw on public.trip_passengers;

create policy trip_passengers_captain_read on public.trip_passengers
  for select to authenticated
  using (exists (select 1 from public.operation_trips tr
                  where tr.id = trip_id
                    and tr.driver_id = public.current_driver_id()));

create policy trip_passengers_captain_board on public.trip_passengers
  for update to authenticated
  using (
    exists (select 1 from public.operation_trips tr
             where tr.id = trip_id
               and tr.driver_id = public.current_driver_id())
    -- A cancelled rider is not on this bus, and a completed one already travelled.
    -- Boarding either is a contradiction the manifest should not be able to hold; the
    -- Captain App already hides the control, and this is what makes that binding.
    and status not in ('cancelled', 'completed')
  )
  with check (
    exists (select 1 from public.operation_trips tr
             where tr.id = trip_id
               and tr.driver_id = public.current_driver_id())
    -- The three states a boarding door produces. 'cancelled' is a booking outcome and
    -- 'completed' is written by update_trip_status when the trip finishes.
    and status in ('reserved', 'confirmed', 'no_show')
  );

comment on policy trip_passengers_captain_board on public.trip_passengers is
  'Captains move their own trip''s riders between reserved / confirmed / no_show, and '
  'may not touch a cancelled or completed one. There is no captain INSERT or DELETE '
  'policy: a paying rider cannot be erased from, or invented onto, the manifest.';

-- Column-level guard. A policy sees rows, not columns, so without this a captain could
-- still rewrite a passenger's name, phone, seat or pickup point on a row they are
-- legitimately allowed to update.
create or replace function public.enforce_captain_manifest_scope()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  -- Only constrains captains. Office users reach this table through their own policy
  -- and legitimately edit the manifest; service_role and the definer RPCs are unaffected.
  if public.current_driver_id() is null or public.current_office_id() is not null then
    return new;
  end if;

  if new.passenger_name    is distinct from old.passenger_name
     or new.phone          is distinct from old.phone
     or new.seat_id        is distinct from old.seat_id
     or new.seat_label     is distinct from old.seat_label
     or new.booking_id     is distinct from old.booking_id
     or new.customer_id    is distinct from old.customer_id
     or new.trip_id        is distinct from old.trip_id
     or new.pickup_point_id  is distinct from old.pickup_point_id
     or new.dropoff_point_id is distinct from old.dropoff_point_id
     or new.payment_method is distinct from old.payment_method then
    raise exception 'captain_may_only_set_passenger_status';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_captain_manifest_scope on public.trip_passengers;
create trigger trg_enforce_captain_manifest_scope
  before update on public.trip_passengers
  for each row execute function public.enforce_captain_manifest_scope();

comment on function public.enforce_captain_manifest_scope() is
  'A captain may change a manifest row''s status and nothing else. RLS can gate the row '
  'and the new status but not the column set, which is what this closes.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 4. captain_messages — authorship is established, not asserted
-- ───────────────────────────────────────────────────────────────────────────────────
-- `sender_type` is what the Captain App reads to decide whether a message is the
-- captain's own (it was already the subject of one defect, when the app tried to derive
-- it from the display name instead). It was writable as anything: a captain could post
-- a message into their own thread stamped `operations`, producing what reads on both
-- ends as an instruction from the office. They could also edit or delete messages the
-- office had already sent.

drop policy if exists captain_messages_driver on public.captain_messages;

create policy captain_messages_captain_read on public.captain_messages
  for select to authenticated
  using (exists (select 1 from public.operation_trips t
                  where t.id = trip_id
                    and t.driver_id = public.current_driver_id()));

create policy captain_messages_captain_send on public.captain_messages
  for insert to authenticated
  with check (
    exists (select 1 from public.operation_trips t
             where t.id = trip_id
               and t.driver_id = public.current_driver_id())
    and sender_type = 'driver'
    and sender_id = auth.uid()
  );

comment on policy captain_messages_captain_send on public.captain_messages is
  'A captain may only post as themselves: sender_type driver, sender_id their own uid. '
  'No UPDATE or DELETE — neither side of an operational thread may be rewritten after '
  'the fact.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 5. trip_live_locations — close the write hole, leave the read path alone
-- ───────────────────────────────────────────────────────────────────────────────────
-- This table runs without RLS by design, so realtime delivery to client tracking maps
-- works (20260723120000). That decision is about READS, and it is preserved here
-- exactly: SELECT stays open to anon and authenticated, nothing about delivery changes.
--
-- What was never intended is that the same arrangement handed `anon` INSERT, UPDATE and
-- DELETE on every vehicle position on the platform. The anon key ships inside the client
-- app, so this was reachable by anyone who has the app: erase the table and every
-- customer's map goes dark mid-trip; insert rows and a customer watches their bus drive
-- somewhere it is not.
--
-- Writes are now: INSERT only, authenticated only, and the trigger below is what makes
-- the row honest — with no RLS there is no policy to do it.

revoke insert, update, delete, truncate on public.trip_live_locations from anon;
revoke        update, delete, truncate on public.trip_live_locations from authenticated;

create or replace function public.enforce_live_location_authorship()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_driver uuid := public.current_driver_id();
begin
  -- The definer RPCs and any service_role job run without a driver identity and are not
  -- what this guards; the hole was a client-side caller, and a client-side caller always
  -- resolves to a driver or to nobody.
  if auth.uid() is null then
    return new;
  end if;

  if v_driver is null then
    raise exception 'live_location_requires_captain';
  end if;

  -- The stamped driver is the signed-in captain, never whatever the caller sent.
  new.driver_id := v_driver;

  if not exists (select 1 from public.operation_trips t
                  where t.id = new.trip_id and t.driver_id = v_driver) then
    raise exception 'live_location_not_your_trip';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_live_location_authorship on public.trip_live_locations;
create trigger trg_enforce_live_location_authorship
  before insert on public.trip_live_locations
  for each row execute function public.enforce_live_location_authorship();

comment on function public.enforce_live_location_authorship() is
  'trip_live_locations has no RLS so realtime delivery to client maps works; this is the '
  'write-side boundary that replaces it. A signed-in caller must be an active captain '
  'and must own the trip, and driver_id is overwritten with the server-resolved captain '
  'rather than trusted from the payload. Reads are deliberately untouched.';
