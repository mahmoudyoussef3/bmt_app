-- ==========================================
-- Supabase Schema for Fleet Management
-- ==========================================

-- 1. Create Drivers Table
CREATE TABLE IF NOT EXISTS drivers (
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

-- 2. Create Vehicles Table
CREATE TABLE IF NOT EXISTS vehicles (
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
  seat_configuration JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Create Driver Documents Table
CREATE TABLE IF NOT EXISTS driver_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
  type VARCHAR NOT NULL, -- driver_license, national_id_front, national_id_back, criminal_record, employment_contract, other
  file_url VARCHAR NOT NULL,
  expiry_date DATE NOT NULL,
  status VARCHAR NOT NULL, -- expired, expiring_soon, valid
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Create Vehicle Documents Table
CREATE TABLE IF NOT EXISTS vehicle_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
  type VARCHAR NOT NULL, -- vehicle_license, insurance, technical_inspection, other
  file_url VARCHAR NOT NULL,
  expiry_date DATE NOT NULL,
  status VARCHAR NOT NULL, -- expired, expiring_soon, valid
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Create Assignments Table
CREATE TABLE IF NOT EXISTS assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES drivers(id) ON DELETE RESTRICT,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE RESTRICT,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status VARCHAR NOT NULL DEFAULT 'active', -- active, ended
  ended_at TIMESTAMPTZ,
  history JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==========================================
-- Supabase Schema for Bookings Management
-- ==========================================

-- 6. Create Operation Bookings Table
CREATE TABLE IF NOT EXISTS operation_bookings (
  id VARCHAR PRIMARY KEY,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
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
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewer_name VARCHAR,
  rejection_reason VARCHAR,
  customer_profile JSONB NOT NULL DEFAULT '{}'::jsonb,
  trip_details JSONB NOT NULL DEFAULT '{}'::jsonb,
  payment_details JSONB NOT NULL DEFAULT '{}'::jsonb,
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  notes JSONB NOT NULL DEFAULT '[]'::jsonb,
  timeline JSONB NOT NULL DEFAULT '[]'::jsonb
);

-- ==========================================
-- Supabase Schema for Complaints & Reports
-- ==========================================

-- 7. Create Operation Trips Table (Stub for reports)
CREATE TABLE IF NOT EXISTS operation_trips (
  id VARCHAR PRIMARY KEY,
  route_code VARCHAR NOT NULL,
  driver_id UUID REFERENCES drivers(id),
  vehicle_id UUID REFERENCES vehicles(id),
  trip_date DATE NOT NULL,
  status VARCHAR NOT NULL DEFAULT 'scheduled',
  revenue NUMERIC(10, 2) NOT NULL DEFAULT 0,
  passenger_count INT NOT NULL DEFAULT 0,
  occupancy_rate NUMERIC(3, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Create Operation Complaints Table
CREATE TABLE IF NOT EXISTS operation_complaints (
  id VARCHAR PRIMARY KEY,
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

-- 9. Create Subscriptions Table (Stub for reports)
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  package_name VARCHAR NOT NULL,
  active_users INT NOT NULL DEFAULT 0,
  expired_users INT NOT NULL DEFAULT 0,
  total_revenue NUMERIC(10, 2) NOT NULL DEFAULT 0,
  renewals_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==========================================
-- Analytics SQL Views for Reports
-- ==========================================

-- A. Revenue Daily View
DROP VIEW IF EXISTS public.revenue_daily_view;
CREATE OR REPLACE VIEW public.revenue_daily_view AS
SELECT
  DATE(created_at) as report_date,
  COALESCE(SUM(payment_amount), 0) as total_bookings_revenue,
  COUNT(*) as total_bookings
FROM public.operation_bookings
WHERE status NOT IN ('rejected', 'cancelled')
GROUP BY DATE(created_at);

-- B. Drivers Performance View
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

-- C. Vehicles Efficiency View
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

-- D. Complaints Summary View
DROP VIEW IF EXISTS public.complaints_summary_view;
CREATE OR REPLACE VIEW public.complaints_summary_view AS
SELECT
  category,
  COUNT(id) as total_complaints,
  COUNT(id) FILTER (WHERE status IN ('resolved', 'closed')) as resolved_complaints,
  COUNT(id) FILTER (WHERE status NOT IN ('resolved', 'closed')) as pending_complaints
FROM public.operation_complaints
GROUP BY category;

-- ==========================================
-- Supabase Schema for Clients (Passenger App)
-- ==========================================

-- 10. Create Clients Table
CREATE TABLE IF NOT EXISTS clients (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name VARCHAR NOT NULL,
  phone VARCHAR UNIQUE NOT NULL,
  email VARCHAR UNIQUE,
  status VARCHAR NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. Create Routes Table
CREATE TABLE IF NOT EXISTS routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pickup VARCHAR NOT NULL,
  destination VARCHAR NOT NULL,
  duration VARCHAR NOT NULL,
  starting_price NUMERIC(10, 2) NOT NULL,
  is_popular BOOLEAN DEFAULT false,
  status VARCHAR DEFAULT 'active'
);

-- 12. Create Packages Table
CREATE TABLE IF NOT EXISTS packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR NOT NULL,
  subtitle VARCHAR NOT NULL,
  price NUMERIC(10, 2) NOT NULL,
  badge VARCHAR,
  icon_key VARCHAR,
  status VARCHAR DEFAULT 'active'
);

ALTER TABLE packages 
ADD COLUMN IF NOT EXISTS days INT DEFAULT 30,
ADD COLUMN IF NOT EXISTS trips_count INT DEFAULT 44,
ADD COLUMN IF NOT EXISTS discount_percent INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS savings_amount NUMERIC(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';

-- 13. Create Package Vehicle Tiers Table
CREATE TABLE IF NOT EXISTS package_vehicle_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR NOT NULL,
  icon_key VARCHAR NOT NULL,
  extra_fee NUMERIC(10, 2) NOT NULL DEFAULT 0,
  description TEXT NOT NULL,
  status VARCHAR DEFAULT 'active'
);

ALTER TABLE operation_bookings 
ADD COLUMN IF NOT EXISTS trip_id UUID REFERENCES operation_trips(id) ON DELETE SET NULL;

ALTER TABLE operation_complaints
ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES clients(id) ON DELETE CASCADE;

-- 14. Create Loyalty Accounts Table
CREATE TABLE IF NOT EXISTS loyalty_accounts (
  client_id UUID PRIMARY KEY REFERENCES clients(id) ON DELETE CASCADE,
  points INT NOT NULL DEFAULT 0,
  wallet_balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00
);

-- 15. Create Loyalty Transactions Table
CREATE TABLE IF NOT EXISTS loyalty_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  title VARCHAR NOT NULL,
  points INT NOT NULL,
  is_earned BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
