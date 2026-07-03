-- =====================================================================================
-- Migration 15: SaaS Booking Flow Redesign
-- Implements: transport_packages, transport_subscriptions, manual payment reviews, seat holds.
-- =====================================================================================

-- 1. Create Enums and Tables
CREATE TYPE public.transport_package_type AS ENUM (
  'just_go',
  'go_and_return',
  'work_week',
  'two_work_weeks',
  'work_month',
  'three_months'
);

CREATE TABLE IF NOT EXISTS public.transport_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ar text NOT NULL,
  name_en text NOT NULL,
  package_type public.transport_package_type NOT NULL,
  duration_days int NOT NULL DEFAULT 1,
  ride_count int NOT NULL DEFAULT 1,
  price numeric(12, 2) NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  display_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.transport_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  package_id uuid NOT NULL REFERENCES public.transport_packages(id) ON DELETE RESTRICT,
  total_rides int NOT NULL,
  remaining_rides int NOT NULL,
  starts_at date NOT NULL,
  expires_at date NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'exhausted', 'expired', 'cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2. Modify operation_bookings
ALTER TABLE public.operation_bookings
ADD COLUMN IF NOT EXISTS package_id uuid REFERENCES public.transport_packages(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS subscription_id uuid REFERENCES public.transport_subscriptions(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS payment_status text NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'submitted', 'under_review', 'approved', 'rejected', 'refunded')),
ADD COLUMN IF NOT EXISTS payment_review_status text NOT NULL DEFAULT 'pending' CHECK (payment_review_status IN ('pending', 'reviewed')),
ADD COLUMN IF NOT EXISTS payment_rejection_reason text,
ADD COLUMN IF NOT EXISTS reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS reviewed_at timestamptz,
ADD COLUMN IF NOT EXISTS plan_start_date date,
ADD COLUMN IF NOT EXISTS plan_end_date date;

-- 3. Modify trip_seats
ALTER TABLE public.trip_seats
ADD COLUMN IF NOT EXISTS held_at timestamptz,
ADD COLUMN IF NOT EXISTS hold_expires_at timestamptz;

-- 4. Seed initial transport packages
INSERT INTO public.transport_packages (name_ar, name_en, package_type, duration_days, ride_count, price, display_order)
VALUES 
('رحلة ذهاب فقط', 'Just Go', 'just_go', 1, 1, 85.00, 1),
('رحلة ذهاب وعودة', 'Go & Return', 'go_and_return', 1, 2, 160.00, 2),
('أسبوع عمل (٥ أيام)', 'Work Week (5 Days)', 'work_week', 5, 10, 750.00, 3),
('أسبوعين عمل (١٠ أيام)', 'Two Work Weeks (10 Days)', 'two_work_weeks', 10, 20, 1400.00, 4),
('شهر عمل', 'One Month', 'work_month', 30, 44, 3000.00, 5),
('ثلاثة أشهر', 'Three Months', 'three_months', 90, 132, 8500.00, 6)
ON CONFLICT DO NOTHING;

-- 5. RPC confirm_seat_booking_v2
CREATE OR REPLACE FUNCTION public.confirm_seat_booking_v2(
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
  p_package_id         uuid,
  p_plan_start_date    date,
  p_receipt_url        text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_booking_id     uuid;
  v_booking_number text;
  v_seat           record;
BEGIN
  -- Validate lock
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
    UPDATE public.trip_seats
    SET state = 'available', passenger_id = NULL, lock_expires_at = NULL
    WHERE id = p_seat_id;
    RAISE EXCEPTION 'lock_expired: Your seat reservation has expired. Please select a seat again';
  END IF;

  -- Generate unique booking number
  v_booking_number := 'BK-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));

  -- Create booking (status = pending)
  INSERT INTO public.operation_bookings (
    client_id, trip_id, passenger_name, phone, route, trip_time, trip_date,
    seat, payment_method, payment_amount, seat_id, pricing_id,
    pickup_point_id, dropoff_point_id, status, booking_number, payment_receipt_url,
    created_by_source, package_id, plan_start_date, payment_status, payment_review_status
  ) VALUES (
    p_client_id, p_trip_id, p_passenger_name, p_phone, p_route, p_trip_time,
    p_trip_date, p_seat_label, p_payment_method, p_payment_amount, p_seat_id,
    p_pricing_id, p_pickup_point_id, p_dropoff_point_id, 'pending',
    v_booking_number, p_receipt_url, 'client', p_package_id, p_plan_start_date,
    'submitted', 'pending'
  )
  RETURNING id INTO v_booking_id;

  -- Maintain seat hold (Set to 30 mins from now)
  UPDATE public.trip_seats
  SET held_at = now(), hold_expires_at = now() + interval '30 minutes'
  WHERE id = p_seat_id;

  -- Increment booked_seats but NOT passenger_count
  UPDATE public.operation_trips
  SET booked_seats = booked_seats + 1
  WHERE id = p_trip_id AND booked_seats < capacity;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'trip_full: Trip has reached maximum capacity';
  END IF;

  -- Notify Dashboard
  INSERT INTO public.notifications (user_id, title, body, type, data)
  SELECT
    ur.user_id,
    'مراجعة دفع جديدة',
    'طلب مراجعة دفع من ' || p_passenger_name || ' — ' || p_route,
    'payment_review',
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

-- 6. RPC approve_payment
CREATE OR REPLACE FUNCTION public.approve_payment(
  p_booking_id uuid,
  p_reviewer_id uuid
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_booking record;
  v_pkg record;
  v_sub_id uuid := NULL;
BEGIN
  -- Get booking
  SELECT * INTO v_booking
  FROM public.operation_bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_not_found';
  END IF;

  IF v_booking.status != 'pending' THEN
    RAISE EXCEPTION 'booking_not_pending';
  END IF;

  -- Get package
  IF v_booking.package_id IS NOT NULL THEN
    SELECT * INTO v_pkg FROM public.transport_packages WHERE id = v_booking.package_id;
    
    -- Create subscription if multi-ride
    IF v_pkg.ride_count > 1 THEN
      INSERT INTO public.transport_subscriptions (
        client_id, package_id, total_rides, remaining_rides, starts_at, expires_at
      ) VALUES (
        v_booking.client_id, v_pkg.id, v_pkg.ride_count, v_pkg.ride_count - 1, 
        v_booking.plan_start_date, v_booking.plan_start_date + (v_pkg.duration_days || ' days')::interval
      ) RETURNING id INTO v_sub_id;
    END IF;
  END IF;

  -- Update Booking
  UPDATE public.operation_bookings
  SET 
    status = 'approved',
    payment_status = 'approved',
    payment_review_status = 'reviewed',
    reviewed_by = p_reviewer_id,
    reviewed_at = now(),
    subscription_id = v_sub_id
  WHERE id = p_booking_id;

  -- Clear Seat Expiration
  UPDATE public.trip_seats
  SET hold_expires_at = NULL, held_at = NULL
  WHERE id = v_booking.seat_id;

  -- Insert Passenger (Option 2 rule)
  INSERT INTO public.trip_passengers (
    trip_id, customer_id, passenger_name, phone, seat_id, seat_label,
    pickup_point_id, pickup_point_name, dropoff_point_id, dropoff_point_name, payment_method, status
  ) VALUES (
    v_booking.trip_id, v_booking.client_id, v_booking.passenger_name, v_booking.phone,
    v_booking.seat_id, v_booking.seat, v_booking.pickup_point_id, NULL, v_booking.dropoff_point_id, NULL,
    v_booking.payment_method, 'reserved'
  );

  -- Increment Passenger Count
  UPDATE public.operation_trips
  SET passenger_count = passenger_count + 1
  WHERE id = v_booking.trip_id;

  RETURN jsonb_build_object('success', true, 'booking_id', p_booking_id);
END;
$$;

-- 7. RPC reject_payment
CREATE OR REPLACE FUNCTION public.reject_payment(
  p_booking_id uuid,
  p_reviewer_id uuid,
  p_reason text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_booking record;
BEGIN
  -- Get booking
  SELECT * INTO v_booking
  FROM public.operation_bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_not_found';
  END IF;

  IF v_booking.status != 'pending' THEN
    RAISE EXCEPTION 'booking_not_pending';
  END IF;

  -- Update Booking
  UPDATE public.operation_bookings
  SET 
    status = 'cancelled',
    payment_status = 'rejected',
    payment_review_status = 'reviewed',
    payment_rejection_reason = p_reason,
    reviewed_by = p_reviewer_id,
    reviewed_at = now()
  WHERE id = p_booking_id;

  -- Release Seat
  UPDATE public.trip_seats
  SET state = 'available', passenger_id = NULL, lock_expires_at = NULL, held_at = NULL, hold_expires_at = NULL
  WHERE id = v_booking.seat_id;

  -- Decrement Booked Seats
  UPDATE public.operation_trips
  SET booked_seats = booked_seats - 1
  WHERE id = v_booking.trip_id;

  RETURN jsonb_build_object('success', true, 'booking_id', p_booking_id);
END;
$$;

-- 8. RPC release_expired_seat_holds
-- Run this via pg_cron periodically (e.g. every minute)
CREATE OR REPLACE FUNCTION public.release_expired_seat_holds()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_rec record;
BEGIN
  FOR v_rec IN 
    SELECT b.id as booking_id, b.seat_id, b.trip_id
    FROM public.operation_bookings b
    JOIN public.trip_seats s ON b.seat_id = s.id
    WHERE b.status = 'pending' 
      AND s.hold_expires_at IS NOT NULL 
      AND s.hold_expires_at < now()
  LOOP
    -- Cancel booking
    UPDATE public.operation_bookings
    SET status = 'cancelled', payment_status = 'rejected', payment_rejection_reason = 'Seat hold expired automatically'
    WHERE id = v_rec.booking_id;

    -- Release seat
    UPDATE public.trip_seats
    SET state = 'available', passenger_id = NULL, lock_expires_at = NULL, held_at = NULL, hold_expires_at = NULL
    WHERE id = v_rec.seat_id;

    -- Decrement Booked Seats
    UPDATE public.operation_trips
    SET booked_seats = booked_seats - 1
    WHERE id = v_rec.trip_id;
  END LOOP;
END;
$$;
