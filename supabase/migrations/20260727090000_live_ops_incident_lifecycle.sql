-- ═══════════════════════════════════════════════════════════════════════════════════
-- Live Operations Center: incident lifecycle + office-scoped live position reads
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Two changes, both driven by gaps found auditing the Live Operations Center against
-- the live database on 2026-07-27.
--
-- 1. INCIDENT LIFECYCLE
--    `driver_trip_reports.status` is free text with no CHECK constraint, and the only
--    two values anything writes are 'pending' (Captain App) and 'resolved' (the
--    dashboard's resolve action). That collapses a real operational workflow into a
--    single irreversible click: an operator who has *seen* an SOS and is calling the
--    captain has no way to say so, so a second operator sees the same untouched-looking
--    alarm and calls again. There is also no record of WHO resolved a report or WHY,
--    which makes an incident queue useless for after-the-fact review.
--
--    The lifecycle below is the smallest one that fixes both:
--        pending ──acknowledge──▶ acknowledged ──resolve──▶ resolved
--           └──────────────────── dismiss ────────────────▶ dismissed
--    `acknowledged` means "a human owns this now". `dismissed` is the honest exit for
--    a report that needed no action (a duplicate, a test, a captain mis-tap) and keeps
--    it out of the resolved-work statistics.
--
-- 2. OFFICE-SCOPED LIVE POSITION READS
--    `trip_live_locations` deliberately runs WITHOUT row-level security so realtime
--    delivery to client maps works (see 20260723120000). Every reader therefore has to
--    scope itself. The dashboard did that by resolving its office's active trip ids
--    first and querying `in (ids)` — correct, but it pulled EVERY fix row for those
--    trips with no bound. At the captain's 30s publish cadence a 3-hour trip is ~360
--    rows, so a desk watching 20 active trips re-downloaded ~7,200 rows every 15s poll
--    to use 20 of them.
--
--    `dashboard_active_trip_fixes` replaces that with one DISTINCT ON per trip, served
--    by the existing (trip_id, recorded_at DESC) index, and moves the office check
--    server-side so the open table is never queried directly by the dashboard.

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. Incident lifecycle columns
-- ───────────────────────────────────────────────────────────────────────────────────

alter table public.driver_trip_reports
  add column if not exists acknowledged_at  timestamptz,
  add column if not exists acknowledged_by  uuid references auth.users(id) on delete set null,
  add column if not exists resolved_by      uuid references auth.users(id) on delete set null,
  add column if not exists resolution_note  text;

comment on column public.driver_trip_reports.acknowledged_at is
  'When an operator took ownership of this report. Set on the pending -> acknowledged transition.';
comment on column public.driver_trip_reports.resolution_note is
  'Operator''s free-text account of what was done. Required by the dashboard when resolving or dismissing.';

-- Existing rows predate the lifecycle. Anything already resolved keeps its resolved_at
-- but has no actor — backfilling a fake one would be worse than an honest null.

-- The allowlist. Written as NOT VALID first so a legacy row with an unexpected value
-- can never block the migration; validated immediately after, which surfaces such a
-- row as a clear error instead of silently accepting it.
alter table public.driver_trip_reports
  drop constraint if exists driver_trip_reports_status_check;

alter table public.driver_trip_reports
  add constraint driver_trip_reports_status_check
  check (status in ('pending', 'acknowledged', 'resolved', 'dismissed'))
  not valid;

alter table public.driver_trip_reports
  validate constraint driver_trip_reports_status_check;

-- The incident queue reads "open reports, newest first" on every poll.
create index if not exists idx_driver_trip_reports_status_created
  on public.driver_trip_reports (status, created_at desc);

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. Office-scoped latest fix per active trip
-- ───────────────────────────────────────────────────────────────────────────────────

create or replace function public.dashboard_active_trip_fixes(p_office_id uuid)
returns table (
  trip_id     uuid,
  latitude    double precision,
  longitude   double precision,
  heading     double precision,
  speed       double precision,
  accuracy    double precision,
  recorded_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $$
  -- The office gate. An office user may only ask for their own office; a platform
  -- admin may ask for any. Anyone else gets an empty set, never an error, so a
  -- signed-out race in the UI degrades to "no positions" rather than a red screen.
  select distinct on (l.trip_id)
         l.trip_id, l.latitude, l.longitude, l.heading, l.speed, l.accuracy, l.recorded_at
    from public.trip_live_locations l
    join public.operation_trips t on t.id = l.trip_id
   where t.office_id = p_office_id
     and t.status in ('boarding', 'in_progress')
     and (p_office_id = public.current_office_id() or public.is_platform_admin())
   order by l.trip_id, l.recorded_at desc;
$$;

comment on function public.dashboard_active_trip_fixes(uuid) is
  'Latest live position per active (boarding/in_progress) trip for one office. '
  'SECURITY DEFINER because trip_live_locations has no RLS by design; the office '
  'check inside is what keeps this scoped.';

revoke all on function public.dashboard_active_trip_fixes(uuid) from public, anon;
grant execute on function public.dashboard_active_trip_fixes(uuid) to authenticated;
