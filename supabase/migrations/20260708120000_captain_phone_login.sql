-- Captain app: passwordless, phone-only sign in.
--
-- Replaces the abandoned SMS-OTP design (link_current_driver_account, which
-- read the phone from `auth.jwt() ->> 'phone'` — a claim only a real phone/OTP
-- session carries, and this app never produces one). No driver has ever had
-- user_id set as a result.
--
-- New model: the captain types only their phone number. resolve_captain_login
-- (anon-callable) checks it against active drivers and, if it matches, hands
-- back a stable email + secret derived from the phone. The app signs in with
-- that pair (or signs up, the first time — Supabase auth is already
-- configured to auto-confirm email signups on this project), then calls
-- link_current_captain_driver to bind the resulting auth.uid() to the driver
-- row. Same phone always derives the same credentials, so this is stable
-- across reinstalls without needing anonymous auth (disabled on this
-- project) or a service-role edge function.
--
-- Trade-off (explicitly requested): there is no proof-of-possession of the
-- phone number (no OTP), matching the existing no-SMS onboarding model. Any
-- caller who can call resolve_captain_login for a given phone can obtain
-- credentials for that driver — accepted for this operational fleet app,
-- same trust model as the existing self-service onboarding.

drop function if exists public.link_current_driver_account();

create or replace function public.resolve_captain_login(p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_phone_norm text := public.normalize_egyptian_phone(coalesce(p_phone, ''));
  v_driver public.drivers;
begin
  if length(v_phone_norm) < 10 then
    raise exception 'رقم الهاتف غير صالح' using errcode = '22023';
  end if;

  select * into v_driver
  from public.drivers d
  where public.normalize_egyptian_phone(d.phone) = v_phone_norm
    and d.status = 'active'
  order by d.created_at
  limit 1;

  if not found then
    return jsonb_build_object('outcome', 'not_registered');
  end if;

  return jsonb_build_object(
    'outcome', 'ready',
    'login_email', v_phone_norm || '@captain.bmt-app.internal',
    'login_secret', encode(hmac(v_phone_norm, 'bmt-captain-login-v1', 'sha256'), 'hex'),
    'full_name', v_driver.full_name,
    'employee_code', v_driver.employee_code
  );
end;
$$;

create or replace function public.link_current_captain_driver(p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_phone_norm text := public.normalize_egyptian_phone(coalesce(p_phone, ''));
  v_driver public.drivers;
begin
  if v_uid is null then
    raise exception 'Authentication is required';
  end if;

  select * into v_driver
  from public.drivers d
  where public.normalize_egyptian_phone(d.phone) = v_phone_norm
    and d.status = 'active'
  order by d.created_at
  limit 1;

  if not found then
    raise exception 'رقم الهاتف غير مسجل كسائق نشط';
  end if;

  update public.drivers
     set user_id = v_uid,
         updated_at = now()
   where id = v_driver.id;

  return jsonb_build_object(
    'driver_id', v_driver.id,
    'full_name', v_driver.full_name,
    'phone', v_driver.phone,
    'employee_code', v_driver.employee_code
  );
end;
$$;

revoke all on function public.resolve_captain_login(text) from public;
revoke all on function public.link_current_captain_driver(text) from public;
grant execute on function public.resolve_captain_login(text) to anon, authenticated;
grant execute on function public.link_current_captain_driver(text) to authenticated;
