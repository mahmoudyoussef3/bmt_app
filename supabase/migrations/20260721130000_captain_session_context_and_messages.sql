-- ═══════════════════════════════════════════════════════════════════════════════════
-- Captain session context + captain_messages office scoping
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Two gaps left by the multi-office migration on the Captain side:
--
-- 1. `CaptainOfficeSession` (driver id + office id) is populated ONLY by
--    `link_current_captain_driver`, which needs the phone the captain typed — so it
--    is written at sign-in and never again. Supabase auth sessions survive app
--    restarts, so on every relaunch the captain is authenticated with an EMPTY
--    session. That is why every captain datasource still re-resolves the driver row
--    itself on each screen load, one of them caching it in a lazy singleton that
--    outlives sign-out (a second captain on the same device inherits the first
--    captain's id). `captain_session_context()` is the missing restore door: it
--    resolves the identity from auth.uid() alone, mirroring the Dashboard's
--    `current_office_context()`.
--
-- 2. `captain_messages` still carries its pre-office policies: addressed to `public`
--    rather than `authenticated`, and the operations side tests the legacy
--    `user_roles` table. Office operators live in `office_users`, so no dashboard
--    user can message a captain at all today, and the policy carries no office
--    predicate — the shape that, once it matched anyone, would match every office.
--
-- Note on `current_driver_id()` / `captain_office_id()`: both stay anon-executable.
-- Marketplace policies on `trip_seats` / `trip_pricing` / `trip_route_points`
-- reference them, and an anon reader evaluates every permissive policy on the table
-- — revoking EXECUTE would turn public seat-map reads into permission errors rather
-- than closing anything.

-- ── 1. Captain session context ─────────────────────────────────────────────────────
-- Returns exactly the shape `link_current_captain_driver` returns, so
-- `CaptainIdentity.fromRpc` parses both without branching. Returns NULL (not an
-- exception) when the caller is not a captain: the app asks this on every launch,
-- including for users who never were one, and that is a fact rather than a failure.
--
-- The phone fallback mirrors the Dart-side resolver this replaces: a driver whose
-- `user_id` was never linked is matched on their normalised phone and linked here,
-- so the app has no reason to run that query itself any more.

create or replace function public.captain_session_context()
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := auth.uid();
  v_driver public.drivers;
  v_office public.offices;
  v_phone  text;
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

revoke all on function public.captain_session_context() from public, anon;
grant execute on function public.captain_session_context() to authenticated;

-- ── 2. captain_messages: office-scoped operations access ───────────────────────────

alter table public.captain_messages enable row level security;
revoke all on public.captain_messages from anon;
grant select, insert, update on public.captain_messages to authenticated;

drop policy if exists "captain_messages_driver_access"     on public.captain_messages;
drop policy if exists "captain_messages_operations_access" on public.captain_messages;
drop policy if exists captain_messages_driver              on public.captain_messages;
drop policy if exists captain_messages_office              on public.captain_messages;

-- The captain sees and writes only their own trips' threads.
create policy captain_messages_driver on public.captain_messages
  for all to authenticated
  using (exists (select 1 from public.operation_trips t
                  where t.id = trip_id
                    and t.driver_id = public.current_driver_id()))
  with check (exists (select 1 from public.operation_trips t
                       where t.id = trip_id
                         and t.driver_id = public.current_driver_id()));

-- An operator sees and writes only threads on their own office's trips. This both
-- restores dashboard→captain messaging (broken since operators moved to
-- `office_users`) and confines it to one office.
create policy captain_messages_office on public.captain_messages
  for all to authenticated
  using (exists (select 1 from public.operation_trips t
                  where t.id = trip_id
                    and t.office_id = public.current_office_id()))
  with check (exists (select 1 from public.operation_trips t
                       where t.id = trip_id
                         and t.office_id = public.current_office_id()));
