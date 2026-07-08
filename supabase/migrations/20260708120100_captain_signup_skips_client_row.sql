-- handle_new_client_user() fires for every auth.users insert and creates a
-- public.clients row, defaulting phone to '' when no phone metadata is
-- given. That's correct for the Client app's signUp flow, but the new
-- Captain phone-login (20260708120000_captain_phone_login.sql) also creates
-- auth.users rows via signUp — tagged with raw_user_meta_data->>'role' =
-- 'driver'. Those aren't clients and shouldn't get a clients row: besides
-- being the wrong entity, a second driver signup with no phone metadata
-- collides on the clients.phone unique constraint (both default to '').
create or replace function public.handle_new_client_user()
returns trigger
language plpgsql
security definer
as $function$
BEGIN
  IF new.raw_user_meta_data->>'role' = 'driver' THEN
    RETURN new;
  END IF;

  INSERT INTO public.clients (id, full_name, phone, email)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Unknown User'),
    COALESCE(new.raw_user_meta_data->>'phone', new.phone, ''),
    new.email
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$function$;
