-- =====================================================================================
-- EWT office administration — staff provisioning
-- -------------------------------------------------------------------------------------
-- Until now an office could see its operators (`get_dashboard_users`) and re-role them
-- by writing `office_users` directly, but it could not CREATE one: the auth.users row
-- needs the Auth Admin API, and 20260721100000 revoked `link_office_user` from every
-- API role precisely so an in-app caller could not mint office memberships. The only
-- door was the platform admin's, through `platform-create-office`, which creates an
-- office — not a colleague inside an existing one.
--
-- This migration gives an office owner that door, with the same split the platform
-- onboarding flow already proved:
--
--   HERE (SQL)          everything about MEMBERSHIP — which office, which role, which
--                       username, and every rule that keeps an office from locking
--                       itself out. The office is never a parameter: it is
--                       current_office_id(), resolved from the caller's own JWT.
--   Edge Function       the one step SQL cannot do — creating the auth.users row.
--
-- ── The three lockout rules ─────────────────────────────────────────────────────────
--
-- An office that demotes or disables its last owner has no way back: `office_role()`
-- gates every function below, so there would be nobody left who could restore it, and
-- only a platform admin with direct database access could repair it. So:
--
--   1. An admin may not change their OWN role.        (cannot_change_own_role)
--   2. An admin may not disable their OWN account.    (cannot_disable_self)
--   3. The last active dashboard_admin of an office may not be demoted or disabled.
--                                                     (last_admin_required)
--
-- Rules 1 and 2 are the ones that actually fire. Rule 3 is a backstop, and is stated
-- as one rather than dressed up as load-bearing: given 1 and 2 it is currently
-- unreachable, because reaching it needs a caller who is an active admin acting on the
-- LAST active admin — and if the target is the last one, the caller is the target, which
-- rule 1 or 2 already refused. It is here because that reasoning depends on who may
-- call these functions, and rule 3 is the only one that stays true if that ever widens
-- (a platform-admin override, an office with a delegated manager role). An office with
-- no active owner cannot be repaired from inside the product at all, so the invariant
-- is worth asserting twice.
--
-- ── What is NOT here ────────────────────────────────────────────────────────────────
--
-- No delete. Removing an office_users row orphans an auth.users row that still holds
-- the username — `uq_office_users_username` is global — so the name could never be
-- reused, and the office would lose the audit trail of who acted while they worked
-- there. Disabling is the reversible, honest operation: `resolve_office_user_login`
-- and `current_office_context` both require status = 'active', so a disabled operator
-- cannot sign in from the moment the row is written.
--
-- ── Licensing ───────────────────────────────────────────────────────────────────────
--
-- Untouched and unbypassed. `trg_quota_office_users` still meters the INSERT against
-- `max_admin_users`, `trg_quota_operator_reactivate` still meters re-activation, and
-- `trg_readonly_office_users` still refuses writes on a read-only license. These
-- functions are SECURITY DEFINER for the office lookup, not to escape those triggers —
-- triggers fire regardless of the invoking role.
-- =====================================================================================

-- ── 1. Shared preamble: who is calling, and may they manage staff? ──────────────────
-- Every function below opens with the same two questions. A helper keeps the answer
-- identical in all five rather than five hand-copied checks that can drift apart.

create or replace function public.assert_office_staff_admin()
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if public.office_role() <> 'dashboard_admin' then
    raise exception 'dashboard_admin_required';
  end if;
  return v_office;
end;
$$;

revoke all on function public.assert_office_staff_admin()
  from public, anon, authenticated;
-- Not granted to anyone: it is an internal predicate for the functions below, all of
-- which are SECURITY DEFINER and therefore call it as the owner.

comment on function public.assert_office_staff_admin() is
  'Returns the caller''s office id, or raises. The single gate in front of every '
  'office staff-management RPC: an active operator of some office, holding the '
  'dashboard_admin role.';


-- ── 2. "Is there another owner besides this one?" ───────────────────────────────────
-- The predicate behind `last_admin_required`. In one place because §6 and §7 must agree
-- about it exactly — an office with one owner left is the one state neither may create.

create or replace function public.office_has_other_admin(
  p_office_id        uuid,
  p_exclude_staff_id uuid
) returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.office_users
     where office_id = p_office_id
       and id <> p_exclude_staff_id
       and role = 'dashboard_admin'
       and status = 'active'
  );
$$;

revoke all on function public.office_has_other_admin(uuid, uuid)
  from public, anon, authenticated;


-- ── 3. One row shape for every answer ───────────────────────────────────────────────
-- Create / role change / status change all return the same object the list returns, so
-- the Dashboard maps one shape and can replace a row in place instead of refetching.
-- The email is the synthetic login address `get_dashboard_users` already exposes to the
-- same audience, so this reveals nothing new.

create or replace function public.office_staff_row(p_row public.office_users)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'id',         p_row.id,
    'user_id',    p_row.user_id,
    'username',   p_row.username,
    'full_name',  p_row.full_name,
    'email',      (select au.email::text from auth.users au where au.id = p_row.user_id),
    'role',       p_row.role,
    'status',     p_row.status,
    'created_at', p_row.created_at
  );
$$;

revoke all on function public.office_staff_row(public.office_users)
  from public, anon, authenticated;


-- ── 4. Username availability ────────────────────────────────────────────────────────
-- Called by the Edge Function BEFORE it creates an auth user, so the common mistake —
-- a name already in use — is a plain validation error rather than a create-then-
-- compensate round trip.
--
-- `uq_office_users_username` is a PLATFORM-wide unique index on lower(username), so
-- this deliberately looks outside the caller's own office. It answers only "is this
-- name free"; it never reveals who holds it, which office they belong to, or whether
-- they are active.

create or replace function public.office_staff_username_available(p_username text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_username text := lower(trim(coalesce(p_username, '')));
begin
  perform public.assert_office_staff_admin();

  return jsonb_build_object(
    'username_available',
      v_username ~ '^[a-z0-9][a-z0-9._-]*$'
      and length(v_username) between 3 and 32
      and not exists (
        select 1 from public.office_users where lower(username) = v_username)
  );
end;
$$;

revoke all on function public.office_staff_username_available(text)
  from public, anon, authenticated;
grant execute on function public.office_staff_username_available(text) to authenticated;


-- ── 5. Create a staff member ────────────────────────────────────────────────────────
-- The auth.users row already exists — that is the Edge Function's half. This binds it
-- to the CALLER's office, and to nothing else.
--
-- What the caller cannot influence, and why:
--   * office_id  — current_office_id(), never a parameter. An office id on the wire
--                  would be the one value worth tampering with, and RLS alone would
--                  not stop this function since it is SECURITY DEFINER.
--   * status     — always 'active'. Provisioning a pre-disabled account is not a
--                  product need, and it would sidestep the reactivation quota.
--
-- Deliberately NOT modelled on link_office_user(): its ON CONFLICT (user_id) DO UPDATE
-- would MOVE an operator who already belongs to another office into this one. Here an
-- already-assigned user is an error, the same conclusion platform_create_office reached.

create or replace function public.office_create_staff(
  p_user_id   uuid,
  p_username  text,
  p_role      text default 'support_agent',
  p_full_name text default ''
) returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_office    uuid := public.assert_office_staff_admin();
  v_username  text := lower(trim(coalesce(p_username, '')));
  v_full_name text := trim(coalesce(p_full_name, ''));
  v_row       public.office_users;
begin
  if p_user_id is null then
    raise exception 'staff_user_required';
  end if;
  if not exists (select 1 from auth.users where id = p_user_id) then
    raise exception 'staff_user_not_found';
  end if;
  if exists (select 1 from public.office_users where user_id = p_user_id) then
    raise exception 'staff_user_already_assigned';
  end if;

  if v_username !~ '^[a-z0-9][a-z0-9._-]*$'
     or length(v_username) < 3 or length(v_username) > 32 then
    raise exception 'invalid_username';
  end if;
  if exists (select 1 from public.office_users where lower(username) = v_username) then
    raise exception 'username_taken';
  end if;

  if length(v_full_name) > 120 then
    raise exception 'invalid_full_name';
  end if;
  if p_role not in ('dashboard_admin', 'support_agent') then
    raise exception 'invalid_role';
  end if;

  insert into public.office_users (
    office_id, user_id, username, full_name, role, status
  ) values (
    v_office, p_user_id, v_username, v_full_name, p_role, 'active'
  )
  returning * into v_row;

  return public.office_staff_row(v_row);
end;
$$;

revoke all on function public.office_create_staff(uuid, text, text, text)
  from public, anon, authenticated;
grant execute on function public.office_create_staff(uuid, text, text, text)
  to authenticated;

comment on function public.office_create_staff(uuid, text, text, text) is
  'Binds an existing auth user to the CALLER''s office as staff. office_id comes from '
  'current_office_id() and is never a parameter; status is always active. Requires '
  'dashboard_admin. The auth.users row is the Edge Function''s half of the flow.';


-- ── 6. Change a colleague's role ────────────────────────────────────────────────────
-- Replaces the Dashboard's direct UPDATE on office_users. RLS permitted that update and
-- would keep permitting it, but a policy cannot express "not the last admin" — it sees
-- one row at a time and has no way to refuse a change that is only wrong in aggregate.

create or replace function public.office_update_staff_role(
  p_office_user_id uuid,
  p_role           text
) returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_office uuid := public.assert_office_staff_admin();
  v_row    public.office_users;
begin
  if p_role not in ('dashboard_admin', 'support_agent') then
    raise exception 'invalid_role';
  end if;

  select * into v_row
    from public.office_users
   where id = p_office_user_id
     and office_id = v_office;

  if v_row.id is null then
    -- Same message for "no such row" and "belongs to another office": an id probe must
    -- not become a way to learn that some other office's operator exists.
    raise exception 'staff_not_found';
  end if;

  if v_row.user_id = auth.uid() then
    raise exception 'cannot_change_own_role';
  end if;

  if v_row.role = 'dashboard_admin'
     and p_role <> 'dashboard_admin'
     and not public.office_has_other_admin(v_office, v_row.id) then
    raise exception 'last_admin_required';
  end if;

  update public.office_users
     set role = p_role
   where id = v_row.id
  returning * into v_row;

  return public.office_staff_row(v_row);
end;
$$;

revoke all on function public.office_update_staff_role(uuid, text)
  from public, anon, authenticated;
grant execute on function public.office_update_staff_role(uuid, text) to authenticated;


-- ── 7. Disable / re-enable a colleague ──────────────────────────────────────────────
-- The removal path. A disabled operator is refused by resolve_office_user_login (which
-- requires status = 'active') and by current_office_context, so the account is shut out
-- from the next sign-in attempt onward — while an existing SESSION keeps its JWT until
-- it expires. That gap is inherent to stateless tokens and is not closed here; the RLS
-- helpers (current_office_id, office_role) all filter on status = 'active', so a
-- lingering session can read and write nothing office-scoped in the meantime.

create or replace function public.office_set_staff_status(
  p_office_user_id uuid,
  p_status         text
) returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_office uuid := public.assert_office_staff_admin();
  v_row    public.office_users;
begin
  if p_status not in ('active', 'disabled') then
    raise exception 'invalid_status';
  end if;

  select * into v_row
    from public.office_users
   where id = p_office_user_id
     and office_id = v_office;

  if v_row.id is null then
    raise exception 'staff_not_found';
  end if;

  if p_status = 'disabled' then
    if v_row.user_id = auth.uid() then
      raise exception 'cannot_disable_self';
    end if;
    if v_row.role = 'dashboard_admin'
       and not public.office_has_other_admin(v_office, v_row.id) then
      raise exception 'last_admin_required';
    end if;
  end if;

  update public.office_users
     set status = p_status
   where id = v_row.id
  returning * into v_row;

  return public.office_staff_row(v_row);
end;
$$;

revoke all on function public.office_set_staff_status(uuid, text)
  from public, anon, authenticated;
grant execute on function public.office_set_staff_status(uuid, text) to authenticated;


-- ── 8. Password reset: naming the target ────────────────────────────────────────────
-- The reset itself is an Auth Admin API call and belongs to the Edge Function. What the
-- function must not do is decide WHOSE password it may reset — that is an authorization
-- question, so it is answered here, under the caller's own JWT.
--
-- Returns the auth user id for a staff row in the caller's office, and raises for
-- anything else. The function holds the service-role key but learns the target id only
-- from this call, so it cannot be pointed at an account outside the caller's office.
--
-- An admin CAN reset their own password this way. That is not a lockout risk — they
-- receive the new password in the same response — so no self-guard applies.

create or replace function public.office_staff_reset_target(p_office_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office uuid := public.assert_office_staff_admin();
  v_row    public.office_users;
begin
  select * into v_row
    from public.office_users
   where id = p_office_user_id
     and office_id = v_office;

  if v_row.id is null then
    raise exception 'staff_not_found';
  end if;

  return jsonb_build_object(
    'user_id',  v_row.user_id,
    'username', v_row.username
  );
end;
$$;

revoke all on function public.office_staff_reset_target(uuid)
  from public, anon, authenticated;
grant execute on function public.office_staff_reset_target(uuid) to authenticated;

comment on function public.office_staff_reset_target(uuid) is
  'Resolves a staff row in the CALLER''s office to its auth user id, for the '
  'office-manage-user Edge Function to reset. Authorization lives here, under the '
  'caller''s JWT, so the service-role key alone can never target another office.';
