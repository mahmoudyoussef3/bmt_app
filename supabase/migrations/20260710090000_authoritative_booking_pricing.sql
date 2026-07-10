-- migration_20260710090000_authoritative_booking_pricing.sql
--
-- Root cause (found while fixing a Client-app display bug where the fare
-- shown for a pickup->dropoff pair didn't match what the Dashboard operator
-- configured for that pair): confirm_seat_booking_v2 never priced the
-- booking itself. It hard-coded payment_amount to v_package.price (the
-- flat, route-agnostic catalog price on transport_packages) for every
-- booking, and silently accepted-but-ignored the client-supplied
-- p_payment_amount. So no matter what the Client app displayed, the amount
-- actually recorded in operation_bookings.payment_amount and
-- booking_payments.amount was always the generic catalog price, never the
-- Dashboard's per-(trip, from_point_id, to_point_id) trip_pricing fare.
--
-- This migration makes the server the single source of truth for the
-- charged amount:
--   1. confirm_seat_booking_v2 now COMPUTES the amount itself:
--        a. Subscription-covered ride (new, optional p_subscription_id):
--           amount = 0, and transport_subscriptions.remaining_rides is
--           decremented. Since there is nothing to review (no receipt, no
--           money changing hands), the booking is confirmed immediately
--           in this same call instead of going through approve_payment
--           (booking_payments.amount has a `check (amount > 0)` constraint,
--           so a $0 row cannot and should not be inserted there).
--        b. Package purchase (existing p_package_id path, single-ride or
--           multi-ride): resolved from public.trip_pricing for the exact
--           (p_trip_id, p_pickup_point_id, p_dropoff_point_id) row, picking
--           the tier column that matches the package's duration_days
--           (see the CASE below for the exact bucketing and its rationale).
--           Falls back to the flat transport_packages.price only when that
--           stop pair has no trip_pricing row yet (graceful degradation —
--           matches the fallback already implemented client-side) or the
--           package's shape has no trip_pricing equivalent (e.g.
--           "go_and_return": duration_days=1 with ride_count=2 has no
--           dedicated round-trip column on trip_pricing).
--   2. That single computed amount is written to BOTH
--      operation_bookings.payment_amount and booking_payments.amount —
--      never two independent values.
--   3. approve_payment's mirror into public.subscriptions (added by
--      20260706130000_subscription_from_approved_booking.sql) now carries
--      v_booking.payment_amount (what was actually charged and recorded)
--      instead of re-querying transport_packages.price, so the Subscriptions
--      tab/finance/reports show the same number that was actually charged.
--
-- Backward compatibility: every existing parameter is kept, in the same
-- order, with the same meaning; p_payment_amount is still accepted (kept
-- so old client builds don't fail validation) but is no longer trusted for
-- the final charge — the return payload's payment_amount is now the
-- server-computed value, which callers should treat as authoritative.
-- Only one parameter is added: p_subscription_id uuid default null, at the
-- end. Because PostgreSQL identifies a function by its full argument-type
-- list, appending a parameter — even a defaulted one — does not "replace"
-- the existing 21-argument function; it would create a second, ambiguous
-- overload that breaks every existing named-parameter call (Supabase's
-- .rpc() always calls with named parameters). So the old signature is
-- explicitly dropped first. This is a one-time, unavoidable signature
-- change; no existing caller passes p_subscription_id, so every current
-- call site keeps working unchanged (it just omits the new, defaulted
-- argument).

-- Exact type list copied from the grant statement in
-- 20260706110000_fix_booking_status_vocabulary.sql (the live 21-argument
-- signature) so this DROP is guaranteed to match — an ambiguous or
-- non-matching DROP would leave two overloads in place and break every
-- existing named-parameter call with "function ... is not unique".
drop function if exists public.confirm_seat_booking_v2(
  uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, date, text,
  text, numeric, text, text, uuid, date, text, text, text
);

create function public.confirm_seat_booking_v2(
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
  -- p_payment_amount is intentionally never read past this point. This
  -- sits where the old package-only lookup used to run (right after the
  -- trip check, before the duplicate/seat checks) so the error precedence
  -- for existing callers is unchanged.
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

    -- Dashboard-configured fare for this exact stop pair, if the operator
    -- has priced it. trip_pricing is per (trip_id, from_point_id,
    -- to_point_id); transport_packages has no route/trip scoping at all,
    -- so trip_pricing is always preferred when it exists for this pair.
    select * into v_pricing
    from public.trip_pricing
    where trip_id = p_trip_id
      and from_point_id = p_pickup_point_id
      and to_point_id = p_dropoff_point_id
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

-- ---------------------------------------------------------------------------
-- approve_payment: mirror the amount actually charged (operation_bookings.
-- payment_amount, set authoritatively above), not a freshly re-queried
-- transport_packages.price — otherwise the Subscriptions tab/finance/
-- reports could show a different number than what confirm_seat_booking_v2
-- actually recorded. Everything else is identical to
-- 20260706130000_subscription_from_approved_booking.sql.
-- ---------------------------------------------------------------------------
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

    -- Mirror into the subscriptions table the dashboard/finance/reports/client
    -- all read, so the subscriber shows up in the Subscriptions tab with their
    -- package, route, plan window, price and ride balance. total_price/
    -- paid_amount now come from what was actually charged
    -- (v_booking.payment_amount), not a re-derived catalog price, so this
    -- can never diverge from operation_bookings/booking_payments.
    insert into public.subscriptions (
      client_id, customer_name, customer_phone, package_name, route_name,
      start_date, end_date, status, total_price, paid_amount, remaining_amount,
      trips_count, trips_used, payment_method, payment_review_status
    ) values (
      v_booking.client_id, v_booking.passenger_name, v_booking.phone,
      coalesce(nullif(trim(v_package.name_ar), ''), v_package.name_en, 'باقة'),
      v_booking.route,
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
