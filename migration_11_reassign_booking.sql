-- Migration 11: Booking reassignment RPC
-- Atomically moves a booking from one trip to another

CREATE OR REPLACE FUNCTION public.reassign_booking(
  p_booking_id uuid,
  p_new_trip_id uuid,
  p_new_seat_label text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_old_trip_id   uuid;
  v_old_seat_id   uuid;
  v_new_seat_id   uuid;
  v_capacity      int;
  v_booked_count  int;
BEGIN
  -- Fetch current booking info
  SELECT trip_id, seat_id
  INTO v_old_trip_id, v_old_seat_id
  FROM public.operation_bookings
  WHERE id = p_booking_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_not_found: Booking % does not exist', p_booking_id;
  END IF;

  IF v_old_trip_id = p_new_trip_id THEN
    RAISE EXCEPTION 'same_trip: Booking is already on this trip';
  END IF;

  -- Check new trip capacity
  SELECT v.capacity INTO v_capacity
  FROM public.operation_trips t
  JOIN public.vehicles v ON v.id = t.vehicle_id
  WHERE t.id = p_new_trip_id;

  SELECT COUNT(*) INTO v_booked_count
  FROM public.operation_bookings
  WHERE trip_id = p_new_trip_id
    AND status NOT IN ('cancelled', 'rejected');

  IF v_booked_count >= v_capacity THEN
    RAISE EXCEPTION 'trip_full: New trip has reached capacity (%)', v_capacity;
  END IF;

  -- Release old seat if exists
  IF v_old_seat_id IS NOT NULL THEN
    UPDATE public.trip_seats
    SET status = 'available'
    WHERE id = v_old_seat_id;
  END IF;

  -- Assign new seat if label provided
  IF p_new_seat_label IS NOT NULL THEN
    SELECT id INTO v_new_seat_id
    FROM public.trip_seats
    WHERE trip_id = p_new_trip_id
      AND seat_label = p_new_seat_label
      AND status = 'available'
    LIMIT 1;

    IF v_new_seat_id IS NOT NULL THEN
      UPDATE public.trip_seats
      SET status = 'booked'
      WHERE id = v_new_seat_id;
    END IF;
  END IF;

  -- Update the booking
  UPDATE public.operation_bookings
  SET trip_id   = p_new_trip_id,
      seat_id   = COALESCE(v_new_seat_id, NULL),
      seat_label = COALESCE(p_new_seat_label, seat_label),
      timeline  = COALESCE(timeline, '[]'::jsonb) || jsonb_build_object(
        'action', 'reassigned',
        'timestamp', now()::text,
        'actor', 'operations'
      )
  WHERE id = p_booking_id;

  RETURN json_build_object('success', true, 'new_trip_id', p_new_trip_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.reassign_booking TO authenticated;
