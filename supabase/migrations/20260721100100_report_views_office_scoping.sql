-- =====================================================================================
-- EWT multi-office — office-scoped report views
-- -------------------------------------------------------------------------------------
-- The four operational report views aggregate across every office with no office
-- predicate, and all four are SELECTable by `anon`. A view owned by `postgres` is not
-- constrained by the RLS on its base tables, so office_id columns added in 090000 do
-- nothing here — the office boundary has to be written into the view body.
--
-- Each view is filtered to public.current_office_id(). A platform admin sees the
-- unfiltered roll-up, which is what the previous behaviour was for everyone.
-- =====================================================================================

-- ── 1. operation_complaints needs an office before it can be scoped ─────────────────
-- It is the one reporting base table 090000 did not reach: complaints arrive from a
-- client and name a trip_code, but carry no office of their own.

alter table public.operation_complaints
  add column if not exists office_id uuid references public.offices(id);

update public.operation_complaints c
   set office_id = t.office_id
  from public.operation_trips t
 where c.office_id is null
   and c.trip_code is not null
   and t.trip_code = c.trip_code;

-- Complaints with no resolvable trip fall to the office the client last booked with.
update public.operation_complaints c
   set office_id = b.office_id
  from (
    select distinct on (client_id) client_id, office_id
      from public.operation_bookings
     where office_id is not null
     order by client_id, created_at desc
  ) b
 where c.office_id is null
   and c.client_id = b.client_id;

create index if not exists operation_complaints_office_idx
  on public.operation_complaints (office_id);

-- Keep it populated going forward rather than relying on the writer to supply it.
create or replace function public.sync_complaint_office()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.office_id is null and new.trip_code is not null then
    select t.office_id into new.office_id
      from public.operation_trips t
     where t.trip_code = new.trip_code
     limit 1;
  end if;

  if new.office_id is null and new.client_id is not null then
    select b.office_id into new.office_id
      from public.operation_bookings b
     where b.client_id = new.client_id
       and b.office_id is not null
     order by b.created_at desc
     limit 1;
  end if;

  return new;
end;
$$;

revoke all on function public.sync_complaint_office() from public, anon, authenticated;

drop trigger if exists sync_complaint_office_trg on public.operation_complaints;
create trigger sync_complaint_office_trg
  before insert or update of trip_code, client_id on public.operation_complaints
  for each row execute function public.sync_complaint_office();

-- ── 2. The reports ──────────────────────────────────────────────────────────────────

drop view if exists public.revenue_daily_view;
create view public.revenue_daily_view as
  select
    (b.created_at at time zone 'UTC')::date as report_date,
    b.office_id,
    count(*)::integer as total_bookings,
    coalesce(
      sum(b.payment_amount) filter (
        where b.status <> all (array['rejected'::text, 'cancelled'::text])
      ), 0::numeric) as total_bookings_revenue
  from public.operation_bookings b
  where b.office_id = public.current_office_id()
     or public.is_platform_admin()
  group by (b.created_at at time zone 'UTC')::date, b.office_id
  order by (b.created_at at time zone 'UTC')::date;

drop view if exists public.drivers_performance_view;
create view public.drivers_performance_view as
  select
    d.id           as driver_id,
    d.office_id,
    d.full_name    as name,
    d.status,
    count(t.id) filter (where t.status = 'completed') as completed_trips,
    coalesce(
      sum(t.revenue) filter (where t.status = 'completed'), 0::numeric
    ) as total_revenue
  from public.drivers d
  left join public.operation_trips t
    on t.driver_id = d.id
   and t.office_id = d.office_id
  where d.office_id = public.current_office_id()
     or public.is_platform_admin()
  group by d.id, d.office_id, d.full_name, d.status;

drop view if exists public.vehicles_efficiency_view;
create view public.vehicles_efficiency_view as
  select
    v.id           as vehicle_id,
    v.office_id,
    v.plate_number,
    v.model,
    v.status,
    count(t.id) filter (where t.status = 'completed') as completed_trips,
    coalesce(
      avg(t.occupancy_rate) filter (where t.status = 'completed'), 0::numeric
    ) as avg_occupancy_rate,
    case
      when v.status = 'maintenance' then 'تحتاج صيانة'
      when v.status = 'active'      then 'جاهزة'
      else 'غير متاحة'
    end as maintenance_status
  from public.vehicles v
  left join public.operation_trips t
    on t.vehicle_id = v.id
   and t.office_id = v.office_id
  where v.office_id = public.current_office_id()
     or public.is_platform_admin()
  group by v.id, v.office_id, v.plate_number, v.model, v.status;

drop view if exists public.complaints_summary_view;
create view public.complaints_summary_view as
  select
    c.office_id,
    c.category,
    count(c.id) as total_complaints,
    count(c.id) filter (
      where c.status = any (array['resolved'::text, 'closed'::text])
    ) as resolved_complaints,
    count(c.id) filter (
      where c.status <> all (array['resolved'::text, 'closed'::text])
    ) as pending_complaints
  from public.operation_complaints c
  where c.office_id = public.current_office_id()
     or public.is_platform_admin()
  group by c.office_id, c.category;

-- ── 3. Reports are staff-only ───────────────────────────────────────────────────────
-- current_office_id() is null for anon, so the predicate already returns nothing, but
-- an operational report has no reason to be in the anon role's grant list at all.

do $$
declare
  v text;
begin
  foreach v in array array[
    'public.revenue_daily_view',
    'public.drivers_performance_view',
    'public.vehicles_efficiency_view',
    'public.complaints_summary_view'
  ]
  loop
    execute format('revoke all on %s from anon, authenticated', v);
    execute format('grant select on %s to authenticated', v);
  end loop;
end $$;

-- Referral reporting is platform-wide by design and carries no office dimension.
-- referral_analytics aggregates the whole programme: platform admins only.
-- referral_leaderboard is surfaced to clients, so it stays readable when signed in.
revoke all on public.referral_analytics   from anon, authenticated;
grant select on public.referral_analytics to authenticated;

revoke all on public.referral_leaderboard from anon;
grant select on public.referral_leaderboard to authenticated;

comment on view public.revenue_daily_view is
  'Office-scoped. Rows are limited to current_office_id(); platform admins see all.';
comment on view public.drivers_performance_view is
  'Office-scoped. Rows are limited to current_office_id(); platform admins see all.';
comment on view public.vehicles_efficiency_view is
  'Office-scoped. Rows are limited to current_office_id(); platform admins see all.';
comment on view public.complaints_summary_view is
  'Office-scoped. Rows are limited to current_office_id(); platform admins see all.';
