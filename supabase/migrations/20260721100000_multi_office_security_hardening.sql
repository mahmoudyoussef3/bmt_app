-- =====================================================================================
-- EWT multi-office — security hardening
-- -------------------------------------------------------------------------------------
-- Follow-up to 20260721090300. Verification against the live database found that the
-- lockdown in that migration was incomplete, and that one revoke broke the Captain app.
--
-- Root cause: `ALTER DEFAULT PRIVILEGES ... IN SCHEMA public GRANT EXECUTE ON FUNCTIONS
-- TO anon, authenticated` is active on this project (pg_default_acl, objtype 'f'). The
-- grant to `anon` is therefore EXPLICIT, not inherited via PUBLIC — so
-- `revoke ... from public` does not remove it. Migration 090300 loop 2 revoked only
-- from `public`, leaving every office_* wrapper anon-executable, and loop 1 named only
-- the (uuid, text) signatures while older overloads of approve_payment / reject_payment
-- still existed and stayed open to anon.
--
-- Everything here is idempotent and safe to re-run.
-- =====================================================================================

-- ── 1. Platform administrators ──────────────────────────────────────────────────────
-- Platform-wide configuration (referral rewards, loyalty tiers) is shared by every
-- office. "Platform-wide" must not mean "any office admin may rewrite it", so writes
-- need an identity that is deliberately separate from office membership.

create table if not exists public.platform_admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  note       text,
  created_at timestamptz not null default now()
);

alter table public.platform_admins enable row level security;

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.platform_admins where user_id = auth.uid()
  );
$$;

-- Readable only by platform admins themselves; never writable from the client tier.
drop policy if exists platform_admins_self_read on public.platform_admins;
create policy platform_admins_self_read on public.platform_admins
  for select using (public.is_platform_admin());

revoke all on public.platform_admins from anon, authenticated;
grant select on public.platform_admins to authenticated;

-- Seed the pre-marketplace owner. Before this migration there was exactly one office
-- and its dashboard_admin already had de-facto platform-wide control, so promoting
-- them takes nothing away and keeps referral configuration and broadcasts working for
-- the account that runs them today. The guard means this never fires on a deployment
-- that has already grown a second office — there, platform admins are appointed
-- deliberately with service_role.
insert into public.platform_admins (user_id, note)
select ou.user_id, 'auto-seeded: sole office admin at multi-office migration'
  from public.office_users ou
 where ou.role = 'dashboard_admin'
   and ou.status = 'active'
   and (select count(*) from public.offices) = 1
on conflict (user_id) do nothing;

-- ── 2. Close the overloads that 090300 missed ───────────────────────────────────────
-- These are the pre-office SECURITY DEFINER originals. They carry no ownership check at
-- all, and both were executable by `anon` — and the anon key ships inside the published
-- app binaries. This was remote-exploitable payment approval.

do $$
declare
  f text;
begin
  foreach f in array array[
    'public.approve_payment(uuid, uuid)',
    'public.reject_payment(uuid, uuid, text)',
    'public.approve_payment(uuid, text)',
    'public.reject_payment(uuid, text)',
    'public.request_payment_review(uuid, text)',
    'public.approve_booking(uuid, text)',
    'public.reject_booking(uuid, text, text)',
    'public.reassign_booking(uuid, uuid, text)',
    'public.update_trip_status(uuid, text)',
    'public.confirm_subscription_payment(uuid)',
    'public.request_subscription_renewal(uuid)',
    'public.consume_subscription_ride(uuid)',
    'public.expire_overdue_subscriptions()',
    'public.link_paymob_order(uuid, text)',
    'public.resolve_booking_payment_config(uuid)',
    -- Office membership grant. Was anon-executable with a caller-supplied role: a
    -- complete tenancy takeover primitive. service_role only from here on.
    'public.link_office_user(uuid, uuid, text, text, text)',
    -- Unscoped mass mutation / fan-out. No office check in any of them.
    'public.bulk_update_booking_status(uuid[], text, text)',
    'public.push_notification(uuid, text, text, text, text, jsonb, text, text)',
    'public.push_operational_alert(text, text, text, jsonb, text, text, uuid)',
    'public.notify_trip_passengers(uuid, text, text, text, jsonb, text)',
    'public.captain_user_for_trip(uuid)',
    -- Rating recomputation: callable by anyone meant ratings could be forced.
    'public.refresh_driver_rating(uuid)',
    'public.refresh_vehicle_rating(uuid)',
    'public.refresh_office_rating(uuid)',
    'public.refresh_rating_aggregates()',
    'public.release_expired_seat_holds()',
    'public.grant_referral_reward()',
    'public.next_office_trip_code(uuid)',
    'public.assert_office_owns_booking(uuid)',
    'public.assert_office_owns_trip(uuid)',
    'public.assert_office_owns_subscription(uuid)'
  ]
  loop
    begin
      execute format(
        'revoke all on function %s from public, anon, authenticated', f);
    exception when undefined_function then
      raise notice 'skipping revoke for missing function %', f;
    end;
  end loop;
end $$;

-- Trigger functions are never invoked directly; they run as part of the triggering
-- statement and do not need EXECUTE granted to the API roles.
do $$
declare
  f text;
begin
  foreach f in array array[
    'public.handle_new_client_user()',
    'public.handle_new_user_notification_prefs()',
    'public.handle_new_user_referral()',
    'public.on_booking_payment_insert()',
    'public.on_captain_request_insert()',
    'public.on_operation_trip_change()',
    'public.on_refund_request_change()',
    'public.on_subscription_status_change()',
    'public.on_support_message_insert()',
    'public.on_support_ticket_insert()',
    'public.on_trip_passenger_delete()',
    'public.on_trip_passenger_insert()',
    'public.sync_booking_office()',
    'public.sync_child_office_from_booking()',
    'public.sync_trip_office()',
    'public.refresh_office_rating_trigger()',
    'public.rls_auto_enable()'
  ]
  loop
    begin
      execute format(
        'revoke all on function %s from public, anon, authenticated', f);
    exception when undefined_function then
      raise notice 'skipping revoke for missing trigger function %', f;
    end;
  end loop;
end $$;

-- ── 3. Re-apply the wrapper grants, this time revoking anon explicitly ──────────────
-- The wrappers already fail closed for anon (current_office_id() is null → the
-- 'not_an_office_user' branch), but relying on the body to refuse a caller that should
-- never have reached it is not a boundary. EXECUTE is the boundary.

do $$
declare
  f text;
begin
  foreach f in array array[
    'public.office_approve_payment(uuid, text)',
    'public.office_reject_payment(uuid, text)',
    'public.office_request_payment_review(uuid, text)',
    'public.office_approve_booking(uuid, text)',
    'public.office_reject_booking(uuid, text, text)',
    'public.office_reassign_booking(uuid, uuid, text)',
    'public.office_update_trip_status(uuid, text)',
    'public.office_confirm_subscription_payment(uuid)',
    'public.office_request_subscription_renewal(uuid)',
    'public.office_consume_subscription_ride(uuid)',
    'public.office_expire_overdue_subscriptions()',
    'public.office_create_trip(uuid, uuid, uuid, date, time, time, int, numeric, '
      || 'text, text[], jsonb, jsonb, text)',
    'public.get_dashboard_users()',
    'public.current_office_context()'
  ]
  loop
    begin
      execute format(
        'revoke all on function %s from public, anon, authenticated', f);
      execute format('grant execute on function %s to authenticated', f);
    exception when undefined_function then
      raise notice 'skipping regrant for missing function %', f;
    end;
  end loop;
end $$;

-- Identity helpers stay callable by both API roles ON PURPOSE. They are referenced from
-- RLS policy expressions, which are evaluated with the querying role's privileges — a
-- revoke here turns every policy-guarded query into a permission error instead of an
-- empty result. They are safe: each one keys off auth.uid() and returns only the
-- caller's own context.
do $$
declare
  f text;
begin
  foreach f in array array[
    'public.current_office_id()',
    'public.captain_office_id()',
    'public.current_driver_id()',
    'public.office_role()',
    'public.office_is_active(uuid)',
    'public.is_office_member(uuid)',
    'public.is_admin()',
    'public.has_role(text)',
    'public.can_manage_subscriptions()',
    'public.is_platform_admin()'
  ]
  loop
    begin
      execute format('revoke all on function %s from public', f);
      execute format(
        'grant execute on function %s to anon, authenticated', f);
    exception when undefined_function then
      raise notice 'skipping identity grant for missing function %', f;
    end;
  end loop;
end $$;

-- ── 4. Captains can drive trips again ───────────────────────────────────────────────
-- 090300 revoked update_trip_status from `authenticated`, but the Captain app calls it
-- directly (trip_execution_datasource.dart:207) to start/complete a trip. Captains are
-- drivers, not office_users, so office_update_trip_status cannot serve them —
-- current_office_id() is null for a captain and the wrapper would refuse.
--
-- This wrapper asserts the caller is the trip's own assigned driver, which is a
-- narrower check than office membership, and re-opens the flow for captains only.

create or replace function public.captain_update_trip_status(
  p_trip_id  uuid,
  p_new_status text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_driver uuid := public.current_driver_id();
  v_trip_driver uuid;
begin
  if v_driver is null then
    raise exception 'not_a_captain';
  end if;

  select driver_id into v_trip_driver
    from public.operation_trips where id = p_trip_id;

  if v_trip_driver is null then
    raise exception 'trip_not_found';
  end if;
  if v_trip_driver <> v_driver then
    raise exception 'not_your_trip';
  end if;

  return public.update_trip_status(p_trip_id, p_new_status);
end;
$$;

revoke all on function public.captain_update_trip_status(uuid, text)
  from public, anon, authenticated;
grant execute on function public.captain_update_trip_status(uuid, text)
  to authenticated;

comment on function public.captain_update_trip_status(uuid, text) is
  'Driver-scoped door to update_trip_status. Asserts the caller owns the trip. '
  'Captains are not office_users, so the office_* wrapper cannot serve them.';

-- ── 5. Client-facing RPCs: authenticated only ───────────────────────────────────────
-- These act on behalf of a signed-in client. None of them should be reachable with the
-- publishable anon key alone.

do $$
declare
  f text;
begin
  foreach f in array array[
    'public.book_trip_seat(uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, '
      || 'text, date, text, text, numeric, text, text)',
    'public.lock_trip_seat(uuid, uuid, uuid)',
    'public.release_trip_seat_lock(uuid, uuid, uuid)',
    'public.cancel_booking(uuid, uuid)',
    'public.cancel_booking_by_client(uuid, text)',
    'public.card_payment_state(uuid)',
    'public.update_existing_booking_payment(uuid, text, text, text, text)',
    'public.submit_trip_review(uuid, int, int, int, int, text)',
    'public.link_current_captain_driver(text)',
    'public.scan_passenger_ticket(uuid, uuid, uuid)',
    'public.redeem_referral_code(text)',
    'public.validate_subscription_for_booking(uuid)'
  ]
  loop
    begin
      execute format(
        'revoke all on function %s from public, anon, authenticated', f);
      execute format('grant execute on function %s to authenticated', f);
    exception when undefined_function then
      raise notice 'skipping client grant for missing function %', f;
    end;
  end loop;
end $$;

-- confirm_seat_booking / confirm_seat_booking_v2 carry long argument lists and exist in
-- more than one overload. Resolve them from the catalog rather than retyping signatures.
do $$
declare
  r record;
begin
  for r in
    select p.oid::regprocedure::text sig
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname in ('confirm_seat_booking', 'confirm_seat_booking_v2')
  loop
    execute format(
      'revoke all on function %s from public, anon, authenticated', r.sig);
    execute format('grant execute on function %s to authenticated', r.sig);
  end loop;
end $$;

-- Pre-authentication RPCs keep anon. Each is a login or signup step that by definition
-- runs before a session exists.
do $$
declare
  f text;
begin
  foreach f in array array[
    'public.resolve_captain_login(text)',
    'public.resolve_office_user_login(text)',
    'public.check_phone_exists(text)',
    'public.get_captain_request_status(text)'
  ]
  loop
    begin
      execute format('revoke all on function %s from public', f);
      execute format(
        'grant execute on function %s to anon, authenticated', f);
    exception when undefined_function then
      raise notice 'skipping pre-auth grant for missing function %', f;
    end;
  end loop;
end $$;

-- ── 6. Broadcast notifications are a platform-admin action ──────────────────────────
-- broadcast_notification fans out to every user of a target app and was anon-callable.
-- It has no office dimension, so it cannot be delegated to office admins.

create or replace function public.platform_broadcast_notification(
  p_title      text,
  p_body       text,
  p_category   text default 'general',
  p_target_app text default 'client',
  p_action_url text default null,
  p_data       jsonb default '{}'::jsonb
) returns integer
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'platform_admin_required';
  end if;
  return public.broadcast_notification(
    p_title, p_body, p_category, p_target_app, p_action_url, p_data);
end;
$$;

revoke all on function public.broadcast_notification(
  text, text, text, text, text, jsonb) from public, anon, authenticated;
revoke all on function public.platform_broadcast_notification(
  text, text, text, text, text, jsonb) from public, anon, authenticated;
grant execute on function public.platform_broadcast_notification(
  text, text, text, text, text, jsonb) to authenticated;

-- ── 7. Platform-wide configuration is read-anywhere, write-platform-admin ───────────
-- referral_rewards carried `for update using (true) with check (true)` addressed to
-- PUBLIC, and anon held the UPDATE table privilege: the reward amount the platform pays
-- out was rewritable by anyone at all.

alter table public.referral_rewards enable row level security;

drop policy if exists referral_rewards_read   on public.referral_rewards;
drop policy if exists referral_rewards_update on public.referral_rewards;
drop policy if exists referral_rewards_insert on public.referral_rewards;

create policy referral_rewards_read on public.referral_rewards
  for select to anon, authenticated using (true);

create policy referral_rewards_write on public.referral_rewards
  for update to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

create policy referral_rewards_insert on public.referral_rewards
  for insert to authenticated
  with check (public.is_platform_admin() and id = 1);

revoke insert, update, delete on public.referral_rewards from anon;
revoke delete on public.referral_rewards from authenticated;

-- Loyalty catalogue: same shape — everyone reads, only the platform writes.
do $$
declare
  t text;
begin
  foreach t in array array['public.loyalty_tiers', 'public.loyalty_rewards']
  loop
    execute format('alter table %s enable row level security', t);
    execute format('revoke insert, update, delete on %s from anon, authenticated', t);
    execute format('grant select on %s to anon, authenticated', t);
  end loop;
end $$;

drop policy if exists loyalty_tiers_platform_write on public.loyalty_tiers;
create policy loyalty_tiers_platform_write on public.loyalty_tiers
  for all to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists loyalty_rewards_platform_write on public.loyalty_rewards;
create policy loyalty_rewards_platform_write on public.loyalty_rewards
  for all to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

-- ── 8. Tables that were left with RLS switched off ──────────────────────────────────
-- Default privileges grant anon ALL on every new table in public, so RLS is the only
-- thing standing between the publishable key and these rows. On `clients` that meant
-- unauthenticated SELECT/UPDATE/DELETE over every customer's name and phone number.

alter table public.clients enable row level security;

drop policy if exists clients_self_read   on public.clients;
drop policy if exists clients_self_write  on public.clients;
drop policy if exists clients_self_insert on public.clients;
drop policy if exists clients_office_read on public.clients;

create policy clients_self_read on public.clients
  for select to authenticated using (id = auth.uid());

create policy clients_self_write on public.clients
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- Signup upserts this row from the app (client_account_guard.dart:53) and swallows
-- failures, so without an insert policy a new client would end up with no row and be
-- signed straight back out by assertRegistered().
create policy clients_self_insert on public.clients
  for insert to authenticated with check (id = auth.uid());

-- Office staff see only the customers who have actually transacted with their office —
-- through a booking or a subscription, since a subscriber need not have a booking.
create policy clients_office_read on public.clients
  for select to authenticated
  using (
    public.current_office_id() is not null
    and (
      exists (
        select 1 from public.operation_bookings b
         where b.client_id = clients.id
           and b.office_id = public.current_office_id()
      )
      or exists (
        select 1 from public.subscriptions s
         where s.client_id = clients.id
           and s.office_id = public.current_office_id()
      )
    )
  );

revoke delete on public.clients from anon, authenticated;
revoke insert, update, select on public.clients from anon;

-- Loyalty balances and ledger: owner-only, and never writable from the client tier.
alter table public.loyalty_accounts     enable row level security;
alter table public.loyalty_transactions enable row level security;

-- Both tables key on client_id, and clients.id is the auth user id.
drop policy if exists loyalty_accounts_self on public.loyalty_accounts;
create policy loyalty_accounts_self on public.loyalty_accounts
  for select to authenticated using (client_id = auth.uid());

drop policy if exists loyalty_transactions_self on public.loyalty_transactions;
create policy loyalty_transactions_self on public.loyalty_transactions
  for select to authenticated using (client_id = auth.uid());

revoke insert, update, delete
  on public.loyalty_accounts, public.loyalty_transactions
  from anon, authenticated;
revoke select on public.loyalty_accounts, public.loyalty_transactions from anon;

-- Superseded referral tables. Still present, still anon-writable, no longer read by any
-- code path — close them rather than leave a live write surface behind.
do $$
declare
  t text;
begin
  foreach t in array array[
    'public.referral_codes_legacy', 'public.referral_rewards_legacy']
  loop
    if to_regclass(t) is not null then
      execute format('alter table %s enable row level security', t);
      execute format('revoke all on %s from anon, authenticated', t);
    end if;
  end loop;
end $$;

-- ── 9. office_payment_configs had RLS on and zero policies ─────────────────────────
-- That is deny-all: the Dashboard could not read its own payment configuration. Scope
-- it to the owning office instead.

drop policy if exists office_payment_configs_own      on public.office_payment_configs;
drop policy if exists office_payment_configs_own_write on public.office_payment_configs;

create policy office_payment_configs_own on public.office_payment_configs
  for select to authenticated
  using (office_id = public.current_office_id());

create policy office_payment_configs_own_write on public.office_payment_configs
  for all to authenticated
  using (
    office_id = public.current_office_id()
    and public.office_role() = 'dashboard_admin'
  )
  with check (
    office_id = public.current_office_id()
    and public.office_role() = 'dashboard_admin'
  );

revoke all on public.office_payment_configs from anon;
