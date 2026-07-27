-- ═══════════════════════════════════════════════════════════════════════════════════
-- Trip lifecycle authority
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 3 of the Dashboard Re-Ownership Program. Full audit in
-- docs/architecture/TRIP_LIFECYCLE_DESIGN.md, run against the live database 2026-07-27.
--
-- The system already had a correct trip state machine (`update_trip_status`) and correct
-- authorisation wrappers around it, and no way to compel anyone to use them: RLS cannot
-- restrict columns, so `trips_office_manage` (ALL) and `trips_captain_update` (UPDATE)
-- let any operator — and any captain — write `status` directly through PostgREST,
-- skipping every transition rule, side effect and notification. The dashboard's own
-- `updateTripInfo` did exactly that.
--
-- This migration makes the machine authoritative and closes the gaps the audit found:
--
--   1. A BEFORE UPDATE trigger that permits a `status` change only from inside
--      `update_trip_status`, freezes planning columns once a trip has departed, and
--      forbids captains from writing the table directly at all.
--   2. A five-point readiness gate on publish (`scheduled -> open_for_booking`), so
--      `scheduled` becomes a real draft rather than a state anyone can leave for free.
--      No `draft` status is added — `scheduled` already *is* the draft; only the exit
--      was ungated. See §4.1 of the design.
--   3. Booking availability as a server-side rule instead of a Dart convention:
--      `lock_trip_seat` gains the trip guard it never had (it would lock a seat on a
--      cancelled trip), including the `trip_date >= today` check that until now existed
--      only in `BookableTrip` in the Flutter client.
--   4. Complete side effects: completion closes bookings and passengers; cancellation
--      cancels passengers (previously orphaned), clears seat holds, and notifies the
--      riders whose payment was still under review — who until now were silently
--      cancelled with no message at all.
--   5. `booked_seats` maintained from `trip_seats`, so `public_trips.available_seats`
--      stops reporting every trip as empty.
--   6. `trip_events.event_code` populated per transition (169 of 175 rows read 'other').
--   7. A delete guard: a trip that has left `scheduled`, or that carries any booking,
--      can no longer be hard-deleted out from under its passengers.
--
-- RLS policies, office isolation and grants are NOT altered. The new trigger is an
-- orthogonal second check that sits behind the policies that already exist.
--
-- No status value is added or removed. `operation_trips_status_check` is untouched.

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. Booking availability — the derived axis, server-side
-- ───────────────────────────────────────────────────────────────────────────────────
-- "Can a seat be sold on this trip right now?" is not the same question as "what
-- operational state is this trip in?", and must not be answered by reading `status`
-- alone. This is the single definition; `lock_trip_seat` and the dashboard both defer
-- to it rather than each carrying their own copy.

create or replace function public.trip_is_bookable(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists (
    select 1
    from public.operation_trips t
    where t.id = p_trip_id
      and t.status = 'open_for_booking'
      and t.trip_date >= current_date
  );
$$;

comment on function public.trip_is_bookable(uuid) is
  'Booking availability as a derived axis: published AND not already departed. The date '
  'half of this rule lived only in BookableTrip in the Flutter client until 20260727160000.';

-- Why a trip cannot be published yet, or null when it can be.
create or replace function public.trip_publish_blocker(p_trip_id uuid)
returns text
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  t public.operation_trips%rowtype;
begin
  select * into t from public.operation_trips where id = p_trip_id;
  if not found then return 'trip_not_found'; end if;

  if t.driver_id is null  then return 'no_driver';  end if;
  if t.vehicle_id is null then return 'no_vehicle'; end if;

  if not exists (select 1 from public.trip_seats where trip_id = p_trip_id) then
    return 'no_seats';
  end if;

  -- create_trip does not write trip_pricing; the dashboard expands the fare across stop
  -- pairs in a client-side loop *after* creation has already committed. A trip whose
  -- pricing never landed sells at the transport_packages catalogue price instead of the
  -- operator's fare, because that is confirm_seat_booking_v2's fallback. Refuse to
  -- publish it rather than sell it at a price the office never set.
  if not exists (
    select 1 from public.trip_pricing where trip_id = p_trip_id and is_active
  ) then
    return 'no_pricing';
  end if;

  if t.trip_date < current_date then return 'past_date'; end if;

  return null;
end;
$$;

comment on function public.trip_publish_blocker(uuid) is
  'Readiness gate for scheduled -> open_for_booking. Returns the first blocking reason, '
  'or null when the trip may be published.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. The state machine
-- ───────────────────────────────────────────────────────────────────────────────────

-- The 2-argument signatures are dropped rather than kept alongside: an overload pair
-- where one form is the other with a defaulted trailing argument is ambiguous for a
-- 2-argument call ("could not choose a best candidate function"). PostgREST resolves
-- RPCs by parameter *name*, so the Captain app's existing
-- `{p_trip_id, p_new_status}` call binds to the 3-argument form unchanged.
drop function if exists public.captain_update_trip_status(uuid, text);
drop function if exists public.office_update_trip_status(uuid, text);
drop function if exists public.update_trip_status(uuid, text);

create or replace function public.update_trip_status(
  p_trip_id    uuid,
  p_new_status text,
  p_reason     text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_current      text;
  v_allowed      boolean := false;
  v_blocker      text;
  v_reason       text := nullif(trim(coalesce(p_reason, '')), '');
  v_event_code   text;
  v_event_title  text;
  v_event_desc   text;
  v_refund_owed  int := 0;
  v_bookings     int := 0;
  v_passengers   int := 0;
  v_seats        int := 0;
begin
  select status into v_current
  from public.operation_trips
  where id = p_trip_id
  for update;                                  -- serialises concurrent transitions

  if not found then
    raise exception 'trip_not_found: Trip does not exist';
  end if;

  -- Idempotency. A retried request, a double-tap, or a client replaying a timed-out
  -- call must not raise `invalid_transition` — nothing is wrong, the trip is already
  -- where the caller wants it. Returning before the UPDATE also means no duplicate
  -- notification is fired, since on_operation_trip_change only runs on a real write.
  if v_current = p_new_status then
    return jsonb_build_object(
      'success', true, 'unchanged', true, 'trip_id', p_trip_id,
      'previous_status', v_current, 'new_status', p_new_status
    );
  end if;

  if (v_current = 'scheduled'        and p_new_status in ('open_for_booking', 'cancelled')) or
     (v_current = 'open_for_booking' and p_new_status in ('boarding', 'cancelled')) or
     (v_current = 'boarding'         and p_new_status in ('in_progress', 'cancelled')) or
     (v_current = 'in_progress'      and p_new_status in ('completed', 'cancelled'))
  then
    v_allowed := true;
  end if;

  if not v_allowed then
    raise exception 'invalid_transition: Cannot transition trip from % to %',
      v_current, p_new_status;
  end if;

  -- Publish gate. Unconditional until now, which is how a trip with no pricing, no
  -- driver or a date in the past could be released to the marketplace.
  if p_new_status = 'open_for_booking' then
    v_blocker := public.trip_publish_blocker(p_trip_id);
    if v_blocker is not null then
      raise exception 'trip_not_publishable:%', v_blocker;
    end if;
  end if;

  -- Cancelling a trip that is boarding or already running strands passengers who are
  -- physically at the stop or on the vehicle. It stays possible — a breakdown is real —
  -- but it may not be a mis-tap, and the record must say why.
  if p_new_status = 'cancelled'
     and v_current in ('boarding', 'in_progress')
     and v_reason is null then
    raise exception 'cancellation_reason_required';
  end if;

  -- The one write of `status` the system permits. The flag is transaction-local and is
  -- what trg_enforce_trip_write_authority checks; nothing outside this function can set
  -- it, so nothing outside this function can move a trip.
  perform set_config('bmt.trip_transition', p_trip_id::text, true);

  update public.operation_trips
  set
    status            = p_new_status,
    updated_at        = now(),
    -- Stamped on entry to `boarding`, not `in_progress`: Live Ops' delay detection
    -- already reads it with that meaning. Deliberately unchanged.
    actual_start_time = case
      when p_new_status = 'boarding' and actual_start_time is null then now()
      else actual_start_time
    end,
    -- A completed trip always has an end time. The previous rule only stamped one when
    -- actual_start_time was already set, so a trip that reached `in_progress` without a
    -- boarding stamp — which the old direct-UPDATE hole made possible — completed with
    -- no end time at all. Cancellation keeps the conditional: a trip cancelled before it
    -- ever moved never ran, and giving it an end time would invent an event.
    actual_end_time   = case
      when p_new_status = 'completed' then now()
      when p_new_status = 'cancelled' and actual_start_time is not null then now()
      else actual_end_time
    end
  where id = p_trip_id;

  perform set_config('bmt.trip_transition', '', true);

  -- ── side effects ────────────────────────────────────────────────────────────────

  if p_new_status = 'completed' then
    -- A booking on a trip that ran is completed, not still 'confirmed'. Both
    -- 'boarded' and 'completed' are permitted by valid_booking_status and neither was
    -- ever written by anything; four live bookings sat 'confirmed' on completed trips.
    update public.operation_bookings
    set status = 'completed', updated_at = now()
    where trip_id = p_trip_id
      and status = 'confirmed';
    get diagnostics v_bookings = row_count;

    update public.trip_passengers
    set status = 'completed', updated_at = now()
    where trip_id = p_trip_id
      and status = 'confirmed';

    -- Anyone the captain never boarded did not travel.
    update public.trip_passengers
    set status = 'no_show', updated_at = now()
    where trip_id = p_trip_id
      and status not in ('cancelled', 'no_show', 'completed');

  elsif p_new_status = 'cancelled' then
    -- Money exposure, measured before the bookings are cancelled. payment_status is
    -- deliberately NOT rewritten: no refund has happened, and claiming 'refunded' would
    -- be a lie. The paid-but-cancelled pair stays representable and stays visible in
    -- booking_state_contradictions (migration 20260727140000), which is where a refund
    -- is actioned from.
    select count(*) into v_refund_owed
    from public.operation_bookings
    where trip_id = p_trip_id
      and status not in ('cancelled', 'rejected')
      and payment_status = 'approved';

    -- Riders whose payment was still under review had their booking cancelled and were
    -- told nothing: notify_trip_passengers reads trip_passengers, and a rider only gains
    -- a row there once payment is approved. Notify them directly, before the booking
    -- rows are rewritten.
    insert into public.notifications
      (user_id, title, body, type, category, target_app, data, priority)
    select distinct b.client_id,
           'تم إلغاء رحلتك',
           'نأسف، تم إلغاء رحلتك وسيتم التواصل معك بخصوص المبلغ المدفوع.',
           'trip', 'trip', 'client',
           jsonb_build_object('trip_id', p_trip_id, 'booking_id', b.id),
           'high'
    from public.operation_bookings b
    where b.trip_id = p_trip_id
      and b.client_id is not null
      and b.status not in ('cancelled', 'rejected')
      and not exists (
        select 1 from public.trip_passengers tp
        where tp.trip_id = p_trip_id and tp.customer_id = b.client_id
      );

    update public.operation_bookings
    set status = 'cancelled', updated_at = now()
    where trip_id = p_trip_id
      and status not in ('cancelled', 'rejected');
    get diagnostics v_bookings = row_count;

    -- Previously untouched entirely: every rider stayed 'confirmed' on a trip that was
    -- never going to run, so the captain's manifest still listed them and every
    -- passenger count still counted them.
    update public.trip_passengers
    set status = 'cancelled', updated_at = now()
    where trip_id = p_trip_id
      and status not in ('cancelled', 'no_show', 'completed');
    get diagnostics v_passengers = row_count;

    -- The hold timestamps survived the release, so a freed seat could still read as
    -- held to anything that inspects them.
    update public.trip_seats
    set state           = 'available',
        passenger_id    = null,
        held_at         = null,
        hold_expires_at = null,
        lock_expires_at = null,
        updated_at      = now()
    where trip_id = p_trip_id
      and state not in ('available', 'blocked');
    get diagnostics v_seats = row_count;
  end if;

  -- ── audit trail ─────────────────────────────────────────────────────────────────

  v_event_code := case p_new_status
    when 'open_for_booking' then 'trip_published'
    when 'boarding'         then 'boarding_started'
    when 'in_progress'      then 'trip_departed'
    when 'completed'        then 'trip_completed'
    when 'cancelled'        then 'trip_cancelled'
    else 'other'
  end;

  v_event_title := case p_new_status
    when 'open_for_booking' then 'فتح الحجز'
    when 'boarding'         then 'بدء التجميع'
    when 'in_progress'      then 'انطلاق الرحلة'
    when 'completed'        then 'اكتمال الرحلة'
    when 'cancelled'        then 'إلغاء الرحلة'
    else p_new_status
  end;

  v_event_desc := 'تم تغيير حالة الرحلة إلى: ' || p_new_status;
  if v_reason is not null then
    v_event_desc := v_event_desc || ' — السبب: ' || v_reason;
  end if;
  if p_new_status = 'cancelled' then
    v_event_desc := v_event_desc
      || ' — تم إلغاء ' || v_bookings || ' حجز وتحرير ' || v_seats || ' مقعد'
      || case when v_refund_owed > 0
              then '، ' || v_refund_owed || ' منها مدفوعة وتحتاج استرداد'
              else '' end;
  elsif p_new_status = 'completed' then
    v_event_desc := v_event_desc || ' — تم إنهاء ' || v_bookings || ' حجز';
  end if;

  insert into public.trip_events (trip_id, title, description, done, event_code)
  values (p_trip_id, v_event_title, v_event_desc, true, v_event_code);

  return jsonb_build_object(
    'success',            true,
    'unchanged',          false,
    'trip_id',            p_trip_id,
    'previous_status',    v_current,
    'new_status',         p_new_status,
    'bookings_affected',  v_bookings,
    'passengers_affected', v_passengers,
    'seats_released',     v_seats,
    'refund_owed_count',  v_refund_owed,
    'actual_start_time',  (select actual_start_time from public.operation_trips where id = p_trip_id),
    'actual_end_time',    (select actual_end_time   from public.operation_trips where id = p_trip_id)
  );
end;
$$;

comment on function public.update_trip_status(uuid, text, text) is
  'The only path that may change operation_trips.status; enforced by '
  'trg_enforce_trip_write_authority. Never granted to authenticated — reach it through '
  'office_update_trip_status or captain_update_trip_status.';

revoke all on function public.update_trip_status(uuid, text, text) from public, anon, authenticated;
grant execute on function public.update_trip_status(uuid, text, text) to service_role;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. Write authority — the trigger that makes §2 the only way in
-- ───────────────────────────────────────────────────────────────────────────────────

create or replace function public.enforce_trip_write_authority()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office  uuid;
  v_driver  uuid;
begin
  -- Service context: migrations, backfills, scheduled jobs. There is no end user to
  -- constrain, and blocking these would make this migration unable to run itself.
  if auth.uid() is null then
    return new;
  end if;

  -- Derived columns are nobody's decision — they are recomputed from rows elsewhere
  -- (sync_trip_booked_seats from trip_seats; the counters from bookings). Such a write
  -- arrives as a cascade under whichever user happened to move a seat, so judging it by
  -- who that user is would block a maintenance trigger for being fired by a captain.
  -- Nothing a person authored has changed, so there is nothing to authorise.
  if new.status         is not distinct from old.status
 and new.route_id       is not distinct from old.route_id
 and new.driver_id      is not distinct from old.driver_id
 and new.vehicle_id     is not distinct from old.vehicle_id
 and new.trip_date      is not distinct from old.trip_date
 and new.departure_time is not distinct from old.departure_time
 and new.arrival_time   is not distinct from old.arrival_time
 and new.capacity       is not distinct from old.capacity
 and new.ticket_price   is not distinct from old.ticket_price
 and new.currency       is not distinct from old.currency
 and new.trip_code      is not distinct from old.trip_code
 and new.office_id      is not distinct from old.office_id
 and new.notes          is not distinct from old.notes
 and new.actual_start_time is not distinct from old.actual_start_time
 and new.actual_end_time   is not distinct from old.actual_end_time
  then
    return new;
  end if;

  -- A status change is checked before anything else, because a legitimate transition is
  -- authorised by the wrapper that started it — not by who the writer happens to be. A
  -- captain moving their own trip through captain_update_trip_status arrives here with
  -- auth.uid() set to the captain, and must pass.
  if new.status is distinct from old.status then
    if coalesce(current_setting('bmt.trip_transition', true), '') <> old.id::text then
      raise exception
        'trip_status_direct_update_forbidden: use office_update_trip_status / captain_update_trip_status';
    end if;
    -- A transition is in flight; update_trip_status has already validated it.
    return new;
  end if;

  v_office := public.current_office_id();
  v_driver := public.current_driver_id();

  -- Everything below is a direct write of an authored, non-status column. A captain
  -- never makes one: the RLS policy trips_captain_update grants UPDATE on the whole row,
  -- which let a captain rewrite ticket_price, capacity, trip_date and driver_id on their
  -- own assigned trip.
  if v_office is null and v_driver is not null then
    raise exception
      'trip_direct_write_forbidden: captains change trips through captain_update_trip_status';
  end if;

  -- Planning fields on a trip that has departed are history, not settings. The
  -- actual_* stamps are observations of what happened and are never hand-edited:
  -- update_trip_status is the only thing that writes them, and it goes down the
  -- status branch above.
  if old.status in ('completed', 'cancelled') then
    if new.route_id       is distinct from old.route_id
    or new.driver_id      is distinct from old.driver_id
    or new.vehicle_id     is distinct from old.vehicle_id
    or new.trip_date      is distinct from old.trip_date
    or new.departure_time is distinct from old.departure_time
    or new.capacity       is distinct from old.capacity
    or new.ticket_price   is distinct from old.ticket_price
    or new.actual_start_time is distinct from old.actual_start_time
    or new.actual_end_time   is distinct from old.actual_end_time then
      raise exception 'trip_locked: a % trip cannot be re-planned', old.status;
    end if;
  elsif old.status in ('boarding', 'in_progress') then
    -- driver_id / vehicle_id stay editable: swapping a broken-down vehicle mid-service
    -- is a real operation. The trip's identity is not.
    if new.route_id       is distinct from old.route_id
    or new.trip_date      is distinct from old.trip_date
    or new.departure_time is distinct from old.departure_time
    or new.capacity       is distinct from old.capacity
    or new.ticket_price   is distinct from old.ticket_price
    or new.actual_start_time is distinct from old.actual_start_time
    or new.actual_end_time   is distinct from old.actual_end_time then
      raise exception 'trip_locked: a trip that has started cannot be re-planned';
    end if;
  end if;

  return new;
end;
$$;

comment on function public.enforce_trip_write_authority() is
  'Column-level protection RLS cannot express: status may only change from inside '
  'update_trip_status, planning fields freeze once a trip departs, and captains may not '
  'write operation_trips directly at all.';

drop trigger if exists trg_enforce_trip_write_authority on public.operation_trips;
create trigger trg_enforce_trip_write_authority
  before update on public.operation_trips
  for each row
  execute function public.enforce_trip_write_authority();

-- ───────────────────────────────────────────────────────────────────────────────────
-- 4. Delete guard
-- ───────────────────────────────────────────────────────────────────────────────────
-- operation_bookings.trip_id is ON DELETE SET NULL, so deleting a trip that carries
-- bookings leaves paid bookings pointing at no trip, no route and no refund trail — and
-- the rider is never told. The dashboard offers this as a routine row action.

create or replace function public.enforce_trip_delete_guard()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    return old;                                -- service context
  end if;

  if old.status <> 'scheduled' then
    raise exception
      'trip_delete_forbidden: only an unpublished trip can be deleted — cancel it instead';
  end if;

  if exists (select 1 from public.operation_bookings where trip_id = old.id) then
    raise exception
      'trip_delete_forbidden: this trip has bookings — cancel it instead';
  end if;

  return old;
end;
$$;

drop trigger if exists trg_enforce_trip_delete_guard on public.operation_trips;
create trigger trg_enforce_trip_delete_guard
  before delete on public.operation_trips
  for each row
  execute function public.enforce_trip_delete_guard();

-- ───────────────────────────────────────────────────────────────────────────────────
-- 5. Authorisation wrappers
-- ───────────────────────────────────────────────────────────────────────────────────

create or replace function public.office_update_trip_status(
  p_trip_id    uuid,
  p_new_status text,
  p_reason     text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
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
    -- The captain actually driving it — but only within the captain-legal subset.
    -- Without this, a captain could reach cancellation (and publishing) simply by
    -- calling this wrapper instead of captain_update_trip_status, whose allowlist was
    -- therefore advisory rather than binding.
    if p_new_status not in ('boarding', 'in_progress', 'completed') then
      raise exception 'status_not_allowed_for_captain';
    end if;
  else
    raise exception 'not_authorized';
  end if;

  return public.update_trip_status(p_trip_id, p_new_status, p_reason);
end;
$$;

grant execute on function public.office_update_trip_status(uuid, text, text) to authenticated;

create or replace function public.captain_update_trip_status(
  p_trip_id    uuid,
  p_new_status text,
  p_reason     text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_driver      uuid := public.current_driver_id();
  v_trip_driver uuid;
begin
  if v_driver is null then
    raise exception 'not_a_captain';
  end if;

  -- The captain-legal subset: start boarding, depart, finish. Cancellation and
  -- publishing (scheduled → open_for_booking) stay with operations.
  if p_new_status not in ('boarding', 'in_progress', 'completed') then
    raise exception 'status_not_allowed_for_captain';
  end if;

  select driver_id into v_trip_driver
    from public.operation_trips where id = p_trip_id;

  if v_trip_driver is null then
    raise exception 'trip_not_found';
  end if;
  if v_trip_driver <> v_driver then
    raise exception 'not_your_trip';
  end if;

  return public.update_trip_status(p_trip_id, p_new_status, p_reason);
end;
$$;

grant execute on function public.captain_update_trip_status(uuid, text, text) to authenticated;

-- Explicit cancellation, so the dashboard has one call that always means "cancel" and
-- always carries a reason — rather than reaching cancellation through a generic status
-- setter, which is why the dashboard had no cancel action for a healthy trip at all.
create or replace function public.office_cancel_trip(p_trip_id uuid, p_reason text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
begin
  if v_reason is null then
    raise exception 'cancellation_reason_required';
  end if;
  return public.office_update_trip_status(p_trip_id, 'cancelled', v_reason);
end;
$$;

grant execute on function public.office_cancel_trip(uuid, text) to authenticated;

-- A trip whose departure day has passed while it is still open for booking is invisible
-- to riders and permanently "open" on the dashboard. The dashboard offered "إنهاء
-- الرحلة" for it, which the state machine rejects outright (open_for_booking →
-- completed is not an edge) — so the button could only ever fail.
--
-- The two honest outcomes are: it ran and nobody closed it, or it did not run. This
-- walks the real machine for the first, so every side effect fires exactly as it would
-- have, and delegates to cancellation for the second.
--
-- Rider notifications are suppressed on the `operated` path only. Replaying "بدأ صعود
-- الركاب" and "انطلقت رحلتك" for a departure that happened a week ago is noise that
-- tells the rider nothing true; a cancellation, by contrast, is news they need — that
-- path notifies normally.
create or replace function public.office_close_stale_trip(
  p_trip_id uuid,
  p_outcome text,                                -- 'operated' | 'cancelled'
  p_reason  text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_status text;
  v_result jsonb;
begin
  select status into v_status
  from public.operation_trips where id = p_trip_id;

  if v_status is null then
    raise exception 'trip_not_found';
  end if;
  if v_status in ('completed', 'cancelled') then
    raise exception 'trip_already_closed';
  end if;

  if p_outcome = 'cancelled' then
    return public.office_cancel_trip(
      p_trip_id,
      coalesce(nullif(trim(coalesce(p_reason, '')), ''), 'إغلاق رحلة فات موعدها')
    );
  end if;

  if p_outcome <> 'operated' then
    raise exception 'invalid_outcome';
  end if;

  -- A trip that was never published could not be booked and therefore cannot have
  -- carried anyone. Claiming it operated would fabricate a service that never ran — and
  -- the publish gate would refuse the past date anyway.
  if v_status = 'scheduled' then
    raise exception 'trip_never_published';
  end if;

  perform set_config('bmt.trip_notify_suppress', p_trip_id::text, true);

  -- Each step is the real transition, authorised the same way and applying the same
  -- side effects; only the operator's click count changes.
  if v_status = 'open_for_booking' then
    perform public.office_update_trip_status(p_trip_id, 'boarding',
                                             'إغلاق رحلة فات موعدها');
    v_status := 'boarding';
  end if;
  if v_status = 'boarding' then
    perform public.office_update_trip_status(p_trip_id, 'in_progress',
                                             'إغلاق رحلة فات موعدها');
  end if;
  v_result := public.office_update_trip_status(p_trip_id, 'completed',
                                               'إغلاق رحلة فات موعدها');
  perform set_config('bmt.trip_notify_suppress', '', true);
  return v_result;
end;
$$;

grant execute on function public.office_close_stale_trip(uuid, text, text) to authenticated;

-- Supabase's default privileges grant EXECUTE to PUBLIC and to `anon` on every new
-- function in `public`, and `create or replace` on a *new* signature is a new function —
-- so dropping the 2-argument wrappers above and recreating them as 3-argument ones would
-- silently widen `office_update_trip_status` and `captain_update_trip_status` from
-- `authenticated` back to `anon`. An anonymous caller gets `not_authorized` from the
-- wrappers' own checks either way, but the reachable surface is kept as narrow as the
-- rest of the office_* family (see the security register in DASHBOARD_STATUS.md).
revoke all on function public.office_update_trip_status(uuid, text, text)  from public, anon;
revoke all on function public.captain_update_trip_status(uuid, text, text) from public, anon;
revoke all on function public.office_cancel_trip(uuid, text)               from public, anon;
revoke all on function public.office_close_stale_trip(uuid, text, text)    from public, anon;
revoke all on function public.trip_is_bookable(uuid)                       from public, anon;
revoke all on function public.trip_publish_blocker(uuid)                   from public, anon;

grant execute on function public.trip_is_bookable(uuid)     to authenticated, service_role;
grant execute on function public.trip_publish_blocker(uuid) to authenticated, service_role;

-- The suppression hook. on_operation_trip_change is otherwise unchanged: it stays the
-- single place every trip notification is fired from, which is what makes "exactly once
-- per transition" true — update_trip_status writes `status` in one UPDATE, and the
-- status guard means no other writer can.
create or replace function public.on_operation_trip_change()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_captain uuid;
  v_code    text := coalesce(nullif(trim(new.trip_code), ''), 'رحلتك');
begin
  -- Captain (re)assignment
  if new.driver_id is not null
     and new.driver_id is distinct from old.driver_id then
    select user_id into v_captain from public.drivers where id = new.driver_id;
    perform public.push_notification(
      v_captain, 'تم إسنادك لرحلة جديدة',
      'رحلة ' || v_code || ' بتاريخ ' || to_char(new.trip_date, 'YYYY-MM-DD'),
      'assignment', 'captain',
      jsonb_build_object('trip_id', new.id), '/trips', 'high');
  end if;

  -- Status transitions
  if new.status is distinct from old.status
     and coalesce(current_setting('bmt.trip_notify_suppress', true), '') <> new.id::text
  then
    v_captain := public.captain_user_for_trip(new.id);

    if new.status = 'boarding' then
      perform public.notify_trip_passengers(
        new.id, 'بدأ صعود الركاب',
        'بدأ صعود الركاب لرحلتك ' || v_code, 'trip',
        jsonb_build_object('trip_id', new.id));
      perform public.push_notification(
        v_captain, 'بدأ صعود الركاب', 'رحلة ' || v_code, 'trip', 'captain',
        jsonb_build_object('trip_id', new.id));

    elsif new.status = 'in_progress' then
      perform public.notify_trip_passengers(
        new.id, 'انطلقت رحلتك',
        'رحلتك ' || v_code || ' في الطريق الآن.', 'trip',
        jsonb_build_object('trip_id', new.id), 'high');
      perform public.push_notification(
        v_captain, 'بدأت الرحلة', 'رحلة ' || v_code || ' قيد التنفيذ.',
        'trip', 'captain', jsonb_build_object('trip_id', new.id));

    elsif new.status = 'completed' then
      perform public.notify_trip_passengers(
        new.id, 'اكتملت رحلتك',
        'نشكرك على السفر معنا في رحلة ' || v_code || '.', 'trip',
        jsonb_build_object('trip_id', new.id));

    elsif new.status = 'cancelled' then
      perform public.notify_trip_passengers(
        new.id, 'تم إلغاء رحلتك',
        'نأسف، تم إلغاء رحلتك ' || v_code || '. سيتم التواصل معك بخصوص الاسترداد.',
        'trip', jsonb_build_object('trip_id', new.id), 'high');
      perform public.push_notification(
        v_captain, 'تم إلغاء الرحلة', 'تم إلغاء رحلة ' || v_code || '.',
        'trip', 'captain', jsonb_build_object('trip_id', new.id), null, 'high');
      perform public.push_operational_alert(
        'trip_cancelled', 'تم إلغاء رحلة', 'تم إلغاء الرحلة ' || v_code || '.',
        jsonb_build_object('trip_id', new.id), 'high', '/live-trips');
    end if;
  end if;

  return new;
end;
$function$;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 6. Booking availability enforced at the seat lock
-- ───────────────────────────────────────────────────────────────────────────────────
-- lock_trip_seat never read operation_trips at all: a seat could be locked on a
-- scheduled, boarding, in_progress, completed or cancelled trip. On a cancelled trip
-- that re-occupies seats update_trip_status had just released, so the release was not
-- final.
--
-- confirm_seat_booking_v2 is intentionally left byte-for-byte alone. It already refuses
-- anything but 'open_for_booking', and every path into it requires a lock this function
-- granted — so gating here gates both, without retyping 200 lines of money handling.

create or replace function public.lock_trip_seat(
  p_trip_id uuid, p_seat_id uuid, p_client_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_lock_expires_at timestamptz;
  v_rows_updated    int;
begin
  if not public.trip_is_bookable(p_trip_id) then
    raise exception 'trip_not_bookable: This trip is not open for booking';
  end if;

  -- Fail before touching trip_seats, not after. confirm_seat_booking_v2 raises
  -- the same error, but by then this function has already committed a lock that
  -- no later rollback can undo. Same status vocabulary as confirm's guard.
  if exists (
    select 1 from public.operation_bookings
    where client_id = p_client_id
      and trip_id = p_trip_id
      and status in ('reserved', 'confirmed')
  ) then
    raise exception 'duplicate_active_booking';
  end if;

  v_lock_expires_at := now() + interval '5 minutes';

  -- Single atomic UPDATE: only succeeds if the seat is currently available.
  -- Postgres serialises concurrent updates on the same row — no double-booking.
  update public.trip_seats
  set state           = 'reserved',
      passenger_id    = p_client_id,
      lock_expires_at = v_lock_expires_at
  where id = p_seat_id
    and trip_id = p_trip_id
    and (
      state = 'available'
      -- Self-healing: also accept expired locks that have no active booking.
      or (
        state = 'reserved'
        and lock_expires_at < now()
        and id not in (
          select seat_id from public.operation_bookings
          where seat_id is not null
            and status not in ('cancelled', 'rejected')
        )
      )
    );

  get diagnostics v_rows_updated = row_count;

  if v_rows_updated = 0 then
    raise exception 'seat_unavailable: Seat is no longer available for booking';
  end if;

  return jsonb_build_object(
    'success',         true,
    'seat_id',         p_seat_id,
    'lock_expires_at', v_lock_expires_at
  );
end;
$$;

grant execute on function public.lock_trip_seat(uuid, uuid, uuid) to authenticated;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 7. booked_seats — stop lying about capacity
-- ───────────────────────────────────────────────────────────────────────────────────
-- booked_seats reads 0 on every live trip, including trips with occupied seats, because
-- the seat flow moves trip_seats.state and never touches the counter. public_trips
-- derives available_seats = capacity - booked_seats from it, so the marketplace view
-- reports every trip as completely empty. The Client is immune only because
-- BookableTrip deliberately counts trip_seats instead.
--
-- Recomputed from trip_seats rather than incremented, so a stale decrement elsewhere
-- (cancel_booking still does one) cannot accumulate drift.

create or replace function public.sync_trip_booked_seats()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_trip uuid := coalesce(new.trip_id, old.trip_id);
begin
  update public.operation_trips t
  set booked_seats = (
        select count(*) from public.trip_seats s
        where s.trip_id = v_trip and s.state <> 'available'
      )
  where t.id = v_trip
    and t.booked_seats is distinct from (
        select count(*) from public.trip_seats s
        where s.trip_id = v_trip and s.state <> 'available'
      );
  return null;
end;
$$;

drop trigger if exists trg_sync_trip_booked_seats on public.trip_seats;
create trigger trg_sync_trip_booked_seats
  after insert or update of state or delete on public.trip_seats
  for each row
  execute function public.sync_trip_booked_seats();

-- ───────────────────────────────────────────────────────────────────────────────────
-- 8. Marketplace visibility — stop exposing unpublished trips
-- ───────────────────────────────────────────────────────────────────────────────────
-- public_trips exposed 'scheduled', and trip_pricing_marketplace_read /
-- trip_seats_marketplace_read are keyed on trip_office_is_listed() with no status
-- condition — so an anonymous caller could read the fares and seat map of a trip the
-- office had not published yet.
--
-- Dropping it is safe: a scheduled trip is unsellable, so no booking can reference one,
-- and every client surface either filters to 'open_for_booking' or reads a trip the
-- rider has already booked. Verified against live data: zero bookings on scheduled trips.

create or replace view public.public_trips as
 SELECT t.id,
    t.trip_code,
    t.office_id,
    t.route_id,
    t.trip_date,
    t.departure_time,
    t.arrival_time,
    t.actual_start_time,
    t.actual_end_time,
    t.status,
    t.capacity,
    t.booked_seats,
    GREATEST(t.capacity - t.booked_seats, 0) AS available_seats,
    t.ticket_price,
    t.currency,
        CASE
            WHEN d.id IS NOT NULL THEN jsonb_build_object('full_name', d.full_name, 'profile_image_url', d.profile_image_url, 'rating', d.rating, 'rating_count', d.rating_count)
            ELSE NULL::jsonb
        END AS drivers,
        CASE
            WHEN v.id IS NOT NULL THEN jsonb_build_object('vehicle_code', v.vehicle_code, 'vehicle_type', v.vehicle_type, 'brand', v.brand, 'model', v.model, 'manufacture_year', v.manufacture_year, 'color', v.color, 'capacity', v.capacity, 'seat_layout_type', v.seat_layout_type, 'image_url', v.image_url, 'rating', v.rating, 'rating_count', v.rating_count)
            ELSE NULL::jsonb
        END AS vehicles
   FROM operation_trips t
     LEFT JOIN drivers d ON d.id = t.driver_id
     LEFT JOIN vehicles v ON v.id = t.vehicle_id
  WHERE (t.status = ANY (ARRAY['open_for_booking'::text, 'boarding'::text, 'in_progress'::text, 'completed'::text]))
    AND office_is_listed(t.office_id);

comment on view public.public_trips is
  'The only operation_trips surface the Client may read. Excludes scheduled (unpublished) '
  'and cancelled trips; includes boarding/in_progress/completed so a rider can follow and '
  'review a trip they booked.';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 9. Reconcile what already drifted
-- ───────────────────────────────────────────────────────────────────────────────────
-- Every statement here recomputes a value that was always a function of data the system
-- already holds. Nothing is invented: actual_start_time / actual_end_time are
-- observations and are left exactly as recorded, including TR-423791's
-- completed-before-its-own-departure-date anomaly, which is reported rather than erased.

update public.operation_trips t
set booked_seats = c.n
from (
  select trip_id, count(*) filter (where state <> 'available') as n
  from public.trip_seats group by trip_id
) c
where c.trip_id = t.id and t.booked_seats is distinct from c.n;

update public.operation_bookings b
set status = 'completed', updated_at = now()
from public.operation_trips t
where t.id = b.trip_id
  and t.status = 'completed'
  and b.status = 'confirmed';

update public.trip_passengers p
set status = 'completed', updated_at = now()
from public.operation_trips t
where t.id = p.trip_id
  and t.status = 'completed'
  and p.status = 'confirmed';

update public.trip_passengers p
set status = 'cancelled', updated_at = now()
from public.operation_trips t
where t.id = p.trip_id
  and t.status = 'cancelled'
  and p.status not in ('cancelled', 'no_show', 'completed');
