-- ═══════════════════════════════════════════════════════════════════════════════════
-- EWT Entitlement Platform — realtime completion
--
-- Design: docs/architecture/PLATFORM_LICENSING.md §7.4, and the post-implementation
-- note that added office_licenses to the publication (20260807150000).
--
-- ── The gap ─────────────────────────────────────────────────────────────────────────
--
-- §7.4 requires an open console to pick up a licensing change without a refresh.
-- 20260807150000 put `office_licenses` in the publication, which covers a plan
-- ASSIGNMENT and a SUSPENSION. It does not cover the other three ways the answer
-- changes:
--
--   * an OVERRIDE      — office_feature_overrides, the highest-priority rung (§4.1)
--   * a PLAN EDIT      — platform_plan_features, which §2.5 requires to propagate live
--   * a KILL SWITCH    — platform_features.status = 'disabled', platform-wide
--
-- The Phase-2 comment argued these were "a handful per month, and the next sign-in
-- picks them up". That is true of frequency and false of expectation: an operator on
-- the phone with the platform owner while an override is granted must see it land.
-- Enforcement makes the difference visible, so the argument no longer holds.
--
-- ── Why this is safe to publish ─────────────────────────────────────────────────────
--
-- Realtime applies RLS to every change it forwards, using the subscriber's own JWT:
--
--   office_feature_overrides  — select policy is office_id = current_office_id()
--                               or is_platform_admin(). An office sees only its own.
--   platform_plan_features    — select policy is the catalogue read, granted to
--                               authenticated for non-draft plans. Plan contents are
--                               already readable by any office (§13.3) so it can learn
--                               what plans exist; publishing them leaks nothing new.
--   platform_features         — same catalogue read.
--
-- No tenant-scoped row reaches an office that could not already select it.
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'office_feature_overrides',
    'platform_plan_features',
    'platform_features'
  ] loop
    if not exists (
      select 1
        from pg_publication_rel pr
        join pg_class c      on c.oid = pr.prrelid
        join pg_namespace n  on n.oid = c.relnamespace
        join pg_publication p on p.oid = pr.prpubid
       where p.pubname = 'supabase_realtime'
         and n.nspname = 'public'
         and c.relname = v_table
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I', v_table);
    end if;
  end loop;
end $$;


-- Realtime needs the full row to build a payload the client can filter on. The
-- licensing tables are small and change a handful of times a month, so the WAL cost
-- of REPLICA IDENTITY FULL is nil, and without it a DELETE (an override being
-- cleared — the case that matters most) arrives carrying only its primary key.
alter table public.office_feature_overrides replica identity full;
alter table public.platform_plan_features   replica identity full;
alter table public.platform_features        replica identity full;
