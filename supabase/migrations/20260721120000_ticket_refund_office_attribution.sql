-- ═══════════════════════════════════════════════════════════════════════════════════
-- Office attribution for support tickets and refund requests
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Migration 20260721090000 backfilled support_tickets.office_id / refund_requests
-- .office_id once, but nothing stamps NEW rows: the client sends only
-- related_trip_id / related_booking_id (and must never be trusted with an office_id),
-- so every ticket created after the cutover stays office_id NULL. Under
-- support_tickets_office / refund_requests_office RLS (office_id is not null and
-- office_id = current_office_id()) those rows are invisible to the very office they
-- concern, and on_support_ticket_insert / on_refund_request_change pass no
-- trip/booking id in p_data, so push_operational_alert drops their alerts as
-- unattributable.
--
-- Fix, following the sync_*_office() pattern this schema already uses for trips,
-- bookings, payments and reviews:
--   1. BEFORE triggers derive office_id server-side from the row's own linkage.
--      SECURITY DEFINER is load-bearing: clients cannot read operation_trips at all
--      any more, so an invoker-rights lookup would silently resolve to NULL.
--   2. A derived office OVERWRITES anything the caller supplied — a client cannot aim
--      a ticket or refund at an arbitrary office. With no linkage the row belongs to
--      the caller's own office (dashboard operators), or stays platform-level (NULL)
--      for clients — general "the app crashed" tickets remain EWT-support-only by
--      design (decision recorded in MULTI_OFFICE_MIGRATION_AUDIT.md).
--   3. The two alert triggers pass p_office_id explicitly, restoring office-routed
--      operational alerts. push_operational_alert still drops anything without an
--      office, so no unscoped or cross-office alert can be produced.
--   4. Re-run the backfill for linked-but-unattributed rows (covers booking-linked
--      rows the trip-only 090000 backfill skipped, and any rows created since).
--
-- No RLS policy changes. No app-side changes.

-- ── 1. support_tickets ──────────────────────────────────────────────────────────────
-- related_booking_id is TEXT (legacy), so it is matched only when it is a valid uuid.
-- The booking is checked first as the more specific link; its office is itself
-- trigger-derived from the trip, so the two can only disagree if the linkage is bogus.

create or replace function public.sync_support_ticket_office()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_office uuid;
begin
  if new.related_booking_id is not null
     and pg_input_is_valid(new.related_booking_id, 'uuid') then
    select office_id into v_office
      from public.operation_bookings where id = new.related_booking_id::uuid;
  end if;

  if v_office is null and new.related_trip_id is not null then
    select office_id into v_office
      from public.operation_trips where id = new.related_trip_id;
  end if;

  -- Linked rows take the linked office, unconditionally. Unlinked rows belong to the
  -- caller's own office when the caller is an office operator, and to the platform
  -- (NULL) otherwise — which also discards any client-forged office_id.
  new.office_id := coalesce(v_office, public.current_office_id());
  return new;
end $$;

drop trigger if exists trg_support_tickets_office on public.support_tickets;
create trigger trg_support_tickets_office
  before insert or update of related_booking_id, related_trip_id
  on public.support_tickets
  for each row execute function public.sync_support_ticket_office();

revoke all on function public.sync_support_ticket_office() from public;

-- ── 2. refund_requests ──────────────────────────────────────────────────────────────
-- Same shape; the chain is booking → trip → the ticket the refund grew out of.

create or replace function public.sync_refund_request_office()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_office uuid;
begin
  if new.booking_id is not null and pg_input_is_valid(new.booking_id, 'uuid') then
    select office_id into v_office
      from public.operation_bookings where id = new.booking_id::uuid;
  end if;

  if v_office is null and new.trip_id is not null then
    select office_id into v_office
      from public.operation_trips where id = new.trip_id;
  end if;

  if v_office is null and new.ticket_id is not null then
    select office_id into v_office
      from public.support_tickets where id = new.ticket_id;
  end if;

  new.office_id := coalesce(v_office, public.current_office_id());
  return new;
end $$;

drop trigger if exists trg_refund_requests_office on public.refund_requests;
create trigger trg_refund_requests_office
  before insert or update of booking_id, trip_id, ticket_id
  on public.refund_requests
  for each row execute function public.sync_refund_request_office();

revoke all on function public.sync_refund_request_office() from public;

-- ── 3. Route the operational alerts to the owning office ───────────────────────────
-- The BEFORE triggers above have already stamped new.office_id by the time these
-- AFTER triggers fire, so the office is passed explicitly instead of hoping
-- push_operational_alert can rediscover it from p_data. A NULL office (platform-level
-- ticket) is dropped inside push_operational_alert — operational_alerts.office_id is
-- NOT NULL and offices must not see platform tickets. Everything else — titles,
-- priorities, action URLs, the client-facing refund push_notification branch — is
-- byte-identical to 20260706140000.

create or replace function public.on_support_ticket_insert()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.push_operational_alert(
    'support_ticket', 'شكوى/تذكرة جديدة', new.title,
    jsonb_build_object('ticket_id', new.id, 'ticket_number', new.ticket_number),
    case when new.priority in ('high', 'urgent') then 'high' else 'normal' end,
    '/tickets',
    new.office_id);
  return new;
end;
$$;

create or replace function public.on_refund_request_change()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    perform public.push_operational_alert(
      'refund_request', 'طلب استرداد جديد',
      'بقيمة ' || new.amount || ' ' || new.currency || ' — ' || new.reason,
      jsonb_build_object('refund_id', new.id), 'high', '/payments',
      new.office_id);

  elsif tg_op = 'UPDATE' and new.status is distinct from old.status
        and new.status in ('approved', 'rejected') then
    perform public.push_notification(
      new.client_id, 'تحديث على طلب الاسترداد',
      case when new.status = 'approved'
        then 'تمت الموافقة على طلب الاسترداد بقيمة ' || new.amount || ' ' ||
             new.currency || '.'
        else 'تم رفض طلب الاسترداد الخاص بك.'
      end,
      'payment', 'client',
      jsonb_build_object('refund_id', new.id, 'status', new.status), '/support');
  end if;
  return new;
end;
$$;

-- ── 4. Retire the legacy client mutation policies 090200 missed ────────────────────
-- Three pre-office policies survived the 090200 drop lists under their original
-- names. The UPDATE ones matter now: with the re-derivation triggers above, a client
-- who can edit related_trip_id / booking_id on their own row could re-aim a ticket or
-- refund at any office after filing — exactly the vector this migration closes on
-- INSERT. No app updates these tables as the client (the client datasource only
-- inserts and reads; the Paymob functions run as service_role), so nothing loses a
-- capability. Filing and reading stay allowed; the refund INSERT is re-created under
-- the house policy name.

drop policy if exists "Clients can update their own tickets"        on public.support_tickets;
drop policy if exists "Clients can update their own refund requests" on public.refund_requests;
drop policy if exists "Clients can view their own refund requests"   on public.refund_requests;

drop policy if exists "Clients can insert their own refund requests" on public.refund_requests;
drop policy if exists refund_requests_client_insert on public.refund_requests;
create policy refund_requests_client_insert on public.refund_requests
  for insert to authenticated
  with check (client_id = auth.uid());

-- ── 5. Backfill rows the one-shot 090000 pass could not attribute ──────────────────
-- 090000 derived support_tickets only through related_trip_id and refund_requests
-- only through trip_id; booking-linked rows and anything inserted since the cutover
-- are still NULL. Platform-level rows (no linkage at all) are left exactly as they
-- are.

update public.support_tickets t
   set office_id = b.office_id
  from public.operation_bookings b
 where t.office_id is null
   and t.related_booking_id is not null
   and pg_input_is_valid(t.related_booking_id, 'uuid')
   and b.id = t.related_booking_id::uuid;

update public.support_tickets t
   set office_id = tr.office_id
  from public.operation_trips tr
 where t.office_id is null
   and t.related_trip_id is not null
   and tr.id = t.related_trip_id;

update public.refund_requests r
   set office_id = b.office_id
  from public.operation_bookings b
 where r.office_id is null
   and r.booking_id is not null
   and pg_input_is_valid(r.booking_id, 'uuid')
   and b.id = r.booking_id::uuid;

update public.refund_requests r
   set office_id = tr.office_id
  from public.operation_trips tr
 where r.office_id is null
   and r.trip_id is not null
   and tr.id = r.trip_id;

update public.refund_requests r
   set office_id = t.office_id
  from public.support_tickets t
 where r.office_id is null
   and r.ticket_id is not null
   and t.id = r.ticket_id
   and t.office_id is not null;
