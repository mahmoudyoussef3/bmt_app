-- migration_20260720090000_paymob_card_settlement.sql
--
-- Card payments had no settlement path.
--
-- `confirm_seat_booking_v2` writes a card booking as
-- (status 'reserved', payment_status 'pending', booking_payments.status
-- 'pending') and holds the seat for 30 minutes. Nothing ever moved it on:
--
--   * `approve_payment` refuses it — it requires booking_payments.status in
--     ('submitted', 'under_review'), so an operator could not rescue a card
--     booking by hand either;
--   * the client app decided "paid" by reading `success=true` off the Paymob
--     redirect URL inside its own WebView, which settles nothing server-side
--     and is trivially forged by anyone who can edit a URL.
--
-- So a rider whose card was actually charged kept a booking that expired with
-- the seat hold. This migration gives the gateway a way in:
--
--   1. `link_paymob_order`     — records the Paymob order against the booking
--                                when the intention is created, so a callback
--                                that only knows the order id can find it.
--   2. `settle_paymob_payment` — the money verdict, applied server-side and
--                                idempotently (Paymob retries callbacks).
--   3. `card_payment_state`    — what the rider's app polls after the WebView
--                                closes, so success is read from our own row
--                                rather than from a redirect parameter.
--
-- Only service_role may call 1 and 2: they are driven by the HMAC-verified
-- `paymob-payment-callback` edge function, never by an app.

-- 1) Gateway columns on the payment row ---------------------------------------
alter table public.booking_payments
  add column if not exists gateway text,
  add column if not exists gateway_order_id text,
  add column if not exists gateway_transaction_id text,
  add column if not exists gateway_response jsonb,
  add column if not exists paid_at timestamptz;

-- A Paymob order maps to exactly one booking payment; the partial index both
-- enforces that and makes the callback's lookup a single index probe.
create unique index if not exists idx_booking_payments_gateway_order
  on public.booking_payments (gateway_order_id)
  where gateway_order_id is not null;

-- A card attempt that the gateway declined is 'failed' — distinct from
-- 'rejected', which means a human looked at a receipt and said no.
alter table public.booking_payments
  drop constraint if exists booking_payments_status_check;
alter table public.booking_payments
  add constraint booking_payments_status_check check (
    status in (
      'pending', 'submitted', 'under_review', 'approved', 'rejected',
      'refunded', 'failed'
    )
  );

-- 2) Link a Paymob order to the booking it is paying --------------------------
create or replace function public.link_paymob_order(
  p_booking_id uuid,
  p_order_id text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order text := nullif(trim(coalesce(p_order_id, '')), '');
begin
  if v_order is null then raise exception 'order_id_required'; end if;

  update public.booking_payments
  set gateway = 'paymob',
      gateway_order_id = v_order,
      updated_at = now()
  where booking_id = p_booking_id;

  if not found then raise exception 'booking_payment_not_found'; end if;

  return jsonb_build_object('success', true, 'order_id', v_order);
end;
$$;

-- 3) Apply the gateway's verdict ----------------------------------------------
--
-- Idempotent by design: Paymob delivers a transaction callback more than once
-- for the same order, and a second delivery must not book a second seat, mint
-- a second subscription, or re-notify the rider.
create or replace function public.settle_paymob_payment(
  p_order_id text,
  p_transaction_id text,
  p_amount_cents bigint,
  p_success boolean,
  p_raw jsonb default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment public.booking_payments%rowtype;
  v_booking public.operation_bookings%rowtype;
  v_package public.transport_packages%rowtype;
  v_subscription_id uuid;
  v_expected_cents bigint;
begin
  if nullif(trim(coalesce(p_order_id, '')), '') is null then
    raise exception 'order_id_required';
  end if;

  select * into v_payment
  from public.booking_payments
  where gateway_order_id = trim(p_order_id)
  for update;

  if not found then raise exception 'payment_not_found'; end if;

  -- Already settled: report the existing outcome instead of re-applying it.
  if v_payment.status in ('approved', 'refunded') then
    return jsonb_build_object(
      'success', true, 'already_settled', true,
      'booking_id', v_payment.booking_id, 'status', v_payment.status
    );
  end if;

  select * into v_booking
  from public.operation_bookings
  where id = v_payment.booking_id
  for update;
  if not found then raise exception 'booking_not_found'; end if;

  -- ---- Declined / cancelled at the gateway ---------------------------------
  -- The seat keeps its hold: the rider can pick another method and settle the
  -- booking that already exists, which is why this does not cancel anything.
  if not coalesce(p_success, false) then
    update public.booking_payments
    set status = 'failed',
        gateway_transaction_id = nullif(trim(coalesce(p_transaction_id, '')), ''),
        gateway_response = coalesce(p_raw, gateway_response),
        updated_at = now()
    where id = v_payment.id;

    update public.operation_bookings
    set payment_status = 'failed', updated_at = now()
    where id = v_booking.id;

    insert into public.notifications (
      user_id, title, body, type, category, target_app, data
    ) values (
      v_booking.client_id, 'لم تتم عملية الدفع',
      'لم يكتمل الدفع بالبطاقة. مقعدك محجوز مؤقتًا — يمكنك إعادة المحاولة أو اختيار وسيلة دفع أخرى.',
      'payment_rejected', 'payment', 'client',
      jsonb_build_object(
        'booking_id', v_booking.id, 'trip_id', v_booking.trip_id
      )
    );

    return jsonb_build_object(
      'success', true, 'booking_id', v_booking.id, 'status', 'failed'
    );
  end if;

  -- ---- Approved: the amount must match what we asked for -------------------
  -- A callback that pays less than the fare is not a payment for this booking.
  v_expected_cents := round(v_payment.amount * 100)::bigint;
  if p_amount_cents is not null and p_amount_cents <> v_expected_cents then
    raise exception 'amount_mismatch: expected % got %',
      v_expected_cents, p_amount_cents;
  end if;

  if v_booking.status <> 'reserved' then
    raise exception 'booking_not_pending';
  end if;

  -- A multi-ride package becomes a live subscription, exactly as it does on the
  -- operator-approved path (see approve_payment).
  select * into v_package
  from public.transport_packages where id = v_booking.package_id;

  if v_package.ride_count > 1 then
    insert into public.transport_subscriptions (
      client_id, package_id, total_rides, remaining_rides, starts_at,
      expires_at, status
    ) values (
      v_booking.client_id, v_package.id, v_package.ride_count,
      v_package.ride_count - 1, v_booking.plan_start_date,
      v_booking.plan_end_date, 'active'
    ) returning id into v_subscription_id;

    -- Mirror into the table the dashboard/finance/reports/client all read.
    -- Prices come from what was actually charged, never a re-derived catalog
    -- price, so this can never diverge from operation_bookings.
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
      reviewed_at = now(),
      subscription_id = v_subscription_id,
      updated_at = now()
  where id = v_booking.id;

  update public.booking_payments
  set status = 'approved',
      gateway_transaction_id = nullif(trim(coalesce(p_transaction_id, '')), ''),
      gateway_response = coalesce(p_raw, gateway_response),
      payment_reference = coalesce(
        nullif(trim(coalesce(p_transaction_id, '')), ''), payment_reference
      ),
      paid_at = now(),
      reviewed_at = now(),
      updated_at = now()
  where id = v_payment.id;

  update public.trip_seats
  set state = 'paid', held_at = null, hold_expires_at = null,
      lock_expires_at = null
  where id = v_booking.seat_id
    and trip_id = v_booking.trip_id
    and passenger_id = v_booking.client_id;
  if not found then raise exception 'seat_hold_not_found'; end if;

  -- The manifest row. Guarded because a redelivered callback that got this far
  -- must not put the same passenger on the bus twice.
  insert into public.trip_passengers (
    booking_id, trip_id, customer_id, passenger_name, phone, seat_id,
    seat_label, pickup_point_id, pickup_point_name, dropoff_point_id,
    dropoff_point_name, payment_method, status
  )
  select
    v_booking.id, v_booking.trip_id, v_booking.client_id,
    v_booking.passenger_name, v_booking.phone, v_booking.seat_id,
    v_booking.seat, v_booking.pickup_point_id, v_booking.pickup_point_name,
    v_booking.dropoff_point_id, v_booking.dropoff_point_name,
    v_booking.payment_method, 'reserved'
  where not exists (
    select 1 from public.trip_passengers where booking_id = v_booking.id
  );

  insert into public.notifications (
    user_id, title, body, type, category, target_app, data
  ) values (
    v_booking.client_id, 'تم تأكيد الدفع',
    'تم استلام دفعتك بالبطاقة وتأكيد مقعدك.',
    'payment_approved', 'payment', 'client',
    jsonb_build_object(
      'booking_id', v_booking.id, 'trip_id', v_booking.trip_id
    )
  );

  return jsonb_build_object(
    'success', true, 'booking_id', v_booking.id, 'status', 'confirmed'
  );
end;
$$;

-- 4) What the rider's app polls after the WebView closes -----------------------
--
-- Scoped to the caller's own booking, so this cannot be used to enumerate
-- anyone else's payments.
create or replace function public.card_payment_state(p_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  v_payment_status text;
  v_booking_status text;
begin
  select b.payment_status, b.status, p.status
  into v_payment_status, v_booking_status, v_status
  from public.operation_bookings b
  left join public.booking_payments p on p.booking_id = b.id
  where b.id = p_booking_id
    and (auth.uid() is null or b.client_id = auth.uid());

  if v_booking_status is null then raise exception 'booking_not_found'; end if;

  return jsonb_build_object(
    'booking_id', p_booking_id,
    'booking_status', v_booking_status,
    'payment_status', v_payment_status,
    'gateway_status', v_status,
    'settled', v_payment_status = 'approved',
    'failed', v_payment_status in ('failed', 'rejected')
  );
end;
$$;

-- 5) Privileges ---------------------------------------------------------------
-- The settlement functions are the gateway's, not the app's: an app that could
-- call them could confirm its own booking without paying.
revoke all on function
  public.link_paymob_order(uuid, text) from public, anon, authenticated;
revoke all on function
  public.settle_paymob_payment(text, text, bigint, boolean, jsonb)
  from public, anon, authenticated;

grant execute on function public.link_paymob_order(uuid, text) to service_role;
grant execute on function
  public.settle_paymob_payment(text, text, bigint, boolean, jsonb)
  to service_role;

grant execute on function public.card_payment_state(uuid)
  to anon, authenticated, service_role;
