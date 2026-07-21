-- ═══════════════════════════════════════════════════════════════════════════════════
-- Regression suite: office attribution for support_tickets / refund_requests
-- (migration 20260721120000_ticket_refund_office_attribution.sql)
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Self-contained: builds two throwaway offices + principals, exercises the sync
-- triggers, the RLS boundaries and the alert routing, then ROLLS EVERYTHING BACK.
-- Safe to run against any environment where the migration is applied; it leaves no
-- trace either on success or on failure (a raised exception aborts the transaction).
--
-- Run it as postgres (e.g. via the Management API query endpoint):
--   the script switches to `role authenticated` + a forged request.jwt.claims to act
--   as each principal, and back to postgres for RLS-bypassing truth assertions.
--
-- Output: one row per check; the final DO block raises listing any failures.

begin;

-- ── Fixtures (all rolled back) ──────────────────────────────────────────────────────
create temporary table _attr_results (seq serial, name text, pass boolean, detail text)
  on commit drop;
grant all on _attr_results to authenticated;
grant all on _attr_results_seq_seq to authenticated;

do $fix$
begin
  insert into public.offices (id, name, slug, status, description) values
    ('a0f10000-0000-4000-8000-00000000000a', 'TEST-ATTR Office A', 'test-attr-a',
     'active', 'attribution regression fixture'),
    ('b0f10000-0000-4000-8000-00000000000b', 'TEST-ATTR Office B', 'test-attr-b',
     'active', 'attribution regression fixture');

  insert into public.operation_routes
        (id, name, start_city, end_city, status, route_code, office_id) values
    ('a0f10000-0000-4000-8000-0000000000a1', 'TEST-ATTR Route A', 'CityA1', 'CityA2',
     'active', 'RT-TEST-ATTR-A', 'a0f10000-0000-4000-8000-00000000000a'),
    ('b0f10000-0000-4000-8000-0000000000b1', 'TEST-ATTR Route B', 'CityB1', 'CityB2',
     'active', 'RT-TEST-ATTR-B', 'b0f10000-0000-4000-8000-00000000000b');

  insert into public.operation_trips
        (id, trip_code, route_id, trip_date, departure_time, arrival_time,
         status, capacity, ticket_price, currency) values
    ('a0f10000-0000-4000-8000-0000000000a2', 'TR-TEST-ATTR-A',
     'a0f10000-0000-4000-8000-0000000000a1', current_date + 3, '09:00', '11:00',
     'open_for_booking', 4, 100, 'EGP'),
    ('b0f10000-0000-4000-8000-0000000000b2', 'TR-TEST-ATTR-B',
     'b0f10000-0000-4000-8000-0000000000b1', current_date + 3, '09:00', '11:00',
     'open_for_booking', 4, 100, 'EGP');

  -- Principals: one client, one operator per office. handle_new_client_user()
  -- auto-creates the public.clients rows from the metadata; the phones must be
  -- unique or that trigger collides with existing empty-phone rows.
  insert into auth.users (id, email, raw_user_meta_data) values
    ('c0f10000-0000-4000-8000-0000000000c1', 'test-attr-client@attr.invalid',
     '{"full_name":"TEST-ATTR Client","phone":"+20100TESTATTR1"}'::jsonb),
    ('a0f10000-0000-4000-8000-0000000000ad', 'test-attr-op-a@attr.invalid',
     '{"full_name":"TEST-ATTR Op A","phone":"+20100TESTATTR2"}'::jsonb),
    ('b0f10000-0000-4000-8000-0000000000bd', 'test-attr-op-b@attr.invalid',
     '{"full_name":"TEST-ATTR Op B","phone":"+20100TESTATTR3"}'::jsonb);

  insert into public.office_users (office_id, user_id, username, role, status) values
    ('a0f10000-0000-4000-8000-00000000000a', 'a0f10000-0000-4000-8000-0000000000ad',
     'test-attr-op-a', 'dashboard_admin', 'active'),
    ('b0f10000-0000-4000-8000-00000000000b', 'b0f10000-0000-4000-8000-0000000000bd',
     'test-attr-op-b', 'dashboard_admin', 'active');

  insert into public.operation_bookings
        (id, client_id, trip_id, passenger_name, phone, route, trip_time,
         trip_date, seat, payment_method)
  values
    ('a0f10000-0000-4000-8000-0000000000a3',
     'c0f10000-0000-4000-8000-0000000000c1',
     'a0f10000-0000-4000-8000-0000000000a2',
     'TEST-ATTR Client', '+20100TESTATTR', 'CityA1 → CityA2', '09:00',
     current_date + 3, 'A1', 'cash');
end $fix$;

-- ── 1. Derivation (as postgres — trigger correctness, not RLS) ─────────────────────
insert into public.support_tickets (id, client_id, ticket_number, category, title,
                                    description, priority, related_trip_id)
values ('11f10000-0000-4000-8000-000000000001',
        'c0f10000-0000-4000-8000-0000000000c1', '#TK-TEST-ATTR-1', 'trip',
        'TEST-ATTR t1 trip-linked', 'x', 'medium',
        'a0f10000-0000-4000-8000-0000000000a2');

insert into public.support_tickets (id, client_id, ticket_number, category, title,
                                    description, priority, related_booking_id)
values ('11f10000-0000-4000-8000-000000000002',
        'c0f10000-0000-4000-8000-0000000000c1', '#TK-TEST-ATTR-2', 'booking',
        'TEST-ATTR t2 booking-linked', 'x', 'medium',
        'a0f10000-0000-4000-8000-0000000000a3');

-- Garbage legacy booking reference must not crash and must stay platform-level.
insert into public.support_tickets (id, client_id, ticket_number, category, title,
                                    description, priority, related_booking_id)
values ('11f10000-0000-4000-8000-000000000006',
        'c0f10000-0000-4000-8000-0000000000c1', '#TK-TEST-ATTR-6', 'other',
        'TEST-ATTR t6 garbage booking ref', 'x', 'medium', 'BK-NOT-A-UUID');

-- Office B ticket for the isolation checks.
insert into public.support_tickets (id, client_id, ticket_number, category, title,
                                    description, priority, related_trip_id)
values ('11f10000-0000-4000-8000-00000000000b',
        'c0f10000-0000-4000-8000-0000000000c1', '#TK-TEST-ATTR-B', 'trip',
        'TEST-ATTR tB office-B trip', 'x', 'medium',
        'b0f10000-0000-4000-8000-0000000000b2');

insert into _attr_results (name, pass, detail)
select 'T1 trip-linked ticket → office A',
       office_id = 'a0f10000-0000-4000-8000-00000000000a', office_id::text
  from public.support_tickets where id = '11f10000-0000-4000-8000-000000000001';

insert into _attr_results (name, pass, detail)
select 'T2 booking-linked ticket → office A',
       office_id = 'a0f10000-0000-4000-8000-00000000000a', office_id::text
  from public.support_tickets where id = '11f10000-0000-4000-8000-000000000002';

insert into _attr_results (name, pass, detail)
select 'T6 non-uuid booking ref → platform (NULL), no error',
       office_id is null, office_id::text
  from public.support_tickets where id = '11f10000-0000-4000-8000-000000000006';

-- Refund requests: booking → trip → ticket chain.
insert into public.refund_requests (id, client_id, booking_id, reason, amount)
values ('22f10000-0000-4000-8000-000000000001',
        'c0f10000-0000-4000-8000-0000000000c1',
        'a0f10000-0000-4000-8000-0000000000a3', 'TEST-ATTR r1 booking', 100);

insert into public.refund_requests (id, client_id, trip_id, reason, amount)
values ('22f10000-0000-4000-8000-000000000002',
        'c0f10000-0000-4000-8000-0000000000c1',
        'a0f10000-0000-4000-8000-0000000000a2', 'TEST-ATTR r2 trip', 100);

insert into public.refund_requests (id, client_id, ticket_id, reason, amount)
values ('22f10000-0000-4000-8000-000000000003',
        'c0f10000-0000-4000-8000-0000000000c1',
        '11f10000-0000-4000-8000-000000000001', 'TEST-ATTR r3 ticket', 100);

insert into public.refund_requests (id, client_id, reason, amount)
values ('22f10000-0000-4000-8000-000000000004',
        'c0f10000-0000-4000-8000-0000000000c1', 'TEST-ATTR r4 unlinked', 100);

insert into public.refund_requests (id, client_id, trip_id, reason, amount)
values ('22f10000-0000-4000-8000-00000000000b',
        'c0f10000-0000-4000-8000-0000000000c1',
        'b0f10000-0000-4000-8000-0000000000b2', 'TEST-ATTR rB office B', 100);

insert into _attr_results (name, pass, detail)
select 'R1 booking-linked refund → office A',
       office_id = 'a0f10000-0000-4000-8000-00000000000a', office_id::text
  from public.refund_requests where id = '22f10000-0000-4000-8000-000000000001';

insert into _attr_results (name, pass, detail)
select 'R2 trip-linked refund → office A',
       office_id = 'a0f10000-0000-4000-8000-00000000000a', office_id::text
  from public.refund_requests where id = '22f10000-0000-4000-8000-000000000002';

insert into _attr_results (name, pass, detail)
select 'R3 ticket-linked refund inherits ticket office A',
       office_id = 'a0f10000-0000-4000-8000-00000000000a', office_id::text
  from public.refund_requests where id = '22f10000-0000-4000-8000-000000000003';

insert into _attr_results (name, pass, detail)
select 'R4 unlinked refund (postgres) → platform (NULL)',
       office_id is null, office_id::text
  from public.refund_requests where id = '22f10000-0000-4000-8000-000000000004';

-- Re-derivation when linkage changes; unlinking returns the row to platform level.
update public.support_tickets
   set related_trip_id = 'b0f10000-0000-4000-8000-0000000000b2'
 where id = '11f10000-0000-4000-8000-000000000006';

insert into _attr_results (name, pass, detail)
select 'T6 relinked to office-B trip → office B',
       office_id = 'b0f10000-0000-4000-8000-00000000000b', office_id::text
  from public.support_tickets where id = '11f10000-0000-4000-8000-000000000006';

update public.support_tickets
   set related_trip_id = null, related_booking_id = null
 where id = '11f10000-0000-4000-8000-000000000006';

insert into _attr_results (name, pass, detail)
select 'T6 unlinked again → back to platform (NULL)',
       office_id is null, office_id::text
  from public.support_tickets where id = '11f10000-0000-4000-8000-000000000006';

-- ── 2. Client spoofing (as the signed-in client) ───────────────────────────────────
select set_config('request.jwt.claims',
  '{"sub":"c0f10000-0000-4000-8000-0000000000c1","role":"authenticated"}', true);
set local role authenticated;

-- Forged office_id with no linkage: must be discarded → platform-level.
insert into public.support_tickets (id, client_id, ticket_number, category, title,
                                    description, priority, office_id)
values ('11f10000-0000-4000-8000-000000000003',
        'c0f10000-0000-4000-8000-0000000000c1', '#TK-TEST-ATTR-3', 'other',
        'TEST-ATTR t3 forged office no link', 'x', 'medium',
        'b0f10000-0000-4000-8000-00000000000b');

-- Forged office_id B alongside a real office-A link: the link must win.
insert into public.support_tickets (id, client_id, ticket_number, category, title,
                                    description, priority, related_trip_id, office_id)
values ('11f10000-0000-4000-8000-000000000004',
        'c0f10000-0000-4000-8000-0000000000c1', '#TK-TEST-ATTR-4', 'trip',
        'TEST-ATTR t4 forged office with A link', 'x', 'medium',
        'a0f10000-0000-4000-8000-0000000000a2',
        'b0f10000-0000-4000-8000-00000000000b');

insert into public.refund_requests (id, client_id, reason, amount, office_id)
values ('22f10000-0000-4000-8000-000000000005',
        'c0f10000-0000-4000-8000-0000000000c1', 'TEST-ATTR r5 forged office', 100,
        'b0f10000-0000-4000-8000-00000000000b');

-- Post-filing mutation by the client must be filtered out by RLS. RLS filters
-- blocked UPDATEs silently (0 rows) rather than raising, so assert on row_count.
do $$
declare n int;
begin
  update public.support_tickets
     set related_trip_id = 'b0f10000-0000-4000-8000-0000000000b2'
   where id = '11f10000-0000-4000-8000-000000000004';
  get diagnostics n = row_count;
  insert into _attr_results (name, pass, detail)
  values ('T7 client cannot re-link their ticket after filing', n = 0, n::text);

  update public.refund_requests
     set status = 'approved'
   where id = '22f10000-0000-4000-8000-000000000005';
  get diagnostics n = row_count;
  insert into _attr_results (name, pass, detail)
  values ('R6 client cannot mutate their refund after filing', n = 0, n::text);
end $$;

reset role;

insert into _attr_results (name, pass, detail)
select 'T3 client-forged office_id, no link → platform (NULL)',
       office_id is null, office_id::text
  from public.support_tickets where id = '11f10000-0000-4000-8000-000000000003';

insert into _attr_results (name, pass, detail)
select 'T4 client-forged office_id + office-A link → office A',
       office_id = 'a0f10000-0000-4000-8000-00000000000a', office_id::text
  from public.support_tickets where id = '11f10000-0000-4000-8000-000000000004';

insert into _attr_results (name, pass, detail)
select 'R5 client-forged office_id refund → platform (NULL)',
       office_id is null, office_id::text
  from public.refund_requests where id = '22f10000-0000-4000-8000-000000000005';

-- ── 3. Operator-created general row belongs to their own office ────────────────────
select set_config('request.jwt.claims',
  '{"sub":"a0f10000-0000-4000-8000-0000000000ad","role":"authenticated"}', true);
set local role authenticated;

insert into public.support_tickets (id, ticket_number, category, title,
                                    description, priority)
values ('11f10000-0000-4000-8000-000000000005', '#TK-TEST-ATTR-5', 'other',
        'TEST-ATTR t5 operator general', 'x', 'medium');

reset role;

insert into _attr_results (name, pass, detail)
select 'T5 operator-created unlinked ticket → own office A',
       office_id = 'a0f10000-0000-4000-8000-00000000000a', office_id::text
  from public.support_tickets where id = '11f10000-0000-4000-8000-000000000005';

-- ── 4. RLS isolation ───────────────────────────────────────────────────────────────
select set_config('request.jwt.claims',
  '{"sub":"a0f10000-0000-4000-8000-0000000000ad","role":"authenticated"}', true);
set local role authenticated;

insert into _attr_results (name, pass, detail)
select 'Op A sees exactly the office-A tickets (t1,t2,t4,t5)',
       count(*) = 4, count(*)::text
  from public.support_tickets where ticket_number like '#TK-TEST-ATTR-%'
   and office_id = 'a0f10000-0000-4000-8000-00000000000a';

insert into _attr_results (name, pass, detail)
select 'Op A sees no office-B ticket', count(*) = 0, count(*)::text
  from public.support_tickets
 where id = '11f10000-0000-4000-8000-00000000000b';

insert into _attr_results (name, pass, detail)
select 'Op A sees no platform-level ticket', count(*) = 0, count(*)::text
  from public.support_tickets
 where id in ('11f10000-0000-4000-8000-000000000003',
              '11f10000-0000-4000-8000-000000000006');

insert into _attr_results (name, pass, detail)
select 'Op A sees exactly the office-A refunds (r1,r2,r3)',
       count(*) = 3, count(*)::text
  from public.refund_requests where reason like 'TEST-ATTR%'
   and office_id = 'a0f10000-0000-4000-8000-00000000000a';

insert into _attr_results (name, pass, detail)
select 'Op A sees neither office-B nor platform refunds', count(*) = 0, count(*)::text
  from public.refund_requests
 where id in ('22f10000-0000-4000-8000-00000000000b',
              '22f10000-0000-4000-8000-000000000004',
              '22f10000-0000-4000-8000-000000000005');

reset role;
select set_config('request.jwt.claims',
  '{"sub":"b0f10000-0000-4000-8000-0000000000bd","role":"authenticated"}', true);
set local role authenticated;

insert into _attr_results (name, pass, detail)
select 'Op B sees exactly the office-B ticket (tB)', count(*) = 1, count(*)::text
  from public.support_tickets where ticket_number like '#TK-TEST-ATTR-%';

insert into _attr_results (name, pass, detail)
select 'Op B sees exactly the office-B refund (rB)', count(*) = 1, count(*)::text
  from public.refund_requests where reason like 'TEST-ATTR%';

reset role;
select set_config('request.jwt.claims',
  '{"sub":"c0f10000-0000-4000-8000-0000000000c1","role":"authenticated"}', true);
set local role authenticated;

insert into _attr_results (name, pass, detail)
select 'Client still sees every own ticket incl. platform ones',
       count(*) = 6, count(*)::text
  from public.support_tickets where ticket_number like '#TK-TEST-ATTR-%'
   and client_id = 'c0f10000-0000-4000-8000-0000000000c1';

reset role;

-- ── 5. Operational alert routing ───────────────────────────────────────────────────
insert into _attr_results (name, pass, detail)
select 'Alert for t1 routed to office A', count(*) = 1, count(*)::text
  from public.operational_alerts
 where type = 'support_ticket'
   and data ->> 'ticket_id' = '11f10000-0000-4000-8000-000000000001'
   and office_id = 'a0f10000-0000-4000-8000-00000000000a';

insert into _attr_results (name, pass, detail)
select 'Alert for tB routed to office B, not A', count(*) = 1, count(*)::text
  from public.operational_alerts
 where type = 'support_ticket'
   and data ->> 'ticket_id' = '11f10000-0000-4000-8000-00000000000b'
   and office_id = 'b0f10000-0000-4000-8000-00000000000b';

insert into _attr_results (name, pass, detail)
select 'Platform ticket t3 produced no operational alert', count(*) = 0, count(*)::text
  from public.operational_alerts
 where data ->> 'ticket_id' = '11f10000-0000-4000-8000-000000000003';

insert into _attr_results (name, pass, detail)
select 'Refund r1 alert routed to office A', count(*) = 1, count(*)::text
  from public.operational_alerts
 where type = 'refund_request'
   and data ->> 'refund_id' = '22f10000-0000-4000-8000-000000000001'
   and office_id = 'a0f10000-0000-4000-8000-00000000000a';

insert into _attr_results (name, pass, detail)
select 'Platform refunds r4/r5 produced no operational alert',
       count(*) = 0, count(*)::text
  from public.operational_alerts
 where data ->> 'refund_id' in ('22f10000-0000-4000-8000-000000000004',
                                '22f10000-0000-4000-8000-000000000005');

insert into _attr_results (name, pass, detail)
select 'No TEST-ATTR alert exists without an office', count(*) = 0, count(*)::text
  from public.operational_alerts
 where office_id is null
   and (data ->> 'ticket_id' like '11f10000%' or data ->> 'refund_id' like '22f10000%');

-- ── Verdict ─────────────────────────────────────────────────────────────────────────
do $$
declare bad text;
begin
  select string_agg(name || ' [' || coalesce(detail, 'null') || ']', '; ')
    into bad from _attr_results where not pass;
  if bad is not null then
    raise exception 'ATTRIBUTION REGRESSION FAILURES: %', bad;
  end if;
end $$;

select name, case when pass then 'PASS' else 'FAIL' end as result, detail
  from _attr_results order by seq;

rollback;
