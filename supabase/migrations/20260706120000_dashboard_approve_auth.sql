-- migration_20260706120000_dashboard_approve_auth.sql
--
-- The dashboard runs with NO login gate (single-owner operational workspace),
-- so it calls the review RPCs anonymously (auth.uid() IS NULL). The previous
-- guard `if not public.is_admin() then raise 'not_authorized'` therefore always
-- failed for the dashboard (is_admin() checks public.admins by auth.uid(), which
-- is NULL for anon), surfacing as the generic "تعذر قبول الدفع" error. The RPCs
-- were also only granted to `authenticated`, so anon had no EXECUTE privilege.
--
-- Fix: allow the anonymous dashboard through while still blocking authenticated
-- non-admin callers (e.g. a client-app user must NOT be able to self-approve
-- their own booking). New guard:
--   if auth.uid() is not null and not public.is_admin() then raise ... end if;
--     * anon dashboard (auth.uid() IS NULL)      -> allowed
--     * authenticated admin (in public.admins)   -> allowed
--     * authenticated non-admin client           -> blocked
-- and EXECUTE is granted to anon.
--
-- Only the authorization guard and grants change; all booking/payment logic is
-- identical to 20260706110000_fix_booking_status_vocabulary.sql.

-- 1) Payment approval ---------------------------------------------------------
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
    insert into public.transport_subscriptions (
      client_id, package_id, total_rides, remaining_rides, starts_at,
      expires_at, status
    ) values (
      v_booking.client_id, v_package.id, v_package.ride_count,
      v_package.ride_count - 1, v_booking.plan_start_date,
      v_booking.plan_end_date, 'active'
    ) returning id into v_subscription_id;
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

-- 2) Payment rejection --------------------------------------------------------
create or replace function public.reject_payment(
  p_booking_id uuid,
  p_reason text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.operation_bookings%rowtype;
begin
  if auth.uid() is not null and not public.is_admin() then
    raise exception 'not_authorized';
  end if;
  if nullif(trim(coalesce(p_reason, '')), '') is null then
    raise exception 'rejection_reason_required';
  end if;

  select * into v_booking
  from public.operation_bookings
  where id = p_booking_id
  for update;

  if not found then raise exception 'booking_not_found'; end if;
  if v_booking.status <> 'reserved' then raise exception 'booking_not_pending'; end if;

  update public.operation_bookings
  set status = 'cancelled',
      payment_status = 'rejected',
      payment_review_status = 'reviewed',
      payment_rejection_reason = trim(p_reason),
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      updated_at = now()
  where id = p_booking_id;

  update public.booking_payments
  set status = 'rejected',
      rejection_reason = trim(p_reason),
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      updated_at = now()
  where booking_id = p_booking_id;

  update public.trip_seats
  set state = 'available', passenger_id = null, lock_expires_at = null,
      held_at = null, hold_expires_at = null
  where id = v_booking.seat_id and passenger_id = v_booking.client_id;

  delete from public.trip_passengers where booking_id = p_booking_id;

  insert into public.notifications (
    user_id, title, body, type, category, target_app, data
  ) values (
    v_booking.client_id, 'تعذر اعتماد الدفع',
    'تم رفض إثبات الدفع: ' || trim(p_reason),
    'payment_rejected', 'payment', 'client',
    jsonb_build_object(
      'booking_id', p_booking_id, 'trip_id', v_booking.trip_id,
      'reason', trim(p_reason)
    )
  );

  return jsonb_build_object(
    'success', true, 'booking_id', p_booking_id, 'status', 'cancelled'
  );
end;
$$;

-- 3) Request payment re-review ------------------------------------------------
create or replace function public.request_payment_review(
  p_booking_id uuid,
  p_note text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.operation_bookings%rowtype;
begin
  if auth.uid() is not null and not public.is_admin() then
    raise exception 'not_authorized';
  end if;
  select * into v_booking
  from public.operation_bookings
  where id = p_booking_id and status = 'reserved'
  for update;
  if not found then raise exception 'booking_not_pending'; end if;

  update public.operation_bookings
  set payment_status = 'underReview',
      payment_review_status = 'under_review',
      notes = case
        when nullif(trim(coalesce(p_note, '')), '') is null then notes
        else jsonb_build_array(trim(p_note)) || coalesce(notes, '[]'::jsonb)
      end,
      updated_at = now()
  where id = p_booking_id;

  update public.booking_payments
  set status = 'under_review', updated_at = now()
  where booking_id = p_booking_id;

  insert into public.notifications (
    user_id, title, body, type, category, target_app, data
  ) values (
    v_booking.client_id, 'مطلوب مراجعة إثبات الدفع',
    coalesce(nullif(trim(p_note), ''), 'يرجى التواصل مع الدعم لمراجعة إثبات الدفع.'),
    'payment_review_requested', 'payment', 'client',
    jsonb_build_object('booking_id', p_booking_id, 'trip_id', v_booking.trip_id)
  );

  return jsonb_build_object(
    'success', true, 'booking_id', p_booking_id, 'status', 'under_review'
  );
end;
$$;

grant execute on function public.approve_payment(uuid, text) to anon, authenticated;
grant execute on function public.reject_payment(uuid, text) to anon, authenticated;
grant execute on function public.request_payment_review(uuid, text)
  to anon, authenticated;
