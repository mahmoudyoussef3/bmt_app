-- ═══════════════════════════════════════════════════════════════════════════════════
-- The join code, with the one fact the console could never read: when it last changed
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- `office_join_code()` returns the code and nothing else, and both `join_code` and
-- `join_code_rotated_at` sit behind the column-privilege revoke of migration
-- 20260721100200 — naming either in a select fails the whole statement. So the office
-- profile screen could show its captain join code but never say how old it is, which is
-- exactly the question an operator asks before deciding to rotate one.
--
-- This adds a second reader beside the existing one rather than changing it: same
-- office resolution (`current_office_id()`, no parameter to point at someone else's
-- office), same definer boundary, same grant. `office_join_code()` keeps its callers.
create or replace function public.office_join_code_info()
returns jsonb
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

  return (
    select jsonb_build_object(
             'code', o.join_code,
             'rotated_at', o.join_code_rotated_at
           )
      from public.offices o
     where o.id = v_office
  );
end;
$$;

revoke all on function public.office_join_code_info() from public, anon, authenticated;
grant execute on function public.office_join_code_info() to authenticated;

comment on function public.office_join_code_info() is
  'The caller office''s captain join code and its last rotation time. Definer-scoped '
  'to current_office_id(); the columns themselves stay unreadable to authenticated.';
