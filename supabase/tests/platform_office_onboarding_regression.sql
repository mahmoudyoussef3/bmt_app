-- ═══════════════════════════════════════════════════════════════════════════════════
-- Regression suite: platform office onboarding
-- (migration 20260721140000_platform_office_onboarding.sql)
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Self-contained: builds a platform admin, an incumbent office with an admin of its
-- own, and a captain-facing fixture; exercises the onboarding RPC, the authorization
-- boundaries, the listing axis and the isolation guarantees; then ROLLS EVERYTHING
-- BACK. Safe to run against any environment where the migration is applied.
--
-- Run it as postgres (e.g. via the Management API query endpoint): the script switches
-- to `role authenticated` with a forged request.jwt.claims to act as each principal,
-- and back to postgres for RLS-bypassing truth assertions.
--
-- What it does NOT cover: the Edge Function. Creating an auth.users row is a GoTrue
-- operation, so the fixtures below insert auth.users directly — exactly the split the
-- design makes, where SQL owns the transaction and the function owns the auth account.
--
-- Output: one row per check; the final DO block raises listing any failures.

begin;

-- anon as well as authenticated: unlike the attribution suite, several checks here are
-- specifically about what an UNAUTHENTICATED caller can see, and they have to be able
-- to record their result.
create temporary table _plat_results (seq serial, name text, pass boolean, detail text)
  on commit drop;
grant all on _plat_results to authenticated, anon;
grant all on _plat_results_seq_seq to authenticated, anon;

-- Holds the onboarded office between sections. Created up front, as postgres, so the
-- later role switches only ever write to it.
create temporary table _plat_office (id uuid, code text) on commit drop;
grant all on _plat_office to authenticated, anon;

-- ── Fixtures (all rolled back) ──────────────────────────────────────────────────────

do $fix$
begin
  -- Office B: the incumbent. Listed, operating, with data of its own that Office A
  -- must never see.
  insert into public.offices (id, name, slug, status, listing_status, description,
                              service_areas)
  values ('b0f20000-0000-4000-8000-00000000000b', 'TEST-PLAT Office B', 'test-plat-b',
          'active', 'listed', 'incumbent fixture', array['TESTPLAT-Giza']);

  insert into public.operation_routes
        (id, name, start_city, end_city, status, route_code, office_id)
  values ('b0f20000-0000-4000-8000-0000000000b1', 'TEST-PLAT Route B', 'CityB1', 'CityB2',
          'active', 'RT-TEST-PLAT-B', 'b0f20000-0000-4000-8000-00000000000b');

  insert into public.operation_trips
        (id, trip_code, route_id, trip_date, departure_time, arrival_time,
         status, capacity, ticket_price, currency)
  values ('b0f20000-0000-4000-8000-0000000000b2', 'TR-TEST-PLAT-B',
          'b0f20000-0000-4000-8000-0000000000b1', current_date + 3, '09:00', '11:00',
          'open_for_booking', 4, 100, 'EGP');

  -- Principals. `role: office_user` on the operators is what keeps
  -- handle_new_client_user() from writing a clients row with an empty phone — the
  -- collision this migration's §5 exists to prevent, and which the second operator
  -- below would otherwise hit.
  insert into auth.users (id, email, raw_user_meta_data) values
    ('90f20000-0000-4000-8000-0000000000f1', 'test-plat-platadmin@plat.invalid',
     '{"full_name":"TEST-PLAT Platform Admin","role":"office_user"}'::jsonb),
    ('b0f20000-0000-4000-8000-0000000000bd', 'test-plat-op-b@plat.invalid',
     '{"full_name":"TEST-PLAT Op B","role":"office_user"}'::jsonb),
    ('a0f20000-0000-4000-8000-0000000000ad', 'test-plat-op-a@plat.invalid',
     '{"full_name":"TEST-PLAT Op A","role":"office_user"}'::jsonb),
    ('c0f20000-0000-4000-8000-0000000000c9', 'test-plat-spare@plat.invalid',
     '{"full_name":"TEST-PLAT Spare","role":"office_user"}'::jsonb);

  -- The platform admin is also an operator of office B: that is the real shape (a
  -- person runs an office AND the platform), and it is the shape that would leak if
  -- office scoping were confused with platform authority.
  insert into public.office_users (office_id, user_id, username, role, status) values
    ('b0f20000-0000-4000-8000-00000000000b', '90f20000-0000-4000-8000-0000000000f1',
     'test-plat-platadmin', 'dashboard_admin', 'active'),
    ('b0f20000-0000-4000-8000-00000000000b', 'b0f20000-0000-4000-8000-0000000000bd',
     'test-plat-op-b', 'dashboard_admin', 'active');

  insert into public.platform_admins (user_id, note)
  values ('90f20000-0000-4000-8000-0000000000f1', 'TEST-PLAT fixture');

  -- An office with a blank marketplace card, for the "cannot be listed yet" check.
  -- Inserted here rather than in §6 because `offices` has no INSERT policy for any
  -- client-tier role — creating it as `authenticated` would fail on the grant, not on
  -- the rule under test.
  insert into public.offices (id, name, slug, status, listing_status, description)
  values ('e0f20000-0000-4000-8000-00000000000e', 'TEST-PLAT Blank', 'test-plat-blank',
          'active', 'draft', '');

  -- Gives §3 a route belonging to an office that is NOT on the marketplace, which is
  -- the only shape in which one office's routes are private from another's.
  insert into public.operation_routes
        (id, name, start_city, end_city, status, route_code, office_id)
  values ('e0f20000-0000-4000-8000-0000000000e1', 'TEST-PLAT Route Blank', 'CityE1',
          'CityE2', 'active', 'RT-TEST-PLAT-E', 'e0f20000-0000-4000-8000-00000000000e');
end $fix$;

-- ═══ 1. Authorization ═══════════════════════════════════════════════════════════════

-- 1a. An OFFICE admin (not a platform admin) must not be able to create an office.
select set_config('request.jwt.claims',
  '{"sub":"b0f20000-0000-4000-8000-0000000000bd","role":"authenticated"}', true);
set local role authenticated;

do $$
declare v_err text;
begin
  begin
    perform public.platform_create_office(
      'TEST-PLAT Rogue', 'a0f20000-0000-4000-8000-0000000000ad', 'test-plat-rogue');
    v_err := 'NO ERROR RAISED';
  exception when others then
    v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('Office admin cannot create an office',
          v_err like '%platform_admin_required%', v_err);
end $$;

-- 1b. …nor list every office on the platform.
do $$
declare v_err text;
begin
  begin
    perform count(*) from public.platform_list_offices();
    v_err := 'NO ERROR RAISED';
  exception when others then
    v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('Office admin cannot list platform offices',
          v_err like '%platform_admin_required%', v_err);
end $$;

-- 1c. …nor promote anyone (including themselves) to platform admin.
do $$
declare v_err text;
begin
  begin
    insert into public.platform_admins (user_id)
    values ('b0f20000-0000-4000-8000-0000000000bd');
    v_err := 'NO ERROR RAISED';
  exception when others then
    v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('Office admin cannot create a platform admin', v_err <> 'NO ERROR RAISED', v_err);
end $$;

-- …nor edit or remove the existing appointment. INSERT alone is not the whole
-- surface: an office admin who could UPDATE platform_admins.user_id would appoint
-- themselves just as effectively.
do $$
declare v_err text;
begin
  begin
    update public.platform_admins
       set user_id = 'b0f20000-0000-4000-8000-0000000000bd'
     where user_id = '90f20000-0000-4000-8000-0000000000f1';
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('Office admin cannot update platform_admins', v_err <> 'NO ERROR RAISED', v_err);
end $$;

do $$
declare v_err text;
begin
  begin
    delete from public.platform_admins
     where user_id = '90f20000-0000-4000-8000-0000000000f1';
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('Office admin cannot delete a platform admin', v_err <> 'NO ERROR RAISED', v_err);
end $$;

reset role;

-- The delete above must have been refused rather than silently filtered away by a
-- policy: an empty-set DELETE raises nothing, so the privilege check is asserted
-- against the truth of the table, as postgres.
insert into _plat_results (name, pass, detail)
select 'The platform admin appointment survived both attempts', count(*) = 1, count(*)::text
  from public.platform_admins where user_id = '90f20000-0000-4000-8000-0000000000f1';

-- 1d. anon must not reach any of it either.
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

do $$
declare v_err text;
begin
  begin
    perform public.platform_create_office(
      'TEST-PLAT Anon', 'a0f20000-0000-4000-8000-0000000000ad', 'test-plat-anon');
    v_err := 'NO ERROR RAISED';
  exception when others then
    v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('anon cannot create an office', v_err <> 'NO ERROR RAISED', v_err);
end $$;

reset role;

-- ═══ 2. Onboarding (as the platform admin) ══════════════════════════════════════════

select set_config('request.jwt.claims',
  '{"sub":"90f20000-0000-4000-8000-0000000000f1","role":"authenticated"}', true);
set local role authenticated;

do $$
declare
  v_result jsonb;
begin
  v_result := public.platform_create_office(
    p_name            => 'TEST-PLAT Office A',
    p_admin_user_id   => 'a0f20000-0000-4000-8000-0000000000ad',
    p_admin_username  => 'test-plat-op-a',
    p_slug            => 'test-plat-a',
    p_description     => 'onboarding fixture',
    p_phone           => '0100000000',
    p_service_areas   => array['TESTPLAT-Cairo', '  ', 'TESTPLAT-Cairo'],
    p_admin_full_name => 'TEST-PLAT Op A');

  insert into _plat_results (name, pass, detail)
  values ('Onboarding returns an office id',
          (v_result ->> 'office_id') is not null, v_result::text);

  insert into _plat_results (name, pass, detail)
  values ('New office starts listing_status = draft',
          v_result ->> 'listing_status' = 'draft', v_result ->> 'listing_status');

  insert into _plat_results (name, pass, detail)
  values ('New office starts status = active (so its admin can sign in)',
          v_result ->> 'status' = 'active', v_result ->> 'status');

  insert into _plat_results (name, pass, detail)
  values ('First operator is a dashboard_admin',
          v_result ->> 'role' = 'dashboard_admin', v_result ->> 'role');

  insert into _plat_results (name, pass, detail)
  values ('Join code is 8 glyphs from the unambiguous alphabet',
          v_result ->> 'join_code' ~ '^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$',
          v_result ->> 'join_code');

  -- Stash the id and the code for the checks that follow. The code is returned exactly
  -- once, here — no later query in this script could recover it.
  insert into _plat_office (id, code)
  values ((v_result ->> 'office_id')::uuid, v_result ->> 'join_code');
end $$;

-- 2a. Duplicate slug and duplicate username are both refused.
do $$
declare v_err text;
begin
  begin
    perform public.platform_create_office(
      'TEST-PLAT Dup Slug', 'c0f20000-0000-4000-8000-0000000000c9',
      'test-plat-spare', 'test-plat-a');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('Duplicate slug refused', v_err like '%slug_taken%', v_err);
end $$;

do $$
declare v_err text;
begin
  begin
    perform public.platform_create_office(
      'TEST-PLAT Dup User', 'c0f20000-0000-4000-8000-0000000000c9',
      'test-plat-op-a', 'test-plat-dup');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('Duplicate username refused', v_err like '%username_taken%', v_err);
end $$;

-- 2b. An operator already bound to an office cannot be re-pointed at a new one.
-- link_office_user()'s ON CONFLICT DO UPDATE would have MOVED them; this must not.
do $$
declare v_err text;
begin
  begin
    perform public.platform_create_office(
      'TEST-PLAT Steal', 'b0f20000-0000-4000-8000-0000000000bd',
      'test-plat-steal', 'test-plat-steal');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('Existing operator cannot be moved to a new office',
          v_err like '%admin_user_already_assigned%', v_err);
end $$;

insert into _plat_results (name, pass, detail)
select 'Office B''s admin still belongs to office B',
       office_id = 'b0f20000-0000-4000-8000-00000000000b', office_id::text
  from public.office_users where user_id = 'b0f20000-0000-4000-8000-0000000000bd';

-- 2c. Input validation.
do $$
declare
  spec record;
  v_err text;
begin
  for spec in
    select * from (values
      ('invalid_slug',        'TEST-PLAT Bad', 'Not A Slug'),
      ('invalid_office_name', 'AB',            'test-plat-ok1')
    ) as t(expected, name, slug)
  loop
    begin
      perform public.platform_create_office(
        spec.name, 'c0f20000-0000-4000-8000-0000000000c9', 'test-plat-spare', spec.slug);
      v_err := 'NO ERROR RAISED';
    exception when others then v_err := SQLERRM;
    end;
    insert into _plat_results (name, pass, detail)
    values ('Rejects ' || spec.expected, v_err like '%' || spec.expected || '%', v_err);
  end loop;
end $$;

reset role;

-- ═══ 3. Isolation ═══════════════════════════════════════════════════════════════════

-- Office A's own admin, signed in.
select set_config('request.jwt.claims',
  '{"sub":"a0f20000-0000-4000-8000-0000000000ad","role":"authenticated"}', true);
set local role authenticated;

insert into _plat_results (name, pass, detail)
select 'Office A admin resolves to office A',
       public.current_office_id() = (select id from _plat_office),
       public.current_office_id()::text;

insert into _plat_results (name, pass, detail)
select 'Office A admin is a dashboard_admin', public.office_role() = 'dashboard_admin',
       public.office_role();

insert into _plat_results (name, pass, detail)
select 'Office A admin can sign in while draft (context resolves)',
       (public.current_office_context() ->> 'office_id') = (select id::text from _plat_office),
       public.current_office_context() ->> 'listing_status';

insert into _plat_results (name, pass, detail)
select 'Office A admin is NOT a platform admin', not public.is_platform_admin(),
       public.is_platform_admin()::text;

-- Routes are not a private table. Office B is LISTED and its route is active, so that
-- route is marketplace data by definition — anon reads it through
-- routes_marketplace_read, and the client's route browser is built on exactly that.
-- Asserting office A cannot see it would be asserting the marketplace does not work.
--
-- The isolation that does hold, and that this pair pins down, is the two things routes
-- are never public for: an office that is NOT on the marketplace, and writes.
insert into _plat_results (name, pass, detail)
select 'Office A cannot see a non-listed office''s routes', count(*) = 0, count(*)::text
  from public.operation_routes where id = 'e0f20000-0000-4000-8000-0000000000e1';

do $$
declare v_rows int;
begin
  with u as (
    update public.operation_routes set status = 'inactive'
     where office_id = 'b0f20000-0000-4000-8000-00000000000b'
    returning 1)
  select count(*) into v_rows from u;
  insert into _plat_results (name, pass, detail)
  values ('Office A cannot write office B''s routes', v_rows = 0, v_rows::text);
exception when others then
  -- A privilege error is an equally good pass: nothing was written either way.
  insert into _plat_results (name, pass, detail)
  values ('Office A cannot write office B''s routes', true, 'refused: ' || SQLERRM);
end $$;

insert into _plat_results (name, pass, detail)
select 'Office A cannot see office B''s trips', count(*) = 0, count(*)::text
  from public.operation_trips where id = 'b0f20000-0000-4000-8000-0000000000b2';

insert into _plat_results (name, pass, detail)
select 'Office A cannot see office B''s operators', count(*) = 0, count(*)::text
  from public.office_users where office_id = 'b0f20000-0000-4000-8000-00000000000b';

do $$
declare v_err text;
begin
  begin
    perform count(*) from public.platform_list_offices();
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('Office A cannot reach the platform office list',
          v_err like '%platform_admin_required%', v_err);
end $$;

-- The join code: readable by its own office through the RPC, and never through the
-- base table for any client-tier role (column privileges, migration 20260721100200).
insert into _plat_results (name, pass, detail)
select 'Office A reads its own join code through office_join_code()',
       public.office_join_code() = (select code from _plat_office),
       public.office_join_code();

do $$
declare v_err text;
begin
  begin
    perform join_code from public.offices where id = (select id from _plat_office);
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('join_code column is not selectable by authenticated',
          v_err like '%permission denied%', v_err);
end $$;

reset role;

-- ═══ 3b. The first admin can actually sign in ═══════════════════════════════════════
-- The Dashboard's Name + Password flow is two steps, and §3 only covered the second.
-- Step one runs BEFORE any session exists: the login screen calls
-- resolve_office_user_login() as anon to turn the typed username into the login email
-- it then hands to signInWithPassword(). If that step does not resolve for a freshly
-- onboarded operator, the account is unreachable no matter how correct its row is.

select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

do $$
declare v_login jsonb;
begin
  v_login := public.resolve_office_user_login('test-plat-op-a');

  insert into _plat_results (name, pass, detail)
  values ('New admin''s username resolves for login (step 1 of Name + Password)',
          v_login ->> 'outcome' = 'ready', v_login::text);

  insert into _plat_results (name, pass, detail)
  values ('Resolution returns the account''s own login email',
          v_login ->> 'login_email' = 'test-plat-op-a@plat.invalid',
          v_login ->> 'login_email');
end $$;

-- Case-insensitively, since the operator types the name by hand.
insert into _plat_results (name, pass, detail)
select 'Username resolution is case-insensitive',
       public.resolve_office_user_login('TEST-PLAT-OP-A') ->> 'outcome' = 'ready',
       public.resolve_office_user_login('TEST-PLAT-OP-A') ->> 'outcome';

-- And an unknown name stays a dead end rather than a directory lookup.
insert into _plat_results (name, pass, detail)
select 'An unknown username reveals nothing',
       public.resolve_office_user_login('test-plat-nobody') ->> 'outcome' = 'not_found',
       public.resolve_office_user_login('test-plat-nobody')::text;

reset role;

-- ═══ 4. Marketplace visibility ══════════════════════════════════════════════════════

select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

insert into _plat_results (name, pass, detail)
select 'Draft office is absent from public_offices', count(*) = 0, count(*)::text
  from public.public_offices where id = (select id from _plat_office);

insert into _plat_results (name, pass, detail)
select 'Listed office B is present in public_offices', count(*) = 1, count(*)::text
  from public.public_offices where id = 'b0f20000-0000-4000-8000-00000000000b';

insert into _plat_results (name, pass, detail)
select 'Draft office is absent from the offices base table for anon',
       count(*) = 0, count(*)::text
  from public.offices where id = (select id from _plat_office);

insert into _plat_results (name, pass, detail)
select 'Existing office B''s trips still reach the marketplace', count(*) = 1, count(*)::text
  from public.public_trips where id = 'b0f20000-0000-4000-8000-0000000000b2';

-- The directory clients actually read must not carry the join code. §3 proved the
-- base-table column is privilege-protected; this proves the view — which runs as its
-- owner and so bypasses those privileges entirely — did not re-expose it. Deliberately
-- a column-list assertion rather than a `select join_code from public_offices`: the
-- latter fails identically whether the column is absent or merely empty.
insert into _plat_results (name, pass, detail)
select 'public_offices exposes no join code column',
       count(*) = 0, coalesce(string_agg(column_name, ', '), 'none')
  from information_schema.columns
 where table_schema = 'public' and table_name = 'public_offices'
   and column_name in ('join_code', 'join_code_rotated_at');

reset role;

-- ═══ 5. Captain onboarding with the join code ═══════════════════════════════════════
-- A draft office is not on the marketplace but IS operating, so it can already recruit.
-- The code is the authority here, not the caller-supplied office id.

select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

do $$
declare
  v_result jsonb;
begin
  v_result := public.submit_captain_request(
    'TEST-PLAT Captain', '+201000099887', null, (select code from _plat_office));

  insert into _plat_results (name, pass, detail)
  values ('Captain request with office A''s join code is accepted',
          v_result ->> 'outcome' = 'submitted', v_result::text);
end $$;

do $$
declare v_err text;
begin
  begin
    perform public.submit_captain_request(
      'TEST-PLAT Captain 2', '+201000099888', null, 'ZZZZZZZZ');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('Captain request with a bogus code is refused',
          v_err like '%invalid_office_code%', v_err);
end $$;

reset role;

insert into _plat_results (name, pass, detail)
select 'The captain request landed in office A''s queue',
       office_id = (select id from _plat_office), office_id::text
  from public.captain_requests where phone_normalized like '%1000099887';

-- ═══ 6. Publishing ══════════════════════════════════════════════════════════════════

select set_config('request.jwt.claims',
  '{"sub":"90f20000-0000-4000-8000-0000000000f1","role":"authenticated"}', true);
set local role authenticated;

insert into _plat_results (name, pass, detail)
select 'Platform admin sees every office including the draft',
       count(*) >= 2, count(*)::text
  from public.platform_list_offices()
 where id in ((select id from _plat_office), 'b0f20000-0000-4000-8000-00000000000b');

-- An office with no description or service areas must not be publishable.
do $$
declare v_err text;
begin
  begin
    perform public.platform_set_office_listing(
      'e0f20000-0000-4000-8000-00000000000e', 'listed');
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _plat_results (name, pass, detail)
  values ('Incomplete office cannot be listed',
          v_err like '%office_profile_incomplete%', v_err);
end $$;

do $$
begin
  perform public.platform_set_office_listing((select id from _plat_office), 'listed');
end $$;

reset role;

insert into _plat_results (name, pass, detail)
select 'Publishing sets listing_status and listed_at',
       listing_status = 'listed' and listed_at is not null,
       listing_status || ' / ' || coalesce(listed_at::text, 'null')
  from public.offices where id = (select id from _plat_office);

select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;

insert into _plat_results (name, pass, detail)
select 'Published office now appears in public_offices', count(*) = 1, count(*)::text
  from public.public_offices where id = (select id from _plat_office);

reset role;

-- Withdrawing hides it again without touching its operational status.
select set_config('request.jwt.claims',
  '{"sub":"90f20000-0000-4000-8000-0000000000f1","role":"authenticated"}', true);
set local role authenticated;
do $$
begin
  perform public.platform_set_office_listing((select id from _plat_office), 'unlisted');
end $$;
reset role;

insert into _plat_results (name, pass, detail)
select 'Withdrawing leaves the office operational',
       listing_status = 'unlisted' and status = 'active',
       listing_status || ' / ' || status
  from public.offices where id = (select id from _plat_office);

select set_config('request.jwt.claims',
  '{"sub":"a0f20000-0000-4000-8000-0000000000ad","role":"authenticated"}', true);
set local role authenticated;
insert into _plat_results (name, pass, detail)
select 'An unlisted office''s own admin can still sign in',
       (public.current_office_context() ->> 'office_id') = (select id::text from _plat_office),
       public.current_office_context() ->> 'listing_status';
reset role;

-- ═══ 7. Existing offices are unaffected ═════════════════════════════════════════════

insert into _plat_results (name, pass, detail)
select 'Every pre-existing office was backfilled to listed',
       count(*) = 0, count(*)::text
  from public.offices
 where listing_status is distinct from 'listed'
   and name not like 'TEST-PLAT%';

insert into _plat_results (name, pass, detail)
select 'Onboarding wrote no clients row for the new operator', count(*) = 0, count(*)::text
  from public.clients where id = 'a0f20000-0000-4000-8000-0000000000ad';

-- ── Verdict ─────────────────────────────────────────────────────────────────────────
do $$
declare bad text;
begin
  select string_agg(name || ' [' || coalesce(detail, 'null') || ']', '; ')
    into bad from _plat_results where not pass;
  if bad is not null then
    raise exception 'PLATFORM ONBOARDING REGRESSION FAILURES: %', bad;
  end if;
end $$;

select name, case when pass then 'PASS' else 'FAIL' end as result, detail
  from _plat_results order by seq;

rollback;
