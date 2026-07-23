-- ═══════════════════════════════════════════════════════════════════════════════════
-- Captain trip-status transitions: restrict to the captain-legal subset
-- ═══════════════════════════════════════════════════════════════════════════════════
-- `captain_update_trip_status` (20260721100000_multi_office_security_hardening.sql)
-- asserts the caller owns the trip, then delegates to `update_trip_status` with
-- whatever status the caller passed. Ownership was the only gate — the target status
-- was not constrained at all.
--
-- `update_trip_status`'s own transition graph permits
--   open_for_booking → cancelled
--   boarding         → cancelled
--   in_progress      → cancelled
-- and its comments mark those as "ops cancels" / "admin emergency only". Cancelling is
-- not a captain action: the same RPC then cancels every open booking on the trip and
-- releases every locked seat.
--
-- The Captain App never offers a cancel control, so this was unreachable through the
-- UI — but the RPC is granted to `authenticated`, so any captain could reach it with a
-- crafted call and wipe out their own trip's bookings.
--
-- Fix: allowlist the three transitions a captain actually performs. Ops keeps the full
-- graph through `office_update_trip_status`, which is unchanged by this migration.

create or replace function public.captain_update_trip_status(
  p_trip_id  uuid,
  p_new_status text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_driver uuid := public.current_driver_id();
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

  return public.update_trip_status(p_trip_id, p_new_status);
end;
$$;

revoke all on function public.captain_update_trip_status(uuid, text)
  from public, anon, authenticated;
grant execute on function public.captain_update_trip_status(uuid, text)
  to authenticated;

comment on function public.captain_update_trip_status(uuid, text) is
  'Driver-scoped door to update_trip_status. Asserts the caller owns the trip AND that '
  'the target status is one a captain may set (boarding / in_progress / completed). '
  'Cancellation and publishing remain operations-only via office_update_trip_status. '
  'Captains are not office_users, so the office_* wrapper cannot serve them.';
