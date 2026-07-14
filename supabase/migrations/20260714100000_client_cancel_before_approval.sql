-- ---------------------------------------------------------------------------
-- Client-initiated cancellation, allowed only before the dashboard approves.
--
-- Trip Details showed a "Cancel Trip" button on every upcoming trip, and the
-- button was pure UI — it showed a snackbar and never reached Supabase. The
-- booking stayed reserved, the seat stayed taken, and the payment stayed in the
-- dashboard's review queue. Two things are wrong there and both are fixed here:
--
--   1. Cancelling must actually cancel: release the seat back to the trip's
--      inventory, drop the passenger off the manifest, and take the payment out
--      of the dashboard's verification queue (which reads
--      payment_status in ('submitted','underReview','approved','rejected')).
--   2. Cancelling must stop being offered once the money is confirmed. An
--      approved payment is final — from that point the client goes through
--      support, not a self-service button.
--
-- The rule is enforced here, in the RPC, not only in the client: the seat and
-- the money are the database's to protect.
-- ---------------------------------------------------------------------------

-- 1. 'cancelled' is a payment outcome distinct from 'rejected' (dashboard said
--    no) and 'refunded' (money went back). Nothing was ever approved here.
alter table public.operation_bookings
  drop constraint if exists operation_bookings_payment_status_check;
alter table public.operation_bookings
  add constraint operation_bookings_payment_status_check check (
    payment_status in (
      'pending', 'submitted', 'underReview', 'approved',
      'rejected', 'refunded', 'failed', 'cancelled'
    )
  );

alter table public.booking_payments
  drop constraint if exists booking_payments_status_check;
alter table public.booking_payments
  add constraint booking_payments_status_check check (
    status in (
      'pending', 'submitted', 'under_review', 'approved',
      'rejected', 'refunded', 'cancelled'
    )
  );

-- 2. Why the client cancelled, kept separate from payment_rejection_reason so a
--    client cancellation is never read back as a dashboard rejection.
alter table public.operation_bookings
  add column if not exists cancellation_reason text,
  add column if not exists cancelled_at timestamptz;

-- ---------------------------------------------------------------------------
-- cancel_booking_by_client
--
-- Callable only by the booking's own client, and only while the payment is
-- still awaiting the dashboard. Idempotent: cancelling an already-cancelled
-- booking succeeds instead of raising, so a double tap is harmless.
-- ---------------------------------------------------------------------------
create or replace function public.cancel_booking_by_client(
  p_booking_id uuid,
  p_reason     text default null
) returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_booking public.operation_bookings%rowtype;
  v_reason  text := nullif(trim(coalesce(p_reason, '')), '');
begin
  select * into v_booking
  from public.operation_bookings
  where id = p_booking_id
  for update;

  if not found then
    raise exception 'booking_not_found';
  end if;

  -- Ownership, not admin: this RPC is the client's own escape hatch.
  if auth.uid() is null or v_booking.client_id <> auth.uid() then
    raise exception 'not_authorized';
  end if;

  if v_booking.status = 'cancelled' then
    return jsonb_build_object(
      'success', true, 'booking_id', p_booking_id, 'status', 'cancelled',
      'already_cancelled', true
    );
  end if;

  -- The business rule. Once the dashboard approves the payment the seat is
  -- paid for and the client cannot take it back on their own.
  if v_booking.payment_status = 'approved'
     or v_booking.status in ('confirmed', 'boarded', 'completed') then
    raise exception 'booking_already_confirmed';
  end if;

  update public.operation_bookings
  set status                = 'cancelled',
      payment_status        = 'cancelled',
      payment_review_status = 'reviewed',
      cancellation_reason   = v_reason,
      cancelled_at          = now(),
      updated_at            = now()
  where id = p_booking_id;

  -- Takes the review request off the dashboard's queue.
  update public.booking_payments
  set status     = 'cancelled',
      updated_at = now()
  where booking_id = p_booking_id
    and status <> 'approved';

  -- Puts the seat back on sale for everyone else.
  update public.trip_seats
  set state           = 'available',
      passenger_id    = null,
      lock_expires_at = null,
      held_at         = null,
      hold_expires_at = null
  where id = v_booking.seat_id
    and passenger_id = v_booking.client_id;

  delete from public.trip_passengers where booking_id = p_booking_id;

  perform public.push_notification(
    v_booking.client_id,
    'تم إلغاء الحجز',
    'تم إلغاء حجزك وإتاحة المقعد مرة أخرى.'
      || coalesce(' السبب: ' || v_reason, ''),
    'booking', 'client',
    jsonb_build_object('booking_id', p_booking_id, 'trip_id', v_booking.trip_id)
  );

  -- The dashboard had a pending review for this booking; tell it why the row
  -- vanished from the queue instead of letting it disappear silently.
  perform public.push_operational_alert(
    'booking_cancelled_by_client',
    'إلغاء حجز من العميل',
    coalesce(v_booking.passenger_name, 'عميل')
      || ' ألغى الحجز قبل اعتماد الدفع — تم تحرير المقعد '
      || coalesce(v_booking.seat, ''),
    jsonb_build_object(
      'booking_id', p_booking_id,
      'trip_id', v_booking.trip_id,
      'seat', v_booking.seat,
      'reason', v_reason
    ),
    'normal'
  );

  return jsonb_build_object(
    'success', true, 'booking_id', p_booking_id, 'status', 'cancelled',
    'seat_released', v_booking.seat_id is not null
  );
end;
$$;

revoke all on function public.cancel_booking_by_client(uuid, text) from public;
grant execute on function public.cancel_booking_by_client(uuid, text)
  to authenticated;
