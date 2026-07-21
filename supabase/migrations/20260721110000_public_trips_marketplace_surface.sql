
-- =====================================================================================
-- EWT multi-office — public_trips: the sanitised trip marketplace surface
-- -------------------------------------------------------------------------------------
-- 090200 kept `trips_marketplace_read` on operation_trips because the Client app
-- queries the table directly; RLS is row-level, so that policy also handed every
-- passenger (and anon) `revenue`, `driver_id`, `vehicle_id`, `passenger_count`,
-- `occupancy_rate` and `notes` for every marketplace trip, cross-office. Two
-- pre-office SELECT policies ("Clients can read bookable/active trips", "Drivers can
-- read their assigned trips") additionally survived 090200's drop list under their
-- older names — the first of them without even the office-is-active check.
--
-- This closes the last blocker in MULTI_OFFICE_MIGRATION_AUDIT.md:
--
--   1. `public_trips` — a projection of operation_trips holding only what a trip
--      card, trip detail, seat map or checkout screen renders. Same mechanism as
--      public_driver_profiles / public_vehicle_profiles / public_offices (090200 §14):
--      security_invoker = false, so the view owner reads the base table and RLS on it
--      never applies to the marketplace caller.
--   2. Every client-facing SELECT policy on operation_trips is dropped. The base
--      table now answers only to office operators (trips_office_manage) and captains
--      (trips_captain_read / trips_captain_update).
--   3. The three child marketplace policies (trip_seats / trip_pricing /
--      trip_route_points) are re-founded on a SECURITY DEFINER helper. Their old
--      predicates subqueried operation_trips under the caller's own RLS, which after
--      step 2 evaluates to empty for every passenger — the helper keeps the seat map,
--      the fare matrix and the stop list readable without reopening the trip row.
-- =====================================================================================

-- ── 1. Helper: is this trip's office open for business? ─────────────────────────────
-- SECURITY DEFINER so it can consult operation_trips on behalf of callers who can no
-- longer read the table themselves. Mirrors the exact predicate the child marketplace
-- policies used before: office active, no condition on trip status.

create or replace function public.trip_office_is_active(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.operation_trips t
     where t.id = p_trip_id
       and public.office_is_active(t.office_id)
  );
$$;

comment on function public.trip_office_is_active(uuid) is
  'Marketplace visibility of a trip''s children (seats/pricing/stops). SECURITY '
  'DEFINER: policy subqueries run under the caller''s RLS, and passengers hold no '
  'SELECT policy on operation_trips any more.';

-- ── 2. The sanitised trip surface ───────────────────────────────────────────────────
-- Row predicate is byte-for-byte the old trips_marketplace_read policy: trips a
-- passenger could act on (or just travelled), from active offices only.
--
-- The assigned driver and vehicle are flattened into `drivers` / `vehicles` jsonb
-- columns carrying exactly the public_driver_profiles / public_vehicle_profiles field
-- set — named like the old table embeds so every existing consumer of the response
-- shape keeps parsing, while the raw driver_id / vehicle_id keys, phone numbers,
-- licences and plate numbers stay out of reach.

create or replace view public.public_trips
with (security_invoker = false) as
  select t.id,
         t.trip_code,
         t.office_id,
         t.route_id,
         t.trip_date,
         t.departure_time,
         t.arrival_time,
         t.actual_start_time,
         t.actual_end_time,
         t.status,
         t.capacity,
         t.booked_seats,
         greatest(t.capacity - t.booked_seats, 0) as available_seats,
         t.ticket_price,
         t.currency,
         case when d.id is not null then
           jsonb_build_object(
             'full_name',         d.full_name,
             'profile_image_url', d.profile_image_url,
             'rating',            d.rating,
             'rating_count',      d.rating_count)
         end as drivers,
         case when v.id is not null then
           jsonb_build_object(
             'vehicle_code',      v.vehicle_code,
             'vehicle_type',      v.vehicle_type,
             'brand',             v.brand,
             'model',             v.model,
             'manufacture_year',  v.manufacture_year,
             'color',             v.color,
             'capacity',          v.capacity,
             'seat_layout_type',  v.seat_layout_type,
             'image_url',         v.image_url,
             'rating',            v.rating,
             'rating_count',      v.rating_count)
         end as vehicles
    from public.operation_trips t
    left join public.drivers  d on d.id = t.driver_id
    left join public.vehicles v on v.id = t.vehicle_id
   where t.status in ('open_for_booking', 'scheduled', 'boarding',
                      'in_progress', 'completed')
     and public.office_is_active(t.office_id);

grant select on public.public_trips to anon, authenticated;

comment on view public.public_trips is
  'Marketplace-safe projection of operation_trips. The base table holds revenue, '
  'driver_id, vehicle_id and occupancy internals that must never reach the Client '
  'app; this is the only trip surface the Client may query.';

-- ── 3. Close the base table to passengers ───────────────────────────────────────────

drop policy if exists trips_marketplace_read                    on public.operation_trips;
drop policy if exists "Clients can read bookable/active trips"  on public.operation_trips;
drop policy if exists "Drivers can read their assigned trips"   on public.operation_trips;

-- ── 4. Re-found the child marketplace policies on the helper ────────────────────────

do $$
declare
  t text;
begin
  foreach t in array array['trip_seats', 'trip_pricing', 'trip_route_points']
  loop
    execute format('drop policy if exists %I on public.%I',
                   t || '_marketplace_read', t);
    execute format($f$
      create policy %I on public.%I for select to anon, authenticated
        using (public.trip_office_is_active(trip_id))
    $f$, t || '_marketplace_read', t);
  end loop;
end $$;
