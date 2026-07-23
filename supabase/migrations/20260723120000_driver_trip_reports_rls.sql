-- ═══════════════════════════════════════════════════════════════════════════════════
-- driver_trip_reports: restore row-level security
-- ═══════════════════════════════════════════════════════════════════════════════════
-- `driver_trip_reports` is where the Captain App files incident and SOS reports
-- (`supabase_incident_datasource.dart`). The original schema
-- (`migration_02_three_app_architecture.sql`) created it WITH row-level security and
-- two correct policies — driver inserts own, driver reads own.
--
-- `all_app_scheme.sql` (the anon-era dashboard schema) then blanket-disabled RLS
-- across a long list of tables. The multi-office hardening sweep
-- (`20260721090200_multi_office_rls.sql`) re-enabled it on ~22 of them, but
-- `driver_trip_reports` was not in that list. It was overlooked — unlike
-- `trip_live_locations`, which is deliberately left open so realtime delivery to
-- client maps works, there is no delivery reason to keep this table readable.
--
-- The result, verified against the live database on 2026-07-23: the two policies
-- are still defined but inert, and `anon` retains SELECT/INSERT/UPDATE/DELETE. An
-- unauthenticated visitor could read every incident report on the platform, delete
-- all of them, and forge an SOS attributed to a real captain. Empirically confirmed:
-- anon SELECT and anon DELETE both succeeded, and a forged report naming a real
-- driver inserted successfully.
--
-- Nothing outside the Captain App's insert reads this table today — the Dashboard has
-- no incident surface yet — so enabling RLS breaks no existing flow. The office policy
-- below is written now so the Dashboard's future incident view is already scoped.

alter table public.driver_trip_reports enable row level security;

-- The original pair, replaced by the multi-office convention: identity comes from the
-- server-resolved helpers, not from a re-derived subquery on `drivers`.
drop policy if exists "Drivers can insert trip reports"   on public.driver_trip_reports;
drop policy if exists "Drivers can view their own reports" on public.driver_trip_reports;

-- A captain files and reads their own reports, and only their own.
drop policy if exists driver_trip_reports_captain_rw on public.driver_trip_reports;
create policy driver_trip_reports_captain_rw on public.driver_trip_reports
  for all to authenticated
  using      (driver_id = public.current_driver_id())
  with check (driver_id = public.current_driver_id());

-- Operations sees the reports filed on its own office's trips.
drop policy if exists driver_trip_reports_office_manage on public.driver_trip_reports;
create policy driver_trip_reports_office_manage on public.driver_trip_reports
  for all to authenticated
  using (exists (select 1 from public.operation_trips tr
                  where tr.id = trip_id and tr.office_id = public.current_office_id()))
  with check (exists (select 1 from public.operation_trips tr
                       where tr.id = trip_id and tr.office_id = public.current_office_id()));

-- An incident report is never anonymous traffic.
revoke all on public.driver_trip_reports from anon;
grant select, insert, update on public.driver_trip_reports to authenticated;

comment on table public.driver_trip_reports is
  'Captain-filed incident and SOS reports. RLS: a captain reads/writes only rows '
  'carrying their own driver_id; office staff see reports on their own office''s '
  'trips. Not readable by anon — restored 20260723120000 after the multi-office '
  'RLS sweep missed this table.';
