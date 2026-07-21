-- ═══════════════════════════════════════════════════════════════════════════════════
-- Regression suite: captain session context + captain_messages office scoping
-- (migration 20260721130000_captain_session_context_and_messages.sql)
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Builds two offices, two captains and two operators, exercises the session-restore
-- RPC and the message policies from each principal, then ROLLS EVERYTHING BACK.
-- Leaves no trace on success or failure. Run as postgres via the Management API.

begin;

create temporary table _cap_results (seq serial, name text, pass boolean, detail text)
  on commit drop;
grant all on _cap_results to authenticated;
grant all on _cap_results_seq_seq to authenticated;

do $fix$
begin
  insert into public.offices (id, name, slug, status, description) values
    ('a0f20000-0000-4000-8000-00000000000a', 'TEST-CAP Office A', 'test-cap-a',
     'active', 'captain regression fixture'),
    ('b0f20000-0000-4000-8000-00000000000b', 'TEST-CAP Office B', 'test-cap-b',
     'active', 'captain regression fixture'),
    ('c0f20000-0000-4000-8000-00000000000c', 'TEST-CAP Office Paused', 'test-cap-c',
     'paused', 'captain regression fixture');

  insert into public.operation_routes
        (id, name, start_city, end_city, status, route_code, office_id) values
    ('a0f20000-0000-4000-8000-0000000000a1', 'TEST-CAP Route A', 'CapA1', 'CapA2',
     'active', 'RT-TEST-CAP-A', 'a0f20000-0000-4000-8000-00000000000a'),
    ('b0f20000-0000-4000-8000-0000000000b1', 'TEST-CAP Route B', 'CapB1', 'CapB2',
     'active', 'RT-TEST-CAP-B', 'b0f20000-0000-4000-8000-00000000000b');

  -- Principals: a captain per office (+ one at a paused office), two operators.
  insert into auth.users (id, email, phone, raw_user_meta_data) values
    ('a0f20000-0000-4000-8000-0000000000ac', 'test-cap-a@cap.invalid',
     '+201000000901', '{"full_name":"TEST-CAP Captain A"}'::jsonb),
    ('b0f20000-0000-4000-8000-0000000000bc', 'test-cap-b@cap.invalid',
     '+201000000902', '{"full_name":"TEST-CAP Captain B"}'::jsonb),
    ('c0f20000-0000-4000-8000-0000000000cc', 'test-cap-c@cap.invalid',
     '+201000000903', '{"full_name":"TEST-CAP Captain Paused"}'::jsonb),
    -- Operators carry a phone only because `handle_new_client_user()` mirrors
    -- every new auth user into `clients`, whose phone is globally unique — two
    -- blank ones collide.
    ('a0f20000-0000-4000-8000-0000000000ad', 'test-cap-op-a@cap.invalid',
     '+201000000904', '{"full_name":"TEST-CAP Op A"}'::jsonb),
    ('b0f20000-0000-4000-8000-0000000000bd', 'test-cap-op-b@cap.invalid',
     '+201000000905', '{"full_name":"TEST-CAP Op B"}'::jsonb);

  insert into public.office_users (office_id, user_id, username, role, status) values
    ('a0f20000-0000-4000-8000-00000000000a', 'a0f20000-0000-4000-8000-0000000000ad',
     'test-cap-op-a', 'dashboard_admin', 'active'),
    ('b0f20000-0000-4000-8000-00000000000b', 'b0f20000-0000-4000-8000-0000000000bd',
     'test-cap-op-b', 'dashboard_admin', 'active');

  -- Captain A is linked by user_id; captain B is deliberately UNLINKED so the
  -- phone-match + auto-link path is exercised; captain C sits at a paused office.
  insert into public.drivers
        (id, full_name, phone, emergency_phone, address, national_id,
         license_number, license_expiry_date, hire_date, status, employee_code,
         office_id, user_id) values
    ('a0f20000-0000-4000-8000-0000000000a3', 'TEST-CAP Captain A', '+201000000901',
     '+201000000911', 'TEST-CAP address A', 'TESTCAPNID0000001', 'TESTCAPLIC0001',
     current_date + 400, current_date - 100, 'active', 'CAP-TEST-A',
     'a0f20000-0000-4000-8000-00000000000a', 'a0f20000-0000-4000-8000-0000000000ac'),
    ('b0f20000-0000-4000-8000-0000000000b3', 'TEST-CAP Captain B', '+201000000902',
     '+201000000912', 'TEST-CAP address B', 'TESTCAPNID0000002', 'TESTCAPLIC0002',
     current_date + 400, current_date - 100, 'active', 'CAP-TEST-B',
     'b0f20000-0000-4000-8000-00000000000b', null),
    ('c0f20000-0000-4000-8000-0000000000c3', 'TEST-CAP Captain Paused',
     '+201000000903', '+201000000913', 'TEST-CAP address C', 'TESTCAPNID0000003',
     'TESTCAPLIC0003', current_date + 400, current_date - 100, 'active',
     'CAP-TEST-C', 'c0f20000-0000-4000-8000-00000000000c',
     'c0f20000-0000-4000-8000-0000000000cc');

  insert into public.operation_trips
        (id, trip_code, route_id, driver_id, trip_date, departure_time,
         arrival_time, status, capacity, ticket_price, currency) values
    ('a0f20000-0000-4000-8000-0000000000a4', 'TR-TEST-CAP-A',
     'a0f20000-0000-4000-8000-0000000000a1', 'a0f20000-0000-4000-8000-0000000000a3',
     current_date + 1, '09:00', '11:00', 'open_for_booking', 4, 100, 'EGP'),
    ('b0f20000-0000-4000-8000-0000000000b4', 'TR-TEST-CAP-B',
     'b0f20000-0000-4000-8000-0000000000b1', 'b0f20000-0000-4000-8000-0000000000b3',
     current_date + 1, '09:00', '11:00', 'open_for_booking', 4, 100, 'EGP');
end $fix$;

-- ── 1. Session restore (the app-relaunch path) ─────────────────────────────────────
select set_config('request.jwt.claims',
  '{"sub":"a0f20000-0000-4000-8000-0000000000ac","role":"authenticated"}', true);
set local role authenticated;

insert into _cap_results (name, pass, detail)
select 'Linked captain restores their own driver + office',
       ctx ->> 'driver_id' = 'a0f20000-0000-4000-8000-0000000000a3'
   and ctx ->> 'office_id' = 'a0f20000-0000-4000-8000-00000000000a'
   and ctx ->> 'office_name' = 'TEST-CAP Office A',
       coalesce(ctx::text, 'null')
  from (select public.captain_session_context() ctx) s;

reset role;
select set_config('request.jwt.claims',
  '{"sub":"b0f20000-0000-4000-8000-0000000000bc","role":"authenticated"}', true);
set local role authenticated;

insert into _cap_results (name, pass, detail)
select 'Unlinked captain resolves by phone, gets office B',
       ctx ->> 'driver_id' = 'b0f20000-0000-4000-8000-0000000000b3'
   and ctx ->> 'office_id' = 'b0f20000-0000-4000-8000-00000000000b',
       coalesce(ctx::text, 'null')
  from (select public.captain_session_context() ctx) s;

reset role;

insert into _cap_results (name, pass, detail)
select 'Phone match auto-linked drivers.user_id',
       user_id = 'b0f20000-0000-4000-8000-0000000000bc', coalesce(user_id::text, 'null')
  from public.drivers where id = 'b0f20000-0000-4000-8000-0000000000b3';

-- A captain of a paused office has no operational context.
select set_config('request.jwt.claims',
  '{"sub":"c0f20000-0000-4000-8000-0000000000cc","role":"authenticated"}', true);
set local role authenticated;

insert into _cap_results (name, pass, detail)
select 'Captain of a paused office gets no context',
       public.captain_session_context() is null,
       coalesce(public.captain_session_context()::text, 'null');

reset role;

-- A signed-in non-captain (an operator) is not a captain — a fact, not an error.
select set_config('request.jwt.claims',
  '{"sub":"a0f20000-0000-4000-8000-0000000000ad","role":"authenticated"}', true);
set local role authenticated;

insert into _cap_results (name, pass, detail)
select 'Non-captain user gets null context, no exception',
       public.captain_session_context() is null, 'ok';

reset role;

insert into _cap_results (name, pass, detail)
select 'captain_session_context is not anon-executable',
       not has_function_privilege('anon', 'public.captain_session_context()', 'execute'),
       'anon execute';

-- ── 2. captain_messages: driver scoping ────────────────────────────────────────────
insert into public.captain_messages (trip_id, sender_type, body)
values ('a0f20000-0000-4000-8000-0000000000a4', 'operations',
        'TEST-CAP message to A'),
       ('b0f20000-0000-4000-8000-0000000000b4', 'operations',
        'TEST-CAP message to B');

select set_config('request.jwt.claims',
  '{"sub":"a0f20000-0000-4000-8000-0000000000ac","role":"authenticated"}', true);
set local role authenticated;

insert into _cap_results (name, pass, detail)
select 'Captain A sees only their own trip thread', count(*) = 1, count(*)::text
  from public.captain_messages where body like 'TEST-CAP%';

insert into _cap_results (name, pass, detail)
select 'Captain A cannot see captain B thread', count(*) = 0, count(*)::text
  from public.captain_messages
 where trip_id = 'b0f20000-0000-4000-8000-0000000000b4';

-- The captain can reply on their own trip.
do $$
declare n int;
begin
  insert into public.captain_messages (trip_id, sender_type, body)
  values ('a0f20000-0000-4000-8000-0000000000a4', 'driver',
          'TEST-CAP reply from A');
  get diagnostics n = row_count;
  insert into _cap_results (name, pass, detail)
  values ('Captain A can reply on their own trip', n = 1, n::text);
exception when others then
  insert into _cap_results (name, pass, detail)
  values ('Captain A can reply on their own trip', false, sqlerrm);
end $$;

-- Writing into another captain's thread must be refused by WITH CHECK.
do $$
begin
  insert into public.captain_messages (trip_id, sender_type, body)
  values ('b0f20000-0000-4000-8000-0000000000b4', 'driver',
          'TEST-CAP cross-captain write');
  insert into _cap_results (name, pass, detail)
  values ('Captain A cannot write into captain B thread', false, 'insert succeeded');
exception when others then
  insert into _cap_results (name, pass, detail)
  values ('Captain A cannot write into captain B thread', true, 'blocked');
end $$;

reset role;

-- ── 3. captain_messages: operator scoping (the policy that was broken) ─────────────
select set_config('request.jwt.claims',
  '{"sub":"a0f20000-0000-4000-8000-0000000000ad","role":"authenticated"}', true);
set local role authenticated;

insert into _cap_results (name, pass, detail)
select 'Operator A sees their office threads (was: none at all)',
       count(*) >= 1, count(*)::text
  from public.captain_messages
 where trip_id = 'a0f20000-0000-4000-8000-0000000000a4';

insert into _cap_results (name, pass, detail)
select 'Operator A cannot see office B threads', count(*) = 0, count(*)::text
  from public.captain_messages
 where trip_id = 'b0f20000-0000-4000-8000-0000000000b4';

do $$
declare n int;
begin
  insert into public.captain_messages (trip_id, sender_type, body)
  values ('a0f20000-0000-4000-8000-0000000000a4', 'operations',
          'TEST-CAP dispatch to own captain');
  get diagnostics n = row_count;
  insert into _cap_results (name, pass, detail)
  values ('Operator A can message their own captain', n = 1, n::text);
exception when others then
  insert into _cap_results (name, pass, detail)
  values ('Operator A can message their own captain', false, sqlerrm);
end $$;

do $$
begin
  insert into public.captain_messages (trip_id, sender_type, body)
  values ('b0f20000-0000-4000-8000-0000000000b4', 'operations',
          'TEST-CAP cross-office dispatch');
  insert into _cap_results (name, pass, detail)
  values ('Operator A cannot message office B captain', false, 'insert succeeded');
exception when others then
  insert into _cap_results (name, pass, detail)
  values ('Operator A cannot message office B captain', true, 'blocked');
end $$;

reset role;

insert into _cap_results (name, pass, detail)
select 'anon holds no captain_messages privileges', count(*) = 0, count(*)::text
  from information_schema.role_table_grants
 where table_name = 'captain_messages' and grantee = 'anon';

-- ── Verdict ─────────────────────────────────────────────────────────────────────────
do $$
declare bad text;
begin
  select string_agg(name || ' [' || coalesce(detail, 'null') || ']', '; ')
    into bad from _cap_results where not pass;
  if bad is not null then
    raise exception 'CAPTAIN REGRESSION FAILURES: %', bad;
  end if;
end $$;

select name, case when pass then 'PASS' else 'FAIL' end as result, detail
  from _cap_results order by seq;

rollback;
