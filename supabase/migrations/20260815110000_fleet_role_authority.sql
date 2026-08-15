-- ═══════════════════════════════════════════════════════════════════════════════════
-- Fleet role authority
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 1.1 of the dashboard roadmap. Closes P0-2 of docs/dashboard/DASHBOARD_AUDIT.md
-- and the OPEN item in docs/dashboard/DASHBOARD_SECURITY.md §3.
--
-- ── The gap ────────────────────────────────────────────────────────────────────────
-- `office_role()` separates owner from support agent on `offices`, `office_users`, the
-- wallet policy table, the captain join code and logo storage. It was never applied to
-- the fleet. All five fleet tables carried a single
--
--     for all to authenticated using (office_id = public.current_office_id())
--
-- policy: office-scoped, but identical for a `dashboard_admin` and a `support_agent`.
-- The only thing keeping a support agent from editing or deleting the office's drivers
-- and vehicles was the Flutter permission map — and DASHBOARD_SECURITY.md §1 says out
-- loud that nothing above the Postgres line is load-bearing. A support agent holding
-- the office session could `PATCH /rest/v1/drivers` or `DELETE /rest/v1/vehicles`
-- directly and the database would have obliged.
--
-- This is also the `for all` bug class listed in DASHBOARD_SECURITY.md §8 item 5,
-- which had already got in twice before.
--
-- ── What changes ───────────────────────────────────────────────────────────────────
-- Each `for all` policy is split into an explicit `select` policy and three explicit
-- write policies. The read predicate is copied verbatim from the policy it replaces —
-- so no read changes for anyone — and the write predicates gain one conjunct:
--
--     and public.office_role() = 'dashboard_admin'
--
-- Same shape as `office_wallet_policies_update` in 20260806090000, deliberately, so
-- the schema keeps one way of expressing "the owner, in their own office".
--
-- ── Why reads are NOT restricted ───────────────────────────────────────────────────
-- `drivers` holds phone, emergency_phone, address, national_id and license_number, and
-- the permission model says a support agent should not see them. Withholding the rows
-- is nevertheless the wrong move *here*, because four surfaces a support agent is
-- entitled to embed driver and vehicle rows through PostgREST:
--
--     live ops          driver:drivers(full_name, phone)  — the desk calls the driver
--     bookings          driver:drivers(full_name)
--     payment review    driver:drivers(full_name)
--     reports           drivers.full_name, vehicles.plate_number for the filter lists
--
-- and Home reads all five tables for every role through GetFleetWorkspaceUseCase.
-- Restricting reads returns zero rows rather than an error, so a support agent's Home
-- would quietly report "0 مركبة / 0 سائق / 0 مهام نشطة" for an office that has twelve
-- of each. A console that fabricates a zero is worse than one that shows a name it
-- should not — and the whole module refuses to fabricate a metric elsewhere.
--
-- Hiding the *columns* is the correct fix and it is a different change: RLS filters
-- rows, not columns, and both roles arrive as the same Postgres role (`authenticated`)
-- with the office role living in a table, so column GRANTs cannot separate them
-- either. It needs a sanitised definer view plus rewrites of those four datasources.
-- Tracked as the follow-up in DASHBOARD_SECURITY.md §3; deliberately not folded in.
--
-- ── What is preserved ──────────────────────────────────────────────────────────────
-- Office isolation   every predicate keeps `= public.current_office_id()`, and the
--                    document tables keep resolving it through their parent row, so a
--                    document can still never be attached to another office's driver.
-- Licensing          untouched. Quotas (trg_quota_drivers, trg_quota_vehicles,
--                    trg_quota_captains, …) and the read-only gate
--                    (trg_readonly_drivers/vehicles/assignments) are BEFORE triggers
--                    and run independently of RLS. RLS narrows *who* may attempt a
--                    write; licensing still decides whether that write is allowed.
-- Captain app        `drivers_self_read` and `vehicles_captain_read` are SELECT-only
--                    and are not touched. Both were already unable to write — a
--                    captain has no office_users row, so current_office_id() is null.
-- RPCs               all 25 functions that touch these tables are SECURITY DEFINER and
--                    bypass RLS: office_create_trip, link_current_captain_driver,
--                    captain_session_context, refresh_driver_rating,
--                    end_assignments_on_fleet_status_change, vehicle_trip_seats, the
--                    platform console readers, and the rest. None is affected.
-- Definer views      public_driver_profiles / public_vehicle_profiles are
--                    security_invoker=false and unaffected. public_trips,
--                    drivers_performance_view and vehicles_efficiency_view are
--                    postgres-owned and likewise unaffected.
--
-- ── Blocked workflows ──────────────────────────────────────────────────────────────
-- None that exist. A support agent's permission set is liveOps, bookings, tickets,
-- reports, paymentVerification, notifications and customerWallets; not one of those
-- writes a fleet table, and every state change they can make already goes through a
-- definer RPC. The fleet module, the trip planner and captain-request approval are all
-- owner-gated and keep full write access.
--
-- Additive nothing, subtractive one thing: a support agent can no longer write to the
-- fleet. That is the point.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. drivers
--
-- `drivers_self_read` stays exactly as it was: a captain reads their own row by
-- user_id, which is how captain_office_id() and the captain profile screen work. It is
-- SELECT-only and grants no write, then or now.
-- ───────────────────────────────────────────────────────────────────────────────────
drop policy if exists drivers_office_manage on public.drivers;

drop policy if exists drivers_office_read on public.drivers;
create policy drivers_office_read on public.drivers
  for select to authenticated
  using (office_id = public.current_office_id());

drop policy if exists drivers_office_insert on public.drivers;
create policy drivers_office_insert on public.drivers
  for insert to authenticated
  with check (office_id = public.current_office_id()
              and public.office_role() = 'dashboard_admin');

-- The `with check` is not redundant with the `using`: without it an owner could move a
-- driver — national ID, licence and all — into another office by rewriting office_id.
drop policy if exists drivers_office_update on public.drivers;
create policy drivers_office_update on public.drivers
  for update to authenticated
  using      (office_id = public.current_office_id()
              and public.office_role() = 'dashboard_admin')
  with check (office_id = public.current_office_id()
              and public.office_role() = 'dashboard_admin');

drop policy if exists drivers_office_delete on public.drivers;
create policy drivers_office_delete on public.drivers
  for delete to authenticated
  using (office_id = public.current_office_id()
         and public.office_role() = 'dashboard_admin');


-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. vehicles
--
-- `vehicles_captain_read` stays: a captain needs the vehicle attached to their trips.
-- ───────────────────────────────────────────────────────────────────────────────────
drop policy if exists vehicles_office_manage on public.vehicles;

drop policy if exists vehicles_office_read on public.vehicles;
create policy vehicles_office_read on public.vehicles
  for select to authenticated
  using (office_id = public.current_office_id());

drop policy if exists vehicles_office_insert on public.vehicles;
create policy vehicles_office_insert on public.vehicles
  for insert to authenticated
  with check (office_id = public.current_office_id()
              and public.office_role() = 'dashboard_admin');

drop policy if exists vehicles_office_update on public.vehicles;
create policy vehicles_office_update on public.vehicles
  for update to authenticated
  using      (office_id = public.current_office_id()
              and public.office_role() = 'dashboard_admin')
  with check (office_id = public.current_office_id()
              and public.office_role() = 'dashboard_admin');

drop policy if exists vehicles_office_delete on public.vehicles;
create policy vehicles_office_delete on public.vehicles
  for delete to authenticated
  using (office_id = public.current_office_id()
         and public.office_role() = 'dashboard_admin');


-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. assignments
--
-- No captain policy here and none is added: the captain app never reads `assignments`
-- directly. `driver_active_vehicle()` resolves the pairing for it and is definer.
-- ───────────────────────────────────────────────────────────────────────────────────
drop policy if exists assignments_office_manage on public.assignments;

drop policy if exists assignments_office_read on public.assignments;
create policy assignments_office_read on public.assignments
  for select to authenticated
  using (office_id = public.current_office_id());

drop policy if exists assignments_office_insert on public.assignments;
create policy assignments_office_insert on public.assignments
  for insert to authenticated
  with check (office_id = public.current_office_id()
              and public.office_role() = 'dashboard_admin');

drop policy if exists assignments_office_update on public.assignments;
create policy assignments_office_update on public.assignments
  for update to authenticated
  using      (office_id = public.current_office_id()
              and public.office_role() = 'dashboard_admin')
  with check (office_id = public.current_office_id()
              and public.office_role() = 'dashboard_admin');

drop policy if exists assignments_office_delete on public.assignments;
create policy assignments_office_delete on public.assignments
  for delete to authenticated
  using (office_id = public.current_office_id()
         and public.office_role() = 'dashboard_admin');


-- ───────────────────────────────────────────────────────────────────────────────────
-- 4. driver_documents
--
-- No office_id column: the scope is resolved through the parent driver, as before.
-- Written out per table rather than generated in a loop, because a security policy
-- should be greppable by name in the source that created it.
-- ───────────────────────────────────────────────────────────────────────────────────
drop policy if exists driver_documents_office_manage on public.driver_documents;

drop policy if exists driver_documents_office_read on public.driver_documents;
create policy driver_documents_office_read on public.driver_documents
  for select to authenticated
  using (exists (select 1 from public.drivers p
                  where p.id = driver_id
                    and p.office_id = public.current_office_id()));

drop policy if exists driver_documents_office_insert on public.driver_documents;
create policy driver_documents_office_insert on public.driver_documents
  for insert to authenticated
  with check (public.office_role() = 'dashboard_admin'
              and exists (select 1 from public.drivers p
                           where p.id = driver_id
                             and p.office_id = public.current_office_id()));

-- Both clauses carry the parent test: the `using` stops an owner touching another
-- office's document, the `with check` stops them re-pointing one of theirs at another
-- office's driver.
drop policy if exists driver_documents_office_update on public.driver_documents;
create policy driver_documents_office_update on public.driver_documents
  for update to authenticated
  using      (public.office_role() = 'dashboard_admin'
              and exists (select 1 from public.drivers p
                           where p.id = driver_id
                             and p.office_id = public.current_office_id()))
  with check (public.office_role() = 'dashboard_admin'
              and exists (select 1 from public.drivers p
                           where p.id = driver_id
                             and p.office_id = public.current_office_id()));

drop policy if exists driver_documents_office_delete on public.driver_documents;
create policy driver_documents_office_delete on public.driver_documents
  for delete to authenticated
  using (public.office_role() = 'dashboard_admin'
         and exists (select 1 from public.drivers p
                      where p.id = driver_id
                        and p.office_id = public.current_office_id()));


-- ───────────────────────────────────────────────────────────────────────────────────
-- 5. vehicle_documents
--
-- Included even though the audit names four tables. It is the sibling of
-- driver_documents, created by the same loop in 20260721090200 and written by the same
-- datasource method; gating one and leaving the other is a hole with a paper trail.
-- ───────────────────────────────────────────────────────────────────────────────────
drop policy if exists vehicle_documents_office_manage on public.vehicle_documents;

drop policy if exists vehicle_documents_office_read on public.vehicle_documents;
create policy vehicle_documents_office_read on public.vehicle_documents
  for select to authenticated
  using (exists (select 1 from public.vehicles p
                  where p.id = vehicle_id
                    and p.office_id = public.current_office_id()));

drop policy if exists vehicle_documents_office_insert on public.vehicle_documents;
create policy vehicle_documents_office_insert on public.vehicle_documents
  for insert to authenticated
  with check (public.office_role() = 'dashboard_admin'
              and exists (select 1 from public.vehicles p
                           where p.id = vehicle_id
                             and p.office_id = public.current_office_id()));

drop policy if exists vehicle_documents_office_update on public.vehicle_documents;
create policy vehicle_documents_office_update on public.vehicle_documents
  for update to authenticated
  using      (public.office_role() = 'dashboard_admin'
              and exists (select 1 from public.vehicles p
                           where p.id = vehicle_id
                             and p.office_id = public.current_office_id()))
  with check (public.office_role() = 'dashboard_admin'
              and exists (select 1 from public.vehicles p
                           where p.id = vehicle_id
                             and p.office_id = public.current_office_id()));

drop policy if exists vehicle_documents_office_delete on public.vehicle_documents;
create policy vehicle_documents_office_delete on public.vehicle_documents
  for delete to authenticated
  using (public.office_role() = 'dashboard_admin'
         and exists (select 1 from public.vehicles p
                      where p.id = vehicle_id
                        and p.office_id = public.current_office_id()));


-- ───────────────────────────────────────────────────────────────────────────────────
-- 6. Documentation
-- ───────────────────────────────────────────────────────────────────────────────────
comment on table public.drivers is
  'Office drivers. Readable by any active member of the owning office (four support '
  'surfaces embed full_name/phone) and by the captain themselves; writable only by '
  'that office''s dashboard_admin. Column-level PII withholding is a follow-up.';

comment on table public.vehicles is
  'Office vehicles. Readable by any active member of the owning office and by that '
  'office''s captains; writable only by that office''s dashboard_admin.';

comment on table public.assignments is
  'Driver↔vehicle pairings. Readable by any active member of the owning office; '
  'writable only by that office''s dashboard_admin.';

comment on table public.driver_documents is
  'Licence and ID scans, scoped through drivers.office_id. Writable only by that '
  'office''s dashboard_admin.';

comment on table public.vehicle_documents is
  'Vehicle papers, scoped through vehicles.office_id. Writable only by that office''s '
  'dashboard_admin.';


-- ───────────────────────────────────────────────────────────────────────────────────
-- 7. Self-verification
--
-- The failure this guards against is the one that produced the finding: a `for all`
-- policy surviving on a fleet table, or a write policy that forgot the role term. Both
-- are silent — the app keeps working, it just permits too much — so the migration
-- refuses to commit rather than leaving that to be noticed later.
-- ───────────────────────────────────────────────────────────────────────────────────
do $$
declare
  v_tables text[] := array['drivers','vehicles','assignments',
                           'driver_documents','vehicle_documents'];
  v_tbl    text;
  v_bad    text;
begin
  foreach v_tbl in array v_tables loop
    -- a. Nothing may remain FOR ALL.
    select string_agg(policyname, ', ') into v_bad
      from pg_policies
     where schemaname = 'public' and tablename = v_tbl and cmd = 'ALL';
    if v_bad is not null then
      raise exception 'fleet_role_authority: % still has FOR ALL policies: %',
        v_tbl, v_bad;
    end if;

    -- b. Every write policy must name the role.
    select string_agg(policyname, ', ') into v_bad
      from pg_policies
     where schemaname = 'public' and tablename = v_tbl
       and cmd in ('INSERT','UPDATE','DELETE')
       and coalesce(qual, '') || coalesce(with_check, '') not like '%office_role%';
    if v_bad is not null then
      raise exception 'fleet_role_authority: % has role-agnostic write policies: %',
        v_tbl, v_bad;
    end if;

    -- c. All three write commands must be covered, or a command falls through to
    --    "no policy", which is a denial today and an invitation to add a loose one
    --    tomorrow.
    if (select count(distinct cmd) from pg_policies
         where schemaname = 'public' and tablename = v_tbl
           and cmd in ('INSERT','UPDATE','DELETE')) <> 3 then
      raise exception 'fleet_role_authority: % is missing a write policy', v_tbl;
    end if;

    -- d. And a read policy must exist, or every consumer above breaks at once.
    if not exists (select 1 from pg_policies
                    where schemaname = 'public' and tablename = v_tbl
                      and cmd = 'SELECT') then
      raise exception 'fleet_role_authority: % has no SELECT policy', v_tbl;
    end if;
  end loop;

  -- e. The two captain read paths must survive. They are the captain app's only
  --    non-definer access to the fleet.
  if not exists (select 1 from pg_policies
                  where schemaname='public' and tablename='drivers'
                    and policyname='drivers_self_read' and cmd='SELECT') then
    raise exception 'fleet_role_authority: drivers_self_read was lost';
  end if;
  if not exists (select 1 from pg_policies
                  where schemaname='public' and tablename='vehicles'
                    and policyname='vehicles_captain_read' and cmd='SELECT') then
    raise exception 'fleet_role_authority: vehicles_captain_read was lost';
  end if;

  raise notice 'fleet_role_authority: 5 tables, 22 policies, all verified';
end $$;
