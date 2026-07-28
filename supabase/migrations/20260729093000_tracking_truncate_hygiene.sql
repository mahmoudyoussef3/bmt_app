-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 6 addendum — TRUNCATE is not gated by row-level security
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Row-level security gates SELECT, INSERT, UPDATE and DELETE. It does not gate
-- TRUNCATE. A role holding the TRUNCATE privilege empties the table outright, with
-- every policy on it intact and irrelevant.
--
-- Supabase's default grants hand `anon` and `authenticated` the full privilege set
-- on tables created in `public`, TRUNCATE included, and every phase of this audit so
-- far has reasoned about those tables in terms of policies. Measured on the live
-- database:
--
--     set local role authenticated;
--     truncate public.driver_trip_reports;   -- accepted
--     truncate public.operation_bookings;    -- privilege check passed; stopped only
--                                            -- by a foreign key, which CASCADE bypasses
--
-- The incident queue is the one that belongs to this phase. `driver_trip_reports`
-- carries the captain's SOS and breakdown reports and is the sole feed behind the
-- Live Operations Center's incident board: emptying it means every open incident on
-- the platform disappears from the operators' screens at once, with no error and
-- nothing in the UI to indicate anything was ever there.
--
-- ── Reachability, stated honestly ────────────────────────────────────────────────
-- PostgREST issues no TRUNCATE, so this is not reachable through the REST API with
-- the anon key alone the way the Phase 6 read hole was. It becomes reachable the
-- moment anything runs caller-supplied SQL, any SECURITY INVOKER function uses
-- dynamic SQL, or the database port is reachable directly. It is a latent privilege
-- that nothing legitimate uses — no client role has any reason to truncate anything
-- — so it costs nothing to give up and removes a whole class of future accident.
--
-- ── Scope ────────────────────────────────────────────────────────────────────────
-- Only the tables this phase's tracking surfaces depend on. The same grant is
-- present on roughly forty-five tables across the schema; sweeping all of them is a
-- platform-wide grant-hygiene change and is recommended as its own piece of work in
-- TRACKING_STATUS.md rather than smuggled in under a tracking migration.
-- ═══════════════════════════════════════════════════════════════════════════════════

-- The captain's incident and SOS queue — the Live Ops incident board's only feed.
revoke truncate on public.driver_trip_reports from anon, authenticated;

-- The trip's operational event trail. The Client tracking screen infers trip state
-- from it (`trip_events` is how a status flip reaches a rider, since clients hold no
-- read policy on `operation_trips`), so emptying it strands every live tracking
-- session on a stale state.
revoke truncate on public.trip_events from anon, authenticated;

-- The stops the tracking map draws, and the manifest rows the rider's own progress
-- is read from.
revoke truncate on public.trip_route_points from anon, authenticated;
revoke truncate on public.trip_passengers  from anon, authenticated;

comment on table public.driver_trip_reports is
  'Captain-filed incidents and SOS. TRUNCATE is revoked from the client roles: RLS '
  'does not gate TRUNCATE, so the policies on this table would not have stopped a '
  'caller from emptying the entire incident queue in one statement.';
