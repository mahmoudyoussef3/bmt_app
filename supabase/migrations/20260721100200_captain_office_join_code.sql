-- =====================================================================================
-- EWT multi-office — captain onboarding must not be self-asserted
-- -------------------------------------------------------------------------------------
-- submit_captain_request (090300) takes p_office_id straight from the app. With one
-- office that is harmless — there is nowhere else to land. With a marketplace it means
-- anyone can queue themselves against any office they can name, and public_offices
-- hands out every office id to anon by design.
--
-- The queue entry alone grants nothing: a dashboard operator still has to approve it,
-- and post-approval the captain's office is read from their own `drivers` row, never
-- from the client. So this is not a privilege escalation — but an open queue is an
-- abuse and social-engineering surface (spam the queue, or get approved by an operator
-- who assumes the applicant was already vetted).
--
-- Fix, in keeping with how offices actually recruit drivers: the office issues a join
-- code out of band, and the request must carry it. Approval remains mandatory, so this
-- is a second factor on the queue, not a replacement for review.
-- =====================================================================================

-- ── 1. Join codes ───────────────────────────────────────────────────────────────────

alter table public.offices
  add column if not exists join_code text,
  add column if not exists join_code_rotated_at timestamptz;

create or replace function public.generate_office_join_code()
returns text
language sql
volatile
as $$
  -- Ambiguous glyphs (0/O, 1/I) left out: these get read aloud and typed by hand.
  select string_agg(
    substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
           (1 + floor(random() * 32))::int, 1), '')
    from generate_series(1, 8);
$$;

update public.offices
   set join_code = public.generate_office_join_code(),
       join_code_rotated_at = now()
 where join_code is null;

-- Defaulted, not just backfilled: onboarding a new office must not have to know that
-- join codes exist, and a NOT NULL column with no default would reject every insert
-- that predates this migration's awareness.
alter table public.offices
  alter column join_code set default public.generate_office_join_code(),
  alter column join_code set not null;

create unique index if not exists offices_join_code_key
  on public.offices (upper(join_code));

-- ── 2. Requests carry the code ──────────────────────────────────────────────────────

alter table public.captain_requests
  add column if not exists office_code_verified boolean not null default false;

create or replace function public.submit_captain_request(
  p_full_name   text,
  p_phone       text,
  p_office_id   uuid default null,
  p_office_code text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone_norm   text := public.normalize_egyptian_phone(coalesce(p_phone, ''));
  v_name         text := trim(coalesce(p_full_name, ''));
  v_code         text := nullif(upper(trim(coalesce(p_office_code, ''))), '');
  v_office       uuid := p_office_id;
  v_active_count int;
  v_existing     public.captain_requests;
  v_id           uuid;
begin
  if length(v_phone_norm) < 10 then
    raise exception 'رقم الهاتف غير صالح' using errcode = '22023';
  end if;
  if length(v_name) < 2 then
    raise exception 'الاسم غير صالح' using errcode = '22023';
  end if;

  select count(*) into v_active_count from public.offices where status = 'active';

  -- Resolve the office from the code when one was supplied. The code is authoritative:
  -- if it and p_office_id disagree, the code wins and the mismatch is rejected, so a
  -- tampered office id cannot ride along with a valid code.
  if v_code is not null then
    select id into v_office from public.offices
     where upper(join_code) = v_code and status = 'active';

    if v_office is null then
      raise exception 'invalid_office_code';
    end if;
    if p_office_id is not null and p_office_id <> v_office then
      raise exception 'office_code_mismatch';
    end if;

  elsif v_active_count = 1 then
    -- Single-office deployment: nothing to disambiguate and nothing to abuse. Keeps
    -- existing installs and older app builds working.
    select id into v_office from public.offices where status = 'active';

  else
    -- More than one office and no code: refuse rather than pick a queue.
    raise exception 'office_code_required';
  end if;

  if not exists (
    select 1 from public.offices where id = v_office and status = 'active'
  ) then
    raise exception 'office_inactive';
  end if;

  if exists (
    select 1 from public.drivers d
     where public.normalize_egyptian_phone(d.phone) = v_phone_norm
       and d.status = 'active'
  ) then
    return jsonb_build_object('outcome', 'already_active');
  end if;

  select * into v_existing
    from public.captain_requests
   where phone_normalized = v_phone_norm and status = 'pending'
   limit 1;

  if found then
    return jsonb_build_object(
      'outcome', 'pending', 'request_id', v_existing.id, 'phone', v_existing.phone);
  end if;

  insert into public.captain_requests
    (full_name, phone, phone_normalized, office_id, status, office_code_verified)
  values
    (v_name, p_phone, v_phone_norm, v_office, 'pending', v_code is not null)
  returning id into v_id;

  return jsonb_build_object('outcome', 'submitted', 'request_id', v_id,
                            'phone', p_phone);
end;
$$;

revoke all on function public.submit_captain_request(text, text, uuid, text)
  from public, anon, authenticated;
grant execute on function public.submit_captain_request(text, text, uuid, text)
  to anon, authenticated;

drop function if exists public.submit_captain_request(text, text, uuid);

comment on function public.submit_captain_request(text, text, uuid, text) is
  'Queues a captain access request. With more than one active office a valid office '
  'join code is required, and the code — not the caller-supplied office id — decides '
  'which queue the request lands in. Dashboard approval is still mandatory.';

-- ── 3. Offices manage their own code ────────────────────────────────────────────────

create or replace function public.office_join_code()
returns text
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
  return (select join_code from public.offices where id = v_office);
end;
$$;

create or replace function public.office_rotate_join_code()
returns text
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
  v_code   text;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if public.office_role() <> 'dashboard_admin' then
    raise exception 'dashboard_admin_required';
  end if;

  loop
    v_code := public.generate_office_join_code();
    exit when not exists (
      select 1 from public.offices where upper(join_code) = upper(v_code));
  end loop;

  update public.offices
     set join_code = v_code, join_code_rotated_at = now()
   where id = v_office;

  return v_code;
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'public.office_join_code()',
    'public.office_rotate_join_code()'
  ]
  loop
    execute format('revoke all on function %s from public, anon, authenticated', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

revoke all on function public.generate_office_join_code()
  from public, anon, authenticated;

-- The code must never be readable through the anon-facing office directory. Recreate
-- public_offices explicitly so a later `select *` cannot pick it up by accident.
drop view if exists public.public_offices;
create view public.public_offices as
  select id, name, slug, logo_url, description, service_areas, rating, ratings_count
    from public.offices
   where status = 'active';

grant select on public.public_offices to anon, authenticated;

-- Excluding it from that view is not enough on its own: `offices` itself carries an
-- `offices_public_read` policy for every active row, so anyone could have read the
-- code straight off the base table. Column-level privileges are the only thing that
-- separates the code from the rest of the row, since a client and a dashboard operator
-- are the same Postgres role. public_offices is unaffected — it runs as its owner.
revoke all on public.offices from anon, authenticated;
grant select (
  id, name, slug, logo_url, description, phone, email, service_areas,
  status, rating, ratings_count, created_at, updated_at
) on public.offices to anon, authenticated;

-- An office admin still edits its own profile; the code is changed only through
-- office_rotate_join_code().
grant update (
  name, slug, logo_url, description, phone, email, service_areas
) on public.offices to authenticated;

comment on column public.offices.join_code is
  'Shared with recruited drivers out of band. Never exposed to anon or authenticated '
  'via column privileges; read it with office_join_code(), rotate with '
  'office_rotate_join_code().';
