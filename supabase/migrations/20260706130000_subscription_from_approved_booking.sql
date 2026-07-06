-- migration_20260706130000_subscription_from_approved_booking.sql
--
-- Make an approved *package* booking appear in the Subscriptions tab.
--
-- Problem
-- -------
-- The booking flow and the subscriptions module were built on two parallel
-- tables that never met:
--   * approve_payment() writes the granted rides into public.transport_subscriptions
--     (linked from operation_bookings.subscription_id) — but NOTHING in any app
--     reads that table; it is write-only.
--   * The Subscriptions tab (dashboard list/details, finance, reports, and the
--     client seat-release view) reads exclusively from public.subscriptions.
-- Result: a client who books a trip with a multi-ride package and gets the
-- payment approved is never shown as a subscriber, and their trip/route data
-- never reaches the subscriptions tab.
--
-- Fix
-- ---
-- When a package booking with ride_count > 1 is approved, ALSO insert a
-- public.subscriptions row carrying all the data the tab renders: customer,
-- package title, route, plan window, price, and the ride balance (the booked
-- trip counts as the first used ride, mirroring transport_subscriptions'
-- remaining_rides = ride_count - 1).
--
-- Single-ride packages (Just Go, ride_count = 1) are intentionally NOT mirrored:
-- a one-way trip is not a subscription and would show a 0-remaining balance.
-- This matches the existing transport_subscriptions boundary (ride_count > 1).
--
-- transport_packages (the booking flow's catalogue) is a different table from
-- packages (the subscriptions module's catalogue), so subscriptions.package_id
-- (FK -> packages) is left NULL here; the package title is stored in
-- package_name, which is what the tab actually displays.
--
-- Everything else in approve_payment is identical to
-- 20260706120000_dashboard_approve_auth.sql.

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
    -- package, route, plan window, price and ride balance.
    insert into public.subscriptions (
      client_id, customer_name, customer_phone, package_name, route_name,
      start_date, end_date, status, total_price, paid_amount, remaining_amount,
      trips_count, trips_used, payment_method, payment_review_status
    ) values (
      v_booking.client_id, v_booking.passenger_name, v_booking.phone,
      coalesce(nullif(trim(v_package.name_ar), ''), v_package.name_en, 'باقة'),
      v_booking.route,
      v_booking.plan_start_date, v_booking.plan_end_date, 'active',
      v_package.price, v_package.price, 0,
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

-- One-time backfill: surface package bookings that were already approved before
-- this migration. Only multi-ride packages, and only when an equivalent
-- subscription row does not already exist (dedup on client + package + start).
insert into public.subscriptions (
  client_id, customer_name, customer_phone, package_name, route_name,
  start_date, end_date, status, total_price, paid_amount, remaining_amount,
  trips_count, trips_used, payment_method, payment_review_status
)
select
  b.client_id, b.passenger_name, b.phone,
  coalesce(nullif(trim(p.name_ar), ''), p.name_en, 'باقة'), b.route,
  b.plan_start_date, b.plan_end_date,
  case when b.plan_end_date < current_date then 'expired' else 'active' end,
  p.price, p.price, 0,
  p.ride_count, 1, b.payment_method, 'accepted'
from public.operation_bookings b
join public.transport_packages p on p.id = b.package_id
where b.status = 'confirmed'
  and p.ride_count > 1
  and b.plan_start_date is not null
  and b.plan_end_date is not null
  and not exists (
    select 1 from public.subscriptions s
    where s.client_id = b.client_id
      and s.package_name = coalesce(nullif(trim(p.name_ar), ''), p.name_en, 'باقة')
      and s.start_date = b.plan_start_date
  );
