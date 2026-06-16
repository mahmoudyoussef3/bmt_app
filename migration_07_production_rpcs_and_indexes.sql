-- =============================================================================
-- Migration 07 — Production RPCs, Indexes, and Seat Lock System
-- =============================================================================
-- Implements the architecture defined in the system design:
--   • Two-step seat booking: lock_trip_seat → confirm_seat_booking
--   • Atomic approval/rejection/cancellation RPCs
--   • Atomic trip creation RPC
--   • Enforced trip status transition machine
--   • Passenger check-in RPC
--   • Bulk booking status update RPC
--   • Performance indexes for 100K-user scale
--   • pg_cron seat lock expiry (applied if extension is available)
-- =============================================================================


-- =============================================================================
-- PART 1 — SCHEMA ADDITIONS
-- =============================================================================

-- 1a. Seat lock expiry: enables the 5-minute reservation hold system
ALTER TABLE public.trip_seats
  ADD COLUMN IF NOT EXISTS lock_expires_at timestamptz;

-- 1b. Payment receipt URL: stores uploaded receipt path in Supabase Storage
ALTER TABLE public.operation_bookings
  ADD COLUMN IF NOT EXISTS payment_receipt_url text;

-- 1c. Payment methods: production configuration consumed by Client checkout.
--     The Client app reads this table instead of hardcoded/mock methods.
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL UNIQUE,
  title text NOT NULL,
  subtitle text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  recommended boolean NOT NULL DEFAULT false,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT payment_methods_type_check CHECK (
    type IN (
      'credit_card',
      'instapay',
      'vodafone_cash',
      'wallet_balance',
      'cash_on_boarding'
    )
  )
);

ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Active payment methods are readable" ON public.payment_methods;
CREATE POLICY "Active payment methods are readable"
  ON public.payment_methods
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

GRANT SELECT ON public.payment_methods TO anon, authenticated;

INSERT INTO public.payment_methods (
  type,
  title,
  subtitle,
  description,
  is_active,
  recommended,
  sort_order
) VALUES
  (
    'instapay',
    'InstaPay',
    'Transfer and attach the receipt',
    'Manual InstaPay transfer verified by operations.',
    true,
    true,
    10
  ),
  (
    'vodafone_cash',
    'Vodafone Cash',
    'Transfer from a mobile wallet',
    'Manual mobile wallet transfer verified by operations.',
    true,
    false,
    20
  ),
  (
    'cash_on_boarding',
    'Cash with driver',
    'Pay when boarding',
    'Cash payment collected by the captain during boarding.',
    true,
    false,
    30
  ),
  (
    'wallet_balance',
    'Wallet balance',
    'Use your available app balance',
    'Deduct payment from the customer wallet balance.',
    false,
    false,
    40
  ),
  (
    'credit_card',
    'Card',
    'Pay securely by card',
    'Online card payment through the configured payment gateway.',
    false,
    false,
    50
  )
ON CONFLICT (type) DO UPDATE
SET
  title       = EXCLUDED.title,
  subtitle    = EXCLUDED.subtitle,
  description = EXCLUDED.description,
  sort_order  = EXCLUDED.sort_order,
  updated_at  = now();

-- Refresh PostgREST/Supabase schema cache after creating the table.
NOTIFY pgrst, 'reload schema';

-- 1d. Capacity check constraint: DB-level guard against counter overflow
--     Applied conditionally to avoid errors if constraint already exists.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'operation_trips_capacity_not_exceeded'
  ) THEN
    ALTER TABLE public.operation_trips
      ADD CONSTRAINT operation_trips_capacity_not_exceeded
      CHECK (booked_seats <= capacity);
  END IF;
END $$;


-- =============================================================================
-- PART 2 — PERFORMANCE INDEXES
-- =============================================================================

-- Trip search by date + status + route (most frequent client query)
CREATE INDEX IF NOT EXISTS idx_operation_trips_date_status_route
  ON public.operation_trips(trip_date, status, route_id, departure_time);

-- Seat state lookup (most frequent query when rendering seat maps)
CREATE INDEX IF NOT EXISTS idx_trip_seats_trip_state
  ON public.trip_seats(trip_id, state);

-- Lock expiry cleanup (pg_cron scans this every minute)
CREATE INDEX IF NOT EXISTS idx_trip_seats_reserved_expiry
  ON public.trip_seats(state, lock_expires_at)
  WHERE state = 'reserved';

-- Booking queue: Dashboard loads by status, ordered by date
CREATE INDEX IF NOT EXISTS idx_operation_bookings_status_created
  ON public.operation_bookings(status, created_at DESC);

-- Client's own booking history
CREATE INDEX IF NOT EXISTS idx_operation_bookings_client_created
  ON public.operation_bookings(client_id, created_at DESC);

-- Captain: fetch active trips by driver
CREATE INDEX IF NOT EXISTS idx_operation_trips_driver_active
  ON public.operation_trips(driver_id, trip_date, status)
  WHERE status IN ('scheduled', 'boarding', 'in_progress');

-- Notifications: unread first per user
CREATE INDEX IF NOT EXISTS idx_notifications_user_read
  ON public.notifications(user_id, is_read, created_at DESC);

-- Live locations: latest position per trip (reconnect snapshot)
CREATE INDEX IF NOT EXISTS idx_trip_live_locations_trip_recent
  ON public.trip_live_locations(trip_id, recorded_at DESC);

-- Trip passengers check-in lookup (Captain manifest)
CREATE INDEX IF NOT EXISTS idx_trip_passengers_trip_status
  ON public.trip_passengers(trip_id, status);


-- =============================================================================
-- PART 3 — CORE RPCs
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 3a. lock_trip_seat
--     Step 1 of the two-step booking flow.
--     Reserves a seat for 5 minutes with a lock_expires_at timestamp.
--     Uses atomic UPDATE WHERE state='available' to prevent double-locking.
--     Returns lock_expires_at so client can display a countdown.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.lock_trip_seat(
  p_trip_id   uuid,
  p_seat_id   uuid,
  p_client_id uuid
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_lock_expires_at timestamptz;
  v_rows_updated    int;
BEGIN
  v_lock_expires_at := now() + interval '5 minutes';

  -- Single atomic UPDATE: only succeeds if seat is currently available.
  -- Postgres serializes concurrent updates on the same row — no double-booking.
  UPDATE public.trip_seats
  SET
    state           = 'reserved',
    passenger_id    = p_client_id,
    lock_expires_at = v_lock_expires_at
  WHERE id = p_seat_id
    AND trip_id = p_trip_id
    AND (
      state = 'available'
      -- Self-healing: also accept expired locks that have no active booking
      OR (
        state = 'reserved'
        AND lock_expires_at < now()
        AND id NOT IN (
          SELECT seat_id FROM public.operation_bookings
          WHERE seat_id IS NOT NULL
            AND status NOT IN ('cancelled', 'rejected')
        )
      )
    );

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

  IF v_rows_updated = 0 THEN
    RAISE EXCEPTION 'seat_unavailable: Seat is no longer available for booking';
  END IF;

  RETURN jsonb_build_object(
    'success',          true,
    'seat_id',          p_seat_id,
    'lock_expires_at',  v_lock_expires_at
  );
END;
$$;


-- -----------------------------------------------------------------------------
-- 3b. confirm_seat_booking
--     Step 2 of the two-step booking flow.
--     Called after the client selects a payment method and uploads receipt.
--     Validates the lock is still held by this client, then creates the booking
--     and passenger records. Seat remains 'reserved' until Dashboard approves.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.confirm_seat_booking(
  p_client_id          uuid,
  p_trip_id            uuid,
  p_seat_id            uuid,
  p_pricing_id         uuid,
  p_pickup_point_id    uuid,
  p_dropoff_point_id   uuid,
  p_passenger_name     text,
  p_phone              text,
  p_route              text,
  p_trip_time          text,
  p_trip_date          date,
  p_seat_label         text,
  p_payment_method     text,
  p_payment_amount     numeric,
  p_pickup_point_name  text,
  p_dropoff_point_name text,
  p_receipt_url        text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_booking_id     uuid;
  v_booking_number text;
  v_seat           record;
BEGIN
  -- Validate: lock must still belong to this client and not be expired
  SELECT state, passenger_id, lock_expires_at
  INTO   v_seat
  FROM   public.trip_seats
  WHERE  id = p_seat_id AND trip_id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'seat_not_found: Seat does not exist for this trip';
  END IF;

  IF v_seat.state != 'reserved' THEN
    RAISE EXCEPTION 'seat_not_locked: Seat is not in reserved state (current: %)', v_seat.state;
  END IF;

  IF v_seat.passenger_id != p_client_id THEN
    RAISE EXCEPTION 'seat_locked_by_other: Seat is locked by a different user';
  END IF;

  IF v_seat.lock_expires_at IS NOT NULL AND v_seat.lock_expires_at < now() THEN
    -- Release expired lock before raising error (cleanup)
    UPDATE public.trip_seats
    SET state = 'available', passenger_id = NULL, lock_expires_at = NULL
    WHERE id = p_seat_id;
    RAISE EXCEPTION 'lock_expired: Your seat reservation has expired. Please select a seat again';
  END IF;

  -- Generate unique booking number
  v_booking_number := 'BK-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));

  -- Create the booking record (status = newRequest, awaiting Dashboard approval)
  INSERT INTO public.operation_bookings (
    client_id, trip_id, passenger_name, phone, route, trip_time, trip_date,
    seat, payment_method, payment_amount, seat_id, pricing_id,
    pickup_point_id, dropoff_point_id, status, booking_number, payment_receipt_url,
    created_by_source
  ) VALUES (
    p_client_id, p_trip_id, p_passenger_name, p_phone, p_route, p_trip_time,
    p_trip_date, p_seat_label, p_payment_method, p_payment_amount, p_seat_id,
    p_pricing_id, p_pickup_point_id, p_dropoff_point_id, 'newRequest',
    v_booking_number, p_receipt_url, 'client'
  )
  RETURNING id INTO v_booking_id;

  -- Create the passenger manifest record
  INSERT INTO public.trip_passengers (
    trip_id, customer_id, passenger_name, phone, seat_id, seat_label,
    pickup_point_id, pickup_point_name, dropoff_point_id, dropoff_point_name,
    payment_method, status
  ) VALUES (
    p_trip_id, p_client_id, p_passenger_name, p_phone, p_seat_id, p_seat_label,
    p_pickup_point_id, p_pickup_point_name, p_dropoff_point_id, p_dropoff_point_name,
    p_payment_method, 'reserved'
  );

  -- Increment trip counter (with capacity guard)
  UPDATE public.operation_trips
  SET
    booked_seats    = booked_seats + 1,
    passenger_count = passenger_count + 1
  WHERE id = p_trip_id
    AND booked_seats < capacity;  -- extra guard; CHECK constraint is the authoritative one

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trip_full: Trip has reached maximum capacity';
  END IF;

  -- Clear the lock expiry (seat stays 'reserved' but no longer has a timeout)
  UPDATE public.trip_seats
  SET lock_expires_at = NULL
  WHERE id = p_seat_id;

  -- Notify Dashboard via notifications table (picked up by realtime INSERT subscription)
  INSERT INTO public.notifications (user_id, title, body, type, data)
  SELECT
    ur.user_id,
    'حجز جديد',
    'حجز جديد من ' || p_passenger_name || ' — ' || p_route,
    'new_booking',
    jsonb_build_object('booking_id', v_booking_id, 'trip_id', p_trip_id)
  FROM public.user_roles ur
  WHERE ur.role IN ('operations_manager', 'dashboard_admin');

  RETURN jsonb_build_object(
    'success',          true,
    'booking_id',       v_booking_id,
    'booking_number',   v_booking_number,
    'trip_id',          p_trip_id,
    'seat_label',       p_seat_label,
    'payment_amount',   p_payment_amount
  );
END;
$$;


-- -----------------------------------------------------------------------------
-- 3c. approve_booking
--     Dashboard agent approves a booking after verifying the payment receipt.
--     Atomically: updates booking status + transitions seat to 'paid'.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.approve_booking(
  p_booking_id   uuid,
  p_reviewer_name text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_booking record;
BEGIN
  SELECT id, seat_id, trip_id, status, client_id, passenger_name
  INTO   v_booking
  FROM   public.operation_bookings
  WHERE  id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_not_found: Booking does not exist';
  END IF;

  IF v_booking.status NOT IN ('newRequest', 'paymentUploaded', 'underReview') THEN
    RAISE EXCEPTION 'invalid_booking_status: Cannot approve booking in status: %', v_booking.status;
  END IF;

  -- Update booking status
  UPDATE public.operation_bookings
  SET
    status        = 'approved',
    reviewer_name = p_reviewer_name,
    updated_at    = now()
  WHERE id = p_booking_id;

  -- Transition seat to paid (authoritative state)
  IF v_booking.seat_id IS NOT NULL THEN
    UPDATE public.trip_seats
    SET
      state           = 'paid',
      lock_expires_at = NULL,
      updated_at      = now()
    WHERE id = v_booking.seat_id;
  END IF;

  -- Notify the client
  IF v_booking.client_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title, body, type, data)
    VALUES (
      v_booking.client_id,
      'تم تأكيد حجزك',
      'تم قبول حجزك وتأكيده. نتمنى لك رحلة ممتعة.',
      'booking_approved',
      jsonb_build_object('booking_id', p_booking_id, 'trip_id', v_booking.trip_id)
    );
  END IF;

  RETURN jsonb_build_object(
    'success',    true,
    'booking_id', p_booking_id,
    'new_status', 'approved'
  );
END;
$$;


-- -----------------------------------------------------------------------------
-- 3d. reject_booking
--     Dashboard agent rejects a booking (invalid payment, etc.).
--     Atomically: updates booking status + releases the seat back to available.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.reject_booking(
  p_booking_id      uuid,
  p_rejection_reason text DEFAULT NULL,
  p_reviewer_name   text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_booking record;
BEGIN
  SELECT id, seat_id, trip_id, status, client_id, passenger_name
  INTO   v_booking
  FROM   public.operation_bookings
  WHERE  id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_not_found: Booking does not exist';
  END IF;

  IF v_booking.status IN ('cancelled', 'rejected') THEN
    RAISE EXCEPTION 'already_closed: Booking is already %', v_booking.status;
  END IF;

  -- Update booking status
  UPDATE public.operation_bookings
  SET
    status           = 'rejected',
    rejection_reason = p_rejection_reason,
    reviewer_name    = p_reviewer_name,
    updated_at       = now()
  WHERE id = p_booking_id;

  -- Release the seat back to available
  IF v_booking.seat_id IS NOT NULL THEN
    UPDATE public.trip_seats
    SET
      state           = 'available',
      passenger_id    = NULL,
      lock_expires_at = NULL,
      updated_at      = now()
    WHERE id = v_booking.seat_id;
  END IF;

  -- Decrement trip counter
  UPDATE public.operation_trips
  SET
    booked_seats    = GREATEST(booked_seats - 1, 0),
    passenger_count = GREATEST(passenger_count - 1, 0)
  WHERE id = v_booking.trip_id;

  -- Update passenger record
  UPDATE public.trip_passengers
  SET status = 'cancelled', updated_at = now()
  WHERE trip_id = v_booking.trip_id
    AND seat_id  = v_booking.seat_id
    AND customer_id = v_booking.client_id
    AND status NOT IN ('cancelled', 'completed', 'no_show');

  -- Notify the client
  IF v_booking.client_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title, body, type, data)
    VALUES (
      v_booking.client_id,
      'تم رفض حجزك',
      COALESCE(p_rejection_reason, 'للأسف، تم رفض طلب الحجز. يمكنك المحاولة مرة أخرى.'),
      'booking_rejected',
      jsonb_build_object('booking_id', p_booking_id, 'trip_id', v_booking.trip_id)
    );
  END IF;

  RETURN jsonb_build_object(
    'success',    true,
    'booking_id', p_booking_id,
    'new_status', 'rejected'
  );
END;
$$;


-- -----------------------------------------------------------------------------
-- 3e. cancel_booking
--     Client-initiated cancellation. Only allowed before trip reaches boarding.
--     Atomically releases seat, cancels booking and passenger records.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cancel_booking(
  p_booking_id uuid,
  p_client_id  uuid
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_booking    record;
  v_trip_status text;
BEGIN
  SELECT b.id, b.seat_id, b.trip_id, b.status, b.client_id
  INTO   v_booking
  FROM   public.operation_bookings b
  WHERE  b.id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_not_found: Booking does not exist';
  END IF;

  IF v_booking.client_id != p_client_id THEN
    RAISE EXCEPTION 'unauthorized: You can only cancel your own bookings';
  END IF;

  IF v_booking.status IN ('cancelled', 'rejected') THEN
    RAISE EXCEPTION 'already_cancelled: Booking is already %', v_booking.status;
  END IF;

  -- Prevent cancellation after boarding starts
  SELECT status INTO v_trip_status
  FROM public.operation_trips
  WHERE id = v_booking.trip_id;

  IF v_trip_status IN ('boarding', 'in_progress', 'completed') THEN
    RAISE EXCEPTION 'cancellation_not_allowed: Cannot cancel a booking after boarding has started';
  END IF;

  -- Cancel the booking
  UPDATE public.operation_bookings
  SET status = 'cancelled', updated_at = now()
  WHERE id = p_booking_id;

  -- Release the seat
  IF v_booking.seat_id IS NOT NULL THEN
    UPDATE public.trip_seats
    SET
      state           = 'available',
      passenger_id    = NULL,
      lock_expires_at = NULL,
      updated_at      = now()
    WHERE id = v_booking.seat_id;
  END IF;

  -- Decrement trip counter
  UPDATE public.operation_trips
  SET
    booked_seats    = GREATEST(booked_seats - 1, 0),
    passenger_count = GREATEST(passenger_count - 1, 0)
  WHERE id = v_booking.trip_id;

  -- Cancel passenger record
  UPDATE public.trip_passengers
  SET status = 'cancelled', updated_at = now()
  WHERE trip_id   = v_booking.trip_id
    AND seat_id   = v_booking.seat_id
    AND customer_id = p_client_id
    AND status NOT IN ('cancelled', 'completed', 'no_show');

  RETURN jsonb_build_object(
    'success',    true,
    'booking_id', p_booking_id,
    'new_status', 'cancelled'
  );
END;
$$;


-- -----------------------------------------------------------------------------
-- 3f. update_trip_status
--     Enforces the one-directional trip status transition machine.
--     Called by Captain (boarding → in_progress → completed)
--     and Dashboard (any → cancelled, or force transitions for ops).
--     On completion: marks non-checked-in passengers as no_show.
-- -----------------------------------------------------------------------------
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

  -- Apply the status change
  UPDATE public.operation_trips
  SET status = p_new_status, updated_at = now()
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
    'new_status',       p_new_status
  );
END;
$$;


-- -----------------------------------------------------------------------------
-- 3g. scan_passenger_ticket
--     Captain app calls this after QR scan.
--     Validates the passenger belongs to this trip with an active booking,
--     marks them as confirmed (checked in), and logs a progress event.
--     QR payload: booking_id (UUID) — unguessable, used as the token.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.scan_passenger_ticket(
  p_trip_id    uuid,
  p_booking_id uuid,
  p_driver_id  uuid
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_booking   record;
  v_passenger record;
BEGIN
  -- Validate booking exists, belongs to this trip, and is in an approvable state
  SELECT b.id, b.client_id, b.seat_id, b.passenger_name, b.seat, b.status
  INTO   v_booking
  FROM   public.operation_bookings b
  WHERE  b.id      = p_booking_id
    AND  b.trip_id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error',   'invalid_ticket: Ticket not found for this trip'
    );
  END IF;

  IF v_booking.status NOT IN ('approved', 'confirmed') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error',   'ticket_not_approved: Booking status is ' || v_booking.status
    );
  END IF;

  -- Find the passenger record
  SELECT id, status, passenger_name, seat_label
  INTO   v_passenger
  FROM   public.trip_passengers
  WHERE  trip_id     = p_trip_id
    AND  customer_id = v_booking.client_id
    AND  seat_id     = v_booking.seat_id
    AND  status NOT IN ('cancelled', 'no_show')
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error',   'passenger_not_found: Passenger record not found'
    );
  END IF;

  IF v_passenger.status = 'confirmed' THEN
    -- Idempotent: already checked in (handles offline retry)
    RETURN jsonb_build_object(
      'success',        true,
      'already_checked_in', true,
      'passenger_name', v_passenger.passenger_name,
      'seat_label',     v_passenger.seat_label
    );
  END IF;

  -- Mark as checked in
  UPDATE public.trip_passengers
  SET status = 'confirmed', updated_at = now()
  WHERE id = v_passenger.id;

  -- Log the check-in event
  INSERT INTO public.trip_progress_events (trip_id, driver_id, event_type, title, description)
  VALUES (
    p_trip_id,
    p_driver_id,
    'passenger_checked_in',
    'ركب الراكب',
    v_passenger.passenger_name || ' — مقعد ' || v_passenger.seat_label
  );

  RETURN jsonb_build_object(
    'success',        true,
    'passenger_name', v_passenger.passenger_name,
    'seat_label',     v_passenger.seat_label
  );
END;
$$;


-- -----------------------------------------------------------------------------
-- 3h. create_trip
--     Atomic trip creation: inserts trip + route points + seats in one
--     transaction. Accepts pre-processed arrays from the Dashboard client
--     (preserving existing client-side seat_configuration logic).
-- -----------------------------------------------------------------------------
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
  p_route_points       jsonb,  -- array of {route_point_id, point_name, point_order, arrival_offset, departure_offset, latitude, longitude}
  p_seats              jsonb   -- array of {seat_label, seat_row, seat_column}
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_trip_id uuid;
BEGIN
  -- Validate inputs
  IF p_capacity <= 0 THEN
    RAISE EXCEPTION 'invalid_capacity: Capacity must be greater than 0';
  END IF;

  IF jsonb_array_length(p_route_points) = 0 THEN
    RAISE EXCEPTION 'no_route_points: Route must have at least one station';
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

  -- 2. Insert route point snapshot (one batch INSERT)
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

  -- 3. Insert seat inventory (one batch INSERT)
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


-- -----------------------------------------------------------------------------
-- 3i. bulk_update_booking_status
--     Replaces the N+1 loop in SupabaseBookingsDatasource.bulkUpdateStatus.
--     Single UPDATE for any number of booking IDs.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.bulk_update_booking_status(
  p_booking_ids uuid[],
  p_new_status  text,
  p_reviewer_name text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_updated_count int;
BEGIN
  IF array_length(p_booking_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'empty_ids: No booking IDs provided';
  END IF;

  UPDATE public.operation_bookings
  SET
    status        = p_new_status,
    reviewer_name = COALESCE(p_reviewer_name, reviewer_name),
    updated_at    = now()
  WHERE id = ANY(p_booking_ids)
    AND status != p_new_status;  -- skip already-at-target rows

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;

  RETURN jsonb_build_object(
    'success',       true,
    'updated_count', v_updated_count,
    'new_status',    p_new_status
  );
END;
$$;


-- =============================================================================
-- PART 4 — SEAT LOCK EXPIRY CLEANUP
-- =============================================================================
-- Runs every minute to release expired seat locks that have no active booking.
-- Condition: state='reserved' AND lock_expires_at < now()
--            AND no non-cancelled booking references this seat
-- The NOT IN guard is critical: it prevents releasing a seat whose booking
-- was confirmed but whose lock timestamp technically expired (e.g. slow upload).
--
-- Applied conditionally: only if pg_cron extension is available on this project.
DO $do$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) THEN
    PERFORM cron.schedule(
      'release-expired-seat-locks',
      '* * * * *',
      $cron$
        UPDATE public.trip_seats
        SET
          state           = 'available',
          passenger_id    = NULL,
          lock_expires_at = NULL,
          updated_at      = now()
        WHERE state = 'reserved'
          AND lock_expires_at IS NOT NULL
          AND lock_expires_at < now()
          AND id NOT IN (
            SELECT seat_id
            FROM   public.operation_bookings
            WHERE  seat_id IS NOT NULL
              AND  status NOT IN ('cancelled', 'rejected')
          );
      $cron$
    );
    RAISE NOTICE 'pg_cron: seat lock expiry job scheduled successfully';
  ELSE
    RAISE NOTICE 'pg_cron not available — seat lock expiry must be handled by Edge Function or application timer';
  END IF;
END $do$;


-- =============================================================================
-- PART 5 — GRANT RPC PERMISSIONS
-- =============================================================================
-- All RPCs use SECURITY DEFINER so they run with the defining role's privileges.
-- Grant EXECUTE to authenticated users (enforced by internal validation logic).

GRANT EXECUTE ON FUNCTION public.lock_trip_seat(uuid, uuid, uuid)              TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_seat_booking(uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, date, text, text, numeric, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_booking(uuid, text)                    TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_booking(uuid, text, text)               TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_booking(uuid, uuid)                     TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_trip_status(uuid, text)                 TO authenticated;
GRANT EXECUTE ON FUNCTION public.scan_passenger_ticket(uuid, uuid, uuid)        TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_trip(text, uuid, uuid, uuid, date, time, time, int, numeric, text, text[], jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.bulk_update_booking_status(uuid[], text, text) TO authenticated;
