-- Operational workflow fields for Fleet, Routes, Trips, Client, and Captain apps.
-- Dashboard remains the source of truth; these columns are additive and safe for
-- existing deployments.

alter table public.operation_routes
add column if not exists route_code text;

update public.operation_routes
set route_code = 'R-' || upper(substr(replace(id::text, '-', ''), 1, 8))
where route_code is null or btrim(route_code) = '';

alter table public.operation_routes
alter column route_code set not null;

create unique index if not exists operation_routes_route_code_key
on public.operation_routes(route_code);

alter table public.route_stations
add column if not exists pickup_allowed boolean not null default true,
add column if not exists dropoff_allowed boolean not null default true,
add column if not exists estimated_arrival_time time;

update public.route_stations
set pickup_allowed = true
where pickup_allowed is null;

update public.route_stations
set dropoff_allowed = true
where dropoff_allowed is null;

alter table public.operation_trips
add column if not exists ticket_price numeric(12, 2) not null default 0,
add column if not exists currency text not null default 'ج.م';

create index if not exists idx_operation_routes_route_code
on public.operation_routes(route_code);

create index if not exists idx_route_stations_pickup_allowed
on public.route_stations(pickup_allowed);

create index if not exists idx_route_stations_dropoff_allowed
on public.route_stations(dropoff_allowed);

create index if not exists idx_operation_trips_schedule_resources
on public.operation_trips(trip_date, departure_time, driver_id, vehicle_id);
