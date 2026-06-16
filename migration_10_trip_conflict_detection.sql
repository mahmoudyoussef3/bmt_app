-- migration_10_trip_conflict_detection.sql
-- Adds driver and vehicle conflict detection to the create_trip RPC.
-- Returns a structured conflict error instead of inserting a duplicate trip.

CREATE OR REPLACE FUNCTION public.create_trip(
  p_trip_code          text,
  p_route_id           uuid,
  p_driver_id          uuid,
  p_vehicle_id         uuid,
  p_trip_date          date,
  p_departure_time     time,
  p_arrival_time       time,
  p_capacity           int,
  p_ticket_price       numeric,
  p_currency           text,
  p_notes              text[],
  p_route_points       jsonb,
  p_seats              jsonb
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_trip_id              uuid;
  v_conflict_driver_trip uuid;
  v_conflict_vehicle_trip uuid;
BEGIN
  -- Validate inputs
  IF p_capacity <= 0 THEN
    RAISE EXCEPTION 'invalid_capacity: Capacity must be greater than 0';
  END IF;

  IF jsonb_array_length(p_route_points) = 0 THEN
    RAISE EXCEPTION 'no_route_points: Route must have at least one station';
  END IF;

  -- Check driver conflict: same driver, same date, not cancelled
  SELECT id INTO v_conflict_driver_trip
  FROM public.operation_trips
  WHERE driver_id  = p_driver_id
    AND trip_date  = p_trip_date
    AND status    != 'cancelled'
  LIMIT 1;

  IF v_conflict_driver_trip IS NOT NULL THEN
    RAISE EXCEPTION 'driver_conflict: Driver already has a trip scheduled on % (trip_id: %)',
      p_trip_date, v_conflict_driver_trip;
  END IF;

  -- Check vehicle conflict: same vehicle, same date, not cancelled
  SELECT id INTO v_conflict_vehicle_trip
  FROM public.operation_trips
  WHERE vehicle_id = p_vehicle_id
    AND trip_date  = p_trip_date
    AND status    != 'cancelled'
  LIMIT 1;

  IF v_conflict_vehicle_trip IS NOT NULL THEN
    RAISE EXCEPTION 'vehicle_conflict: Vehicle already has a trip scheduled on % (trip_id: %)',
      p_trip_date, v_conflict_vehicle_trip;
  END IF;

  -- 1. Insert trip record
  INSERT INTO public.operation_trips (
    trip_code, route_id, driver_id, vehicle_id,
    trip_date, departure_time, arrival_time,
    capacity, ticket_price, currency, notes, status
  ) VALUES (
    p_trip_code, p_route_id, p_driver_id, p_vehicle_id,
    p_trip_date, p_departure_time, p_arrival_time,
    p_capacity, p_ticket_price, p_currency, p_notes, 'scheduled'
  )
  RETURNING id INTO v_trip_id;

  -- 2. Insert route point snapshot
  INSERT INTO public.trip_route_points (
    trip_id, route_point_id, point_name, point_order,
    arrival_offset, departure_offset, latitude, longitude
  )
  SELECT
    v_trip_id,
    (rp->>'route_point_id')::uuid,
    rp->>'point_name',
    (rp->>'point_order')::int,
    COALESCE(rp->>'arrival_offset', ''),
    COALESCE(rp->>'departure_offset', ''),
    NULLIF(rp->>'latitude',  '')::double precision,
    NULLIF(rp->>'longitude', '')::double precision
  FROM jsonb_array_elements(p_route_points) AS rp;

  -- 3. Insert seat inventory
  INSERT INTO public.trip_seats (trip_id, seat_label, seat_row, seat_column, state)
  SELECT
    v_trip_id,
    s->>'seat_label',
    (s->>'seat_row')::int,
    (s->>'seat_column')::int,
    'available'
  FROM jsonb_array_elements(p_seats) AS s;

  -- 4. Log creation event
  INSERT INTO public.trip_events (trip_id, title, description, done)
  VALUES (
    v_trip_id,
    'إنشاء الرحلة',
    'تم إنشاء الرحلة وتهيئة المقاعد والمحطات تلقائياً',
    true
  );

  RETURN jsonb_build_object(
    'success', true,
    'trip_id', v_trip_id,
    'trip_code', p_trip_code,
    'seats_created', jsonb_array_length(p_seats),
    'stations_created', jsonb_array_length(p_route_points)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_trip(text, uuid, uuid, uuid, date, time, time, int, numeric, text, text[], jsonb, jsonb) TO authenticated;
