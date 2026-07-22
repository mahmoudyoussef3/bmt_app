-- =====================================================================================
-- EWT platform administration — office management
-- -------------------------------------------------------------------------------------
-- 20260721140000 gave the platform a door: onboard an office, publish it, withdraw it.
-- What it did not give is a way to LOOK at one. `platform_list_offices()` returns three
-- counts and no way to ask a question of a single office, so the only thing a platform
-- admin can currently decide is "publish / do not publish" — from a card that does not
-- say who runs the office, how many vehicles it has, or what a passenger would actually
-- see if it were published.
--
-- This migration adds the reading half. It creates no new tables, no new authorisation
-- concept and no second listing path: `platform_set_office_listing` remains the only way
-- listing_status ever changes, and `is_platform_admin()` remains the only identity that
-- opens any of it.
--
-- ── What is deliberately NOT returned ───────────────────────────────────────────────
--
-- Neither function touches `auth.users`. The platform admin sees an office's operators
-- by username, full name, role and account status — never their email, and there is no
-- password surface here at all: dashboard logins are `<username>@office.ewt.internal`
-- synthetic addresses that receive no mail, so exposing them would leak a login handle
-- while telling the reader nothing. Resetting an operator's password needs the Auth
-- Admin API and therefore the service-role key, which lives only in the
-- `platform-create-office` Edge Function; until an equivalent function exists for
-- resets, this migration deliberately offers no path to one.
--
-- Likewise absent: captain phone numbers, client PII, Paymob credentials, and every
-- financial column. `bookings` below is a COUNT, not a row set. An office's operational
-- detail belongs to that office's own dashboard, which is already scoped by RLS; the
-- platform sees magnitudes, not contents.
--
-- join_code stays absent for the same reason 140000 left it out: the platform admin
-- receives it once at onboarding to hand over, after which it is the office's own
-- secret, read and rotated through `office_join_code()` / `office_rotate_join_code()`.
-- =====================================================================================

-- ── 1. The list, with enough on it to triage ────────────────────────────────────────
-- Adds five columns to the existing function. The return type of a set-returning
-- function cannot be widened in place, so it is dropped and recreated — the body,
-- the guard and the grant are otherwise unchanged from 20260721140000 §9.
--
--   vehicles       the fleet size behind the office's routes
--   trips          lifetime trips, the cheapest proxy for "has this office ever traded"
--   owner_name     who to contact, so triage does not need a second query per row
--   owner_username the handle that owner signs in with
--   updated_at     when the office record last changed
--
-- owner_* resolve the office's FIRST active dashboard_admin. An office has exactly one
-- at onboarding; if a second is ever added, the oldest is the one shown, which is the
-- account the platform itself created.

drop function if exists public.platform_list_offices();

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
  vehicles       bigint,
  trips          bigint,
  owner_name     text,
  owner_username text,
  created_at     timestamptz,
  updated_at     timestamptz
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
           (select count(*) from public.vehicles v
             where v.office_id = o.id),
           (select count(*) from public.operation_trips t
             where t.office_id = o.id),
           owner.full_name,
           owner.username,
           o.created_at,
           o.updated_at
      from public.offices o
      left join lateral (
        select ou.full_name, ou.username
          from public.office_users ou
         where ou.office_id = o.id
           and ou.role = 'dashboard_admin'
           and ou.status = 'active'
         order by ou.created_at
         limit 1
      ) owner on true
     order by o.created_at desc;
end;
$$;

revoke all on function public.platform_list_offices()
  from public, anon, authenticated;
grant execute on function public.platform_list_offices() to authenticated;

comment on function public.platform_list_offices() is
  'Every office on the platform, including draft/paused/suspended ones RLS hides. '
  'Platform admins only. No auth.users data, no join codes, no financial columns.';

-- ── 2. One office, in full ──────────────────────────────────────────────────────────
-- jsonb rather than a wide row because the payload nests: a list of operators and a
-- marketplace preview object do not flatten into columns without inventing array
-- parallel-arrays, and `platform_set_office_listing` already established jsonb as the
-- shape platform RPCs return.
--
-- `marketplace` reads `public_offices` — the same sanitised view the Client app reads,
-- selected by id. When the office is not on the marketplace the view has no row for it
-- and the key is null, which is the honest answer to "what would a passenger see": it
-- is not a missing value, it is the absence itself, and the UI renders it as such.
-- Reading the real view rather than reconstructing its columns means the preview cannot
-- drift into showing a field the view stops exposing.
--
-- p_office_id is unvalidated on purpose: it is not an authorisation input. The guard
-- above it asks who the CALLER is, and a platform admin is entitled to every office, so
-- there is no id an attacker could substitute to reach something they could not already
-- request. This is the same reason `platform_set_office_listing` takes a bare office id.

create or replace function public.platform_office_details(p_office_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office public.offices;
  v_result jsonb;
begin
  if not public.is_platform_admin() then
    raise exception 'platform_admin_required';
  end if;

  select * into v_office from public.offices where id = p_office_id;
  if v_office.id is null then
    raise exception 'office_not_found';
  end if;

  select jsonb_build_object(
    'id',             v_office.id,
    'name',           v_office.name,
    'slug',           v_office.slug,
    'logo_url',       v_office.logo_url,
    'description',    v_office.description,
    'phone',          v_office.phone,
    'email',          v_office.email,
    'service_areas',  to_jsonb(v_office.service_areas),
    'status',         v_office.status,
    'listing_status', v_office.listing_status,
    'listed_at',      v_office.listed_at,
    'rating',         v_office.rating,
    'ratings_count',  v_office.ratings_count,
    'created_at',     v_office.created_at,
    'updated_at',     v_office.updated_at,

    -- Magnitudes only. Every one of these is a count over a table the office already
    -- owns; none of them carries a row out of it.
    'counts', jsonb_build_object(
      'operators', (select count(*) from public.office_users ou
                     where ou.office_id = v_office.id and ou.status = 'active'),
      'drivers',   (select count(*) from public.drivers d
                     where d.office_id = v_office.id and d.status = 'active'),
      'vehicles',  (select count(*) from public.vehicles v
                     where v.office_id = v_office.id),
      'routes',    (select count(*) from public.operation_routes r
                     where r.office_id = v_office.id),
      'trips',     (select count(*) from public.operation_trips t
                     where t.office_id = v_office.id),
      'bookings',  (select count(*) from public.operation_bookings b
                     where b.office_id = v_office.id),
      'reviews',   (select count(*) from public.trip_reviews tr
                     where tr.office_id = v_office.id)
    ),

    -- Who runs the office. Username and full name only — see the header.
    'operators', coalesce(
      (select jsonb_agg(
                jsonb_build_object(
                  'username',   ou.username,
                  'full_name',  ou.full_name,
                  'role',       ou.role,
                  'status',     ou.status,
                  'created_at', ou.created_at
                ) order by ou.created_at
              )
         from public.office_users ou
        where ou.office_id = v_office.id),
      '[]'::jsonb
    ),

    -- Exactly what the Client marketplace can see, or null when it can see nothing.
    'marketplace', (
      select jsonb_build_object(
               'id',            po.id,
               'name',          po.name,
               'slug',          po.slug,
               'logo_url',      po.logo_url,
               'description',   po.description,
               'service_areas', to_jsonb(po.service_areas),
               'rating',        po.rating,
               'ratings_count', po.ratings_count
             )
        from public.public_offices po
       where po.id = v_office.id
    )
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.platform_office_details(uuid)
  from public, anon, authenticated;
grant execute on function public.platform_office_details(uuid) to authenticated;

comment on function public.platform_office_details(uuid) is
  'Full platform view of one office: identity, operational counts, its operators and '
  'its sanitised marketplace preview. Platform admins only. Reads public_offices for '
  'the preview so it cannot drift from what clients actually see. No auth.users data.';
