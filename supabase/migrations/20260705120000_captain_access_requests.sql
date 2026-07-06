-- Captain self-service access requests.
--
-- A prospective captain submits their name + phone from the Captain app before
-- they have any account. Operations reviews the queue on the Dashboard and
-- either approves (completing the full driver record) or rejects the request.
-- The captain has no auth session yet, so submission + status polling run
-- through SECURITY DEFINER RPCs callable by the anon role. The Dashboard reads
-- and reviews the queue as an authenticated user.

create table if not exists public.captain_requests (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text not null,
  phone_normalized text not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  note text,
  rejection_reason text,
  driver_id uuid references public.drivers(id) on delete set null,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_captain_requests_status
  on public.captain_requests (status, created_at desc);

create index if not exists idx_captain_requests_phone
  on public.captain_requests (phone_normalized);

-- One live pending request per phone keeps the queue clean and makes
-- re-submissions idempotent.
create unique index if not exists uq_captain_requests_pending_phone
  on public.captain_requests (phone_normalized)
  where status = 'pending';

alter table public.captain_requests enable row level security;

-- Dashboard operators (authenticated) manage the whole queue. Anonymous
-- captains never touch the table directly — only via the RPCs below.
drop policy if exists "authenticated read captain requests" on public.captain_requests;
create policy "authenticated read captain requests"
  on public.captain_requests for select
  to authenticated using (true);

drop policy if exists "authenticated review captain requests" on public.captain_requests;
create policy "authenticated review captain requests"
  on public.captain_requests for update
  to authenticated using (true) with check (true);

-- ── Captain-facing RPCs (anon) ──────────────────────────────────────────────

-- Submit an access request. Returns a JSON outcome the app can branch on:
--   { outcome: 'already_active' }              -> already a driver, just sign in
--   { outcome: 'pending', request_id, phone }  -> a review is already in flight
--   { outcome: 'submitted', request_id, phone }-> newly queued for review
create or replace function public.submit_captain_request(
  p_full_name text,
  p_phone text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := btrim(coalesce(p_full_name, ''));
  v_phone_norm text := public.normalize_egyptian_phone(coalesce(p_phone, ''));
  v_existing public.captain_requests;
  v_new_id uuid;
begin
  if length(v_name) < 3 then
    raise exception 'الاسم غير صالح' using errcode = '22023';
  end if;
  if length(v_phone_norm) < 10 then
    raise exception 'رقم الهاتف غير صالح' using errcode = '22023';
  end if;

  -- Already an active captain? Nothing to request — they can sign in.
  if exists (
    select 1 from public.drivers d
    where public.normalize_egyptian_phone(d.phone) = v_phone_norm
      and d.status = 'active'
  ) then
    return jsonb_build_object('outcome', 'already_active');
  end if;

  -- Idempotent: return the in-flight request instead of creating a duplicate.
  select * into v_existing
  from public.captain_requests
  where phone_normalized = v_phone_norm and status = 'pending'
  order by created_at desc
  limit 1;

  if found then
    return jsonb_build_object(
      'outcome', 'pending',
      'request_id', v_existing.id,
      'phone', v_existing.phone
    );
  end if;

  insert into public.captain_requests (full_name, phone, phone_normalized)
  values (v_name, btrim(p_phone), v_phone_norm)
  returning id into v_new_id;

  return jsonb_build_object(
    'outcome', 'submitted',
    'request_id', v_new_id,
    'phone', btrim(p_phone)
  );
end;
$$;

-- Poll the latest request status for a phone. Returns null when none exists.
-- When approved, the linked driver's name/phone ride along so the app can greet
-- the captain immediately.
create or replace function public.get_captain_request_status(p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone_norm text := public.normalize_egyptian_phone(coalesce(p_phone, ''));
  v_row public.captain_requests;
  v_driver public.drivers;
begin
  select * into v_row
  from public.captain_requests
  where phone_normalized = v_phone_norm
  order by created_at desc
  limit 1;

  if not found then
    return null;
  end if;

  if v_row.driver_id is not null then
    select * into v_driver from public.drivers where id = v_row.driver_id;
  end if;

  return jsonb_build_object(
    'request_id', v_row.id,
    'status', v_row.status,
    'full_name', coalesce(v_driver.full_name, v_row.full_name),
    'phone', coalesce(v_driver.phone, v_row.phone),
    'rejection_reason', v_row.rejection_reason,
    'driver_id', v_row.driver_id,
    'employee_code', v_driver.employee_code
  );
end;
$$;

revoke all on function public.submit_captain_request(text, text) from public;
revoke all on function public.get_captain_request_status(text) from public;
grant execute on function public.submit_captain_request(text, text) to anon, authenticated;
grant execute on function public.get_captain_request_status(text) to anon, authenticated;

-- Live queue updates for the Dashboard.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'captain_requests'
    ) then
      alter publication supabase_realtime add table public.captain_requests;
    end if;
  end if;
end $$;
