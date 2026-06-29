-- ============================================================================
-- Notification System — Production upgrade
-- ----------------------------------------------------------------------------
-- Upgrades the existing `notifications` table with category / priority /
-- deep-link metadata, adds `notification_tokens` for FCM readiness, and
-- `notification_preferences` for per-user opt-in/out control.
-- RLS and Realtime are configured for all three tables.
-- ============================================================================

-- ── 1. Upgrade notifications table ──────────────────────────────────────────

alter table public.notifications
  add column if not exists category   text not null default 'general',
  add column if not exists data       jsonb default '{}',
  add column if not exists action_url text,
  add column if not exists target_app text not null default 'client',
  add column if not exists priority   text not null default 'normal';

-- Guard: add check constraints only once
do $$ begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'notifications_target_app_check'
      and conrelid = 'public.notifications'::regclass
  ) then
    alter table public.notifications
      add constraint notifications_target_app_check
        check (target_app in ('client', 'captain', 'all')),
      add constraint notifications_priority_check
        check (priority in ('low', 'normal', 'high', 'urgent'));
  end if;
end $$;

-- ── 2. notification_tokens ───────────────────────────────────────────────────
-- Stores FCM / APNs tokens per device. Populated by the mobile apps on login.
-- Ready to use once Firebase native config is added to the projects.

create table if not exists public.notification_tokens (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  token       text not null,
  platform    text not null,
  app_type    text not null,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique(user_id, token)
);

do $$ begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'notification_tokens_platform_check'
      and conrelid = 'public.notification_tokens'::regclass
  ) then
    alter table public.notification_tokens
      add constraint notification_tokens_platform_check
        check (platform in ('android', 'ios', 'web')),
      add constraint notification_tokens_app_type_check
        check (app_type in ('client', 'captain', 'dashboard'));
  end if;
end $$;

create index if not exists idx_notification_tokens_user_id
  on public.notification_tokens (user_id);
create index if not exists idx_notification_tokens_active
  on public.notification_tokens (user_id, app_type) where is_active = true;

-- ── 3. notification_preferences ─────────────────────────────────────────────
-- One row per user. Auto-created with defaults on first login via trigger.

create table if not exists public.notification_preferences (
  user_id              uuid primary key references auth.users(id) on delete cascade,
  booking_enabled      boolean not null default true,
  payment_enabled      boolean not null default true,
  trip_enabled         boolean not null default true,
  announcement_enabled boolean not null default true,
  promotion_enabled    boolean not null default true,
  emergency_enabled    boolean not null default true,
  chat_enabled         boolean not null default true,
  push_enabled         boolean not null default true,
  sound_enabled        boolean not null default true,
  vibration_enabled    boolean not null default true,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

-- Auto-provision preference row when a new auth user signs up
create or replace function public.handle_new_user_notification_prefs()
returns trigger language plpgsql security definer as $$
begin
  insert into public.notification_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_notif_prefs on auth.users;
create trigger on_auth_user_created_notif_prefs
  after insert on auth.users
  for each row execute procedure public.handle_new_user_notification_prefs();

-- ── 4. RPC: broadcast notification ─────────────────────────────────────────
-- Called from the Dashboard to fan-out a notification to every user whose
-- preferences allow the given category.

create or replace function public.broadcast_notification(
  p_title      text,
  p_body       text,
  p_category   text  default 'announcement',
  p_target_app text  default 'client',
  p_action_url text  default null,
  p_data       jsonb default '{}'
) returns int
language plpgsql security definer as $$
declare
  v_inserted int;
  v_col      text;
begin
  v_col := p_category || '_enabled';

  -- Fan-out to all users with the matching token app_type who haven't opted out.
  -- Falls back gracefully: if the preference column doesn't exist, skip the filter.
  begin
    execute format(
      'insert into public.notifications
         (user_id, title, body, category, target_app, action_url, data)
       select t.user_id, $1, $2, $3, $4, $5, $6
       from   public.notification_tokens t
       join   public.notification_preferences p on p.user_id = t.user_id
       where  t.app_type = $4
         and  t.is_active = true
         and  p.%I = true
       on conflict do nothing',
      v_col
    ) using p_title, p_body, p_category, p_target_app, p_action_url, p_data;
  exception when undefined_column then
    insert into public.notifications
      (user_id, title, body, category, target_app, action_url, data)
    select t.user_id, p_title, p_body, p_category, p_target_app, p_action_url, p_data
    from   public.notification_tokens t
    where  t.app_type = p_target_app
      and  t.is_active = true;
  end;

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

-- ── 5. Indexes ───────────────────────────────────────────────────────────────
create index if not exists idx_notifications_user_id
  on public.notifications (user_id, created_at desc);
create index if not exists idx_notifications_user_unread
  on public.notifications (user_id) where is_read = false;
create index if not exists idx_notifications_category
  on public.notifications (user_id, category);

-- ── 6. RLS ───────────────────────────────────────────────────────────────────
alter table public.notifications           enable row level security;
alter table public.notification_tokens     enable row level security;
alter table public.notification_preferences enable row level security;

-- notifications: own rows only
drop policy if exists "Users read own notifications"       on public.notifications;
drop policy if exists "Users update own notifications"     on public.notifications;
drop policy if exists "Service role insert notifications"  on public.notifications;

create policy "Users read own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

create policy "Users update own notifications"
  on public.notifications for update
  using (auth.uid() = user_id);

create policy "Service role insert notifications"
  on public.notifications for insert
  with check (true);

-- notification_tokens: own tokens
drop policy if exists "Users manage own tokens" on public.notification_tokens;
create policy "Users manage own tokens"
  on public.notification_tokens for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- notification_preferences: own row
drop policy if exists "Users manage own preferences" on public.notification_preferences;
create policy "Users manage own preferences"
  on public.notification_preferences for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── 7. Realtime ──────────────────────────────────────────────────────────────
do $$ begin
  begin
    alter publication supabase_realtime add table public.notifications;
  exception when duplicate_object then null;
  end;
end $$;
