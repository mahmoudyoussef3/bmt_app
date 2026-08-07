-- ═══════════════════════════════════════════════════════════════════════════════════
-- get_dashboard_users — cast auth.users.email to text
--
-- The المستخدمون والصلاحيات screen failed on every load with:
--
--     PostgrestException(message: structure of query does not match function result
--     type, code: 42804, details: Returned type character varying(255) does not match
--     expected type text in column 5.)
--
-- Column 5 is `email`. The function (20260721090300_multi_office_rpcs.sql) declares it
-- `text`, but the value comes from `auth.users.email`, which GoTrue defines as
-- `character varying(255)`. plpgsql's `return query` demands an exact type match per
-- column and raises 42804 the moment a row is returned — so the screen broke as soon as
-- the office had a single operator, not at deploy time.
--
-- Every other column already lines up: `office_users` stores username / full_name /
-- role / status as `text`, and `created_at` as `timestamptz`. Only the join to
-- `auth.users` crosses a schema we do not own, so only that one needs the cast.
--
-- Nothing else about the function changes: same signature, same office scoping via
-- `current_office_id()`, same security definer + search_path, same grants (CREATE OR
-- REPLACE preserves them, so no re-grant is needed).
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.get_dashboard_users()
returns table(
  id         uuid,
  user_id    uuid,
  username   text,
  full_name  text,
  email      text,
  role       text,
  status     text,
  created_at timestamptz
)
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;

  return query
    select ou.id, ou.user_id, ou.username, ou.full_name, au.email::text,
           ou.role, ou.status, ou.created_at
      from public.office_users ou
      join auth.users au on au.id = ou.user_id
     where ou.office_id = v_office
     order by ou.created_at desc;
end;
$$;
