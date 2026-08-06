-- ═══════════════════════════════════════════════════════════════════════════════════
-- EWT Entitlement Platform — Phase 5/6 (b): trials, dunning, renewal, state machine
--
-- Design: docs/architecture/PLATFORM_LICENSING.md Part 14, §12, §15.2 step 6.
--
-- ── Transitions belong to ONE authority ────────────────────────────────────────────
--
-- The same discipline 20260727160000_trip_lifecycle_authority.sql applied to trips:
-- a status is changed by platform_set_license_status, platform_assign_plan, or this
-- job — never by whoever happens to be updating the row. Each writes an audit row and
-- an operational alert through the channel that already exists.
--
-- ── The state machine (§14.3) ──────────────────────────────────────────────────────
--
--   trialing ──trial_ends_at──▶ expired ──downgrade_to_plan──▶ active (cycle 'free')
--   active   ──period_end, auto_renew──▶ invoice issued, period advanced
--   active   ──period_end, no auto_renew──▶ expired
--   issued invoice past due_at ──▶ past_due   (grace_ends_at := now + grace_days)
--   past_due ──grace_ends_at──▶ grace         (grace_ends_at := now + warn_days_before)
--   grace    ──grace_ends_at──▶ suspended
--
-- The diagram's two windows are read as: `past_due` is "the invoice is late" and the
-- office is fully operational with a banner; `grace` is the final countdown before
-- the hold lands. Both windows are settings rows, so their lengths are a commercial
-- decision rather than a deploy.
--
-- suspended → expired stays MANUAL. Deciding that a customer is gone is not a thing a
-- cron job should do on its own.
--
-- ── What suspension does, restated where it executes ───────────────────────────────
--
-- It degrades to read-only. It does not black out. The office keeps serving
-- passengers who already hold tickets, its captains keep driving, and a trip already
-- in flight is never interrupted. The gates are on CREATING NEW COMMITMENTS, never on
-- HONOURING EXISTING ONES — and this file is where that promise is either kept or
-- quietly broken, so it is written down here as well as in the design.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. Every new office gets a license (§15.2 step 6, closing F5)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- office_self_signup lets an operator register with no platform admin in the loop, so
-- an office could otherwise exist with no license row at all. The resolver has a
-- defined answer for that (the default plan), but leaving the gap open means "which
-- offices actually have licenses" is a question nobody can answer from the table.
--
-- A trigger rather than an edit to office_self_signup and platform_create_office:
-- there are two signup paths today and any third would have to remember.

create or replace function public.office_assign_default_license()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_plan  public.platform_plans;
  v_trial int;
begin
  select p.* into v_plan
    from public.platform_settings s
    join public.platform_plans p on p.id = s.default_signup_plan_id
   where s.id;

  if not found then
    return null;   -- no default configured: leave it to the platform admin
  end if;

  v_trial := v_plan.trial_days;

  insert into public.office_licenses
    (office_id, plan_id, status, billing_cycle, trial_ends_at,
     period_start, period_end, auto_renew, notes)
  values (
    new.id, v_plan.id,
    case when v_trial > 0 then 'trialing' else 'active' end,
    'monthly',
    case when v_trial > 0 then now() + make_interval(days => v_trial) end,
    now(),
    now() + interval '1 month',
    true,
    'تعيين تلقائي عند إنشاء المكتب')
  on conflict (office_id) do nothing;

  return null;
end;
$$;

drop trigger if exists trg_office_default_license on public.offices;
create trigger trg_office_default_license
  after insert on public.offices
  for each row execute function public.office_assign_default_license();

revoke all on function public.office_assign_default_license() from public, anon, authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. The renewal job (§12)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Idempotent per (office, period) through the unique index on office_invoices, so
-- running it twice in one day bills nobody twice. Whether it fires from pg_cron or an
-- Edge Function is an implementation choice, not an architectural one.

create or replace function public.platform_run_billing_cycle()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lic      record;
  v_new_end  timestamptz;
  v_issued   int := 0;
begin
  perform public.assert_platform_admin_or_system();

  for v_lic in
    select l.*, p.key as plan_key
      from public.office_licenses l
      join public.platform_plans p on p.id = l.plan_id
     where l.auto_renew
       and l.period_end is not null
       and l.period_end <= now()
       and l.status in ('active','past_due','grace')
  loop
    v_new_end := v_lic.period_end + case v_lic.billing_cycle
                                      when 'yearly' then interval '1 year'
                                      else interval '1 month'
                                    end;

    perform public.platform_issue_invoice(
      v_lic.office_id, v_lic.period_end, v_new_end,
      jsonb_build_object('reason', 'تجديد دوري'));

    update public.office_licenses
       set period_start = v_lic.period_end,
           period_end   = v_new_end
     where office_id = v_lic.office_id;

    v_issued := v_issued + 1;
  end loop;

  return jsonb_build_object('invoices_issued', v_issued, 'ran_at', now());
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. The lifecycle job (§14.1, §14.3)
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.platform_run_licensing_lifecycle()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_settings public.platform_settings;
  v_row      record;
  v_plan     public.platform_plans;
  v_counts   jsonb := jsonb_build_object(
    'trials_expired', 0, 'downgraded', 0, 'past_due', 0,
    'grace', 0, 'suspended', 0, 'expired', 0, 'warned', 0);
begin
  perform public.assert_platform_admin_or_system();

  select * into v_settings from public.platform_settings where id;

  ---------------------------------------------------------------- 1. trial warnings
  for v_row in
    select l.office_id, l.trial_ends_at
      from public.office_licenses l
     where l.status = 'trialing'
       and l.trial_ends_at between now()
                               and now() + make_interval(days => v_settings.warn_days_before)
  loop
    perform public.push_operational_alert(
      'trial_ending',
      'تنتهي الفترة التجريبية قريبًا',
      'تنتهي فترتك التجريبية في ' || to_char(v_row.trial_ends_at, 'YYYY-MM-DD') ||
      '. تواصل مع المنصة لاختيار باقة قبل انتهائها.',
      jsonb_build_object('trial_ends_at', v_row.trial_ends_at),
      'normal', '/settings/billing', v_row.office_id);
    v_counts := jsonb_set(v_counts, '{warned}',
                  to_jsonb((v_counts ->> 'warned')::int + 1));
  end loop;

  ------------------------------------------------------------------ 2. trial expiry
  for v_row in
    select office_id from public.office_licenses
     where status = 'trialing' and trial_ends_at <= now()
  loop
    perform set_config('bmt.licensing_reason', 'انتهت الفترة التجريبية', true);
    update public.office_licenses
       set status = 'expired', trial_ends_at = null
     where office_id = v_row.office_id;

    perform public.platform_audit_write(
      v_row.office_id, 'license', v_row.office_id::text, 'updated',
      jsonb_build_object('status','trialing'), jsonb_build_object('status','expired'),
      'انتهت الفترة التجريبية');

    v_counts := jsonb_set(v_counts, '{trials_expired}',
                  to_jsonb((v_counts ->> 'trials_expired')::int + 1));
  end loop;

  ------------------------------------------- 3. period ended with no auto-renewal
  for v_row in
    select office_id from public.office_licenses
     where status = 'active'
       and not auto_renew
       and period_end is not null
       and period_end <= now()
  loop
    perform set_config('bmt.licensing_reason', 'انتهت المدة بدون تجديد تلقائي', true);
    update public.office_licenses set status = 'expired' where office_id = v_row.office_id;
    v_counts := jsonb_set(v_counts, '{expired}',
                  to_jsonb((v_counts ->> 'expired')::int + 1));
  end loop;

  ------------------------------------------------------------------ 4. dunning
  -- An invoice that passed its due date marks itself overdue and moves the license
  -- into the first dunning window. The office stays FULLY OPERATIONAL here — this is
  -- a banner, not a hold.
  update public.office_invoices
     set status = 'overdue'
   where status = 'issued' and due_at is not null and due_at <= now();

  for v_row in
    select distinct i.office_id
      from public.office_invoices i
      join public.office_licenses l on l.office_id = i.office_id
     where i.status = 'overdue' and l.status = 'active'
  loop
    perform set_config('bmt.licensing_reason', 'فاتورة متأخرة', true);
    update public.office_licenses
       set status = 'past_due',
           grace_ends_at = now() + make_interval(days => v_settings.grace_days)
     where office_id = v_row.office_id;

    perform public.push_operational_alert(
      'license_past_due', 'فاتورة اشتراك متأخرة',
      'يوجد اشتراك غير مسدد. الحساب يعمل بالكامل حاليًا، وسيتحوّل إلى وضع القراءة فقط إن لم يُسدَّد.',
      '{}'::jsonb, 'high', '/settings/billing', v_row.office_id);

    v_counts := jsonb_set(v_counts, '{past_due}',
                  to_jsonb((v_counts ->> 'past_due')::int + 1));
  end loop;

  -- past_due → grace: the final countdown, urgent banner, still fully operational.
  for v_row in
    select office_id from public.office_licenses
     where status = 'past_due' and grace_ends_at is not null and grace_ends_at <= now()
  loop
    perform set_config('bmt.licensing_reason', 'انتهت مهلة السداد الأولى', true);
    update public.office_licenses
       set status = 'grace',
           grace_ends_at = now() + make_interval(days => v_settings.warn_days_before)
     where office_id = v_row.office_id;

    perform public.push_operational_alert(
      'license_grace', 'مهلة أخيرة قبل إيقاف الخدمة',
      'سيتحوّل الحساب إلى وضع القراءة فقط خلال أيام إن لم تُسدَّد الفاتورة. ' ||
      'الرحلات القائمة والتذاكر المُباعة تكمل كالمعتاد في كل الأحوال.',
      '{}'::jsonb, 'high', '/settings/billing', v_row.office_id);

    v_counts := jsonb_set(v_counts, '{grace}',
                  to_jsonb((v_counts ->> 'grace')::int + 1));
  end loop;

  -- grace → suspended. This is the one transition that changes what the office can
  -- do, and what it changes is CREATION only (§4.3).
  for v_row in
    select office_id from public.office_licenses
     where status = 'grace' and grace_ends_at is not null and grace_ends_at <= now()
  loop
    perform set_config('bmt.licensing_reason', 'انتهت مهلة السداد', true);
    update public.office_licenses
       set status = 'suspended',
           suspended_at = now(),
           suspended_reason = 'عدم سداد اشتراك المنصة'
     where office_id = v_row.office_id;

    perform public.platform_audit_write(
      v_row.office_id, 'license', v_row.office_id::text, 'suspended',
      jsonb_build_object('status','grace'), jsonb_build_object('status','suspended'),
      'عدم سداد اشتراك المنصة');

    perform public.push_operational_alert(
      'license_suspended', 'تم تحويل الحساب إلى وضع القراءة فقط',
      'لا يمكن إنشاء رحلات أو سائقين أو خطوط جديدة، ولا يظهر المكتب لعملاء التطبيق. ' ||
      'كل ما هو قائم يكمل: التذاكر المُباعة، الرحلات الجارية، ودخول الكباتن.',
      '{}'::jsonb, 'high', '/settings/billing', v_row.office_id);

    v_counts := jsonb_set(v_counts, '{suspended}',
                  to_jsonb((v_counts ->> 'suspended')::int + 1));
  end loop;

  ------------------------------------------------------- 5. automatic downgrade
  -- An expired license falls to its plan's declared successor rather than sitting in
  -- a dead state. `free` cycle, no period end, no auto-renewal: the office keeps
  -- operating on whatever that plan allows and nothing bills it.
  for v_row in
    select l.office_id, l.plan_id, p.downgrade_to_plan_id
      from public.office_licenses l
      join public.platform_plans p on p.id = l.plan_id
     where l.status = 'expired' and p.downgrade_to_plan_id is not null
  loop
    select * into v_plan from public.platform_plans where id = v_row.downgrade_to_plan_id;

    perform set_config('bmt.licensing_reason', 'تخفيض تلقائي بعد انتهاء الترخيص', true);
    update public.office_licenses
       set plan_id       = v_row.downgrade_to_plan_id,
           status        = 'active',
           billing_cycle = 'free',
           period_start  = now(),
           period_end    = null,
           auto_renew    = false,
           grace_ends_at = null
     where office_id = v_row.office_id;

    perform public.platform_audit_write(
      v_row.office_id, 'license', v_row.office_id::text, 'plan_changed',
      jsonb_build_object('plan_id', v_row.plan_id),
      jsonb_build_object('plan_key', v_plan.key), 'تخفيض تلقائي');

    perform public.push_operational_alert(
      'license_downgraded', 'تم تخفيض الباقة تلقائيًا',
      'الباقة الحالية: ' || v_plan.name_ar ||
      '. لم يُحذف أي بيان — الحدود الجديدة تمنع الإنشاء الجديد فقط.',
      jsonb_build_object('plan_key', v_plan.key),
      'high', '/settings/billing', v_row.office_id);

    v_counts := jsonb_set(v_counts, '{downgraded}',
                  to_jsonb((v_counts ->> 'downgraded')::int + 1));
  end loop;

  return v_counts || jsonb_build_object('ran_at', now());
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. Grants
-- ═══════════════════════════════════════════════════════════════════════════════════

revoke all on function public.platform_run_billing_cycle()        from public, anon;
revoke all on function public.platform_run_licensing_lifecycle()  from public, anon;

-- Callable by a platform admin from the console (a "run now" button is far more
-- useful than waiting for a schedule while debugging a customer's state), and by a
-- JWT-less scheduled job.
grant execute on function public.platform_run_billing_cycle()       to authenticated;
grant execute on function public.platform_run_licensing_lifecycle() to authenticated;
