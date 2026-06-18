-- migration_13_open_for_booking_status.sql
-- Adds 'open_for_booking' as a distinct trip status, separate from 'scheduled'.
--
-- Before this migration:
--   scheduled   = trip exists but is NOT yet open to clients (pricing may be incomplete)
--   openForBooking was a Flutter-only concept mapped to 'scheduled' in DB
--
-- After this migration:
--   scheduled        = trip created, pricing/config in progress — NOT visible to clients
--   open_for_booking = explicitly published by ops — visible and bookable by clients
--   boarding         = driver started boarding — no new bookings accepted
--   in_progress      = trip moving
--   completed        = terminal
--   cancelled        = terminal

-- ---------------------------------------------------------------------------
-- 1. Update RLS on operation_trips
--    Clients should only see 'open_for_booking', 'boarding', 'in_progress', 'completed'
--    NOT 'scheduled' (that is an internal ops state)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Clients can read scheduled/boarding/in_progress trips" ON public.operation_trips;

CREATE POLICY "Clients can read bookable/active trips" ON public.operation_trips
  FOR SELECT USING (
    status IN ('open_for_booking', 'boarding', 'in_progress', 'completed')
    OR public.has_role('operations_manager')
    OR public.has_role('dashboard_admin')
    OR public.has_role('finance_agent')
    OR public.has_role('support_agent')
  );

-- Drivers can still see their assigned trips regardless of status
CREATE POLICY "Drivers can read their assigned trips" ON public.operation_trips
  FOR SELECT USING (
    driver_id = (
      SELECT d.id FROM public.drivers d WHERE d.user_id = auth.uid() LIMIT 1
    )
  );

-- ---------------------------------------------------------------------------
-- 2. Update update_trip_status RPC to include open_for_booking in the
--    transition machine and stamp actual_start_time on boarding (not in_progress)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_trip_status(
  p_trip_id    uuid,
  p_new_status text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_current_status  text;
  v_allowed         boolean := false;
BEGIN
  SELECT status INTO v_current_status
  FROM public.operation_trips
  WHERE id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trip_not_found: Trip does not exist';
  END IF;

  -- Validate allowed transitions
  -- scheduled → open_for_booking (publish): ops publishes the trip to clients
  -- open_for_booking → boarding: driver starts boarding, or ops force-starts
  -- open_for_booking → cancelled: ops cancels before boarding
  -- boarding → in_progress: driver starts the trip
  -- boarding → cancelled: admin emergency cancel
  -- in_progress → completed: driver ends the trip
  -- in_progress → cancelled: admin emergency only
  -- scheduled → cancelled: ops cancels before publishing
  IF (v_current_status = 'scheduled'        AND p_new_status IN ('open_for_booking', 'cancelled')) OR
     (v_current_status = 'open_for_booking' AND p_new_status IN ('boarding', 'cancelled')) OR
     (v_current_status = 'boarding'         AND p_new_status IN ('in_progress', 'cancelled')) OR
     (v_current_status = 'in_progress'      AND p_new_status IN ('completed', 'cancelled'))
  THEN
    v_allowed := true;
  END IF;

  IF NOT v_allowed THEN
    RAISE EXCEPTION 'invalid_transition: Cannot transition trip from % to %',
      v_current_status, p_new_status;
  END IF;

  -- Apply the status change and stamp actual times
  UPDATE public.operation_trips
  SET
    status            = p_new_status,
    updated_at        = now(),
    -- Record boarding start when driver begins accepting passengers
    actual_start_time = CASE
      WHEN p_new_status = 'boarding' AND actual_start_time IS NULL THEN now()
      ELSE actual_start_time
    END,
    -- Record end time when trip completes or is cancelled after starting
    actual_end_time   = CASE
      WHEN p_new_status IN ('completed', 'cancelled') AND actual_start_time IS NOT NULL THEN now()
      ELSE actual_end_time
    END
  WHERE id = p_trip_id;

  -- Log the transition as a trip event
  INSERT INTO public.trip_events (trip_id, title, description, done)
  VALUES (
    p_trip_id,
    CASE p_new_status
      WHEN 'open_for_booking' THEN 'فتح الحجز'
      WHEN 'boarding'         THEN 'بدء التجميع'
      WHEN 'in_progress'      THEN 'انطلاق الرحلة'
      WHEN 'completed'        THEN 'اكتمال الرحلة'
      WHEN 'cancelled'        THEN 'إلغاء الرحلة'
      ELSE p_new_status
    END,
    'تم تغيير حالة الرحلة إلى: ' || p_new_status,
    true
  );

  -- On completion: mark remaining unboarded passengers as no_show
  IF p_new_status = 'completed' THEN
    UPDATE public.trip_passengers
    SET status = 'no_show', updated_at = now()
    WHERE trip_id = p_trip_id
      AND status NOT IN ('confirmed', 'cancelled', 'no_show', 'completed');
  END IF;

  -- On cancellation: release all locked seats and cancel all open bookings
  IF p_new_status = 'cancelled' THEN
    UPDATE public.trip_seats
    SET state = 'available', passenger_id = NULL
    WHERE trip_id = p_trip_id
      AND state NOT IN ('available', 'blocked');

    UPDATE public.operation_bookings
    SET status = 'cancelled', updated_at = now()
    WHERE trip_id = p_trip_id
      AND status NOT IN ('cancelled', 'rejected');
  END IF;

  RETURN jsonb_build_object(
    'success',           true,
    'trip_id',           p_trip_id,
    'previous_status',   v_current_status,
    'new_status',        p_new_status,
    'actual_start_time', (SELECT actual_start_time FROM public.operation_trips WHERE id = p_trip_id),
    'actual_end_time',   (SELECT actual_end_time   FROM public.operation_trips WHERE id = p_trip_id)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_trip_status(uuid, text) TO authenticated;

-- ---------------------------------------------------------------------------
-- 3. Update the trip search index to include open_for_booking
-- ---------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_operation_trips_date_status_route;
CREATE INDEX idx_operation_trips_date_status_route
  ON public.operation_trips(trip_date, status, route_id, departure_time)
  WHERE status IN ('open_for_booking', 'boarding', 'in_progress');

-- ---------------------------------------------------------------------------
-- 4. Update conflict detection index
-- ---------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_trips_driver_date_status;
CREATE INDEX idx_trips_driver_date_status
  ON public.operation_trips(driver_id, trip_date, status)
  WHERE status IN ('scheduled', 'open_for_booking', 'boarding', 'in_progress');

-- ---------------------------------------------------------------------------
-- 5. Add check constraint to prevent subscriptions in pendingPayment
--    from being used for booking (enforced in lock_trip_seat RPC)
-- ---------------------------------------------------------------------------
-- Note: The book_trip_seat RPC in migration_07 uses payment_method = 'subscription'
-- path. Add validation there. This migration adds a helper function.
CREATE OR REPLACE FUNCTION public.validate_subscription_for_booking(
  p_subscription_id uuid
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.subscriptions
    WHERE id = p_subscription_id
      AND status = 'active'
      AND start_date <= current_date
      AND end_date >= current_date
  );
$$;

GRANT EXECUTE ON FUNCTION public.validate_subscription_for_booking(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 6. Backfill: existing 'scheduled' trips that have pricing → open_for_booking
--    (Run only if you want to publish existing trips with pricing configured)
-- ---------------------------------------------------------------------------
-- UPDATE public.operation_trips
-- SET status = 'open_for_booking'
-- WHERE status = 'scheduled'
--   AND id IN (SELECT DISTINCT trip_id FROM public.trip_pricing WHERE is_active = true)
--   AND trip_date >= current_date;
-- Commented out — run manually after reviewing which trips should be published.
