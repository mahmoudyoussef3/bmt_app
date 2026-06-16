-- migration_09_actual_timing.sql
-- Adds actual_start_time and actual_end_time to operation_trips.
-- Updates update_trip_status RPC to record these timestamps automatically.

-- ---------------------------------------------------------------------------
-- 1. Add columns
-- ---------------------------------------------------------------------------
ALTER TABLE public.operation_trips
  ADD COLUMN IF NOT EXISTS actual_start_time timestamptz,
  ADD COLUMN IF NOT EXISTS actual_end_time   timestamptz;

-- ---------------------------------------------------------------------------
-- 2. Replace update_trip_status RPC to stamp actual times on transitions
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_trip_status(
  p_trip_id    uuid,
  p_new_status text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_current_status text;
  v_allowed        boolean := false;
BEGIN
  SELECT status INTO v_current_status
  FROM public.operation_trips
  WHERE id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trip_not_found: Trip does not exist';
  END IF;

  -- Validate allowed transitions
  IF (v_current_status = 'scheduled'   AND p_new_status IN ('boarding', 'cancelled')) OR
     (v_current_status = 'boarding'    AND p_new_status IN ('in_progress', 'cancelled')) OR
     (v_current_status = 'in_progress' AND p_new_status IN ('completed', 'cancelled'))
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
    status           = p_new_status,
    updated_at       = now(),
    actual_start_time = CASE
      WHEN p_new_status = 'in_progress' AND actual_start_time IS NULL
        THEN now()
      ELSE actual_start_time
    END,
    actual_end_time  = CASE
      WHEN p_new_status IN ('completed', 'cancelled')
        THEN now()
      ELSE actual_end_time
    END
  WHERE id = p_trip_id;

  -- Log the event
  INSERT INTO public.trip_events (trip_id, title, description, done)
  VALUES (
    p_trip_id,
    CASE p_new_status
      WHEN 'boarding'    THEN 'بدء التجميع'
      WHEN 'in_progress' THEN 'انطلاق الرحلة'
      WHEN 'completed'   THEN 'اكتمال الرحلة'
      WHEN 'cancelled'   THEN 'إلغاء الرحلة'
      ELSE p_new_status
    END,
    'تم تغيير حالة الرحلة إلى: ' || p_new_status,
    true
  );

  -- On completion: mark remaining unchecked passengers as no_show
  IF p_new_status = 'completed' THEN
    UPDATE public.trip_passengers
    SET status = 'no_show', updated_at = now()
    WHERE trip_id = p_trip_id
      AND status NOT IN ('confirmed', 'cancelled', 'no_show', 'completed');
  END IF;

  RETURN jsonb_build_object(
    'success',          true,
    'trip_id',          p_trip_id,
    'previous_status',  v_current_status,
    'new_status',       p_new_status,
    'actual_start_time', (SELECT actual_start_time FROM public.operation_trips WHERE id = p_trip_id),
    'actual_end_time',   (SELECT actual_end_time   FROM public.operation_trips WHERE id = p_trip_id)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_trip_status(uuid, text) TO authenticated;
