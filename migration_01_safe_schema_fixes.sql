-- Phase 1 - MIGRATION: Safe schema fixes for BMT Platform

-- 1. Fix support_tickets.client_id
-- Clean up orphaned tickets where client_id does not exist in clients table
DELETE FROM public.support_tickets WHERE client_id NOT IN (SELECT id FROM public.clients);
ALTER TABLE public.support_tickets DROP CONSTRAINT IF EXISTS support_tickets_client_id_fkey;
ALTER TABLE public.support_tickets ADD CONSTRAINT support_tickets_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;

-- 2. Fix refund_requests.client_id
-- Clean up orphaned refund requests where client_id does not exist in clients table
DELETE FROM public.refund_requests WHERE client_id NOT IN (SELECT id FROM public.clients);
ALTER TABLE public.refund_requests DROP CONSTRAINT IF EXISTS refund_requests_client_id_fkey;
ALTER TABLE public.refund_requests ADD CONSTRAINT refund_requests_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;

-- 3. Add missing relationship columns to operation_bookings
ALTER TABLE public.operation_bookings ADD COLUMN IF NOT EXISTS seat_id uuid REFERENCES public.trip_seats(id) ON DELETE SET NULL;
ALTER TABLE public.operation_bookings ADD COLUMN IF NOT EXISTS pricing_id uuid REFERENCES public.trip_pricing(id) ON DELETE SET NULL;
ALTER TABLE public.operation_bookings ADD COLUMN IF NOT EXISTS pickup_point_id uuid;
ALTER TABLE public.operation_bookings ADD COLUMN IF NOT EXISTS dropoff_point_id uuid;
ALTER TABLE public.operation_bookings ADD COLUMN IF NOT EXISTS booking_number text UNIQUE;
ALTER TABLE public.operation_bookings ADD COLUMN IF NOT EXISTS payment_status text;
ALTER TABLE public.operation_bookings ADD COLUMN IF NOT EXISTS created_by_source text DEFAULT 'client';

-- 4. Add admin role table
CREATE TABLE IF NOT EXISTS public.user_roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    role text NOT NULL CHECK (role IN ('client', 'dashboard_admin', 'support_agent', 'operations_manager', 'finance_agent')),
    created_at timestamptz DEFAULT now(),
    UNIQUE(user_id, role)
);

-- 5. Add helper function for RLS
CREATE OR REPLACE FUNCTION public.has_role(role_name text) RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = auth.uid() AND role = role_name
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Add Safe RLS Policies
-- Enable RLS safely on tables that missed it.
ALTER TABLE public.operation_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operation_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_seats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operation_bookings ENABLE ROW LEVEL SECURITY;

-- Note: We only ADD permissive policies here. If existing open policies exist, they won't conflict, but this ensures access if it was locked.
-- Client Policies
CREATE POLICY "Clients can read active routes" ON public.operation_routes FOR SELECT USING (status = 'active' OR public.has_role('operations_manager'));
CREATE POLICY "Clients can read scheduled/boarding/in_progress trips" ON public.operation_trips FOR SELECT USING (status IN ('scheduled', 'boarding', 'in_progress', 'completed') OR public.has_role('operations_manager'));
CREATE POLICY "Clients can read trip seats" ON public.trip_seats FOR SELECT USING (true);
CREATE POLICY "Clients can read trip pricing" ON public.trip_pricing FOR SELECT USING (true);
CREATE POLICY "Clients can read packages" ON public.packages FOR SELECT USING (status = 'active' OR public.has_role('dashboard_admin'));

CREATE POLICY "Clients can view their own bookings" ON public.operation_bookings FOR SELECT USING (client_id = auth.uid() OR public.has_role('dashboard_admin') OR public.has_role('operations_manager'));
CREATE POLICY "Clients can insert their own bookings" ON public.operation_bookings FOR INSERT WITH CHECK (client_id = auth.uid() OR public.has_role('dashboard_admin'));

-- Admin/Dashboard Policies
CREATE POLICY "Admins can manage routes" ON public.operation_routes FOR ALL USING (public.has_role('operations_manager') OR public.has_role('dashboard_admin'));
CREATE POLICY "Admins can manage trips" ON public.operation_trips FOR ALL USING (public.has_role('operations_manager') OR public.has_role('dashboard_admin'));
CREATE POLICY "Admins can manage seats" ON public.trip_seats FOR ALL USING (public.has_role('operations_manager') OR public.has_role('dashboard_admin'));
CREATE POLICY "Admins can manage pricing" ON public.trip_pricing FOR ALL USING (public.has_role('operations_manager') OR public.has_role('dashboard_admin'));
CREATE POLICY "Admins can manage bookings" ON public.operation_bookings FOR ALL USING (public.has_role('operations_manager') OR public.has_role('dashboard_admin'));
CREATE POLICY "Admins can manage packages" ON public.packages FOR ALL USING (public.has_role('dashboard_admin'));

-- 7. Add RPC for booking atomicity (prevent double booking)
CREATE OR REPLACE FUNCTION public.book_trip_seat(
    p_client_id uuid,
    p_trip_id uuid,
    p_seat_id uuid,
    p_pricing_id uuid,
    p_pickup_point_id uuid,
    p_dropoff_point_id uuid,
    p_passenger_name text,
    p_phone text,
    p_route text,
    p_trip_time text,
    p_trip_date date,
    p_seat text,
    p_payment_method text,
    p_payment_amount numeric,
    p_pickup_point_name text,
    p_dropoff_point_name text
) RETURNS uuid AS $$
DECLARE
    v_booking_id uuid;
    v_seat_state text;
BEGIN
    -- Check if seat is available
    SELECT state INTO v_seat_state FROM public.trip_seats WHERE id = p_seat_id FOR UPDATE;
    IF v_seat_state != 'available' THEN
        RAISE EXCEPTION 'Seat is no longer available';
    END IF;

    -- Update seat
    UPDATE public.trip_seats SET state = 'reserved', passenger_id = p_client_id WHERE id = p_seat_id;

    -- Update trip booked_seats
    UPDATE public.operation_trips SET booked_seats = booked_seats + 1, passenger_count = passenger_count + 1 WHERE id = p_trip_id;

    -- Create passenger record
    INSERT INTO public.trip_passengers (
        trip_id, customer_id, passenger_name, phone, seat_id, seat_label, pickup_point_id, pickup_point_name, dropoff_point_id, dropoff_point_name, payment_method, status
    ) VALUES (
        p_trip_id, p_client_id, p_passenger_name, p_phone, p_seat_id, p_seat, p_pickup_point_id, p_pickup_point_name, p_dropoff_point_id, p_dropoff_point_name, p_payment_method, 'reserved'
    );

    -- Create booking
    INSERT INTO public.operation_bookings (
        client_id, trip_id, passenger_name, phone, route, trip_time, trip_date, seat, payment_method, payment_amount, seat_id, pricing_id, pickup_point_id, dropoff_point_id, status
    ) VALUES (
        p_client_id, p_trip_id, p_passenger_name, p_phone, p_route, p_trip_time, p_trip_date, p_seat, p_payment_method, p_payment_amount, p_seat_id, p_pricing_id, p_pickup_point_id, p_dropoff_point_id, 'newRequest'
    ) RETURNING id INTO v_booking_id;

    RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 8. Add Indexes
CREATE INDEX IF NOT EXISTS idx_operation_bookings_seat_id ON public.operation_bookings(seat_id);
CREATE INDEX IF NOT EXISTS idx_operation_bookings_pricing_id ON public.operation_bookings(pricing_id);

-- 9. Add Comments for Deprecation
COMMENT ON TABLE public.routes IS 'DEPRECATED: Use operation_routes instead.';
COMMENT ON TABLE public.operation_complaints IS 'DEPRECATED: Use support_tickets instead.';
