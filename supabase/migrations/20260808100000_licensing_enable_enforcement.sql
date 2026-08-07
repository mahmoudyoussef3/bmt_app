-- ═══════════════════════════════════════════════════════════════════════════════════
-- EWT Entitlement Platform — enforcement ON
--
-- Design: docs/architecture/PLATFORM_LICENSING.md Part 15 step 5, decision 8.
--
-- This migration does one thing. It is deliberately alone in its own file, because
-- it is the only change in the whole subsystem that alters behaviour for a live
-- office, and it must be revertible by reading a single line.
--
--     off        → the subsystem resolves, records and enforces nothing
--     shadow     → it evaluates and logs to platform_quota_violations, blocks nothing
--     enforcing  → it blocks
--
-- ── Why now, and what replaced the shadow period ────────────────────────────────────
--
-- §15.2 step 4 asks for a shadow period of at least one billing cycle before this
-- flip. Its stated purpose is precise: "a non-empty violations table in shadow means
-- a limit is wrong, not that a customer is cheating — this is how the seeded numbers
-- get corrected before they can hurt anyone."
--
-- That risk does not exist here, and saying so is more honest than performing the
-- ritual. All three live offices are on `founder`, which is `"unlimited"` in every
-- enforced limit and `true` in every enforced boolean. There is no seeded number
-- that could be wrong for them, because no number applies to them at all. A shadow
-- period would observe an empty table for a month and teach nobody anything.
--
-- What the shadow period WOULD have caught — gates that fire where they should not,
-- and gates that do not exist where the catalog says they do — was instead found by
-- the pre-enforcement audit and closed in 20260808090000, and is now asserted by
-- 96 checks in supabase/tests/licensing_authority_regression.sql, including the
-- three that matter most on this day:
--
--     T1  every incumbent shipped on founder, active, unheld
--     T2  the founder plan is unlimited in every enforced limit
--     T4  no listed office was delisted by the flip
--
-- ── The kill switch stays a kill switch ────────────────────────────────────────────
--
--     update public.platform_settings set enforcement_mode = 'off' where id;
--
-- One row, no deploy, and — since 20260808090000 made every gate mode-aware and
-- reprojects licensing_hold when the mode moves — genuinely instantaneous and
-- genuinely complete. That property is tested (section R), because a kill switch
-- nobody has pulled is a kill switch nobody knows works.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ── Refuse to flip onto a broken foundation ────────────────────────────────────────
--
-- Three preconditions, checked rather than assumed. Each one, if false, would turn
-- this migration into an outage for a paying tenant.
do $$
declare
  v_bad text;
begin
  -- 1. Nobody is left without a licence. An office with no license row resolves to
  --    the default signup plan (F5), which is `starter` — five drivers. For an
  --    incumbent that is not a downgrade, it is a lockout.
  select string_agg(o.name, ', ') into v_bad
    from public.offices o
   where not exists (select 1 from public.office_licenses l where l.office_id = o.id);
  if v_bad is not null then
    raise exception 'REFUSING TO ENFORCE: offices with no licence row: %', v_bad;
  end if;

  -- 2. No office is already over an enforced limit. Enforcement gates creation and
  --    never existence (§5.4), so this would not break them — but it would put them
  --    in a state they never agreed to, and the platform owner should decide that
  --    deliberately rather than discover it.
  select string_agg(o.name || '/' || f.key, ', ') into v_bad
    from public.offices o
   cross join public.platform_features f
   where f.value_type = 'limit'
     and f.enforcement_status = 'enforced'
     and f.meter_kind = 'stock'
     and (public.platform_resolve_feature(o.id, null, f.key) #>> '{value}') <> 'unlimited'
     and public.office_usage_stock(o.id, f.key)
         > (public.platform_resolve_feature(o.id, null, f.key) #>> '{value}')::bigint;
  if v_bad is not null then
    raise exception 'REFUSING TO ENFORCE: offices already over an enforced limit: %', v_bad;
  end if;

  -- 3. The suspension fallback exists. Without it, rung 1 falls back to the
  --    office's own plan and a suspended office keeps everything it was suspended
  --    for.
  if not exists (select 1 from public.platform_settings
                  where restricted_plan_id is not null) then
    raise exception 'REFUSING TO ENFORCE: platform_settings.restricted_plan_id is null';
  end if;
end $$;


-- ── The flip ───────────────────────────────────────────────────────────────────────
--
-- The audit row is written by the trigger on platform_settings, so the moment and
-- the actor are recorded without this migration asking. Updating the row also fires
-- trg_settings_project_holds (20260808090000 §9), which recomputes licensing_hold
-- for every office against the new mode — so no office is left carrying a hold that
-- was computed under the old one.
update public.platform_settings
   set enforcement_mode = 'enforcing',
       updated_at       = now()
 where id;


-- ── And the default, so a fresh database starts enforcing ──────────────────────────
--
-- 20260807090000 defaulted the column to 'off' because that was the correct state to
-- ship into a live platform mid-rollout. A database created from these migrations
-- today should come up enforcing: the alternative is a new environment that silently
-- honours no limits and behaves unlike production until somebody notices.
alter table public.platform_settings
  alter column enforcement_mode set default 'enforcing';

comment on column public.platform_settings.enforcement_mode is
  'off | shadow | enforcing. The subsystem kill switch, and the only row in the '
  'platform whose value changes behaviour for every tenant at once. Enforcing since '
  '20260808100000. Setting it to ''off'' disables every gate instantly and without a '
  'deploy — every gate is mode-aware and licensing_hold is reprojected on change.';
