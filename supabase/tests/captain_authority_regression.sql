-- ═══════════════════════════════════════════════════════════════════════════════════
-- Captain authority regression suite
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Impersonates a real captain against the linked database and asserts, in one pass,
-- that every action a captain MUST be able to perform still works and every action they
-- MUST NOT be able to perform is refused.
--
-- Runs entirely inside BEGIN … ROLLBACK: it writes an SOS, an event, a message and a
-- position fix, then throws all of it away. Nothing survives the run, so it is safe
-- against the production-bound development database.
--
--   supabase db query --linked -f supabase/tests/captain_authority_regression.sql
--
-- Point the `request.jwt.claims` sub below at an active captain who has at least one
-- trip.
-- Every row of the output should read OK or "blocked"; any row reading
-- "STILL EXPLOITABLE" or "BROKEN" is a regression.
--
-- Covers: 20260723090000 (status allowlist), 20260727160000 (lifecycle authority),
-- 20260728120000 (captain authority).

begin;

create temp table probe(step text, result text) on commit drop;
grant all on probe to authenticated;

set local role authenticated;
set local request.jwt.claims = '{"sub":"af345d1c-c4f3-490b-bacf-f4de61cc1a43","role":"authenticated"}';

do $$
declare v_trip uuid; v_rep uuid; v_ev uuid; v_pax uuid; v_n int;
begin
  insert into probe values ('00. driver resolved from JWT',
    coalesce(public.current_driver_id()::text, 'NULL — fix :captain_user'));

  select id into v_trip from public.operation_trips
   where driver_id = public.current_driver_id() limit 1;
  if v_trip is null then
    insert into probe values ('00. no trip for this captain', 'ABORTED'); return;
  end if;

  -- ── MUST WORK ────────────────────────────────────────────────────────────────────
  begin
    insert into public.driver_trip_reports (trip_id, driver_id, report_type, description, status)
    values (v_trip, public.current_driver_id(), 'emergency', 'regression SOS', 'pending')
    returning id into v_rep;
    insert into probe values ('01. file an incident', 'OK');
  exception when others then insert into probe values ('01. file an incident','BROKEN: '||sqlerrm); end;

  begin
    insert into public.trip_events (trip_id, title, description, done)
    values (v_trip, 'وصول محطة', 'regression arrival', true) returning id into v_ev;
    insert into probe values ('02. mark a station arrived', 'OK');
  exception when others then insert into probe values ('02. mark a station arrived','BROKEN: '||sqlerrm); end;

  begin
    insert into public.captain_messages (trip_id, sender_type, sender_id, body, message_type)
    values (v_trip, 'driver', auth.uid(), 'regression message', 'text');
    insert into probe values ('03. message operations', 'OK');
  exception when others then insert into probe values ('03. message operations','BROKEN: '||sqlerrm); end;

  begin
    insert into public.trip_live_locations (trip_id, driver_id, vehicle_id, latitude, longitude, recorded_at)
    select v_trip, public.current_driver_id(), t.vehicle_id, 30.0, 31.0, now()
      from public.operation_trips t where t.id = v_trip;
    insert into probe values ('04. publish own position', 'OK');
  exception when others then insert into probe values ('04. publish own position','BROKEN: '||sqlerrm); end;

  select id into v_pax from public.trip_passengers
   where trip_id=v_trip and status in ('reserved','confirmed','no_show') limit 1;
  if v_pax is not null then
    begin
      update public.trip_passengers set status='confirmed' where id=v_pax;
      get diagnostics v_n = row_count;
      insert into probe values ('05. board a rider', case when v_n>0 then 'OK' else 'BROKEN (0 rows)' end);
    exception when others then insert into probe values ('05. board a rider','BROKEN: '||sqlerrm); end;
  else
    insert into probe values ('05. board a rider', 'skipped — no rider on this trip');
  end if;

  insert into probe values ('06. live positions readable (client tracking)',
    (select 'OK — '||count(*)||' rows' from public.trip_live_locations));

  -- ── MUST FAIL ────────────────────────────────────────────────────────────────────
  begin
    update public.driver_trip_reports set status='resolved' where id=v_rep;
    get diagnostics v_n = row_count;
    insert into probe values ('10. self-resolve own incident',
      case when v_n>0 then 'STILL EXPLOITABLE' else 'blocked' end);
  exception when others then insert into probe values ('10. self-resolve own incident','blocked: '||sqlerrm); end;

  begin
    delete from public.driver_trip_reports where id=v_rep;
    get diagnostics v_n = row_count;
    insert into probe values ('11. delete own incident',
      case when v_n>0 then 'STILL EXPLOITABLE' else 'blocked' end);
  exception when others then insert into probe values ('11. delete own incident','blocked: '||sqlerrm); end;

  begin
    insert into public.driver_trip_reports (trip_id, driver_id, report_type, description, status)
    values (gen_random_uuid(), public.current_driver_id(), 'other', 'x', 'pending');
    insert into probe values ('12. file on a foreign trip', 'STILL EXPLOITABLE');
  exception when others then insert into probe values ('12. file on a foreign trip','blocked: '||sqlerrm); end;

  begin
    insert into public.trip_events (trip_id, title, description, done, event_code)
    values (v_trip, 'انطلاق الرحلة', 'forged', true, 'trip_departed');
    insert into probe values ('13. forge a lifecycle audit row', 'STILL EXPLOITABLE');
  exception when others then insert into probe values ('13. forge a lifecycle audit row','blocked: '||sqlerrm); end;

  begin
    delete from public.trip_events where id=v_ev;
    get diagnostics v_n = row_count;
    insert into probe values ('14. delete an audit event',
      case when v_n>0 then 'STILL EXPLOITABLE' else 'blocked' end);
  exception when others then insert into probe values ('14. delete an audit event','blocked: '||sqlerrm); end;

  if v_pax is not null then
    begin
      update public.trip_passengers set phone='01000000000' where id=v_pax;
      insert into probe values ('15. rewrite a rider''s identity', 'STILL EXPLOITABLE');
    exception when others then insert into probe values ('15. rewrite a rider''s identity','blocked: '||sqlerrm); end;

    begin
      update public.trip_passengers set status='cancelled' where id=v_pax;
      get diagnostics v_n = row_count;
      insert into probe values ('16. cancel a rider',
        case when v_n>0 then 'STILL EXPLOITABLE' else 'blocked' end);
    exception when others then insert into probe values ('16. cancel a rider','blocked: '||sqlerrm); end;
  end if;

  begin
    delete from public.trip_passengers where trip_id=v_trip;
    get diagnostics v_n = row_count;
    insert into probe values ('17. erase the manifest',
      case when v_n>0 then 'STILL EXPLOITABLE — '||v_n else 'blocked' end);
  exception when others then insert into probe values ('17. erase the manifest','blocked: '||sqlerrm); end;

  begin
    insert into public.captain_messages (trip_id, sender_type, sender_id, body, message_type)
    values (v_trip, 'operations', auth.uid(), 'forged', 'text');
    insert into probe values ('18. forge an operations message', 'STILL EXPLOITABLE');
  exception when others then insert into probe values ('18. forge an operations message','blocked: '||sqlerrm); end;

  begin
    insert into public.trip_live_locations (trip_id, driver_id, vehicle_id, latitude, longitude, recorded_at)
    select gen_random_uuid(), public.current_driver_id(), t.vehicle_id, 30.0, 31.0, now()
      from public.operation_trips t where t.id = v_trip;
    insert into probe values ('19. publish onto a foreign trip', 'STILL EXPLOITABLE');
  exception when others then insert into probe values ('19. publish onto a foreign trip','blocked: '||sqlerrm); end;

  begin
    delete from public.trip_live_locations where trip_id=v_trip;
    get diagnostics v_n = row_count;
    insert into probe values ('20. erase the tracking feed',
      case when v_n>0 then 'STILL EXPLOITABLE' else 'blocked' end);
  exception when others then insert into probe values ('20. erase the tracking feed','blocked: '||sqlerrm); end;

  begin
    perform public.captain_update_trip_status(v_trip, 'cancelled');
    insert into probe values ('21. cancel own trip', 'STILL EXPLOITABLE');
  exception when others then insert into probe values ('21. cancel own trip','blocked: '||sqlerrm); end;

  begin
    perform public.office_update_trip_status(v_trip, 'cancelled', 'x');
    insert into probe values ('22. cancel via the office wrapper', 'STILL EXPLOITABLE');
  exception when others then insert into probe values ('22. cancel via the office wrapper','blocked: '||sqlerrm); end;

  begin
    perform public.captain_update_trip_status(v_trip, 'open_for_booking');
    insert into probe values ('23. publish own trip', 'STILL EXPLOITABLE');
  exception when others then insert into probe values ('23. publish own trip','blocked: '||sqlerrm); end;

  begin
    perform public.update_trip_status(v_trip, 'cancelled', 'x');
    insert into probe values ('24. call the raw status setter', 'STILL EXPLOITABLE');
  exception when others then insert into probe values ('24. call the raw status setter','blocked: '||sqlerrm); end;

  -- ── cross-driver isolation ───────────────────────────────────────────────────────
  insert into probe values ('30. another driver''s trips visible',
    (select case when count(*)>0 then 'LEAK — '||count(*) else 'blocked (0 rows)' end
       from public.operation_trips
      where driver_id is not null and driver_id <> public.current_driver_id()));

  insert into probe values ('31. another trip''s manifest visible',
    (select case when count(*)>0 then 'LEAK — '||count(*) else 'blocked (0 rows)' end
       from public.trip_passengers tp
      where not exists (select 1 from public.operation_trips t
                         where t.id=tp.trip_id and t.driver_id=public.current_driver_id())));
end $$;

select step, result from probe order by step;

rollback;
