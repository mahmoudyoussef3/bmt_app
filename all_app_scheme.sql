-- =====================================================================================
-- BMT Dashboard & Client App - Clean Consolidated Supabase Schema
-- No duplicate tables / Includes one-time dashboard demo seed data / No auth.clients seed data
-- =====================================================================================

create extension if not exists pgcrypto;

create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =====================================================================================
-- 1. Client app base tables
-- =====================================================================================

create table if not exists public.clients (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text unique not null,
  email text unique,
  status text not null default 'active' check (status in ('active', 'blocked', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.routes (
  id uuid primary key default gen_random_uuid(),
  pickup text not null,
  destination text not null,
  duration text not null default '',
  starting_price numeric(12, 2) not null default 0,
  is_popular boolean not null default false,
  status text not null default 'active' check (status in ('active', 'paused', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.packages (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text not null,
  price numeric(12, 2) not null default 0,
  badge text,
  icon_key text,
  days int not null default 30,
  trips_count int not null default 44,
  discount_percent int not null default 0,
  savings_amount numeric(12, 2) not null default 0,
  description text not null default '',
  status text not null default 'active' check (status in ('active', 'paused', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.package_vehicle_tiers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  icon_key text not null,
  extra_fee numeric(12, 2) not null default 0,
  description text not null default '',
  status text not null default 'active' check (status in ('active', 'paused', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =====================================================================================
-- 2. Fleet
-- =====================================================================================

create table if not exists public.drivers (
  id uuid primary key default gen_random_uuid(),
  employee_code text unique not null,
  full_name text not null,
  phone text not null,
  emergency_phone text not null,
  address text not null,
  national_id text unique not null,
  profile_image_url text,
  license_number text unique not null,
  license_expiry_date date not null,
  hire_date date not null,
  notes text,
  status text not null default 'active' check (status in ('active', 'suspended', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  vehicle_code text unique not null,
  plate_number text unique not null,
  vehicle_type text not null,
  brand text not null,
  model text not null,
  manufacture_year int not null,
  color text not null,
  capacity int not null check (capacity > 0),
  seat_layout_type text not null,
  image_url text,
  notes text,
  status text not null default 'active' check (status in ('active', 'maintenance', 'suspended', 'archived')),
  seat_configuration jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.driver_documents (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete cascade,
  type text not null,
  file_url text not null,
  expiry_date date not null,
  status text not null default 'valid' check (status in ('expired', 'expiring_soon', 'valid')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.vehicle_documents (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  type text not null,
  file_url text not null,
  expiry_date date not null,
  status text not null default 'valid' check (status in ('expired', 'expiring_soon', 'valid')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete restrict,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  assigned_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active', 'ended')),
  ended_at timestamptz,
  history jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =====================================================================================
-- 3. Operations routes
-- =====================================================================================

create table if not exists public.operation_routes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  start_city text not null,
  end_city text not null,
  duration text not null default '',
  distance text not null default '',
  status text not null default 'draft' check (status in ('draft', 'active', 'paused', 'archived')),
  notes text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.route_stations (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.operation_routes(id) on delete cascade,
  name text not null,
  area text not null default '',
  arrival_offset text not null default '',
  departure_offset text not null default '',
  location_description text not null default '',
  notes text not null default '',
  sort_order int not null default 0,
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =====================================================================================
-- 4. Trips
-- =====================================================================================

create table if not exists public.operation_trips (
  id uuid primary key default gen_random_uuid(),
  trip_code text unique not null,
  route_id uuid references public.operation_routes(id) on delete set null,
  driver_id uuid references public.drivers(id) on delete set null,
  vehicle_id uuid references public.vehicles(id) on delete set null,
  trip_date date not null,
  departure_time time not null,
  arrival_time time,
  status text not null default 'scheduled' check (status in ('scheduled', 'boarding', 'in_progress', 'completed', 'cancelled')),
  capacity int not null default 0 check (capacity >= 0),
  booked_seats int not null default 0 check (booked_seats >= 0),
  revenue numeric(12, 2) not null default 0,
  passenger_count int not null default 0 check (passenger_count >= 0),
  occupancy_rate numeric(5, 2) not null default 0,
  notes text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.trip_route_points (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.operation_trips(id) on delete cascade,
  route_point_id uuid,
  point_name text not null,
  point_order int not null,
  latitude double precision,
  longitude double precision,
  arrival_offset text,
  departure_offset text,
  created_at timestamptz not null default now()
);

create table if not exists public.trip_seats (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.operation_trips(id) on delete cascade,
  seat_label text not null,
  seat_row int not null,
  seat_column int not null,
  state text not null default 'available' check (state in ('available', 'reserved', 'paid', 'subscription', 'blocked')),
  passenger_id uuid,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.trip_passengers (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.operation_trips(id) on delete cascade,
  customer_id uuid,
  passenger_name text not null,
  phone text not null,
  seat_id uuid references public.trip_seats(id) on delete set null,
  seat_label text not null,
  pickup_point_id uuid,
  pickup_point_name text not null,
  dropoff_point_id uuid,
  dropoff_point_name text not null,
  payment_method text,
  status text not null default 'reserved' check (status in ('reserved', 'confirmed', 'cancelled', 'no_show', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.trip_pricing (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.operation_trips(id) on delete cascade,
  from_point_id uuid not null,
  to_point_id uuid not null,
  from_point_name text not null,
  to_point_name text not null,
  from_point_order int not null,
  to_point_order int not null,
  one_time_price numeric(12, 2) not null default 0 check (one_time_price >= 0),
  five_days_price numeric(12, 2) not null default 0 check (five_days_price >= 0),
  ten_days_price numeric(12, 2) not null default 0 check (ten_days_price >= 0),
  monthly_price numeric(12, 2) not null default 0 check (monthly_price >= 0),
  three_months_price numeric(12, 2) not null default 0 check (three_months_price >= 0),
  currency text not null default 'ج.م',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint valid_trip_pricing_order check (from_point_order < to_point_order)
);

create table if not exists public.trip_events (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.operation_trips(id) on delete cascade,
  title text not null,
  description text not null,
  event_time timestamptz not null default now(),
  done boolean not null default true,
  created_at timestamptz not null default now()
);

-- =====================================================================================
-- 5. Bookings, complaints, subscriptions, loyalty
-- =====================================================================================

create table if not exists public.operation_bookings (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id) on delete set null,
  trip_id uuid references public.operation_trips(id) on delete set null,
  passenger_name text not null,
  phone text not null,
  route text not null,
  trip_time text not null,
  trip_date date not null,
  seat text not null,
  payment_method text not null,
  status text not null default 'newRequest',
  priority text not null default 'normal' check (priority in ('normal', 'urgent', 'vip')),
  assigned_trip text not null default 'غير مسند',
  reviewer_name text,
  rejection_reason text,
  customer_profile jsonb not null default '{}'::jsonb,
  trip_details jsonb not null default '{}'::jsonb,
  payment_details jsonb not null default '{}'::jsonb,
  payment_amount numeric(12, 2) not null default 0,
  attachments jsonb not null default '[]'::jsonb,
  notes jsonb not null default '[]'::jsonb,
  timeline jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.operation_complaints (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id) on delete cascade,
  client_name text not null,
  client_phone text not null,
  category text not null,
  trip_code text,
  assigned_to text,
  status text not null default 'newlyCreated',
  priority text not null default 'low' check (priority in ('low', 'medium', 'high', 'urgent')),
  description text not null,
  conversation jsonb not null default '[]'::jsonb,
  attachments jsonb not null default '[]'::jsonb,
  history jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id) on delete set null,
  customer_name text,
  customer_phone text,
  package_name text not null,
  route_name text,
  start_date date,
  end_date date,
  status text not null default 'active' check (status in ('active', 'expired', 'cancelled', 'paused')),
  total_price numeric(12, 2) not null default 0,
  paid_amount numeric(12, 2) not null default 0,
  remaining_amount numeric(12, 2) not null default 0,
  renewals_count int not null default 0,
  active_users int not null default 0,
  expired_users int not null default 0,
  total_revenue numeric(12, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.loyalty_accounts (
  client_id uuid primary key references public.clients(id) on delete cascade,
  points int not null default 0,
  wallet_balance numeric(12, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.loyalty_transactions (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  title text not null,
  points int not null,
  is_earned boolean not null default true,
  created_at timestamptz not null default now()
);

-- =====================================================================================
-- 6. Existing old-table fixes
-- =====================================================================================

alter table public.operation_bookings add column if not exists payment_amount numeric(12, 2) not null default 0;

alter table public.packages
add column if not exists days int default 30,
add column if not exists trips_count int default 44,
add column if not exists discount_percent int default 0,
add column if not exists savings_amount numeric(12, 2) default 0,
add column if not exists description text default '';


-- =====================================================================================
-- Compatibility fixes for already-created old tables
-- CREATE TABLE IF NOT EXISTS does not add missing columns to existing tables.
-- Keep this before seed data because seed UPSERT statements update updated_at.
-- =====================================================================================

alter table if exists public.routes
add column if not exists updated_at timestamptz not null default now();

alter table if exists public.packages
add column if not exists updated_at timestamptz not null default now();

alter table if exists public.package_vehicle_tiers
add column if not exists updated_at timestamptz not null default now();

alter table if exists public.subscriptions
add column if not exists updated_at timestamptz not null default now();

alter table if exists public.loyalty_accounts
add column if not exists created_at timestamptz not null default now(),
add column if not exists updated_at timestamptz not null default now();

alter table if exists public.operation_bookings
add column if not exists updated_at timestamptz not null default now();

alter table if exists public.operation_trips
add column if not exists updated_at timestamptz not null default now();

alter table if exists public.operation_complaints
add column if not exists updated_at timestamptz not null default now();


-- =====================================================================================
-- 6B. One-time Dashboard Demo Data
-- No auth.clients seed data. This data is operational/dashboard data only.
-- It also feeds client-visible lookup screens such as routes and packages.
-- All inserts are idempotent by fixed UUIDs or unique codes.
-- =====================================================================================

-- Client-visible routes created by dashboard data
insert into public.routes (id, pickup, destination, duration, starting_price, is_popular, status)
values
  ('30000000-0000-0000-0000-000000000001', 'بنها - محطة القطار', 'القرية الذكية', '75 دقيقة', 85.00, true, 'active'),
  ('30000000-0000-0000-0000-000000000002', 'بنها - وسط البلد', 'مدينة نصر', '90 دقيقة', 95.00, true, 'active'),
  ('30000000-0000-0000-0000-000000000003', 'بنها - موقف الأتوبيس', 'التجمع الخامس', '110 دقيقة', 120.00, true, 'active'),
  ('30000000-0000-0000-0000-000000000004', 'القاهرة الجديدة', 'بنها', '105 دقيقة', 110.00, false, 'active')
on conflict (id) do update set
  pickup = excluded.pickup,
  destination = excluded.destination,
  duration = excluded.duration,
  starting_price = excluded.starting_price,
  is_popular = excluded.is_popular,
  status = excluded.status,
  updated_at = now();

insert into public.packages (id, title, subtitle, price, badge, icon_key, days, trips_count, discount_percent, savings_amount, description, status)
values
  ('40000000-0000-0000-0000-000000000001', 'اشتراك أسبوع عمل', '5 أيام متتالية مناسبة لتجربة الخدمة', 380.00, 'تجربة', 'calendar_week', 5, 10, 8, 35.00, 'مناسب للموظفين الذين يريدون تجربة خط ثابت لمدة أسبوع.', 'active'),
  ('40000000-0000-0000-0000-000000000002', 'اشتراك نصف شهر', '10 أيام خلال الشهر', 720.00, 'الأكثر مرونة', 'calendar_half', 10, 20, 12, 100.00, 'مناسب للطلاب والموظفين بنظام حضور جزئي.', 'active'),
  ('40000000-0000-0000-0000-000000000003', 'اشتراك شهري', 'شهر كامل للذهاب والعودة', 1350.00, 'الأكثر اختيارًا', 'calendar_month', 30, 44, 18, 290.00, 'أفضل اختيار للركاب اليوميين على نفس المسار.', 'active'),
  ('40000000-0000-0000-0000-000000000004', 'اشتراك 3 شهور', 'قيمة أفضل لفترة أطول', 3700.00, 'أفضل قيمة', 'stars', 90, 132, 25, 900.00, 'مصمم للركاب الثابتين والشركات الصغيرة.', 'active')
on conflict (id) do update set
  title = excluded.title,
  subtitle = excluded.subtitle,
  price = excluded.price,
  badge = excluded.badge,
  icon_key = excluded.icon_key,
  days = excluded.days,
  trips_count = excluded.trips_count,
  discount_percent = excluded.discount_percent,
  savings_amount = excluded.savings_amount,
  description = excluded.description,
  status = excluded.status,
  updated_at = now();

insert into public.package_vehicle_tiers (id, name, icon_key, extra_fee, description, status)
values
  ('41000000-0000-0000-0000-000000000001', 'اقتصادي', 'bus', 0.00, 'مقعد عادي داخل أتوبيس أو كوستر مكيف.', 'active'),
  ('41000000-0000-0000-0000-000000000002', 'مريح', 'seat', 120.00, 'مقاعد أفضل ومساحة أوسع للرحلات الطويلة.', 'active'),
  ('41000000-0000-0000-0000-000000000003', 'VIP', 'stars', 250.00, 'مركبة مميزة وعدد ركاب أقل.', 'active')
on conflict (id) do update set
  name = excluded.name,
  icon_key = excluded.icon_key,
  extra_fee = excluded.extra_fee,
  description = excluded.description,
  status = excluded.status,
  updated_at = now();

-- Fleet demo data
insert into public.drivers (id, employee_code, full_name, phone, emergency_phone, address, national_id, license_number, license_expiry_date, hire_date, notes, status)
values
  ('10000000-0000-0000-0000-000000000001', 'DRV-001', 'أحمد عبد الرازق', '01022334455', '01244770000', 'بنها - القليوبية', '29801010000001', 'LIC-60001', '2027-12-10', '2021-01-15', 'سائق أساسي لمسار بنها - القرية الذكية.', 'active'),
  ('10000000-0000-0000-0000-000000000002', 'DRV-002', 'مصطفى سمير', '01022335186', '01244770421', 'شبرا الخيمة - القليوبية', '29801010000002', 'LIC-60002', '2027-11-20', '2020-03-20', 'ملتزم بالمواعيد ومناسب للرحلات الصباحية.', 'active'),
  ('10000000-0000-0000-0000-000000000003', 'DRV-003', 'كريم فتحي', '01022335917', '01244770842', 'مدينة نصر - القاهرة', '29801010000003', 'LIC-60003', '2027-09-15', '2022-05-10', 'سائق احتياطي للطوارئ.', 'active'),
  ('10000000-0000-0000-0000-000000000004', 'DRV-004', 'حسن عادل', '01022336648', '01244771263', 'المعادي - القاهرة', '29801010000004', 'LIC-60004', '2026-06-20', '2019-11-01', 'يحتاج متابعة تجديد الرخصة.', 'active')
on conflict (id) do update set
  employee_code = excluded.employee_code,
  full_name = excluded.full_name,
  phone = excluded.phone,
  emergency_phone = excluded.emergency_phone,
  address = excluded.address,
  national_id = excluded.national_id,
  license_number = excluded.license_number,
  license_expiry_date = excluded.license_expiry_date,
  hire_date = excluded.hire_date,
  notes = excluded.notes,
  status = excluded.status,
  updated_at = now();

insert into public.vehicles (id, vehicle_code, plate_number, vehicle_type, brand, model, manufacture_year, color, capacity, seat_layout_type, image_url, notes, status, seat_configuration)
values
  ('20000000-0000-0000-0000-000000000001', 'BUS-201', '3300 ق ل', 'Coaster', 'Toyota', 'كوستر', 2020, 'أبيض', 14, 'standard', null, 'مركبة مكيفة مناسبة للخطوط اليومية.', 'active', '{"rows":4,"columns":4,"seats":[]}'::jsonb),
  ('20000000-0000-0000-0000-000000000002', 'BUS-202', '3317 ق ل', 'Sprinter', 'Mercedes', 'سبرنتر', 2021, 'فضي', 16, 'comfort', null, 'مركبة مريحة لمسارات أكتوبر والقرية الذكية.', 'active', '{"rows":4,"columns":4,"seats":[]}'::jsonb),
  ('20000000-0000-0000-0000-000000000003', 'BUS-203', '3334 ق ل', 'Hiace', 'Toyota', 'هايس', 2019, 'رمادي', 12, 'standard', null, 'تحت الصيانة الدورية.', 'maintenance', '{"rows":3,"columns":4,"seats":[]}'::jsonb),
  ('20000000-0000-0000-0000-000000000004', 'BUS-204', '4488 م د', 'Coaster', 'Toyota', 'كوستر', 2022, 'أزرق', 18, 'vip', null, 'مركبة مميزة للحجوزات عالية الطلب.', 'active', '{"rows":5,"columns":4,"seats":[]}'::jsonb)
on conflict (id) do update set
  vehicle_code = excluded.vehicle_code,
  plate_number = excluded.plate_number,
  vehicle_type = excluded.vehicle_type,
  brand = excluded.brand,
  model = excluded.model,
  manufacture_year = excluded.manufacture_year,
  color = excluded.color,
  capacity = excluded.capacity,
  seat_layout_type = excluded.seat_layout_type,
  image_url = excluded.image_url,
  notes = excluded.notes,
  status = excluded.status,
  seat_configuration = excluded.seat_configuration,
  updated_at = now();

insert into public.assignments (id, driver_id, vehicle_id, assigned_at, status, history)
values
  ('22000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', now() - interval '12 days', 'active', '[{"title":"تم التعيين","description":"تم ربط السائق أحمد بالمركبة BUS-201."}]'::jsonb),
  ('22000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', now() - interval '8 days', 'active', '[{"title":"تم التعيين","description":"تم ربط السائق مصطفى بالمركبة BUS-202."}]'::jsonb),
  ('22000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000004', now() - interval '3 days', 'active', '[{"title":"تم التعيين","description":"تم ربط السائق كريم بالمركبة BUS-204."}]'::jsonb)
on conflict (id) do update set
  driver_id = excluded.driver_id,
  vehicle_id = excluded.vehicle_id,
  assigned_at = excluded.assigned_at,
  status = excluded.status,
  history = excluded.history,
  updated_at = now();

insert into public.driver_documents (id, driver_id, type, file_url, expiry_date, status)
values
  ('23000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'driver_license', 'https://example.com/demo/driver-license-1.pdf', '2027-12-10', 'valid'),
  ('23000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000004', 'driver_license', 'https://example.com/demo/driver-license-4.pdf', '2026-06-20', 'expiring_soon')
on conflict (id) do update set
  driver_id = excluded.driver_id,
  type = excluded.type,
  file_url = excluded.file_url,
  expiry_date = excluded.expiry_date,
  status = excluded.status,
  updated_at = now();

insert into public.vehicle_documents (id, vehicle_id, type, file_url, expiry_date, status)
values
  ('24000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'vehicle_license', 'https://example.com/demo/vehicle-license-1.pdf', '2027-01-15', 'valid'),
  ('24000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'insurance', 'https://example.com/demo/insurance-2.pdf', '2027-02-10', 'valid')
on conflict (id) do update set
  vehicle_id = excluded.vehicle_id,
  type = excluded.type,
  file_url = excluded.file_url,
  expiry_date = excluded.expiry_date,
  status = excluded.status,
  updated_at = now();

-- Operations routes + stations
insert into public.operation_routes (id, name, start_city, end_city, duration, distance, status, notes)
values
  ('50000000-0000-0000-0000-000000000001', 'بنها - القرية الذكية', 'بنها', 'القرية الذكية', '75 دقيقة', '76 كم', 'active', array['مسار صباحي ثابت', 'مناسب للموظفين']),
  ('50000000-0000-0000-0000-000000000002', 'بنها - مدينة نصر', 'بنها', 'مدينة نصر', '90 دقيقة', '82 كم', 'active', array['مسار عالي الطلب', 'يمر بمحطات مركزية']),
  ('50000000-0000-0000-0000-000000000003', 'بنها - التجمع الخامس', 'بنها', 'التجمع الخامس', '110 دقيقة', '95 كم', 'active', array['مسار للجامعات والشركات', 'قابل للتوسع'])
on conflict (id) do update set
  name = excluded.name,
  start_city = excluded.start_city,
  end_city = excluded.end_city,
  duration = excluded.duration,
  distance = excluded.distance,
  status = excluded.status,
  notes = excluded.notes,
  updated_at = now();

insert into public.route_stations (id, route_id, name, area, arrival_offset, departure_offset, location_description, notes, sort_order, latitude, longitude)
values
  ('51000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', 'بنها - محطة القطار', 'بنها', '0 دقيقة', '0 دقيقة', 'أمام محطة قطار بنها', 'نقطة تجمع رئيسية', 1, 30.46630, 31.18480),
  ('51000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000001', 'طوخ', 'طوخ', '20 دقيقة', '23 دقيقة', 'مدخل طوخ الرئيسي', 'توقف سريع', 2, 30.35390, 31.20070),
  ('51000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000001', 'شبرا الخيمة', 'شبرا الخيمة', '42 دقيقة', '45 دقيقة', 'قرب محطة المؤسسة', 'متوقع ازدحام صباحي', 3, 30.12860, 31.24220),
  ('51000000-0000-0000-0000-000000000004', '50000000-0000-0000-0000-000000000001', 'القرية الذكية - البوابة الرئيسية', 'القرية الذكية', '75 دقيقة', '75 دقيقة', 'البوابة الرئيسية للقرية الذكية', 'نقطة الوصول', 4, 30.07220, 31.01890),

  ('51000000-0000-0000-0000-000000000005', '50000000-0000-0000-0000-000000000002', 'بنها - موقف الأتوبيس', 'بنها', '0 دقيقة', '0 دقيقة', 'موقف بنها العمومي', 'نقطة الانطلاق', 1, 30.46250, 31.17860),
  ('51000000-0000-0000-0000-000000000006', '50000000-0000-0000-0000-000000000002', 'رمسيس', 'رمسيس', '55 دقيقة', '58 دقيقة', 'قرب ميدان رمسيس', 'محطة ركوب ونزول', 2, 30.06260, 31.24630),
  ('51000000-0000-0000-0000-000000000007', '50000000-0000-0000-0000-000000000002', 'عباس العقاد', 'مدينة نصر', '90 دقيقة', '90 دقيقة', 'شارع عباس العقاد الرئيسي', 'نقطة الوصول', 3, 30.06380, 31.33700),

  ('51000000-0000-0000-0000-000000000008', '50000000-0000-0000-0000-000000000003', 'بنها - وسط البلد', 'بنها', '0 دقيقة', '0 دقيقة', 'ميدان الإشارة', 'نقطة الانطلاق', 1, 30.46500, 31.18200),
  ('51000000-0000-0000-0000-000000000009', '50000000-0000-0000-0000-000000000003', 'الرحاب', 'الرحاب', '95 دقيقة', '98 دقيقة', 'بوابة الرحاب', 'محطة قبل الوصول', 2, 30.06470, 31.49130),
  ('51000000-0000-0000-0000-000000000010', '50000000-0000-0000-0000-000000000003', 'التجمع الخامس', 'التجمع الخامس', '110 دقيقة', '110 دقيقة', 'شارع التسعين', 'نقطة الوصول', 3, 30.00740, 31.49130)
on conflict (id) do update set
  route_id = excluded.route_id,
  name = excluded.name,
  area = excluded.area,
  arrival_offset = excluded.arrival_offset,
  departure_offset = excluded.departure_offset,
  location_description = excluded.location_description,
  notes = excluded.notes,
  sort_order = excluded.sort_order,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  updated_at = now();

-- Trips + live operational data
insert into public.operation_trips (id, trip_code, route_id, driver_id, vehicle_id, trip_date, departure_time, arrival_time, status, capacity, booked_seats, revenue, passenger_count, occupancy_rate, notes)
values
  ('60000000-0000-0000-0000-000000000001', 'TR-2026-001', '50000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', current_date, '08:00', '09:15', 'in_progress', 14, 9, 765.00, 9, 64.29, array['رحلة مباشرة الآن', 'متابعة من خدمة العملاء']),
  ('60000000-0000-0000-0000-000000000002', 'TR-2026-002', '50000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', current_date, '17:30', '19:00', 'scheduled', 16, 7, 665.00, 7, 43.75, array['رحلة عودة مسائية']),
  ('60000000-0000-0000-0000-000000000003', 'TR-2026-003', '50000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000004', current_date + 1, '07:30', '09:20', 'scheduled', 18, 10, 1200.00, 10, 55.56, array['رحلة غدًا صباحًا']),
  ('60000000-0000-0000-0000-000000000004', 'TR-2026-004', '50000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', current_date - 1, '08:00', '09:18', 'completed', 14, 12, 1020.00, 12, 85.71, array['رحلة مكتملة'])
on conflict (id) do update set
  trip_code = excluded.trip_code,
  route_id = excluded.route_id,
  driver_id = excluded.driver_id,
  vehicle_id = excluded.vehicle_id,
  trip_date = excluded.trip_date,
  departure_time = excluded.departure_time,
  arrival_time = excluded.arrival_time,
  status = excluded.status,
  capacity = excluded.capacity,
  booked_seats = excluded.booked_seats,
  revenue = excluded.revenue,
  passenger_count = excluded.passenger_count,
  occupancy_rate = excluded.occupancy_rate,
  notes = excluded.notes,
  updated_at = now();

insert into public.trip_route_points (id, trip_id, route_point_id, point_name, point_order, latitude, longitude, arrival_offset, departure_offset)
values
  ('61000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-000000000001', 'بنها - محطة القطار', 1, 30.46630, 31.18480, '0 دقيقة', '0 دقيقة'),
  ('61000000-0000-0000-0000-000000000002', '60000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-000000000002', 'طوخ', 2, 30.35390, 31.20070, '20 دقيقة', '23 دقيقة'),
  ('61000000-0000-0000-0000-000000000003', '60000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-000000000003', 'شبرا الخيمة', 3, 30.12860, 31.24220, '42 دقيقة', '45 دقيقة'),
  ('61000000-0000-0000-0000-000000000004', '60000000-0000-0000-0000-000000000001', '51000000-0000-0000-0000-000000000004', 'القرية الذكية - البوابة الرئيسية', 4, 30.07220, 31.01890, '75 دقيقة', '75 دقيقة'),
  ('61000000-0000-0000-0000-000000000005', '60000000-0000-0000-0000-000000000002', '51000000-0000-0000-0000-000000000005', 'بنها - موقف الأتوبيس', 1, 30.46250, 31.17860, '0 دقيقة', '0 دقيقة'),
  ('61000000-0000-0000-0000-000000000006', '60000000-0000-0000-0000-000000000002', '51000000-0000-0000-0000-000000000006', 'رمسيس', 2, 30.06260, 31.24630, '55 دقيقة', '58 دقيقة'),
  ('61000000-0000-0000-0000-000000000007', '60000000-0000-0000-0000-000000000002', '51000000-0000-0000-0000-000000000007', 'عباس العقاد', 3, 30.06380, 31.33700, '90 دقيقة', '90 دقيقة')
on conflict (id) do update set
  trip_id = excluded.trip_id,
  route_point_id = excluded.route_point_id,
  point_name = excluded.point_name,
  point_order = excluded.point_order,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  arrival_offset = excluded.arrival_offset,
  departure_offset = excluded.departure_offset;

insert into public.trip_pricing (id, trip_id, from_point_id, to_point_id, from_point_name, to_point_name, from_point_order, to_point_order, one_time_price, five_days_price, ten_days_price, monthly_price, three_months_price, currency, is_active)
values
  ('62000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', '61000000-0000-0000-0000-000000000001', '61000000-0000-0000-0000-000000000004', 'بنها - محطة القطار', 'القرية الذكية - البوابة الرئيسية', 1, 4, 85.00, 400.00, 760.00, 1450.00, 4050.00, 'ج.م', true),
  ('62000000-0000-0000-0000-000000000002', '60000000-0000-0000-0000-000000000002', '61000000-0000-0000-0000-000000000005', '61000000-0000-0000-0000-000000000007', 'بنها - موقف الأتوبيس', 'عباس العقاد', 1, 3, 95.00, 450.00, 860.00, 1650.00, 4600.00, 'ج.م', true)
on conflict (id) do update set
  trip_id = excluded.trip_id,
  from_point_id = excluded.from_point_id,
  to_point_id = excluded.to_point_id,
  from_point_name = excluded.from_point_name,
  to_point_name = excluded.to_point_name,
  from_point_order = excluded.from_point_order,
  to_point_order = excluded.to_point_order,
  one_time_price = excluded.one_time_price,
  five_days_price = excluded.five_days_price,
  ten_days_price = excluded.ten_days_price,
  monthly_price = excluded.monthly_price,
  three_months_price = excluded.three_months_price,
  currency = excluded.currency,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.trip_seats (id, trip_id, seat_label, seat_row, seat_column, state, passenger_id, notes)
values
  ('63000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', '1', 1, 1, 'paid', null, ''),
  ('63000000-0000-0000-0000-000000000002', '60000000-0000-0000-0000-000000000001', '2', 1, 2, 'reserved', null, ''),
  ('63000000-0000-0000-0000-000000000003', '60000000-0000-0000-0000-000000000001', '3', 1, 3, 'subscription', null, ''),
  ('63000000-0000-0000-0000-000000000004', '60000000-0000-0000-0000-000000000001', '4', 1, 4, 'available', null, ''),
  ('63000000-0000-0000-0000-000000000005', '60000000-0000-0000-0000-000000000001', '5', 2, 1, 'blocked', null, 'صيانة مقعد'),
  ('63000000-0000-0000-0000-000000000006', '60000000-0000-0000-0000-000000000002', '1', 1, 1, 'paid', null, ''),
  ('63000000-0000-0000-0000-000000000007', '60000000-0000-0000-0000-000000000002', '2', 1, 2, 'available', null, ''),
  ('63000000-0000-0000-0000-000000000008', '60000000-0000-0000-0000-000000000002', '3', 1, 3, 'reserved', null, '')
on conflict (id) do update set
  trip_id = excluded.trip_id,
  seat_label = excluded.seat_label,
  seat_row = excluded.seat_row,
  seat_column = excluded.seat_column,
  state = excluded.state,
  passenger_id = excluded.passenger_id,
  notes = excluded.notes,
  updated_at = now();

insert into public.trip_passengers (id, trip_id, customer_id, passenger_name, phone, seat_id, seat_label, pickup_point_id, pickup_point_name, dropoff_point_id, dropoff_point_name, payment_method, status)
values
  ('64000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', null, 'محمود علي', '01011112222', '63000000-0000-0000-0000-000000000001', '1', '61000000-0000-0000-0000-000000000001', 'بنها - محطة القطار', '61000000-0000-0000-0000-000000000004', 'القرية الذكية - البوابة الرئيسية', 'cash', 'confirmed'),
  ('64000000-0000-0000-0000-000000000002', '60000000-0000-0000-0000-000000000001', null, 'سارة حسن', '01033334444', '63000000-0000-0000-0000-000000000002', '2', '61000000-0000-0000-0000-000000000002', 'طوخ', '61000000-0000-0000-0000-000000000004', 'القرية الذكية - البوابة الرئيسية', 'wallet', 'reserved'),
  ('64000000-0000-0000-0000-000000000003', '60000000-0000-0000-0000-000000000002', null, 'أحمد سمير', '01055556666', '63000000-0000-0000-0000-000000000006', '1', '61000000-0000-0000-0000-000000000005', 'بنها - موقف الأتوبيس', '61000000-0000-0000-0000-000000000007', 'عباس العقاد', 'card', 'confirmed')
on conflict (id) do update set
  trip_id = excluded.trip_id,
  customer_id = excluded.customer_id,
  passenger_name = excluded.passenger_name,
  phone = excluded.phone,
  seat_id = excluded.seat_id,
  seat_label = excluded.seat_label,
  pickup_point_id = excluded.pickup_point_id,
  pickup_point_name = excluded.pickup_point_name,
  dropoff_point_id = excluded.dropoff_point_id,
  dropoff_point_name = excluded.dropoff_point_name,
  payment_method = excluded.payment_method,
  status = excluded.status,
  updated_at = now();

insert into public.trip_events (id, trip_id, title, description, event_time, done)
values
  ('65000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', 'بدأت الرحلة', 'تحركت المركبة من بنها في الموعد المحدد.', now() - interval '35 minutes', true),
  ('65000000-0000-0000-0000-000000000002', '60000000-0000-0000-0000-000000000001', 'وصلت طوخ', 'تم تسجيل صعود الركاب من محطة طوخ.', now() - interval '15 minutes', true),
  ('65000000-0000-0000-0000-000000000003', '60000000-0000-0000-0000-000000000002', 'مجدولة', 'الرحلة جاهزة للتحرك مساء اليوم.', now(), false)
on conflict (id) do update set
  trip_id = excluded.trip_id,
  title = excluded.title,
  description = excluded.description,
  event_time = excluded.event_time,
  done = excluded.done;

-- Dashboard bookings, complaints, subscriptions. No auth clients are inserted.
insert into public.operation_bookings (id, client_id, trip_id, passenger_name, phone, route, trip_time, trip_date, seat, payment_method, status, priority, assigned_trip, reviewer_name, rejection_reason, customer_profile, trip_details, payment_details, payment_amount, attachments, notes, timeline)
values
  ('70000000-0000-0000-0000-000000000001', null, '60000000-0000-0000-0000-000000000001', 'محمود علي', '01011112222', 'بنها - القرية الذكية', '08:00', current_date, '1', 'cash', 'confirmed', 'normal', 'TR-2026-001', 'خدمة العملاء', null, '{"name":"محمود علي","phone":"01011112222","email":"demo.passenger1@example.com","tripsCount":"12","accountStatus":"نشط"}'::jsonb, '{"route":"بنها - القرية الذكية","date":"اليوم","time":"08:00","vehicle":"BUS-201","driver":"أحمد عبد الرازق"}'::jsonb, '{"amount":"85","method":"cash","status":"confirmed","reference":"CASH-001"}'::jsonb, 85.00, '[]'::jsonb, '["تم تأكيد الحجز من لوحة خدمة العملاء"]'::jsonb, '[{"action":"تم إنشاء الحجز","actor":"النظام"},{"action":"تم التأكيد","actor":"خدمة العملاء"}]'::jsonb),
  ('70000000-0000-0000-0000-000000000002', null, '60000000-0000-0000-0000-000000000002', 'سارة حسن', '01033334444', 'بنها - مدينة نصر', '17:30', current_date, '2', 'wallet', 'paymentUploaded', 'urgent', 'TR-2026-002', null, null, '{"name":"سارة حسن","phone":"01033334444","email":"demo.passenger2@example.com","tripsCount":"3","accountStatus":"نشط"}'::jsonb, '{"route":"بنها - مدينة نصر","date":"اليوم","time":"17:30","vehicle":"BUS-202","driver":"مصطفى سمير"}'::jsonb, '{"amount":"95","method":"wallet","status":"pending","reference":"WALLET-002"}'::jsonb, 95.00, '["https://example.com/demo/payment-receipt-2.jpg"]'::jsonb, '["بانتظار مراجعة الإيصال"]'::jsonb, '[{"action":"تم إنشاء الحجز","actor":"النظام"},{"action":"تم رفع إيصال","actor":"العميل"}]'::jsonb),
  ('70000000-0000-0000-0000-000000000003', null, '60000000-0000-0000-0000-000000000003', 'أحمد سمير', '01055556666', 'بنها - التجمع الخامس', '07:30', current_date + 1, '1', 'card', 'newRequest', 'vip', 'غير مسند', null, null, '{"name":"أحمد سمير","phone":"01055556666","email":"demo.passenger3@example.com","tripsCount":"1","accountStatus":"جديد"}'::jsonb, '{"route":"بنها - التجمع الخامس","date":"غدًا","time":"07:30","vehicle":"BUS-204","driver":"كريم فتحي"}'::jsonb, '{"amount":"120","method":"card","status":"pending","reference":"CARD-003"}'::jsonb, 120.00, '[]'::jsonb, '[]'::jsonb, '[{"action":"تم إنشاء الحجز","actor":"النظام"}]'::jsonb)
on conflict (id) do update set
  client_id = excluded.client_id,
  trip_id = excluded.trip_id,
  passenger_name = excluded.passenger_name,
  phone = excluded.phone,
  route = excluded.route,
  trip_time = excluded.trip_time,
  trip_date = excluded.trip_date,
  seat = excluded.seat,
  payment_method = excluded.payment_method,
  status = excluded.status,
  priority = excluded.priority,
  assigned_trip = excluded.assigned_trip,
  reviewer_name = excluded.reviewer_name,
  rejection_reason = excluded.rejection_reason,
  customer_profile = excluded.customer_profile,
  trip_details = excluded.trip_details,
  payment_details = excluded.payment_details,
  payment_amount = excluded.payment_amount,
  attachments = excluded.attachments,
  notes = excluded.notes,
  timeline = excluded.timeline,
  updated_at = now();

insert into public.operation_complaints (id, client_id, client_name, client_phone, category, trip_code, assigned_to, status, priority, description, conversation, attachments, history)
values
  ('80000000-0000-0000-0000-000000000001', null, 'محمود علي', '01011112222', 'تأخير', 'TR-2026-001', 'خدمة العملاء', 'newlyCreated', 'medium', 'الرحلة تأخرت عن الوصول المتوقع 10 دقائق.', '[{"from":"client","message":"الأتوبيس اتأخر شوية"}]'::jsonb, '[]'::jsonb, '[{"title":"تم فتح الشكوى","actor":"النظام"}]'::jsonb),
  ('80000000-0000-0000-0000-000000000002', null, 'سارة حسن', '01033334444', 'دفع', 'TR-2026-002', 'المالية', 'inReview', 'high', 'العميلة رفعت إيصال وتحتاج مراجعة.', '[{"from":"client","message":"دفعت من المحفظة"}]'::jsonb, '["https://example.com/demo/payment-receipt-2.jpg"]'::jsonb, '[{"title":"تم التحويل للمالية","actor":"خدمة العملاء"}]'::jsonb)
on conflict (id) do update set
  client_id = excluded.client_id,
  client_name = excluded.client_name,
  client_phone = excluded.client_phone,
  category = excluded.category,
  trip_code = excluded.trip_code,
  assigned_to = excluded.assigned_to,
  status = excluded.status,
  priority = excluded.priority,
  description = excluded.description,
  conversation = excluded.conversation,
  attachments = excluded.attachments,
  history = excluded.history,
  updated_at = now();

insert into public.subscriptions (id, client_id, customer_name, customer_phone, package_name, route_name, start_date, end_date, status, total_price, paid_amount, remaining_amount, renewals_count, active_users, expired_users, total_revenue)
values
  ('90000000-0000-0000-0000-000000000001', null, 'محمود علي', '01011112222', 'اشتراك شهري', 'بنها - القرية الذكية', current_date - 10, current_date + 20, 'active', 1350.00, 1350.00, 0.00, 2, 1, 0, 2700.00),
  ('90000000-0000-0000-0000-000000000002', null, 'سارة حسن', '01033334444', 'اشتراك نصف شهر', 'بنها - مدينة نصر', current_date - 5, current_date + 25, 'active', 720.00, 400.00, 320.00, 0, 1, 0, 400.00),
  ('90000000-0000-0000-0000-000000000003', null, 'أحمد سمير', '01055556666', 'اشتراك أسبوع عمل', 'بنها - التجمع الخامس', current_date - 35, current_date - 5, 'expired', 380.00, 380.00, 0.00, 0, 0, 1, 380.00)
on conflict (id) do update set
  client_id = excluded.client_id,
  customer_name = excluded.customer_name,
  customer_phone = excluded.customer_phone,
  package_name = excluded.package_name,
  route_name = excluded.route_name,
  start_date = excluded.start_date,
  end_date = excluded.end_date,
  status = excluded.status,
  total_price = excluded.total_price,
  paid_amount = excluded.paid_amount,
  remaining_amount = excluded.remaining_amount,
  renewals_count = excluded.renewals_count,
  active_users = excluded.active_users,
  expired_users = excluded.expired_users,
  total_revenue = excluded.total_revenue,
  updated_at = now();

-- =====================================================================================
-- 7. Indexes
-- =====================================================================================

create index if not exists idx_clients_phone on public.clients(phone);
create index if not exists idx_clients_status on public.clients(status);
create index if not exists idx_routes_status on public.routes(status);
create index if not exists idx_routes_popular on public.routes(is_popular);
create index if not exists idx_packages_status on public.packages(status);
create index if not exists idx_drivers_status on public.drivers(status);
create index if not exists idx_vehicles_status on public.vehicles(status);
create index if not exists idx_assignments_driver_id on public.assignments(driver_id);
create index if not exists idx_assignments_vehicle_id on public.assignments(vehicle_id);
create index if not exists idx_assignments_status on public.assignments(status);
create index if not exists idx_operation_routes_status on public.operation_routes(status);
create index if not exists idx_route_stations_route_id on public.route_stations(route_id);
create index if not exists idx_route_stations_sort_order on public.route_stations(route_id, sort_order);
create index if not exists idx_operation_trips_trip_date on public.operation_trips(trip_date);
create index if not exists idx_operation_trips_status on public.operation_trips(status);
create index if not exists idx_operation_trips_driver_id on public.operation_trips(driver_id);
create index if not exists idx_operation_trips_vehicle_id on public.operation_trips(vehicle_id);
create index if not exists idx_trip_route_points_trip_id on public.trip_route_points(trip_id);
create index if not exists idx_trip_seats_trip_id on public.trip_seats(trip_id);
create index if not exists idx_trip_passengers_trip_id on public.trip_passengers(trip_id);
create index if not exists idx_trip_pricing_trip_id on public.trip_pricing(trip_id);
create index if not exists idx_trip_events_trip_id on public.trip_events(trip_id);
create index if not exists idx_operation_bookings_status on public.operation_bookings(status);
create index if not exists idx_operation_bookings_trip_id on public.operation_bookings(trip_id);
create index if not exists idx_operation_bookings_client_id on public.operation_bookings(client_id);
create index if not exists idx_operation_bookings_trip_date on public.operation_bookings(trip_date);
create index if not exists idx_operation_bookings_phone on public.operation_bookings(phone);
create index if not exists idx_operation_complaints_status on public.operation_complaints(status);
create index if not exists idx_operation_complaints_priority on public.operation_complaints(priority);
create index if not exists idx_operation_complaints_category on public.operation_complaints(category);
create index if not exists idx_operation_complaints_client_id on public.operation_complaints(client_id);
create index if not exists idx_subscriptions_client_id on public.subscriptions(client_id);
create index if not exists idx_subscriptions_status on public.subscriptions(status);
create index if not exists idx_loyalty_transactions_client_id on public.loyalty_transactions(client_id);

-- =====================================================================================
-- 8. Updated_at triggers
-- =====================================================================================

drop trigger if exists update_clients_updated_at on public.clients;
create trigger update_clients_updated_at before update on public.clients for each row execute function public.update_updated_at_column();

drop trigger if exists update_routes_updated_at on public.routes;
create trigger update_routes_updated_at before update on public.routes for each row execute function public.update_updated_at_column();

drop trigger if exists update_packages_updated_at on public.packages;
create trigger update_packages_updated_at before update on public.packages for each row execute function public.update_updated_at_column();

drop trigger if exists update_package_vehicle_tiers_updated_at on public.package_vehicle_tiers;
create trigger update_package_vehicle_tiers_updated_at before update on public.package_vehicle_tiers for each row execute function public.update_updated_at_column();

drop trigger if exists update_drivers_updated_at on public.drivers;
create trigger update_drivers_updated_at before update on public.drivers for each row execute function public.update_updated_at_column();

drop trigger if exists update_vehicles_updated_at on public.vehicles;
create trigger update_vehicles_updated_at before update on public.vehicles for each row execute function public.update_updated_at_column();

drop trigger if exists update_driver_documents_updated_at on public.driver_documents;
create trigger update_driver_documents_updated_at before update on public.driver_documents for each row execute function public.update_updated_at_column();

drop trigger if exists update_vehicle_documents_updated_at on public.vehicle_documents;
create trigger update_vehicle_documents_updated_at before update on public.vehicle_documents for each row execute function public.update_updated_at_column();

drop trigger if exists update_assignments_updated_at on public.assignments;
create trigger update_assignments_updated_at before update on public.assignments for each row execute function public.update_updated_at_column();

drop trigger if exists update_operation_routes_updated_at on public.operation_routes;
create trigger update_operation_routes_updated_at before update on public.operation_routes for each row execute function public.update_updated_at_column();

drop trigger if exists update_route_stations_updated_at on public.route_stations;
create trigger update_route_stations_updated_at before update on public.route_stations for each row execute function public.update_updated_at_column();

drop trigger if exists update_operation_trips_updated_at on public.operation_trips;
create trigger update_operation_trips_updated_at before update on public.operation_trips for each row execute function public.update_updated_at_column();

drop trigger if exists update_trip_seats_updated_at on public.trip_seats;
create trigger update_trip_seats_updated_at before update on public.trip_seats for each row execute function public.update_updated_at_column();

drop trigger if exists update_trip_passengers_updated_at on public.trip_passengers;
create trigger update_trip_passengers_updated_at before update on public.trip_passengers for each row execute function public.update_updated_at_column();

drop trigger if exists update_trip_pricing_updated_at on public.trip_pricing;
create trigger update_trip_pricing_updated_at before update on public.trip_pricing for each row execute function public.update_updated_at_column();

drop trigger if exists update_operation_bookings_updated_at on public.operation_bookings;
create trigger update_operation_bookings_updated_at before update on public.operation_bookings for each row execute function public.update_updated_at_column();

drop trigger if exists update_operation_complaints_updated_at on public.operation_complaints;
create trigger update_operation_complaints_updated_at before update on public.operation_complaints for each row execute function public.update_updated_at_column();

drop trigger if exists update_subscriptions_updated_at on public.subscriptions;
create trigger update_subscriptions_updated_at before update on public.subscriptions for each row execute function public.update_updated_at_column();

drop trigger if exists update_loyalty_accounts_updated_at on public.loyalty_accounts;
create trigger update_loyalty_accounts_updated_at before update on public.loyalty_accounts for each row execute function public.update_updated_at_column();

-- =====================================================================================
-- 9. Storage buckets + policies
-- =====================================================================================

insert into storage.buckets (id, name, public) values ('documents', 'documents', true) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('vehicle-images', 'vehicle-images', true) on conflict (id) do nothing;

drop policy if exists documents_public_read on storage.objects;
create policy documents_public_read on storage.objects for select using (bucket_id = 'documents');
drop policy if exists documents_public_upload on storage.objects;
create policy documents_public_upload on storage.objects for insert with check (bucket_id = 'documents');
drop policy if exists documents_public_update on storage.objects;
create policy documents_public_update on storage.objects for update using (bucket_id = 'documents') with check (bucket_id = 'documents');
drop policy if exists documents_public_delete on storage.objects;
create policy documents_public_delete on storage.objects for delete using (bucket_id = 'documents');

drop policy if exists vehicle_images_public_read on storage.objects;
create policy vehicle_images_public_read on storage.objects for select using (bucket_id = 'vehicle-images');
drop policy if exists vehicle_images_public_upload on storage.objects;
create policy vehicle_images_public_upload on storage.objects for insert with check (bucket_id = 'vehicle-images');
drop policy if exists vehicle_images_public_update on storage.objects;
create policy vehicle_images_public_update on storage.objects for update using (bucket_id = 'vehicle-images') with check (bucket_id = 'vehicle-images');
drop policy if exists vehicle_images_public_delete on storage.objects;
create policy vehicle_images_public_delete on storage.objects for delete using (bucket_id = 'vehicle-images');

-- =====================================================================================
-- 10. Analytics views
-- =====================================================================================

drop view if exists public.revenue_daily_view;
create or replace view public.revenue_daily_view as
select
  date(created_at) as report_date,
  coalesce(sum(payment_amount), 0) as total_bookings_revenue,
  count(*) as total_bookings
from public.operation_bookings
where status not in ('rejected', 'cancelled')
group by date(created_at);

drop view if exists public.drivers_performance_view;
create or replace view public.drivers_performance_view as
select
  d.id as driver_id,
  d.full_name as name,
  d.status,
  count(t.id) filter (where t.status = 'completed') as completed_trips,
  coalesce(sum(t.revenue) filter (where t.status = 'completed'), 0) as total_revenue
from public.drivers d
left join public.operation_trips t on t.driver_id = d.id
group by d.id, d.full_name, d.status;

drop view if exists public.vehicles_efficiency_view;
create or replace view public.vehicles_efficiency_view as
select
  v.id as vehicle_id,
  v.plate_number,
  v.model,
  v.status,
  count(t.id) filter (where t.status = 'completed') as completed_trips,
  coalesce(avg(t.occupancy_rate) filter (where t.status = 'completed'), 0) as avg_occupancy_rate,
  case
    when v.status = 'maintenance' then 'تحتاج صيانة'
    when v.status = 'active' then 'جاهزة'
    else 'غير متاحة'
  end as maintenance_status
from public.vehicles v
left join public.operation_trips t on t.vehicle_id = v.id
group by v.id, v.plate_number, v.model, v.status;

drop view if exists public.complaints_summary_view;
create or replace view public.complaints_summary_view as
select
  category,
  count(id) as total_complaints,
  count(id) filter (where status in ('resolved', 'closed')) as resolved_complaints,
  count(id) filter (where status not in ('resolved', 'closed')) as pending_complaints
from public.operation_complaints
group by category;

-- =====================================================================================
-- 11. RLS
-- =====================================================================================

alter table public.clients enable row level security;

drop policy if exists clients_insert_own_profile on public.clients;
create policy clients_insert_own_profile on public.clients for insert to authenticated with check (auth.uid() = id);

drop policy if exists clients_select_own_profile on public.clients;
create policy clients_select_own_profile on public.clients for select to authenticated using (auth.uid() = id);

drop policy if exists clients_update_own_profile on public.clients;
create policy clients_update_own_profile on public.clients for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

alter table public.routes disable row level security;
alter table public.packages disable row level security;
alter table public.package_vehicle_tiers disable row level security;
alter table public.drivers disable row level security;
alter table public.vehicles disable row level security;
alter table public.driver_documents disable row level security;
alter table public.vehicle_documents disable row level security;
alter table public.assignments disable row level security;
alter table public.operation_routes disable row level security;
alter table public.route_stations disable row level security;
alter table public.operation_trips disable row level security;
alter table public.trip_route_points disable row level security;
alter table public.trip_seats disable row level security;
alter table public.trip_passengers disable row level security;
alter table public.trip_pricing disable row level security;
alter table public.trip_events disable row level security;
alter table public.operation_bookings disable row level security;
alter table public.operation_complaints disable row level security;
alter table public.subscriptions disable row level security;
alter table public.loyalty_accounts disable row level security;
alter table public.loyalty_transactions disable row level security;
-- ============================================================
-- Supabase Support Schema & RLS Policies - Safe Re-runnable
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- Tables
-- ============================================================

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references auth.users(id) on delete cascade,
  ticket_number text unique not null,
  category text not null,
  title text not null,
  description text not null,
  priority text not null,
  status text not null default 'open',
  assigned_agent_name text,
  related_booking_id text,
  related_trip_id uuid,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  resolved_at timestamptz,
  closed_at timestamptz
);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid references public.support_tickets(id) on delete cascade,
  sender_type text not null,
  sender_id uuid,
  sender_name text not null,
  message text not null,
  created_at timestamptz default now()
);

create table if not exists public.support_attachments (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid references public.support_tickets(id) on delete cascade,
  message_id uuid references public.support_messages(id) on delete cascade,
  file_url text not null,
  file_name text not null,
  file_type text not null,
  file_size int,
  created_at timestamptz default now()
);

create table if not exists public.support_timeline_events (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid references public.support_tickets(id) on delete cascade,
  title text not null,
  description text not null,
  event_type text not null,
  done boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.refund_requests (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references auth.users(id) on delete cascade,
  ticket_id uuid references public.support_tickets(id) on delete set null,
  booking_id text,
  trip_id uuid,
  reason text not null,
  description text,
  amount numeric(12,2) not null default 0,
  currency text not null default 'EGP',
  status text not null default 'pending',
  evidence_url text,
  reviewed_by text,
  reviewed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================================
-- Safe missing columns
-- ============================================================

alter table public.support_tickets
add column if not exists status text not null default 'open',
add column if not exists updated_at timestamptz default now();

alter table public.refund_requests
add column if not exists updated_at timestamptz default now();

-- ============================================================
-- RLS
-- ============================================================

alter table public.support_tickets enable row level security;
alter table public.support_messages enable row level security;
alter table public.support_attachments enable row level security;
alter table public.support_timeline_events enable row level security;
alter table public.refund_requests enable row level security;

-- ============================================================
-- Indexes
-- ============================================================

create index if not exists support_tickets_client_id_idx
on public.support_tickets(client_id);

create index if not exists support_tickets_status_idx
on public.support_tickets(status);

create index if not exists support_tickets_created_at_idx
on public.support_tickets(created_at);

create index if not exists support_messages_ticket_id_idx
on public.support_messages(ticket_id);

create index if not exists support_attachments_ticket_id_idx
on public.support_attachments(ticket_id);

create index if not exists refund_requests_client_id_idx
on public.refund_requests(client_id);

create index if not exists refund_requests_status_idx
on public.refund_requests(status);

-- ============================================================
-- Updated_at function + triggers
-- ============================================================

create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists update_support_tickets_updated_at
on public.support_tickets;

create trigger update_support_tickets_updated_at
before update on public.support_tickets
for each row execute function public.update_updated_at_column();

drop trigger if exists update_refund_requests_updated_at
on public.refund_requests;

create trigger update_refund_requests_updated_at
before update on public.refund_requests
for each row execute function public.update_updated_at_column();

-- ============================================================
-- Drop old policies safely
-- ============================================================

drop policy if exists "Clients can view their own tickets" on public.support_tickets;
drop policy if exists "Clients can insert their own tickets" on public.support_tickets;
drop policy if exists "Clients can update their own tickets" on public.support_tickets;

drop policy if exists "Clients can view messages for their tickets" on public.support_messages;
drop policy if exists "Clients can insert messages to their tickets" on public.support_messages;

drop policy if exists "Clients can view their ticket attachments" on public.support_attachments;
drop policy if exists "Clients can insert their ticket attachments" on public.support_attachments;

drop policy if exists "Clients can view timeline events for their tickets" on public.support_timeline_events;

drop policy if exists "Clients can view their own refund requests" on public.refund_requests;
drop policy if exists "Clients can insert their own refund requests" on public.refund_requests;
drop policy if exists "Clients can update their own refund requests" on public.refund_requests;

-- Storage policies
drop policy if exists "Public Read Access for Support Attachments" on storage.objects;
drop policy if exists "Authenticated users can upload attachments" on storage.objects;
drop policy if exists "Users can delete own attachments" on storage.objects;

-- ============================================================
-- Create RLS policies
-- ============================================================

create policy "Clients can view their own tickets"
on public.support_tickets
for select
to authenticated
using (auth.uid() = client_id);

create policy "Clients can insert their own tickets"
on public.support_tickets
for insert
to authenticated
with check (auth.uid() = client_id);

create policy "Clients can update their own tickets"
on public.support_tickets
for update
to authenticated
using (auth.uid() = client_id)
with check (auth.uid() = client_id);

create policy "Clients can view messages for their tickets"
on public.support_messages
for select
to authenticated
using (
  exists (
    select 1
    from public.support_tickets
    where support_tickets.id = support_messages.ticket_id
      and support_tickets.client_id = auth.uid()
  )
);

create policy "Clients can insert messages to their tickets"
on public.support_messages
for insert
to authenticated
with check (
  exists (
    select 1
    from public.support_tickets
    where support_tickets.id = support_messages.ticket_id
      and support_tickets.client_id = auth.uid()
  )
  and sender_id = auth.uid()
  and sender_type = 'client'
);

create policy "Clients can view their ticket attachments"
on public.support_attachments
for select
to authenticated
using (
  exists (
    select 1
    from public.support_tickets
    where support_tickets.id = support_attachments.ticket_id
      and support_tickets.client_id = auth.uid()
  )
);

create policy "Clients can insert their ticket attachments"
on public.support_attachments
for insert
to authenticated
with check (
  exists (
    select 1
    from public.support_tickets
    where support_tickets.id = support_attachments.ticket_id
      and support_tickets.client_id = auth.uid()
  )
);

create policy "Clients can view timeline events for their tickets"
on public.support_timeline_events
for select
to authenticated
using (
  exists (
    select 1
    from public.support_tickets
    where support_tickets.id = support_timeline_events.ticket_id
      and support_tickets.client_id = auth.uid()
  )
);

create policy "Clients can view their own refund requests"
on public.refund_requests
for select
to authenticated
using (auth.uid() = client_id);

create policy "Clients can insert their own refund requests"
on public.refund_requests
for insert
to authenticated
with check (auth.uid() = client_id);

create policy "Clients can update their own refund requests"
on public.refund_requests
for update
to authenticated
using (auth.uid() = client_id)
with check (auth.uid() = client_id);

-- ============================================================
-- Storage bucket + policies
-- ============================================================

insert into storage.buckets (id, name, public)
values ('support-attachments', 'support-attachments', true)
on conflict (id) do nothing;

create policy "Public Read Access for Support Attachments"
on storage.objects
for select
using (bucket_id = 'support-attachments');

create policy "Authenticated users can upload attachments"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'support-attachments');

create policy "Users can delete own attachments"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'support-attachments'
  and auth.uid() = owner
);

-- ============================================================
-- Realtime publication - safe add
-- ============================================================

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'support_messages'
  ) then
    alter publication supabase_realtime add table public.support_messages;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'support_tickets'
  ) then
    alter publication supabase_realtime add table public.support_tickets;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'support_timeline_events'
  ) then
    alter publication supabase_realtime add table public.support_timeline_events;
  end if;
end $$;
drop policy if exists "Clients can insert timeline events for their tickets"
on public.support_timeline_events;

create policy "Clients can insert timeline events for their tickets"
on public.support_timeline_events
for insert
to authenticated
with check (
  exists (
    select 1
    from public.support_tickets
    where support_tickets.id = support_timeline_events.ticket_id
      and support_tickets.client_id = auth.uid()
  )
);
