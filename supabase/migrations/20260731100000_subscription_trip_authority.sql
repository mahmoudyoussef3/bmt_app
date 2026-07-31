-- ═══════════════════════════════════════════════════════════════════════════════════
-- Subscription ↔ trip authority
-- ═══════════════════════════════════════════════════════════════════════════════════
-- The Dashboard Subscriptions module could list subscribers but could not answer the
-- one question an operator running a trip actually asks: *who on this trip is riding
-- on a subscription, on which package, and what do I owe them?*
--
-- It could not answer it because nothing in the database connected a subscription to a
-- trip. `public.subscriptions` stored the route as free text (`route_name`) copied off
-- `operation_bookings.route`, with no `route_id`, no `trip_id` and no `booking_id`. The
-- only trip context lived on `operation_bookings`, and the mirror row written by
-- `approve_payment` dropped it on the floor.
--
-- What this migration closes, in order of severity:
--
--   1. BROKEN WRITES. `subscriptions.office_id` is NOT NULL with no default (set by
--      20260721090000_multi_office_foundation). Two functions insert into
--      `public.subscriptions` without supplying it, so both raise
--      `null value in column "office_id"` every time they run:
--        * `approve_payment` — approving a multi-ride package booking. The whole
--          "an approved package booking shows up as a subscriber" path added by
--          20260706130000 has been dead since the multi-office cutover.
--        * `request_subscription_renewal` — the Subscriptions tab's own "تجديد
--          الاشتراك" button.
--      Both now carry the office explicitly, from the booking / from the source
--      subscription. This is a live production bug, not a refactor.
--
--   2. NO TRIP LINK. `subscriptions` gains three nullable foreign keys — the route it
--      is sold on, and the booking/trip it originated from. `approve_payment` fills
--      all three from the booking it is approving; renewals inherit them; the
--      dashboard's manual creation form sets `route_id` directly. Existing rows are
--      backfilled from `operation_bookings` where the link can be proven.
--
--   3. NO RIDE LEDGER. `consume_subscription_ride` incremented `trips_used` and left
--      no trace: which trip the ride was burnt on, when, or by whom was unrecoverable.
--      A subscriber could be charged a ride twice for the same trip and nothing in the
--      database would disagree. `public.subscription_ride_usage` is that ledger, and
--      consuming a ride now writes to it in the same transaction as the decrement.
--
-- Deliberately NOT changed:
--   * `subscriptions.package_id` still references `public.packages` while the booking
--      flow's catalogue is `public.transport_packages` (the two-worlds split documented
--      in 20260706130000). Mirrored rows keep `package_id` NULL and carry the title in
--      `package_name`. Joining the catalogues is a separate migration.
--   * No RLS policy on `subscriptions` is altered; `subscriptions_office_manage`
--      already scopes every row to `current_office_id()`.
--   * No status value is added or removed on any table.

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. Link columns on subscriptions
-- ───────────────────────────────────────────────────────────────────────────────────
-- All three are nullable and ON DELETE SET NULL: a subscription outlives the trip it
-- was sold on, and deleting a cancelled trip must never delete the money.

alter table public.subscriptions
  add column if not exists route_id          uuid,
  add column if not exists origin_trip_id    uuid,
  add column if not exists origin_booking_id uuid;

comment on column public.subscriptions.route_id is
  'The office route (operation_routes) this subscription is sold on. Drives the '
  'Dashboard trip filter: a subscriber on this route is eligible for its trips.';
comment on column public.subscriptions.origin_trip_id is
  'The trip whose booking created this subscription, when it came from the booking '
  'flow. NULL for subscriptions the office created by hand.';
comment on column public.subscriptions.origin_booking_id is
  'The approved operation_bookings row this subscription was mirrored from.';

alter table public.subscriptions
  drop constraint if exists subscriptions_route_fk;
alter table public.subscriptions
  add constraint subscriptions_route_fk
  foreign key (route_id) references public.operation_routes(id) on delete set null;

alter table public.subscriptions
  drop constraint if exists subscriptions_origin_trip_fk;
alter table public.subscriptions
  add constraint subscriptions_origin_trip_fk
  foreign key (origin_trip_id) references public.operation_trips(id) on delete set null;

alter table public.subscriptions
  drop constraint if exists subscriptions_origin_booking_fk;
alter table public.subscriptions
  add constraint subscriptions_origin_booking_fk
  foreign key (origin_booking_id) references public.operation_bookings(id)
  on delete set null;

create index if not exists idx_subscriptions_route
  on public.subscriptions (route_id);
create index if not exists idx_subscriptions_origin_trip
  on public.subscriptions (origin_trip_id);
create index if not exists idx_subscriptions_origin_booking
  on public.subscriptions (origin_booking_id);
-- The list the Subscriptions tab opens with: this office, newest first.
create index if not exists idx_subscriptions_office_created
  on public.subscriptions (office_id, created_at desc);

-- A subscription's route must belong to the same office as the subscription. Without
-- this an operator could attach their subscriber to a competitor's route and the
-- trip board would silently read across the tenancy line.
create or replace function public.assert_subscription_route_office()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_route_office uuid;
begin
  if new.route_id is null then
    return new;
  end if;

  select office_id into v_route_office
    from public.operation_routes where id = new.route_id;

  if v_route_office is distinct from new.office_id then
    raise exception 'subscription_route_office_mismatch';
  end if;

  return new;
end $$;

drop trigger if exists trg_subscriptions_route_office on public.subscriptions;
create trigger trg_subscriptions_route_office
  before insert or update of route_id, office_id on public.subscriptions
  for each row execute function public.assert_subscription_route_office();

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. The ride ledger
-- ───────────────────────────────────────────────────────────────────────────────────
-- One row per ride burnt off a subscription. `trip_id` is nullable because the office
-- can still burn a ride outside any trip (a walk-in, a correction), and because a trip
-- may later be deleted — but the ride stays spent either way.

create table if not exists public.subscription_ride_usage (
  id              uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  office_id       uuid not null references public.offices(id) on delete restrict,
  trip_id         uuid references public.operation_trips(id) on delete set null,
  used_at         timestamptz not null default now(),
  recorded_by     uuid,
  note            text,
  created_at      timestamptz not null default now()
);

comment on table public.subscription_ride_usage is
  'Append-only ledger of subscription rides consumed, written by '
  'consume_subscription_ride. Answers "who rode this trip on a subscription".';

create index if not exists idx_subscription_ride_usage_subscription
  on public.subscription_ride_usage (subscription_id, used_at desc);
create index if not exists idx_subscription_ride_usage_trip
  on public.subscription_ride_usage (trip_id);
create index if not exists idx_subscription_ride_usage_office
  on public.subscription_ride_usage (office_id, used_at desc);

-- One ride per subscription per trip. A subscriber boards a given departure once; a
-- double tap on "تسجيل رحلة" was previously two rides off their balance with no way
-- to tell it happened.
create unique index if not exists uq_subscription_ride_usage_trip
  on public.subscription_ride_usage (subscription_id, trip_id)
  where trip_id is not null;

-- office_id is derived, never posted — same rule as bookings/payments
-- (20260721090000 §8).
create or replace function public.sync_ride_usage_office()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip_office uuid;
begin
  select office_id into new.office_id
    from public.subscriptions where id = new.subscription_id;

  if new.office_id is null then
    raise exception 'ride_usage_office_unresolved';
  end if;

  if new.trip_id is not null then
    select office_id into v_trip_office
      from public.operation_trips where id = new.trip_id;
    if v_trip_office is distinct from new.office_id then
      raise exception 'ride_usage_trip_office_mismatch';
    end if;
  end if;

  return new;
end $$;

drop trigger if exists trg_subscription_ride_usage_office
  on public.subscription_ride_usage;
create trigger trg_subscription_ride_usage_office
  before insert on public.subscription_ride_usage
  for each row execute function public.sync_ride_usage_office();

alter table public.subscription_ride_usage enable row level security;

-- Read: the owning office, and the subscriber themselves (the Client app shows a
-- rider their own ride history).
drop policy if exists subscription_ride_usage_office_read
  on public.subscription_ride_usage;
create policy subscription_ride_usage_office_read on public.subscription_ride_usage
  for select to authenticated
  using (office_id = public.current_office_id());

drop policy if exists subscription_ride_usage_client_read
  on public.subscription_ride_usage;
create policy subscription_ride_usage_client_read on public.subscription_ride_usage
  for select to authenticated
  using (exists (
    select 1 from public.subscriptions s
     where s.id = subscription_id and s.client_id = auth.uid()
  ));

-- No INSERT/UPDATE/DELETE policy by design: the ledger is written only by
-- consume_subscription_ride (SECURITY DEFINER), so a spent ride cannot be edited
-- away from the client side.

-- Supabase's default privileges grant every table in `public` to anon and
-- authenticated, so the grants have to be narrowed explicitly rather than assumed.
revoke all on public.subscription_ride_usage from anon;
revoke all on public.subscription_ride_usage from authenticated;
grant select on public.subscription_ride_usage to authenticated;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. Consuming a ride now records which trip it was spent on
-- ───────────────────────────────────────────────────────────────────────────────────
-- The single-argument form is dropped rather than kept alongside the new one: two
-- overloads differing only by a defaulted argument make a one-argument call ambiguous
-- ("function is not unique") for PostgREST and for plpgsql alike.

drop function if exists public.consume_subscription_ride(uuid);

create function public.consume_subscription_ride(
  p_subscription_id uuid,
  p_trip_id uuid default null
)
returns public.subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.subscriptions;
begin
  update public.subscriptions
     set trips_used = trips_used + 1,
         status = case
           when trips_count > 0 and trips_used + 1 >= trips_count
             then 'expired'
           else status
         end,
         updated_at = now()
   where id = p_subscription_id
     and status = 'active'
     and start_date <= current_date
     and end_date >= current_date
     and (trips_count = 0 or trips_used < trips_count)
  returning * into result;

  if result.id is null then
    raise exception 'Subscription is inactive, expired, or has no rides left';
  end if;

  -- The unique index makes a second consumption on the same trip a hard error, so
  -- the balance decrement above is rolled back with it.
  insert into public.subscription_ride_usage (
    subscription_id, office_id, trip_id, recorded_by
  ) values (
    p_subscription_id, result.office_id, p_trip_id, auth.uid()
  );

  return result;
exception
  when unique_violation then
    raise exception 'ride_already_recorded_for_trip';
end $$;

drop function if exists public.office_consume_subscription_ride(uuid);

create function public.office_consume_subscription_ride(
  p_subscription_id uuid,
  p_trip_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_office uuid;
  v_trip_office uuid;
begin
  v_office := public.assert_office_owns_subscription(p_subscription_id);

  if p_trip_id is not null then
    select office_id into v_trip_office
      from public.operation_trips where id = p_trip_id;
    if v_trip_office is null then
      raise exception 'trip_not_found';
    end if;
    if v_trip_office <> v_office then
      raise exception 'cross_office_denied';
    end if;
  end if;

  return to_jsonb(public.consume_subscription_ride(p_subscription_id, p_trip_id));
end $$;

revoke all on function public.consume_subscription_ride(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.office_consume_subscription_ride(uuid, uuid)
  from public, anon;
grant execute on function public.office_consume_subscription_ride(uuid, uuid)
  to authenticated;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 4. Renewal carries the office (and the trip/route context)
-- ───────────────────────────────────────────────────────────────────────────────────
-- Unchanged from the previous definition apart from the columns copied across:
-- office_id (previously omitted → NOT NULL violation on every renewal) plus the three
-- new links, so a renewed subscription stays on the same route board as the original.

create or replace function public.request_subscription_renewal(p_subscription_id uuid)
returns public.subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  source public.subscriptions;
  result public.subscriptions;
  duration_days integer;
  renewal_start date;
begin
  select * into source
    from public.subscriptions
   where id = p_subscription_id;

  if source.id is null then
    raise exception 'Subscription not found';
  end if;

  duration_days := greatest(
    coalesce(
      (select days from public.packages where id = source.package_id),
      source.end_date - source.start_date,
      1
    ),
    1
  );
  renewal_start := greatest(coalesce(source.end_date + 1, current_date), current_date);

  insert into public.subscriptions (
    office_id, client_id, customer_name, customer_phone, package_id, package_name,
    route_name, route_id, origin_trip_id, origin_booking_id,
    start_date, end_date, status, total_price, paid_amount,
    remaining_amount, renewals_count, trips_count, trips_used,
    payment_review_status
  ) values (
    source.office_id, source.client_id, source.customer_name, source.customer_phone,
    source.package_id, source.package_name,
    source.route_name, source.route_id, source.origin_trip_id, source.origin_booking_id,
    renewal_start, renewal_start + duration_days - 1, 'pending_payment',
    source.total_price, 0, source.total_price, source.renewals_count + 1,
    source.trips_count, 0, 'pending'
  )
  returning * into result;

  return result;
end $$;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 5. approve_payment writes a complete, office-attributed subscription
-- ───────────────────────────────────────────────────────────────────────────────────
-- Identical to 20260730090000's definition except for the mirror INSERT, which now
-- supplies office_id (previously missing → the insert always raised, so approving a
-- multi-ride package booking failed outright) and the route/trip/booking links.

create or replace function public.approve_payment(
  p_booking_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.operation_bookings%rowtype;
  v_package public.transport_packages%rowtype;
  v_subscription_id uuid;
  v_route_id uuid;
begin
  if auth.uid() is not null and not public.is_admin() then
    raise exception 'not_authorized';
  end if;

  select * into v_booking
  from public.operation_bookings
  where id = p_booking_id
  for update;

  if not found then raise exception 'booking_not_found'; end if;
  if v_booking.status <> 'reserved' then raise exception 'booking_not_pending'; end if;

  perform 1 from public.booking_payments
  where booking_id = p_booking_id and status in ('submitted', 'under_review')
  for update;
  if not found then raise exception 'payment_not_submitted'; end if;

  select * into v_package
  from public.transport_packages where id = v_booking.package_id;

  if v_package.ride_count > 1 then
    -- Operational ride ledger (kept for the operation_bookings.subscription_id FK).
    insert into public.transport_subscriptions (
      client_id, package_id, total_rides, remaining_rides, starts_at,
      expires_at, status
    ) values (
      v_booking.client_id, v_package.id, v_package.ride_count,
      v_package.ride_count - 1, v_booking.plan_start_date,
      v_booking.plan_end_date, 'active'
    ) returning id into v_subscription_id;

    select route_id into v_route_id
      from public.operation_trips where id = v_booking.trip_id;

    -- Mirror into the subscriptions table the dashboard/finance/reports/client
    -- all read, so the subscriber shows up in the Subscriptions tab with their
    -- package, route, plan window, price and ride balance. total_price/
    -- paid_amount come from what was actually charged (v_booking.payment_amount),
    -- not a re-derived catalog price, so this can never diverge from
    -- operation_bookings/booking_payments. office_id and the route/trip/booking
    -- links come from the booking, which is the only thing that knows them.
    insert into public.subscriptions (
      office_id, client_id, customer_name, customer_phone, package_name, route_name,
      route_id, origin_trip_id, origin_booking_id,
      start_date, end_date, status, total_price, paid_amount, remaining_amount,
      trips_count, trips_used, payment_method, payment_review_status
    ) values (
      v_booking.office_id, v_booking.client_id, v_booking.passenger_name,
      v_booking.phone,
      coalesce(nullif(trim(v_package.name_ar), ''), v_package.name_en, 'باقة'),
      v_booking.route,
      v_route_id, v_booking.trip_id, v_booking.id,
      v_booking.plan_start_date, v_booking.plan_end_date, 'active',
      v_booking.payment_amount, v_booking.payment_amount, 0,
      v_package.ride_count, 1, v_booking.payment_method, 'accepted'
    );
  end if;

  update public.operation_bookings
  set status = 'confirmed',
      payment_status = 'approved',
      payment_review_status = 'reviewed',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      subscription_id = v_subscription_id,
      notes = case
        when nullif(trim(coalesce(p_note, '')), '') is null then notes
        else jsonb_build_array(trim(p_note)) || coalesce(notes, '[]'::jsonb)
      end,
      updated_at = now()
  where id = p_booking_id;

  update public.booking_payments
  set status = 'approved', reviewed_by = auth.uid(), reviewed_at = now(),
      updated_at = now()
  where booking_id = p_booking_id;

  update public.trip_seats
  set state = 'paid', held_at = null, hold_expires_at = null
  where id = v_booking.seat_id
    and trip_id = v_booking.trip_id
    and passenger_id = v_booking.client_id;
  if not found then raise exception 'seat_hold_not_found'; end if;

  insert into public.trip_passengers (
    booking_id, trip_id, customer_id, passenger_name, phone, seat_id,
    seat_label, pickup_point_id, pickup_point_name, dropoff_point_id,
    dropoff_point_name, payment_method, status
  ) values (
    p_booking_id, v_booking.trip_id, v_booking.client_id,
    v_booking.passenger_name, v_booking.phone, v_booking.seat_id,
    v_booking.seat, v_booking.pickup_point_id, v_booking.pickup_point_name,
    v_booking.dropoff_point_id, v_booking.dropoff_point_name,
    v_booking.payment_method, 'reserved'
  );

  insert into public.notifications (
    user_id, title, body, type, category, target_app, data
  ) values (
    v_booking.client_id, 'تم اعتماد الدفع',
    'تم تأكيد حجزك. يمكنك الآن متابعة حالة الرحلة.',
    'payment_approved', 'payment', 'client',
    jsonb_build_object(
      'booking_id', p_booking_id, 'trip_id', v_booking.trip_id
    )
  );

  return jsonb_build_object(
    'success', true, 'booking_id', p_booking_id, 'status', 'confirmed'
  );
end;
$$;

grant execute on function public.approve_payment(uuid, text) to anon, authenticated;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 6. Backfill the links for subscriptions that already exist
-- ───────────────────────────────────────────────────────────────────────────────────
-- Step 1 — rows mirrored from a booking. The mirror INSERT copied client, plan window
-- and route text verbatim, so those four together identify the source booking. Ties
-- (a client who bought the same package twice for the same window) resolve to the
-- earliest booking, which is the one the mirror ran for.

with matched as (
  select distinct on (s.id)
         s.id       as subscription_id,
         b.id       as booking_id,
         b.trip_id  as trip_id,
         t.route_id as route_id
    from public.subscriptions s
    join public.operation_bookings b
      on b.office_id = s.office_id
     and b.client_id = s.client_id
     and b.plan_start_date = s.start_date
     and b.plan_end_date   = s.end_date
     and coalesce(b.route, '') = coalesce(s.route_name, '')
    left join public.operation_trips t on t.id = b.trip_id
   where s.origin_booking_id is null
     and s.client_id is not null
     and s.start_date is not null
     and s.end_date is not null
   order by s.id, b.created_at
)
update public.subscriptions s
   set origin_booking_id = matched.booking_id,
       origin_trip_id    = coalesce(s.origin_trip_id, matched.trip_id),
       route_id          = coalesce(s.route_id, matched.route_id)
  from matched
 where s.id = matched.subscription_id;

-- Step 2 — rows with no booking to match (hand-created, or created before the route
-- link existed). Resolve `route_name` against the office's routes, but only when
-- exactly one route matches: several routes can share a start/end city pair, and
-- guessing between them would put a subscriber on the wrong trip board.

with candidates as (
  select s.id as subscription_id,
         min(r.id::text)::uuid as route_id,
         count(*) as match_count
    from public.subscriptions s
    join public.operation_routes r
      on r.office_id = s.office_id
     and (
       r.name = s.route_name
       or concat(r.start_city, ' → ', r.end_city) = s.route_name
       or concat(r.start_city, ' - ', r.end_city) = s.route_name
     )
   where s.route_id is null
     and nullif(trim(coalesce(s.route_name, '')), '') is not null
   group by s.id
)
update public.subscriptions s
   set route_id = candidates.route_id
  from candidates
 where s.id = candidates.subscription_id
   and candidates.match_count = 1;
