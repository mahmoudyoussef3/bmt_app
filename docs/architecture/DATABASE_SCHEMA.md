# Database Schema

All tables reside in the `public` schema in PostgreSQL (Supabase).
All primary keys are UUIDs (`uuid default gen_random_uuid()`).
All tables have `created_at` and `updated_at` timestamps.

## `users` (Managed via Supabase Auth + Public Profile)
* `id` (UUID, PK) -> references `auth.users`
* `phone` (VARCHAR, Unique)
* `full_name` (VARCHAR)
* `role` (ENUM: `client`, `driver`, `admin`, `dispatcher`)
* `status` (ENUM: `active`, `suspended`)

## `drivers`
* `id` (UUID, PK)
* `user_id` (UUID, FK -> `users.id`, Unique)
* `employee_code` (VARCHAR, Unique)
* `license_number` (VARCHAR)
* `license_expiry` (DATE)
* `status` (ENUM: `available`, `assigned`, `on_trip`, `suspended`, `license_expired`)

## `vehicles`
* `id` (UUID, PK)
* `plate_number` (VARCHAR, Unique)
* `vehicle_code` (VARCHAR, Unique)
* `brand` (VARCHAR)
* `model` (VARCHAR)
* `capacity` (INTEGER)
* `vehicle_type` (VARCHAR)
* `status` (ENUM: `available`, `assigned`, `in_maintenance`, `on_trip`, `inactive`)

## `assignments`
* `id` (UUID, PK)
* `driver_id` (UUID, FK -> `drivers.id`)
* `vehicle_id` (UUID, FK -> `vehicles.id`)
* `start_date` (TIMESTAMPTZ)
* `end_date` (TIMESTAMPTZ, Nullable)
* `status` (ENUM: `active`, `ended`)
* **Constraints:** A driver or vehicle can only have one `active` assignment at a time.

## `routes`
* `id` (UUID, PK)
* `route_code` (VARCHAR, Unique)
* `name` (VARCHAR)
* `start_city` (VARCHAR)
* `end_city` (VARCHAR)
* `distance_km` (NUMERIC)
* `estimated_duration_mins` (INTEGER)
* `status` (ENUM: `draft`, `active`, `archived`)

## `route_stations`
* `id` (UUID, PK)
* `route_id` (UUID, FK -> `routes.id` ON DELETE CASCADE)
* `sort_order` (INTEGER)
* `name` (VARCHAR)
* `arrival_offset_mins` (INTEGER) -> Minutes from trip start to arrive here
* `pickup_allowed` (BOOLEAN)
* `dropoff_allowed` (BOOLEAN)
* `latitude` (FLOAT8)
* `longitude` (FLOAT8)
* **Constraints:** UNIQUE(`route_id`, `sort_order`)

## `operation_trips`
* `id` (UUID, PK)
* `route_id` (UUID, FK -> `routes.id`)
* `driver_id` (UUID, FK -> `drivers.id`)
* `vehicle_id` (UUID, FK -> `vehicles.id`)
* `trip_date` (DATE)
* `departure_time` (TIME)
* `status` (ENUM: `scheduled`, `boarding`, `in_progress`, `completed`, `cancelled`)
* `capacity` (INTEGER)
* **Indexes:** Index on `(trip_date, status)` for fast upcoming queries.

## `trip_pricing`
* `id` (UUID, PK)
* `trip_id` (UUID, FK -> `operation_trips.id` ON DELETE CASCADE)
* `from_point_id` (UUID, FK -> `route_stations.id`)
* `to_point_id` (UUID, FK -> `route_stations.id`)
* `one_time_price` (NUMERIC)
* `five_days_price` (NUMERIC)
* `monthly_price` (NUMERIC)
* `currency` (VARCHAR) DEFAULT 'EGP'
* `is_active` (BOOLEAN) DEFAULT true
* **Constraints:** UNIQUE(`trip_id`, `from_point_id`, `to_point_id`)

## `trip_seats`
* `id` (UUID, PK)
* `trip_id` (UUID, FK -> `operation_trips.id` ON DELETE CASCADE)
* `seat_label` (VARCHAR) (e.g., 'A1', 'B2')
* `state` (ENUM: `available`, `reserved`, `paid`, `subscription`, `blocked`)
* `passenger_id` (UUID, FK -> `users.id`, Nullable)
* **Constraints:** UNIQUE(`trip_id`, `seat_label`)

## `operation_bookings`
* `id` (UUID, PK)
* `trip_id` (UUID, FK -> `operation_trips.id`)
* `client_id` (UUID, FK -> `users.id`)
* `seat_id` (UUID, FK -> `trip_seats.id`)
* `pickup_station_id` (UUID, FK -> `route_stations.id`)
* `dropoff_station_id` (UUID, FK -> `route_stations.id`)
* `status` (ENUM: `pending`, `confirmed`, `cancelled`, `refunded`)
* `payment_status` (ENUM: `unpaid`, `paid`, `refunded`)
* `payment_method` (ENUM: `cash`, `wallet`, `card`, `subscription`)
* `total_amount` (NUMERIC)
* `qr_code_token` (VARCHAR, Unique)

## `subscriptions` (Packages)
* `id` (UUID, PK)
* `client_id` (UUID, FK -> `users.id`)
* `route_id` (UUID, FK -> `routes.id`)
* `package_type` (ENUM: `five_days`, `ten_days`, `monthly`, `quarterly`)
* `total_trips_allowed` (INTEGER)
* `trips_used` (INTEGER) DEFAULT 0
* `valid_from` (DATE)
* `valid_to` (DATE)
* `status` (ENUM: `active`, `expired`, `cancelled`)

## `notifications`
* `id` (UUID, PK)
* `user_id` (UUID, FK -> `users.id`)
* `title` (VARCHAR)
* `body` (TEXT)
* `is_read` (BOOLEAN) DEFAULT false
* `type` (VARCHAR) (e.g., `trip_reminder`, `booking_confirmed`)

## Soft Delete Rules
All tables implement a `deleted_at` (TIMESTAMPTZ) column. 
Postgres Row Level Security (RLS) policies are configured so that `deleted_at IS NULL` is enforced on all `SELECT` queries unless accessed by an admin bypass role. 
No hard deletes are permitted for audit compliance.
