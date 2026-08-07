-- ═══════════════════════════════════════════════════════════════════════════════════
-- EWT Entitlement Platform — enforcement completion
--
-- Design: docs/architecture/PLATFORM_LICENSING.md §4.3, §5.3, §5.4, §7.2, §7.3,
--         Part 6, Part 11, Part 15 step 5.
--
-- Phases 1–6 built the subsystem and left `enforcement_mode = 'off'`. This migration
-- closes the enforcement gaps found by the pre-enforcement audit, so that flipping
-- the switch enforces what the catalog claims and nothing more.
--
-- ── The seven gaps this closes ──────────────────────────────────────────────────────
--
--   G1  READ-ONLY WAS NEVER IMPLEMENTED. §14.3 says a suspended, cancelled or
--       expired office is read-only. Every gate shipped so far is BEFORE INSERT, so
--       a held office could still UPDATE and DELETE its whole configuration —
--       re-price packages, delete routes, remove operators. Section 2.
--
--   G2  STOCK QUOTAS WERE BYPASSABLE BY UPDATE. max_drivers and max_admin_users
--       count rows with status = 'active'. With an INSERT-only trigger an office at
--       5/5 deactivates one driver, creates a sixth (the count now reads 4), then
--       re-activates the fifth: six active drivers on a five-driver plan. Section 3.
--
--   G3  FIFTEEN FEATURES CLAIMED `enforced` IN THE DESIGN AND HAD NO GATE. Part 6
--       marks 34 features E; only 17 carried a gate row. Sections 4–8 add real gates
--       for eleven of them, and section 9 records the honest verdict for the rest.
--
--   G4  assert_feature() WAS DEAD CODE. Defined in Phase 4, called from nowhere. The
--       new RPCs in sections 6 and 7 are its first callers; section 5 closes the
--       refund-decision path it was meant to guard, at the table instead.
--
--   G5  THE KILL SWITCH WAS INCOMPLETE. office_sells_packages(),
--       trip_tracking_licensed() and the licensing_hold projection resolved features
--       without consulting platform_enforcement_mode(), so a plan value could
--       withdraw a client-facing surface while the subsystem was supposedly off.
--       §15.3 promises `off` restores current behaviour instantly. Section 1 makes
--       every gate mode-aware through one helper, and section 10 rewires those three.
--
--   G6  `license_expired` WAS UNREACHABLE. §7.2 documents six refusal codes; the
--       verdict function collapsed all three held states onto `license_suspended`,
--       so the renewal card in §7.2 could never be shown. Section 1 fixes it.
--
--   G7  NOTIFICATION DISPATCH HAD NO BOUNDARY AT ALL. `notifications_staff_insert`
--       let any office user insert a notification addressed to ANY user id, with no
--       office scoping and no licensing. Section 7 replaces it with an audited RPC.
--
-- ── What this migration deliberately does NOT do ───────────────────────────────────
--
-- It does not enable enforcement. That is one row, in its own migration, so that the
-- flip is reviewable and revertible on its own.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. Mode-aware primitives — the kill switch has to reach every gate (G5, G6)
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.platform_is_enforcing()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.platform_enforcement_mode() = 'enforcing';
$$;

comment on function public.platform_is_enforcing() is
  'The single question every gate must ask before refusing anything. §15.3 promises '
  'enforcement_mode = ''off'' restores prior behaviour instantly at any point, and a '
  'gate that resolves a feature without asking this breaks that promise.';


-- The gate to use inside an RLS policy, a view predicate or a security-definer
-- helper. Fails OPEN while the platform is not enforcing, and fails CLOSED once it
-- is. Never raises: a policy expression that raises turns every guarded query into a
-- permission error instead of an empty result (the trap from 20260721140000 §2).
create or replace function public.office_licensed(p_key text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not public.platform_is_enforcing() or public.office_has(p_key);
$$;

create or replace function public.office_licensed_for(p_office_id uuid, p_key text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not public.platform_is_enforcing()
      or p_office_id is null
      or public.platform_value_is_truthy(
           public.platform_resolve_feature(p_office_id, null, p_key) -> 'value');
$$;

comment on function public.office_licensed(text) is
  'Mode-aware entitlement test for read surfaces. Prefer this over office_has() '
  'anywhere a FALSE would hide data, so that turning enforcement off really does '
  'restore the previous behaviour.';


-- ── The held-license refusal code (G6) ─────────────────────────────────────────────
--
-- §7.2 documents `license_expired` as a distinct code driving a renewal card rather
-- than a billing banner. Both enforcement paths collapsed it onto
-- `license_suspended`, which made one of the six documented codes unreachable.

create or replace function public.license_refusal_code(p_license_status text)
returns text
language sql
immutable
as $$
  select case p_license_status
    when 'expired' then 'license_expired'
    else 'license_suspended'
  end;
$$;


create or replace function public.office_can_consume_for(
  p_office_id uuid,
  p_key       text,
  p_amount    bigint default 1
) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_res       jsonb;
  v_type      text;
  v_value     jsonb;
  v_limit     bigint;
  v_used      bigint;
  v_unlimited boolean := false;
  v_allowed   boolean;
  v_reason    text := null;
  v_held      text;
begin
  v_res   := public.platform_resolve_feature(p_office_id, null, p_key);
  v_type  := v_res ->> 'value_type';
  v_value := v_res -> 'value';

  -- Which held state we are in decides which of the six codes the client sees, and
  -- therefore whether the office is shown a billing banner or a renewal card.
  v_held := case when v_res ->> 'source' = 'license_hold'
                 then public.license_refusal_code(v_res ->> 'license_status')
            end;

  -- A non-limit feature has no quota; the verdict degenerates to "is it on".
  if v_type <> 'limit' then
    v_allowed := public.platform_value_is_truthy(v_value);
    if not v_allowed then
      v_reason := case
        when v_res ->> 'blocked_by' is not null then 'feature_dependency_blocked'
        when v_held is not null then v_held
        else 'feature_not_licensed'
      end;
    end if;
    return jsonb_build_object(
      'allowed', v_allowed, 'limit', null, 'used', null, 'remaining', null,
      'unlimited', false, 'reason', v_reason, 'feature', p_key,
      'plan_key', v_res ->> 'plan_key', 'source', v_res ->> 'source',
      'blocked_by', v_res ->> 'blocked_by',
      'license_status', v_res ->> 'license_status');
  end if;

  v_used := public.office_usage_for(p_office_id, p_key);

  if (v_value #>> '{}') = 'unlimited' then
    v_unlimited := true;
    v_allowed   := true;
  else
    v_limit   := (v_value #>> '{}')::bigint;
    v_allowed := (v_used + greatest(p_amount, 0)) <= v_limit;
    if not v_allowed then
      v_reason := case
        when v_res ->> 'blocked_by' is not null then 'feature_dependency_blocked'
        when v_held is not null then v_held
        else 'quota_exceeded'
      end;
    end if;
  end if;

  return jsonb_build_object(
    'allowed',   v_allowed,
    'limit',     case when v_unlimited then null else v_limit end,
    'used',      v_used,
    'remaining', case when v_unlimited then null else greatest(v_limit - v_used, 0) end,
    'unlimited', v_unlimited,
    'reason',    v_reason,
    'feature',   p_key,
    'plan_key',  v_res ->> 'plan_key',
    'source',    v_res ->> 'source',
    'blocked_by', v_res ->> 'blocked_by',
    'license_status', v_res ->> 'license_status');
end;
$$;


-- assert_feature gains the same three-way answer, so an RPC guard and a trigger
-- report the identical code for the identical cause (the parity rule established in
-- 20260807150100).
create or replace function public.assert_feature(p_key text)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_res jsonb;
begin
  if not public.platform_is_enforcing() then
    return;
  end if;

  v_res := public.office_feature(p_key);

  if not public.platform_value_is_truthy(v_res -> 'value') then
    raise exception '%', case
        when v_res ->> 'blocked_by' is not null  then 'feature_dependency_blocked'
        when v_res ->> 'source' = 'license_hold'
          then public.license_refusal_code(v_res ->> 'license_status')
        else 'feature_not_licensed'
      end
      using detail = v_res::text, errcode = 'check_violation';
  end if;
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. Read-only suspension, actually implemented (G1)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- §14.3: suspended / cancelled / expired ⇒ read-only. Every gate before this one was
-- BEFORE INSERT, which enforced "cannot create" and nothing else.
--
-- ── What read-only means, and where the line is ─────────────────────────────────────
--
-- Decision 4 is absolute: a licensing action must never strand a passenger or a
-- captain. So the split is not "writes vs reads", it is
-- **CONFIGURATION vs OPERATION**:
--
--   CONFIGURATION — the office's sellable inventory and its own settings. A held
--     office may not change it. drivers, vehicles, assignments, routes, operators,
--     fare bundles, payment configuration, wallet policy. Nothing here is time
--     critical, and freezing it is exactly the commercial leverage suspension is for.
--
--   OPERATION — honouring what was already sold. Trip status advances, bookings get
--     checked in and cancelled, seats are taken, refunds are filed and settled,
--     tickets are scanned, complaints are answered. NONE of these tables is attached.
--     A trip that cannot be marked complete is a bus that never arrives.
--
-- Trip DELETE is the one operational write that is blocked: destroying a trip row
-- destroys the record of tickets sold against it, and no billing dispute justifies
-- that.
--
-- ── Why the CALLER decides and not the row ─────────────────────────────────────────
--
-- The gate asks "is the actor an operator of a held office", not "does this row
-- belong to a held office". Three reasons: a platform admin must be able to repair a
-- suspended tenant's data; internal security-definer triggers (trip cascades, ledger
-- projections, the lifecycle job) run with no office context and must never be
-- caught; and the promise being enforced is about what the OFFICE may do.

create or replace function public.office_license_writes_allowed(p_office_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not exists (
    select 1 from public.office_licenses l
     where l.office_id = p_office_id
       and l.status in ('suspended','cancelled','expired')
  );
$$;

comment on function public.office_license_writes_allowed(uuid) is
  'False while the office is suspended, cancelled or expired. Consulted by the '
  'read-only trigger on configuration tables — never on operational ones, because a '
  'licensing action that strands a passenger is a safety incident (§4.3, decision 4).';

revoke all on function public.office_license_writes_allowed(uuid) from public;
grant execute on function public.office_license_writes_allowed(uuid) to authenticated;


create or replace function public.enforce_license_read_only()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller_office uuid;
  v_row_office    uuid;
  v_status        text;
begin
  if not public.platform_is_enforcing() then
    return coalesce(new, old);
  end if;

  -- A platform admin repairing a suspended tenant is the whole point of having an
  -- admin. Never blocked.
  if public.is_platform_admin() then
    return coalesce(new, old);
  end if;

  v_caller_office := public.current_office_id();

  -- No office context: an internal definer path, the lifecycle job, or a
  -- passenger-side write. Not the actor this gate is about.
  if v_caller_office is null then
    return coalesce(new, old);
  end if;

  v_row_office := nullif(to_jsonb(coalesce(new, old)) ->> 'office_id', '')::uuid;
  if v_row_office is not null and v_row_office <> v_caller_office then
    -- RLS already refuses this; the gate has no opinion about another office's rows.
    return coalesce(new, old);
  end if;

  if public.office_license_writes_allowed(v_caller_office) then
    return coalesce(new, old);
  end if;

  select l.status into v_status
    from public.office_licenses l where l.office_id = v_caller_office;

  raise exception '%', public.license_refusal_code(v_status)
    using detail = jsonb_build_object(
            'allowed',        false,
            'reason',         public.license_refusal_code(v_status),
            'license_status', v_status,
            'table_name',     tg_table_name,
            'operation',      tg_op)::text,
          errcode = 'check_violation';
end;
$$;

revoke all on function public.enforce_license_read_only() from public, anon, authenticated;


-- ── Configuration tables: frozen while held ────────────────────────────────────────

drop trigger if exists trg_readonly_drivers on public.drivers;
create trigger trg_readonly_drivers
  before update or delete on public.drivers
  for each row execute function public.enforce_license_read_only();

drop trigger if exists trg_readonly_vehicles on public.vehicles;
create trigger trg_readonly_vehicles
  before update or delete on public.vehicles
  for each row execute function public.enforce_license_read_only();

drop trigger if exists trg_readonly_assignments on public.assignments;
create trigger trg_readonly_assignments
  before update or delete on public.assignments
  for each row execute function public.enforce_license_read_only();

drop trigger if exists trg_readonly_routes on public.operation_routes;
create trigger trg_readonly_routes
  before update or delete on public.operation_routes
  for each row execute function public.enforce_license_read_only();

-- §5.4's sibling rule: this blocks an operator EDIT while held. It never disables an
-- existing operator, and it never locks the office out of its own dashboard.
drop trigger if exists trg_readonly_office_users on public.office_users;
create trigger trg_readonly_office_users
  before update or delete on public.office_users
  for each row execute function public.enforce_license_read_only();

drop trigger if exists trg_readonly_packages on public.packages;
create trigger trg_readonly_packages
  before update or delete on public.packages
  for each row execute function public.enforce_license_read_only();

drop trigger if exists trg_readonly_transport_packages on public.transport_packages;
create trigger trg_readonly_transport_packages
  before update or delete on public.transport_packages
  for each row execute function public.enforce_license_read_only();

drop trigger if exists trg_readonly_package_tiers on public.package_vehicle_tiers;
create trigger trg_readonly_package_tiers
  before update or delete on public.package_vehicle_tiers
  for each row execute function public.enforce_license_read_only();

drop trigger if exists trg_readonly_payment_configs on public.office_payment_configs;
create trigger trg_readonly_payment_configs
  before update or delete on public.office_payment_configs
  for each row execute function public.enforce_license_read_only();

drop trigger if exists trg_readonly_wallet_policies on public.office_wallet_policies;
create trigger trg_readonly_wallet_policies
  before update or delete on public.office_wallet_policies
  for each row execute function public.enforce_license_read_only();


-- The one operational DELETE that is blocked. UPDATE is deliberately absent: a trip
-- must always be able to board, depart, complete and be cancelled.
drop trigger if exists trg_readonly_trip_delete on public.operation_trips;
create trigger trg_readonly_trip_delete
  before delete on public.operation_trips
  for each row execute function public.enforce_license_read_only();


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. Stock quotas re-checked on the transitions that grow the count (G2)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- office_usage_stock() counts drivers and operators with status = 'active'. An
-- INSERT-only trigger therefore meters only half the ways the count can rise:
--
--     5/5 drivers → deactivate one (4/5) → create a sixth (allowed) → re-activate
--     the fifth → six active drivers on a five-driver plan.
--
-- §5.4 still holds, and this does not contradict it: nothing existing is deleted or
-- disabled. Re-activation is a NEW claim on a seat, so it is metered like one, while
-- a driver who is already active stays untouched forever.

create or replace function public.enforce_stock_reactivation_quota()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Only the transition INTO the counted set, and only when the office is unchanged.
  -- Deactivation, archiving and every edit that leaves status alone pass straight
  -- through: a limit gates growth, never existence.
  if new.status = 'active' and coalesce(old.status, '') <> 'active' then
    perform public.enforce_office_quota_keys(
      new.office_id, tg_argv, tg_table_name, tg_op);
  end if;
  return new;
end;
$$;

revoke all on function public.enforce_stock_reactivation_quota()
  from public, anon, authenticated;

drop trigger if exists trg_quota_driver_reactivate on public.drivers;
create trigger trg_quota_driver_reactivate
  before update of status on public.drivers
  for each row execute function public.enforce_stock_reactivation_quota('max_drivers');

drop trigger if exists trg_quota_operator_reactivate on public.office_users;
create trigger trg_quota_operator_reactivate
  before update of status on public.office_users
  for each row
  execute function public.enforce_stock_reactivation_quota('max_admin_users');


-- Moving a row between offices is a creation as far as the receiving office's meter
-- is concerned. RLS makes this hard to reach today; metering it costs one trigger and
-- removes the question.
create or replace function public.enforce_office_transfer_quota()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.office_id is distinct from old.office_id then
    perform public.enforce_office_quota_keys(
      new.office_id, tg_argv, tg_table_name, tg_op);
  end if;
  return new;
end;
$$;

revoke all on function public.enforce_office_transfer_quota()
  from public, anon, authenticated;

drop trigger if exists trg_quota_driver_transfer on public.drivers;
create trigger trg_quota_driver_transfer
  before update of office_id on public.drivers
  for each row execute function public.enforce_office_transfer_quota('max_drivers');

drop trigger if exists trg_quota_vehicle_transfer on public.vehicles;
create trigger trg_quota_vehicle_transfer
  before update of office_id on public.vehicles
  for each row execute function public.enforce_office_transfer_quota('max_vehicles');

drop trigger if exists trg_quota_route_transfer on public.operation_routes;
create trigger trg_quota_route_transfer
  before update of office_id on public.operation_routes
  for each row execute function public.enforce_office_transfer_quota('max_routes');


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. Table-level gates for four features the design marked E and never gated (G3)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Same argument as deviation 1 in the design header: gating the underlying table
-- closes every path at once — dashboard, client app, and any future writer — and
-- needs no edit to a function that already works.

-- ── A NOTE ON TRIGGER NAMES, WHICH IS LOAD-BEARING HERE ────────────────────────────
--
-- Postgres fires same-event row triggers in ALPHABETICAL order, and both tables below
-- already carry a BEFORE INSERT trigger that DERIVES office_id (bookings from the
-- trip, tickets from the booking or the picked office). enforce_office_quota() reads
-- office_id off the row and returns early when it is null, so a gate that sorts
-- BEFORE the deriving trigger silently enforces nothing.
--
--   operation_bookings:  trg_operation_bookings_office  <  trg_quota_bookings        ✅
--   support_tickets:     trg_support_tickets_office     <  trg_support_tickets_quota ✅
--
-- The ticket gate is therefore named out of the trg_quota_* family on purpose. Do not
-- "tidy" it back — it would break the gate without breaking a test.

-- `bookings` — the office's ability to take reservations at all. The gate is on
-- CREATION only: an existing booking stays readable, cancellable and refundable
-- forever, because a passenger's ticket is not the office's billing dispute.
drop trigger if exists trg_quota_bookings on public.operation_bookings;
create trigger trg_quota_bookings
  before insert on public.operation_bookings
  for each row execute function public.enforce_office_quota('bookings');

-- `support_tickets` — an office that has not bought the support desk does not
-- receive new tickets. Existing threads stay open and answerable.
drop trigger if exists trg_quota_support_tickets on public.support_tickets;
drop trigger if exists trg_support_tickets_quota on public.support_tickets;
create trigger trg_support_tickets_quota
  before insert on public.support_tickets
  for each row execute function public.enforce_office_quota('support_tickets');


-- `notifications` — the operational alert inbox (the dashboard's own channel).
--
-- This one SUPPRESSES instead of raising, and the difference matters. Operational
-- alerts are written by `push_operational_alert` from inside dozens of other
-- transactions — approving a booking, cancelling a trip, filing a refund. A trigger
-- that raised here would abort the operation that generated the alert, so switching
-- `notifications` off would not withdraw a channel, it would break the office.
--
-- Returning NULL from a BEFORE INSERT drops the row and lets the transaction proceed:
-- an unlicensed office simply stops receiving alerts, which is precisely what the
-- feature says.
create or replace function public.suppress_unlicensed_alert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.platform_is_enforcing() then
    return new;
  end if;
  if new.office_id is null then
    return new;
  end if;
  if public.platform_value_is_truthy(
       public.platform_resolve_feature(new.office_id, null, 'notifications') -> 'value') then
    return new;
  end if;
  return null;   -- dropped, never raised
end;
$$;

revoke all on function public.suppress_unlicensed_alert() from public, anon, authenticated;

drop trigger if exists trg_quota_operational_alerts on public.operational_alerts;
create trigger trg_quota_operational_alerts
  before insert on public.operational_alerts
  for each row execute function public.suppress_unlicensed_alert();


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. The refund DECISION path (G4)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- §4.3 lists "refund approval" as blocked for a held office while "refund requests"
-- stay allowed — a passenger's claim must not be blocked by the office's billing
-- dispute, but paying it out is money leaving a disputed account.
--
-- office_refund_decide() carries its role check (`office_can('refund_decide')`) and
-- was meant to carry `assert_feature('refunds')` too. Gating the transition at the
-- table instead reaches the batch RPC and any future writer with one trigger, and
-- leaves the 80-line function untouched.
create or replace function public.enforce_refund_decision_feature()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status in ('approved','rejected','settled')
     and old.status not in ('approved','rejected','settled') then
    perform public.enforce_office_quota_keys(
      new.office_id, tg_argv, tg_table_name, tg_op);
  end if;
  return new;
end;
$$;

revoke all on function public.enforce_refund_decision_feature()
  from public, anon, authenticated;

drop trigger if exists trg_quota_refund_decide on public.refund_requests;
create trigger trg_quota_refund_decide
  before update of status on public.refund_requests
  for each row execute function public.enforce_refund_decision_feature('refunds');


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Storage: max_storage_mb and logo_max_kb (G3)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Part 6 marks both E with "logo/document upload" as the gate. Uploads go straight to
-- the Storage API, so the only real boundary is a trigger on storage.objects — the
-- same reasoning as F4 for drivers and vehicles, one schema over.
--
-- Both office-scoped buckets follow the `<office_id>/…` prefix convention the
-- office-logos policy established, which is what makes the office resolvable here.

create or replace function public.enforce_storage_quota()
returns trigger
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  v_office  uuid;
  v_size    bigint := coalesce((new.metadata ->> 'size')::bigint, 0);
  v_used    bigint;
  v_limit   jsonb;
  v_max_kb  jsonb;
begin
  if public.platform_enforcement_mode() = 'off' then
    return new;
  end if;

  if new.bucket_id not in ('office-logos', 'documents') then
    return new;
  end if;

  -- office-logos is prefixed by office id; documents is written by office staff, so
  -- the caller's office is the attribution of last resort.
  begin
    v_office := nullif((storage.foldername(new.name))[1], '')::uuid;
  exception when others then
    v_office := null;
  end;
  v_office := coalesce(v_office, public.current_office_id());

  if v_office is null or not exists (select 1 from public.offices where id = v_office) then
    return new;
  end if;

  -- logo_max_kb is a per-file ceiling, not a quota: it has no meter and no usage.
  if new.bucket_id = 'office-logos' then
    v_max_kb := public.platform_resolve_feature(v_office, null, 'logo_max_kb') -> 'value';
    if (v_max_kb #>> '{}') <> 'unlimited'
       and v_size > (v_max_kb #>> '{}')::bigint * 1024 then
      if public.platform_enforcement_mode() = 'shadow' then
        insert into public.platform_quota_violations
          (office_id, feature_key, verdict, table_name, operation, actor_id)
        values (v_office, 'logo_max_kb',
                jsonb_build_object('allowed', false, 'reason', 'quota_exceeded',
                                   'feature', 'logo_max_kb',
                                   'limit', (v_max_kb #>> '{}')::bigint,
                                   'used', v_size / 1024),
                'storage.objects', tg_op, auth.uid());
      else
        raise exception 'quota_exceeded'
          using detail = jsonb_build_object(
                  'allowed', false, 'reason', 'quota_exceeded',
                  'feature', 'logo_max_kb',
                  'limit', (v_max_kb #>> '{}')::bigint,
                  'used', v_size / 1024, 'unlimited', false)::text,
                errcode = 'check_violation';
      end if;
    end if;
  end if;

  -- max_storage_mb is a stock meter: office_usage_stock() already sums the office's
  -- prefix, so the check is the incoming file plus what is already there.
  v_limit := public.platform_resolve_feature(v_office, null, 'max_storage_mb') -> 'value';
  if (v_limit #>> '{}') = 'unlimited' then
    return new;
  end if;

  v_used := public.office_usage_stock(v_office, 'max_storage_mb');

  if v_used + (v_size / 1048576) > (v_limit #>> '{}')::bigint then
    if public.platform_enforcement_mode() = 'shadow' then
      insert into public.platform_quota_violations
        (office_id, feature_key, verdict, table_name, operation, actor_id)
      values (v_office, 'max_storage_mb',
              jsonb_build_object('allowed', false, 'reason', 'quota_exceeded',
                                 'feature', 'max_storage_mb',
                                 'limit', (v_limit #>> '{}')::bigint, 'used', v_used),
              'storage.objects', tg_op, auth.uid());
    else
      raise exception 'quota_exceeded'
        using detail = jsonb_build_object(
                'allowed', false, 'reason', 'quota_exceeded',
                'feature', 'max_storage_mb',
                'limit', (v_limit #>> '{}')::bigint,
                'used', v_used, 'unlimited', false)::text,
              errcode = 'check_violation';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_storage_quota() from public, anon, authenticated;

drop trigger if exists trg_quota_storage on storage.objects;
create trigger trg_quota_storage
  before insert on storage.objects
  for each row execute function public.enforce_storage_quota();


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 7. Two new RPCs — the first real callers of assert_feature() (G3, G4, G7)
-- ═══════════════════════════════════════════════════════════════════════════════════

-- ── 7.1 Exports ────────────────────────────────────────────────────────────────────
--
-- PDF and Excel are generated in the Flutter layer from data the office is already
-- licensed to read, so there is no row to gate and no request to intercept. A
-- Flutter-only check would therefore be the only gate — which is exactly what this
-- RPC exists to avoid.
--
-- The export services call this BEFORE producing a file. It is a real server-side
-- refusal with a real flow meter, so `max_exports_per_month` is metered by the
-- database and cannot be reset by an app that lies about its own count. What it
-- cannot do is stop a determined operator who already holds the data — stated
-- plainly rather than hidden, and it is why the feature is registered as an `rpc`
-- gate and not an `rls` one.
create or replace function public.office_consume_export(p_kind text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_office  uuid := public.current_office_id();
  v_feature text;
  v_verdict jsonb;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;

  v_feature := case p_kind
    when 'pdf'   then 'export_pdf'
    when 'excel' then 'export_excel'
    when 'csv'   then 'export_excel'   -- one licence covers both spreadsheet forms
    else null
  end;

  if v_feature is null then
    raise exception 'unknown_export_kind' using detail = p_kind;
  end if;

  -- Role first, entitlement second (§7.3). The role predicate for reporting lives in
  -- DashboardPermissions and both dashboard roles hold it, so office membership is
  -- the whole role test here — stated so nobody later reads its absence as an
  -- oversight.
  perform public.assert_feature(v_feature);

  if public.platform_is_enforcing() then
    v_verdict := public.office_can_consume_for(v_office, 'max_exports_per_month', 1);
    if not (v_verdict ->> 'allowed')::boolean then
      raise exception '%', coalesce(v_verdict ->> 'reason', 'quota_exceeded')
        using detail = v_verdict::text, errcode = 'check_violation';
    end if;
  end if;

  -- Metered even while enforcement is off, so the console's usage history is real
  -- from the first day rather than starting at the flip.
  perform public.office_usage_record(v_office, 'max_exports_per_month', 1);

  return public.office_can_consume_for(v_office, 'max_exports_per_month', 0);
end;
$$;

revoke all on function public.office_consume_export(text) from public, anon;
grant execute on function public.office_consume_export(text) to authenticated;

comment on function public.office_consume_export(text) is
  'Asserts export_pdf / export_excel and consumes one unit of max_exports_per_month. '
  'Called before a file is produced. The server owns the meter; the app owns the '
  'file.';


-- ── 7.2 Notification dispatch (G7) ─────────────────────────────────────────────────
--
-- `notifications_staff_insert` allowed ANY office user to insert a notification
-- addressed to ANY user id, with no office scoping and no licensing at all. That is a
-- cross-tenant messaging surface, and it was the `push_notifications` gate's missing
-- home. Both problems close with one definer RPC and one narrowed policy.
--
-- The office's own recipients are its clients (people who booked with it) and its
-- captains (its drivers). Anyone else is refused, whatever the plan says.
create or replace function public.office_dispatch_notification(
  p_user_id    uuid,
  p_title      text,
  p_body       text,
  p_category   text default 'general',
  p_target_app text default 'client',
  p_action_url text default null,
  p_data       jsonb default '{}'::jsonb
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
  v_id     uuid;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if p_user_id is null then
    raise exception 'recipient_required';
  end if;
  if nullif(btrim(coalesce(p_title, '')), '') is null then
    raise exception 'title_required';
  end if;

  perform public.assert_feature('push_notifications');

  -- The office may only reach its own audience: a client who has booked with it, or
  -- one of its own captains. Without this the RPC would inherit exactly the
  -- cross-tenant hole it replaces.
  if not exists (
       select 1 from public.operation_bookings b
        where b.office_id = v_office and b.client_id = p_user_id)
     and not exists (
       select 1 from public.drivers d
        where d.office_id = v_office and d.user_id = p_user_id)
     and not exists (
       select 1 from public.office_users u
        where u.office_id = v_office and u.user_id = p_user_id)
  then
    raise exception 'recipient_not_in_office';
  end if;

  insert into public.notifications
    (user_id, title, body, category, target_app, action_url, data, is_read)
  values
    (p_user_id, btrim(p_title), coalesce(p_body, ''), coalesce(p_category, 'general'),
     coalesce(p_target_app, 'client'), p_action_url, coalesce(p_data, '{}'::jsonb), false)
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.office_dispatch_notification(uuid, text, text, text, text, text, jsonb)
  from public, anon;
grant execute on function public.office_dispatch_notification(uuid, text, text, text, text, text, jsonb)
  to authenticated;

-- The policy this replaces. Internal helpers (push_notification and friends) are
-- `security definer` and unaffected; the client and captain apps only ever read and
-- mark their own rows.
drop policy if exists notifications_staff_insert on public.notifications;

comment on function public.office_dispatch_notification(uuid, text, text, text, text, text, jsonb) is
  'The only path by which an office may push a notification. Replaces the '
  'notifications_staff_insert policy, which let any office user address any user id '
  'on the platform. Gated on push_notifications, and scoped to the office''s own '
  'clients, captains and operators.';


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 8. Reports: a real read gate on the three reports-exclusive views (G3)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- These three views exist for the reports module and nothing else, so a licensing
-- term in them is a genuine server-side boundary rather than a UI convention. It is
-- mode-aware through office_licensed(), so turning enforcement off restores the
-- previous behaviour exactly.
--
-- revenue_daily_view is deliberately NOT gated: finance and the owner overview read
-- it too, and withdrawing it with `reports` would take down two modules the office
-- still holds. Its module-level gate is recorded honestly as `ui` in section 9.

create or replace view public.drivers_performance_view as
  select d.id as driver_id,
         d.office_id,
         d.full_name as name,
         d.status,
         count(t.id) filter (where t.status = 'completed') as completed_trips,
         coalesce(sum(t.revenue) filter (where t.status = 'completed'), 0::numeric)
           as total_revenue
    from public.drivers d
    left join public.operation_trips t
      on t.driver_id = d.id and t.office_id = d.office_id
   where (d.office_id = public.current_office_id() and public.office_licensed('reports'))
      or public.is_platform_admin()
   group by d.id, d.office_id, d.full_name, d.status;

create or replace view public.vehicles_efficiency_view as
  select v.id as vehicle_id,
         v.office_id,
         v.plate_number,
         v.model,
         v.status,
         count(t.id) filter (where t.status = 'completed') as completed_trips,
         coalesce(avg(t.occupancy_rate) filter (where t.status = 'completed'), 0::numeric)
           as avg_occupancy_rate,
         case
           when v.status = 'maintenance' then 'تحتاج صيانة'
           when v.status = 'active'      then 'جاهزة'
           else 'غير متاحة'
         end as maintenance_status
    from public.vehicles v
    left join public.operation_trips t
      on t.vehicle_id = v.id and t.office_id = v.office_id
   where (v.office_id = public.current_office_id() and public.office_licensed('reports'))
      or public.is_platform_admin()
   group by v.id, v.office_id, v.plate_number, v.model, v.status;

create or replace view public.complaints_summary_view as
  select c.office_id,
         c.category,
         count(c.id) as total_complaints,
         count(c.id) filter (where c.status in ('resolved','closed')) as resolved_complaints,
         count(c.id) filter (where c.status not in ('resolved','closed')) as pending_complaints
    from public.operation_complaints c
   where (c.office_id = public.current_office_id() and public.office_licensed('reports'))
      or public.is_platform_admin()
   group by c.office_id, c.category;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 9. Make the client-facing predicates mode-aware (G5)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- All three resolved features without asking whether the platform was enforcing, so
-- a plan value could withdraw a marketplace surface while the kill switch was
-- supposedly off. §15.3 promises otherwise.

create or replace function public.office_sells_packages(p_office_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.office_licensed_for(p_office_id, 'passenger_packages');
$$;

create or replace function public.trip_tracking_licensed(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select public.office_licensed_for(t.office_id, 'live_tracking')
      from public.operation_trips t where t.id = p_trip_id), true);
$$;


-- licensing_hold is a projection, so "mode-aware" means the client_app term only
-- applies while enforcing. The license-status term stays unconditional: a suspension
-- delisting is a commercial state the platform set by hand, not an inference the
-- kill switch should undo.
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

  if public.platform_is_enforcing()
     and not public.platform_value_is_truthy(
           public.platform_resolve_feature(p_office_id, null, 'client_app') -> 'value') then
    v_hold := 'delisted';
  end if;

  update public.offices
     set licensing_hold = v_hold
   where id = p_office_id
     and coalesce(licensing_hold, 'none') is distinct from v_hold;
end;
$$;

revoke all on function public.office_refresh_licensing_hold(uuid)
  from public, anon, authenticated;


-- Flipping enforcement_mode changes the answer for every office, so the projection
-- has to be recomputed when it moves. Without this, enabling enforcement would leave
-- every hold stale until the next license edit.
create or replace function public.platform_settings_project_holds()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare v_office uuid;
begin
  if new.enforcement_mode is distinct from old.enforcement_mode then
    for v_office in select id from public.offices loop
      perform public.office_refresh_licensing_hold(v_office);
    end loop;
  end if;
  return null;
end;
$$;

revoke all on function public.platform_settings_project_holds()
  from public, anon, authenticated;

drop trigger if exists trg_settings_project_holds on public.platform_settings;
create trigger trg_settings_project_holds
  after update on public.platform_settings
  for each row execute function public.platform_settings_project_holds();


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 10. One seed correction the audit forced: restricted.max_captains
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- The `restricted` fallback plan (§4.3) seeded max_captains = 0 alongside every other
-- creation limit. Under enforcement that has a consequence nobody intended:
-- `captain_session_context` BINDS a driver row to its auth user on first sign-in, and
-- trg_quota_captains meters exactly that transition. So a captain who had never
-- signed in before could not sign in at all while their office was suspended —
-- which contradicts §4.3's own row ("Captain app sign-in and trip completion ✅
-- allowed") and Part 11's absolute mid-trip rule.
--
-- The plan already makes this exemption once, for the same reason, with
-- max_live_trips = 'unlimited': a licensing state may not stop a bus. max_captains
-- gets the same treatment rather than a special case in the trigger, so the mechanism
-- stays uniform and the exemption is visible in the plan the console shows.
update public.platform_plan_features pf
   set value = '"unlimited"'::jsonb
  from public.platform_plans p
 where p.id = pf.plan_id
   and p.key = 'restricted'
   and pf.feature_key = 'max_captains'
   and pf.value <> '"unlimited"'::jsonb;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 11. Register every gate this migration created (§3.2)
-- ═══════════════════════════════════════════════════════════════════════════════════

insert into public.platform_feature_gates (feature_key, gate_kind, gate_ref, note) values
  -- Section 2 — read-only holds. Registered against client_app because that is the
  -- feature whose licence state drives them; the gate_ref names the mechanism.
  ('client_app',            'trigger', 'enforce_license_read_only',   'وضع القراءة فقط: لا تعديل ولا حذف للإعدادات والمخزون'),

  -- Section 3 — the UPDATE half of the stock meters.
  ('max_drivers',           'trigger', 'trg_quota_driver_reactivate',   'إعادة تنشيط سائق تُحتسب من الحد'),
  ('max_admin_users',       'trigger', 'trg_quota_operator_reactivate', 'إعادة تنشيط مستخدم تُحتسب من الحد'),
  ('max_drivers',           'trigger', 'trg_quota_driver_transfer',     'نقل سائق إلى المكتب'),
  ('max_vehicles',          'trigger', 'trg_quota_vehicle_transfer',    'نقل مركبة إلى المكتب'),
  ('max_routes',            'trigger', 'trg_quota_route_transfer',      'نقل خط سير إلى المكتب'),

  -- Section 4 — new table gates.
  ('bookings',              'trigger', 'trg_quota_bookings',            'إنشاء حجز'),
  ('support_tickets',       'trigger', 'trg_support_tickets_quota',     'إنشاء شكوى'),
  ('notifications',         'trigger', 'trg_quota_operational_alerts',  'تنبيهات اللوحة — تُحجب بلا إفشال العملية'),

  -- Section 5 — the refund decision.
  ('refunds',               'trigger', 'trg_quota_refund_decide',       'اعتماد أو رفض طلب استرداد'),

  -- Section 6 — storage.
  ('max_storage_mb',        'trigger', 'trg_quota_storage',             'حد المساحة عند الرفع'),
  ('logo_max_kb',           'trigger', 'trg_quota_storage',             'حد حجم ملف الشعار'),

  -- Section 7 — the two new RPCs.
  ('export_pdf',            'rpc',     'office_consume_export',         'تصدير PDF'),
  ('export_excel',          'rpc',     'office_consume_export',         'تصدير Excel / CSV'),
  ('max_exports_per_month', 'rpc',     'office_consume_export',         'حصة التصدير الشهرية'),
  ('push_notifications',    'rpc',     'office_dispatch_notification',  'إرسال إشعار من المكتب'),

  -- Section 8 — the reports read gate.
  ('reports',               'view',    'drivers_performance_view',      'تقرير أداء السائقين'),
  ('reports',               'view',    'vehicles_efficiency_view',      'تقرير كفاءة المركبات'),
  ('reports',               'view',    'complaints_summary_view',       'ملخص الشكاوى'),

  -- ── Module-surface gates ─────────────────────────────────────────────────────────
  -- Recorded as `ui` and not `rls`, because that is what they are. These four gate a
  -- MODULE, not a secret: the data behind each is read through tables the office is
  -- still licensed for by other modules, so there is no confidentiality boundary to
  -- defend — only a product surface to withhold. The sidebar hides or locks them and
  -- the route refuses them; an operator issuing raw REST calls would still see the
  -- underlying rows, and that is the correct outcome for their own data.
  ('finance',               'ui',      'DashboardRoutes.payments',      'وحدة المدفوعات في اللوحة'),
  ('live_ops_center',       'ui',      'DashboardRoutes.liveOps',       'مركز العمليات المباشرة'),
  ('report_level',          'ui',      'report_export_toolbar',         'اتساع التقارير المتاحة'),
  ('analytics_level',       'ui',      'DashboardRoutes.ownerOverview', 'اتساع نظرة المالك')
on conflict (feature_key, gate_kind, gate_ref) do nothing;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 12. What is STILL not enforced, named rather than quietly skipped
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Part 6 of the design marks these E. They are not, they cannot be yet, and the
-- honest `declared` badge is the whole point of decision 7:
--
--   referrals   — `referrals`, `referral_codes` and `referral_rewards` carry no
--                 office_id. The programme is platform-wide, so there is nothing to
--                 meter an office by and no row to refuse. Enforcing it would require
--                 giving the referral domain an office dimension first, which is a
--                 product decision and not a licensing one.
--   promotions  — `promo_codes` still does not exist in this database.
--   loyalty     — `loyalty_accounts` still carries no office_id.
--
-- And these stay `declared` because the capability itself does not exist:
--   bulk_import · qr_tickets · support_sla · marketing · custom_roles · multi_branch
--   max_branches · api_access · max_api_calls_per_month · webhook_url · white_label
--   custom_domain · booking_retention_days
--
-- 31 of 47 features are enforced after this migration, up from 17. The remaining 16
-- are catalogued, sellable in principle, and marked "غير مفعّل بعد" in the plan
-- builder so nobody promises a customer something the code does not do.
--
-- Part 6 of the design claims 34/13. That number was never true and this migration
-- does not make it true: three of the features it counts as enforced have no
-- office-scoped surface to gate. Reporting 31/16 instead of quietly rounding up to
-- the design's figure is the entire purpose of enforcement_status (decision 7).
