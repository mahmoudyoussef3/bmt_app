-- =====================================================================================
-- BMT Dashboard & Client App Production Schema
-- Copy and run this in the Supabase SQL Editor.
-- =====================================================================================

-- WARNING: Uncomment the DROP statements below ONLY if you want to wipe existing tables 
-- and start completely fresh. This will DELETE ALL DATA in these tables.

/*
DROP VIEW IF EXISTS public.revenue_daily_view CASCADE;
DROP VIEW IF EXISTS public.drivers_performance_view CASCADE;
DROP VIEW IF EXISTS public.vehicles_efficiency_view CASCADE;
DROP VIEW IF EXISTS public.complaints_summary_view CASCADE;

DROP TABLE IF EXISTS public.loyalty_transactions CASCADE;
DROP TABLE IF EXISTS public.loyalty_accounts CASCADE;
DROP TABLE IF EXISTS public.operation_complaints CASCADE;
DROP TABLE IF EXISTS public.operation_bookings CASCADE;
DROP TABLE IF EXISTS public.operation_trips CASCADE;
DROP TABLE IF EXISTS public.assignments CASCADE;
DROP TABLE IF EXISTS public.vehicle_documents CASCADE;
DROP TABLE IF EXISTS public.driver_documents CASCADE;
DROP TABLE IF EXISTS public.vehicles CASCADE;
DROP TABLE IF EXISTS public.drivers CASCADE;
DROP TABLE IF EXISTS public.clients CASCADE;
DROP TABLE IF EXISTS public.routes CASCADE;
DROP TABLE IF EXISTS public.packages CASCADE;
DROP TABLE IF EXISTS public.package_vehicle_tiers CASCADE;
DROP TABLE IF EXISTS public.subscriptions CASCADE;
*/

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 0. Helpers
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 1. Base Entities (No Foreign Keys)
-- ============================================================

-- Clients (Passenger App Users)
CREATE TABLE IF NOT EXISTS public.clients (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name VARCHAR NOT NULL,
  phone VARCHAR UNIQUE NOT NULL,
  email VARCHAR UNIQUE,
  status VARCHAR NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Drivers
CREATE TABLE IF NOT EXISTS public.drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_code VARCHAR UNIQUE NOT NULL,
  full_name VARCHAR NOT NULL,
  phone VARCHAR NOT NULL,
  emergency_phone VARCHAR NOT NULL,
  address TEXT NOT NULL,
  national_id VARCHAR UNIQUE NOT NULL,
  profile_image_url VARCHAR,
  license_number VARCHAR UNIQUE NOT NULL,
  license_expiry_date DATE NOT NULL,
  hire_date DATE NOT NULL,
  notes TEXT,
  status VARCHAR NOT NULL DEFAULT 'active', -- active, suspended, archived
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vehicles
CREATE TABLE IF NOT EXISTS public.vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_code VARCHAR UNIQUE NOT NULL,
  plate_number VARCHAR UNIQUE NOT NULL,
  vehicle_type VARCHAR NOT NULL,
  brand VARCHAR NOT NULL,
  model VARCHAR NOT NULL,
  manufacture_year INT NOT NULL,
  color VARCHAR NOT NULL,
  capacity INT NOT NULL,
  seat_layout_type VARCHAR NOT NULL, -- standard, VIP
  image_url VARCHAR,
  notes TEXT,
  status VARCHAR NOT NULL DEFAULT 'active', -- active, maintenance, suspended, archived
  seat_configuration JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Routes
CREATE TABLE IF NOT EXISTS public.routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pickup VARCHAR NOT NULL,
  destination VARCHAR NOT NULL,
  duration VARCHAR NOT NULL,
  starting_price NUMERIC(10, 2) NOT NULL,
  is_popular BOOLEAN DEFAULT false,
  status VARCHAR DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Packages
CREATE TABLE IF NOT EXISTS public.packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR NOT NULL,
  subtitle VARCHAR NOT NULL,
  price NUMERIC(10, 2) NOT NULL,
  badge VARCHAR,
  icon_key VARCHAR,
  days INT DEFAULT 30,
  trips_count INT DEFAULT 44,
  discount_percent INT DEFAULT 0,
  savings_amount NUMERIC(10, 2) DEFAULT 0,
  description TEXT DEFAULT '',
  status VARCHAR DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Package Vehicle Tiers
CREATE TABLE IF NOT EXISTS public.package_vehicle_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR NOT NULL,
  icon_key VARCHAR NOT NULL,
  extra_fee NUMERIC(10, 2) NOT NULL DEFAULT 0,
  description TEXT NOT NULL,
  status VARCHAR DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Subscriptions (Reports Stub)
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  package_name VARCHAR NOT NULL,
  active_users INT NOT NULL DEFAULT 0,
  expired_users INT NOT NULL DEFAULT 0,
  total_revenue NUMERIC(10, 2) NOT NULL DEFAULT 0,
  renewals_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. Dependent Entities (Have Foreign Keys)
-- ============================================================

-- Operation Trips
CREATE TABLE IF NOT EXISTS public.operation_trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_code VARCHAR NOT NULL,
  driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
  vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE SET NULL,
  trip_date DATE NOT NULL,
  status VARCHAR NOT NULL DEFAULT 'scheduled',
  revenue NUMERIC(10, 2) NOT NULL DEFAULT 0,
  passenger_count INT NOT NULL DEFAULT 0,
  occupancy_rate NUMERIC(3, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Operation Bookings
CREATE TABLE IF NOT EXISTS public.operation_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  trip_id UUID REFERENCES public.operation_trips(id) ON DELETE SET NULL,
  passenger_name VARCHAR NOT NULL,
  phone VARCHAR NOT NULL,
  route VARCHAR NOT NULL,
  trip_time VARCHAR NOT NULL,
  trip_date VARCHAR NOT NULL,
  seat VARCHAR NOT NULL,
  payment_method VARCHAR NOT NULL,
  status VARCHAR NOT NULL DEFAULT 'newRequest',
  priority VARCHAR NOT NULL DEFAULT 'normal',
  assigned_trip VARCHAR NOT NULL DEFAULT 'غير مسند',
  reviewer_name VARCHAR,
  rejection_reason VARCHAR,
  customer_profile JSONB NOT NULL DEFAULT '{}'::jsonb,
  trip_details JSONB NOT NULL DEFAULT '{}'::jsonb,
  payment_details JSONB NOT NULL DEFAULT '{}'::jsonb,
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  notes JSONB NOT NULL DEFAULT '[]'::jsonb,
  timeline JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Operation Complaints / Support Tickets
CREATE TABLE IF NOT EXISTS public.operation_complaints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES public.clients(id) ON DELETE CASCADE,
  client_name VARCHAR NOT NULL,
  client_phone VARCHAR NOT NULL,
  category VARCHAR NOT NULL,
  trip_code VARCHAR NOT NULL,
  assigned_to VARCHAR,
  status VARCHAR NOT NULL DEFAULT 'newlyCreated',
  priority VARCHAR NOT NULL DEFAULT 'low',
  description TEXT NOT NULL,
  conversation JSONB NOT NULL DEFAULT '[]'::jsonb,
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  history JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Driver Documents
CREATE TABLE IF NOT EXISTS public.driver_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
  type VARCHAR NOT NULL,
  file_url VARCHAR NOT NULL,
  expiry_date DATE NOT NULL,
  status VARCHAR NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vehicle Documents
CREATE TABLE IF NOT EXISTS public.vehicle_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE CASCADE,
  type VARCHAR NOT NULL,
  file_url VARCHAR NOT NULL,
  expiry_date DATE NOT NULL,
  status VARCHAR NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vehicle/Driver Assignments
CREATE TABLE IF NOT EXISTS public.assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES public.drivers(id) ON DELETE RESTRICT,
  vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE RESTRICT,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status VARCHAR NOT NULL DEFAULT 'active',
  ended_at TIMESTAMPTZ,
  history JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Loyalty Accounts
CREATE TABLE IF NOT EXISTS public.loyalty_accounts (
  client_id UUID PRIMARY KEY REFERENCES public.clients(id) ON DELETE CASCADE,
  points INT NOT NULL DEFAULT 0,
  wallet_balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00
);

-- Loyalty Transactions
CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES public.clients(id) ON DELETE CASCADE,
  title VARCHAR NOT NULL,
  points INT NOT NULL,
  is_earned BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. Triggers for updated_at
-- ============================================================

-- Create Triggers
DROP TRIGGER IF EXISTS update_clients_updated_at ON public.clients;
CREATE TRIGGER update_clients_updated_at
BEFORE UPDATE ON public.clients
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_drivers_updated_at ON public.drivers;
CREATE TRIGGER update_drivers_updated_at
BEFORE UPDATE ON public.drivers
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_vehicles_updated_at ON public.vehicles;
CREATE TRIGGER update_vehicles_updated_at
BEFORE UPDATE ON public.vehicles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_operation_complaints_updated_at ON public.operation_complaints;
CREATE TRIGGER update_operation_complaints_updated_at
BEFORE UPDATE ON public.operation_complaints
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 4. Analytics Views
-- ============================================================

DROP VIEW IF EXISTS public.revenue_daily_view;
CREATE OR REPLACE VIEW public.revenue_daily_view AS
SELECT
  DATE(created_at) as report_date,
  COALESCE(SUM((payment_details->>'amount')::NUMERIC), 0) as total_bookings_revenue,
  COUNT(*) as total_bookings
FROM public.operation_bookings
WHERE status NOT IN ('rejected', 'cancelled')
GROUP BY DATE(created_at);

DROP VIEW IF EXISTS public.drivers_performance_view;
CREATE OR REPLACE VIEW public.drivers_performance_view AS
SELECT
  d.id as driver_id,
  d.full_name as name,
  d.status,
  COUNT(t.id) FILTER (WHERE t.status = 'completed') as completed_trips,
  COALESCE(SUM(t.revenue) FILTER (WHERE t.status = 'completed'), 0) as total_revenue
FROM public.drivers d
LEFT JOIN public.operation_trips t ON t.driver_id = d.id
GROUP BY d.id, d.full_name, d.status;

DROP VIEW IF EXISTS public.vehicles_efficiency_view;
CREATE OR REPLACE VIEW public.vehicles_efficiency_view AS
SELECT
  v.id as vehicle_id,
  v.plate_number,
  v.model,
  v.status,
  COUNT(t.id) FILTER (WHERE t.status = 'completed') as completed_trips,
  COALESCE(AVG(t.occupancy_rate) FILTER (WHERE t.status = 'completed'), 0) as avg_occupancy_rate,
  CASE
    WHEN v.status = 'maintenance' THEN 'تحتاج صيانة'
    WHEN v.status = 'active' THEN 'جاهزة'
    ELSE 'غير متاحة'
  END as maintenance_status
FROM public.vehicles v
LEFT JOIN public.operation_trips t ON t.vehicle_id = v.id
GROUP BY v.id, v.plate_number, v.model, v.status;

DROP VIEW IF EXISTS public.complaints_summary_view;
CREATE OR REPLACE VIEW public.complaints_summary_view AS
SELECT
  category,
  COUNT(id) as total_complaints,
  COUNT(id) FILTER (WHERE status IN ('resolved', 'closed')) as resolved_complaints,
  COUNT(id) FILTER (WHERE status NOT IN ('resolved', 'closed')) as pending_complaints
FROM public.operation_complaints
GROUP BY category;
