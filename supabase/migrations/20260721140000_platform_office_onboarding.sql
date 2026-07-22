-- =====================================================================================
-- EWT platform administration — office onboarding
-- -------------------------------------------------------------------------------------
-- Until now a second office could only be created by hand: INSERT into offices, create
-- the auth user in the Supabase dashboard, INSERT into office_users, hope the join code
-- did not collide. 090200 states the intent plainly — "creating and deleting offices is
-- a platform action (service_role), never an in-app one" — and 100000 revoked
-- link_office_user from every client-tier role to enforce it.
--
-- This migration keeps that boundary and gives it a door: a platform administrator (and
-- only a platform administrator) can onboard an office end to end, with the office row,
-- its marketplace identity, its join code and its first dashboard operator created in
-- ONE transaction.
--
-- ── The listing axis ────────────────────────────────────────────────────────────────
--
-- A new office has to be two contradictory things at once: workable by its own operator
-- from the first minute, and invisible to passengers until the platform approves it.
-- `status` cannot express both — current_office_context() refuses to sign anyone in
-- unless status = 'active', so the only "hidden" states are also states that lock the
-- office's own staff out of their dashboard.
--
-- So visibility moves onto its own column:
--
--   status         operational   active | paused | suspended | archived
--   listing_status marketplace   draft  | listed | unlisted
--
--   * `draft`    — never been published. Where every onboarded office starts.
--   * `listed`   — appears in the client marketplace. Where every EXISTING office is
--                  backfilled, so nothing about the live platform changes.
--   * `unlisted` — was published, then withdrawn by the platform.
--
-- An office is on the marketplace when status = 'active' AND listing_status = 'listed'.
-- That pair is `office_is_listed()`, and every anon-facing surface moves onto it.
-- `office_is_active()` keeps its literal meaning (the office is operating) and stays
-- the predicate for login, captain recruitment and driver sign-in.
-- =====================================================================================

-- ── 1. The listing column ───────────────────────────────────────────────────────────

alter table public.offices
  add column if not exists listing_status text not null default 'listed',
  add column if not exists listed_at timestamptz;

-- Existing offices are already on the marketplace; the default above covers them, and
-- this backfill covers any row that predates the default with an explicit NULL.
update public.offices set listing_status = 'listed' where listing_status is null;

alter table public.offices drop constraint if exists offices_listing_status_check;
alter table public.offices add constraint offices_listing_status_check
  check (listing_status in ('draft', 'listed', 'unlisted'));

update public.offices
   set listed_at = coalesce(listed_at, created_at)
 where listing_status = 'listed' and listed_at is null;

create index if not exists idx_offices_listed on public.offices (listing_status)
  where listing_status = 'listed';

comment on column public.offices.listing_status is
  'Marketplace visibility, independent of operational `status`. draft = onboarded but '
  'never published; listed = discoverable by clients; unlisted = withdrawn. An office '
  'is visible only when status = ''active'' AND listing_status = ''listed''.';

-- The column is platform-owned: an office publishing itself would defeat approval.
-- 100200 granted UPDATE on a named column list, so listing_status is already excluded
-- from it — this is the belt to that braces, and it survives anyone widening the grant.
revoke update (listing_status) on public.offices from anon, authenticated;

-- Readable, so an office can see in its own dashboard why it is not yet on the
-- marketplace. `offices_operator_read` still restricts that to its own row.
grant select (listing_status, listed_at) on public.offices to anon, authenticated;

-- ── 2. office_is_listed(): the marketplace predicate ────────────────────────────────

create or replace function public.office_is_listed(p_office_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.offices
     where id = p_office_id
       and status = 'active'
       and listing_status = 'listed'
  );
$$;

revoke all on function public.office_is_listed(uuid) from public;
-- Granted to both API roles for the same reason office_is_active() is (100000 §3):
-- it is referenced from RLS policy expressions, which are evaluated with the querying
-- role's privileges, so a revoke turns every guarded query into a permission error
-- instead of an empty result.
grant execute on function public.office_is_listed(uuid) to anon, authenticated;

comment on function public.office_is_listed(uuid) is
  'Is this office on the client marketplace? status = active AND listing_status = '
  'listed. The predicate behind every anon-facing policy and view. Distinct from '
  'office_is_active(), which asks only whether the office is operating.';

-- ── 3. Repoint every marketplace surface onto it ────────────────────────────────────
-- office_is_active() had exactly one class of caller — the anon-facing read paths — so
-- this is a complete sweep, not a partial one. For every office that exists today the
-- two predicates return the same answer (all were backfilled to 'listed'), so this
-- section changes nothing about the live marketplace.

-- 3a. Routes and their stations.
drop policy if exists routes_marketplace_read on public.operation_routes;
create policy routes_marketplace_read on public.operation_routes
  for select to anon, authenticated
  using (status = 'active' and public.office_is_listed(office_id));

drop policy if exists route_stations_marketplace_read on public.route_stations;
create policy route_stations_marketplace_read on public.route_stations
  for select to anon, authenticated
  using (exists (select 1 from public.operation_routes r
                  where r.id = route_id
                    and r.status = 'active'
                    and public.office_is_listed(r.office_id)));

-- 3b. Catalogue tables. Same spec table as 090200 §10, including the guards: promo_codes
-- ships in a hand-applied root-level migration and is absent on some environments.
do $$
declare
  spec record;
begin
  for spec in
    select * from (values
      ('transport_packages',    'active = true',      'anon, authenticated'),
      ('packages',              'status = ''active''', 'anon, authenticated'),
      ('package_vehicle_tiers', 'status = ''active''', 'anon, authenticated'),
      ('promo_codes',
       'is_active = true and (expires_at is null or expires_at > now())',
       'authenticated')
    ) as t(tbl, active_pred, audience)
  loop
    if to_regclass('public.' || spec.tbl) is null then
      raise notice 'platform-onboarding: skipping %, table not present', spec.tbl;
      continue;
    end if;

    execute format('drop policy if exists %I on public.%I',
                   spec.tbl || '_marketplace_read', spec.tbl);
    execute format(
      'create policy %I on public.%I for select to ' || spec.audience
      || ' using (' || spec.active_pred || ' and public.office_is_listed(office_id))',
      spec.tbl || '_marketplace_read', spec.tbl);
  end loop;
end $$;

-- 3c. Trip children (seat map, fare matrix, stop list). 20260721110000 re-founded these
-- on a SECURITY DEFINER helper because passengers hold no SELECT policy on
-- operation_trips any more; the helper keeps that shape and only swaps the predicate.
create or replace function public.trip_office_is_listed(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.operation_trips t
     where t.id = p_trip_id
       and public.office_is_listed(t.office_id)
  );
$$;

revoke all on function public.trip_office_is_listed(uuid) from public;
grant execute on function public.trip_office_is_listed(uuid) to anon, authenticated;

comment on function public.trip_office_is_listed(uuid) is
  'Marketplace visibility of a trip''s children (seats/pricing/stops). SECURITY '
  'DEFINER: policy subqueries run under the caller''s RLS, and passengers hold no '
  'SELECT policy on operation_trips.';

do $$
declare
  t text;
begin
  foreach t in array array['trip_seats', 'trip_pricing', 'trip_route_points']
  loop
    execute format('drop policy if exists %I on public.%I',
                   t || '_marketplace_read', t);
    execute format($f$
      create policy %I on public.%I for select to anon, authenticated
        using (public.trip_office_is_listed(trip_id))
    $f$, t || '_marketplace_read', t);
  end loop;
end $$;

-- Nothing references the old helper now that the three policies are rebuilt. Dropping
-- it rather than leaving it behind means there is one answer to "is this trip public",
-- not two that can drift.
drop function if exists public.trip_office_is_active(uuid);

-- 3d. The public views. Column lists are unchanged, so `create or replace` applies.
create or replace view public.public_driver_profiles
with (security_invoker = false) as
  select d.id,
         d.office_id,
         d.full_name,
         d.profile_image_url,
         d.rating,
         d.rating_count
    from public.drivers d
   where d.status = 'active'
     and public.office_is_listed(d.office_id);

create or replace view public.public_vehicle_profiles
with (security_invoker = false) as
  select v.id,
         v.office_id,
         v.vehicle_code,
         v.vehicle_type,
         v.brand,
         v.model,
         v.manufacture_year,
         v.color,
         v.capacity,
         v.seat_layout_type,
         v.image_url,
         v.rating,
         v.rating_count
    from public.vehicles v
   where v.status = 'active'
     and public.office_is_listed(v.office_id);

create or replace view public.public_trips
with (security_invoker = false) as
  select t.id,
         t.trip_code,
         t.office_id,
         t.route_id,
         t.trip_date,
         t.departure_time,
         t.arrival_time,
         t.actual_start_time,
         t.actual_end_time,
         t.status,
         t.capacity,
         t.booked_seats,
         greatest(t.capacity - t.booked_seats, 0) as available_seats,
         t.ticket_price,
         t.currency,
         case when d.id is not null then
           jsonb_build_object(
             'full_name',         d.full_name,
             'profile_image_url', d.profile_image_url,
             'rating',            d.rating,
             'rating_count',      d.rating_count)
         end as drivers,
         case when v.id is not null then
           jsonb_build_object(
             'vehicle_code',      v.vehicle_code,
             'vehicle_type',      v.vehicle_type,
             'brand',             v.brand,
             'model',             v.model,
             'manufacture_year',  v.manufacture_year,
             'color',             v.color,
             'capacity',          v.capacity,
             'seat_layout_type',  v.seat_layout_type,
             'image_url',         v.image_url,
             'rating',            v.rating,
             'rating_count',      v.rating_count)
         end as vehicles
    from public.operation_trips t
    left join public.drivers  d on d.id = t.driver_id
    left join public.vehicles v on v.id = t.vehicle_id
   where t.status in ('open_for_booking', 'scheduled', 'boarding',
                      'in_progress', 'completed')
     and public.office_is_listed(t.office_id);

-- The office directory itself. Recreated with the same eight columns 100200 fixed it
-- to — the join code must never reappear here by way of a `select *`.
create or replace view public.public_offices
with (security_invoker = false) as
  select o.id,
         o.name,
         o.slug,
         o.logo_url,
         o.description,
         o.service_areas,
         o.rating,
         o.ratings_count
    from public.offices o
   where o.status = 'active'
     and o.listing_status = 'listed';

grant select on public.public_driver_profiles  to anon, authenticated;
grant select on public.public_vehicle_profiles to anon, authenticated;
grant select on public.public_offices          to anon, authenticated;
grant select on public.public_trips            to anon, authenticated;

-- An unlisted office is also absent from the base-table directory, not just the view.
-- `offices_public_read` was written when 'active' meant 'listed'; it no longer does.
drop policy if exists offices_public_read on public.offices;
create policy offices_public_read on public.offices
  for select to anon, authenticated
  using (status = 'active' and listing_status = 'listed');

-- ── 4. A join code worth trusting ───────────────────────────────────────────────────
-- The generator drew from random(), which is a deterministic PRNG seeded per session —
-- fine for picking a colour, not for a credential that gates the captain queue. Same
-- signature, same alphabet, same length (so the column DEFAULT and office_rotate_join_code
-- keep working untouched); the entropy source becomes pgcrypto's CSPRNG.
--
-- 32-glyph alphabet is exactly 5 bits, so masking a random byte with 31 is unbiased.
-- 8 glyphs = 40 bits.

create or replace function public.generate_office_join_code()
returns text
language plpgsql
volatile
set search_path = public, extensions
as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_bytes bytea;
  v_code  text := '';
  i       int;
begin
  begin
    v_bytes := gen_random_bytes(8);
  exception when undefined_function then
    -- pgcrypto absent: degrade to the original generator rather than break every
    -- insert into offices, which carries this function as its column default.
    return (
      select string_agg(substr(v_alphabet, 1 + floor(random() * 32)::int, 1), '')
        from generate_series(1, 8)
    );
  end;

  for i in 0..7 loop
    v_code := v_code || substr(v_alphabet, 1 + (get_byte(v_bytes, i) & 31), 1);
  end loop;
  return v_code;
end;
$$;

revoke all on function public.generate_office_join_code()
  from public, anon, authenticated;

comment on function public.generate_office_join_code() is
  'Crypto-random 8-glyph join code (40 bits) over an alphabet with no ambiguous '
  'glyphs. Uniqueness is not guaranteed here — callers retry against '
  'offices_join_code_key; see next_office_join_code().';

-- Uniqueness belongs with the caller, not the generator: the unique index is on
-- upper(join_code) and only a loop can honour it.
create or replace function public.next_office_join_code()
returns text
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  for i in 1..20 loop
    v_code := public.generate_office_join_code();
    if not exists (
      select 1 from public.offices where upper(join_code) = upper(v_code)
    ) then
      return v_code;
    end if;
  end loop;
  -- 40 bits against a handful of offices: twenty consecutive collisions means the
  -- generator is broken, not that we were unlucky. Fail rather than emit a duplicate.
  raise exception 'join_code_generation_failed';
end;
$$;

revoke all on function public.next_office_join_code()
  from public, anon, authenticated;

-- office_rotate_join_code() hand-rolled the same loop. Point it at the shared one so
-- there is a single definition of "an unused code".
create or replace function public.office_rotate_join_code()
returns text
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
  v_code   text;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if public.office_role() <> 'dashboard_admin' then
    raise exception 'dashboard_admin_required';
  end if;

  v_code := public.next_office_join_code();

  update public.offices
     set join_code = v_code, join_code_rotated_at = now()
   where id = v_office;

  return v_code;
end;
$$;

revoke all on function public.office_rotate_join_code()
  from public, anon, authenticated;
grant execute on function public.office_rotate_join_code() to authenticated;

-- ── 5. A dashboard operator is not a passenger ──────────────────────────────────────
-- handle_new_client_user() fires on EVERY auth.users insert and writes a public.clients
-- row, defaulting phone to '' when the metadata carries none. clients.phone is uniquely
-- constrained, so the first operator provisioned through the Admin API would take the
-- empty phone and the SECOND one would fail — the exact collision 20260708120100 fixed
-- for drivers. Same fix, same shape: skip the row for tagged non-client accounts.
--
-- Deliberately an allow-list of roles rather than "skip unless role = client": the
-- Client app's signUp sends no `role` key at all, and inverting the test would stop
-- creating clients rows for real passengers.

create or replace function public.handle_new_client_user()
returns trigger
language plpgsql
security definer
as $function$
BEGIN
  IF new.raw_user_meta_data->>'role' IN ('driver', 'office_user') THEN
    RETURN new;
  END IF;

  INSERT INTO public.clients (id, full_name, phone, email)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Unknown User'),
    COALESCE(new.raw_user_meta_data->>'phone', new.phone, ''),
    new.email
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$function$;

revoke all on function public.handle_new_client_user()
  from public, anon, authenticated;

-- ── 6. platform_admins is append-only from the backend ──────────────────────────────
-- 100000 revoked the table and re-granted SELECT, which already denies writes. Stating
-- the write revoke explicitly means a future `grant all on all tables` — the shape that
-- created most of the holes 100000 had to close — does not silently reopen the one
-- table that decides who may create offices. There is no INSERT policy either, so a
-- privilege grant alone would still not be enough.

revoke insert, update, delete on public.platform_admins from anon, authenticated;

comment on table public.platform_admins is
  'EWT platform operators. Appointed with service_role only: no INSERT privilege and '
  'no INSERT policy exists for anon or authenticated, so neither an office admin nor '
  'any RPC reachable from the apps can create one.';

-- ── 7. Onboarding: pre-flight ───────────────────────────────────────────────────────
-- Creating the auth user is the one step that cannot join the transaction, so the Edge
-- Function does it first and compensates on failure. This RPC lets it check the two
-- collidable names BEFORE creating anything, which turns the common mistake (a slug or
-- username already in use) from a create-then-roll-back into a plain validation error.
--
-- Availability only. It answers "is this name free", never "who holds it".

create or replace function public.platform_office_onboarding_precheck(
  p_slug     text default null,
  p_username text default null
) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_slug     text := lower(trim(coalesce(p_slug, '')));
  v_username text := lower(trim(coalesce(p_username, '')));
begin
  if not public.is_platform_admin() then
    raise exception 'platform_admin_required';
  end if;

  return jsonb_build_object(
    'slug_available',
      v_slug <> '' and not exists (
        select 1 from public.offices where lower(slug) = v_slug),
    'username_available',
      v_username <> '' and not exists (
        select 1 from public.office_users where lower(username) = v_username)
  );
end;
$$;

revoke all on function public.platform_office_onboarding_precheck(text, text)
  from public, anon, authenticated;
grant execute on function public.platform_office_onboarding_precheck(text, text)
  to authenticated;

-- ── 8. Onboarding: the transaction ──────────────────────────────────────────────────
-- One statement creates the office, its marketplace identity, its join code and its
-- first operator. Either all of it exists or none of it does — a half-onboarded office
-- with no admin is unreachable and invisible, and would have to be cleaned up by hand.
--
-- Authorization is `is_platform_admin()` under the CALLER's JWT, not a trusted flag
-- passed in by the Edge Function. The function therefore needs no privilege of its own
-- to call this, and this RPC is safe even if it were called directly: an office admin
-- executing it gets platform_admin_required.
--
-- Everything the caller supplies is either validated here or ignored here:
--   * office_id       generated, never accepted
--   * join_code       generated, never accepted
--   * role            hard-coded 'dashboard_admin' — the first operator of an office is
--                     its admin by definition, and accepting a role parameter would be
--                     a parameter worth tampering with
--   * status          hard-coded 'active'   — the office's own dashboard works at once
--   * listing_status  hard-coded 'draft'    — invisible to passengers until published

create or replace function public.platform_create_office(
  p_name            text,
  p_admin_user_id   uuid,
  p_admin_username  text,
  p_slug            text default null,
  p_description     text default '',
  p_logo_url        text default null,
  p_phone           text default null,
  p_email           text default null,
  p_service_areas   text[] default '{}',
  p_admin_full_name text default ''
) returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_name        text := trim(coalesce(p_name, ''));
  v_slug        text := lower(trim(coalesce(p_slug, '')));
  v_description text := trim(coalesce(p_description, ''));
  v_logo        text := nullif(trim(coalesce(p_logo_url, '')), '');
  v_phone       text := nullif(trim(coalesce(p_phone, '')), '');
  v_email       text := lower(nullif(trim(coalesce(p_email, '')), ''));
  v_username    text := lower(trim(coalesce(p_admin_username, '')));
  v_full_name   text := trim(coalesce(p_admin_full_name, ''));
  v_areas       text[];
  v_code        text;
  v_office_id   uuid;
  v_area        text;
begin
  if not public.is_platform_admin() then
    raise exception 'platform_admin_required';
  end if;

  -- ── Office identity ──
  if length(v_name) < 3 then
    raise exception 'invalid_office_name';
  end if;
  if length(v_name) > 120 then
    raise exception 'office_name_too_long';
  end if;

  -- Office names are Arabic; slugs are the latin public identifier other rows key off,
  -- so one cannot be derived from the other. Fall back to an opaque unique slug rather
  -- than refusing, and let the platform admin set a readable one later.
  if v_slug = '' then
    v_slug := 'office-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 10);
  end if;
  if v_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' or length(v_slug) < 3 or length(v_slug) > 48 then
    raise exception 'invalid_slug';
  end if;
  if exists (select 1 from public.offices where lower(slug) = v_slug) then
    raise exception 'slug_taken';
  end if;

  if length(v_description) > 500 then
    raise exception 'description_too_long';
  end if;
  if v_logo is not null and v_logo !~* '^https://' then
    -- http:// would be mixed content in the client's image loader and a downgrade
    -- vector for the office's own branding.
    raise exception 'invalid_logo_url';
  end if;
  if v_phone is not null and (length(v_phone) < 7 or length(v_phone) > 20) then
    raise exception 'invalid_phone';
  end if;
  if v_email is not null and v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[a-z]{2,}$' then
    raise exception 'invalid_email';
  end if;

  select array_agg(distinct trim(t.area) order by trim(t.area)) into v_areas
    from unnest(coalesce(p_service_areas, '{}'::text[])) as t(area)
   where trim(t.area) <> '';
  v_areas := coalesce(v_areas, '{}'::text[]);
  if array_length(v_areas, 1) > 30 then
    raise exception 'too_many_service_areas';
  end if;
  foreach v_area in array v_areas loop
    if length(v_area) > 60 then
      raise exception 'invalid_service_area';
    end if;
  end loop;

  -- ── First operator ──
  if p_admin_user_id is null then
    raise exception 'admin_user_required';
  end if;
  if not exists (select 1 from auth.users where id = p_admin_user_id) then
    raise exception 'admin_user_not_found';
  end if;
  -- office_users.user_id is UNIQUE, so this is also enforced by the index. Checking it
  -- explicitly turns "23505" into an error the UI can explain, and — more importantly —
  -- makes it impossible to reach the ON CONFLICT ... DO UPDATE shape that
  -- link_office_user() has, which would MOVE an existing operator to the new office.
  if exists (select 1 from public.office_users where user_id = p_admin_user_id) then
    raise exception 'admin_user_already_assigned';
  end if;

  if v_username !~ '^[a-z0-9][a-z0-9._-]*$'
     or length(v_username) < 3 or length(v_username) > 32 then
    raise exception 'invalid_username';
  end if;
  if exists (select 1 from public.office_users where lower(username) = v_username) then
    raise exception 'username_taken';
  end if;

  -- ── Write ──
  v_code := public.next_office_join_code();

  insert into public.offices (
    name, slug, logo_url, description, phone, email, service_areas,
    status, listing_status, join_code, join_code_rotated_at
  ) values (
    v_name, v_slug, v_logo, v_description, v_phone, v_email, v_areas,
    'active', 'draft', v_code, now()
  )
  returning id into v_office_id;

  insert into public.office_users (
    office_id, user_id, username, full_name, role, status
  ) values (
    v_office_id, p_admin_user_id, v_username, v_full_name, 'dashboard_admin', 'active'
  );

  return jsonb_build_object(
    'office_id',      v_office_id,
    'name',           v_name,
    'slug',           v_slug,
    'status',         'active',
    'listing_status', 'draft',
    'join_code',      v_code,
    'username',       v_username,
    'role',           'dashboard_admin'
  );
end;
$$;

revoke all on function public.platform_create_office(
  text, uuid, text, text, text, text, text, text, text[], text)
  from public, anon, authenticated;
grant execute on function public.platform_create_office(
  text, uuid, text, text, text, text, text, text, text[], text)
  to authenticated;

comment on function public.platform_create_office(
  text, uuid, text, text, text, text, text, text, text[], text) is
  'Onboards an office and its first dashboard_admin in one transaction. Requires '
  'is_platform_admin() under the caller''s own JWT. office_id, join_code, role, status '
  'and listing_status are decided here, never accepted from the caller. The auth.users '
  'row must already exist — that is the Edge Function''s half of the flow.';

-- ── 9. Onboarding: the platform's view of every office ──────────────────────────────
-- RLS on `offices` shows an operator their own row and the listed ones. A platform
-- admin has to see the draft and suspended ones too — those are precisely the offices
-- that need attention. SECURITY DEFINER + an explicit gate, rather than a policy, so
-- the wider visibility exists only inside this one function.
--
-- join_code is NOT returned. The platform admin receives it once, at onboarding, to
-- hand over; after that it is the office's own secret, readable through
-- office_join_code() by its operators and rotatable by them.

create or replace function public.platform_list_offices()
returns table(
  id             uuid,
  name           text,
  slug           text,
  logo_url       text,
  description    text,
  phone          text,
  email          text,
  service_areas  text[],
  status         text,
  listing_status text,
  listed_at      timestamptz,
  rating         numeric,
  ratings_count  int,
  operators      bigint,
  drivers        bigint,
  routes         bigint,
  created_at     timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'platform_admin_required';
  end if;

  return query
    select o.id, o.name, o.slug, o.logo_url, o.description, o.phone, o.email,
           o.service_areas, o.status, o.listing_status, o.listed_at,
           o.rating, o.ratings_count,
           (select count(*) from public.office_users ou
             where ou.office_id = o.id and ou.status = 'active'),
           (select count(*) from public.drivers d
             where d.office_id = o.id and d.status = 'active'),
           (select count(*) from public.operation_routes r
             where r.office_id = o.id),
           o.created_at
      from public.offices o
     order by o.created_at desc;
end;
$$;

revoke all on function public.platform_list_offices()
  from public, anon, authenticated;
grant execute on function public.platform_list_offices() to authenticated;

-- ── 10. Onboarding: publish / withdraw ──────────────────────────────────────────────
-- The approval step that §1 exists for. Listing is refused while the office's
-- marketplace card would be a blank: an office with no description and no service areas
-- in the client's directory is worse for the platform than one that is not there yet.

create or replace function public.platform_set_office_listing(
  p_office_id      uuid,
  p_listing_status text
) returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_office public.offices;
begin
  if not public.is_platform_admin() then
    raise exception 'platform_admin_required';
  end if;
  if p_listing_status not in ('draft', 'listed', 'unlisted') then
    raise exception 'invalid_listing_status';
  end if;

  select * into v_office from public.offices where id = p_office_id;
  if v_office.id is null then
    raise exception 'office_not_found';
  end if;

  if p_listing_status = 'listed' then
    if v_office.status <> 'active' then
      raise exception 'office_not_active';
    end if;
    if trim(coalesce(v_office.description, '')) = ''
       or coalesce(array_length(v_office.service_areas, 1), 0) = 0 then
      raise exception 'office_profile_incomplete';
    end if;
  end if;

  update public.offices
     set listing_status = p_listing_status,
         listed_at = case
           when p_listing_status = 'listed' then coalesce(listed_at, now())
           else listed_at
         end,
         updated_at = now()
   where id = p_office_id;

  return jsonb_build_object(
    'office_id', p_office_id, 'listing_status', p_listing_status);
end;
$$;

revoke all on function public.platform_set_office_listing(uuid, text)
  from public, anon, authenticated;
grant execute on function public.platform_set_office_listing(uuid, text)
  to authenticated;

-- Operational status is a separate lever: suspending an office locks its dashboard and
-- its captains out, which withdrawing a listing deliberately does not.
create or replace function public.platform_set_office_status(
  p_office_id uuid,
  p_status    text
) returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'platform_admin_required';
  end if;
  if p_status not in ('active', 'paused', 'suspended', 'archived') then
    raise exception 'invalid_status';
  end if;
  if not exists (select 1 from public.offices where id = p_office_id) then
    raise exception 'office_not_found';
  end if;

  update public.offices
     set status = p_status, updated_at = now()
   where id = p_office_id;

  return jsonb_build_object('office_id', p_office_id, 'status', p_status);
end;
$$;

revoke all on function public.platform_set_office_status(uuid, text)
  from public, anon, authenticated;
grant execute on function public.platform_set_office_status(uuid, text)
  to authenticated;

-- ── 11. The dashboard needs to know it is talking to a platform admin ───────────────
-- Purely so the shell can show the onboarding module. Every one of the RPCs above
-- re-checks is_platform_admin() server-side, so a client that forged this flag would
-- reach a screen whose every action fails — which is the correct failure mode for a
-- hint. Additive: existing keys are untouched.

create or replace function public.current_office_context()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_ctx record;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  select ou.office_id, ou.role, ou.username, ou.full_name,
         o.name as office_name, o.slug as office_slug, o.logo_url,
         o.status as office_status, o.listing_status as office_listing_status
    into v_ctx
    from public.office_users ou
    join public.offices o on o.id = ou.office_id
   where ou.user_id = v_uid
     and ou.status = 'active'
   limit 1;

  if v_ctx.office_id is null then
    raise exception 'not_an_office_user';
  end if;

  if v_ctx.office_status <> 'active' then
    raise exception 'office_suspended';
  end if;

  return jsonb_build_object(
    'office_id',      v_ctx.office_id,
    'office_name',    v_ctx.office_name,
    'office_slug',    v_ctx.office_slug,
    'logo_url',       v_ctx.logo_url,
    'role',           v_ctx.role,
    'username',       v_ctx.username,
    'full_name',      v_ctx.full_name,
    'listing_status', v_ctx.office_listing_status,
    'is_platform_admin', public.is_platform_admin()
  );
end;
$$;

revoke all on function public.current_office_context() from public, anon, authenticated;
grant execute on function public.current_office_context() to authenticated;

comment on column public.offices.listed_at is
  'When the office was first published to the marketplace. NULL while draft.';
