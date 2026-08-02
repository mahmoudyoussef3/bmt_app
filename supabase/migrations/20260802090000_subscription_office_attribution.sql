-- migration_20260802090000_subscription_office_attribution.sql
--
-- Approving the payment on a multi-ride package booking failed outright:
--
--   null value in column "office_id" of relation "transport_subscriptions"
--   violates not-null constraint (23502)
--
-- 20260721090000 made office_id NOT NULL on both subscription tables, but it
-- listed them as *directly owned* (parent = null), so — unlike operation_trips,
-- operation_bookings, booking_payments and trip_reviews — neither table got a
-- `sync_*_office` trigger. That left office_id as something every writer had to
-- remember by hand, and two of the three writers did not:
--
--   * approve_payment(uuid, text)  — the operator path behind the dashboard's
--     "قبول الدفع". 20260731100000 fixed the office_id it was missing on the
--     `subscriptions` mirror but left the `transport_subscriptions` ledger
--     insert above it untouched, so the statement that actually raises is the
--     first one. This is the reported failure.
--   * settle_paymob_payment(...)   — the card-settlement path driven by the
--     paymob-payment-callback edge function. Missing office_id on *both*
--     inserts, so a card payment for a package booking would fail the same way
--     with the rider already charged at the gateway.
--
-- Both are fixed below by supplying office_id from the booking, which is the
-- only row that knows it. The card path also gains the route/trip/booking links
-- that 20260731100000 established for the operator path, so a subscription sold
-- by card is as traceable as one sold in the office.
--
-- Nothing needs backfilling: the failing INSERT aborted its whole transaction,
-- so no half-approved booking or office-less subscription was ever written.

-- ── 1. Why there is no sync_*_office trigger here ───────────────────────────────────
-- The obvious "belt as well as braces" move — a BEFORE INSERT trigger deriving
-- office_id the way 20260721090000 §8 does for trips/bookings/payments/reviews — is
-- deliberately NOT taken. transport_subscriptions holds no link to the booking, so
-- the only chain available to a trigger is package_id → transport_packages.office_id,
-- and that chain is not the authority: a package's office and the office running the
-- trip the package was sold against are different columns that can disagree (in this
-- database today, every transport_packages row still sits on the incumbent office
-- while trips and bookings sit on real ones). Deriving from the package would file
-- the ride ledger under an office that did not sell it, and office-scoped RLS would
-- then hide it from the office that did.
--
-- The booking is the authority — it is the only row that knows which office took the
-- money — so office_id stays an explicit argument at each call site below. NOT NULL
-- remains the backstop, and it is a good one: it failed loudly here rather than
-- letting a misattributed subscription through, which is exactly the trade wanted.

-- ── 2. approve_payment attributes the ride ledger ───────────────────────────────────
-- Identical to 20260731100000's definition except for the transport_subscriptions
-- INSERT, which now supplies office_id. Grants are deliberately not restated: a
-- `create or replace` keeps the existing ACL, and changing who may call this is a
-- separate decision from fixing what it writes.

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
      office_id, client_id, package_id, total_rides, remaining_rides, starts_at,
      expires_at, status
    ) values (
      v_booking.office_id, v_booking.client_id, v_package.id, v_package.ride_count,
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

-- ── 3. The card path writes the same complete subscription ──────────────────────────
-- Identical to 20260720090000's definition except for the two subscription INSERTs,
-- which now carry office_id and the route/trip/booking links. Everything else —
-- idempotency, the amount check, the guarded manifest insert — is unchanged.

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
  v_route_id uuid;
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
  -- operator-approved path (see approve_payment) — same columns, same office
  -- attribution, same links back to the route/trip/booking it was sold on.
  select * into v_package
  from public.transport_packages where id = v_booking.package_id;

  if v_package.ride_count > 1 then
    insert into public.transport_subscriptions (
      office_id, client_id, package_id, total_rides, remaining_rides, starts_at,
      expires_at, status
    ) values (
      v_booking.office_id, v_booking.client_id, v_package.id, v_package.ride_count,
      v_package.ride_count - 1, v_booking.plan_start_date,
      v_booking.plan_end_date, 'active'
    ) returning id into v_subscription_id;

    select route_id into v_route_id
      from public.operation_trips where id = v_booking.trip_id;

    -- Mirror into the table the dashboard/finance/reports/client all read.
    -- Prices come from what was actually charged, never a re-derived catalog
    -- price, so this can never diverge from operation_bookings.
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

comment on function public.approve_payment(uuid, text) is
  'Operator payment approval. Writes an office-attributed ride ledger row and '
  'subscription mirror for multi-ride packages, confirms the booking, settles the '
  'seat and manifests the passenger.';
