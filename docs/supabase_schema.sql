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
-- Insert Egyptian Mock Data
-- ==========================================

-- Insert Drivers
INSERT INTO drivers (id, employee_code, full_name, phone, emergency_phone, address, national_id, license_number, license_expiry_date, hire_date, notes, status) VALUES
('d1111111-1111-1111-1111-111111111111', 'EMP-101', 'أحمد عبد الرازق', '01022334455', '01244770000', 'شارع 12، القاهرة الكبرى', '29800000000000', 'د-60000', '2026-12-10', '2020-01-15', 'سائق ذو خبرة عالية بمسارات الجيزة والقاهرة', 'active'),
('d2222222-2222-2222-2222-222222222222', 'EMP-102', 'مصطفى سمير', '01022335186', '01244770421', 'شارع 13، القاهرة الكبرى', '29800000091017', 'د-60137', '2026-12-11', '2021-03-20', 'ملتزم بالمواعيد وحسن السلوك', 'active'),
('d3333333-3333-3333-3333-333333333333', 'EMP-103', 'كريم فتحي', '01022335917', '01244770842', 'شارع 14، القاهرة الكبرى', '29800000182034', 'د-60274', '2026-12-12', '2022-05-10', 'سائق احتياطي للطوارئ', 'active'),
('d4444444-4444-4444-4444-444444444444', 'EMP-104', 'حسن عادل', '01022336648', '01244771263', 'شارع 15، القاهرة الكبرى', '29800000273051', 'د-60411', '2026-06-20', '2019-11-01', 'رخصة القيادة تقترب من الانتهاء', 'active'),
('d5555555-5555-5555-5555-555555555555', 'EMP-105', 'ياسر عبد الحميد', '01022340303', '01244773368', 'شارع 16، القاهرة الكبرى', '29800000728136', 'د-61096', '2026-05-01', '2018-02-14', 'سائق موقوف مؤقتاً', 'suspended');

-- Insert Vehicles
INSERT INTO vehicles (id, vehicle_code, plate_number, vehicle_type, brand, model, manufacture_year, color, capacity, seat_layout_type, notes, status, seat_configuration) VALUES
('v1111111-1111-1111-1111-111111111111', 'BUS-201', '3300 ق ل', 'Coaster', 'Toyota', 'كوستر', 2020, 'أبيض', 14, 'standard', 'حالة جيدة ومكيفة بالكامل', 'active', '{"rows": 4, "columns": 3, "seats": [{"row": 1, "column": 1, "seat_type": "driver", "seat_number": "D"}, {"row": 1, "column": 3, "seat_type": "passenger", "seat_number": "1"}, {"row": 2, "column": 1, "seat_type": "passenger", "seat_number": "2"}, {"row": 2, "column": 2, "seat_type": "passenger", "seat_number": "3"}, {"row": 2, "column": 3, "seat_type": "passenger", "seat_number": "4"}, {"row": 3, "column": 1, "seat_type": "passenger", "seat_number": "5"}, {"row": 3, "column": 2, "seat_type": "passenger", "seat_number": "6"}, {"row": 3, "column": 3, "seat_type": "passenger", "seat_number": "7"}, {"row": 4, "column": 1, "seat_type": "passenger", "seat_number": "8"}, {"row": 4, "column": 2, "seat_type": "passenger", "seat_number": "9"}, {"row": 4, "column": 3, "seat_type": "passenger", "seat_number": "10"}]}'),
('v2222222-2222-2222-2222-222222222222', 'BUS-202', '3317 ق ل', 'Sprinter', 'Mercedes', 'سبرنتر', 2021, 'فضي', 14, 'VIP', 'مركبة كبار شخصيات VIP', 'active', '{"rows": 4, "columns": 3, "seats": [{"row": 1, "column": 1, "seat_type": "driver", "seat_number": "D"}, {"row": 1, "column": 3, "seat_type": "passenger", "seat_number": "1"}, {"row": 2, "column": 1, "seat_type": "passenger", "seat_number": "2"}, {"row": 2, "column": 2, "seat_type": "passenger", "seat_number": "3"}, {"row": 2, "column": 3, "seat_type": "passenger", "seat_number": "4"}, {"row": 3, "column": 1, "seat_type": "passenger", "seat_number": "5"}, {"row": 3, "column": 2, "seat_type": "passenger", "seat_number": "6"}, {"row": 3, "column": 3, "seat_type": "passenger", "seat_number": "7"}, {"row": 4, "column": 1, "seat_type": "passenger", "seat_number": "8"}, {"row": 4, "column": 2, "seat_type": "passenger", "seat_number": "9"}, {"row": 4, "column": 3, "seat_type": "passenger", "seat_number": "10"}]}'),
('v3333333-3333-3333-3333-333333333333', 'BUS-203', '3334 ق ل', 'Hiace', 'Toyota', 'هايس', 2019, 'رمادي', 14, 'standard', 'صيانة دورية للمحرك والتكييف', 'maintenance', '{"rows": 4, "columns": 3, "seats": [{"row": 1, "column": 1, "seat_type": "driver", "seat_number": "D"}, {"row": 1, "column": 3, "seat_type": "passenger", "seat_number": "1"}, {"row": 2, "column": 1, "seat_type": "passenger", "seat_number": "2"}, {"row": 2, "column": 2, "seat_type": "passenger", "seat_number": "3"}, {"row": 2, "column": 3, "seat_type": "passenger", "seat_number": "4"}, {"row": 3, "column": 1, "seat_type": "passenger", "seat_number": "5"}, {"row": 3, "column": 2, "seat_type": "passenger", "seat_number": "6"}, {"row": 3, "column": 3, "seat_type": "passenger", "seat_number": "7"}, {"row": 4, "column": 1, "seat_type": "passenger", "seat_number": "8"}, {"row": 4, "column": 2, "seat_type": "passenger", "seat_number": "9"}, {"row": 4, "column": 3, "seat_type": "passenger", "seat_number": "10"}]}');

-- Insert Initial Active Assignments
INSERT INTO assignments (id, driver_id, vehicle_id, assigned_at, status, history) VALUES
('a1111111-1111-1111-1111-111111111111', 'd1111111-1111-1111-1111-111111111111', 'v1111111-1111-1111-1111-111111111111', '2026-06-01 08:00:00+02', 'active', '[{"date": "2026-06-01", "title": "تم التعيين", "description": "تم ربط السائق بالمركبة BUS-201 بعد مراجعة الوثائق."}]'::jsonb),
('a2222222-2222-2222-2222-222222222222', 'd2222222-2222-2222-2222-222222222222', 'v2222222-2222-2222-2222-222222222222', '2026-06-02 08:00:00+02', 'active', '[{"date": "2026-06-02", "title": "تم التعيين", "description": "تم ربط السائق بالمركبة BUS-202 بعد مراجعة الوثائق."}]'::jsonb);

-- Insert Documents
INSERT INTO driver_documents (driver_id, type, file_url, expiry_date, status) VALUES
('d1111111-1111-1111-1111-111111111111', 'driver_license', 'https://placeholder.com/license1.jpg', '2026-12-10', 'valid'),
('d4444444-4444-4444-4444-444444444444', 'driver_license', 'https://placeholder.com/license4.jpg', '2026-06-20', 'expiring_soon'),
('d5555555-5555-5555-5555-555555555555', 'driver_license', 'https://placeholder.com/license5.jpg', '2026-05-01', 'expired');

INSERT INTO vehicle_documents (vehicle_id, type, file_url, expiry_date, status) VALUES
('v1111111-1111-1111-1111-111111111111', 'vehicle_license', 'https://placeholder.com/vlicense1.jpg', '2026-12-10', 'valid'),
('v1111111-1111-1111-1111-111111111111', 'insurance', 'https://placeholder.com/ins1.jpg', '2027-01-15', 'valid');

-- ==========================================
-- Supabase Schema for Bookings Management
-- ==========================================

-- 6. Create Operation Bookings Table
CREATE TABLE IF NOT EXISTS operation_bookings (
  id VARCHAR PRIMARY KEY,
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
CREATE OR REPLACE VIEW revenue_daily_view AS
SELECT 
  DATE(created_at) as report_date,
  SUM(CAST(payment_details->>'amount' AS NUMERIC)) as total_bookings_revenue,
  COUNT(*) as total_bookings
FROM operation_bookings
WHERE status != 'rejected'
GROUP BY DATE(created_at);

-- B. Drivers Performance View
CREATE OR REPLACE VIEW drivers_performance_view AS
SELECT 
  d.id as driver_id,
  d.full_name as name,
  d.status,
  COUNT(t.id) as completed_trips,
  SUM(t.revenue) as total_revenue,
  -- Stubbing hours and rating for now as they require timesheets and reviews tables
  80 as total_working_hours, 
  4.5 as rating
FROM drivers d
LEFT JOIN operation_trips t ON t.driver_id = d.id AND t.status = 'completed'
GROUP BY d.id, d.full_name, d.status;

-- C. Vehicles Efficiency View
CREATE OR REPLACE VIEW vehicles_efficiency_view AS
SELECT 
  v.id as vehicle_id,
  v.plate_number,
  v.model,
  v.status,
  COUNT(t.id) as completed_trips,
  12.5 as fuel_consumption, -- Stub
  CASE WHEN v.status = 'maintenance' THEN 'تحتاج صيانة' ELSE 'جاهزة' END as maintenance_status
FROM vehicles v
LEFT JOIN operation_trips t ON t.vehicle_id = v.id AND t.status = 'completed'
GROUP BY v.id, v.plate_number, v.model, v.status;

-- D. Complaints Summary View
CREATE OR REPLACE VIEW complaints_summary_view AS
SELECT 
  category,
  COUNT(id) as total_complaints,
  SUM(CASE WHEN status = 'resolved' OR status = 'closed' THEN 1 ELSE 0 END) as resolved_complaints,
  SUM(CASE WHEN status != 'resolved' AND status != 'closed' THEN 1 ELSE 0 END) as pending_complaints,
  24.0 as avg_resolution_time -- Stub
FROM operation_complaints
GROUP BY category;
