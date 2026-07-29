-- next_office_trip_code() lpad truncation
-- ─────────────────────────────────────────────────────────────────────────────────────
-- lpad(string, length, fill) TRUNCATES the input when it is already longer than length
-- (keeping only its leftmost `length` characters) — it does not skip padding and leave
-- the value alone. next_office_trip_code always calls lpad(v_seq::text, 5, '0'), which
-- is only safe while v_seq stays under 100000.
--
-- Every office seeded with legacy 'TR-<millis>'-derived codes has trip_code digit
-- sequences well past 5 digits. Confirmed live against office
-- 00000000-0000-0000-0000-0000000000e0: its highest trip_code digit sequence is 960360,
-- so next_office_trip_code computes v_seq = 960361, lpad chops it down to '96036', and
-- the insert collides with the pre-existing 'TR-96036' row every single time. Trip
-- creation was unconditionally broken for that office — not a race, not a one-off,
-- reproduced deterministically on every call.
--
-- Fix: pad to the greater of 5 and the number's own length, so short sequences still
-- get zero-padded to 5 digits and sequences that are already wider are left intact.

create or replace function public.next_office_trip_code(p_office_id uuid)
returns text
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_seq    int;
  v_digits text;
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

  v_digits := v_seq::text;
  return 'TR-' || lpad(v_digits, greatest(length(v_digits), 5), '0');
end;
$$;
