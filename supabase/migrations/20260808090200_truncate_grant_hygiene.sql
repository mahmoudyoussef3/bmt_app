-- ═══════════════════════════════════════════════════════════════════════════════════
-- Platform-wide TRUNCATE hygiene — the bypass that defeats every gate at once
--
-- Follows 20260729093000_tracking_truncate_hygiene.sql, which closed four tables and
-- said, in its own scope note:
--
--     "The same grant is present on roughly forty-five tables across the schema;
--      sweeping all of them is a platform-wide grant-hygiene change and is
--      recommended as its own piece of work […] rather than smuggled in under a
--      tracking migration."
--
-- This is that piece of work, and the enforcement audit is what forced it.
--
-- ── Why it belongs to licensing ─────────────────────────────────────────────────────
--
-- TRUNCATE is gated by neither row-level security nor row triggers. It therefore
-- walks through the entire enforcement design:
--
--     truncate public.operation_routes;      -- BEFORE INSERT quota:      never fires
--     truncate public.office_users;          -- read-only freeze:         never fires
--     truncate public.packages;              -- passenger_packages gate:  never fires
--     truncate public.operation_bookings;    -- bookings gate:            never fires
--
-- Measured on the linked database before this migration, `authenticated` held
-- TRUNCATE on `office_users`, `operation_bookings`, `operation_routes`, `packages`
-- and `transport_packages` — five of the eleven tables 20260808090000 had just
-- frozen. A suspended office could not edit one route and could empty all of them.
--
-- Enforcement that a single statement steps around is not enforcement, so the sweep
-- is a precondition of the flip rather than an improvement to schedule later.
--
-- ── Reachability, stated as honestly as the tracking migration stated it ────────────
--
-- PostgREST issues no TRUNCATE, so this is not reachable with an anon key over REST
-- today. It becomes reachable the moment anything runs caller-supplied SQL, any
-- SECURITY INVOKER function uses dynamic SQL, or the database port is reachable
-- directly. It is a latent privilege that nothing legitimate uses — no client role
-- has any reason to truncate anything — so it costs nothing to give up.
--
-- ── Scope ───────────────────────────────────────────────────────────────────────────
--
-- Every base table in `public`, not a curated list. A curated list is a list that
-- goes stale the next time somebody adds a table, and the correct answer for the
-- client roles is the same for all of them. Views and foreign tables are skipped
-- because TRUNCATE does not apply to them.
--
-- This does NOT touch `postgres`, `service_role`, or the migration role: server-side
-- maintenance keeps the privilege it needs.
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_rel   text;
  v_count int := 0;
begin
  for v_rel in
    select format('%I.%I', n.nspname, c.relname)
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public'
       and c.relkind = 'r'
       and (has_table_privilege('authenticated', c.oid, 'TRUNCATE')
            or has_table_privilege('anon', c.oid, 'TRUNCATE'))
     order by 1
  loop
    execute format('revoke truncate on %s from anon, authenticated', v_rel);
    v_count := v_count + 1;
  end loop;

  raise notice 'TRUNCATE revoked from anon, authenticated on % table(s)', v_count;
end $$;


-- Supabase's default privileges hand the full set — TRUNCATE included (`D` in
-- `arwdDxtm`) — to `anon` and `authenticated` on every table created in `public`.
-- Without changing them, the next table anybody adds silently reopens the hole and
-- the sweep above is a one-time cleanup rather than a rule.
--
-- REVOKE and not GRANT: ALTER DEFAULT PRIVILEGES … GRANT only adds, so restating the
-- privilege list minus TRUNCATE would leave the existing `D` exactly where it is.
--
-- There are two default-ACL entries in this schema, one per creating role. Migrations
-- run as `postgres`, so that is the one that governs every table this repo will ever
-- add; `supabase_admin` owns tables created by the platform itself and may not be
-- alterable from here, so it is attempted and its failure is reported rather than
-- fatal — a partial fix plus a notice beats a migration that cannot run.
alter default privileges for role postgres in schema public
  revoke truncate on tables from anon, authenticated;

do $$
begin
  execute 'alter default privileges for role supabase_admin in schema public '
          'revoke truncate on tables from anon, authenticated';
exception when insufficient_privilege or undefined_object then
  raise notice
    'Could not alter supabase_admin default privileges (expected: postgres is not a '
    'member). Tables created BY supabase_admin in public would still grant TRUNCATE; '
    'no migration in this repo creates one.';
end $$;


-- Verify, in the same transaction, rather than trusting the loop. A licensing gate
-- that a TRUNCATE steps around is worth failing a migration over.
do $$
declare
  v_left text;
begin
  select string_agg(c.relname, ', ' order by c.relname) into v_left
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relkind = 'r'
     and (has_table_privilege('authenticated', c.oid, 'TRUNCATE')
          or has_table_privilege('anon', c.oid, 'TRUNCATE'));

  if v_left is not null then
    raise exception 'TRUNCATE still held by a client role on: %', v_left;
  end if;
end $$;
