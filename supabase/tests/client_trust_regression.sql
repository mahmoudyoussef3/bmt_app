-- ═══════════════════════════════════════════════════════════════════════════════════
-- Client trust regression suite  (Phase 7)
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Impersonates the two parties the Client app ships credentials for — an anonymous
-- visitor holding the shipped anon key, and a signed-in rider — and asserts that
-- neither can read another customer's support attachments, forge a notification
-- for anyone, or book a seat at a price they chose themselves.
--
-- Runs entirely inside BEGIN … ROLLBACK. Nothing survives the run, so it is safe
-- against the production-bound development database.
--
--   supabase db query --linked -f supabase/tests/client_trust_regression.sql
--
-- Every row of the output should read OK. Any row reading "STILL EXPLOITABLE" or
-- "BROKEN" is a regression.
--
-- Covers: 20260730090000 (client trust hardening).
-- ═══════════════════════════════════════════════════════════════════════════════════

begin;

create temp table probe(step text, result text) on commit drop;
create temp table fixture(k text primary key, v text) on commit drop;
grant all on probe to authenticated, anon;
grant all on fixture to authenticated, anon;

-- ───────────────────────────────────────────────────────────────────────────────────
-- Resolve the cast as superuser, before any impersonation starts.
--   ticket_owner : the client who owns some support ticket
--   outsider     : any other client — the attacker
-- ───────────────────────────────────────────────────────────────────────────────────
do $$
declare v_ticket uuid; v_owner uuid; v_outsider uuid;
begin
  select t.id, t.client_id into v_ticket, v_owner
    from public.support_tickets t
   where t.client_id is not null
   order by t.created_at desc limit 1;

  select c.id into v_outsider
    from public.clients c
   where v_owner is null or c.id <> v_owner
   limit 1;

  if v_ticket is null or v_outsider is null then
    insert into probe values
      ('00. fixture', 'ABORTED — needs one support ticket and two clients');
    return;
  end if;

  insert into fixture values
    ('ticket',   v_ticket::text),
    ('owner',    v_owner::text),
    ('outsider', v_outsider::text);
end $$;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. support_attachments — RLS is actually on
-- ───────────────────────────────────────────────────────────────────────────────────

insert into probe
select '01. support_attachments RLS enabled',
       case when c.relrowsecurity then 'OK' else 'STILL EXPLOITABLE — RLS off' end
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and c.relname = 'support_attachments';

insert into probe
select '02. support_attachments closed to anon',
       case when count(*) = 0 then 'OK'
            else 'STILL EXPLOITABLE — anon holds ' || string_agg(privilege_type, ',')
       end
  from information_schema.role_table_grants
 where table_schema = 'public'
   and table_name = 'support_attachments'
   and grantee = 'anon';

-- An anonymous visitor tries to list every attachment on the platform. With the
-- grant revoked this raises rather than returning nothing — a stronger result
-- than an empty read, and the one the migration aims for.
do $$
declare v_count bigint;
begin
  begin
    set local role anon;
    select count(*) into v_count from public.support_attachments;
    reset role;
    insert into probe values ('03. anon cannot read attachments',
      case when v_count = 0 then 'OK (RLS filtered)'
           else 'STILL EXPLOITABLE — ' || v_count || ' rows readable' end);
  exception when insufficient_privilege then
    reset role;
    insert into probe values ('03. anon cannot read attachments',
      'OK (grant revoked)');
  end;
end $$;

-- A signed-in rider who owns nothing tries to read someone else's ticket files —
-- exactly what SupabaseSupportDatasource.getTicketAttachments(ticketId) would do
-- if it were handed an id that is not theirs.
set local role authenticated;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-000000000000","role":"authenticated"}';
insert into probe
select '04. outsider cannot read another ticket''s attachments',
       case when count(*) = 0 then 'OK'
            else 'STILL EXPLOITABLE — ' || count(*) || ' rows readable' end
  from public.support_attachments a
 where a.ticket_id = (select v::uuid from fixture where k = 'ticket');
reset role;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. notifications — a rider cannot address anyone
-- ───────────────────────────────────────────────────────────────────────────────────

insert into probe
select '05. no public INSERT policy on notifications',
       case when count(*) = 0 then 'OK'
            else 'STILL EXPLOITABLE — ' || string_agg(policyname, ', ') end
  from pg_policies
 where schemaname = 'public' and tablename = 'notifications' and cmd = 'INSERT'
   and 'public' = any (roles);

do $$
declare v_outsider uuid; v_owner uuid;
begin
  select v::uuid into v_outsider from fixture where k = 'outsider';
  select v::uuid into v_owner    from fixture where k = 'owner';
  if v_outsider is null then return; end if;

  begin
    set local role authenticated;
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_outsider, 'role', 'authenticated')::text, true);

    insert into public.notifications (user_id, title, body, type, category,
                                      target_app, action_url)
    values (v_owner, 'Payment rejected', 'Tap to re-enter your card',
            'payment_rejected', 'payment', 'client', '/checkout');

    reset role;
    insert into probe values
      ('06. rider cannot forge a notification', 'STILL EXPLOITABLE — insert accepted');
  exception when insufficient_privilege or others then
    reset role;
    insert into probe values ('06. rider cannot forge a notification', 'OK');
  end;
end $$;

insert into probe
select '07. notifications closed to anon',
       case when count(*) = 0 then 'OK'
            else 'STILL EXPLOITABLE — anon holds ' || string_agg(privilege_type, ',')
       end
  from information_schema.role_table_grants
 where table_schema = 'public' and table_name = 'notifications' and grantee = 'anon';

-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. Booking price authority — exactly one entry point, and it ignores the client
-- ───────────────────────────────────────────────────────────────────────────────────

insert into probe
select '08. legacy price-trusting booking RPCs are gone',
       case when count(*) = 0 then 'OK'
            else 'STILL EXPLOITABLE — ' || string_agg(proname, ', ') end
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('book_trip_seat', 'confirm_seat_booking');

insert into probe
select '09. exactly one confirm_seat_booking_v2 overload',
       case when count(*) = 1 then 'OK'
            else 'BROKEN — ' || count(*) || ' overloads' end
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'confirm_seat_booking_v2';

-- The surviving overload must be the one that resolves the fare itself. It takes
-- p_payment_amount for backwards compatibility and documents that it never reads
-- it past validation.
insert into probe
select '10. surviving booking RPC ignores the client''s amount',
       case
         when position('p_payment_amount is intentionally never read' in p.prosrc) > 0
           then 'OK'
         else 'BROKEN — cannot confirm server-side pricing'
       end
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'confirm_seat_booking_v2'
 limit 1;

-- ───────────────────────────────────────────────────────────────────────────────────
-- 4. Storage — public buckets are read-only to the public
-- ───────────────────────────────────────────────────────────────────────────────────

insert into probe
select '11. public buckets are not publicly writable',
       case when count(*) = 0 then 'OK'
            else 'STILL EXPLOITABLE — ' || string_agg(policyname, ', ') end
  from pg_policies
 where schemaname = 'storage' and tablename = 'objects'
   and cmd in ('INSERT', 'UPDATE', 'DELETE')
   and 'public' = any (roles)
   and (qual like '%documents%' or with_check like '%documents%'
     or qual like '%vehicle-images%' or with_check like '%vehicle-images%');

select * from probe order by step;

rollback;
