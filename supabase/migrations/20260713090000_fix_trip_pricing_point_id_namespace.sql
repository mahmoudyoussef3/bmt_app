-- migration_20260713090000_fix_trip_pricing_point_id_namespace.sql
--
-- Root cause: confirm_seat_booking_v2 (20260710090000_authoritative_booking_
-- pricing.sql) looks the fare up with
--
--     where trip_id = p_trip_id
--       and from_point_id = p_pickup_point_id
--       and to_point_id   = p_dropoff_point_id
--
-- but those two sides live in different id spaces and can never be equal:
--
--   * `trip_pricing.from_point_id` / `to_point_id` are **trip_route_points.id**
--     — the per-trip snapshot of the route's stations that createTrip writes,
--     and what CreateTripUseCase expands the operator's fare across.
--   * `p_pickup_point_id` / `p_dropoff_point_id` are **route_stations.id** —
--     the Client app's stop picker reads `route_stations`, and
--     operation_bookings.pickup_point_id has stored route_stations ids all
--     along.
--
-- `trip_route_points.route_point_id` is the bridge between them, and nothing
-- was crossing it. So the `select ... into v_pricing` never found a row, the
-- graceful "operator hasn't priced this pair yet" fallback fired on EVERY
-- booking, and the rider was charged the flat, route-agnostic
-- transport_packages.price instead of the Dashboard's per-stop-pair fare.
-- Live example: booking e90304bd charged 8500 (the "Three Months" catalog
-- price) for a trip whose configured three_months_price is 450.
--
-- The fix translates the incoming route_stations ids into this trip's
-- trip_route_points ids before the lookup. The translation is a coalesce, not
-- a hard swap, so an id already in trip_route_points space (any other caller,
-- present or future) still matches directly. Nothing else in the function
-- changes; the signature is identical, so this is a plain replace.
--
-- The Client app's package cards resolve the same row client-side
-- (TripPricingResolver + trip_stop_pair_price_mapper) and are fixed in the
-- same change, so what the rider sees is what this function charges.
--
-- Not repaired here: bookings already recorded at the catalog price. They are
-- financial records (operation_bookings.payment_amount, booking_payments.
-- amount, subscriptions.total_price/paid_amount) and re-pricing them is an
-- operator decision, not a migration's.

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
      -- Bucket the package's duration_days onto the matching trip_pricing
      -- tier column. Calibrated against the seeded catalog: work_week=5d
      -- -> five_days_price, two_work_weeks=10d -> ten_days_price,
      -- work_month=30d -> monthly_price, three_months=90d ->
      -- three_months_price. A package whose shape has no trip_pricing
      -- equivalent (e.g. go_and_return: 1 day but ride_count=2, a same-day
      -- round trip with no dedicated column) falls through to NULL here
      -- and is caught by the catalog-price fallback below rather than
      -- guessed at.
      v_amount := case
        when v_package.duration_days <= 1 and v_package.ride_count = 1
          then v_pricing.one_time_price
        when v_package.duration_days between 2 and 6
          then v_pricing.five_days_price
        when v_package.duration_days between 7 and 15
          then v_pricing.ten_days_price
        when v_package.duration_days between 16 and 60
          then v_pricing.monthly_price
        when v_package.duration_days > 60
          then v_pricing.three_months_price
        else null
      end;
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
