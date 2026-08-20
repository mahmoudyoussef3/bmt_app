-- ═══════════════════════════════════════════════════════════════════════════════════
-- Trip-scoped packages — regression suite
-- ═══════════════════════════════════════════════════════════════════════════════════
-- An office decides, per trip, which packages that departure sells. It may add one of
-- its catalog packages, or write a package that exists on that trip and nowhere else
-- (`transport_packages.trip_id`), each with its own price and an optional note
-- (`trip_package_prices.note`). Three things have to hold for that to be honest:
--
--     1. the rider booking the trip can READ its menu — the package rows and the
--        notes. A blocked read here looks exactly like "the office sold nothing",
--        which is the failure mode that shipped with per-package pricing itself
--        (see trip_package_pricing_regression.sql).
--     2. a trip package cannot be attached to another office's trip, or it would
--        render inside a stranger's booking flow. RLS only checks
--        `office_id = current_office_id()`, so the pairing needs its own guard.
--     3. a trip package cannot be BOOKED on another trip. Without that,
--        `confirm_seat_booking_v2` would resolve it through its
--        "no pricing row for this pair" fallback and charge the package's flat price
--        on a trip that never offered it.
--
-- Runs entirely inside BEGIN … ROLLBACK. Nothing survives the run, so it is safe
-- against the production-bound development database.
--
--   supabase db query --linked -f supabase/tests/trip_scoped_packages_regression.sql
--
-- Every row of the output should read OK. Any row reading "BROKEN" or "LEAK" is a
-- regression.
--
-- Covers: 20260820100000 (trip-scoped packages + per-trip package notes).
-- ═══════════════════════════════════════════════════════════════════════════════════

begin;

create temp table probe(step text, result text) on commit drop;
create temp table fixture(k text primary key, v text) on commit drop;
grant all on probe to authenticated, anon;
grant all on fixture to authenticated, anon;

-- A real trip of a listed office, with a priced stop pair to hang the package off.
insert into fixture
select 'pricing_id', tp.id::text
  from public.trip_pricing tp
  join public.operation_trips tr on tr.id = tp.trip_id
 where public.office_is_listed(tr.office_id)
   and public.office_sells_packages(tr.office_id)
   and tp.is_active
 limit 1;

insert into fixture
select 'trip_id', tp.trip_id::text from public.trip_pricing tp
 where tp.id = (select v from fixture where k = 'pricing_id')::uuid;

insert into fixture
select 'office_id', tr.office_id::text from public.operation_trips tr
 where tr.id = (select v from fixture where k = 'trip_id')::uuid;

-- A trip belonging to a DIFFERENT office, for the cross-office probes.
insert into fixture
select 'other_trip_id', tr.id::text from public.operation_trips tr
 where tr.office_id <> (select v from fixture where k = 'office_id')::uuid
 limit 1;

do $$
declare
  v_trip   uuid := (select v from fixture where k = 'trip_id')::uuid;
  v_office uuid := (select v from fixture where k = 'office_id')::uuid;
  v_pkg    uuid;
begin
  if v_trip is null then
    return;
  end if;

  insert into public.transport_packages (
    office_id, trip_id, name_ar, name_en, package_type, price,
    duration_days, ride_count, description_ar, description_en, active,
    display_order
  ) values (
    v_office, v_trip, 'باقة اختبار الرحلة', 'Trip probe package',
    'trip_probe_regression', 123.00, 7, 6, '', '', true, 9999
  ) returning id into v_pkg;

  insert into fixture values ('package_id', v_pkg::text);

  insert into public.trip_package_prices (trip_pricing_id, package_id, price, note)
  values (
    (select v from fixture where k = 'pricing_id')::uuid, v_pkg, 123.00,
    'تشمل رحلة العودة'
  );
end $$;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. The rider's read — the trip's menu has to reach the booking wizard
-- ───────────────────────────────────────────────────────────────────────────────────

set local role anon;
insert into probe
select '01. an anonymous browser reads a package created for one trip',
       case when (select v from fixture where k = 'package_id') is null
              then 'SKIPPED — no listed package-selling office has a priced trip'
            when exists (select 1 from public.transport_packages
                          where id = (select v from fixture where k = 'package_id')::uuid)
              then 'OK'
            else 'BROKEN — the trip sells a package the rider cannot see'
       end;
reset role;

set local role authenticated;
set local request.jwt.claims to
  '{"sub":"00000000-0000-0000-0000-000000000000","role":"authenticated"}';
insert into probe
select '02. the office''s note travels to the rider with the price',
       case when (select v from fixture where k = 'package_id') is null
              then 'SKIPPED — no fixture'
            when (select note from public.trip_package_prices
                   where package_id = (select v from fixture where k = 'package_id')::uuid)
                 = 'تشمل رحلة العودة'
              then 'OK'
            else 'BROKEN — the note is not readable at booking time'
       end;
reset role;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. The pairing guard — a trip package belongs to its own office's trip
-- ───────────────────────────────────────────────────────────────────────────────────

do $$
declare
  v_other uuid := (select v from fixture where k = 'other_trip_id')::uuid;
  v_pkg   uuid := (select v from fixture where k = 'package_id')::uuid;
begin
  if v_other is null or v_pkg is null then
    insert into probe values (
      '03. a trip package cannot be attached to another office''s trip',
      'SKIPPED — only one office has trips');
    return;
  end if;

  begin
    update public.transport_packages set trip_id = v_other where id = v_pkg;
    insert into probe values (
      '03. a trip package cannot be attached to another office''s trip',
      'LEAK — a package now renders inside another office''s booking flow');
  exception when others then
    insert into probe values (
      '03. a trip package cannot be attached to another office''s trip',
      case when sqlerrm like '%package_trip_office_mismatch%' then 'OK'
           else 'BROKEN — refused, but not by the pairing guard: ' || sqlerrm end);
  end;
end $$;

insert into probe
select '04. the pairing guard is a trigger, not a hope',
       case when count(*) = 1 then 'OK'
            else 'BROKEN — trg_transport_packages_trip_office is gone' end
  from pg_trigger
 where tgrelid = 'public.transport_packages'::regclass
   and tgname = 'trg_transport_packages_trip_office'
   and not tgisinternal;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. The booking RPC — a trip package is not sellable on another trip
-- ───────────────────────────────────────────────────────────────────────────────────

insert into probe
select '05. the booking RPC refuses a trip package booked on a different trip',
       case when body like '%trip_id is null or trip_id = p_trip_id%' then 'OK'
            else 'BROKEN — any trip package resolves on any trip, at its flat price'
       end
  from (
    select pg_get_functiondef(
      'public.confirm_seat_booking_v2(uuid,uuid,uuid,uuid,uuid,uuid,text,text,text,'
      'text,date,text,text,numeric,text,text,uuid,date,text,text,text,uuid)'::regprocedure
    ) as body
  ) f;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 4. The catalog surfaces — a per-trip offer must not read as a permanent one
-- ───────────────────────────────────────────────────────────────────────────────────

insert into probe
select '06. catalog browsing can exclude trip packages (`trip_id is null`)',
       case when (select v from fixture where k = 'package_id') is null
              then 'SKIPPED — no fixture'
            when not exists (
                   select 1 from public.transport_packages
                    where id = (select v from fixture where k = 'package_id')::uuid
                      and trip_id is null)
              then 'OK'
            else 'BROKEN — a trip package looks like a catalog package'
       end;

select * from probe order by step;

rollback;
