-- =====================================================================================
-- EWT multi-office — office-aware RPCs
-- -------------------------------------------------------------------------------------
-- The existing RPCs are SECURITY DEFINER, so RLS does not constrain them: an operator
-- of office A could call approve_payment on office B's booking and it would succeed.
-- Closing that is the job of this migration.
--
-- Approach: rather than retyping several hundred lines of working booking, seat and
-- payment logic — and risking a transcription bug in the most business-critical code in
-- the system — each sensitive RPC gains a thin `office_*` guard wrapper that asserts
-- ownership and then delegates. Direct EXECUTE on the originals is then revoked from
-- `authenticated`, so the wrapper is the only door. The originals keep working
-- unchanged for service_role and for the wrappers (which run as owner).
--
-- Only the RPCs whose CONTRACT changes are rewritten in full: reviews (new office
-- rating), captain requests (must name an office), operational alerts (must be routed),
-- and the dashboard user directory (must be scoped).
-- =====================================================================================

-- ── 1. Ownership assertions ─────────────────────────────────────────────────────────

create or replace function public.assert_office_owns_booking(p_booking_id uuid)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office uuid;
  v_caller uuid := public.current_office_id();
begin
  if v_caller is null then
    raise exception 'not_an_office_user';
  end if;

  select office_id into v_office
    from public.operation_bookings where id = p_booking_id;

  if v_office is null then
    raise exception 'booking_not_found';
  end if;
  if v_office <> v_caller then
    raise exception 'cross_office_denied';
  end if;

  return v_office;
end;
$$;

create or replace function public.assert_office_owns_trip(p_trip_id uuid)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office uuid;
  v_caller uuid := public.current_office_id();
begin
  if v_caller is null then
    raise exception 'not_an_office_user';
  end if;

  select office_id into v_office
    from public.operation_trips where id = p_trip_id;

  if v_office is null then
    raise exception 'trip_not_found';
  end if;
  if v_office <> v_caller then
    raise exception 'cross_office_denied';
  end if;

  return v_office;
end;
$$;

create or replace function public.assert_office_owns_subscription(p_subscription_id uuid)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office uuid;
  v_caller uuid := public.current_office_id();
begin
  if v_caller is null then
    raise exception 'not_an_office_user';
  end if;

  select office_id into v_office
    from public.subscriptions where id = p_subscription_id;

  if v_office is null then
    raise exception 'subscription_not_found';
  end if;
  if v_office <> v_caller then
    raise exception 'cross_office_denied';
  end if;

  return v_office;
end;
$$;

-- ── 2. Payment + booking review wrappers ────────────────────────────────────────────

create or replace function public.office_approve_payment(
  p_booking_id uuid,
  p_note text default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  perform public.assert_office_owns_booking(p_booking_id);
  return public.approve_payment(p_booking_id, p_note);
end;
$$;

create or replace function public.office_reject_payment(
  p_booking_id uuid,
  p_reason text default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  perform public.assert_office_owns_booking(p_booking_id);
  return public.reject_payment(p_booking_id, p_reason);
end;
$$;

create or replace function public.office_request_payment_review(
  p_booking_id uuid,
  p_note text default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  perform public.assert_office_owns_booking(p_booking_id);
  return public.request_payment_review(p_booking_id, p_note);
end;
$$;

create or replace function public.office_approve_booking(
  p_booking_id uuid,
  p_reviewer_name text default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  perform public.assert_office_owns_booking(p_booking_id);
  return public.approve_booking(p_booking_id, p_reviewer_name);
end;
$$;

create or replace function public.office_reject_booking(
  p_booking_id uuid,
  p_rejection_reason text default null,
  p_reviewer_name text default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  perform public.assert_office_owns_booking(p_booking_id);
  return public.reject_booking(p_booking_id, p_rejection_reason, p_reviewer_name);
end;
$$;

-- Reassignment was a cross-office move vector: the target trip list was unfiltered, so
-- a booking could be walked from one office to another. Both ends are checked here.
create or replace function public.office_reassign_booking(
  p_booking_id uuid,
  p_new_trip_id uuid,
  p_new_seat_label text default null
) returns json
language plpgsql security definer set search_path = public as $$
declare
  v_from uuid;
  v_to   uuid;
begin
  v_from := public.assert_office_owns_booking(p_booking_id);
  v_to   := public.assert_office_owns_trip(p_new_trip_id);

  if v_from <> v_to then
    raise exception 'cross_office_reassignment_denied';
  end if;

  return public.reassign_booking(p_booking_id, p_new_trip_id, p_new_seat_label);
end;
$$;

-- ── 3. Trip creation and status ─────────────────────────────────────────────────────
-- Every referenced entity must belong to the caller's office, and the trip code is now
-- generated server-side: the Dashboard used to mint 'TR-<millis>' client-side, which
-- collides across offices.

create or replace function public.next_office_trip_code(p_office_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seq int;
begin
  select coalesce(max(nullif(regexp_replace(trip_code, '\D', '', 'g'), '')::bigint), 0) + 1
    into v_seq
    from public.operation_trips
   where office_id = p_office_id;

  return 'TR-' || lpad(v_seq::text, 5, '0');
end;
$$;

create or replace function public.office_create_trip(
  p_route_id       uuid,
  p_driver_id      uuid,
  p_vehicle_id     uuid,
  p_trip_date      date,
  p_departure_time time,
  p_arrival_time   time,
  p_capacity       int,
  p_ticket_price   numeric,
  p_currency       text,
  p_notes          text[],
  p_route_points   jsonb,
  p_seats          jsonb,
  p_trip_code      text default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_office uuid := public.current_office_id();
  v_code   text;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;

  -- Every referenced entity must be ours. Without this an operator could schedule a
  -- trip onto another office's route, driver or vehicle.
  if not exists (select 1 from public.operation_routes
                  where id = p_route_id and office_id = v_office) then
    raise exception 'route_not_in_office';
  end if;

  if p_driver_id is not null
     and not exists (select 1 from public.drivers
                      where id = p_driver_id and office_id = v_office) then
    raise exception 'driver_not_in_office';
  end if;

  if p_vehicle_id is not null
     and not exists (select 1 from public.vehicles
                      where id = p_vehicle_id and office_id = v_office) then
    raise exception 'vehicle_not_in_office';
  end if;

  v_code := coalesce(nullif(trim(coalesce(p_trip_code, '')), ''),
                     public.next_office_trip_code(v_office));

  return public.create_trip(
    v_code, p_route_id, p_driver_id, p_vehicle_id, p_trip_date, p_departure_time,
    p_arrival_time, p_capacity, p_ticket_price, p_currency, p_notes,
    p_route_points, p_seats
  );
end;
$$;

-- update_trip_status was SECURITY DEFINER with no caller check at all — any
-- authenticated user could drive any trip's state machine. Now the caller must either
-- operate the trip's office or be the captain assigned to it.
create or replace function public.office_update_trip_status(
  p_trip_id uuid,
  p_new_status text
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_office uuid;
  v_driver uuid;
begin
  select office_id, driver_id into v_office, v_driver
    from public.operation_trips where id = p_trip_id;

  if v_office is null then
    raise exception 'trip_not_found';
  end if;

  if v_office = public.current_office_id() then
    null;                                        -- operator of the owning office
  elsif v_driver is not null and v_driver = public.current_driver_id()
        and v_office = public.captain_office_id() then
    null;                                        -- the captain actually driving it
  else
    raise exception 'not_authorized';
  end if;

  return public.update_trip_status(p_trip_id, p_new_status);
end;
$$;

-- ── 4. Subscriptions ────────────────────────────────────────────────────────────────

create or replace function public.office_confirm_subscription_payment(p_subscription_id uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  perform public.assert_office_owns_subscription(p_subscription_id);
  return public.confirm_subscription_payment(p_subscription_id);
end;
$$;

create or replace function public.office_request_subscription_renewal(p_subscription_id uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  perform public.assert_office_owns_subscription(p_subscription_id);
  return public.request_subscription_renewal(p_subscription_id);
end;
$$;

create or replace function public.office_consume_subscription_ride(p_subscription_id uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  perform public.assert_office_owns_subscription(p_subscription_id);
  return public.consume_subscription_ride(p_subscription_id);
end;
$$;

-- The Dashboard called expire_overdue_subscriptions() on every Subscriptions screen
-- load, which expired EVERY office's overdue rows. Scope it to the caller.
create or replace function public.office_expire_overdue_subscriptions()
returns int
language plpgsql security definer set search_path = public as $$
declare
  v_office uuid := public.current_office_id();
  v_count  int;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;

  update public.subscriptions
     set status = 'expired', updated_at = now()
   where office_id = v_office
     and status = 'active'
     and end_date is not null
     and end_date < current_date;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- ── 5. Reviews — the office is rated explicitly ─────────────────────────────────────
-- Per the product decision: an office rating is NOT inferred from driver/vehicle
-- averages. It is its own dimension. The office is resolved from the booking's trip,
-- never accepted as a parameter, so a client cannot aim a review at an arbitrary office.

alter table public.trip_reviews
  add column if not exists office_rating int;

update public.trip_reviews
   set office_rating = greatest(1, least(5,
         round((coalesce(driver_rating, 3) + coalesce(vehicle_rating, 3)
                + coalesce(route_rating, 3)) / 3.0)::int))
 where office_rating is null;

alter table public.trip_reviews
  alter column office_rating set not null;
alter table public.trip_reviews
  drop constraint if exists trip_reviews_office_rating_check;
alter table public.trip_reviews
  add constraint trip_reviews_office_rating_check
  check (office_rating between 1 and 5);

create index if not exists idx_trip_reviews_office_created
  on public.trip_reviews (office_id, created_at desc);

create or replace function public.refresh_office_rating(p_office uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_office is null then return; end if;

  update public.offices o
     set rating = coalesce(agg.avg_rating, 0),
         ratings_count = coalesce(agg.n, 0),
         updated_at = now()
    from (
      select round(avg(office_rating)::numeric, 2) as avg_rating, count(*) as n
        from public.trip_reviews
       where office_id = p_office
    ) agg
   where o.id = p_office;
end;
$$;

create or replace function public.refresh_office_rating_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.refresh_office_rating(old.office_id);
    return old;
  end if;
  perform public.refresh_office_rating(new.office_id);
  if tg_op = 'UPDATE' and old.office_id is distinct from new.office_id then
    perform public.refresh_office_rating(old.office_id);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_trip_reviews_office_rating on public.trip_reviews;
create trigger trg_trip_reviews_office_rating
  after insert or update or delete on public.trip_reviews
  for each row execute function public.refresh_office_rating_trigger();

-- New five-argument signature. The old four-rating form is dropped so no caller can
-- silently keep submitting reviews without an office score.
drop function if exists public.submit_trip_review(uuid, int, int, int, text);

create or replace function public.submit_trip_review(
  p_booking_id     uuid,
  p_office_rating  int,
  p_driver_rating  int,
  p_vehicle_rating int,
  p_route_rating   int,
  p_comment        text default ''
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_b   record;
  v_id  uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  if p_office_rating  not between 1 and 5
  or p_driver_rating  not between 1 and 5
  or p_vehicle_rating not between 1 and 5
  or p_route_rating   not between 1 and 5 then
    raise exception 'invalid_rating';
  end if;

  select b.id, b.client_id, b.trip_id, b.office_id,
         b.status                        as booking_status,
         coalesce(b.booking_number, '')  as booking_number,
         t.status                        as trip_status,
         t.driver_id, t.vehicle_id, t.route_id,
         coalesce(c.full_name, '')       as client_name,
         coalesce(d.full_name, '')       as driver_name,
         trim(coalesce(v.brand, '') || ' ' || coalesce(v.model, '')) as vehicle_name,
         coalesce(
           nullif(r.name, ''),
           nullif(trim(coalesce(r.start_city, '') || ' → ' ||
                       coalesce(r.end_city, '')), '→'),
           coalesce(b.route, '')
         )                               as route_label
    into v_b
    from public.operation_bookings b
    left join public.operation_trips   t on t.id = b.trip_id
    left join public.clients           c on c.id = b.client_id
    left join public.drivers           d on d.id = t.driver_id
    left join public.vehicles          v on v.id = t.vehicle_id
    left join public.operation_routes  r on r.id = t.route_id
   where b.id = p_booking_id;

  if v_b.id is null then
    raise exception 'booking_not_found';
  end if;

  -- A passenger reviews their own trip. Nobody reviews on their behalf.
  if v_b.client_id is distinct from v_uid then
    raise exception 'not_authorized';
  end if;

  if v_b.trip_status is distinct from 'completed' then
    raise exception 'trip_not_completed';
  end if;

  insert into public.trip_reviews (
    booking_id, client_id, trip_id, driver_id, vehicle_id, route_id, office_id,
    office_rating, driver_rating, vehicle_rating, route_rating, comment,
    booking_number, client_name, driver_name, vehicle_name, route_label
  ) values (
    v_b.id, v_b.client_id, v_b.trip_id, v_b.driver_id, v_b.vehicle_id, v_b.route_id,
    v_b.office_id,                       -- derived, never accepted from the caller
    p_office_rating, p_driver_rating, p_vehicle_rating, p_route_rating,
    coalesce(p_comment, ''),
    v_b.booking_number, v_b.client_name, v_b.driver_name, v_b.vehicle_name,
    v_b.route_label
  )
  on conflict (booking_id) do nothing
  returning id into v_id;

  if v_id is null then
    raise exception 'already_reviewed';
  end if;

  return v_id;
end;
$$;

revoke all on function public.submit_trip_review(uuid, int, int, int, int, text)
  from public;
grant execute on function public.submit_trip_review(uuid, int, int, int, int, text)
  to authenticated;

-- Backfill office ratings from the reviews that already exist.
do $$
declare
  o record;
begin
  for o in select distinct office_id from public.trip_reviews where office_id is not null
  loop
    perform public.refresh_office_rating(o.office_id);
  end loop;
end $$;

-- ── 6. Captain requests now name an office ──────────────────────────────────────────
-- A prospective captain applies TO a specific office; the Dashboard queue is scoped to
-- that office. The Captain app gains an office picker (it reads public_offices).

create or replace function public.submit_captain_request(
  p_full_name text,
  p_phone     text,
  p_office_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone_norm text := public.normalize_egyptian_phone(coalesce(p_phone, ''));
  v_name       text := trim(coalesce(p_full_name, ''));
  v_office     uuid := p_office_id;
  v_existing   public.captain_requests;
  v_id         uuid;
begin
  if length(v_phone_norm) < 10 then
    raise exception 'رقم الهاتف غير صالح' using errcode = '22023';
  end if;
  if length(v_name) < 2 then
    raise exception 'الاسم غير صالح' using errcode = '22023';
  end if;

  -- Single-office deployments (and older app builds that do not send an office yet)
  -- fall back to the only active office. With more than one active office the caller
  -- must choose, otherwise the request would land in an arbitrary queue.
  if v_office is null then
    select o.id into v_office
      from public.offices o
     where o.status = 'active'
       and (select count(*) from public.offices where status = 'active') = 1;

    if v_office is null then
      raise exception 'office_required';
    end if;
  end if;

  if not exists (select 1 from public.offices
                  where id = v_office and status = 'active') then
    raise exception 'office_inactive';
  end if;

  -- Already a driver somewhere? Then just sign in.
  if exists (
    select 1 from public.drivers d
     where public.normalize_egyptian_phone(d.phone) = v_phone_norm
       and d.status = 'active'
  ) then
    return jsonb_build_object('outcome', 'already_active');
  end if;

  select * into v_existing
    from public.captain_requests
   where phone_normalized = v_phone_norm and status = 'pending'
   limit 1;

  if found then
    return jsonb_build_object(
      'outcome', 'pending', 'request_id', v_existing.id, 'phone', v_existing.phone);
  end if;

  insert into public.captain_requests
    (full_name, phone, phone_normalized, office_id, status)
  values (v_name, p_phone, v_phone_norm, v_office, 'pending')
  returning id into v_id;

  return jsonb_build_object('outcome', 'submitted', 'request_id', v_id,
                            'phone', p_phone);
end;
$$;

revoke all on function public.submit_captain_request(text, text, uuid) from public;
grant execute on function public.submit_captain_request(text, text, uuid)
  to anon, authenticated;
drop function if exists public.submit_captain_request(text, text);

-- ── 7. Operational alerts are routed to the owning office ──────────────────────────
-- Every existing trigger already passes a trip/booking/driver id in p_data, so the
-- office is derived from that and no trigger has to change. An alert that cannot be
-- attributed is dropped rather than raised: a missing notification must never abort
-- the business transaction that produced it.

-- The previous six-argument version MUST go. Every emitting trigger calls this with six
-- arguments or fewer, and Postgres prefers an exact-arity match over one satisfied by a
-- default — so leaving it in place would keep routing alerts through the old body,
-- inserting a NULL office_id and failing the NOT NULL check inside whatever booking or
-- trip transaction happened to fire it.
drop function if exists public.push_operational_alert(
  text, text, text, jsonb, text, text);

create or replace function public.push_operational_alert(
  p_type       text,
  p_title      text,
  p_body       text,
  p_data       jsonb default '{}'::jsonb,
  p_priority   text  default 'normal',
  p_action_url text  default null,
  p_office_id  uuid  default null
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_data   jsonb := coalesce(p_data, '{}'::jsonb);
  v_office uuid  := p_office_id;
begin
  if v_office is null and (v_data ? 'trip_id') then
    select office_id into v_office from public.operation_trips
     where id = (v_data ->> 'trip_id')::uuid;
  end if;

  if v_office is null and (v_data ? 'booking_id') then
    select office_id into v_office from public.operation_bookings
     where id = (v_data ->> 'booking_id')::uuid;
  end if;

  if v_office is null and (v_data ? 'driver_id') then
    select office_id into v_office from public.drivers
     where id = (v_data ->> 'driver_id')::uuid;
  end if;

  if v_office is null and (v_data ? 'request_id') then
    select office_id into v_office from public.captain_requests
     where id = (v_data ->> 'request_id')::uuid;
  end if;

  if v_office is null and (v_data ? 'subscription_id') then
    select office_id into v_office from public.subscriptions
     where id = (v_data ->> 'subscription_id')::uuid;
  end if;

  if v_office is null then
    return;   -- unattributable: better a lost alert than a failed booking
  end if;

  insert into public.operational_alerts
    (type, title, body, data, priority, action_url, office_id)
  values
    (p_type, p_title, p_body, v_data, p_priority, p_action_url, v_office);
end;
$$;

revoke all on function public.push_operational_alert(
  text, text, text, jsonb, text, text, uuid) from public;

-- ── 8. Office-scoped dashboard user directory ──────────────────────────────────────

drop function if exists public.get_dashboard_users();

create or replace function public.get_dashboard_users()
returns table(
  id         uuid,
  user_id    uuid,
  username   text,
  full_name  text,
  email      text,
  role       text,
  status     text,
  created_at timestamptz
)
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;

  return query
    select ou.id, ou.user_id, ou.username, ou.full_name, au.email,
           ou.role, ou.status, ou.created_at
      from public.office_users ou
      join auth.users au on au.id = ou.user_id
     where ou.office_id = v_office
     order by ou.created_at desc;
end;
$$;

grant execute on function public.get_dashboard_users() to authenticated;

-- ── 9. Payment configuration resolver (backend only) ───────────────────────────────
-- The Client app used to send integration_id / iframe_id in the checkout payload. It no
-- longer knows them: the Edge Function resolves the merchant config from the booking's
-- office with the service-role key. EXECUTE is granted to nobody — service_role
-- bypasses privilege checks, which is precisely the only caller we want.

create or replace function public.resolve_booking_payment_config(p_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_office uuid;
  v_cfg    public.office_payment_configs;
  v_office_name text;
begin
  select b.office_id, o.name into v_office, v_office_name
    from public.operation_bookings b
    join public.offices o on o.id = b.office_id
   where b.id = p_booking_id;

  if v_office is null then
    raise exception 'booking_not_found';
  end if;

  select * into v_cfg
    from public.office_payment_configs
   where office_id = v_office and provider = 'paymob' and is_active
   limit 1;

  return jsonb_build_object(
    'office_id',      v_office,
    'office_name',    v_office_name,
    'integration_id', v_cfg.integration_id,
    'iframe_id',      v_cfg.iframe_id,
    'api_key',        v_cfg.api_key,
    'configured',     v_cfg.id is not null
  );
end;
$$;

revoke all on function public.resolve_booking_payment_config(uuid)
  from public, anon, authenticated;

-- ── 10. Lock the originals behind their wrappers ───────────────────────────────────

-- Postgres grants EXECUTE to PUBLIC on every new function by default, so revoking from
-- `authenticated` alone would leave the raw, unscoped function wide open. PUBLIC has to
-- go first — this is the difference between a closed door and one that only looks shut.
do $$
declare
  f text;
begin
  foreach f in array array[
    'public.approve_payment(uuid, text)',
    'public.reject_payment(uuid, text)',
    'public.request_payment_review(uuid, text)',
    'public.approve_booking(uuid, text)',
    'public.reject_booking(uuid, text, text)',
    'public.reassign_booking(uuid, uuid, text)',
    'public.update_trip_status(uuid, text)',
    'public.confirm_subscription_payment(uuid)',
    'public.request_subscription_renewal(uuid)',
    'public.consume_subscription_ride(uuid)',
    'public.expire_overdue_subscriptions()',
    'public.create_trip(text, uuid, uuid, uuid, date, time, time, int, numeric, '
      || 'text, text[], jsonb, jsonb)',
    'public.link_paymob_order(uuid, text)'
  ]
  loop
    begin
      execute format('revoke all on function %s from public, anon, authenticated', f);
    exception when undefined_function then
      raise notice 'skipping revoke for missing function %', f;
    end;
  end loop;
end $$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'public.office_approve_payment(uuid, text)',
    'public.office_reject_payment(uuid, text)',
    'public.office_request_payment_review(uuid, text)',
    'public.office_approve_booking(uuid, text)',
    'public.office_reject_booking(uuid, text, text)',
    'public.office_reassign_booking(uuid, uuid, text)',
    'public.office_update_trip_status(uuid, text)',
    'public.office_confirm_subscription_payment(uuid)',
    'public.office_request_subscription_renewal(uuid)',
    'public.office_consume_subscription_ride(uuid)',
    'public.office_expire_overdue_subscriptions()',
    'public.office_create_trip(uuid, uuid, uuid, date, time, time, int, numeric, '
      || 'text, text[], jsonb, jsonb, text)',
    'public.current_office_id()',
    'public.captain_office_id()',
    'public.current_driver_id()',
    'public.office_role()',
    'public.office_is_active(uuid)'
  ]
  loop
    execute format('revoke all on function %s from public', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

comment on function public.office_approve_payment(uuid, text) is
  'Office-scoped door to approve_payment. The raw function is no longer callable by '
  'authenticated users — it had no ownership check.';
