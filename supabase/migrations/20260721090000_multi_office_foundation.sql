-- =====================================================================================
-- EWT multi-office foundation — schema + backfill
-- -------------------------------------------------------------------------------------
-- Turns the single-office platform into a multi-office marketplace by introducing an
-- `offices` root above the existing operational graph.
--
-- Ownership model (decided with the product owner, 2026-07-21):
--
--   EWT platform ── clients, wallet, loyalty, referrals, notifications   (NO office_id)
--        │
--        └── office ── drivers, vehicles, assignments, routes, trips, packages, fares,
--                      payment configuration, office rating
--
--   * A driver belongs to exactly ONE office. A vehicle belongs to exactly ONE office.
--     No many-to-many. national_id / license_number / plate_number therefore stay
--     GLOBALLY unique — they identify a real-world person or asset, not an office row.
--   * Office-internal codes (employee_code, vehicle_code, route_code, trip_code) become
--     unique PER OFFICE: two offices numbering their first trip "TRIP-001" is normal.
--   * booking_number stays globally unique — a passenger sees it across offices in
--     "my trips", so it must not collide platform-wide.
--
-- This migration is ADDITIVE and safe to run while the current apps are live: every
-- office_id starts nullable, is backfilled to the incumbent office, and only then set
-- NOT NULL. It changes NO behaviour on its own — RLS and the RPC guards land in
-- 20260721090200 / 20260721090300, which are the actual cutover.
--
-- EVERY table reference below is guarded by to_regclass. Part of this project's schema
-- history lives in root-level migration_NN_*.sql files that are applied by hand and are
-- NOT tracked in supabase/migrations, so tables such as promo_codes, user_roles, admins
-- and payment_methods may or may not exist on any given environment. A hard reference
-- to one of them would abort the whole migration — as promo_codes did on first run.
-- =====================================================================================

-- ── 1. Offices ──────────────────────────────────────────────────────────────────────

create table if not exists public.offices (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null,
  logo_url text,
  description text not null default '',
  phone text,
  email text,
  service_areas text[] not null default '{}',
  status text not null default 'active'
    check (status in ('active', 'paused', 'suspended', 'archived')),

  -- Denormalised office reputation, maintained by trigger from trip_reviews.
  -- Deliberately NOT derived from driver/vehicle ratings: the office is its own
  -- marketplace entity and is rated explicitly (see 20260721090300).
  rating numeric(3, 2) not null default 0 check (rating >= 0 and rating <= 5),
  ratings_count int not null default 0 check (ratings_count >= 0),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists uq_offices_slug on public.offices (lower(slug));
create index if not exists idx_offices_status on public.offices (status)
  where status = 'active';

drop trigger if exists trg_offices_updated_at on public.offices;
create trigger trg_offices_updated_at before update on public.offices
  for each row execute function public.update_updated_at_column();

-- ── 2. Dashboard users ↔ office ─────────────────────────────────────────────────────
-- user_id is UNIQUE: one dashboard user administers exactly one office. `username` is
-- globally unique so the Name+Password login resolves without an office picker.

create table if not exists public.office_users (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references public.offices(id) on delete cascade,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  username text not null,
  full_name text not null default '',
  role text not null default 'dashboard_admin'
    check (role in ('dashboard_admin', 'support_agent')),
  status text not null default 'active' check (status in ('active', 'disabled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists uq_office_users_username
  on public.office_users (lower(username));
create index if not exists idx_office_users_office on public.office_users (office_id);

drop trigger if exists trg_office_users_updated_at on public.office_users;
create trigger trg_office_users_updated_at before update on public.office_users
  for each row execute function public.update_updated_at_column();

-- ── 3. Per-office payment configuration ─────────────────────────────────────────────
-- Offices collect money independently, so merchant credentials are per office.
-- This table is NEVER readable by the client or by anon — the Edge Function resolves
-- it with the service-role key from the booking's office. RLS below denies everyone;
-- service_role bypasses RLS, which is exactly the intended access path.

create table if not exists public.office_payment_configs (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references public.offices(id) on delete cascade,
  provider text not null default 'paymob'
    check (provider in ('paymob', 'manual')),

  -- Paymob merchant wiring. Null falls back to the platform-level Deno env vars so
  -- the incumbent office keeps working untouched.
  integration_id text,
  iframe_id text,
  api_key text,
  hmac_secret text,

  -- Manual (instapay / wallet / bank transfer) collection details shown to the rider.
  manual_instructions text not null default '',
  manual_account_ref text,

  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists uq_office_payment_configs_provider
  on public.office_payment_configs (office_id, provider);

alter table public.office_payment_configs enable row level security;
-- No policy is created on purpose: with RLS enabled and zero policies, every role
-- except service_role (which bypasses RLS) is denied. Credentials never leave the
-- backend.
revoke all on public.office_payment_configs from anon, authenticated;

drop trigger if exists trg_office_payment_configs_updated_at
  on public.office_payment_configs;
create trigger trg_office_payment_configs_updated_at
  before update on public.office_payment_configs
  for each row execute function public.update_updated_at_column();

-- ── 4. The incumbent office ─────────────────────────────────────────────────────────
-- Fixed UUID so later migrations, seeds and tests can reference it deterministically.
-- The owner renames it from Dashboard → Settings; only the id is load-bearing.

insert into public.offices (id, name, slug, description, status)
values (
  '00000000-0000-0000-0000-0000000000e0',
  'المكتب الرئيسي',
  'main-office',
  'المكتب الأصلي — تم ترحيل جميع البيانات الحالية إليه.',
  'active'
)
on conflict (id) do nothing;

-- ── 5-7. office_id: add, backfill, constrain ───────────────────────────────────────
-- One pass per table so a missing optional table is skipped rather than fatal.
--
--   owns  = office_id is mandatory (NOT NULL + FK restrict)
--   opt   = office_id is nullable  (platform-level rows are legitimate)
--
-- `parent`/`fk` describe how a derived table inherits its office; NULL means the table
-- is owned directly and every existing row belongs to the incumbent office.

do $$
declare
  v_office uuid := '00000000-0000-0000-0000-0000000000e0';
  spec record;
  v_sql text;
begin
  for spec in
    select * from (values
      -- table,                    parent,              fk,           mandatory
      ('operation_routes',         null,                null,          true ),
      ('drivers',                  null,                null,          true ),
      ('vehicles',                 null,                null,          true ),
      ('assignments',              null,                null,          true ),
      ('captain_requests',         null,                null,          true ),
      ('operational_alerts',       null,                null,          true ),
      ('transport_packages',       null,                null,          true ),
      ('packages',                 null,                null,          true ),
      ('package_vehicle_tiers',    null,                null,          true ),
      ('promo_codes',              null,                null,          true ),
      ('subscriptions',            null,                null,          true ),
      ('transport_subscriptions',  null,                null,          true ),
      -- Denormalised one level down so the hottest queries filter without a join.
      ('operation_trips',          'operation_routes',  'route_id',    true ),
      ('operation_bookings',       'operation_trips',   'trip_id',     true ),
      ('booking_payments',         'operation_bookings','booking_id',  true ),
      ('trip_reviews',             'operation_bookings','booking_id',  true ),
      -- Support is office-scoped only when the ticket names a trip. A general
      -- "the app crashed" ticket has no office and stays platform-level.
      -- ⚠ FLAGGED ASSUMPTION — see docs/architecture/MULTI_OFFICE_MIGRATION_AUDIT.md
      ('support_tickets',          'operation_trips',   'related_trip_id', false),
      ('refund_requests',          'operation_trips',   'trip_id',     false)
    ) as t(tbl, parent, fk, mandatory)
  loop
    if to_regclass('public.' || spec.tbl) is null then
      raise notice 'multi-office: skipping %, table not present', spec.tbl;
      continue;
    end if;

    execute format('alter table public.%I add column if not exists office_id uuid',
                   spec.tbl);

    -- Inherit from the parent chain where there is one.
    if spec.parent is not null
       and to_regclass('public.' || spec.parent) is not null then
      execute format(
        'update public.%I c set office_id = p.office_id from public.%I p '
        || 'where p.id = c.%I and c.office_id is null and p.office_id is not null',
        spec.tbl, spec.parent, spec.fk);
    end if;

    -- Everything still unattributed predates multi-office, so it is the incumbent's.
    -- Only for mandatory tables: a platform-level ticket must stay NULL.
    if spec.mandatory then
      execute format(
        'update public.%I set office_id = $1 where office_id is null', spec.tbl)
        using v_office;

      execute format('alter table public.%I alter column office_id set not null',
                     spec.tbl);
    end if;

    execute format('alter table public.%I drop constraint if exists %I',
                   spec.tbl, spec.tbl || '_office_fk');
    execute format(
      'alter table public.%I add constraint %I foreign key (office_id) '
      || 'references public.offices(id) on delete %s',
      spec.tbl, spec.tbl || '_office_fk',
      case when spec.mandatory then 'restrict' else 'set null' end);

    execute format('create index if not exists %I on public.%I (office_id)',
                   'idx_' || spec.tbl || '_office', spec.tbl);
  end loop;
end $$;

-- Composite indexes for the queries the Dashboard runs on every screen.
create index if not exists idx_operation_trips_office_date
  on public.operation_trips (office_id, trip_date desc);
create index if not exists idx_operation_bookings_office_created
  on public.operation_bookings (office_id, created_at desc);
create index if not exists idx_drivers_office_status
  on public.drivers (office_id, status);
create index if not exists idx_vehicles_office_status
  on public.vehicles (office_id, status);

do $$
begin
  if to_regclass('public.operational_alerts') is not null then
    create index if not exists idx_operational_alerts_office_unread
      on public.operational_alerts (office_id, created_at desc) where is_read = false;
  end if;
end $$;

-- ── 8. Keep the denormalised office_id honest ───────────────────────────────────────
-- Application code never sets office_id on these tables; the chain decides it. That
-- also closes the "client posts a forged office_id" vector for reviews and bookings.

create or replace function public.sync_trip_office()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.route_id is not null then
    select office_id into new.office_id
      from public.operation_routes where id = new.route_id;
  end if;
  if new.office_id is null then
    raise exception 'trip_office_unresolved';
  end if;
  return new;
end $$;

drop trigger if exists trg_operation_trips_office on public.operation_trips;
create trigger trg_operation_trips_office
  before insert or update of route_id on public.operation_trips
  for each row execute function public.sync_trip_office();

create or replace function public.sync_booking_office()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.trip_id is not null then
    select office_id into new.office_id
      from public.operation_trips where id = new.trip_id;
  end if;
  if new.office_id is null then
    raise exception 'booking_office_unresolved';
  end if;
  return new;
end $$;

drop trigger if exists trg_operation_bookings_office on public.operation_bookings;
create trigger trg_operation_bookings_office
  before insert or update of trip_id on public.operation_bookings
  for each row execute function public.sync_booking_office();

create or replace function public.sync_child_office_from_booking()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  select office_id into new.office_id
    from public.operation_bookings where id = new.booking_id;
  if new.office_id is null then
    raise exception 'office_unresolved_for_booking';
  end if;
  return new;
end $$;

do $$
begin
  if to_regclass('public.booking_payments') is not null then
    drop trigger if exists trg_booking_payments_office on public.booking_payments;
    create trigger trg_booking_payments_office
      before insert on public.booking_payments
      for each row execute function public.sync_child_office_from_booking();
  end if;

  if to_regclass('public.trip_reviews') is not null then
    drop trigger if exists trg_trip_reviews_office on public.trip_reviews;
    create trigger trg_trip_reviews_office
      before insert on public.trip_reviews
      for each row execute function public.sync_child_office_from_booking();
  end if;
end $$;

-- ── 9. Re-scope office-internal unique codes ────────────────────────────────────────
-- Global uniqueness on these would make office #2 fail on its first driver or trip.
-- Real-world identifiers (national_id, license_number, plate_number) intentionally
-- keep their global uniqueness — one driver / one vehicle belongs to one office.

do $$
declare
  spec record;
begin
  for spec in
    select * from (values
      ('drivers',          'employee_code', 'drivers_employee_code_key'),
      ('vehicles',         'vehicle_code',  'vehicles_vehicle_code_key'),
      ('operation_trips',  'trip_code',     'operation_trips_trip_code_key'),
      ('operation_routes', 'route_code',    'operation_routes_route_code_key')
    ) as t(tbl, col, old_name)
  loop
    -- route_code arrives with a hand-applied migration and may be absent.
    if to_regclass('public.' || spec.tbl) is null
       or not exists (
         select 1 from information_schema.columns
          where table_schema = 'public' and table_name = spec.tbl
            and column_name = spec.col
       ) then
      raise notice 'multi-office: skipping unique re-scope for %.%', spec.tbl, spec.col;
      continue;
    end if;

    execute format('alter table public.%I drop constraint if exists %I',
                   spec.tbl, spec.old_name);
    execute format('drop index if exists public.%I', spec.old_name);
    execute format('create unique index if not exists %I on public.%I (office_id, %I)',
                   'uq_' || spec.tbl || '_office_' || spec.col, spec.tbl, spec.col);
  end loop;

  -- Support ticket numbers: per office, with platform-level tickets sharing one
  -- global namespace (office_id is null there, and NULLs never collide in a
  -- composite unique index — hence the explicit partial pair).
  if to_regclass('public.support_tickets') is not null then
    alter table public.support_tickets
      drop constraint if exists support_tickets_ticket_number_key;
    drop index if exists public.support_tickets_ticket_number_key;
    create unique index if not exists uq_support_tickets_office_number
      on public.support_tickets (office_id, ticket_number) where office_id is not null;
    create unique index if not exists uq_support_tickets_platform_number
      on public.support_tickets (ticket_number) where office_id is null;
  end if;
end $$;

-- operation_bookings.booking_number stays GLOBALLY unique on purpose (rider-facing
-- across offices) — no change here.

-- ── 10. trip_events.event_code ──────────────────────────────────────────────────────
-- The Client app currently infers trip state by matching Arabic `title` text
-- (tracking_state_model.dart). That silently breaks the moment a second office words
-- its events differently, so state moves onto a stable machine code.

alter table public.trip_events
  add column if not exists event_code text;

update public.trip_events
   set event_code = case
     when title ilike '%اكتملت%'                     then 'trip_completed'
     when title ilike '%غادر%'                       then 'trip_departed'
     when title ilike '%صعود%'                       then 'boarding_started'
     when title ilike '%وصل السائق%'                 then 'driver_arrived'
     when title ilike '%في الطريق%'                  then 'driver_en_route'
     else 'other'
   end
 where event_code is null;

alter table public.trip_events alter column event_code set default 'other';
alter table public.trip_events alter column event_code set not null;

create index if not exists idx_trip_events_trip_code
  on public.trip_events (trip_id, event_code);

comment on column public.trip_events.event_code is
  'Stable machine code for trip state. Clients MUST branch on this, never on title '
  '— title is free Arabic prose and varies per office.';

-- ── 11. Migrate existing dashboard staff onto office_users ──────────────────────────
-- Every current non-client, non-driver operator becomes an office_users row on the
-- incumbent office, so existing staff keep working after the auth cutover. Username
-- defaults to the email local-part; the owner can rename it later.
--
-- Both source tables come from hand-applied migrations, so both are guarded.

do $$
declare
  v_office uuid := '00000000-0000-0000-0000-0000000000e0';
begin
  if to_regclass('public.user_roles') is not null then
    insert into public.office_users
      (office_id, user_id, username, full_name, role, status)
    select v_office,
           ur.user_id,
           lower(split_part(au.email, '@', 1)),
           coalesce(au.raw_user_meta_data ->> 'full_name', ''),
           case when ur.role = 'support_agent' then 'support_agent'
                else 'dashboard_admin' end,
           'active'
      from public.user_roles ur
      join auth.users au on au.id = ur.user_id
     where ur.role not in ('client', 'driver')
       and au.email is not null
    on conflict (user_id) do nothing;
  end if;

  if to_regclass('public.admins') is not null then
    insert into public.office_users
      (office_id, user_id, username, full_name, role, status)
    select v_office,
           a.user_id,
           lower(split_part(au.email, '@', 1)),
           coalesce(au.raw_user_meta_data ->> 'full_name', ''),
           'dashboard_admin',
           'active'
      from public.admins a
      join auth.users au on au.id = a.user_id
     where au.email is not null
    on conflict (user_id) do nothing;
  end if;
end $$;

-- ── 12. Realtime ────────────────────────────────────────────────────────────────────

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public' and tablename = 'offices'
    ) then
      alter publication supabase_realtime add table public.offices;
    end if;
  end if;
end $$;

comment on table public.offices is
  'A transportation office on the EWT marketplace. Root of all operational ownership.';
comment on table public.office_users is
  'Dashboard operators. user_id is UNIQUE: one operator administers exactly one office.';
comment on table public.office_payment_configs is
  'Per-office merchant credentials. RLS-enabled with NO policies — only service_role '
  '(the Edge Function) can read this. Never expose to the client.';
