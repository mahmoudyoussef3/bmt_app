-- The Dashboard runs without an auth session (single-owner, no login screen),
-- so it reads and reviews the captain queue as the anon role — exactly like the
-- other operational tables (drivers, vehicles, routes, support_tickets), which
-- all have RLS disabled. The authenticated-only policies added with the table
-- made the queue invisible to the Dashboard (anon SELECT returned nothing).
--
-- Drop those policies and disable RLS so captain_requests matches the rest of
-- the operational schema. Captain-side submission + status polling continue to
-- flow through the SECURITY DEFINER RPCs (submit_captain_request /
-- get_captain_request_status), which are unaffected.

drop policy if exists "authenticated read captain requests" on public.captain_requests;
drop policy if exists "authenticated review captain requests" on public.captain_requests;

alter table public.captain_requests disable row level security;
