-- Captain accounts authenticate with their registered driver phone number.
-- The auth user UUID is deliberately kept separate from the operational driver
-- UUID and linked after a successful SMS OTP verification.

alter table public.drivers
  add column if not exists user_id uuid references auth.users(id) on delete set null;

create unique index if not exists uq_drivers_user_id
  on public.drivers (user_id)
  where user_id is not null;

create or replace function public.normalize_egyptian_phone(value text)
returns text
language sql
immutable
strict
set search_path = ''
as $$
  select case
    when regexp_replace(value, '[^0-9]', '', 'g') like '0020%'
      then substring(regexp_replace(value, '[^0-9]', '', 'g') from 3)
    when regexp_replace(value, '[^0-9]', '', 'g') like '01%'
      then '20' || substring(regexp_replace(value, '[^0-9]', '', 'g') from 2)
    else regexp_replace(value, '[^0-9]', '', 'g')
  end
$$;

create or replace function public.link_current_driver_account()
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  current_user_id uuid := auth.uid();
  authenticated_phone text := auth.jwt() ->> 'phone';
  matched_driver_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication is required';
  end if;

  if authenticated_phone is null or authenticated_phone = '' then
    raise exception 'The authenticated account has no phone number';
  end if;

  select d.id
    into matched_driver_id
    from public.drivers d
   where public.normalize_egyptian_phone(d.phone) =
         public.normalize_egyptian_phone(authenticated_phone)
     and d.status = 'active'
     and (d.user_id is null or d.user_id = current_user_id)
   order by d.created_at
   limit 1
   for update;

  if matched_driver_id is null then
    raise exception 'No active driver is registered with this phone number';
  end if;

  update public.drivers
     set user_id = current_user_id,
         updated_at = now()
   where id = matched_driver_id;

  return matched_driver_id;
end;
$$;

revoke all on function public.link_current_driver_account() from public;
grant execute on function public.link_current_driver_account() to authenticated;

