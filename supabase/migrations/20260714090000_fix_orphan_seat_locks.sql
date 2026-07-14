-- ---------------------------------------------------------------------------
-- Orphan seat locks
--
-- lock_trip_seat commits in its own transaction, then the client calls
-- confirm_seat_booking_v2. When confirm raises (duplicate_active_booking being
-- the common case: the client already holds a reserved booking on this trip),
-- confirm's transaction rolls back but the lock does not — it was a separate,
-- already-committed statement. The seat is left state='reserved',
-- passenger_id=<client>, with no operation_bookings row pointing at it.
--
-- Nothing reclaims that seat: release_expired_seat_holds() only walks seats
-- reachable from a booking row (and keys off hold_expires_at, which only
-- confirm ever sets), so an orphan is invisible to it. The seat map renders
-- every state <> 'available' as taken, so the client cannot re-pick it either.
-- Each retry burns another seat.
--
-- Three parts:
--   1. lock_trip_seat refuses the lock when the caller already has an active
--      booking on the trip — the seat is never burned in the first place.
--   2. release_trip_seat_lock lets the client hand a lock back when confirm
--      fails for any other reason (trip_not_available, network drop, ...).
--   3. Backfill: free the seats already stranded in production.
-- ---------------------------------------------------------------------------

create or replace function public.lock_trip_seat(
  p_trip_id   uuid,
  p_seat_id   uuid,
  p_client_id uuid
) returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_lock_expires_at timestamptz;
  v_rows_updated    int;
begin
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

-- ---------------------------------------------------------------------------
-- release_trip_seat_lock: compensating action for a failed confirm.
--
-- Deliberately narrow — it only frees a seat that is still nothing but a lock
-- held by this caller. A seat carrying a real booking (hold_expires_at set by
-- confirm, or any non-cancelled operation_bookings row) is left alone, so a
-- stray call can never cancel a paid or under-review seat. Idempotent: returns
-- false when there was nothing to release.
-- ---------------------------------------------------------------------------
create or replace function public.release_trip_seat_lock(
  p_trip_id   uuid,
  p_seat_id   uuid,
  p_client_id uuid
) returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_rows_updated int;
begin
  update public.trip_seats s
  set state           = 'available',
      passenger_id    = null,
      lock_expires_at = null,
      held_at         = null,
      hold_expires_at = null
  where s.id = p_seat_id
    and s.trip_id = p_trip_id
    and s.state = 'reserved'
    and s.passenger_id = p_client_id
    and s.hold_expires_at is null
    and not exists (
      select 1 from public.operation_bookings b
      where b.seat_id = s.id
        and b.status not in ('cancelled', 'rejected')
    );

  get diagnostics v_rows_updated = row_count;

  return jsonb_build_object('success', true, 'released', v_rows_updated > 0);
end;
$$;

grant execute on function public.lock_trip_seat(uuid, uuid, uuid)
  to authenticated;
grant execute on function public.release_trip_seat_lock(uuid, uuid, uuid)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Backfill: seats stranded by the bug above. Same predicate as
-- release_trip_seat_lock (lock-only, no booking, no hold), restricted to locks
-- that have already expired so a checkout in flight right now is not yanked
-- out from under the passenger.
-- ---------------------------------------------------------------------------
update public.trip_seats s
set state           = 'available',
    passenger_id    = null,
    lock_expires_at = null,
    held_at         = null,
    hold_expires_at = null
where s.state = 'reserved'
  and s.hold_expires_at is null
  and s.lock_expires_at is not null
  and s.lock_expires_at <= now()
  and not exists (
    select 1 from public.operation_bookings b
    where b.seat_id = s.id
      and b.status not in ('cancelled', 'rejected')
  );
