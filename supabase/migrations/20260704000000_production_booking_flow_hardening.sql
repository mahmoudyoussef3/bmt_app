-- Production booking-flow hardening.
-- This migration intentionally builds on 20260703020000_saas_booking_flow.sql.

-- Package types are data, not a release-time enum. This allows administrators
-- to introduce a new package without shipping a database or app migration.
alter table public.transport_packages
  alter column package_type type text using package_type::text;

drop type if exists public.transport_package_type;

alter table public.transport_packages enable row level security;

drop policy if exists "Clients read active transport packages"
  on public.transport_packages;
create policy "Clients read active transport packages"
  on public.transport_packages for select
  using (active = true or public.is_admin());

drop policy if exists "Dashboard manages transport packages"
  on public.transport_packages;
create policy "Dashboard manages transport packages"
  on public.transport_packages for all
  using (public.is_admin())
  with check (public.is_admin());

drop trigger if exists set_transport_packages_updated_at
  on public.transport_packages;
create trigger set_transport_packages_updated_at
before update on public.transport_packages
for each row execute function public.update_updated_at_column();

alter table public.transport_subscriptions enable row level security;

drop policy if exists "Clients read own transport subscriptions"
  on public.transport_subscriptions;
create policy "Clients read own transport subscriptions"
  on public.transport_subscriptions for select
  using (client_id = auth.uid());

drop policy if exists "Dashboard manages transport subscriptions"
  on public.transport_subscriptions;
create policy "Dashboard manages transport subscriptions"
  on public.transport_subscriptions for all
  using (public.is_admin())
  with check (public.is_admin());

alter table public.operation_bookings
  add column if not exists pickup_point_name text,
  add column if not exists dropoff_point_name text;

alter table public.operation_bookings
  drop constraint if exists operation_bookings_payment_review_status_check;
alter table public.operation_bookings
  add constraint operation_bookings_payment_review_status_check
  check (payment_review_status in ('pending', 'under_review', 'reviewed'));

alter table public.trip_passengers
  add column if not exists booking_id uuid
    references public.operation_bookings(id) on delete restrict;

create unique index if not exists uniq_trip_passenger_booking
  on public.trip_passengers (booking_id)
  where booking_id is not null;

create unique index if not exists uniq_active_client_trip_booking
  on public.operation_bookings (client_id, trip_id)
  where status in ('pending', 'approved');

create table if not exists public.booking_payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique
    references public.operation_bookings(id) on delete restrict,
  client_id uuid not null references public.clients(id) on delete restrict,
  method text not null check (
    method in ('credit_card', 'instapay', 'vodafone_cash', 'bank_transfer')
  ),
  amount numeric(12, 2) not null check (amount > 0),
  currency text not null default 'EGP',
  status text not null default 'submitted' check (
    status in (
      'pending', 'submitted', 'under_review', 'approved', 'rejected', 'refunded'
    )
  ),
  receipt_url text,
  payment_reference text,
  payer_phone text,
  rejection_reason text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  submitted_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.booking_payments
  drop constraint if exists booking_payments_method_check;
alter table public.booking_payments
  add constraint booking_payments_method_check check (
    method in ('credit_card', 'instapay', 'vodafone_cash', 'bank_transfer')
  );
alter table public.booking_payments
  alter column receipt_url drop not null;

create index if not exists idx_booking_payments_review_queue
  on public.booking_payments (status, submitted_at desc);

alter table public.booking_payments enable row level security;

drop policy if exists "Clients read own booking payments"
  on public.booking_payments;
create policy "Clients read own booking payments"
  on public.booking_payments for select
  using (client_id = auth.uid());

drop policy if exists "Dashboard manages booking payments"
  on public.booking_payments;
create policy "Dashboard manages booking payments"
  on public.booking_payments for all
  using (public.is_admin())
  with check (public.is_admin());

-- A submitted receipt creates the booking, payment and durable seat hold in one
-- transaction. The row lock plus partial unique indexes are the race-condition
-- boundary; all business values are re-read from the database.
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
  p_payer_phone        text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking_id uuid;
  v_booking_number text;
  v_trip public.operation_trips%rowtype;
  v_seat public.trip_seats%rowtype;
  v_package public.transport_packages%rowtype;
begin
  if auth.uid() is null or auth.uid() <> p_client_id then
    raise exception 'not_authorized';
  end if;
  if p_payment_method not in (
    'credit_card', 'instapay', 'vodafone_cash', 'bank_transfer'
  ) then
    raise exception 'payment_method_not_allowed';
  end if;
  if p_payment_method <> 'credit_card'
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

  select * into v_package
  from public.transport_packages
  where id = p_package_id and active = true;

  if not found then
    raise exception 'package_not_available';
  end if;

  if exists (
    select 1 from public.operation_bookings
    where client_id = p_client_id
      and trip_id = p_trip_id
      and status in ('pending', 'approved')
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
    plan_start_date, plan_end_date, payment_status, payment_review_status
  ) values (
    p_client_id, p_trip_id, trim(p_passenger_name), trim(p_phone), p_route,
    p_trip_time, coalesce(p_trip_date, v_trip.trip_date), p_seat_label,
    p_payment_method, v_package.price, p_seat_id, p_pricing_id,
    p_pickup_point_id, p_dropoff_point_id, p_pickup_point_name,
    p_dropoff_point_name, 'pending', v_booking_number, p_receipt_url, 'client',
    p_package_id, coalesce(p_plan_start_date, v_trip.trip_date),
    coalesce(p_plan_start_date, v_trip.trip_date)
      + greatest(v_package.duration_days - 1, 0),
    case when p_payment_method = 'credit_card' then 'pending'
         else 'submitted' end,
    'pending'
  ) returning id into v_booking_id;

  insert into public.booking_payments (
    booking_id, client_id, method, amount, status, receipt_url,
    payment_reference, payer_phone
  ) values (
    v_booking_id, p_client_id, p_payment_method, v_package.price,
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

  return jsonb_build_object(
    'success', true,
    'booking_id', v_booking_id,
    'booking_number', v_booking_number,
    'trip_id', p_trip_id,
    'seat_label', p_seat_label,
    'payment_amount', v_package.price,
    'status', 'pending'
  );
exception
  when unique_violation then
    raise exception 'seat_or_booking_already_exists';
end;
$$;

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
  if not public.is_admin() then
    raise exception 'not_authorized';
  end if;

  select * into v_booking
  from public.operation_bookings
  where id = p_booking_id
  for update;

  if not found then raise exception 'booking_not_found'; end if;
  if v_booking.status <> 'pending' then raise exception 'booking_not_pending'; end if;

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
  set status = 'approved',
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
    'success', true, 'booking_id', p_booking_id, 'status', 'approved'
  );
end;
$$;

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
  if not public.is_admin() then
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
  if v_booking.status <> 'pending' then raise exception 'booking_not_pending'; end if;

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
  if not public.is_admin() then
    raise exception 'not_authorized';
  end if;
  select * into v_booking
  from public.operation_bookings
  where id = p_booking_id and status = 'pending'
  for update;
  if not found then raise exception 'booking_not_pending'; end if;

  update public.operation_bookings
  set payment_status = 'under_review',
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

-- Only unpaid pre-submission holds expire. Submitted receipts remain held until
-- a dashboard reviewer makes an explicit decision.
drop function if exists public.release_expired_seat_holds();


create or replace function public.release_expired_seat_holds()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_released integer;
begin
  with expired as (
    select b.id, b.seat_id, b.client_id
    from public.operation_bookings b
    join public.trip_seats s on s.id = b.seat_id
    left join public.booking_payments p on p.booking_id = b.id
    where b.status = 'pending'
      and s.hold_expires_at <= now()
      and coalesce(p.status, 'pending') = 'pending'
    for update of b, s skip locked
  ),
  cancelled as (
    update public.operation_bookings b
    set status = 'cancelled',
        payment_status = 'rejected',
        payment_rejection_reason = 'انتهت مهلة حجز المقعد',
        updated_at = now()
    from expired e
    where b.id = e.id
    returning e.id, e.seat_id, e.client_id
  ),
  released as (
    update public.trip_seats s
    set state = 'available', passenger_id = null, lock_expires_at = null,
        held_at = null, hold_expires_at = null
    from cancelled c
    where s.id = c.seat_id
    returning c.id, c.client_id
  )
  select count(*) into v_released from released;

  insert into public.notifications (
    user_id, title, body, type, category, target_app, data
  )
  select b.client_id, 'انتهت مهلة الحجز',
    'تم تحرير المقعد لعدم إرسال إثبات الدفع في الوقت المحدد.',
    'seat_hold_expired', 'booking', 'client',
    jsonb_build_object('booking_id', b.id, 'trip_id', b.trip_id)
  from public.operation_bookings b
  where b.payment_rejection_reason = 'انتهت مهلة حجز المقعد'
    and b.updated_at >= now() - interval '1 minute';

  return v_released;
end;
$$;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid)
    from cron.job
    where jobname = 'release-expired-booking-seat-holds';

    perform cron.schedule(
      'release-expired-booking-seat-holds',
      '* * * * *',
      'select public.release_expired_seat_holds()'
    );
  end if;
end;
$$;

grant execute on function public.confirm_seat_booking_v2(
  uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, date, text,
  text, numeric, text, text, uuid, date, text, text, text
) to authenticated;
grant execute on function public.approve_payment(uuid, text) to authenticated;
grant execute on function public.reject_payment(uuid, text) to authenticated;
grant execute on function public.request_payment_review(uuid, text)
  to authenticated;
