-- migration_14_fleet_single_active_assignment.sql
-- Enforces the redesigned Fleet rule: a vehicle requires a driver at creation
-- and is reassignable, with at most ONE active assignment per vehicle and per
-- driver at any time.
--
-- Background:
--   The dashboard Fleet module was redesigned so that a driver is assigned to a
--   vehicle during vehicle creation (and can be changed later). Reassignment
--   ends the old assignment (status='ended') and inserts a new active one.
--   This migration backs that rule at the database level with partial unique
--   indexes, so concurrent or buggy writes can never produce two simultaneous
--   active assignments for the same vehicle or driver.
--
-- This is index-only: no columns are added or dropped, and no NOT NULL hard
-- constraint is introduced (the "driver required" rule is enforced in the UI,
-- per the agreed design — keeping reassignment and edge cases flexible).

-- ---------------------------------------------------------------------------
-- 0. Pre-flight: resolve any existing duplicate active assignments FIRST.
--    The unique indexes below will FAIL to create if duplicates already exist.
--    Review these queries and reconcile before (or instead of) the auto-fix.
-- ---------------------------------------------------------------------------
-- Inspect duplicates (run manually first):
--   SELECT vehicle_id, count(*) FROM public.assignments
--   WHERE status = 'active' GROUP BY vehicle_id HAVING count(*) > 1;
--   SELECT driver_id, count(*) FROM public.assignments
--   WHERE status = 'active' GROUP BY driver_id HAVING count(*) > 1;
--
-- Optional auto-fix: keep only the most recent active assignment per vehicle
-- and per driver, ending the older ones. Uncomment to apply.
--
-- WITH ranked AS (
--   SELECT id,
--          row_number() OVER (
--            PARTITION BY vehicle_id ORDER BY assigned_at DESC, created_at DESC
--          ) AS rn
--   FROM public.assignments
--   WHERE status = 'active'
-- )
-- UPDATE public.assignments a
-- SET status = 'ended', ended_at = now(), updated_at = now()
-- FROM ranked r
-- WHERE a.id = r.id AND r.rn > 1;
--
-- WITH ranked AS (
--   SELECT id,
--          row_number() OVER (
--            PARTITION BY driver_id ORDER BY assigned_at DESC, created_at DESC
--          ) AS rn
--   FROM public.assignments
--   WHERE status = 'active'
-- )
-- UPDATE public.assignments a
-- SET status = 'ended', ended_at = now(), updated_at = now()
-- FROM ranked r
-- WHERE a.id = r.id AND r.rn > 1;

-- ---------------------------------------------------------------------------
-- 1. At most one ACTIVE assignment per vehicle.
-- ---------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS uniq_active_assignment_per_vehicle
  ON public.assignments (vehicle_id)
  WHERE status = 'active';

-- ---------------------------------------------------------------------------
-- 2. At most one ACTIVE assignment per driver.
-- ---------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS uniq_active_assignment_per_driver
  ON public.assignments (driver_id)
  WHERE status = 'active';
