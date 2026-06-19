-- Migration 15: Booking Integrity Constraints
-- Adds a unique constraint to prevent two active bookings from referencing the
-- same seat on the same trip, backing up the seat-state-machine RPC at the DB level.

-- ============================================================================
-- 1. UNIQUE CONSTRAINT: one active booking per seat per trip
-- ============================================================================
-- The seat-lock RPC (lock_trip_seat) serialises concurrent attempts correctly,
-- but if any code path inserts a booking outside that RPC the DB would silently
-- allow duplicate seat ownership. This partial unique index prevents that.

CREATE UNIQUE INDEX IF NOT EXISTS uniq_active_booking_per_seat
  ON public.operation_bookings (trip_id, seat_id)
  WHERE status NOT IN ('cancelled', 'rejected');

-- ============================================================================
-- 2. UNIQUE CONSTRAINT: one active booking per trip+seat_label (fallback)
-- ============================================================================
-- seat_id can be null on legacy rows that pre-date the seat-id FK.
-- Guard the seat label string as a secondary defence.

CREATE UNIQUE INDEX IF NOT EXISTS uniq_active_booking_per_seat_label
  ON public.operation_bookings (trip_id, seat)
  WHERE status NOT IN ('cancelled', 'rejected') AND seat IS NOT NULL;

-- ============================================================================
-- 3. ROUTE NULLABILITY NOTE (no DDL change — informational)
-- ============================================================================
-- operation_trips.route_id is currently NULLABLE with ON DELETE SET NULL.
-- Enforcing NOT NULL here would require a data backfill first.
-- Recommended follow-up:
--   UPDATE operation_trips SET route_id = <default_route> WHERE route_id IS NULL;
--   ALTER TABLE operation_trips ALTER COLUMN route_id SET NOT NULL;

-- ============================================================================
-- 4. VERIFY pg_cron IS ENABLED
-- ============================================================================
-- The seat-lock expiry (FLOW 9 in SYSTEM_FLOW.md) depends on pg_cron running
-- every 5 minutes to release expired reservations.
-- Run the following on the Supabase dashboard to verify:
--
--   SELECT * FROM pg_extension WHERE extname = 'pg_cron';
--
-- If the result is empty, enable pg_cron in the Supabase dashboard under
-- Database → Extensions → pg_cron, then apply migration_07 again or
-- manually re-create the cron job:
--
--   SELECT cron.schedule(
--     'release-expired-seat-locks',
--     '*/5 * * * *',
--     $$
--       UPDATE public.trip_seats
--         SET state = 'available', passenger_id = null, lock_expires_at = null
--       WHERE state = 'reserved' AND lock_expires_at < now();
--
--       UPDATE public.operation_bookings
--         SET status = 'cancelled'
--       WHERE status = 'newRequest'
--         AND seat_id IN (
--           SELECT id FROM public.trip_seats
--           WHERE state = 'available' AND lock_expires_at < now()
--         );
--     $$
--   );
