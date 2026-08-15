-- ═══════════════════════════════════════════════════════════════════════════════════
-- Regression suite: office staff provisioning
-- (migration 20260815100000_office_staff_provisioning.sql)
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Self-contained: builds two offices, each with an owner and a support agent, plus a
-- spare auth user to provision; exercises every authorization boundary and all three
-- lockout rules; then ROLLS EVERYTHING BACK. Safe to run against any environment where
-- the migration is applied.
--
-- Run it as postgres (e.g. via the Management API query endpoint): the script switches
-- to `role authenticated` with a forged request.jwt.claims to act as each principal,
-- and back to postgres for RLS-bypassing truth assertions.
--
-- What it does NOT cover: the Edge Function. Creating an auth.users row is a GoTrue
-- operation, so the fixtures below insert auth.users directly — exactly the split the
-- design makes, where SQL owns membership and the function owns the auth account.
--
-- Output: one row per check; the final DO block raises listing any failures.

begin;

create temporary table _staff_results (seq serial, name text, pass boolean, detail text)
  on commit drop;
grant all on _staff_results to authenticated;
grant all on _staff_results_seq_seq to authenticated;

-- ── Fixtures (all rolled back) ──────────────────────────────────────────────────────

do $fix$
begin
  insert into public.offices (id, name, slug, status, listing_status, description,
                              service_areas)
  values ('c0f30000-0000-4000-8000-00000000000a', 'TEST-STAFF Office A', 'test-staff-a',
          'active', 'listed', 'fixture A', array['TESTSTAFF-Cairo']),
         ('c0f30000-0000-4000-8000-00000000000b', 'TEST-STAFF Office B', 'test-staff-b',
          'active', 'listed', 'fixture B', array['TESTSTAFF-Giza']);

  -- `role: office_user` keeps handle_new_client_user() from writing a clients row with
  -- an empty phone — the collision migration 20260721140000 §5 exists to prevent.
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, raw_user_meta_data,
                          created_at, updated_at)
  select u.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         u.email, 'x', now(), '{"role":"office_user"}'::jsonb, now(), now()
    from (values
      ('c0f30000-0000-4000-8000-0000000000a1'::uuid, 'teststaff.a.owner@office.ewt.internal'),
      ('c0f30000-0000-4000-8000-0000000000a2'::uuid, 'teststaff.a.agent@office.ewt.internal'),
      ('c0f30000-0000-4000-8000-0000000000a3'::uuid, 'teststaff.a.owner2@office.ewt.internal'),
      ('c0f30000-0000-4000-8000-0000000000b1'::uuid, 'teststaff.b.owner@office.ewt.internal'),
      -- The spare: has an auth account, belongs to no office yet. Stands in for what
      -- the Edge Function creates just before calling office_create_staff.
      ('c0f30000-0000-4000-8000-0000000000f1'::uuid, 'teststaff.new@office.ewt.internal'),
      ('c0f30000-0000-4000-8000-0000000000f2'::uuid, 'teststaff.new2@office.ewt.internal')
    ) as u(id, email);

  insert into public.office_users (id, office_id, user_id, username, full_name, role, status)
  values ('c0f30000-0000-4000-8000-0000000000d1',
          'c0f30000-0000-4000-8000-00000000000a', 'c0f30000-0000-4000-8000-0000000000a1',
          'teststaff.a.owner', 'A Owner', 'dashboard_admin', 'active'),
         ('c0f30000-0000-4000-8000-0000000000d2',
          'c0f30000-0000-4000-8000-00000000000a', 'c0f30000-0000-4000-8000-0000000000a2',
          'teststaff.a.agent', 'A Agent', 'support_agent', 'active'),
         ('c0f30000-0000-4000-8000-0000000000d4',
          'c0f30000-0000-4000-8000-00000000000b', 'c0f30000-0000-4000-8000-0000000000b1',
          'teststaff.b.owner', 'B Owner', 'dashboard_admin', 'active');
end $fix$;

-- ═══ 1. Authorization ═══════════════════════════════════════════════════════════════

-- 1a. A SUPPORT AGENT may not create a colleague.
select set_config('request.jwt.claims',
  '{"sub":"c0f30000-0000-4000-8000-0000000000a2","role":"authenticated"}', true);
set local role authenticated;

do $$
declare v_err text;
begin
  begin
    perform public.office_create_staff(
      'c0f30000-0000-4000-8000-0000000000f1', 'teststaff.rogue', 'dashboard_admin');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('Support agent cannot create staff',
          v_err like '%dashboard_admin_required%', v_err);
end $$;

-- 1b. …nor promote themselves.
do $$
declare v_err text;
begin
  begin
    perform public.office_update_staff_role(
      'c0f30000-0000-4000-8000-0000000000d2', 'dashboard_admin');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('Support agent cannot change any role',
          v_err like '%dashboard_admin_required%', v_err);
end $$;

-- 1c. …nor disable the owner above them.
do $$
declare v_err text;
begin
  begin
    perform public.office_set_staff_status(
      'c0f30000-0000-4000-8000-0000000000d1', 'disabled');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('Support agent cannot disable the owner',
          v_err like '%dashboard_admin_required%', v_err);
end $$;

reset role;

-- ═══ 2. Tenancy: office A's owner cannot reach office B ═════════════════════════════

select set_config('request.jwt.claims',
  '{"sub":"c0f30000-0000-4000-8000-0000000000a1","role":"authenticated"}', true);
set local role authenticated;

do $$
declare v_err text;
begin
  begin
    perform public.office_update_staff_role(
      'c0f30000-0000-4000-8000-0000000000d4', 'support_agent');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('Owner A cannot re-role office B''s owner',
          v_err like '%staff_not_found%', v_err);
end $$;

do $$
declare v_err text;
begin
  begin
    perform public.office_staff_reset_target('c0f30000-0000-4000-8000-0000000000d4');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('Owner A cannot resolve office B''s staff for a password reset',
          v_err like '%staff_not_found%', v_err);
end $$;

-- ═══ 3. Creating staff ══════════════════════════════════════════════════════════════

do $$
declare v_row jsonb;
begin
  v_row := public.office_create_staff(
    'c0f30000-0000-4000-8000-0000000000f1', 'TestStaff.New', 'support_agent', 'New Agent');

  insert into _staff_results (name, pass, detail)
  values ('Owner creates a colleague',
          v_row ->> 'role' = 'support_agent' and v_row ->> 'status' = 'active', v_row::text);

  insert into _staff_results (name, pass, detail)
  values ('Username is normalised to lower case',
          v_row ->> 'username' = 'teststaff.new', v_row ->> 'username');
end $$;

-- The office is the caller's, not a parameter — there is no parameter to check, so the
-- assertion is that the row landed in office A and nowhere else.
reset role;
insert into _staff_results (name, pass, detail)
select 'New staff row belongs to the creating owner''s office',
       count(*) = 1, count(*)::text
  from public.office_users
 where user_id = 'c0f30000-0000-4000-8000-0000000000f1'
   and office_id = 'c0f30000-0000-4000-8000-00000000000a';

insert into _staff_results (name, pass, detail)
select 'Provisioning wrote no clients row for the new operator', count(*) = 0, count(*)::text
  from public.clients where id = 'c0f30000-0000-4000-8000-0000000000f1';

select set_config('request.jwt.claims',
  '{"sub":"c0f30000-0000-4000-8000-0000000000a1","role":"authenticated"}', true);
set local role authenticated;

-- A taken username is refused, including across office boundaries: the unique index is
-- platform-wide, so office A may not take a name office B already holds.
do $$
declare v_err text;
begin
  begin
    perform public.office_create_staff(
      'c0f30000-0000-4000-8000-0000000000f2', 'teststaff.b.owner', 'support_agent');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('A username held by another office is refused',
          v_err like '%username_taken%', v_err);
end $$;

-- An auth user who already works somewhere is refused rather than MOVED — the
-- link_office_user() ON CONFLICT DO UPDATE behaviour this deliberately does not copy.
do $$
declare v_err text;
begin
  begin
    perform public.office_create_staff(
      'c0f30000-0000-4000-8000-0000000000b1', 'teststaff.poached', 'support_agent');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('An operator of another office cannot be poached',
          v_err like '%staff_user_already_assigned%', v_err);
end $$;

reset role;
insert into _staff_results (name, pass, detail)
select 'Office B''s owner still belongs to office B', count(*) = 1, count(*)::text
  from public.office_users
 where user_id = 'c0f30000-0000-4000-8000-0000000000b1'
   and office_id = 'c0f30000-0000-4000-8000-00000000000b';

select set_config('request.jwt.claims',
  '{"sub":"c0f30000-0000-4000-8000-0000000000a1","role":"authenticated"}', true);
set local role authenticated;

do $$
declare v_err text;
begin
  begin
    perform public.office_create_staff(
      'c0f30000-0000-4000-8000-0000000000f2', 'ops sara', 'support_agent');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('A malformed username is refused', v_err like '%invalid_username%', v_err);
end $$;

do $$
declare v_err text;
begin
  begin
    perform public.office_create_staff(
      'c0f30000-0000-4000-8000-0000000000f2', 'teststaff.new2', 'platform_admin');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('A role outside the two is refused', v_err like '%invalid_role%', v_err);
end $$;

-- ═══ 4. The three lockout rules ═════════════════════════════════════════════════════

-- 4a. An owner may not change their own role, even with another owner present.
do $$
declare v_err text;
begin
  begin
    perform public.office_update_staff_role(
      'c0f30000-0000-4000-8000-0000000000d1', 'support_agent');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('Owner cannot demote themselves', v_err like '%cannot_change_own_role%', v_err);
end $$;

-- 4b. An owner may not disable their own account.
do $$
declare v_err text;
begin
  begin
    perform public.office_set_staff_status(
      'c0f30000-0000-4000-8000-0000000000d1', 'disabled');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('Owner cannot disable themselves', v_err like '%cannot_disable_self%', v_err);
end $$;

-- 4c. A SECOND owner can be promoted, demoted and disabled freely — the rules gate
-- losing the last one, never ordinary staffing.
do $$
declare v_row jsonb;
begin
  v_row := public.office_update_staff_role(
    (select id from public.office_users
      where user_id = 'c0f30000-0000-4000-8000-0000000000f1'),
    'dashboard_admin');
  insert into _staff_results (name, pass, detail)
  values ('A colleague can be promoted to owner',
          v_row ->> 'role' = 'dashboard_admin', v_row::text);
end $$;

do $$
declare v_row jsonb;
begin
  v_row := public.office_set_staff_status(
    (select id from public.office_users
      where user_id = 'c0f30000-0000-4000-8000-0000000000f1'),
    'disabled');
  insert into _staff_results (name, pass, detail)
  values ('The second owner can be disabled while the first is active',
          v_row ->> 'status' = 'disabled', v_row::text);
end $$;

-- 4d. Rule 3 stated honestly: it is a BACKSTOP, currently unreachable through 4a/4b.
--
-- Reaching `last_admin_required` needs an active-owner caller acting on the last active
-- owner — but if the target is the last one, the caller IS the target, and 4a/4b refuse
-- first. So the assertion here is the invariant the rule exists to protect, not the
-- error code: whatever an owner tries, the office never ends up with zero active owners.
--
-- The direct unit test of the predicate follows, because the invariant alone would also
-- pass if the rule were deleted.
do $$
declare v_err text;
begin
  begin
    perform public.office_update_staff_role(
      'c0f30000-0000-4000-8000-0000000000d1', 'support_agent');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('The last active owner cannot be stripped by any route',
          v_err like '%cannot_change_own_role%' or v_err like '%last_admin_required%',
          v_err);
end $$;

reset role;
insert into _staff_results (name, pass, detail)
select 'Office A still has an active owner after every attempt above',
       count(*) >= 1, count(*)::text
  from public.office_users
 where office_id = 'c0f30000-0000-4000-8000-00000000000a'
   and role = 'dashboard_admin' and status = 'active';

-- The predicate itself: it must not count the excluded row, a disabled owner, or an
-- owner belonging to another office. Those three mistakes are exactly what would make
-- the backstop pass while protecting nothing.
-- Office A right now holds: owner d1 (active), the second owner from 4c (DISABLED), and
-- two support agents. So this one call proves both mistakes at once — excluding d1 must
-- answer false, which it only can if the disabled owner is not counted either.
insert into _staff_results (name, pass, detail)
select 'office_has_other_admin ignores the excluded row and disabled owners',
       public.office_has_other_admin(
         'c0f30000-0000-4000-8000-00000000000a',
         'c0f30000-0000-4000-8000-0000000000d1') = false,
       'only d1 is an active owner, and it is the excluded row';

insert into _staff_results (name, pass, detail)
select 'office_has_other_admin ignores other offices'' owners',
       public.office_has_other_admin(
         'c0f30000-0000-4000-8000-00000000000b',
         'c0f30000-0000-4000-8000-0000000000d4') = false,
       'office B''s only owner, excluded, must answer false';

-- …and answers true when there genuinely is one, so the checks above are not passing
-- because the function simply always returns false.
insert into public.office_users (id, office_id, user_id, username, full_name, role, status)
values ('c0f30000-0000-4000-8000-0000000000d3',
        'c0f30000-0000-4000-8000-00000000000a', 'c0f30000-0000-4000-8000-0000000000a3',
        'teststaff.a.owner2', 'A Owner 2', 'dashboard_admin', 'active');

insert into _staff_results (name, pass, detail)
select 'office_has_other_admin sees a genuine second owner',
       public.office_has_other_admin(
         'c0f30000-0000-4000-8000-00000000000a',
         'c0f30000-0000-4000-8000-0000000000d1') = true,
       'owner 2 is active and not excluded';

-- With two active owners, demoting one is allowed — the rule gates the last, not any.
select set_config('request.jwt.claims',
  '{"sub":"c0f30000-0000-4000-8000-0000000000a3","role":"authenticated"}', true);
set local role authenticated;

do $$
declare v_row jsonb;
begin
  v_row := public.office_update_staff_role(
    'c0f30000-0000-4000-8000-0000000000d1', 'support_agent');
  insert into _staff_results (name, pass, detail)
  values ('An owner can be demoted while another owner is active',
          v_row ->> 'role' = 'support_agent', v_row::text);
end $$;

-- ═══ 5. Disabling actually shuts the account out ════════════════════════════════════

reset role;
insert into _staff_results (name, pass, detail)
select 'A disabled operator cannot resolve a login',
       public.resolve_office_user_login('teststaff.new') ->> 'outcome' = 'not_found',
       public.resolve_office_user_login('teststaff.new')::text;

select set_config('request.jwt.claims',
  '{"sub":"c0f30000-0000-4000-8000-0000000000f1","role":"authenticated"}', true);
set local role authenticated;

do $$
declare v_err text;
begin
  begin
    perform public.current_office_context();
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _staff_results (name, pass, detail)
  values ('A disabled operator has no office context',
          v_err like '%not_an_office_user%', v_err);
end $$;

-- ═══ 6. Grants ══════════════════════════════════════════════════════════════════════

reset role;

insert into _staff_results (name, pass, detail)
select 'anon holds EXECUTE on none of the staff RPCs',
       count(*) = 0, coalesce(string_agg(p.proname, ', '), 'none')
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('office_create_staff', 'office_update_staff_role',
                     'office_set_staff_status', 'office_staff_reset_target',
                     'office_staff_username_available')
   and has_function_privilege('anon', p.oid, 'execute');

-- The internal helpers are called only from the SECURITY DEFINER functions above, which
-- run as the owner. An API role that could call them directly would be able to ask
-- "does this office have another admin" about an office it does not belong to.
insert into _staff_results (name, pass, detail)
select 'Internal helpers are not callable by the API roles',
       count(*) = 0, coalesce(string_agg(p.proname || '/' || r.rolname, ', '), 'none')
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 cross join (values ('anon'), ('authenticated')) as r(rolname)
 where n.nspname = 'public'
   and p.proname in ('assert_office_staff_admin', 'office_has_other_admin',
                     'office_staff_row')
   and has_function_privilege(r.rolname, p.oid, 'execute');

-- ── Verdict ─────────────────────────────────────────────────────────────────────────
do $$
declare bad text;
begin
  select string_agg(name || ' [' || coalesce(detail, 'null') || ']', '; ')
    into bad from _staff_results where not pass;
  if bad is not null then
    raise exception 'OFFICE STAFF PROVISIONING REGRESSION FAILURES: %', bad;
  end if;
end $$;

select name, case when pass then 'PASS' else 'FAIL' end as result, detail
  from _staff_results order by seq;

rollback;
