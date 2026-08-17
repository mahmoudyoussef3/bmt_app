-- ═══════════════════════════════════════════════════════════════════════════════════
-- Boarding boundary — regression probes
--
--     passenger waiting  →  receives vehicle tracking
--     passenger boards   →  no longer receives the waiting-stage feed
--     others waiting     →  keep receiving it
--
-- The third line is why this is per *booking* rather than per trip; the second is the
-- one that is easy to lose, because the app also enforces it and the app enforcing it
-- makes the server side look untested.
--
-- Run:
--   supabase db query --linked -f supabase/tests/boarding_tracking_boundary_regression.sql
--
-- Every row should read OK. `STILL EXPLOITABLE` or `BROKEN` is a regression.
-- Read-only: no transaction needed, nothing is written.
-- ═══════════════════════════════════════════════════════════════════════════════════

with def as (
  select pg_get_functiondef('public.can_read_trip_fixes(uuid)'::regprocedure) as body
)
select probe, result from (
  -- The rule itself. Checked against the status list rather than the prose, so a
  -- comment mentioning the word `boarded` cannot pass or fail this.
  select 1 as ord,
    'a waiting (confirmed) passenger may read positions' as probe,
    case when (select body from def) like '%b.status = ''confirmed''%'
              or (select body from def) like '%''confirmed''%'
         then 'OK' else 'BROKEN — the feature does not work' end as result
  union all
  select 2,
    'a boarded passenger may not',
    case when (select body from def) like '%''boarded''%'
         then 'STILL EXPLOITABLE — boarding no longer ends the feed'
         else 'OK' end
  union all
  select 3,
    'an unpaid (reserved) or cancelled booking may not',
    case when (select body from def) like '%''reserved''%'
           or (select body from def) like '%''cancelled''%'
         then 'STILL EXPLOITABLE' else 'OK' end

  -- The other three arms. Narrowing the passenger arm must not touch them: the
  -- captain publishes for everyone still waiting, and the office watches its fleet.
  union all
  select 4,
    'the assigned captain still reads back what they published',
    case when (select body from def) like '%current_driver_id()%'
         then 'OK' else 'BROKEN — every waiting rider loses their map' end
  union all
  select 5,
    'the operating office still sees its own fleet',
    case when (select body from def) like '%current_office_id()%'
         then 'OK' else 'BROKEN — Live Ops goes dark' end
  union all
  select 6,
    'platform admin remains the one unscoped reader',
    case when (select body from def) like '%is_platform_admin()%'
         then 'OK' else 'BROKEN' end

  -- The shape that makes RLS work with Realtime at all: the policy body touches
  -- only the row's own trip_id, and the joins run inside a definer function.
  union all
  select 7,
    'still SECURITY DEFINER and STABLE',
    case when (select body from def) like '%SECURITY DEFINER%'
          and (select body from def) like '%STABLE%'
         then 'OK' else 'BROKEN — realtime cannot evaluate this per row' end

  -- Both tables that share the helper.
  union all
  select 8,
    'trip_live_locations read policy still calls the helper',
    case when exists (
      select 1 from pg_policies
       where schemaname = 'public' and tablename = 'trip_live_locations'
         and policyname = 'trip_live_locations_read'
         and qual like '%can_read_trip_fixes%'
    ) then 'OK' else 'BROKEN' end
  union all
  select 9,
    'trip_progress_events read policy still calls the helper',
    case when exists (
      select 1 from pg_policies
       where schemaname = 'public' and tablename = 'trip_progress_events'
         and policyname = 'trip_progress_events_read'
         and qual like '%can_read_trip_fixes%'
    ) then 'OK' else 'BROKEN' end

  -- The Phase 6 grants, re-checked here because this file is the one someone runs
  -- after touching the boundary.
  union all
  select 10,
    'anon holds no SELECT on the fix table',
    case when has_table_privilege('anon', 'public.trip_live_locations', 'SELECT')
         then 'STILL EXPLOITABLE' else 'OK' end
  union all
  select 11,
    'anon holds no INSERT on the fix table',
    case when has_table_privilege('anon', 'public.trip_live_locations', 'INSERT')
         then 'STILL EXPLOITABLE' else 'OK' end
  union all
  select 12,
    'nobody may rewrite or erase a reported position',
    case when has_table_privilege('authenticated', 'public.trip_live_locations', 'UPDATE')
           or has_table_privilege('authenticated', 'public.trip_live_locations', 'DELETE')
         then 'STILL EXPLOITABLE' else 'OK' end
  union all
  select 13,
    'only the assigned captain may publish',
    case when exists (
      select 1 from pg_policies
       where schemaname = 'public' and tablename = 'trip_live_locations'
         and policyname = 'trip_live_locations_captain_publish'
         and with_check like '%can_publish_trip_fix%'
    ) then 'OK' else 'BROKEN' end
  union all
  select 14,
    'RLS is enabled on the fix table',
    case when (select relrowsecurity from pg_class
                where oid = 'public.trip_live_locations'::regclass)
         then 'OK' else 'STILL EXPLOITABLE' end
) probes
order by ord;
