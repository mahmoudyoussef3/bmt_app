-- Root cause: `trip_package_prices_marketplace_read`
-- (20260815091000_per_package_trip_pricing.sql) never matched a single row
-- for a rider, so the client wizard quoted a package at the catalogue's flat
-- `transport_packages.price` while `confirm_seat_booking_v2` charged the
-- office's configured `trip_package_prices.price` — the rider saw one number
-- and the receipt showed another.
--
-- Why it never matched: the policy inlines
--   exists (select 1 from trip_pricing tp join operation_trips tr ... )
-- and a policy's own subquery is itself subject to RLS. `operation_trips` is
-- closed to anon/authenticated riders on purpose (public_trips is the only
-- client-facing trip surface), so that join returns zero rows for exactly the
-- role the policy was written for, and the predicate is always false.
--
-- Every sibling child table solves this with a SECURITY DEFINER helper
-- (`trip_office_is_listed`) precisely so the lookup is not re-filtered by the
-- caller's RLS — see 20260729...tracking authority. `trip_package_prices`
-- hangs off `trip_pricing` rather than `operation_trips` directly, so it needs
-- the one-hop-further equivalent, added here.
--
-- This also aligns the visibility rule with its parent row: prices are
-- readable exactly when the `trip_pricing` row carrying them is
-- (`office_is_listed`, not the looser `office_is_active` the broken policy
-- used), so a delisted office's fares can never leak through the child table.

create or replace function public.trip_pricing_office_is_listed(p_pricing_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.trip_pricing tp
     where tp.id = p_pricing_id
       and public.trip_office_is_listed(tp.trip_id)
  );
$$;

grant execute on function public.trip_pricing_office_is_listed(uuid)
  to anon, authenticated;

drop policy if exists trip_package_prices_marketplace_read
  on public.trip_package_prices;

create policy trip_package_prices_marketplace_read on public.trip_package_prices
  for select to anon, authenticated
  using (public.trip_pricing_office_is_listed(trip_pricing_id));
