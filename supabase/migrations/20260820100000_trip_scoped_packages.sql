-- Trip-scoped packages: an office defines the packages a *trip* sells, not
-- only the ones its catalog happens to hold.
--
-- Where this started: `20260815091000_per_package_trip_pricing.sql` gave every
-- one of an office's `transport_packages` its own real price per trip stop
-- pair, which fixed pricing but left the *menu* fixed — the trip planner could
-- only price the packages already in the office catalog, so an operator who
-- wanted "أسبوع الجامعة" on one Friday trip and nothing like it anywhere else
-- had to pollute the office-wide catalog to get it, and every other trip then
-- had to be priced for it too. The office owner asked for the opposite: each
-- trip carries whatever packages that trip actually sells, invented on the
-- spot if need be, each with its own price and an optional note, and the rider
-- booking that trip sees exactly that menu.
--
-- Two additions, no new tables:
--
--   1. `transport_packages.trip_id` — a package created *for one trip*. NULL
--      keeps today's meaning (an office catalog package, offered as a template
--      in the planner and browsable in the marketplace); non-NULL means the
--      package exists only to be sold on that trip and is hidden from every
--      catalog-browsing surface. Keeping trip packages in `transport_packages`
--      rather than a parallel table is deliberate: `operation_bookings.
--      package_id`, `transport_subscriptions.package_id` and
--      `trip_package_prices.package_id` all reference it, and
--      `confirm_seat_booking_v2` reads the package row to resolve the fare and
--      the plan window. A second package table would have to be threaded
--      through every one of those.
--
--   2. `trip_package_prices.note` — the operator's optional note for this
--      package on this trip ("يشمل الرجوع بعد المحاضرة"), shown to the rider
--      under the package in the booking wizard. It sits next to `price`, on the
--      same (stop pair, package) row, because that is the row the rider's
--      wizard already reads to quote the fare — the note arrives with the price
--      it belongs to, needing no extra query, embed, or RLS surface. The
--      planner writes the same note to every stop pair, exactly as it writes
--      the same price.

alter table public.transport_packages
  add column if not exists trip_id uuid
    references public.operation_trips(id) on delete cascade;

comment on column public.transport_packages.trip_id is
  'NULL = office catalog package (browsable, offered as a planner template). '
  'Non-NULL = a package created for that one trip only; sold there and hidden '
  'from every catalog-browsing surface.';

create index if not exists idx_transport_packages_trip_id
  on public.transport_packages(trip_id)
  where trip_id is not null;

alter table public.trip_package_prices
  add column if not exists note text not null default '';

comment on column public.trip_package_prices.note is
  'The office''s optional note for this package on this trip, shown to the '
  'rider under the package in the booking wizard. Written uniformly across a '
  'trip''s stop pairs by the planner, same as price.';

-- A trip package must belong to the same office as its trip. Nothing else in
-- the schema pairs a package to a trip, and RLS on transport_packages only
-- checks `office_id = current_office_id()` — without this an office could
-- attach one of its own packages to another office's trip id and have it
-- render inside that office's booking flow. A cross-table rule cannot be a
-- CHECK, so it is a trigger; the same shape the fleet-authority migrations use.
create or replace function public.enforce_trip_package_office()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_trip_office uuid;
begin
  if new.trip_id is null then
    return new;
  end if;

  select office_id into v_trip_office
  from public.operation_trips
  where id = new.trip_id;

  if v_trip_office is null then
    raise exception 'trip_not_found';
  end if;
  if v_trip_office <> new.office_id then
    raise exception 'package_trip_office_mismatch';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_transport_packages_trip_office
  on public.transport_packages;
create trigger trg_transport_packages_trip_office
  before insert or update of trip_id, office_id on public.transport_packages
  for each row execute function public.enforce_trip_package_office();

-- confirm_seat_booking_v2: identical to
-- `20260815091000_per_package_trip_pricing.sql` except that the package lookup
-- now refuses a trip package booked against a different trip. Without it a
-- rider could pass any trip package's id into any trip and be charged that
-- package's flat `price` through the "no pricing row for this pair" fallback
-- below — a package that exists only on one trip must not resolve on another.
create or replace function public.confirm_seat_booking_v2(
  p_client_id uuid,
  p_trip_id uuid,
  p_seat_id uuid,
  p_pricing_id uuid,
  p_pickup_point_id uuid,
  p_dropoff_point_id uuid,
  p_passenger_name text,
  p_phone text,
  p_route text,
  p_trip_time text,
  p_trip_date date,
  p_seat_label text,
  p_payment_method text,
  p_payment_amount numeric,
  p_pickup_point_name text,
  p_dropoff_point_name text,
  p_package_id uuid,
  p_plan_start_date date,
  p_receipt_url text default null,
  p_payment_reference text default null,
  p_payer_phone text default null,
  p_subscription_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
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
    -- A trip package (trip_id set) is only sellable on its own trip; a
    -- catalog package (trip_id null) is sellable on any of the office's.
    select * into v_package
    from public.transport_packages
    where id = p_package_id
      and active = true
      and (trip_id is null or trip_id = p_trip_id);

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
    -- to_point_id), so it is always preferred when it exists for this pair.
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
$function$;
