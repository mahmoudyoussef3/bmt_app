-- ═══════════════════════════════════════════════════════════════════════════════════
-- Per-package trip pricing — regression suite
-- ═══════════════════════════════════════════════════════════════════════════════════
-- One number has to survive two very different readers:
--
--     the office prices a package on a stop pair  →  the rider is quoted THAT price
--     the rider books                             →  the receipt shows the same price
--
-- Both halves read `trip_package_prices`. The wizard reads it over PostgREST as anon
-- or as a signed-in rider; `confirm_seat_booking_v2` reads it as definer. When only
-- the rider's read is blocked, nothing errors — the wizard quietly falls back to the
-- catalogue's flat `transport_packages.price` and quotes a number the receipt then
-- contradicts. So this suite impersonates the rider rather than trusting a count run
-- as superuser, which would pass either way.
--
-- That silent failure is how the table shipped: `trip_package_prices_marketplace_read`
-- inlined `join operation_trips`, and a policy's own subquery is itself subject to
-- RLS, so the join returned nothing for exactly the role the policy was written for.
-- Probes 01-02 are the live check; 04-05 guard the bug class, because a predicate can
-- be rewritten to read correctly and still self-block.
--
-- Runs entirely inside BEGIN … ROLLBACK. Nothing survives the run, so it is safe
-- against the production-bound development database.
--
--   supabase db query --linked -f supabase/tests/trip_package_pricing_regression.sql
--
-- Every row of the output should read OK. Any row reading "BROKEN" or "LEAK" is a
-- regression.
--
-- Covers: 20260815091000 (per-package trip pricing),
--         20260819090000 (its marketplace read fix).
-- ═══════════════════════════════════════════════════════════════════════════════════

begin;

create temp table probe(step text, result text) on commit drop;
create temp table fixture(k text primary key, v text) on commit drop;
grant all on probe to authenticated, anon;
grant all on fixture to authenticated, anon;

-- What the marketplace *should* publish, counted as superuser before any
-- impersonation starts: every price row whose office is listed, and every row whose
-- office is not (the set that must stay invisible).
insert into fixture
select 'listed', count(*)::text
  from public.trip_package_prices tpp
  join public.trip_pricing tp on tp.id = tpp.trip_pricing_id
  join public.operation_trips tr on tr.id = tp.trip_id
 where public.office_is_listed(tr.office_id);

insert into fixture
select 'unlisted', count(*)::text
  from public.trip_package_prices tpp
  join public.trip_pricing tp on tp.id = tpp.trip_pricing_id
  join public.operation_trips tr on tr.id = tp.trip_id
 where not public.office_is_listed(tr.office_id);

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. The rider's read — the half that failed silently
-- ───────────────────────────────────────────────────────────────────────────────────

set local role anon;
insert into probe
select '01. an anonymous browser reads the published price rows',
       case when (select v::bigint from fixture where k = 'listed') = 0
              then 'SKIPPED — no listed office has priced a package'
            when count(*) >= (select v::bigint from fixture where k = 'listed')
              then 'OK'
            else 'BROKEN — the wizard falls back to the catalogue price ('
                 || count(*) || ' of '
                 || (select v from fixture where k = 'listed') || ' rows readable)'
       end
  from public.trip_package_prices;
reset role;

set local role authenticated;
set local request.jwt.claims to
  '{"sub":"00000000-0000-0000-0000-000000000000","role":"authenticated"}';
insert into probe
select '02. a signed-in rider reads them too',
       case when (select v::bigint from fixture where k = 'listed') = 0
              then 'SKIPPED — no listed office has priced a package'
            when count(*) >= (select v::bigint from fixture where k = 'listed')
              then 'OK'
            else 'BROKEN — the price quoted at booking is not the price charged ('
                 || count(*) || ' of '
                 || (select v from fixture where k = 'listed') || ' rows readable)'
       end
  from public.trip_package_prices;
reset role;

-- The other direction: widening the read must not have published the fares of an
-- office the marketplace has delisted or suspended.
set local role anon;
insert into probe
select '03. a delisted office''s price rows stay hidden',
       case when (select v::bigint from fixture where k = 'unlisted') = 0
              then 'OK (none to hide)'
            when count(*) <= (select v::bigint from fixture where k = 'listed')
              then 'OK'
            else 'LEAK — an unlisted office''s fares are readable'
       end
  from public.trip_package_prices;
reset role;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. The bug class — a child policy may not reach through a table the reader
--    cannot see. Every sibling (trip_pricing, trip_route_points) goes through a
--    SECURITY DEFINER helper for exactly this reason.
-- ───────────────────────────────────────────────────────────────────────────────────

insert into probe
select '04. the rider read policy uses a definer helper, not an inline join',
       case when qual is null then 'BROKEN — the policy is gone'
            when qual ilike '%operation_trips%'
              then 'BROKEN — self-blocking join: riders cannot read operation_trips'
            when qual ilike '%trip_pricing_office_is_listed%' then 'OK'
            else 'BROKEN — unrecognised predicate, verify it by hand'
       end
  from (
    select (select qual from pg_policies
             where tablename = 'trip_package_prices'
               and policyname = 'trip_package_prices_marketplace_read') as qual
  ) p;

insert into probe
select '05. that helper is SECURITY DEFINER and executable by riders',
       case when bool_or(p.prosecdef
                         and has_function_privilege('anon', p.oid, 'execute')
                         and has_function_privilege('authenticated', p.oid, 'execute'))
            then 'OK' else 'BROKEN — the helper cannot run for the role that needs it'
       end
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'trip_pricing_office_is_listed';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. The server side — client and RPC must resolve the same row, or the two
--    numbers drift apart again from the other end.
-- ───────────────────────────────────────────────────────────────────────────────────

insert into probe
select '06. the booking RPC charges trip_package_prices, not the catalogue price',
       case when body like '%trip_package_prices%' then 'OK'
            else 'BROKEN — per-package pricing is not what gets charged' end
  from (
    select pg_get_functiondef(
      'public.confirm_seat_booking_v2(uuid,uuid,uuid,uuid,uuid,uuid,text,text,text,'
      'text,date,text,text,numeric,text,text,uuid,date,text,text,text,uuid)'::regprocedure
    ) as body
  ) f;

select * from probe order by step;

rollback;
