-- ═══════════════════════════════════════════════════════════════════════════════════
-- Fleet role authority regression suite
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Covers 20260815110000_fleet_role_authority, which split the five `for all` fleet
-- policies into an open read and a `dashboard_admin`-only write.
--
-- Impersonates every identity that can reach these tables and asserts, per table:
--
--   allowed reads    owner, second office admin, support agent, captain
--   denied reads     another office, a platform admin with no office, a disabled
--                    member, anon
--   allowed writes   owner — insert, update, delete on all five tables
--   denied writes    support agent, another office, captain, platform admin, disabled
--   isolation        no predicate lets an identity cross the office boundary, in
--                    either direction, including by rewriting office_id on the way out
--   preservation     licensing triggers, captain read paths and definer RPCs survive
--
-- On the roles being tested: the schema has exactly two office roles,
-- `dashboard_admin` and `support_agent` (office_users_role_check). "Office owner" and
-- "office admin" are the same role and are tested as two distinct accounts holding it;
-- an "operations user" cannot exist, and §1 proves the database refuses to store one
-- rather than leaving that as an assumption. A disabled member stands in for the
-- fourth shape of office identity — someone the office knows but has switched off.
--
-- Runs entirely inside BEGIN … ROLLBACK. It creates its own fleet rows and its own
-- office memberships and throws them all away; it never writes to a real driver,
-- vehicle, assignment or document, so it is safe against the production-bound
-- development database.
--
--   supabase db query --linked -f supabase/tests/fleet_role_authority_regression.sql
--
-- Every row of the output should read OK. Any row reading "BROKEN", "LEAK" or
-- "STILL EXPLOITABLE" is a regression.
-- ═══════════════════════════════════════════════════════════════════════════════════

begin;

create temp table probe(step text, result text) on commit drop;
create temp table fixture(k text primary key, v text) on commit drop;
grant all on probe to authenticated, anon;
grant all on fixture to authenticated, anon;


-- ───────────────────────────────────────────────────────────────────────────────────
-- 0. The cast, resolved as postgres before any impersonation starts.
--
-- Identities and fleet rows are read out of the linked database rather than
-- hardcoded. New rows are cloned from existing ones so that every NOT NULL column and
-- every check constraint — vehicles.capacity must equal the seat configuration's
-- passenger count, for one — is satisfied without this file having to know the shape
-- of the fleet schema.
-- ───────────────────────────────────────────────────────────────────────────────────
do $$
declare
  v_office     uuid;
  v_other      uuid;
  v_owner      uuid;
  v_admin2     uuid;
  v_support    uuid;
  v_disabled   uuid;
  v_platform   uuid;
  v_other_own  uuid;
  v_captain    uuid;
  v_drv        uuid;
  v_veh        uuid;
  v_asg        uuid;
  v_ddoc       uuid;
  v_vdoc       uuid;
  v_odrv       uuid;
  v_oveh       uuid;
  v_del_drv    uuid;
  v_del_veh    uuid;
  v_del_asg    uuid;
  v_del_ddoc   uuid;
  v_del_vdoc   uuid;
  i            int;
  v_spare      uuid[];
begin
  -- The office with the most drivers: the one where reads have something to return.
  select d.office_id into v_office
    from public.drivers d
   where exists (select 1 from public.vehicles v where v.office_id = d.office_id)
     and exists (select 1 from public.office_users u
                  where u.office_id = d.office_id and u.status = 'active'
                    and u.role = 'dashboard_admin')
   group by d.office_id
   order by count(*) desc
   limit 1;

  if v_office is null then
    insert into probe values ('00. fixture',
      'ABORTED — no office has drivers, vehicles and an active dashboard_admin');
    return;
  end if;

  select id into v_other from public.offices where id <> v_office limit 1;
  if v_other is null then
    insert into probe values ('00. fixture',
      'ABORTED — only one office exists, cross-office isolation cannot be tested');
    return;
  end if;

  select user_id into v_owner from public.office_users
   where office_id = v_office and status = 'active' and role = 'dashboard_admin'
   limit 1;

  -- Four accounts that belong to nothing yet, for the synthetic memberships.
  select array_agg(id) into v_spare from (
    select u.id from auth.users u
     where not exists (select 1 from public.office_users o where o.user_id = u.id)
       and not exists (select 1 from public.drivers d where d.user_id = u.id)
       and not exists (select 1 from public.platform_admins p where p.user_id = u.id)
     order by u.created_at
     limit 4) s;

  if coalesce(array_length(v_spare, 1), 0) < 4 then
    insert into probe values ('00. fixture',
      'ABORTED — fewer than 4 unattached auth users to cast as test identities');
    return;
  end if;

  v_admin2   := v_spare[1];
  v_support  := v_spare[2];
  v_disabled := v_spare[3];
  v_platform := v_spare[4];

  insert into public.office_users (user_id, office_id, role, status, username, full_name)
  values (v_admin2,   v_office, 'dashboard_admin', 'active',   'rlstest_admin2',
          'اختبار: مدير ثانٍ'),
         (v_support,  v_office, 'support_agent',   'active',   'rlstest_support',
          'اختبار: خدمة عملاء'),
         (v_disabled, v_office, 'dashboard_admin', 'disabled', 'rlstest_disabled',
          'اختبار: حساب موقوف');

  -- A platform admin who operates no office. The live platform admin also owns an
  -- office, which would mask the question this suite asks: whether the fleet policies
  -- carry a platform-admin OR-branch. They must not.
  insert into public.platform_admins (user_id) values (v_platform);

  -- An operator in the other office. Reuse a real one if there is one.
  select user_id into v_other_own from public.office_users
   where office_id = v_other and status = 'active' limit 1;

  -- A captain of the primary office: their own driver row is their read key.
  select user_id into v_captain from public.drivers
   where office_id = v_office and user_id is not null and status = 'active' limit 1;

  -- ── The fleet rows the suite acts on ────────────────────────────────────────────
  insert into public.drivers
         (employee_code, full_name, phone, emergency_phone, address,
          national_id, license_number, license_expiry_date, hire_date,
          status, office_id)
  select 'RLSTEST-' || substr(gen_random_uuid()::text, 1, 8), 'اختبار صلاحيات الأسطول', src.phone, src.emergency_phone,
         src.address,
         'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
         'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
         current_date + 400, current_date - 30, 'active', v_office
    from public.drivers src where src.office_id = v_office limit 1
  returning id into v_drv;

  insert into public.vehicles
         (vehicle_code, plate_number, vehicle_type, brand, model, manufacture_year,
          color, capacity, seat_layout_type, seat_configuration, status, office_id)
  select 'RLSTEST-' || substr(gen_random_uuid()::text, 1, 6),
         'RLSTEST-' || substr(gen_random_uuid()::text, 1, 8),
         src.vehicle_type, src.brand, src.model, src.manufacture_year, src.color,
         src.capacity, src.seat_layout_type, src.seat_configuration, 'active', v_office
    from public.vehicles src where src.office_id = v_office limit 1
  returning id into v_veh;

  insert into public.assignments (driver_id, vehicle_id, office_id, status)
  values (v_drv, v_veh, v_office, 'active')
  returning id into v_asg;

  insert into public.driver_documents (driver_id, type, file_url, expiry_date, status)
  values (v_drv, 'license', 'rlstest://driver-doc', current_date + 200, 'valid')
  returning id into v_ddoc;

  insert into public.vehicle_documents (vehicle_id, type, file_url, expiry_date, status)
  values (v_veh, 'license', 'rlstest://vehicle-doc', current_date + 200, 'valid')
  returning id into v_vdoc;

  -- The same shapes in the other office, so isolation is tested against rows that
  -- certainly exist rather than against whatever that office happens to hold.
  insert into public.drivers
         (employee_code, full_name, phone, emergency_phone, address,
          national_id, license_number, license_expiry_date, hire_date,
          status, office_id)
  select 'RLSTEST-' || substr(gen_random_uuid()::text, 1, 8), 'اختبار: سائق مكتب آخر', src.phone, src.emergency_phone,
         src.address,
         'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
         'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
         current_date + 400, current_date - 30, 'active', v_other
    from public.drivers src where src.office_id = v_office limit 1
  returning id into v_odrv;

  insert into public.vehicles
         (vehicle_code, plate_number, vehicle_type, brand, model, manufacture_year,
          color, capacity, seat_layout_type, seat_configuration, status, office_id)
  select 'RLSTEST-' || substr(gen_random_uuid()::text, 1, 6),
         'RLSTEST-' || substr(gen_random_uuid()::text, 1, 8),
         src.vehicle_type, src.brand, src.model, src.manufacture_year, src.color,
         src.capacity, src.seat_layout_type, src.seat_configuration, 'active', v_other
    from public.vehicles src where src.office_id = v_office limit 1
  returning id into v_oveh;

  -- ── Disposable delete targets ───────────────────────────────────────────────────
  -- Every DELETE probe gets a row of its own. Sharing one would make the suite
  -- order-dependent the moment a policy actually leaks: the first identity through
  -- would remove the row and every identity after it would read as denied because
  -- there was nothing left to delete. These also have no dependents, so a delete that
  -- gets past RLS is stopped by RLS or not at all — never by a foreign key, which
  -- would otherwise disguise an exploit as an error.
  insert into public.drivers
         (employee_code, full_name, phone, emergency_phone, address,
          national_id, license_number, license_expiry_date, hire_date,
          status, office_id)
  select 'RLSTEST-' || substr(gen_random_uuid()::text, 1, 8), 'اختبار: هدف حذف',
         src.phone, src.emergency_phone, src.address,
         'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
         'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
         current_date + 400, current_date - 30, 'active', v_office
    from public.drivers src where src.office_id = v_office limit 1
  returning id into v_del_drv;

  insert into public.vehicles
         (vehicle_code, plate_number, vehicle_type, brand, model, manufacture_year,
          color, capacity, seat_layout_type, seat_configuration, status, office_id)
  select 'RLSTEST-' || substr(gen_random_uuid()::text, 1, 6),
         'RLSTEST-' || substr(gen_random_uuid()::text, 1, 8),
         src.vehicle_type, src.brand, src.model, src.manufacture_year, src.color,
         src.capacity, src.seat_layout_type, src.seat_configuration, 'active', v_office
    from public.vehicles src where src.office_id = v_office limit 1
  returning id into v_del_veh;

  insert into public.driver_documents (driver_id, type, file_url, expiry_date, status)
  values (v_drv, 'national_id', 'rlstest://ddoc-target', current_date + 90, 'valid')
  returning id into v_del_ddoc;

  insert into public.vehicle_documents (vehicle_id, type, file_url, expiry_date, status)
  values (v_veh, 'insurance', 'rlstest://vdoc-target', current_date + 90, 'valid')
  returning id into v_del_vdoc;

  -- Five spare assignments — one for the support agent and one for each identity in
  -- §6. `ended` rather than `active`, because uniq_active_assignment_per_driver
  -- allows only one live pairing per driver.
  for i in 1..5 loop
    insert into public.assignments (driver_id, vehicle_id, office_id, status)
    values (v_drv, v_veh, v_office, 'ended')
    returning id into v_del_asg;
    insert into fixture values ('del_asg_' || i, v_del_asg::text);
  end loop;

  insert into fixture values
    ('office', v_office::text),      ('other_office', v_other::text),
    ('owner', v_owner::text),        ('admin2', v_admin2::text),
    ('support', v_support::text),    ('disabled', v_disabled::text),
    ('platform', v_platform::text),  ('captain', coalesce(v_captain::text, '')),
    ('other_owner', coalesce(v_other_own::text, '')),
    ('drv', v_drv::text),            ('veh', v_veh::text),
    ('asg', v_asg::text),            ('ddoc', v_ddoc::text),
    ('vdoc', v_vdoc::text),
    ('other_drv', v_odrv::text),     ('other_veh', v_oveh::text),
    ('del_drv', v_del_drv::text),    ('del_veh', v_del_veh::text),
    ('del_ddoc', v_del_ddoc::text),  ('del_vdoc', v_del_vdoc::text);

  insert into probe values ('00. fixture',
    'OK — office ' || left(v_office::text, 8) || ', other ' || left(v_other::text, 8)
    || ', captain ' || case when v_captain is null then 'absent' else 'present' end
    || ', other-office operator '
    || case when v_other_own is null then 'absent' else 'present' end);
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. The role model itself
--
-- Every predicate below leans on `office_role()` returning one of two values. If a
-- third could be stored, a row holding it would satisfy no write policy and silently
-- lose access — or, worse, a future migration would add a branch for it.
-- ═══════════════════════════════════════════════════════════════════════════════════
insert into probe
select '01. exactly two office roles',
       case when def = 'CHECK ((role = ANY (ARRAY[''dashboard_admin''::text, '
                       '''support_agent''::text])))'
            then 'OK — dashboard_admin, support_agent'
            else 'BROKEN — ' || def end
  from (select pg_get_constraintdef(oid) as def from pg_constraint
         where conrelid = 'public.office_users'::regclass
           and conname = 'office_users_role_check') c;

do $$
declare v_uid uuid := (select v::uuid from fixture where k = 'platform');
begin
  if v_uid is null then return; end if;
  begin
    insert into public.office_users (user_id, office_id, role, status, username)
    values (v_uid, (select v::uuid from fixture where k = 'office'),
            'operations', 'active', 'rlstest_ops');
    insert into probe values ('02. a fabricated "operations" role',
      'BROKEN — the database stored a role no policy grants');
  exception when check_violation then
    insert into probe values ('02. a fabricated "operations" role',
      'OK — refused by office_users_role_check');
  end;
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. Allowed reads. Nothing here may change: four support-agent surfaces embed driver
--    and vehicle rows through PostgREST, and Home reads all five tables for every
--    role. A read regression here is a blank live-ops board.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  r        record;
  v_drv    uuid := (select v::uuid from fixture where k = 'drv');
  v_veh    uuid := (select v::uuid from fixture where k = 'veh');
  v_asg    uuid := (select v::uuid from fixture where k = 'asg');
  v_ddoc   uuid := (select v::uuid from fixture where k = 'ddoc');
  v_vdoc   uuid := (select v::uuid from fixture where k = 'vdoc');
  n_drv    bigint; n_veh bigint; n_asg bigint; n_dd bigint; n_vd bigint;
begin
  if v_drv is null then return; end if;

  for r in
    select * from (values
      ('03', 'owner',                 'owner'),
      ('04', 'second office admin',   'admin2'),
      ('05', 'support agent',         'support')
    ) as t(num, label, key)
  loop
    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims',
      json_build_object('sub', (select v from fixture where k = r.key),
                        'role', 'authenticated')::text, true);

    select count(*) into n_drv from public.drivers           where id = v_drv;
    select count(*) into n_veh from public.vehicles          where id = v_veh;
    select count(*) into n_asg from public.assignments       where id = v_asg;
    select count(*) into n_dd  from public.driver_documents  where id = v_ddoc;
    select count(*) into n_vd  from public.vehicle_documents where id = v_vdoc;

    perform set_config('role', 'postgres', true);

    insert into probe values (r.num || '. ' || r.label || ' reads the fleet',
      case when n_drv = 1 and n_veh = 1 and n_asg = 1 and n_dd = 1 and n_vd = 1
           then 'OK — driver, vehicle, assignment, both documents'
           else 'BROKEN — drivers ' || n_drv || ', vehicles ' || n_veh
                || ', assignments ' || n_asg || ', driver_docs ' || n_dd
                || ', vehicle_docs ' || n_vd end);
  end loop;
end $$;

reset role;

-- The support agent's four real surfaces, read the way PostgREST reads them: the
-- columns live ops and the bookings queue actually embed.
do $$
declare
  v_sup  uuid := (select v::uuid from fixture where k = 'support');
  v_off  uuid := (select v::uuid from fixture where k = 'office');
  n_name bigint; n_plate bigint;
begin
  if v_sup is null then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_sup, 'role', 'authenticated')::text, true);

  select count(*) into n_name  from public.drivers  where office_id = v_off;
  select count(*) into n_plate from public.vehicles where office_id = v_off;

  perform set_config('role', 'postgres', true);

  insert into probe values ('06. support agent keeps live ops / bookings / reports',
    case when n_name > 0 and n_plate > 0
         then 'OK — ' || n_name || ' drivers, ' || n_plate || ' vehicles visible'
         else 'BROKEN — support agent sees ' || n_name || ' drivers, '
              || n_plate || ' vehicles; live ops and the bookings queue go blank' end);
end $$;

reset role;

-- The captain app's only two non-definer reads of the fleet.
do $$
declare
  v_cap  uuid := (select nullif(v, '')::uuid from fixture where k = 'captain');
  v_off  uuid := (select v::uuid from fixture where k = 'office');
  v_drv  uuid := (select v::uuid from fixture where k = 'drv');
  n_self bigint; n_veh bigint; n_other bigint;
begin
  if v_cap is null then
    insert into probe values ('07. captain reads own row and office vehicles',
      'SKIPPED — no captain is linked to a driver row in this office');
    return;
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_cap, 'role', 'authenticated')::text, true);

  select count(*) into n_self  from public.drivers  where user_id = v_cap;
  select count(*) into n_veh   from public.vehicles where office_id = v_off;
  select count(*) into n_other from public.drivers  where id = v_drv;

  perform set_config('role', 'postgres', true);

  insert into probe values ('07. captain reads own row and office vehicles',
    case when n_self = 1 and n_veh > 0
         then 'OK — own driver row + ' || n_veh || ' office vehicles'
         else 'BROKEN — own row ' || n_self || ', vehicles ' || n_veh end);

  -- drivers_self_read is keyed on user_id, not office. A captain is not an office
  -- user, so no colleague's national ID is reachable.
  insert into probe values ('08. captain cannot read a colleague''s driver row',
    case when n_other = 0 then 'OK — filtered'
         else 'LEAK — a captain read another driver''s record' end);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. Denied reads and cross-office isolation.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  r      record;
  v_drv  uuid := (select v::uuid from fixture where k = 'drv');
  v_veh  uuid := (select v::uuid from fixture where k = 'veh');
  v_asg  uuid := (select v::uuid from fixture where k = 'asg');
  v_ddoc uuid := (select v::uuid from fixture where k = 'ddoc');
  v_vdoc uuid := (select v::uuid from fixture where k = 'vdoc');
  v_uid  text;
  n      bigint;
begin
  if v_drv is null then return; end if;

  for r in
    select * from (values
      ('09', 'another office''s operator', 'other_owner'),
      ('10', 'a platform admin with no office', 'platform'),
      ('11', 'a disabled office member', 'disabled')
    ) as t(num, label, key)
  loop
    v_uid := (select nullif(v, '') from fixture where k = r.key);
    if v_uid is null then
      insert into probe values (r.num || '. ' || r.label || ' reads nothing',
        'SKIPPED — no such identity available');
      continue;
    end if;

    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);

    select (select count(*) from public.drivers           where id = v_drv)
         + (select count(*) from public.vehicles          where id = v_veh)
         + (select count(*) from public.assignments       where id = v_asg)
         + (select count(*) from public.driver_documents  where id = v_ddoc)
         + (select count(*) from public.vehicle_documents where id = v_vdoc)
      into n;

    perform set_config('role', 'postgres', true);

    insert into probe values (r.num || '. ' || r.label || ' reads nothing',
      case when n = 0 then 'OK — every table filtered'
           else 'LEAK — ' || n || ' of 5 fleet rows readable' end);
  end loop;
end $$;

reset role;

do $$
declare n bigint;
begin
  begin
    set local role anon;
    select (select count(*) from public.drivers)
         + (select count(*) from public.vehicles)
         + (select count(*) from public.assignments)
         + (select count(*) from public.driver_documents)
         + (select count(*) from public.vehicle_documents)
      into n;
    reset role;
    insert into probe values ('12. anon reads nothing',
      case when n = 0 then 'OK — RLS filtered'
           else 'STILL EXPLOITABLE — ' || n || ' fleet rows readable with the anon key'
      end);
  exception when insufficient_privilege then
    reset role;
    insert into probe values ('12. anon reads nothing', 'OK — grant revoked');
  end;
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. Allowed writes. The owner must keep the fleet module, the trip planner and
--    captain-request approval working end to end.
--
--    `status` is deliberately not the column under test on drivers and vehicles:
--    trg_end_assignments_on_*_status closes assignments as a side effect, which would
--    make the assignment probes below depend on the order of this block.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  v_own   uuid := (select v::uuid from fixture where k = 'owner');
  v_off   uuid := (select v::uuid from fixture where k = 'office');
  v_drv   uuid := (select v::uuid from fixture where k = 'drv');
  v_veh   uuid := (select v::uuid from fixture where k = 'veh');
  v_asg   uuid := (select v::uuid from fixture where k = 'asg');
  v_ddoc  uuid := (select v::uuid from fixture where k = 'ddoc');
  v_vdoc  uuid := (select v::uuid from fixture where k = 'vdoc');
  v_new   uuid;
  n_d int; n_v int; n_a int; n_dd int; n_vd int;
begin
  if v_own is null then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_own, 'role', 'authenticated')::text, true);

  update public.drivers           set notes = 'rlstest' where id = v_drv;
  get diagnostics n_d = row_count;
  update public.vehicles          set notes = 'rlstest' where id = v_veh;
  get diagnostics n_v = row_count;
  update public.assignments       set status = 'active' where id = v_asg;
  get diagnostics n_a = row_count;
  update public.driver_documents  set status = 'valid'  where id = v_ddoc;
  get diagnostics n_dd = row_count;
  update public.vehicle_documents set status = 'valid'  where id = v_vdoc;
  get diagnostics n_vd = row_count;

  insert into probe values ('13. owner updates all five tables',
    case when n_d = 1 and n_v = 1 and n_a = 1 and n_dd = 1 and n_vd = 1
         then 'OK — drivers, vehicles, assignments, both document tables'
         else 'BROKEN — ' || n_d || n_v || n_a || n_dd || n_vd
              || ' (expected 11111) — the fleet module is locked out' end);

  insert into public.drivers
         (employee_code, full_name, phone, emergency_phone, address, national_id,
          license_number, license_expiry_date, hire_date, status, office_id)
  values ('RLSTEST-' || substr(gen_random_uuid()::text, 1, 8), 'اختبار: إضافة سائق', '01000000000', '01000000001', '-',
          'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
          'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
          current_date + 400, current_date, 'active', v_off)
  returning id into v_new;

  insert into probe values ('14. owner adds a driver',
    case when v_new is not null then 'OK — inserted'
         else 'BROKEN — insert returned nothing' end);

  insert into public.driver_documents (driver_id, type, file_url, expiry_date, status)
  values (v_new, 'national_id', 'rlstest://new', current_date + 100, 'valid');

  insert into probe values ('15. owner attaches a document',
    'OK — inserted against their own office''s driver');

  delete from public.driver_documents where driver_id = v_new;
  get diagnostics n_dd = row_count;
  delete from public.drivers where id = v_new;
  get diagnostics n_d = row_count;

  insert into probe values ('16. owner deletes what they created',
    case when n_dd = 1 and n_d = 1 then 'OK — document and driver removed'
         else 'BROKEN — documents ' || n_dd || ', drivers ' || n_d end);

  perform set_config('role', 'postgres', true);
end $$;

reset role;

-- The `with check` half of the update policies: an owner may edit their own driver,
-- but not walk them across the office boundary on the way out.
do $$
declare
  v_own   uuid := (select v::uuid from fixture where k = 'owner');
  v_other uuid := (select v::uuid from fixture where k = 'other_office');
  v_drv   uuid := (select v::uuid from fixture where k = 'drv');
  v_odrv  uuid := (select v::uuid from fixture where k = 'other_drv');
  v_ddoc  uuid := (select v::uuid from fixture where k = 'ddoc');
begin
  if v_own is null then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_own, 'role', 'authenticated')::text, true);

  begin
    update public.drivers set office_id = v_other where id = v_drv;
    insert into probe values ('17. owner exports a driver to another office',
      'STILL EXPLOITABLE — office_id was rewritten');
  exception when insufficient_privilege then
    insert into probe values ('17. owner exports a driver to another office',
      'OK — refused by with check');
  end;

  begin
    update public.driver_documents set driver_id = v_odrv where id = v_ddoc;
    insert into probe values ('18. owner re-points a document at another office',
      'STILL EXPLOITABLE — a licence scan was attached across the boundary');
  exception when insufficient_privilege then
    insert into probe values ('18. owner re-points a document at another office',
      'OK — refused by with check');
  end;

  perform set_config('role', 'postgres', true);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. Denied writes — the support agent. This is the finding.
--
--    A refused UPDATE or DELETE is not an error: the USING clause filters the row out
--    before anything runs, so the statement succeeds and touches nothing. Row counts
--    are therefore the assertion, and a count of 1 here is the exploit.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  r       record;
  v_sup   uuid := (select v::uuid from fixture where k = 'support');
  v_off   uuid := (select v::uuid from fixture where k = 'office');
  n_upd   int;
  n_del   int;
  v_ins   text;
begin
  if v_sup is null then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_sup, 'role', 'authenticated')::text, true);

  -- ── drivers ──────────────────────────────────────────────────────────────────
  update public.drivers set phone = '00000000000', notes = 'support tampered'
   where id = (select v::uuid from fixture where k = 'drv');
  get diagnostics n_upd = row_count;
  delete from public.drivers where id = (select v::uuid from fixture where k = 'del_drv');
  get diagnostics n_del = row_count;
  begin
    insert into public.drivers
           (employee_code, full_name, phone, emergency_phone, address, national_id,
            license_number, license_expiry_date, hire_date, status, office_id)
    values ('RLSTEST-' || substr(gen_random_uuid()::text, 1, 8), 'اختبار: سائق من خدمة العملاء', '0100', '0100', '-',
            'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
            'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
            current_date + 400, current_date, 'active', v_off);
    v_ins := 'accepted';
  exception when insufficient_privilege then v_ins := 'refused';
            when others then v_ins := 'errored (' || sqlerrm || ')';
  end;
  insert into probe values ('19. support agent writes drivers',
    case when n_upd = 0 and n_del = 0 and v_ins = 'refused'
         then 'OK — update 0, delete 0, insert refused'
         else 'STILL EXPLOITABLE — update ' || n_upd || ', delete ' || n_del
              || ', insert ' || v_ins end);

  -- ── vehicles ─────────────────────────────────────────────────────────────────
  update public.vehicles set notes = 'support tampered'
   where id = (select v::uuid from fixture where k = 'veh');
  get diagnostics n_upd = row_count;
  delete from public.vehicles where id = (select v::uuid from fixture where k = 'del_veh');
  get diagnostics n_del = row_count;
  begin
    insert into public.vehicles
           (vehicle_code, plate_number, vehicle_type, brand, model, manufacture_year,
            color, capacity, seat_layout_type, seat_configuration, status, office_id)
    select 'RLSTEST-' || substr(gen_random_uuid()::text, 1, 6),
           'RLSTEST-' || substr(gen_random_uuid()::text, 1, 8),
           src.vehicle_type, src.brand, src.model, src.manufacture_year, src.color,
           src.capacity, src.seat_layout_type, src.seat_configuration, 'active', v_off
      from public.vehicles src where src.id = (select v::uuid from fixture where k = 'veh');
    v_ins := 'accepted';
  exception when insufficient_privilege then v_ins := 'refused';
            when others then v_ins := 'errored (' || sqlerrm || ')';
  end;
  insert into probe values ('20. support agent writes vehicles',
    case when n_upd = 0 and n_del = 0 and v_ins = 'refused'
         then 'OK — update 0, delete 0, insert refused'
         else 'STILL EXPLOITABLE — update ' || n_upd || ', delete ' || n_del
              || ', insert ' || v_ins end);

  -- ── assignments ──────────────────────────────────────────────────────────────
  update public.assignments set status = 'ended'
   where id = (select v::uuid from fixture where k = 'asg');
  get diagnostics n_upd = row_count;
  delete from public.assignments
   where id = (select v::uuid from fixture where k = 'del_asg_1');
  get diagnostics n_del = row_count;
  begin
    insert into public.assignments (driver_id, vehicle_id, office_id, status)
    values ((select v::uuid from fixture where k = 'drv'),
            (select v::uuid from fixture where k = 'veh'), v_off, 'ended');
    v_ins := 'accepted';
  exception when insufficient_privilege then v_ins := 'refused';
            when others then v_ins := 'errored (' || sqlerrm || ')';
  end;
  insert into probe values ('21. support agent writes assignments',
    case when n_upd = 0 and n_del = 0 and v_ins = 'refused'
         then 'OK — update 0, delete 0, insert refused'
         else 'STILL EXPLOITABLE — update ' || n_upd || ', delete ' || n_del
              || ', insert ' || v_ins end);

  -- ── driver_documents and vehicle_documents ───────────────────────────────────
  update public.driver_documents set file_url = 'rlstest://tampered'
   where id = (select v::uuid from fixture where k = 'ddoc');
  get diagnostics n_upd = row_count;
  delete from public.driver_documents
   where id = (select v::uuid from fixture where k = 'del_ddoc');
  get diagnostics n_del = row_count;
  begin
    insert into public.driver_documents (driver_id, type, file_url, expiry_date, status)
    values ((select v::uuid from fixture where k = 'drv'), 'license',
            'rlstest://support', current_date + 30, 'valid');
    v_ins := 'accepted';
  exception when insufficient_privilege then v_ins := 'refused';
            when others then v_ins := 'errored (' || sqlerrm || ')';
  end;
  insert into probe values ('22. support agent writes driver documents',
    case when n_upd = 0 and n_del = 0 and v_ins = 'refused'
         then 'OK — update 0, delete 0, insert refused'
         else 'STILL EXPLOITABLE — update ' || n_upd || ', delete ' || n_del
              || ', insert ' || v_ins end);

  update public.vehicle_documents set file_url = 'rlstest://tampered'
   where id = (select v::uuid from fixture where k = 'vdoc');
  get diagnostics n_upd = row_count;
  delete from public.vehicle_documents
   where id = (select v::uuid from fixture where k = 'del_vdoc');
  get diagnostics n_del = row_count;
  begin
    insert into public.vehicle_documents (vehicle_id, type, file_url, expiry_date, status)
    values ((select v::uuid from fixture where k = 'veh'), 'license',
            'rlstest://support', current_date + 30, 'valid');
    v_ins := 'accepted';
  exception when insufficient_privilege then v_ins := 'refused';
            when others then v_ins := 'errored (' || sqlerrm || ')';
  end;
  insert into probe values ('23. support agent writes vehicle documents',
    case when n_upd = 0 and n_del = 0 and v_ins = 'refused'
         then 'OK — update 0, delete 0, insert refused'
         else 'STILL EXPLOITABLE — update ' || n_upd || ', delete ' || n_del
              || ', insert ' || v_ins end);

  perform set_config('role', 'postgres', true);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Denied writes — everyone else who can hold a session.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  r     record;
  v_uid text;
  v_off uuid := (select v::uuid from fixture where k = 'office');
  n_upd int; n_del int; v_ins text;
begin
  for r in
    select * from (values
      ('24', 'another office''s owner',        'other_owner', 2),
      ('25', 'a platform admin with no office','platform',    3),
      ('26', 'a disabled office member',       'disabled',     4),
      ('27', 'a captain',                      'captain',      5)
    ) as t(num, label, key, slot)
  loop
    v_uid := (select nullif(v, '') from fixture where k = r.key);
    if v_uid is null then
      insert into probe values (r.num || '. ' || r.label || ' cannot write the fleet',
        'SKIPPED — no such identity available');
      continue;
    end if;

    perform set_config('role', 'authenticated', true);
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);

    update public.drivers set notes = 'tampered'
     where id = (select v::uuid from fixture where k = 'drv');
    get diagnostics n_upd = row_count;
    delete from public.assignments
     where id = (select v::uuid from fixture where k = 'del_asg_' || r.slot);
    get diagnostics n_del = row_count;
    begin
      insert into public.drivers
             (employee_code, full_name, phone, emergency_phone, address, national_id,
              license_number, license_expiry_date, hire_date, status, office_id)
      values ('RLSTEST-' || substr(gen_random_uuid()::text, 1, 8), 'اختبار: دخيل', '0100', '0100', '-',
              'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
              'RLSTEST-' || substr(gen_random_uuid()::text, 1, 12),
              current_date + 400, current_date, 'active', v_off);
      v_ins := 'accepted';
    exception when insufficient_privilege then v_ins := 'refused';
              when others then v_ins := 'errored (' || sqlerrm || ')';
    end;

    perform set_config('role', 'postgres', true);

    insert into probe values (r.num || '. ' || r.label || ' cannot write the fleet',
      case when n_upd = 0 and n_del = 0 and v_ins = 'refused'
           then 'OK — update 0, delete 0, insert refused'
           else 'STILL EXPLOITABLE — update ' || n_upd || ', delete ' || n_del
                || ', insert ' || v_ins end);
  end loop;
end $$;

reset role;

-- A captain writing their *own* driver row. drivers_self_read is SELECT-only and
-- must stay that way: a captain editing their own licence expiry would walk straight
-- past the office's document review.
do $$
declare
  v_cap uuid := (select nullif(v, '')::uuid from fixture where k = 'captain');
  n int;
begin
  if v_cap is null then
    insert into probe values ('28. captain cannot edit their own driver row',
      'SKIPPED — no captain linked');
    return;
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_cap, 'role', 'authenticated')::text, true);

  update public.drivers set license_expiry_date = current_date + 3650
   where user_id = v_cap;
  get diagnostics n = row_count;

  perform set_config('role', 'postgres', true);

  insert into probe values ('28. captain cannot edit their own driver row',
    case when n = 0 then 'OK — read-only, as before'
         else 'STILL EXPLOITABLE — a captain extended their own licence' end);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 7. What must not have changed.
-- ═══════════════════════════════════════════════════════════════════════════════════

-- No `for all` may survive on a fleet table — the bug class this migration exists to
-- retire, and the one DASHBOARD_SECURITY.md §8 says has got in twice already.
insert into probe
select '29. no FOR ALL policy on the fleet',
       case when count(*) = 0 then 'OK — read and write are separate everywhere'
            else 'BROKEN — ' || string_agg(tablename || '.' || policyname, ', ') end
  from pg_policies
 where schemaname = 'public' and cmd = 'ALL'
   and tablename in ('drivers','vehicles','assignments',
                     'driver_documents','vehicle_documents');

-- Every write policy names the role. A policy that forgot it fails open silently.
insert into probe
select '30. every fleet write policy is role-gated',
       case when count(*) = 15
            then 'OK — 15 write policies (5 tables × insert/update/delete), '
                 || 'all naming office_role()'
            else 'BROKEN — only ' || count(*)
                 || ' of 15 write policies carry the role term' end
  from pg_policies
 where schemaname = 'public' and cmd in ('INSERT','UPDATE','DELETE')
   and tablename in ('drivers','vehicles','assignments',
                     'driver_documents','vehicle_documents')
   and coalesce(qual,'') || coalesce(with_check,'') like '%office_role%';

-- Office isolation is still expressed on every single policy, read and write alike.
insert into probe
select '31. every fleet policy is office-scoped',
       case when count(*) = 0 then 'OK — no policy omits the office predicate'
            else 'BROKEN — ' || string_agg(tablename || '.' || policyname, ', ') end
  from pg_policies
 where schemaname = 'public'
   and tablename in ('drivers','vehicles','assignments',
                     'driver_documents','vehicle_documents')
   and policyname not in ('drivers_self_read', 'vehicles_captain_read')
   and coalesce(qual,'') || coalesce(with_check,'') not like '%current_office_id%';

-- The captain's two read paths.
insert into probe
select '32. captain read policies survive',
       case when count(*) = 2 then 'OK — drivers_self_read + vehicles_captain_read'
            else 'BROKEN — ' || count(*) || ' of 2 present' end
  from pg_policies
 where schemaname = 'public' and cmd = 'SELECT'
   and policyname in ('drivers_self_read','vehicles_captain_read');

-- Licensing is a trigger, not a policy, and this migration must not have disturbed it.
insert into probe
select '33. licensing gates still armed',
       case when count(*) = 8
            then 'OK — 3 read-only gates + 5 quota meters'
            else 'BROKEN — ' || count(*) || ' of 8 fleet licensing triggers present' end
  from pg_trigger
 where not tgisinternal
   and tgrelid in ('public.drivers'::regclass, 'public.vehicles'::regclass,
                   'public.assignments'::regclass)
   and tgname in ('trg_readonly_drivers','trg_readonly_vehicles',
                  'trg_readonly_assignments','trg_quota_drivers','trg_quota_vehicles',
                  'trg_quota_captains','trg_quota_driver_reactivate',
                  'trg_quota_driver_transfer');

-- Fleet integrity triggers.
insert into probe
select '34. fleet integrity triggers still armed',
       case when count(*) = 5 then 'OK — assignment integrity, delete guards, status cascade'
            else 'BROKEN — ' || count(*) || ' of 5 present' end
  from pg_trigger
 where not tgisinternal
   and tgname in ('trg_enforce_assignment_integrity','trg_enforce_driver_delete_guard',
                  'trg_enforce_vehicle_delete_guard','trg_end_assignments_on_driver_status',
                  'trg_end_assignments_on_vehicle_status');

-- A definer RPC reads the fleet regardless of who calls it. If RLS had leaked into
-- these paths, the trip planner's seat derivation would break for half the console.
do $$
declare
  v_sup uuid := (select v::uuid from fixture where k = 'support');
  v_veh uuid := (select v::uuid from fixture where k = 'veh');
  n int;
begin
  if v_sup is null then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_sup, 'role', 'authenticated')::text, true);

  select count(*) into n from public.vehicle_trip_seats(v_veh);

  perform set_config('role', 'postgres', true);

  insert into probe values ('35. definer RPCs unaffected by the split',
    case when n > 0 then 'OK — vehicle_trip_seats returned ' || n || ' seats'
         else 'BROKEN — a definer read of vehicles came back empty' end);
exception when others then
  perform set_config('role', 'postgres', true);
  insert into probe values ('35. definer RPCs unaffected by the split',
    'BROKEN — ' || sqlerrm);
end $$;

reset role;

-- The read gap this migration knowingly leaves open, asserted rather than assumed, so
-- it shows up on every run until the sanitised view lands.
do $$
declare
  v_sup uuid := (select v::uuid from fixture where k = 'support');
  n int;
begin
  if v_sup is null then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_sup, 'role', 'authenticated')::text, true);

  select count(*) into n from public.drivers
   where id = (select v::uuid from fixture where k = 'drv') and national_id is not null;

  perform set_config('role', 'postgres', true);

  insert into probe values ('36. KNOWN GAP — support agent still reads driver PII',
    case when n > 0
         then 'EXPECTED — national_id readable; needs the column split '
              || '(DASHBOARD_SECURITY.md §3 follow-up)'
         else 'CHANGED — reads are now restricted; update the docs and this probe' end);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
select step, result from probe order by step;

rollback;
