-- ── 1. Trip-tracking columns on subscriptions ────────────────────────────────
-- package_id  → FK to the packages table so we can reload duration/trips_count.
-- trips_count → copied from packages.trips_count at subscription creation time.
-- trips_used  → incremented each time the admin marks a ride as used.

alter table public.subscriptions
  add column if not exists package_id   uuid    references public.packages(id) on delete set null,
  add column if not exists trips_count  integer not null default 0,
  add column if not exists trips_used   integer not null default 0;

-- Backfill trips_count for any existing subscriptions that already have a
-- package_id link.
update public.subscriptions s
   set trips_count = p.trips_count
  from public.packages p
 where s.package_id = p.id
   and s.trips_count = 0
   and p.trips_count > 0;

-- ── 2. revenue_daily_view ─────────────────────────────────────────────────────
-- DROP first so we can freely redefine column names/order.
-- CREATE OR REPLACE cannot rename existing columns in PostgreSQL.

drop view if exists public.revenue_daily_view;

create view public.revenue_daily_view as
select
  (created_at at time zone 'UTC')::date            as report_date,
  count(*)::integer                                as total_bookings,
  coalesce(
    sum(payment_amount)
      filter (where status not in ('rejected', 'cancelled')),
    0
  )                                                as total_bookings_revenue
from  public.operation_bookings
group by (created_at at time zone 'UTC')::date
order by report_date;

grant select on public.revenue_daily_view to authenticated;

-- ── 3. RLS guard for new columns ──────────────────────────────────────────────
-- trips_used is admin-managed; allow authenticated users to read subscriptions
-- (existing policy covers this) — no extra policy needed.
