-- Migration 16: Remove VIP Priority from Bookings
-- The platform has no VIP seat tier — all seats are standard.
-- This migration downgrades any existing 'vip' priority rows to 'normal'
-- and tightens the check constraint to prevent future insertion.

-- 1. Backfill: convert any existing vip rows to normal
UPDATE public.operation_bookings
  SET priority = 'normal'
  WHERE priority = 'vip';

-- 2. Drop old check constraint (name may vary; use pg_constraint to find it)
DO $$
DECLARE
  con_name text;
BEGIN
  SELECT conname INTO con_name
  FROM pg_constraint
  WHERE conrelid = 'public.operation_bookings'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%vip%';

  IF con_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.operation_bookings DROP CONSTRAINT %I', con_name);
  END IF;
END;
$$;

-- 3. Add tightened constraint: only normal and urgent
ALTER TABLE public.operation_bookings
  ADD CONSTRAINT operation_bookings_priority_check
  CHECK (priority IN ('normal', 'urgent'));
