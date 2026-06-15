-- Phase 2 - MIGRATION: Three-App Architecture (Dashboard, Client, Driver)
-- This script safely constructs the necessary structures without deleting data.

-- ============================================================================
-- 1. EXTEND DRIVERS TABLE FOR DRIVER APP AUTH
-- ============================================================================
ALTER TABLE public.drivers 
ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

-- Unique constraint so one auth user can only map to one driver profile
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'drivers_user_id_key'
    ) THEN
        ALTER TABLE public.drivers ADD CONSTRAINT drivers_user_id_key UNIQUE (user_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_drivers_user_id ON public.drivers(user_id);

-- ============================================================================
-- 2. CREATE DRIVER APP OPERATIONAL TABLES
-- ============================================================================

-- Trip Live Locations
CREATE TABLE IF NOT EXISTS public.trip_live_locations (
    id uuid primary key default gen_random_uuid(),
    trip_id uuid not null references public.operation_trips(id) on delete cascade,
    driver_id uuid not null references public.drivers(id) on delete cascade,
    vehicle_id uuid not null references public.vehicles(id) on delete cascade,
    latitude double precision not null,
    longitude double precision not null,
    heading double precision,
    speed double precision,
    accuracy double precision,
    recorded_at timestamptz not null default now()
);
CREATE INDEX IF NOT EXISTS idx_trip_live_locations_trip_id ON public.trip_live_locations(trip_id);

-- Trip Progress Events
CREATE TABLE IF NOT EXISTS public.trip_progress_events (
    id uuid primary key default gen_random_uuid(),
    trip_id uuid not null references public.operation_trips(id) on delete cascade,
    driver_id uuid not null references public.drivers(id) on delete cascade,
    event_type text not null, -- e.g., 'started', 'arrived_station', 'completed'
    station_id uuid references public.route_stations(id) on delete set null,
    title text not null,
    description text,
    latitude double precision,
    longitude double precision,
    created_at timestamptz not null default now()
);
CREATE INDEX IF NOT EXISTS idx_trip_progress_events_trip_id ON public.trip_progress_events(trip_id);

-- Driver Trip Reports
CREATE TABLE IF NOT EXISTS public.driver_trip_reports (
    id uuid primary key default gen_random_uuid(),
    trip_id uuid not null references public.operation_trips(id) on delete cascade,
    driver_id uuid not null references public.drivers(id) on delete cascade,
    report_type text not null, -- e.g., 'flat_tire', 'passenger_no_show', 'traffic'
    description text not null,
    status text not null default 'pending', -- 'pending', 'resolved'
    resolved_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
CREATE INDEX IF NOT EXISTS idx_driver_trip_reports_trip_id ON public.driver_trip_reports(trip_id);

-- ============================================================================
-- 3. CREATE CLIENT APP RETENTION TABLES
-- ============================================================================

-- Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    body text not null,
    type text not null default 'general',
    data jsonb default '{}'::jsonb,
    is_read boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);

-- Referral Codes
CREATE TABLE IF NOT EXISTS public.referral_codes (
    id uuid primary key default gen_random_uuid(),
    client_id uuid not null references public.clients(id) on delete cascade,
    code text not null unique,
    status text not null default 'active',
    created_at timestamptz not null default now()
);
CREATE INDEX IF NOT EXISTS idx_referral_codes_client_id ON public.referral_codes(client_id);

-- Referral Rewards
CREATE TABLE IF NOT EXISTS public.referral_rewards (
    id uuid primary key default gen_random_uuid(),
    referrer_id uuid not null references public.clients(id) on delete cascade,
    referred_client_id uuid not null references public.clients(id) on delete cascade,
    reward_amount numeric not null,
    status text not null default 'pending', -- 'pending', 'granted'
    granted_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
CREATE INDEX IF NOT EXISTS idx_referral_rewards_referrer_id ON public.referral_rewards(referrer_id);

-- ============================================================================
-- 4. UPDATED_AT TRIGGERS
-- ============================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_driver_trip_reports_updated_at') THEN
        CREATE TRIGGER update_driver_trip_reports_updated_at BEFORE UPDATE ON public.driver_trip_reports FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_notifications_updated_at') THEN
        CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_referral_rewards_updated_at') THEN
        CREATE TRIGGER update_referral_rewards_updated_at BEFORE UPDATE ON public.referral_rewards FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
END $$;

-- ============================================================================
-- 5. ROW LEVEL SECURITY (RLS) ACTIVATION
-- ============================================================================
ALTER TABLE public.trip_live_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_progress_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_trip_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_rewards ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 6. RLS POLICIES FOR DRIVER APP
-- Using the explicit relationship: drivers.user_id = auth.uid()
-- ============================================================================

DROP POLICY IF EXISTS "Drivers can insert live locations for their assigned trips" ON public.trip_live_locations;
CREATE POLICY "Drivers can insert live locations for their assigned trips" 
ON public.trip_live_locations FOR INSERT 
TO authenticated 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.drivers d 
    WHERE d.id = trip_live_locations.driver_id 
      AND d.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Drivers can insert progress events" ON public.trip_progress_events;
CREATE POLICY "Drivers can insert progress events" 
ON public.trip_progress_events FOR INSERT 
TO authenticated 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.drivers d 
    WHERE d.id = trip_progress_events.driver_id 
      AND d.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Drivers can insert trip reports" ON public.driver_trip_reports;
CREATE POLICY "Drivers can insert trip reports" 
ON public.driver_trip_reports FOR INSERT 
TO authenticated 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.drivers d 
    WHERE d.id = driver_trip_reports.driver_id 
      AND d.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Drivers can view their own reports" ON public.driver_trip_reports;
CREATE POLICY "Drivers can view their own reports" 
ON public.driver_trip_reports FOR SELECT 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.drivers d 
    WHERE d.id = driver_trip_reports.driver_id 
      AND d.user_id = auth.uid()
  )
);

-- Note: To apply this rule to operation_trips (allowing drivers to view/update assigned trips):
DROP POLICY IF EXISTS "Drivers can view trips assigned to them" ON public.operation_trips;
CREATE POLICY "Drivers can view trips assigned to them" 
ON public.operation_trips FOR SELECT 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.drivers d 
    WHERE d.id = operation_trips.driver_id 
      AND d.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Drivers can update status of trips assigned to them" ON public.operation_trips;
CREATE POLICY "Drivers can update status of trips assigned to them" 
ON public.operation_trips FOR UPDATE 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.drivers d 
    WHERE d.id = operation_trips.driver_id 
      AND d.user_id = auth.uid()
  )
);

-- ============================================================================
-- 7. RLS POLICIES FOR CLIENT APP
-- ============================================================================

-- Clients can strictly read live tracking ONLY for active trips they have booked
DROP POLICY IF EXISTS "Clients can view live locations for booked trips" ON public.trip_live_locations;
CREATE POLICY "Clients can view live locations for booked trips" 
ON public.trip_live_locations FOR SELECT 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.operation_bookings b
    WHERE b.trip_id = trip_live_locations.trip_id 
      AND b.client_id = auth.uid()
      AND b.status = 'confirmed'
  )
);

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" 
ON public.notifications FOR SELECT 
TO authenticated 
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" 
ON public.notifications FOR UPDATE 
TO authenticated 
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Clients can view their own referral codes" ON public.referral_codes;
CREATE POLICY "Clients can view their own referral codes" 
ON public.referral_codes FOR SELECT 
TO authenticated 
USING (client_id = auth.uid());

DROP POLICY IF EXISTS "Clients can view their own rewards" ON public.referral_rewards;
CREATE POLICY "Clients can view their own rewards" 
ON public.referral_rewards FOR SELECT 
TO authenticated 
USING (referrer_id = auth.uid());
