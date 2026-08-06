-- ═══════════════════════════════════════════════════════════════════════════════════
-- EWT Entitlement Platform — Phase 6/6: passenger and captain surfaces
--
-- Design: docs/architecture/PLATFORM_LICENSING.md Part 11, §1.2 F6, §3.9, §4.3.
--
-- Neither passenger-facing app gets an entitlement API. Their behaviour is DERIVED
-- from the office's entitlements, server-side.
--
-- ── THE MID-TRIP RULE IS ABSOLUTE ──────────────────────────────────────────────────
--
-- No licensing state — expiry, suspension, non-payment — may interrupt a trip that
-- has started or a ticket already sold. Every gate in this file is on CREATING NEW
-- COMMITMENTS or on DISCOVERY, never on HONOURING what already exists. The captain
-- gate below carries an explicit in-flight exemption for exactly this reason: the
-- captain app is where a licensing action would do physical harm.
--
-- ── Why office_is_listed() costs one predicate and not a join (F6, §3.9) ────────────
--
-- Every anon-facing marketplace surface was already swept onto office_is_listed() in
-- 20260721140000 §3, so gating client discovery is ONE predicate change rather than a
-- sweep. That predicate must stay cheap: it runs inside RLS policies on the hottest
-- read path in the Client app. So the licensing answer is DENORMALISED onto
-- offices.licensing_hold, and this migration makes that column complete — maintained
-- from all four writers that can change it, not just from the license status.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. licensing_hold, maintained from every writer that can change the answer
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- The column has two independent inputs:
--
--   * the license STATUS   — suspended/cancelled delist, expired is read-only
--   * the client_app VALUE — a plan or an override can withdraw marketplace listing
--                            without any billing event at all
--
-- Both fold into one column so the read path stays a single boolean test, and every
-- table that can move either input gets a trigger. This is the one place the design
-- deliberately denormalises, and maintaining it from all its sources is the price.

create or replace function public.office_refresh_licensing_hold(p_office_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  v_hold   text;
begin
  select status into v_status from public.office_licenses where office_id = p_office_id;

  v_hold := public.license_hold_for_status(coalesce(v_status, 'active'));

  -- A plan or an override that switches client_app off delists just as surely as a
  -- suspension does, and `delisted` is the stronger of the two states.
  if not public.platform_value_is_truthy(
       public.platform_resolve_feature(p_office_id, null, 'client_app') -> 'value') then
    v_hold := 'delisted';
  end if;

  update public.offices
     set licensing_hold = v_hold
   where id = p_office_id
     and coalesce(licensing_hold, 'none') is distinct from v_hold;
end;
$$;


-- Replaces the status-only projection installed with the console migration.
create or replace function public.office_license_project_hold()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.office_refresh_licensing_hold(coalesce(new.office_id, old.office_id));
  return null;
end;
$$;

drop trigger if exists trg_license_project_hold on public.office_licenses;
create trigger trg_license_project_hold
  after insert or update or delete on public.office_licenses
  for each row execute function public.office_license_project_hold();


-- An override on client_app moves one office.
create or replace function public.office_override_project_hold()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(new.feature_key, old.feature_key) = 'client_app' then
    perform public.office_refresh_licensing_hold(coalesce(new.office_id, old.office_id));
  end if;
  return null;
end;
$$;

drop trigger if exists trg_override_project_hold on public.office_feature_overrides;
create trigger trg_override_project_hold
  after insert or update or delete on public.office_feature_overrides
  for each row execute function public.office_override_project_hold();


-- A plan edit on client_app moves every office on that plan. Statement-level, because
-- platform_save_plan rewrites the whole feature map row by row and re-running the
-- refresh per row would be pointless work.
create or replace function public.plan_feature_project_hold()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_office uuid;
begin
  for v_office in select office_id from public.office_licenses loop
    perform public.office_refresh_licensing_hold(v_office);
  end loop;
  return null;
end;
$$;

drop trigger if exists trg_plan_feature_project_hold on public.platform_plan_features;
create trigger trg_plan_feature_project_hold
  after insert or update or delete on public.platform_plan_features
  for each statement execute function public.plan_feature_project_hold();

drop trigger if exists trg_feature_status_project_hold on public.platform_features;
create trigger trg_feature_status_project_hold
  after update of status on public.platform_features
  for each statement execute function public.plan_feature_project_hold();


-- Recompute for every office now that client_app is part of the answer.
do $$
declare v_office uuid;
begin
  for v_office in select id from public.offices loop
    perform public.office_refresh_licensing_hold(v_office);
  end loop;
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. The one predicate change (F6)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Every anon marketplace policy already calls this, so this single edit withdraws a
-- delisted office from routes, stations, trips, packages and office discovery at
-- once. Existing bookings stay visible and trackable: those read paths are keyed to
-- the passenger's own booking, not to the office's listing.

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
       and coalesce(licensing_hold, 'none') <> 'delisted'
  );
$$;

comment on function public.office_is_listed(uuid) is
  'Is this office on the client marketplace? status = active AND listing_status = '
  'listed AND no licensing delisting. One column and one term rather than a '
  'three-table join, because this runs inside RLS policies on the Client app''s '
  'hottest read path (§3.9).';


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. passenger_packages — a separate switch from marketplace listing
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- An office can be perfectly listed and still not licensed to sell ride bundles, so
-- this is its own predicate rather than another fold into licensing_hold. Packages
-- are a bounded read (a handful of rows per office), so a resolver call here is
-- affordable where one in office_is_listed() would not be.

create or replace function public.office_sells_packages(p_office_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.platform_value_is_truthy(
    public.platform_resolve_feature(p_office_id, null, 'passenger_packages') -> 'value');
$$;

revoke all on function public.office_sells_packages(uuid) from public;
-- Granted to both API roles: it is referenced from an anon-facing policy expression,
-- and a revoked function in a policy turns every guarded query into a permission
-- error instead of an empty result (the trap from 20260721140000 §2).
grant execute on function public.office_sells_packages(uuid) to anon, authenticated;

drop policy if exists packages_marketplace_read on public.packages;
create policy packages_marketplace_read on public.packages
  for select to anon, authenticated
  using (status = 'active'
         and public.office_is_listed(office_id)
         and public.office_sells_packages(office_id));

drop policy if exists transport_packages_marketplace_read on public.transport_packages;
create policy transport_packages_marketplace_read on public.transport_packages
  for select to anon, authenticated
  using (active = true
         and public.office_is_listed(office_id)
         and public.office_sells_packages(office_id));


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. live_tracking — the map degrades, the trip does not
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- With tracking unlicensed, the Client app falls back to schedule + status: no live
-- map. The trip itself, the seats, the ticket and the captain's flow are untouched.

create or replace function public.trip_tracking_licensed(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select public.platform_value_is_truthy(
      public.platform_resolve_feature(t.office_id, null, 'live_tracking') -> 'value')
      from public.operation_trips t where t.id = p_trip_id), true);
$$;

revoke all on function public.trip_tracking_licensed(uuid) from public;
grant execute on function public.trip_tracking_licensed(uuid) to anon, authenticated;

drop policy if exists trip_live_locations_read on public.trip_live_locations;
create policy trip_live_locations_read on public.trip_live_locations
  for select to anon, authenticated
  using (public.can_read_trip_fixes(trip_id)
         and public.trip_tracking_licensed(trip_id));

-- The INSERT policy is deliberately NOT gated. Refusing a captain's location write
-- turns an unpaid invoice into an error dialog on a moving bus; the publisher is
-- stopped in the captain app instead, from the licensing block returned below.


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. The captain gate — with an absolute in-flight exemption
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.captain_session_context()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid       uuid := auth.uid();
  v_driver    public.drivers;
  v_office    public.offices;
  v_phone     text;
  v_app       boolean;
  v_tracking  boolean;
  v_in_flight boolean;
  v_blocked   boolean := false;
begin
  if v_uid is null then
    return null;
  end if;

  select * into v_driver
    from public.drivers d
   where d.user_id = v_uid
     and d.status = 'active'
   limit 1;

  if not found then
    select u.phone into v_phone from auth.users u where u.id = v_uid;

    if v_phone is null or v_phone = '' then
      return null;
    end if;

    select * into v_driver
      from public.drivers d
     where public.normalize_egyptian_phone(d.phone)
         = public.normalize_egyptian_phone(v_phone)
       and d.status = 'active'
       and (d.user_id is null or d.user_id = v_uid)
     order by d.created_at
     limit 1;

    if not found then
      return null;
    end if;

    -- Matched on phone, so the row was never bound to this auth user. Bind it now:
    -- the next resolve then takes the direct path, and the RLS helpers
    -- (`current_driver_id()`) can see this captain at all. Done inline rather than
    -- as a second RPC so the common already-linked path stays one round trip.
    update public.drivers
       set user_id = v_uid, updated_at = now()
     where id = v_driver.id and user_id is null;
  end if;

  select * into v_office from public.offices where id = v_driver.office_id;

  -- A captain of a paused or suspended office has no operational context. Failing
  -- closed here keeps them off the operational shell instead of letting them drive
  -- trips for an office the marketplace has stopped listing.
  if v_office.id is null or v_office.status <> 'active' then
    return null;
  end if;

  -- ── Licensing ────────────────────────────────────────────────────────────────
  -- Resolved server-side, because the captain app holds no entitlement context and
  -- must not be trusted to gate itself.
  v_app := public.platform_value_is_truthy(
             public.platform_resolve_feature(v_office.id, null, 'driver_app') -> 'value');
  v_tracking := public.platform_value_is_truthy(
             public.platform_resolve_feature(v_office.id, null, 'live_tracking') -> 'value');

  -- THE MID-TRIP RULE. A captain who is already driving is never cut off, whatever
  -- the office owes. This exemption is the reason the whole design says suspension
  -- degrades rather than blacks out — it is the one gate where the alternative has
  -- physical consequences.
  select exists (
    select 1 from public.operation_trips t
     where t.driver_id = v_driver.id
       and t.status in ('boarding','in_progress')
  ) into v_in_flight;

  v_blocked := (not v_app)
               and not v_in_flight
               and public.platform_enforcement_mode() = 'enforcing';

  return jsonb_build_object(
    'driver_id',     v_driver.id,
    'full_name',     v_driver.full_name,
    'phone',         v_driver.phone,
    'employee_code', v_driver.employee_code,
    'office_id',     v_office.id,
    'office_name',   v_office.name,
    -- New. Absent-tolerant on the client: an older build that ignores this key
    -- behaves exactly as it does today.
    'licensing', jsonb_build_object(
      'driver_app',    v_app,
      'live_tracking', v_tracking,
      'in_flight',     v_in_flight,
      'blocked',       v_blocked,
      'message_ar',    case
        when v_blocked then 'خدمة تطبيق الكابتن متوقفة حاليًا لهذا المكتب. تواصل مع إدارة المكتب.'
        else null
      end)
  );
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Register the gates
-- ═══════════════════════════════════════════════════════════════════════════════════

insert into public.platform_feature_gates (feature_key, gate_kind, gate_ref, note) values
  ('client_app',         'rls', 'office_is_listed',        'كل أسطح السوق للعملاء'),
  ('client_app',         'trigger', 'trg_license_project_hold', 'إسقاط الحالة على offices.licensing_hold'),
  ('passenger_packages', 'rls', 'packages_marketplace_read',           'إخفاء الباقات عن العملاء'),
  ('passenger_packages', 'rls', 'transport_packages_marketplace_read', 'إخفاء باقات النقل عن العملاء'),
  ('live_tracking',      'rls', 'trip_live_locations_read', 'إخفاء الموقع اللحظي'),
  ('live_tracking',      'rpc', 'captain_session_context',  'إيقاف ناشر الموقع في تطبيق الكابتن'),
  ('driver_app',         'rpc', 'captain_session_context',  'حجب دخول الكابتن — مع استثناء الرحلة الجارية')
on conflict (feature_key, gate_kind, gate_ref) do nothing;


revoke all on function public.office_refresh_licensing_hold(uuid) from public, anon, authenticated;
revoke all on function public.office_override_project_hold()      from public, anon, authenticated;
revoke all on function public.plan_feature_project_hold()         from public, anon, authenticated;
