-- =====================================================================================
-- EWT multi-office — identity resolution
-- -------------------------------------------------------------------------------------
-- Establishes the three questions every policy and RPC downstream needs to answer:
--
--   current_office_id()  — which office does the signed-in DASHBOARD user administer?
--   captain_office_id()  — which office does the signed-in CAPTAIN belong to?
--   office_role()        — is this operator an admin or a support agent?
--
-- Dashboard login is Name + Password and nothing else. Supabase Auth needs an email
-- internally, so `resolve_office_user_login` maps a username to the account's login
-- email exactly the way `resolve_captain_login` already maps a phone number — the same
-- proven pattern, so the app keeps one mental model. The synthetic address never
-- surfaces in the UI.
--
-- Trade-off, stated plainly: resolve_office_user_login is anon-callable and returns the
-- login email for a valid, active username. Someone who guesses a username learns that
-- internal address. It reveals no credential and grants no access — the password is
-- still verified by GoTrue — and there is no way to sign in through the Supabase client
-- SDK without knowing the email. New operators are provisioned with a synthetic
-- `@office.ewt.internal` address so nothing personal is exposed for them at all.
-- =====================================================================================

-- ── 1. Who is the caller? ───────────────────────────────────────────────────────────

-- The office the signed-in dashboard operator administers. NULL for anon, for clients,
-- and for captains — which is what makes the RLS policies deny by default.
create or replace function public.current_office_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select office_id
    from public.office_users
   where user_id = auth.uid()
     and status = 'active'
   limit 1;
$$;

-- The office the signed-in captain belongs to, via their driver row.
create or replace function public.captain_office_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select office_id
    from public.drivers
   where user_id = auth.uid()
     and status = 'active'
   limit 1;
$$;

-- The signed-in captain's driver row. Every captain-facing policy needs this, and
-- inlining the subquery in each policy made them unreadable.
create or replace function public.current_driver_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id
    from public.drivers
   where user_id = auth.uid()
     and status = 'active'
   limit 1;
$$;

create or replace function public.office_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role
    from public.office_users
   where user_id = auth.uid()
     and status = 'active'
   limit 1;
$$;

-- `is_admin()` predates offices and is referenced by policies and RPCs written before
-- this migration. Redefining it here — rather than dropping it — keeps every existing
-- reference compiling while giving it the correct meaning: an active operator of SOME
-- office. Office *scoping* is then enforced by the office_id predicates in
-- 20260721090200; this function only answers "is this an operator at all".
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.office_users
     where user_id = auth.uid() and status = 'active'
  );
$$;

-- Convenience: does the caller operate this specific office?
create or replace function public.is_office_member(p_office_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_office_id is not null
     and p_office_id = public.current_office_id();
$$;

-- ── 2. Name + password login ────────────────────────────────────────────────────────

create or replace function public.resolve_office_user_login(p_username text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text := lower(trim(coalesce(p_username, '')));
  v_user     record;
begin
  if length(v_username) < 3 then
    return jsonb_build_object('outcome', 'not_found');
  end if;

  select ou.user_id, ou.office_id, ou.role, ou.full_name, ou.status, au.email
    into v_user
    from public.office_users ou
    join auth.users au on au.id = ou.user_id
   where lower(ou.username) = v_username
   limit 1;

  -- One generic outcome for "no such user" and "disabled": the login screen must not
  -- become a directory of who works here.
  if v_user.user_id is null or v_user.status <> 'active' or v_user.email is null then
    return jsonb_build_object('outcome', 'not_found');
  end if;

  return jsonb_build_object(
    'outcome',     'ready',
    'login_email', v_user.email,
    'full_name',   v_user.full_name,
    'role',        v_user.role
  );
end;
$$;

revoke all on function public.resolve_office_user_login(text) from public;
grant execute on function public.resolve_office_user_login(text) to anon, authenticated;

-- What the dashboard calls right after a successful signInWithPassword, to load the
-- office context in one round-trip. Authenticated-only, and it answers strictly for
-- the caller — there is no user_id parameter to tamper with.
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
         o.name as office_name, o.slug as office_slug, o.logo_url, o.status as office_status
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
    'office_id',   v_ctx.office_id,
    'office_name', v_ctx.office_name,
    'office_slug', v_ctx.office_slug,
    'logo_url',    v_ctx.logo_url,
    'role',        v_ctx.role,
    'username',    v_ctx.username,
    'full_name',   v_ctx.full_name
  );
end;
$$;

revoke all on function public.current_office_context() from public;
grant execute on function public.current_office_context() to authenticated;

-- ── 3. Provisioning ─────────────────────────────────────────────────────────────────
-- Creating the auth.users row itself stays a Supabase-admin operation (Admin API or
-- the Supabase dashboard) — writing encrypted_password and auth.identities by hand from
-- SQL is fragile and version-coupled. This RPC binds an already-created auth user to an
-- office, which is the part the product actually owns.
--
-- Provision new operators with a synthetic address, e.g.
--   ops-cairo@office.ewt.internal
-- so no personal email is ever returned by resolve_office_user_login.

create or replace function public.link_office_user(
  p_user_id   uuid,
  p_office_id uuid,
  p_username  text,
  p_role      text default 'dashboard_admin',
  p_full_name text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text := lower(trim(coalesce(p_username, '')));
begin
  -- Only an existing admin OF THAT OFFICE may add operators to it. service_role
  -- bypasses this (auth.uid() is null) so the platform owner can bootstrap office #1.
  if auth.uid() is not null then
    if public.current_office_id() is distinct from p_office_id
       or public.office_role() <> 'dashboard_admin' then
      raise exception 'not_authorized';
    end if;
  end if;

  if length(v_username) < 3 then
    raise exception 'username_too_short';
  end if;
  if p_role not in ('dashboard_admin', 'support_agent') then
    raise exception 'invalid_role';
  end if;

  insert into public.office_users (office_id, user_id, username, full_name, role, status)
  values (p_office_id, p_user_id, v_username, coalesce(p_full_name, ''), p_role, 'active')
  on conflict (user_id) do update
    set office_id = excluded.office_id,
        username  = excluded.username,
        full_name = excluded.full_name,
        role      = excluded.role,
        status    = 'active',
        updated_at = now();

  return jsonb_build_object('ok', true, 'user_id', p_user_id, 'office_id', p_office_id);
end;
$$;

revoke all on function public.link_office_user(uuid, uuid, text, text, text) from public;
grant execute on function public.link_office_user(uuid, uuid, text, text, text)
  to authenticated;

-- ── 4. Captain login now carries the office ─────────────────────────────────────────
-- Same contract as before (phone → derived credentials), with two changes:
--   * the office is returned, so the app never has to ask or guess;
--   * a driver whose office is suspended cannot sign in.

create or replace function public.resolve_captain_login(p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_phone_norm text := public.normalize_egyptian_phone(coalesce(p_phone, ''));
  v_driver public.drivers;
  v_office public.offices;
begin
  if length(v_phone_norm) < 10 then
    raise exception 'رقم الهاتف غير صالح' using errcode = '22023';
  end if;

  select * into v_driver
  from public.drivers d
  where public.normalize_egyptian_phone(d.phone) = v_phone_norm
    and d.status = 'active'
  order by d.created_at
  limit 1;

  if not found then
    return jsonb_build_object('outcome', 'not_registered');
  end if;

  select * into v_office from public.offices where id = v_driver.office_id;

  if v_office.id is null or v_office.status <> 'active' then
    return jsonb_build_object('outcome', 'office_inactive');
  end if;

  return jsonb_build_object(
    'outcome',       'ready',
    'login_email',   v_phone_norm || '@captain.bmt-app.internal',
    'login_secret',  encode(hmac(v_phone_norm, 'bmt-captain-login-v1', 'sha256'), 'hex'),
    'full_name',     v_driver.full_name,
    'employee_code', v_driver.employee_code,
    'office_id',     v_office.id,
    'office_name',   v_office.name
  );
end;
$$;

grant execute on function public.resolve_captain_login(text) to anon, authenticated;

-- link_current_captain_driver now returns the office too, and refuses to re-point a
-- driver row that is already bound to a different auth user — the previous version
-- rebound unconditionally, which let a phone-number collision hijack another captain.
create or replace function public.link_current_captain_driver(p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_phone_norm text := public.normalize_egyptian_phone(coalesce(p_phone, ''));
  v_driver public.drivers;
  v_office public.offices;
begin
  if v_uid is null then
    raise exception 'Authentication is required';
  end if;

  select * into v_driver
  from public.drivers d
  where public.normalize_egyptian_phone(d.phone) = v_phone_norm
    and d.status = 'active'
  order by d.created_at
  limit 1;

  if not found then
    raise exception 'رقم الهاتف غير مسجل كسائق نشط';
  end if;

  if v_driver.user_id is not null and v_driver.user_id <> v_uid then
    raise exception 'driver_already_linked';
  end if;

  select * into v_office from public.offices where id = v_driver.office_id;
  if v_office.id is null or v_office.status <> 'active' then
    raise exception 'office_inactive';
  end if;

  update public.drivers
     set user_id = v_uid,
         updated_at = now()
   where id = v_driver.id;

  return jsonb_build_object(
    'driver_id',     v_driver.id,
    'full_name',     v_driver.full_name,
    'phone',         v_driver.phone,
    'employee_code', v_driver.employee_code,
    'office_id',     v_office.id,
    'office_name',   v_office.name
  );
end;
$$;

grant execute on function public.link_current_captain_driver(text) to authenticated;

comment on function public.current_office_id() is
  'Office of the signed-in dashboard operator. NULL for anon/client/captain — this is '
  'what makes the office RLS policies deny by default.';
comment on function public.captain_office_id() is
  'Office of the signed-in captain, resolved through their drivers row.';
