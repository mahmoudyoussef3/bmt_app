-- ═══════════════════════════════════════════════════════════════════════════════════
-- Drift repair: bring the recorded boarding boundary in line with production
--
-- This migration changes nothing on the linked database. It exists because the
-- database and the migration history had come apart, and the history was the
-- weaker of the two.
--
-- ── What was found ───────────────────────────────────────────────────────────────
--
-- `20260729090000_tracking_authority.sql` defines the passenger arm of
-- `can_read_trip_fixes` as:
--
--     and b.status in ('confirmed', 'boarded', 'completed')
--
-- The function actually deployed admits only:
--
--     and b.status = 'confirmed'
--
-- with a comment of its own recording the intent: "`reserved` (payment pending)
-- and `cancelled` never could; `boarded` and `completed` no longer can." So the
-- boarding rule — a rider who boards stops receiving the waiting-stage feed — *is*
-- enforced server-side today, and the two Dart comments that say the database is
-- the half that matters are accurate.
--
-- What was not true is the repository. Anyone rebuilding this schema from
-- migrations — a new environment, a restore, a reviewer reading the history to
-- learn where the boundary is — would have got the wider version, and a boarded
-- rider would have kept streaming the vehicle for the rest of the journey. A
-- security boundary that lives only in a deployed function and not in the history
-- is one `supabase db reset` away from being gone.
--
-- ── What this does ───────────────────────────────────────────────────────────────
--
-- Restates the deployed definition verbatim, so replaying the history produces the
-- boundary that is actually in force. Verified as a no-op against the linked
-- database: probed inside `begin … rollback` before being written, and the
-- resulting definition matches what is already there.
--
-- Regression coverage: `supabase/tests/boarding_tracking_boundary_regression.sql`.
-- ═══════════════════════════════════════════════════════════════════════════════════

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

    -- The captain driving it, who is the author of these rows. Boarding a
    -- passenger does not stop the captain publishing, and must not — every rider
    -- still waiting further down the route is watching the same vehicle.
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
  'operating office, the assigned captain, or a passenger who is still WAITING for '
  'the vehicle (booking `confirmed`) — nobody else. A boarded rider is deliberately '
  'excluded: boarding ends the waiting-stage feed, and that is enforced here rather '
  'than only in the app, while the captain keeps publishing for everyone still at a '
  'stop. Note the Client app''s `TrackingTripQuery.trackableStatuses` is wider on '
  'purpose (confirmed/boarded/completed) — that decides who may OPEN the tracking '
  'screen and see their own stops, not who may read positions. SECURITY DEFINER '
  'because it is called from an RLS policy on a realtime-published table and joins '
  'tables the reader has no read policy on; written the obvious way a policy '
  'silently denies everyone and the table ends up left open instead.';
