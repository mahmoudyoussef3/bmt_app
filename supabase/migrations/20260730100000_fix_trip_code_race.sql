-- next_office_trip_code() race condition
-- ─────────────────────────────────────────────────────────────────────────────────────
-- office_create_trip mints a trip code by reading MAX(trip_code) + 1 and then inserting
-- it a moment later, with nothing serializing the two steps. Two office_create_trip
-- calls for the same office landing close together both read the same max, both mint
-- the same 'TR-NNNNN' code, and the second insert dies on
-- uq_operation_trips_office_trip_code. Fix: take a transaction-scoped advisory lock
-- keyed on the office before reading the max, so a concurrent call blocks until the
-- first transaction commits (or rolls back) and then sees the true max.

create or replace function public.next_office_trip_code(p_office_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seq int;
begin
  -- Released automatically at transaction end, so this only serializes the brief
  -- read-then-insert window of a single office_create_trip call, not the whole request.
  perform pg_advisory_xact_lock(
    hashtextextended('next_office_trip_code:' || p_office_id::text, 0)
  );

  select coalesce(max(nullif(regexp_replace(trip_code, '\D', '', 'g'), '')::bigint), 0) + 1
    into v_seq
    from public.operation_trips
   where office_id = p_office_id;

  return 'TR-' || lpad(v_seq::text, 5, '0');
end;
$$;
