-- ═══════════════════════════════════════════════════════════════════════════════════
-- Licensing — realtime delivery for the office's own licence row
-- ═══════════════════════════════════════════════════════════════════════════════════
-- `EntitlementService` subscribes to `office_licenses` filtered on the caller's
-- office, so that a plan change or a suspension reaches a console that is already
-- open. Without the table in the publication that subscription is a channel to
-- silence: it connects, it never errors, and it never fires — the failure mode
-- that made the live-location work hard to trust.
--
-- Read authority is unchanged. `office_licenses_read` already restricts SELECT to
-- `office_id = current_office_id() or is_platform_admin()`, and Realtime evaluates
-- that same policy per subscriber. Both helpers are SECURITY DEFINER and executable
-- by `authenticated`, which is what lets the policy evaluate inside the Realtime
-- path rather than silently denying — the pattern established for
-- `trip_live_locations`.
--
-- Only `office_licenses` is published. Overrides, usage counters and invoices are
-- deliberately left out: they change on a platform-side cadence measured in a few
-- edits per month, and the next sign-in or an explicit refresh picks them up. A
-- channel per table would cost every signed-in console a connection to carry
-- traffic that does not exist.

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'office_licenses'
    ) then
      alter publication supabase_realtime add table public.office_licenses;
    end if;
  end if;
end $$;
