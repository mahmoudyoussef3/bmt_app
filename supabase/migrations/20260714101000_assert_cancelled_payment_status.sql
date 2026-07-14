-- ---------------------------------------------------------------------------
-- Guarantee 'cancelled' is actually a writable payment status.
--
-- The previous migration dropped `operation_bookings_payment_status_check` by
-- name before recreating it, and Postgres reported that no such constraint
-- existed. That is a warning sign, not a success: it means the original CHECK
-- (added inline with the column) may be living under a different name and would
-- still reject 'cancelled' on write — cancel_booking_by_client would fail at
-- the UPDATE, in production, with the seat still held.
--
-- So: find the check constraints on these columns by their *column*, not their
-- name, drop any that predate 'cancelled', and then assert the end state. If
-- this migration applies cleanly, the value is genuinely writable.
-- ---------------------------------------------------------------------------

do $$
declare
  v_con record;
begin
  for v_con in
    select con.conname
    from   pg_constraint con
    join   pg_class rel on rel.oid = con.conrelid
    join   pg_namespace ns on ns.oid = rel.relnamespace
    where  ns.nspname = 'public'
      and  rel.relname = 'operation_bookings'
      and  con.contype = 'c'
      and  exists (
             select 1 from pg_attribute a
             where a.attrelid = con.conrelid
               and a.attnum = any (con.conkey)
               and a.attname = 'payment_status'
           )
      and  pg_get_constraintdef(con.oid) not ilike '%cancelled%'
  loop
    raise notice 'dropping stale payment_status constraint %', v_con.conname;
    execute format(
      'alter table public.operation_bookings drop constraint %I', v_con.conname
    );
  end loop;
end $$;

-- Re-assert the canonical constraint (no-op when the earlier migration's
-- version is already in place).
alter table public.operation_bookings
  drop constraint if exists operation_bookings_payment_status_check;
alter table public.operation_bookings
  add constraint operation_bookings_payment_status_check check (
    payment_status in (
      'pending', 'submitted', 'underReview', 'approved',
      'rejected', 'refunded', 'failed', 'cancelled'
    )
  );

-- The assertion. Any surviving CHECK on operation_bookings.payment_status that
-- does not mention 'cancelled' would veto the write, so fail the push loudly
-- rather than ship a cancel button that dies on the UPDATE.
do $$
declare
  v_blocking text;
begin
  select string_agg(con.conname, ', ')
  into   v_blocking
  from   pg_constraint con
  join   pg_class rel on rel.oid = con.conrelid
  join   pg_namespace ns on ns.oid = rel.relnamespace
  where  ns.nspname = 'public'
    and  rel.relname = 'operation_bookings'
    and  con.contype = 'c'
    and  exists (
           select 1 from pg_attribute a
           where a.attrelid = con.conrelid
             and a.attnum = any (con.conkey)
             and a.attname = 'payment_status'
         )
    and  pg_get_constraintdef(con.oid) not ilike '%cancelled%';

  if v_blocking is not null then
    raise exception
      'payment_status cannot be set to cancelled; blocked by: %', v_blocking;
  end if;

  raise notice 'verified: operation_bookings.payment_status accepts cancelled';
end $$;
