-- =====================================================================================
-- EWT dashboard — self-service office registration
-- -------------------------------------------------------------------------------------
-- 20260721140000 gave the platform a door for onboarding an office: a platform admin
-- fills a form, an Edge Function mints the auth user with the service-role key, and
-- `platform_create_office` writes the office in one transaction. That flow stays exactly
-- as it is — it is how EWT onboards an office it has already spoken to, complete with
-- a temporary password to hand over.
--
-- This migration adds the other door: an operator arrives at the dashboard with no
-- account at all, signs up with email + password + the name of their office, and lands
-- in their own workspace. No platform admin in the loop, and no service-role key
-- anywhere — the auth user is created by the client SDK's own `signUp`, which is the
-- one account-creation path that is safe to expose to an unauthenticated caller.
--
-- ── What stops this from being a hole ───────────────────────────────────────────────
--
-- Self-registration creates an office that is `active` (its own dashboard works from the
-- first minute) and `draft` (invisible to every passenger). That is the whole safety
-- model, and it is the same one onboarding already relies on: publishing to the
-- marketplace remains `platform_set_office_listing`, which remains platform-admin-only.
-- Someone who signs up with a throwaway address gets a private workspace nobody can
-- book from, not a listing.
--
-- Everything else that could be worth tampering with is decided here, not accepted:
--
--   * user_id        always auth.uid() — there is no parameter for it, so this cannot
--                    provision an office for anyone but the caller
--   * role           hard-coded 'dashboard_admin'
--   * status         hard-coded 'active'
--   * listing_status hard-coded 'draft'
--   * office_id      generated · join_code generated · slug generated
--   * one per caller — office_users.user_id is UNIQUE and §2 checks it explicitly, so
--                    this RPC cannot be looped to spray offices from one account
--
-- ── Why the login name is derived, not typed ────────────────────────────────────────
--
-- The sign-up form asks for three things and no more: email, password, office name.
-- But dashboard login is Name + Password (090100), so an account still needs a
-- `username`. Asking for a fourth field to name something the operator has not yet been
-- told exists is how sign-up forms get abandoned, so the username is derived from the
-- email's local part instead — and §4 teaches `resolve_office_user_login` to accept the
-- email address itself, so a self-registered owner signs in with exactly what they
-- typed at sign-up and never has to learn the derived name at all.
-- =====================================================================================

-- ── 1. Deriving a login name from an email address ──────────────────────────────────
-- office_users.username is constrained to ^[a-z0-9][a-z0-9._-]*$ over 3..32 chars by
-- every writer that touches it. An email local part is close to that shape but not
-- inside it (`+` tags, unicode, leading dots), so it is sanitised rather than trusted,
-- then uniquified — `owner@a.com` and `owner@b.com` are different people who would
-- otherwise both want `owner`.

create or replace function public.derive_office_username(p_seed text)
returns text
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_base      text;
  v_candidate text;
  i           int;
begin
  -- Local part only, stripped of plus-addressing, then reduced to the allowed alphabet.
  v_base := lower(trim(coalesce(p_seed, '')));
  v_base := split_part(v_base, '@', 1);
  v_base := split_part(v_base, '+', 1);
  v_base := regexp_replace(v_base, '[^a-z0-9._-]', '', 'g');
  -- The alphabet allows dots, dashes and underscores anywhere but the first character.
  v_base := regexp_replace(v_base, '^[^a-z0-9]+', '');
  v_base := left(v_base, 24);

  -- Nothing usable survived (an all-unicode local part, say). An opaque name is still
  -- a working login, because §4 lets this operator sign in with their email.
  if length(v_base) < 3 then
    v_base := 'office' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 6);
  end if;

  if not exists (select 1 from public.office_users where lower(username) = v_base) then
    return v_base;
  end if;

  -- Taken. Walk a short numeric suffix before falling back to randomness, so the
  -- second `owner@…` gets `owner2` rather than something unpronounceable.
  for i in 2..99 loop
    v_candidate := left(v_base, 32 - length(i::text)) || i::text;
    if not exists (
      select 1 from public.office_users where lower(username) = v_candidate
    ) then
      return v_candidate;
    end if;
  end loop;

  for i in 1..20 loop
    v_candidate := left(v_base, 24) || substr(
      replace(gen_random_uuid()::text, '-', ''), 1, 6);
    if not exists (
      select 1 from public.office_users where lower(username) = v_candidate
    ) then
      return v_candidate;
    end if;
  end loop;

  raise exception 'username_generation_failed';
end;
$$;

revoke all on function public.derive_office_username(text)
  from public, anon, authenticated;

comment on function public.derive_office_username(text) is
  'Turns an email address into a free office_users.username inside the '
  '^[a-z0-9][a-z0-9._-]*$ / 3..32 shape. Internal to register_office(); not callable '
  'from the apps, because a free-username oracle is a username-enumeration oracle.';

-- ── 2. Registration ─────────────────────────────────────────────────────────────────
-- Called by the dashboard immediately after `auth.signUp` returns a session. The
-- auth.users row therefore already exists and is the caller's own — this RPC never
-- creates or names an account, it only gives the account that is already signed in an
-- office to administer.
--
-- p_office_name falls back to the `pending_office_name` the sign-up wrote into user
-- metadata. That fallback is what makes the flow survive an email-confirmation step:
-- if signUp returns no session, the office cannot be created until the operator comes
-- back and signs in, and by then the typed office name is long gone from the form.

create or replace function public.register_office(
  p_office_name text default null,
  p_full_name   text default null
) returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid       uuid := auth.uid();
  v_user      record;
  v_name      text;
  v_full_name text;
  v_username  text;
  v_slug      text;
  v_email     text;
  v_code      text;
  v_office_id uuid;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  select id, email, raw_user_meta_data
    into v_user
    from auth.users
   where id = v_uid;

  if v_user.id is null then
    raise exception 'not_authenticated';
  end if;

  -- One office per account. office_users.user_id is UNIQUE so the index enforces this
  -- too; checking it here turns a 23505 into an error the sign-up screen can explain,
  -- and makes it explicit that this RPC is not a way to accumulate offices.
  if exists (select 1 from public.office_users where user_id = v_uid) then
    raise exception 'already_registered';
  end if;

  -- A captain's account is bound to an office by their drivers row; letting it also
  -- become that office's admin (or another office's) would cross a boundary every
  -- policy downstream assumes is uncrossable.
  if exists (select 1 from public.drivers where user_id = v_uid) then
    raise exception 'driver_cannot_register_office';
  end if;

  v_name := trim(coalesce(
    nullif(trim(coalesce(p_office_name, '')), ''),
    v_user.raw_user_meta_data->>'pending_office_name',
    ''
  ));
  if length(v_name) < 3 then
    raise exception 'invalid_office_name';
  end if;
  if length(v_name) > 120 then
    raise exception 'office_name_too_long';
  end if;

  v_full_name := trim(coalesce(
    nullif(trim(coalesce(p_full_name, '')), ''),
    v_user.raw_user_meta_data->>'full_name',
    ''
  ));
  if length(v_full_name) > 120 then
    raise exception 'invalid_full_name';
  end if;

  v_email := lower(nullif(trim(coalesce(v_user.email, '')), ''));

  -- Office names are Arabic and slugs are the latin public identifier, so one cannot be
  -- transliterated into the other. Same opaque fallback platform_create_office uses;
  -- a readable slug is set later from the office profile screen.
  v_slug := 'office-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 10);
  while exists (select 1 from public.offices where lower(slug) = v_slug) loop
    v_slug := 'office-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 10);
  end loop;

  v_username := public.derive_office_username(coalesce(v_email, v_uid::text));
  v_code     := public.next_office_join_code();

  insert into public.offices (
    name, slug, description, email, service_areas,
    status, listing_status, join_code, join_code_rotated_at
  ) values (
    v_name, v_slug, '', v_email, '{}'::text[],
    'active', 'draft', v_code, now()
  )
  returning id into v_office_id;

  insert into public.office_users (
    office_id, user_id, username, full_name, role, status
  ) values (
    v_office_id, v_uid, v_username, v_full_name, 'dashboard_admin', 'active'
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

revoke all on function public.register_office(text, text)
  from public, anon, authenticated;
-- `authenticated` only: an anon caller has no auth.uid() and would be refused anyway,
-- but the grant should say what the function actually requires.
grant execute on function public.register_office(text, text) to authenticated;

comment on function public.register_office(text, text) is
  'Self-service office registration for the dashboard sign-up screen. Creates an '
  'active + draft office owned by auth.uid() as its dashboard_admin, one per account. '
  'Marketplace visibility stays platform-admin-only (platform_set_office_listing), so '
  'a self-registered office is a private workspace until EWT publishes it.';

-- ── 3. A dashboard account is not a passenger ───────────────────────────────────────
-- handle_new_client_user() fires on every auth.users insert and writes a public.clients
-- row whose phone defaults to ''. clients.phone is uniquely constrained, so the SECOND
-- office owner to sign up would collide on the empty phone and their signUp would fail.
-- 20260721140000 §5 already added 'office_user' to the skip list for exactly this
-- reason; the sign-up screen sends `role: 'office_user'` in its metadata to land in it.
-- Restated here as the assertion this migration depends on, so the coupling is visible
-- at the place that relies on it rather than only at the place that provides it.

do $$
begin
  if not exists (
    select 1 from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname = 'handle_new_client_user'
       and pg_get_functiondef(p.oid) like '%office_user%'
  ) then
    raise exception
      'handle_new_client_user() does not skip office_user accounts; apply '
      '20260721140000_platform_office_onboarding.sql first';
  end if;
end $$;

-- ── 4. Sign in with the email you signed up with ────────────────────────────────────
-- The login screen asks for a Name. A self-registered owner never chose one — §1 derived
-- it — so the one credential they are certain of is the email address they typed into
-- the sign-up form.
--
-- The function therefore branches on the shape of what was typed: an input containing
-- `@` is matched against auth.users.email, anything else against office_users.username,
-- exactly as before. Name login is untouched for every operator provisioned the old way,
-- including the synthetic `@office.ewt.internal` addresses — those contain `@` and now
-- also work as a login, which is harmless and occasionally useful.
--
-- The disclosure trade-off is unchanged in kind but worth restating: this is still
-- anon-callable and still confirms that a given name or address belongs to an active
-- operator. It reveals no credential — GoTrue still verifies the password — and for the
-- email branch it returns only the address that was already supplied.

create or replace function public.resolve_office_user_login(p_username text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_input text := lower(trim(coalesce(p_username, '')));
  v_user  record;
begin
  if length(v_input) < 3 then
    return jsonb_build_object('outcome', 'not_found');
  end if;

  if position('@' in v_input) > 0 then
    select ou.user_id, ou.office_id, ou.role, ou.full_name, ou.status, au.email
      into v_user
      from public.office_users ou
      join auth.users au on au.id = ou.user_id
     where lower(au.email) = v_input
     limit 1;
  else
    select ou.user_id, ou.office_id, ou.role, ou.full_name, ou.status, au.email
      into v_user
      from public.office_users ou
      join auth.users au on au.id = ou.user_id
     where lower(ou.username) = v_input
     limit 1;
  end if;

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

comment on function public.resolve_office_user_login(text) is
  'Maps a typed login — an office_users.username, or the account email for '
  'self-registered owners — to the address GoTrue signs in with. Availability only: '
  'it verifies no credential and returns the same not_found for unknown and disabled.';
