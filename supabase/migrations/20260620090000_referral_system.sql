-- ============================================================================
-- Referral & Rewards System
-- ----------------------------------------------------------------------------
-- Production-grade referral engine: per-user codes, referral lifecycle,
-- configurable reward engine, reward transactions, automatic reward granting
-- on the referred user's first paid order, dual notifications, leaderboard and
-- analytics views, and RLS.
--
-- Idempotent where practical (IF NOT EXISTS / CREATE OR REPLACE). Apply with the
-- Supabase CLI:  supabase db push
-- ============================================================================

create extension if not exists pgcrypto;

-- ── 1. Reward engine configuration (admin-editable) ─────────────────────────
-- Earlier app drafts used `referral_rewards` for per-referral reward records
-- with required `referrer_id` / `referred_id` columns. Preserve that data under
-- a legacy name so `referral_rewards` can become the singleton config table
-- expected by the dashboard and reward-granting RPCs.
do $$
declare
  v_legacy_name text;
begin
  if to_regclass('public.referral_rewards') is not null
     and exists (
       select 1
         from information_schema.columns
        where table_schema = 'public'
          and table_name = 'referral_rewards'
          and column_name in ('referrer_id', 'referred_id')
     ) then
    v_legacy_name := 'referral_rewards_legacy';

    if to_regclass('public.' || v_legacy_name) is not null then
      v_legacy_name := 'referral_rewards_legacy_' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS');
    end if;

    alter table public.referral_rewards drop constraint if exists referral_rewards_pkey;
    alter table public.referral_rewards drop constraint if exists referral_rewards_singleton;
    drop index if exists public.referral_rewards_pkey;

    execute format('alter table public.referral_rewards rename to %I', v_legacy_name);
  end if;
end $$;

create table if not exists public.referral_rewards (
  id              int primary key default 1,
  enabled         boolean      not null default true,
  reward_type     text         not null default 'wallet'
                    check (reward_type in ('points','wallet','coupon','loyalty')),
  reward_value    numeric      not null default 50,      -- referrer reward
  referred_value  numeric      not null default 25,      -- referred welcome reward
  currency        text         not null default 'EGP',
  coupon_code     text,
  updated_at      timestamptz  not null default now(),
  updated_by      uuid references auth.users(id),
  constraint referral_rewards_singleton check (id = 1)
);

-- Earlier drafts of this table used a UUID primary key. Normalize existing
-- databases to the singleton integer key expected by the dashboard and RPCs.
do $$ begin
  if exists (
    select 1
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'referral_rewards'
       and column_name = 'id'
       and data_type = 'uuid'
  ) then
    alter table public.referral_rewards drop constraint if exists referral_rewards_pkey;
    alter table public.referral_rewards drop constraint if exists referral_rewards_singleton;
    alter table public.referral_rewards drop column id;
    alter table public.referral_rewards add column id int not null default 1;
  end if;
end $$;

alter table public.referral_rewards
  add column if not exists enabled         boolean      not null default true,
  add column if not exists reward_type     text         not null default 'wallet',
  add column if not exists reward_value    numeric      not null default 50,
  add column if not exists referred_value  numeric      not null default 25,
  add column if not exists currency        text         not null default 'EGP',
  add column if not exists coupon_code     text,
  add column if not exists updated_at      timestamptz  not null default now(),
  add column if not exists updated_by      uuid references auth.users(id);

delete from public.referral_rewards a
 using public.referral_rewards b
 where a.ctid < b.ctid;

do $$ begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.referral_rewards'::regclass
       and contype = 'p'
  ) then
    alter table public.referral_rewards
      add constraint referral_rewards_pkey primary key (id);
  end if;
end $$;

do $$ begin
  alter table public.referral_rewards
    add constraint referral_rewards_singleton check (id = 1);
exception when duplicate_object then null; end $$;

insert into public.referral_rewards (id) values (1)
  on conflict (id) do nothing;

-- ── 2. Per-user referral codes ──────────────────────────────────────────────
-- Preserve incompatible earlier `referral_codes` drafts before creating the
-- production table expected by triggers, RPCs, dashboard lookups, and RLS.
do $$
declare
  v_legacy_name text;
begin
  if to_regclass('public.referral_codes') is not null
     and (
       not exists (
         select 1
           from information_schema.columns
          where table_schema = 'public'
            and table_name = 'referral_codes'
            and column_name = 'user_id'
       )
       or not exists (
         select 1
           from information_schema.columns
          where table_schema = 'public'
            and table_name = 'referral_codes'
            and column_name = 'code'
       )
     ) then
    v_legacy_name := 'referral_codes_legacy';

    if to_regclass('public.' || v_legacy_name) is not null then
      v_legacy_name := 'referral_codes_legacy_' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS');
    end if;

    alter table public.referral_codes drop constraint if exists referral_codes_pkey;
    alter table public.referral_codes drop constraint if exists referral_codes_user_id_key;
    alter table public.referral_codes drop constraint if exists referral_codes_code_key;
    drop index if exists public.referral_codes_pkey;
    drop index if exists public.referral_codes_user_id_key;
    drop index if exists public.referral_codes_code_key;
    drop index if exists public.idx_referral_codes_code;

    execute format('alter table public.referral_codes rename to %I', v_legacy_name);
  end if;
end $$;

create table if not exists public.referral_codes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null unique references auth.users(id) on delete cascade,
  code        text not null unique,
  created_at  timestamptz not null default now()
);

alter table public.referral_codes
  add column if not exists id         uuid        default gen_random_uuid(),
  add column if not exists user_id    uuid        references auth.users(id) on delete cascade,
  add column if not exists code       text,
  add column if not exists created_at timestamptz not null default now();

do $$ begin
  alter table public.referral_codes alter column id set not null;
  alter table public.referral_codes alter column user_id set not null;
  alter table public.referral_codes alter column code set not null;
exception when not_null_violation then
  raise exception 'Existing referral_codes rows contain null user_id or code; table was not automatically migrated.';
end $$;

do $$ begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.referral_codes'::regclass
       and contype = 'p'
  ) then
    alter table public.referral_codes
      add constraint referral_codes_pkey primary key (id);
  end if;
end $$;

create unique index if not exists uq_referral_codes_user_id
  on public.referral_codes (user_id);
create unique index if not exists uq_referral_codes_code
  on public.referral_codes (code);
create index if not exists idx_referral_codes_code on public.referral_codes (code);

-- ── 3. Referrals (lifecycle) ────────────────────────────────────────────────
-- The base table may already exist; add the columns the engine needs.
create table if not exists public.referrals (
  id            uuid primary key default gen_random_uuid(),
  referrer_id   uuid not null references auth.users(id) on delete cascade,
  created_at    timestamptz not null default now()
);

alter table public.referrals
  add column if not exists referred_id   uuid references auth.users(id) on delete set null,
  add column if not exists referral_code text,
  add column if not exists referred_name text,
  add column if not exists status        text not null default 'pending_registration',
  add column if not exists reward_type   text,
  add column if not exists reward_value  numeric not null default 0,
  add column if not exists reward_status text not null default 'pending',
  add column if not exists first_order_id uuid,
  add column if not exists registered_at  timestamptz,
  add column if not exists first_order_at timestamptz,
  add column if not exists rewarded_at    timestamptz;

-- Legacy column kept in sync for older clients that read reward_amount.
alter table public.referrals
  add column if not exists reward_amount numeric generated always as (reward_value) stored;

do $$ begin
  alter table public.referrals
    add constraint referrals_status_chk check (status in
      ('pending_registration','registered','first_order_completed','reward_granted'));
exception when duplicate_object then null; end $$;

-- A customer can only be referred once.
create unique index if not exists uq_referrals_referred
  on public.referrals (referred_id) where referred_id is not null;
create index if not exists idx_referrals_referrer on public.referrals (referrer_id);

-- ── 4. Reward transactions (immutable ledger) ───────────────────────────────
create table if not exists public.referral_reward_transactions (
  id           uuid primary key default gen_random_uuid(),
  referral_id  uuid not null references public.referrals(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  role         text not null check (role in ('referrer','referred')),
  reward_type  text not null,
  reward_value numeric not null default 0,
  status       text not null default 'granted',
  created_at   timestamptz not null default now()
);
create index if not exists idx_rrt_user on public.referral_reward_transactions (user_id);

-- ── 5. Code generation ──────────────────────────────────────────────────────
create or replace function public.generate_unique_referral_code(p_seed text)
returns text language plpgsql as $$
declare
  v_prefix text;
  v_code   text;
begin
  v_prefix := upper(left(regexp_replace(coalesce(p_seed,''), '[^A-Za-z]', '', 'g'), 6));
  if length(v_prefix) < 3 then v_prefix := 'BMT'; end if;
  loop
    v_code := v_prefix || '-' || upper(substr(md5(random()::text), 1, 4));
    exit when not exists (select 1 from public.referral_codes where code = v_code);
  end loop;
  return v_code;
end $$;

-- ── 6. New-user hook: issue code + record pending referral from metadata ─────
create or replace function public.handle_new_user_referral()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_name        text := coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1));
  v_used_code   text := upper(coalesce(new.raw_user_meta_data->>'referral_code',''));
  v_referrer    uuid;
begin
  -- 6a. Always issue a unique referral code for the new user.
  insert into public.referral_codes (user_id, code)
  values (new.id, public.generate_unique_referral_code(v_name))
  on conflict (user_id) do nothing;

  -- 6b. If they signed up with a referral code, record a pending referral.
  if v_used_code <> '' then
    select user_id into v_referrer from public.referral_codes where code = v_used_code;
    if v_referrer is not null
       and v_referrer <> new.id
       and not exists (select 1 from public.referrals where referred_id = new.id) then
      insert into public.referrals
        (referrer_id, referred_id, referral_code, referred_name, status, registered_at)
      values (v_referrer, new.id, v_used_code, v_name, 'registered', now());
    end if;
  end if;
  return new;
end $$;

drop trigger if exists on_auth_user_created_referral on auth.users;
create trigger on_auth_user_created_referral
  after insert on auth.users
  for each row execute function public.handle_new_user_referral();

-- ── 7. Redeem a code at checkout (RPC for the "enter later" path) ────────────
create or replace function public.redeem_referral_code(p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_user     uuid := auth.uid();
  v_code     text := upper(coalesce(p_code,''));
  v_referrer uuid;
  v_name     text;
begin
  if v_user is null then return jsonb_build_object('ok', false, 'error', 'unauthenticated'); end if;
  select user_id into v_referrer from public.referral_codes where code = v_code;
  if v_referrer is null then return jsonb_build_object('ok', false, 'error', 'invalid_code'); end if;
  if v_referrer = v_user then return jsonb_build_object('ok', false, 'error', 'self_referral'); end if;
  if exists (select 1 from public.referrals where referred_id = v_user) then
    return jsonb_build_object('ok', false, 'error', 'already_referred');
  end if;
  select coalesce(full_name, 'Guest') into v_name from public.clients where id = v_user;
  insert into public.referrals
    (referrer_id, referred_id, referral_code, referred_name, status, registered_at)
  values (v_referrer, v_user, v_code, v_name, 'registered', now());
  return jsonb_build_object('ok', true);
end $$;

-- ── 8. Reward granting on the referred user's first paid order ───────────────
create or replace function public.grant_referral_reward()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_ref    public.referrals%rowtype;
  v_cfg    public.referral_rewards%rowtype;
begin
  -- Only act on the transition into a paid/confirmed state.
  if new.status not in ('confirmed','approved') then return new; end if;

  select * into v_ref from public.referrals
   where referred_id = new.client_id
     and status in ('registered','pending_registration')
   limit 1;
  if not found then return new; end if;

  -- Must be the customer's first paid order.
  if exists (
    select 1 from public.operation_bookings
     where client_id = new.client_id and id <> new.id
       and status in ('confirmed','approved')
  ) then return new; end if;

  select * into v_cfg from public.referral_rewards where id = 1;

  update public.referrals
     set status = 'first_order_completed', first_order_id = new.id, first_order_at = now()
   where id = v_ref.id;

  if v_cfg.enabled then
    -- Referrer reward
    insert into public.referral_reward_transactions
      (referral_id, user_id, role, reward_type, reward_value)
    values (v_ref.id, v_ref.referrer_id, 'referrer', v_cfg.reward_type, v_cfg.reward_value);
    -- Referred welcome reward
    insert into public.referral_reward_transactions
      (referral_id, user_id, role, reward_type, reward_value)
    values (v_ref.id, v_ref.referred_id, 'referred', v_cfg.reward_type, v_cfg.referred_value);

    -- Credit balances (wallet/points) on loyalty_accounts.
    if v_cfg.reward_type in ('wallet','coupon') then
      update public.loyalty_accounts set wallet_balance = coalesce(wallet_balance,0) + v_cfg.reward_value
        where client_id = v_ref.referrer_id;
      update public.loyalty_accounts set wallet_balance = coalesce(wallet_balance,0) + v_cfg.referred_value
        where client_id = v_ref.referred_id;
    else -- points / loyalty
      update public.loyalty_accounts set points_balance = coalesce(points_balance,0) + v_cfg.reward_value::int
        where client_id = v_ref.referrer_id;
      update public.loyalty_accounts set points_balance = coalesce(points_balance,0) + v_cfg.referred_value::int
        where client_id = v_ref.referred_id;
    end if;

    update public.referrals
       set status = 'reward_granted', reward_type = v_cfg.reward_type,
           reward_value = v_cfg.reward_value, reward_status = 'granted', rewarded_at = now()
     where id = v_ref.id;

    -- Dual notifications.
    insert into public.notifications (user_id, title, body, type, is_read)
    values (
      v_ref.referrer_id,
      'Referral reward earned 🎉',
      'Congratulations! ' || coalesce(v_ref.referred_name,'Your friend') ||
        ' completed their first order using your referral code. You earned ' ||
        v_cfg.reward_value || ' ' ||
        case when v_cfg.reward_type in ('wallet','coupon') then v_cfg.currency else 'points' end || '.',
      'referral', false
    );
    insert into public.notifications (user_id, title, body, type, is_read)
    values (
      v_ref.referred_id,
      'Welcome reward unlocked 🎁',
      'You received a welcome reward for using a referral code. Enjoy your ride!',
      'referral', false
    );
  end if;

  return new;
end $$;

drop trigger if exists on_booking_paid_referral on public.operation_bookings;
create trigger on_booking_paid_referral
  after insert or update of status on public.operation_bookings
  for each row execute function public.grant_referral_reward();

-- ── 9. Leaderboard + analytics views ────────────────────────────────────────
create or replace view public.referral_leaderboard as
  select r.referrer_id,
         coalesce(c.full_name, 'Member')                          as name,
         count(*) filter (where r.status in
           ('first_order_completed','reward_granted'))            as successful_count,
         coalesce(sum(r.reward_value) filter
           (where r.reward_status = 'granted'), 0)                as total_rewards
    from public.referrals r
    left join public.clients c on c.id = r.referrer_id
   group by r.referrer_id, c.full_name
   order by successful_count desc;

create or replace view public.referral_analytics as
  select count(*)                                                          as total_referrals,
         count(*) filter (where status in
           ('first_order_completed','reward_granted'))                     as successful_referrals,
         round(100.0 * count(*) filter (where status in
           ('first_order_completed','reward_granted'))
           / nullif(count(*),0), 1)                                        as conversion_rate,
         coalesce(sum(reward_value) filter (where reward_status='granted'),0) as rewards_distributed
    from public.referrals;

-- ── 10. Row-level security ──────────────────────────────────────────────────
alter table public.referral_codes enable row level security;
alter table public.referrals enable row level security;
alter table public.referral_reward_transactions enable row level security;
alter table public.referral_rewards enable row level security;

do $$ begin
  create policy referral_codes_select_own on public.referral_codes
    for select using (auth.uid() = user_id);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy referrals_select_involved on public.referrals
    for select using (auth.uid() = referrer_id or auth.uid() = referred_id);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy rrt_select_own on public.referral_reward_transactions
    for select using (auth.uid() = user_id);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy referral_rewards_read on public.referral_rewards
    for select using (true);
exception when duplicate_object then null; end $$;

grant select on public.referral_leaderboard to authenticated;
grant select on public.referral_analytics  to authenticated;

-- Backfill referral codes for existing users.
insert into public.referral_codes (user_id, code)
select u.id, public.generate_unique_referral_code(coalesce(c.full_name, split_part(u.email,'@',1)))
  from auth.users u
  left join public.clients c on c.id = u.id
 where not exists (select 1 from public.referral_codes rc where rc.user_id = u.id);
