
-- =====================================================================================
-- EWT multi-office — row level security cutover
-- -------------------------------------------------------------------------------------
-- This is the migration that actually enforces isolation. Everything before it was
-- additive; this one changes who can read what.
--
-- Three audiences, three rules:
--
--   DASHBOARD  authenticated office operator  → office_id = current_office_id()
--   CLIENT     anon or authenticated passenger → only the intentionally public surface
--                                                of ACTIVE offices, plus their own rows
--   CAPTAIN    authenticated driver            → their office AND their own trips
--
-- Before this migration RLS was DISABLED on 21 operational tables and absent entirely
-- from 8 more, and the Dashboard talked to Postgres as `anon`. Both of those end here.
-- =====================================================================================

-- ── 0. Helper: is this row's office open for business? ──────────────────────────────

create or replace function public.office_is_active(p_office_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.offices
     where id = p_office_id and status = 'active'
  );
$$;

-- ── 1. Offices ──────────────────────────────────────────────────────────────────────
-- The marketplace directory. Public by design — this is what the Client app browses.

alter table public.offices enable row level security;

drop policy if exists offices_public_read on public.offices;
create policy offices_public_read on public.offices
  for select to anon, authenticated
  using (status = 'active');

drop policy if exists offices_operator_read on public.offices;
create policy offices_operator_read on public.offices
  for select to authenticated
  using (id = public.current_office_id());

drop policy if exists offices_operator_update on public.offices;
create policy offices_operator_update on public.offices
  for update to authenticated
  using (id = public.current_office_id() and public.office_role() = 'dashboard_admin')
  with check (id = public.current_office_id());

-- Creating and deleting offices is a platform action (service_role), never an in-app one.

-- ── 2. office_users ─────────────────────────────────────────────────────────────────

alter table public.office_users enable row level security;

drop policy if exists office_users_read_own_office on public.office_users;
create policy office_users_read_own_office on public.office_users
  for select to authenticated
  using (office_id = public.current_office_id());

drop policy if exists office_users_admin_manage on public.office_users;
create policy office_users_admin_manage on public.office_users
  for all to authenticated
  using (office_id = public.current_office_id()
         and public.office_role() = 'dashboard_admin')
  with check (office_id = public.current_office_id()
              and public.office_role() = 'dashboard_admin');

-- ── 3. Routes and stations ──────────────────────────────────────────────────────────

alter table public.operation_routes enable row level security;

-- Drop every pre-office policy by name — they granted access on "is an admin at all".
drop policy if exists "Admins have full access to operation_routes" on public.operation_routes;
drop policy if exists "Anyone can view operation_routes"            on public.operation_routes;
drop policy if exists "Admins can manage routes"                    on public.operation_routes;
drop policy if exists "Clients can read active routes"              on public.operation_routes;

create policy routes_office_manage on public.operation_routes
  for all to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

-- The marketplace surface: active routes of active offices, to everyone.
create policy routes_marketplace_read on public.operation_routes
  for select to anon, authenticated
  using (status = 'active' and public.office_is_active(office_id));

-- Captains need their office's routes to render trip detail.
create policy routes_captain_read on public.operation_routes
  for select to authenticated
  using (office_id = public.captain_office_id());

alter table public.route_stations enable row level security;

drop policy if exists "Admins have full access to route_stations" on public.route_stations;
drop policy if exists "Anyone can view route_stations"            on public.route_stations;

create policy route_stations_office_manage on public.route_stations
  for all to authenticated
  using (exists (select 1 from public.operation_routes r
                  where r.id = route_id and r.office_id = public.current_office_id()))
  with check (exists (select 1 from public.operation_routes r
                       where r.id = route_id and r.office_id = public.current_office_id()));

create policy route_stations_marketplace_read on public.route_stations
  for select to anon, authenticated
  using (exists (select 1 from public.operation_routes r
                  where r.id = route_id
                    and r.status = 'active'
                    and public.office_is_active(r.office_id)));

create policy route_stations_captain_read on public.route_stations
  for select to authenticated
  using (exists (select 1 from public.operation_routes r
                  where r.id = route_id and r.office_id = public.captain_office_id()));

-- ── 4. Trips ────────────────────────────────────────────────────────────────────────

alter table public.operation_trips enable row level security;

drop policy if exists "Admins can manage trips"                             on public.operation_trips;
drop policy if exists "Clients can read scheduled/boarding/in_progress trips" on public.operation_trips;
drop policy if exists "Drivers can view trips assigned to them"             on public.operation_trips;
drop policy if exists "Drivers can update status of trips assigned to them" on public.operation_trips;
drop policy if exists "Clients can view bookable trips"                     on public.operation_trips;

create policy trips_office_manage on public.operation_trips
  for all to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

-- Marketplace: only trips a passenger could actually act on, from active offices.
create policy trips_marketplace_read on public.operation_trips
  for select to anon, authenticated
  using (status in ('open_for_booking', 'scheduled', 'boarding', 'in_progress', 'completed')
         and public.office_is_active(office_id));

-- Captain: their own assigned trips, and only within their own office.
create policy trips_captain_read on public.operation_trips
  for select to authenticated
  using (office_id = public.captain_office_id()
         and driver_id = public.current_driver_id());

create policy trips_captain_update on public.operation_trips
  for update to authenticated
  using (office_id = public.captain_office_id()
         and driver_id = public.current_driver_id())
  with check (office_id = public.captain_office_id()
              and driver_id = public.current_driver_id());

-- ── 5. Trip children (office derived through the trip) ──────────────────────────────
-- trip_seats / trip_pricing / trip_route_points all follow one shape, so generate them
-- rather than hand-writing four near-identical blocks and letting them drift.

do $$
declare
  t text;
begin
  foreach t in array array['trip_seats', 'trip_pricing', 'trip_route_points']
  loop
    execute format('alter table public.%I enable row level security', t);

    execute format('drop policy if exists %I on public.%I', t || '_office_manage', t);
    execute format($f$
      create policy %I on public.%I for all to authenticated
        using (exists (select 1 from public.operation_trips tr
                        where tr.id = trip_id
                          and tr.office_id = public.current_office_id()))
        with check (exists (select 1 from public.operation_trips tr
                             where tr.id = trip_id
                               and tr.office_id = public.current_office_id()))
    $f$, t || '_office_manage', t);

    execute format('drop policy if exists %I on public.%I', t || '_marketplace_read', t);
    execute format($f$
      create policy %I on public.%I for select to anon, authenticated
        using (exists (select 1 from public.operation_trips tr
                        where tr.id = trip_id
                          and public.office_is_active(tr.office_id)))
    $f$, t || '_marketplace_read', t);

    execute format('drop policy if exists %I on public.%I', t || '_captain_read', t);
    execute format($f$
      create policy %I on public.%I for select to authenticated
        using (exists (select 1 from public.operation_trips tr
                        where tr.id = trip_id
                          and tr.driver_id = public.current_driver_id()))
    $f$, t || '_captain_read', t);
  end loop;
end $$;

-- Legacy blanket policies from migration_01.
drop policy if exists "Clients can read trip seats"   on public.trip_seats;
drop policy if exists "Clients can read trip pricing" on public.trip_pricing;
drop policy if exists "Admins can manage seats"       on public.trip_seats;
drop policy if exists "Admins can manage pricing"     on public.trip_pricing;

-- ── 6. trip_events — had NO RLS at all before this ─────────────────────────────────

alter table public.trip_events enable row level security;

drop policy if exists trip_events_office_manage on public.trip_events;
create policy trip_events_office_manage on public.trip_events
  for all to authenticated
  using (exists (select 1 from public.operation_trips tr
                  where tr.id = trip_id and tr.office_id = public.current_office_id()))
  with check (exists (select 1 from public.operation_trips tr
                       where tr.id = trip_id and tr.office_id = public.current_office_id()));

-- A passenger sees the timeline only for a trip they actually booked.
drop policy if exists trip_events_passenger_read on public.trip_events;
create policy trip_events_passenger_read on public.trip_events
  for select to authenticated
  using (exists (select 1 from public.operation_bookings b
                  where b.trip_id = trip_events.trip_id
                    and b.client_id = auth.uid()));

drop policy if exists trip_events_captain_rw on public.trip_events;
create policy trip_events_captain_rw on public.trip_events
  for all to authenticated
  using (exists (select 1 from public.operation_trips tr
                  where tr.id = trip_id and tr.driver_id = public.current_driver_id()))
  with check (exists (select 1 from public.operation_trips tr
                       where tr.id = trip_id and tr.driver_id = public.current_driver_id()));

-- ── 7. trip_passengers — had NO RLS at all; the manifest leaked names + phones ──────

alter table public.trip_passengers enable row level security;

drop policy if exists trip_passengers_office_manage on public.trip_passengers;
create policy trip_passengers_office_manage on public.trip_passengers
  for all to authenticated
  using (exists (select 1 from public.operation_trips tr
                  where tr.id = trip_id and tr.office_id = public.current_office_id()))
  with check (exists (select 1 from public.operation_trips tr
                       where tr.id = trip_id and tr.office_id = public.current_office_id()));

-- The captain works the manifest for trips assigned to them — and only those.
drop policy if exists trip_passengers_captain_rw on public.trip_passengers;
create policy trip_passengers_captain_rw on public.trip_passengers
  for all to authenticated
  using (exists (select 1 from public.operation_trips tr
                  where tr.id = trip_id and tr.driver_id = public.current_driver_id()))
  with check (exists (select 1 from public.operation_trips tr
                       where tr.id = trip_id and tr.driver_id = public.current_driver_id()));

drop policy if exists trip_passengers_self_read on public.trip_passengers;
create policy trip_passengers_self_read on public.trip_passengers
  for select to authenticated
  using (customer_id = auth.uid());

-- ── 8. Bookings and payments ────────────────────────────────────────────────────────

alter table public.operation_bookings enable row level security;

drop policy if exists "Clients can view their own bookings"   on public.operation_bookings;
drop policy if exists "Clients can insert their own bookings" on public.operation_bookings;
drop policy if exists "Admins can manage bookings"            on public.operation_bookings;

create policy bookings_office_manage on public.operation_bookings
  for all to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

create policy bookings_client_read on public.operation_bookings
  for select to authenticated
  using (client_id = auth.uid());

-- Inserts go through confirm_seat_booking_v2 (SECURITY DEFINER); this policy exists so
-- a direct insert by the owner still works, and nobody can book on someone else's behalf.
create policy bookings_client_insert on public.operation_bookings
  for insert to authenticated
  with check (client_id = auth.uid());

-- Captain: read-only, and only for their own trips (manifest / headcount).
create policy bookings_captain_read on public.operation_bookings
  for select to authenticated
  using (exists (select 1 from public.operation_trips tr
                  where tr.id = trip_id and tr.driver_id = public.current_driver_id()));

alter table public.booking_payments enable row level security;

drop policy if exists "Clients read own booking payments"  on public.booking_payments;
drop policy if exists "Dashboard manages booking payments" on public.booking_payments;

create policy booking_payments_office_manage on public.booking_payments
  for all to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

create policy booking_payments_client_read on public.booking_payments
  for select to authenticated
  using (client_id = auth.uid());

create policy booking_payments_client_insert on public.booking_payments
  for insert to authenticated
  with check (client_id = auth.uid());

-- ── 9. Fleet — drivers, vehicles, assignments, documents ───────────────────────────
-- None of these had RLS. The base tables now hold internal data (national_id, phone,
-- licence numbers) and are office-only. The marketplace reads the sanitised views in
-- section 14 instead.

alter table public.drivers enable row level security;

drop policy if exists drivers_office_manage on public.drivers;
create policy drivers_office_manage on public.drivers
  for all to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

drop policy if exists drivers_self_read on public.drivers;
create policy drivers_self_read on public.drivers
  for select to authenticated
  using (user_id = auth.uid());

alter table public.vehicles enable row level security;

drop policy if exists vehicles_office_manage on public.vehicles;
create policy vehicles_office_manage on public.vehicles
  for all to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

-- A captain needs the vehicle attached to their trips.
drop policy if exists vehicles_captain_read on public.vehicles;
create policy vehicles_captain_read on public.vehicles
  for select to authenticated
  using (office_id = public.captain_office_id());

alter table public.assignments enable row level security;

drop policy if exists assignments_office_manage on public.assignments;
create policy assignments_office_manage on public.assignments
  for all to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

do $$
declare
  spec record;
begin
  for spec in
    select * from (values
      ('driver_documents',  'drivers',  'driver_id'),
      ('vehicle_documents', 'vehicles', 'vehicle_id')
    ) as t(tbl, parent, fk)
  loop
    execute format('alter table public.%I enable row level security', spec.tbl);
    execute format('drop policy if exists %I on public.%I',
                   spec.tbl || '_office_manage', spec.tbl);
    execute format($f$
      create policy %I on public.%I for all to authenticated
        using (exists (select 1 from public.%I p
                        where p.id = %I and p.office_id = public.current_office_id()))
        with check (exists (select 1 from public.%I p
                             where p.id = %I and p.office_id = public.current_office_id()))
    $f$, spec.tbl || '_office_manage', spec.tbl,
         spec.parent, spec.fk, spec.parent, spec.fk);
  end loop;
end $$;

-- ── 10. Catalogue: packages, fares, promo codes (per-office) ───────────────────────

-- promo_codes ships in a hand-applied root-level migration and is absent on some
-- environments, so every table here is existence-checked. `active_pred` is the
-- per-table "is this row publicly visible" predicate, since the column that expresses
-- it differs (active / status / is_active + expiry).
do $$
declare
  spec record;
  legacy text;
begin
  for spec in
    select * from (values
      ('transport_packages',    'active = true',      'anon, authenticated'),
      ('packages',              'status = ''active''', 'anon, authenticated'),
      ('package_vehicle_tiers', 'status = ''active''', 'anon, authenticated'),
      ('promo_codes',
       'is_active = true and (expires_at is null or expires_at > now())',
       'authenticated')
    ) as t(tbl, active_pred, audience)
  loop
    if to_regclass('public.' || spec.tbl) is null then
      raise notice 'multi-office: skipping RLS for %, table not present', spec.tbl;
      continue;
    end if;

    execute format('alter table public.%I enable row level security', spec.tbl);

    -- Retire the pre-office policies, which granted on "is an admin at all".
    foreach legacy in array array[
      'Clients read active transport packages', 'Dashboard manages transport packages',
      'Clients can read packages', 'Admins can manage packages',
      'clients can read active promo codes'
    ]
    loop
      execute format('drop policy if exists %I on public.%I', legacy, spec.tbl);
    end loop;

    execute format('drop policy if exists %I on public.%I',
                   spec.tbl || '_office_manage', spec.tbl);
    execute format($f$
      create policy %I on public.%I for all to authenticated
        using (office_id = public.current_office_id())
        with check (office_id = public.current_office_id())
    $f$, spec.tbl || '_office_manage', spec.tbl);

    execute format('drop policy if exists %I on public.%I',
                   spec.tbl || '_marketplace_read', spec.tbl);
    execute format(
      'create policy %I on public.%I for select to ' || spec.audience
      || ' using (' || spec.active_pred || ' and public.office_is_active(office_id))',
      spec.tbl || '_marketplace_read', spec.tbl);
  end loop;
end $$;

-- ── 11. Subscriptions ───────────────────────────────────────────────────────────────

alter table public.subscriptions enable row level security;

drop policy if exists subscriptions_client_read_own      on public.subscriptions;
drop policy if exists subscriptions_client_create_pending on public.subscriptions;
drop policy if exists subscriptions_dashboard_manage     on public.subscriptions;

create policy subscriptions_office_manage on public.subscriptions
  for all to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

create policy subscriptions_client_read on public.subscriptions
  for select to authenticated
  using (client_id = auth.uid());

alter table public.transport_subscriptions enable row level security;

drop policy if exists "Clients read own transport subscriptions" on public.transport_subscriptions;
drop policy if exists "Dashboard manages transport subscriptions" on public.transport_subscriptions;

create policy transport_subs_office_manage on public.transport_subscriptions
  for all to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

create policy transport_subs_client_read on public.transport_subscriptions
  for select to authenticated
  using (client_id = auth.uid());

-- ── 12. Operational alerts — was a single global anon-writable feed ────────────────

alter table public.operational_alerts enable row level security;
revoke all on public.operational_alerts from anon;
grant select, update on public.operational_alerts to authenticated;

drop policy if exists operational_alerts_office on public.operational_alerts;
create policy operational_alerts_office on public.operational_alerts
  for select to authenticated
  using (office_id = public.current_office_id());

drop policy if exists operational_alerts_office_update on public.operational_alerts;
create policy operational_alerts_office_update on public.operational_alerts
  for update to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

-- Rows are written only by push_operational_alert() (SECURITY DEFINER).

-- ── 13. Captain requests, support, refunds, reviews ────────────────────────────────

alter table public.captain_requests enable row level security;
revoke all on public.captain_requests from anon;

drop policy if exists "authenticated read captain requests"   on public.captain_requests;
drop policy if exists "authenticated review captain requests" on public.captain_requests;

create policy captain_requests_office on public.captain_requests
  for all to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

alter table public.support_tickets enable row level security;

drop policy if exists "Clients can view their own tickets"   on public.support_tickets;
drop policy if exists "Clients can insert their own tickets" on public.support_tickets;
drop policy if exists "Admins can manage all tickets"        on public.support_tickets;

create policy support_tickets_client_read on public.support_tickets
  for select to authenticated
  using (client_id = auth.uid());

create policy support_tickets_client_insert on public.support_tickets
  for insert to authenticated
  with check (client_id = auth.uid());

-- An office sees tickets routed to it. Platform-level tickets (office_id IS NULL) are
-- deliberately invisible to every office — they belong to EWT support.
create policy support_tickets_office on public.support_tickets
  for all to authenticated
  using (office_id is not null and office_id = public.current_office_id())
  with check (office_id is not null and office_id = public.current_office_id());

alter table public.refund_requests enable row level security;

drop policy if exists refund_requests_client_read on public.refund_requests;
create policy refund_requests_client_read on public.refund_requests
  for select to authenticated
  using (client_id = auth.uid());

drop policy if exists refund_requests_office on public.refund_requests;
create policy refund_requests_office on public.refund_requests
  for all to authenticated
  using (office_id is not null and office_id = public.current_office_id())
  with check (office_id is not null and office_id = public.current_office_id());

alter table public.trip_reviews enable row level security;

drop policy if exists "dashboard reads all reviews" on public.trip_reviews;
drop policy if exists "clients read own reviews"    on public.trip_reviews;

create policy trip_reviews_office_read on public.trip_reviews
  for select to authenticated
  using (office_id = public.current_office_id());

create policy trip_reviews_client_read on public.trip_reviews
  for select to authenticated
  using (client_id = auth.uid());

-- Writes go exclusively through submit_trip_review().

-- ── 14. The sanitised marketplace surface ──────────────────────────────────────────
-- The Client app needs a driver's name/photo/rating and a vehicle's make/photos to
-- render a trip card — but must never see phone numbers, national ids or licences.
-- RLS is row-level, so the split is done with views: base tables stay office-only
-- (section 9), and these projections are what the marketplace reads.

create or replace view public.public_driver_profiles
with (security_invoker = false) as
  select d.id,
         d.office_id,
         d.full_name,
         d.profile_image_url,
         d.rating,
         d.rating_count
    from public.drivers d
   where d.status = 'active'
     and public.office_is_active(d.office_id);

create or replace view public.public_vehicle_profiles
with (security_invoker = false) as
  select v.id,
         v.office_id,
         v.vehicle_code,
         v.vehicle_type,
         v.brand,
         v.model,
         v.manufacture_year,
         v.color,
         v.capacity,
         v.seat_layout_type,
         v.image_url,
         v.rating,
         v.rating_count
    from public.vehicles v
   where v.status = 'active'
     and public.office_is_active(v.office_id);

-- The marketplace office directory, with only intentionally public fields.
create or replace view public.public_offices
with (security_invoker = false) as
  select o.id,
         o.name,
         o.slug,
         o.logo_url,
         o.description,
         o.service_areas,
         o.rating,
         o.ratings_count
    from public.offices o
   where o.status = 'active';

grant select on public.public_driver_profiles  to anon, authenticated;
grant select on public.public_vehicle_profiles to anon, authenticated;
grant select on public.public_offices          to anon, authenticated;

comment on view public.public_driver_profiles is
  'Marketplace-safe projection of drivers. The base table is office-scoped and holds '
  'phone, national_id and licence data that must never reach the Client app.';

-- ── 15. Close the anon holes left by the single-owner dashboard ────────────────────
-- These grants existed only because the Dashboard had no login. It has one now.

-- Each revoke is guarded: several of these functions come from hand-applied root-level
-- migrations, and a missing one must not abort the security cutover.
-- get_dashboard_users listed every operator on the platform; 20260721090300 replaces it
-- with an office-scoped version.
do $$
declare
  f text;
begin
  foreach f in array array[
    'public.approve_payment(uuid, text)',
    'public.reject_payment(uuid, text)',
    'public.expire_overdue_subscriptions()',
    'public.confirm_subscription_payment(uuid)',
    'public.request_subscription_renewal(uuid)',
    'public.consume_subscription_ride(uuid)',
    'public.get_dashboard_users()'
  ]
  loop
    begin
      execute format('revoke all on function %s from anon', f);
    exception when undefined_function then
      raise notice 'multi-office: skipping revoke, % not present', f;
    end;
  end loop;

  begin
    execute 'revoke all on function public.get_dashboard_users() from authenticated';
  exception when undefined_function then null;
  end;
end $$;
