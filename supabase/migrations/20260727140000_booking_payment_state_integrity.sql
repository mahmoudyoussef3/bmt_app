-- ═══════════════════════════════════════════════════════════════════════════════════
-- Booking & payment state integrity
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Phase 2 of the Dashboard Re-Ownership Program. Three defects found auditing the
-- booking/payment surface against the live database on 2026-07-27.
--
-- 1. `payment_review_status` DRIFTS FROM `payment_status`
--    `operation_bookings` carries two columns modelling one fact — "has the desk looked
--    at this payment?". `payment_review_status` is entirely derivable from
--    `payment_status`:
--        approved | rejected  -> reviewed
--        underReview          -> under_review
--        anything else        -> pending
--    Every RPC that touches one sets the other by hand, so they agree *only* as long as
--    every future writer remembers. Two live rows already disagree
--    (payment_status='approved' with payment_review_status='pending', and reviewed_at
--    null — i.e. rows written directly rather than through approve_payment).
--
--    The fix is to stop asking writers to remember: a BEFORE trigger derives the column.
--    Every existing RPC keeps working unchanged — their explicit assignments now simply
--    agree with what the trigger would compute.
--
-- 2. CANCELLED BOOKINGS WITH NO `cancelled_at`
--    Three live rows are `status='cancelled'` with `cancelled_at` null, so there is no
--    record of when the seat was released. The same trigger stamps it.
--
-- 3. NO GUARD AGAINST PAID-BUT-CANCELLED
--    Nothing prevents a booking being cancelled while its payment stays 'approved',
--    which means the office holds a passenger's money for a released seat. This is the
--    single most dispute-prone state in a cash-heavy market. A CHECK constraint would be
--    wrong here — the state must remain *representable* so a refund can be processed
--    through it — so this migration adds detection (a view the dashboard and any future
--    report can read) rather than prohibition.
--
-- No RLS policy, grant, or office boundary is altered by this migration.

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. Derive payment_review_status; stamp cancelled_at
-- ───────────────────────────────────────────────────────────────────────────────────

create or replace function public.sync_booking_payment_review_status()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  -- Single source of truth: payment_status. Writers may still set
  -- payment_review_status explicitly; this overwrites it with the derived value, so
  -- the two can no longer disagree regardless of who wrote the row.
  new.payment_review_status := case
    when new.payment_status in ('approved', 'rejected') then 'reviewed'
    when new.payment_status = 'underReview'             then 'under_review'
    else 'pending'
  end;

  -- A cancellation without a timestamp cannot be audited. Only stamped on the
  -- transition into 'cancelled', and never overwritten, so a re-save of an already
  -- cancelled booking keeps the original moment.
  if new.status = 'cancelled' and new.cancelled_at is null then
    new.cancelled_at := now();
  end if;

  return new;
end;
$$;

comment on function public.sync_booking_payment_review_status() is
  'Keeps operation_bookings.payment_review_status derived from payment_status, and '
  'stamps cancelled_at on cancellation. Added 20260727140000 after two live rows were '
  'found with the two status columns disagreeing.';

drop trigger if exists trg_sync_booking_payment_review_status on public.operation_bookings;
create trigger trg_sync_booking_payment_review_status
  before insert or update on public.operation_bookings
  for each row
  execute function public.sync_booking_payment_review_status();

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. Reconcile the rows that already drifted
-- ───────────────────────────────────────────────────────────────────────────────────
-- payment_review_status is *derived*, so correcting it invents nothing — it recomputes
-- a value that was always a function of payment_status.

update public.operation_bookings
set payment_review_status = case
      when payment_status in ('approved', 'rejected') then 'reviewed'
      when payment_status = 'underReview'             then 'under_review'
      else 'pending'
    end
where payment_review_status is distinct from case
      when payment_status in ('approved', 'rejected') then 'reviewed'
      when payment_status = 'underReview'             then 'under_review'
      else 'pending'
    end;

-- cancelled_at is NOT derivable, so it is not fabricated. `updated_at` is used because
-- for an already-cancelled booking the cancellation *is* the last change the row saw,
-- which makes it a defensible record rather than an invented one. Rows cancelled from
-- this migration onward get an exact timestamp from the trigger above.
update public.operation_bookings
set cancelled_at = updated_at
where status = 'cancelled' and cancelled_at is null;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. Contradiction detection
-- ───────────────────────────────────────────────────────────────────────────────────
-- Mirrors `detectBookingIssues` in
-- `lib/apps/dashboard/features/bookings/domain/entities/booking_lifecycle.dart`.
-- The Dart side explains a single booking to an operator; this view answers "how many
-- are wrong right now, across the office" for monitoring and reporting.

create or replace view public.booking_state_contradictions as
select
  b.id            as booking_id,
  b.office_id,
  b.booking_number,
  b.status,
  b.payment_status,
  b.payment_amount,
  b.trip_id,
  b.created_at,
  case
    when b.status = 'cancelled' and b.payment_status = 'approved'
      then 'paid_but_cancelled'
    when b.status = 'confirmed' and b.payment_status <> 'approved'
      then 'confirmed_without_payment'
    when b.status in ('boarded', 'completed')
         and b.payment_status in ('pending', 'rejected', 'failed')
      then 'travelled_without_payment'
    when b.status = 'completed' and b.payment_status = 'refunded'
      then 'completed_but_refunded'
  end as issue_code,
  case
    when b.status = 'completed' and b.payment_status = 'refunded' then 'warning'
    else 'critical'
  end as severity
from public.operation_bookings b
where (b.status = 'cancelled' and b.payment_status = 'approved')
   or (b.status = 'confirmed' and b.payment_status <> 'approved')
   or (b.status in ('boarded', 'completed')
       and b.payment_status in ('pending', 'rejected', 'failed'))
   or (b.status = 'completed' and b.payment_status = 'refunded');

comment on view public.booking_state_contradictions is
  'Bookings whose booking state and payment state contradict each other. Office-scoped '
  'by the underlying operation_bookings RLS — the view is security_invoker so a caller '
  'sees only their own office''s rows.';

-- security_invoker is what keeps this office-scoped: without it the view would run as
-- its owner and bypass the RLS on operation_bookings entirely.
alter view public.booking_state_contradictions set (security_invoker = on);

-- This database carries a default grant that hands `authenticated` ALL privileges on new
-- relations. A single-table view is updatable in Postgres, so without the explicit revoke
-- below an operator could UPDATE operation_bookings *through* this diagnostic view —
-- bypassing the RPC discipline (`approve_payment` and friends) that keeps seats,
-- passengers, payments and notifications consistent. RLS would still confine them to
-- their own office, but "their own office, incoherently" is exactly what Phase 2 exists
-- to prevent. Revoke first, then grant back only SELECT.
revoke all on public.booking_state_contradictions from public, anon, authenticated;
grant select on public.booking_state_contradictions to authenticated;
