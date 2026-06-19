-- migration_14_operation_trips_status_check.sql
-- Allows the distinct 'open_for_booking' trip lifecycle state in the
-- operation_trips.status check constraint.

ALTER TABLE public.operation_trips
  DROP CONSTRAINT IF EXISTS operation_trips_status_check;

ALTER TABLE public.operation_trips
  ADD CONSTRAINT operation_trips_status_check
  CHECK (
    status IN (
      'scheduled',
      'open_for_booking',
      'boarding',
      'in_progress',
      'completed',
      'cancelled'
    )
  );
