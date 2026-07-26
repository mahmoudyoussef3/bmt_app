-- ═══════════════════════════════════════════════════════════════════════════════════
-- Let a client pick the office an unlinked complaint is filed against
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Migration 20260721120000 derives support_tickets.office_id from the ticket's linked
-- booking/trip and, finding none, discards whatever the caller supplied (falling back
-- to current_office_id(), which is NULL for a client). In practice clients file general
-- complaints with no booking linked, so every client ticket landed office_id NULL —
-- platform-level, and the support_tickets_office RLS policy
-- (office_id is not null and office_id = current_office_id()) makes those invisible to
-- EVERY office. There is no platform-support console reading them, so client complaints
-- reached no one.
--
-- Product decision: a complaint must reach an office, and the client chooses which one
-- on the create-ticket form (an office picker fed by public_offices). This reworks the
-- BEFORE trigger to HONOUR that choice while keeping every existing guarantee:
--
--   1. A linked booking/trip is still authoritative and unforgeable — its office always
--      wins over anything the caller sent (SECURITY DEFINER lookup, since clients can no
--      longer read operation_trips at all).
--   2. With no linkage, a client-supplied office_id is honoured ONLY when it is a real,
--      pickable office — i.e. present in public_offices (active + listed), the very set
--      the client can see. Filing grants no read access: support_tickets_client_read
--      still restricts the client to their own rows, so aiming a complaint at an office
--      leaks nothing — it just routes the complaint, which is the whole point.
--   3. Anything else (bogus/unlisted office, or nothing supplied) falls back to
--      current_office_id() exactly as before: an office operator's own office, or NULL
--      (platform-level) for a client. push_operational_alert still drops NULL-office
--      alerts, so no unscoped or cross-office alert can be produced.
--
-- Only support_tickets changes. refund_requests grow from a booking/ticket that is
-- already attributed, so their derivation is left untouched. No RLS policy changes; the
-- trigger's event list is unchanged (clients cannot UPDATE tickets, so they cannot
-- re-aim one after filing). No backfill: the handful of pre-existing NULL tickets predate
-- the picker and cannot be attributed to an office after the fact.

create or replace function public.sync_support_ticket_office()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_office uuid;
begin
  -- 1. A linked booking/trip is authoritative and cannot be forged.
  if new.related_booking_id is not null
     and pg_input_is_valid(new.related_booking_id, 'uuid') then
    select office_id into v_office
      from public.operation_bookings where id = new.related_booking_id::uuid;
  end if;

  if v_office is null and new.related_trip_id is not null then
    select office_id into v_office
      from public.operation_trips where id = new.related_trip_id;
  end if;

  -- 2. No linkage: honour the office the client picked, but only when it is one they
  --    could actually pick — a real, active, listed office in the marketplace surface.
  if v_office is null
     and new.office_id is not null
     and exists (select 1 from public.public_offices where id = new.office_id) then
    v_office := new.office_id;
  end if;

  -- 3. Fall back to the caller's own office (dashboard operators); NULL for a client
  --    with no valid choice — which also discards any client-forged office_id.
  new.office_id := coalesce(v_office, public.current_office_id());
  return new;
end $$;

revoke all on function public.sync_support_ticket_office() from public;
