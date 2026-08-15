-- Root cause: what a rider is actually charged for a package has never come
-- from the package itself. Every trip_pricing row carries exactly 5 fixed
-- price columns (one_time_price + four "tier" columns), and
-- confirm_seat_booking_v2 picks one of the four tier columns purely by
-- bucketing the package's duration_days into a range (2-6 -> five_days,
-- 7-15 -> ten_days, 16-60 -> monthly, >60 -> three_months). Two different
-- office-created packages that both happen to land in the same duration
-- range are charged the exact same price on a given trip, no matter what
-- the office actually wants to charge for each — the price lives on the
-- trip's bucket, not on the package. That is what keeps every office stuck
-- with "1/2/5-day" shaped packages even though transport_packages.duration_
-- days/ride_count have been freeform integers since the package_type enum
-- was dropped (20260704000000_production_booking_flow_hardening.sql).
--
-- Fix: replace the 4 bucketed tier columns with a real per-package price,
-- keyed by package_id, so an office's own packages are priced individually
-- on every trip. one_time_price is untouched — every walk-up (non-
-- subscription) booking already references a package shaped
-- duration_days<=1/ride_count=1, and that case keeps mapping straight to
-- one_time_price exactly as it does today.

create table public.trip_package_prices (
  id uuid primary key default gen_random_uuid(),
  trip_pricing_id uuid not null references public.trip_pricing(id) on delete cascade,
  package_id uuid not null references public.transport_packages(id) on delete cascade,
  price numeric(12, 2) not null check (price >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (trip_pricing_id, package_id)
);

create index idx_trip_package_prices_trip_pricing_id
  on public.trip_package_prices(trip_pricing_id);
create index idx_trip_package_prices_package_id
  on public.trip_package_prices(package_id);

drop trigger if exists update_trip_package_prices_updated_at
  on public.trip_package_prices;
create trigger update_trip_package_prices_updated_at
  before update on public.trip_package_prices
  for each row execute function public.update_updated_at_column();

-- RLS follows the same "office derived through the trip" shape as
-- trip_pricing/trip_seats/trip_route_points (20260721090200_multi_office_
-- rls.sql), one hop further since this table hangs off trip_pricing rather
-- than operation_trips directly. The extra join on transport_packages
-- guards against pricing another office's package onto this office's trip
-- (or vice versa) — nothing else in the schema pairs a package to an office
-- at write time.

alter table public.trip_package_prices enable row level security;

create policy trip_package_prices_office_manage on public.trip_package_prices
  for all to authenticated
  using (exists (
    select 1
    from public.trip_pricing tp
    join public.operation_trips tr on tr.id = tp.trip_id
    join public.transport_packages pkg on pkg.id = package_id
    where tp.id = trip_pricing_id
      and tr.office_id = public.current_office_id()
      and pkg.office_id = tr.office_id
  ))
  with check (exists (
    select 1
    from public.trip_pricing tp
    join public.operation_trips tr on tr.id = tp.trip_id
    join public.transport_packages pkg on pkg.id = package_id
    where tp.id = trip_pricing_id
      and tr.office_id = public.current_office_id()
      and pkg.office_id = tr.office_id
  ));

create policy trip_package_prices_marketplace_read on public.trip_package_prices
  for select to anon, authenticated
  using (exists (
    select 1
    from public.trip_pricing tp
    join public.operation_trips tr on tr.id = tp.trip_id
    where tp.id = trip_pricing_id
      and public.office_is_active(tr.office_id)
  ));

-- Backfill: reproduce exactly what confirm_seat_booking_v2 would have
-- charged for each of an office's packages on each of its existing trips,
-- so no live trip's configured price changes when the bucket columns go
-- away below.
insert into public.trip_package_prices (trip_pricing_id, package_id, price)
select mapped.trip_pricing_id, mapped.package_id, mapped.price
from (
  select
    tp.id as trip_pricing_id,
    pkg.id as package_id,
    case
      when pkg.duration_days between 2 and 6 then tp.five_days_price
      when pkg.duration_days between 7 and 15 then tp.ten_days_price
      when pkg.duration_days between 16 and 60 then tp.monthly_price
      when pkg.duration_days > 60 then tp.three_months_price
      else null
    end as price
  from public.trip_pricing tp
  join public.operation_trips tr on tr.id = tp.trip_id
  join public.transport_packages pkg on pkg.office_id = tr.office_id
) mapped
where mapped.price is not null and mapped.price > 0
on conflict (trip_pricing_id, package_id) do nothing;

alter table public.trip_pricing
  drop column if exists five_days_price,
  drop column if exists ten_days_price,
  drop column if exists monthly_price,
  drop column if exists three_months_price;

-- confirm_seat_booking_v2: identical signature, only the amount-resolution
-- block changes (single-ride packages keep resolving to one_time_price; any
-- other package now looks itself up in trip_package_prices instead of a
-- duration bucket). Everything else in the function is unchanged from
-- 20260713090000_fix_trip_pricing_point_id_namespace.sql.

create or replace function public.confirm_seat_booking_v2(
  p_client_id          uuid,
  p_trip_id            uuid,
  p_seat_id            uuid,
  p_pricing_id         uuid,
  p_pickup_point_id    uuid,
  p_dropoff_point_id   uuid,
  p_passenger_name     text,
  p_phone              text,
  p_route              text,
  p_trip_time          text,
  p_trip_date          date,
  p_seat_label         text,
  p_payment_method     text,
  p_payment_amount     numeric,
  p_pickup_point_name  text,
  p_dropoff_point_name text,
  p_package_id         uuid,
  p_plan_start_date    date,
  p_receipt_url        text default null,
  p_payment_reference  text default null,
  p_payer_phone        text default null,
  p_subscription_id    uuid default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking_id     uuid;
  v_booking_number text;
  v_trip           public.operation_trips%rowtype;
  v_seat           public.trip_seats%rowtype;
  v_package        public.transport_packages%rowtype;
  v_pricing        public.trip_pricing%rowtype;
  v_subscription   public.transport_subscriptions%rowtype;
  v_from_point_id  uuid;
  v_to_point_id    uuid;
  v_amount         numeric(12, 2);
  v_via_subscription boolean := false;
begin
  if auth.uid() is null or auth.uid() <> p_client_id then
    raise exception 'not_authorized';
  end if;
  if p_payment_method not in (
    'credit_card', 'instapay', 'vodafone_cash', 'bank_transfer'
  ) then
    raise exception 'payment_method_not_allowed';
  end if;
  if p_subscription_id is null
     and p_payment_method <> 'credit_card'
     and nullif(trim(coalesce(p_receipt_url, '')), '') is null then
    raise exception 'payment_receipt_required';
  end if;

  select * into v_trip
  from public.operation_trips
  where id = p_trip_id
  for share;

  if not found or v_trip.status <> 'open_for_booking' then
    raise exception 'trip_not_available';
  end if;

  -- ---------------------------------------------------------------------
  -- Resolve the authoritative amount server-side. The client-sent
  -- p_payment_amount is intentionally never read past this point.
  -- ---------------------------------------------------------------------
  if p_subscription_id is not null then
    select * into v_subscription
    from public.transport_subscriptions
    where id = p_subscription_id
      and client_id = p_client_id
    for update;

    if not found
       or v_subscription.status <> 'active'
       or v_subscription.remaining_rides <= 0
       or v_subscription.expires_at < current_date
    then
      raise exception 'subscription_not_usable';
    end if;

    v_amount := 0;
    v_via_subscription := true;
  else
    select * into v_package
    from public.transport_packages
    where id = p_package_id and active = true;

    if not found then
      raise exception 'package_not_available';
    end if;

    -- Translate the rider's stops (route_stations ids) into this trip's
    -- snapshot points (trip_route_points ids), which is what trip_pricing is
    -- keyed by. coalesce keeps a caller that already passes trip_route_points
    -- ids working unchanged.
    select trp.id into v_from_point_id
    from public.trip_route_points trp
    where trp.trip_id = p_trip_id
      and trp.route_point_id = p_pickup_point_id;

    select trp.id into v_to_point_id
    from public.trip_route_points trp
    where trp.trip_id = p_trip_id
      and trp.route_point_id = p_dropoff_point_id;

    -- Dashboard-configured fare for this exact stop pair, if the operator
    -- has priced it. trip_pricing is per (trip_id, from_point_id,
    -- to_point_id); transport_packages has no route/trip scoping at all,
    -- so trip_pricing is always preferred when it exists for this pair.
    select * into v_pricing
    from public.trip_pricing
    where trip_id = p_trip_id
      and from_point_id = coalesce(v_from_point_id, p_pickup_point_id)
      and to_point_id = coalesce(v_to_point_id, p_dropoff_point_id)
      and is_active = true;

    if found then
      if v_package.duration_days <= 1 and v_package.ride_count = 1 then
        v_amount := v_pricing.one_time_price;
      else
        select tpp.price into v_amount
        from public.trip_package_prices tpp
        where tpp.trip_pricing_id = v_pricing.id
          and tpp.package_id = p_package_id;
      end if;
    end if;

    if v_amount is null or v_amount <= 0 then
      v_amount := v_package.price;
    end if;
  end if;

  if v_amount is null or v_amount < 0 then
    raise exception 'fare_unavailable';
  end if;

  if exists (
    select 1 from public.operation_bookings
    where client_id = p_client_id
      and trip_id = p_trip_id
      and status in ('reserved', 'confirmed')
  ) then
    raise exception 'duplicate_active_booking';
  end if;

  select * into v_seat
  from public.trip_seats
  where id = p_seat_id and trip_id = p_trip_id
  for update;

  if not found then
    raise exception 'seat_not_found';
  end if;
  if v_seat.state <> 'reserved' or v_seat.passenger_id <> p_client_id then
    raise exception 'seat_unavailable';
  end if;
  if v_seat.lock_expires_at is null or v_seat.lock_expires_at <= now() then
    raise exception 'lock_expired';
  end if;

  v_booking_number :=
    'BK-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));

  insert into public.operation_bookings (
    client_id, trip_id, passenger_name, phone, route, trip_time, trip_date,
    seat, payment_method, payment_amount, seat_id, pricing_id,
    pickup_point_id, dropoff_point_id, pickup_point_name, dropoff_point_name,
    status, booking_number, payment_receipt_url, created_by_source, package_id,
    plan_start_date, plan_end_date, payment_status, payment_review_status,
    subscription_id
  ) values (
    p_client_id, p_trip_id, trim(p_passenger_name), trim(p_phone), p_route,
    p_trip_time, coalesce(p_trip_date, v_trip.trip_date), p_seat_label,
    p_payment_method, v_amount, p_seat_id,
    p_pricing_id, p_pickup_point_id, p_dropoff_point_id, p_pickup_point_name,
    p_dropoff_point_name,
    case when v_via_subscription then 'confirmed' else 'reserved' end,
    v_booking_number, p_receipt_url, 'client',
    case when v_via_subscription then null else p_package_id end,
    case when v_via_subscription then null
         else coalesce(p_plan_start_date, v_trip.trip_date) end,
    case when v_via_subscription then null
         else coalesce(p_plan_start_date, v_trip.trip_date)
                + greatest(v_package.duration_days - 1, 0) end,
    case when v_via_subscription then 'approved'
         when p_payment_method = 'credit_card' then 'pending'
         else 'submitted' end,
    case when v_via_subscription then 'reviewed' else 'pending' end,
    p_subscription_id
  ) returning id into v_booking_id;

  if v_via_subscription then
    -- No money changes hands: nothing to log in booking_payments (its
    -- amount column requires > 0), and nothing for a human to review, so
    -- confirm the seat immediately instead of leaving it in the manual
    -- payment-review queue.
    update public.transport_subscriptions
    set remaining_rides = remaining_rides - 1,
        status = case when remaining_rides - 1 <= 0 then 'exhausted'
                      else status end,
        updated_at = now()
    where id = p_subscription_id;

    update public.trip_seats
    set state = 'paid', held_at = null, hold_expires_at = null,
        lock_expires_at = null
    where id = p_seat_id;

    insert into public.trip_passengers (
      booking_id, trip_id, customer_id, passenger_name, phone, seat_id,
      seat_label, pickup_point_id, pickup_point_name, dropoff_point_id,
      dropoff_point_name, payment_method, status
    ) values (
      v_booking_id, p_trip_id, p_client_id, trim(p_passenger_name),
      trim(p_phone), p_seat_id, p_seat_label, p_pickup_point_id,
      p_pickup_point_name, p_dropoff_point_id, p_dropoff_point_name,
      p_payment_method, 'reserved'
    );

    insert into public.notifications (
      user_id, title, body, type, category, target_app, data
    ) values (
      p_client_id, 'تم تأكيد حجزك',
      'تم خصم رحلة من رصيد اشتراكك وتأكيد مقعدك.',
      'booking_received', 'payment', 'client',
      jsonb_build_object('booking_id', v_booking_id, 'trip_id', p_trip_id)
    );
  else
    insert into public.booking_payments (
      booking_id, client_id, method, amount, status, receipt_url,
      payment_reference, payer_phone
    ) values (
      v_booking_id, p_client_id, p_payment_method, v_amount,
      case when p_payment_method = 'credit_card' then 'pending'
           else 'submitted' end,
      p_receipt_url, nullif(trim(coalesce(p_payment_reference, '')), ''),
      nullif(trim(coalesce(p_payer_phone, '')), '')
    );

    update public.trip_seats
    set held_at = now(),
        hold_expires_at = now() + interval '30 minutes',
        lock_expires_at = null
    where id = p_seat_id;

    insert into public.notifications (
      user_id, title, body, type, category, target_app, data
    )
    select ur.user_id, 'مراجعة دفع جديدة',
      'طلب مراجعة دفع من ' || trim(p_passenger_name) || ' — ' || p_route,
      'payment_review', 'payment', 'all',
      jsonb_build_object('booking_id', v_booking_id, 'trip_id', p_trip_id)
    from public.user_roles ur
    where ur.role in ('operations_manager', 'dashboard_admin')
      and p_payment_method <> 'credit_card';

    insert into public.notifications (
      user_id, title, body, type, category, target_app, data
    ) values (
      p_client_id, 'تم استلام الحجز',
      case when p_payment_method = 'credit_card'
        then 'أكمل الدفع الآمن لتأكيد حجزك.'
        else 'تم إرسال إثبات الدفع وسيتم إشعارك بعد المراجعة.'
      end,
      'booking_received', 'payment', 'client',
      jsonb_build_object('booking_id', v_booking_id, 'trip_id', p_trip_id)
    );
  end if;

  return jsonb_build_object(
    'success', true,
    'booking_id', v_booking_id,
    'booking_number', v_booking_number,
    'trip_id', p_trip_id,
    'seat_label', p_seat_label,
    'payment_amount', v_amount,
    'status', case when v_via_subscription then 'confirmed' else 'reserved' end
  );
exception
  when unique_violation then
    raise exception 'seat_or_booking_already_exists';
end;
$$;

grant execute on function public.confirm_seat_booking_v2(
  uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, date, text,
  text, numeric, text, text, uuid, date, text, text, text, uuid
) to authenticated;
