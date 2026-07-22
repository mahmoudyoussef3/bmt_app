-- ═══════════════════════════════════════════════════════════════════════════════════
-- Regression suite: platform office analytics
-- (migration 20260722140000_platform_office_analytics.sql)
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Covers `platform_office_analytics(int)`: the authorization boundary, the windowing,
-- the revenue definition, and the office scoping of every aggregate.
--
-- The assertions that matter most here are the ones a plausible implementation gets
-- wrong rather than the ones it gets right by construction:
--
--   * revenue counts APPROVED payments only. A pending or submitted payment is money a
--     passenger has committed and nobody has accepted — counting it inflates the
--     platform's income with cash it may never receive, and the difference between the
--     two is exactly what the 'awaiting review' figure exists to show.
--   * the window is a real boundary. A booking one day older than the window must not
--     appear in the windowed counts while still appearing in the lifetime ones.
--   * 'upcoming' means bookable: dated today or later AND still open_for_booking. A
--     completed trip dated next week is not something a passenger can buy.
--   * every aggregate is office-scoped. Office P and office Q both trade in this
--     fixture, with deliberately different amounts, so any total that leaked across
--     offices reads as the sum and fails.
--
-- Self-contained: builds its own platform admin, two offices and their traffic, then
-- ROLLS EVERYTHING BACK.
--
-- Run as postgres (e.g. the Management API query endpoint): the script switches to
-- `role authenticated` with a forged request.jwt.claims to act as each principal.
--
-- Output: one row per check; the final DO block raises listing any failures.

begin;

create temporary table _poa_results (seq serial, name text, pass boolean, detail text)
  on commit drop;
grant all on _poa_results to authenticated;
grant all on _poa_results_seq_seq to authenticated;

-- ── Fixtures (all rolled back) ──────────────────────────────────────────────────────
--
-- Office P: trading. One route; three trips (one bookable in future, one completed in
--           window, one past-dated but still open — the "stale" case); four bookings
--           spanning approved / pending / cancelled / out-of-window.
-- Office Q: listed but inert. A route and nothing else — the marketplace dead end, and
--           the office whose zero must not be contaminated by P's numbers.

do $fix$
begin
  insert into public.offices (id, name, slug, status, listing_status, description,
                              service_areas, phone, email, created_at)
  values
    ('33f40000-0000-4000-8000-00000000003a', 'TEST-POA Office P', 'test-poa-p',
     'active', 'listed', 'مكتب اختبار التحليلات', array['TESTPOA-Alex'],
     '+201000000003', 'p@test-poa.invalid', now() - interval '200 days'),
    ('44f40000-0000-4000-8000-00000000004a', 'TEST-POA Office Q', 'test-poa-q',
     'active', 'listed', 'مكتب اختبار خامل', array['TESTPOA-Cairo'],
     '+201000000004', 'q@test-poa.invalid', now() - interval '200 days');

  insert into auth.users (id, email, raw_user_meta_data) values
    ('99f40000-0000-4000-8000-0000000000f9', 'test-poa-platadmin@poa.invalid',
     '{"full_name":"TEST-POA Platform Admin","role":"office_user"}'::jsonb),
    ('33f40000-0000-4000-8000-0000000000d3', 'test-poa-op-p@poa.invalid',
     '{"full_name":"TEST-POA Owner P","role":"office_user"}'::jsonb);

  -- The platform admin is an operator of Q, not of P — same reasoning as the
  -- management suite: what an admin can measure must not depend on where they work.
  insert into public.office_users
        (office_id, user_id, username, full_name, role, status, created_at) values
    ('44f40000-0000-4000-8000-00000000004a', '99f40000-0000-4000-8000-0000000000f9',
     'test-poa-platadmin', 'TEST-POA Platform Admin', 'dashboard_admin', 'active',
     now() - interval '1 hour'),
    ('33f40000-0000-4000-8000-00000000003a', '33f40000-0000-4000-8000-0000000000d3',
     'test-poa-owner-p', 'TEST-POA Owner P', 'dashboard_admin', 'active',
     now() - interval '2 hour');

  insert into public.platform_admins (user_id, note)
  values ('99f40000-0000-4000-8000-0000000000f9', 'TEST-POA fixture');

  insert into public.operation_routes
        (id, name, start_city, end_city, status, route_code, office_id)
  values
    ('33f40000-0000-4000-8000-0000000000a3', 'TEST-POA Route P', 'CityP1', 'CityP2',
     'active', 'RT-TEST-POA-P', '33f40000-0000-4000-8000-00000000003a'),
    ('44f40000-0000-4000-8000-0000000000a4', 'TEST-POA Route Q', 'CityQ1', 'CityQ2',
     'active', 'RT-TEST-POA-Q', '44f40000-0000-4000-8000-00000000004a');

  -- P's trips. Capacity 4 each; seat rows below make occupancy checkable.
  insert into public.operation_trips
        (id, trip_code, route_id, trip_date, departure_time, arrival_time,
         status, capacity, ticket_price, currency, office_id)
  values
    -- Bookable: future AND open.
    ('33f40000-0000-4000-8000-0000000000b1', 'TR-TEST-POA-P1',
     '33f40000-0000-4000-8000-0000000000a3', current_date + 3, '09:00', '11:00',
     'open_for_booking', 4, 100, 'EGP', '33f40000-0000-4000-8000-00000000003a'),
    -- Future but COMPLETED: not bookable. A naive `trip_date >= today` counts this.
    ('33f40000-0000-4000-8000-0000000000b2', 'TR-TEST-POA-P2',
     '33f40000-0000-4000-8000-0000000000a3', current_date + 5, '09:00', '11:00',
     'completed', 4, 100, 'EGP', '33f40000-0000-4000-8000-00000000003a'),
    -- Past-dated and still open: the stale case, never auto-closed by design.
    ('33f40000-0000-4000-8000-0000000000b3', 'TR-TEST-POA-P3',
     '33f40000-0000-4000-8000-0000000000a3', current_date - 2, '09:00', '11:00',
     'open_for_booking', 4, 100, 'EGP', '33f40000-0000-4000-8000-00000000003a'),
    -- Well outside a 30-day window: lifetime only.
    ('33f40000-0000-4000-8000-0000000000b4', 'TR-TEST-POA-P4',
     '33f40000-0000-4000-8000-0000000000a3', current_date - 120, '09:00', '11:00',
     'completed', 4, 100, 'EGP', '33f40000-0000-4000-8000-00000000003a');

  -- Seats on the one in-window bookable trip: 4 offered, 1 paid + 1 reserved = 50%.
  insert into public.trip_seats (trip_id, seat_label, seat_row, seat_column, state)
  values
    ('33f40000-0000-4000-8000-0000000000b1', 'A1', 1, 1, 'paid'),
    ('33f40000-0000-4000-8000-0000000000b1', 'A2', 1, 2, 'reserved'),
    ('33f40000-0000-4000-8000-0000000000b1', 'B1', 2, 1, 'available'),
    ('33f40000-0000-4000-8000-0000000000b1', 'B2', 2, 2, 'available');

  -- P's bookings. The payment_status vocabulary is the point of this block.
  insert into public.operation_bookings
        (id, passenger_name, phone, route, trip_time, trip_date, seat, payment_method,
         status, payment_status, payment_amount, office_id, created_at)
  values
    -- Approved and in window: the only row that is revenue.
    ('33f40000-0000-4000-8000-0000000000c1', 'TEST-POA Pax 1', '+201555000101',
     'TEST-POA Route P', '09:00', current_date + 3, 'A1', 'cash',
     'confirmed', 'approved', 500, '33f40000-0000-4000-8000-00000000003a',
     now() - interval '3 days'),
    -- Submitted: money committed, nobody has decided. Never revenue.
    ('33f40000-0000-4000-8000-0000000000c2', 'TEST-POA Pax 2', '+201555000102',
     'TEST-POA Route P', '09:00', current_date + 3, 'A2', 'wallet',
     'reserved', 'submitted', 300, '33f40000-0000-4000-8000-00000000003a',
     now() - interval '2 days'),
    -- Cancelled: not revenue, and not part of the awaiting-review workload either.
    ('33f40000-0000-4000-8000-0000000000c3', 'TEST-POA Pax 3', '+201555000103',
     'TEST-POA Route P', '09:00', current_date - 2, 'B1', 'cash',
     'cancelled', 'pending', 200, '33f40000-0000-4000-8000-00000000003a',
     now() - interval '4 days'),
    -- Approved but 120 days old: lifetime revenue, not window revenue.
    ('33f40000-0000-4000-8000-0000000000c4', 'TEST-POA Pax 4', '+201555000104',
     'TEST-POA Route P', '09:00', current_date - 120, 'B2', 'cash',
     'confirmed', 'approved', 700, '33f40000-0000-4000-8000-00000000003a',
     now() - interval '120 days');
end $fix$;

-- ═══ 1. Authorization ═══════════════════════════════════════════════════════════════
-- Same boundary as every other platform RPC, asserted from the realistic attacker's
-- seat: an authenticated office admin whose client could forge is_platform_admin.

select set_config('request.jwt.claims',
  '{"sub":"33f40000-0000-4000-8000-0000000000d3","role":"authenticated"}', true);
set local role authenticated;

do $$
declare v_err text;
begin
  begin
    perform public.platform_office_analytics(30);
    v_err := 'NO ERROR RAISED';
  exception when others then v_err := SQLERRM;
  end;
  insert into _poa_results (name, pass, detail)
  values ('Office admin cannot read platform analytics',
          v_err like '%platform_admin_required%', v_err);
end $$;

reset role;

insert into _poa_results (name, pass, detail)
select 'Analytics is not granted to anon',
       count(*) = 0, coalesce(string_agg(p.proname, ', '), 'none')
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname = 'platform_office_analytics'
   and has_function_privilege('anon', p.oid, 'execute');

insert into _poa_results (name, pass, detail)
select 'Analytics is SECURITY DEFINER and STABLE, never volatile',
       bool_and(p.prosecdef) and bool_and(p.provolatile = 's'), count(*)::text
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'platform_office_analytics';

-- ═══ 2. Per-office aggregates ═══════════════════════════════════════════════════════

select set_config('request.jwt.claims',
  '{"sub":"99f40000-0000-4000-8000-0000000000f9","role":"authenticated"}', true);
set local role authenticated;

create temporary view _poa_p as
select o.*
  from jsonb_array_elements(public.platform_office_analytics(30) -> 'offices') e(o),
       lateral jsonb_to_record(e.o) as o(
         office_id uuid, trips_total int, trips_recent int, trips_upcoming int,
         trips_stale int, trips_completed int, bookings_total int,
         bookings_recent int, bookings_confirmed int, bookings_cancelled int,
         revenue_total numeric, revenue_recent numeric,
         payments_awaiting_review int, payments_awaiting_amount numeric,
         seats_offered int, seats_sold int, active_admins int
       )
 where o.office_id = '33f40000-0000-4000-8000-00000000003a';

-- Revenue is approved-only. Anything else and this reads 800 (approved+submitted) or
-- 1000 (everything with an amount) instead of 500.
insert into _poa_results (name, pass, detail)
select 'Window revenue counts approved payments only',
       revenue_recent = 500, revenue_recent::text
  from _poa_p;

insert into _poa_results (name, pass, detail)
select 'Lifetime revenue includes the out-of-window approved booking',
       revenue_total = 1200, revenue_total::text
  from _poa_p;

-- The window is a real boundary, not a label.
insert into _poa_results (name, pass, detail)
select 'The 120-day-old booking is outside the 30-day window',
       bookings_recent = 3 and bookings_total = 4,
       format('recent=%s total=%s', bookings_recent, bookings_total)
  from _poa_p;

-- Pending/submitted are the workload figure, and a cancelled booking is not workload:
-- nobody is waiting on it. 3 would mean the cancelled row leaked in.
insert into _poa_results (name, pass, detail)
select 'Awaiting review counts uncancelled pending payments only',
       payments_awaiting_review = 1 and payments_awaiting_amount = 300,
       format('count=%s amount=%s', payments_awaiting_review,
              payments_awaiting_amount)
  from _poa_p;

-- Bookable means future AND open. The completed trip dated +5 days must not count.
insert into _poa_results (name, pass, detail)
select 'Upcoming counts only trips a passenger can actually book',
       trips_upcoming = 1, trips_upcoming::text
  from _poa_p;

insert into _poa_results (name, pass, detail)
select 'Past-dated open trips are reported as stale',
       trips_stale = 1, trips_stale::text
  from _poa_p;

insert into _poa_results (name, pass, detail)
select 'Trip counts separate the window from the lifetime',
       trips_recent = 3 and trips_total = 4,
       format('recent=%s total=%s', trips_recent, trips_total)
  from _poa_p;

-- Read from trip_seats, because operation_trips.booked_seats is unmaintained.
insert into _poa_results (name, pass, detail)
select 'Occupancy is read from seat states: 2 sold of 4 offered',
       seats_offered = 4 and seats_sold = 2,
       format('offered=%s sold=%s', seats_offered, seats_sold)
  from _poa_p;

insert into _poa_results (name, pass, detail)
select 'Cancelled bookings are counted as cancelled',
       bookings_cancelled = 1 and bookings_confirmed = 2,
       format('cancelled=%s confirmed=%s', bookings_cancelled, bookings_confirmed)
  from _poa_p;

-- ═══ 3. Office scoping ══════════════════════════════════════════════════════════════
-- Office Q trades nothing. Every one of its figures must be zero: if any aggregate
-- were computed platform-wide and joined per office, these would carry P's numbers.

create temporary view _poa_q as
select o.*
  from jsonb_array_elements(public.platform_office_analytics(30) -> 'offices') e(o),
       lateral jsonb_to_record(e.o) as o(
         office_id uuid, trips_total int, trips_upcoming int, bookings_total int,
         revenue_total numeric, revenue_recent numeric, seats_offered int,
         payments_awaiting_review int, active_admins int
       )
 where o.office_id = '44f40000-0000-4000-8000-00000000004a';

insert into _poa_results (name, pass, detail)
select 'An office that never traded reports zeros, not the platform total',
       trips_total = 0 and bookings_total = 0 and revenue_total = 0
       and seats_offered = 0 and payments_awaiting_review = 0,
       format('trips=%s bookings=%s revenue=%s seats=%s awaiting=%s',
              trips_total, bookings_total, revenue_total, seats_offered,
              payments_awaiting_review)
  from _poa_q;

-- The dead-end case the UI raises as critical: listed, active, nothing to sell.
insert into _poa_results (name, pass, detail)
select 'A listed office with nothing on sale reports zero upcoming trips',
       trips_upcoming = 0, trips_upcoming::text
  from _poa_q;

insert into _poa_results (name, pass, detail)
select 'Every office on the platform gets a row, including the inert one',
       count(*) = 2, count(*)::text
  from jsonb_array_elements(public.platform_office_analytics(30) -> 'offices') e(o)
 where (e.o ->> 'office_id')::uuid in (
   '33f40000-0000-4000-8000-00000000003a',
   '44f40000-0000-4000-8000-00000000004a');

-- ═══ 4. Totals and trend ════════════════════════════════════════════════════════════

insert into _poa_results (name, pass, detail)
select 'Totals classify the two offices as one trading and one never-traded',
       (t ->> 'trading')::int >= 1 and (t ->> 'never_traded')::int >= 1,
       t::text
  from (select public.platform_office_analytics(30) -> 'totals' as t) s;

insert into _poa_results (name, pass, detail)
select 'Totals count the listed office with no bookable trips',
       (t ->> 'listed_without_trips')::int >= 1, t ->> 'listed_without_trips'
  from (select public.platform_office_analytics(30) -> 'totals' as t) s;

-- Quiet days must be present as zeros: a series that skips them draws a business that
-- never slowed down.
insert into _poa_results (name, pass, detail)
select 'The trend spans the whole window, including days with no bookings',
       count(*) = 31, count(*)::text
  from jsonb_array_elements(public.platform_office_analytics(30) -> 'trend');

insert into _poa_results (name, pass, detail)
select 'A 7-day window returns a 7-day trend',
       count(*) = 8, count(*)::text
  from jsonb_array_elements(public.platform_office_analytics(7) -> 'trend');

-- The window is a lens, not an authorization input: absurd values are clamped so the
-- caller gets a sane chart rather than an exception.
insert into _poa_results (name, pass, detail)
select 'An out-of-range window is clamped, not rejected',
       (public.platform_office_analytics(100000) ->> 'window_days')::int = 365
       and (public.platform_office_analytics(0) ->> 'window_days')::int = 1,
       format('%s / %s',
              public.platform_office_analytics(100000) ->> 'window_days',
              public.platform_office_analytics(0) ->> 'window_days');

-- ═══ 5. What analytics must NOT return ══════════════════════════════════════════════
-- The boundary 090000 drew and this migration keeps: aggregates, never rows. A single
-- passenger name, phone or receipt anywhere in the payload means the function has
-- become a window onto booking data instead of a measure of it.

insert into _poa_results (name, pass, detail)
select 'The payload carries no passenger PII or receipts',
       payload not like '%TEST-POA Pax%'
       and payload not like '%+20155500010%'
       and payload not like '%passenger_name%'
       and payload not like '%receipt%',
       left(payload, 120)
  from (select public.platform_office_analytics(30)::text as payload) s;

insert into _poa_results (name, pass, detail)
select 'The payload carries no join codes',
       payload not like '%join_code%', 'checked'
  from (select public.platform_office_analytics(30)::text as payload) s;

reset role;

-- ═══ 6. Nothing pre-existing was disturbed ══════════════════════════════════════════

insert into _poa_results (name, pass, detail)
select 'The management-era read functions were not redefined',
       count(*) = 2, count(*)::text
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('platform_list_offices', 'platform_office_details');

-- ── Verdict ─────────────────────────────────────────────────────────────────────────
do $$
declare bad text;
begin
  select string_agg(name || ' [' || coalesce(detail, 'null') || ']', '; ')
    into bad from _poa_results where not pass;
  if bad is not null then
    raise exception 'PLATFORM OFFICE ANALYTICS REGRESSION FAILURES: %', bad;
  end if;
end $$;

select name, case when pass then 'PASS' else 'FAIL' end as result, detail
  from _poa_results order by seq;

rollback;
